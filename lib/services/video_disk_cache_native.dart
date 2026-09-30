// lib/services/video_disk_cache_native.dart
// Stores motion-artwork videos on disk (one folder per video, named after the
// SHA-1 of its URL) so they replay offline and without re-downloading.
//   • HLS (.m3u8): the lowest-bitrate variant is downloaded segment by
//     segment and a local playlist with relative paths is written last.
//   • Plain files (.mp4...): downloaded as a single file.
// A folder only counts once its index file exists, so half-downloaded videos
// are never played. Eviction is LRU (folder modification time).
// Android only: iOS/desktop players don't reliably read local HLS.
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoDiskCache {
  VideoDiskCache._();

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Size limit in bytes: 0 = unlimited, negative = disk cache disabled.
  static int maxBytes = 500 * 1024 * 1024;

  static Directory? _root;
  static final Set<String> _busy = {};

  static Future<void> init(int maxBytesLimit) async => maxBytes = maxBytesLimit;

  static Future<Directory> _dir() async {
    final r = _root;
    if (r != null) return r;
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/video_cache');
    await d.create(recursive: true);
    return _root = d;
  }

  static String _id(String url) => sha1.convert(utf8.encode(url)).toString();

  static Future<File?> _indexOf(String url) async {
    final f = File('${(await _dir()).path}/${_id(url)}/index');
    return f.existsSync() ? f : null;
  }

  /// A player reading the cached copy, or null when the video isn't cached.
  static Future<VideoPlayerController?> localController(
      String url, VideoPlayerOptions options) async {
    if (!supported || maxBytes < 0) return null;
    try {
      final idx = await _indexOf(url);
      if (idx == null) return null;
      // Bump the folder time so LRU keeps recently played videos.
      idx.parent.setLastModifiedSync(DateTime.now());
      final target = File(File('${idx.parent.path}/target').readAsStringSync());
      return VideoPlayerController.file(target, videoPlayerOptions: options);
    } catch (_) {
      return null;
    }
  }

  /// Downloads [url] in the background (fire and forget).
  static void storeInBackground(String url) {
    if (!supported || maxBytes < 0 || !_busy.add(url)) return;
    _store(url).catchError((_) {}).whenComplete(() => _busy.remove(url));
  }

  static Future<void> _store(String url) async {
    if (await _indexOf(url) != null) return;
    final dir = Directory('${(await _dir()).path}/${_id(url)}');
    if (dir.existsSync()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    try {
      final String target;
      if (Uri.parse(url).path.endsWith('.m3u8')) {
        target = await _storeHls(url, dir);
      } else {
        final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
        if (r.statusCode != 200) throw Exception('http ${r.statusCode}');
        final f = File('${dir.path}/video.mp4');
        await f.writeAsBytes(r.bodyBytes);
        target = f.path;
      }
      await File('${dir.path}/target').writeAsString(target);
      await File('${dir.path}/index').writeAsString('1'); // written last
      await enforce(maxBytes);
    } catch (_) {
      if (dir.existsSync()) await dir.delete(recursive: true);
    }
  }

  static Future<String> _get(Uri u) async {
    final r = await http.get(u).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('http ${r.statusCode}');
    return r.body;
  }

  static Future<void> _save(Uri u, File f) async {
    final r = await http.get(u).timeout(const Duration(seconds: 60));
    if (r.statusCode != 200) throw Exception('http ${r.statusCode}');
    await f.writeAsBytes(r.bodyBytes);
  }

  /// Returns the path of the local playlist.
  static Future<String> _storeHls(String url, Directory dir) async {
    var base = Uri.parse(url);
    var text = await _get(base);
    // Master playlist: keep the lowest-bandwidth variant (the cover is tiny).
    if (text.contains('#EXT-X-STREAM-INF')) {
      final lines = const LineSplitter().convert(text);
      String? best; var bestBw = 1 << 62;
      for (var i = 0; i < lines.length - 1; i++) {
        if (!lines[i].startsWith('#EXT-X-STREAM-INF')) continue;
        final bw = int.tryParse(
                RegExp(r'BANDWIDTH=(\d+)').firstMatch(lines[i])?.group(1) ?? '') ??
            bestBw;
        if (bw < bestBw) { bestBw = bw; best = lines[i + 1].trim(); }
      }
      if (best == null) throw Exception('no variant');
      base = base.resolve(best);
      text = await _get(base);
    }
    if (text.contains('#EXT-X-KEY')) throw Exception('encrypted');
    final out = StringBuffer();
    var n = 0;
    for (final raw in const LineSplitter().convert(text)) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#EXT-X-MAP')) {
        final m = RegExp(r'URI="([^"]+)"').firstMatch(line);
        if (m != null) {
          await _save(base.resolve(m.group(1)!), File('${dir.path}/init.mp4'));
          out.writeln(line.replaceFirst(m.group(1)!, 'init.mp4'));
          continue;
        }
      }
      if (line.startsWith('#')) { out.writeln(line); continue; }
      final name = 'seg${n++}${_ext(line)}';
      await _save(base.resolve(line), File('${dir.path}/$name'));
      out.writeln(name);
    }
    final playlist = File('${dir.path}/local.m3u8');
    await playlist.writeAsString(out.toString());
    return playlist.path;
  }

  static String _ext(String uri) {
    final p = Uri.parse(uri).path;
    final i = p.lastIndexOf('.');
    return i < 0 || p.length - i > 6 ? '.bin' : p.substring(i);
  }

  // ── Size / eviction ───────────────────────────────────────────────────────

  static int _sizeOf(Directory d) {
    var t = 0;
    try {
      for (final e in d.listSync(recursive: true)) {
        if (e is File) t += e.lengthSync();
      }
    } catch (_) {}
    return t;
  }

  static Future<int> totalBytes() async {
    if (!supported) return 0;
    var t = 0;
    for (final e in (await _dir()).listSync()) {
      if (e is Directory) t += _sizeOf(e);
    }
    return t;
  }

  /// Evicts the least recently played videos until under [limit] bytes.
  /// A negative limit clears everything; 0 means unlimited.
  static Future<void> enforce(int limit) async {
    if (!supported || limit == 0) return;
    if (limit < 0) return clear();
    final dirs = (await _dir()).listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    var total = dirs.fold<int>(0, (s, d) => s + _sizeOf(d));
    for (final d in dirs) {
      if (total <= limit) break;
      total -= _sizeOf(d);
      try { await d.delete(recursive: true); } catch (_) {}
    }
  }

  static Future<void> clear() async {
    if (!supported) return;
    final d = await _dir();
    for (final e in d.listSync()) {
      try { await e.delete(recursive: true); } catch (_) {}
    }
  }
}
