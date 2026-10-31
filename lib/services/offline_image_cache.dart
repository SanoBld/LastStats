// lib/services/offline_image_cache.dart
//
// Caches image bytes on disk (native) or IndexedDB (web).
// Metadata tracks last-access time for LRU eviction.
// Provides ImageProvider for offline-capable widgets.
//
// Usage:
//   final provider = await OfflineImageCache.imageProvider(url);
//   Image(image: provider, ...)

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/skeleton.dart';

import 'image_cache_backend_stub.dart'
    if (dart.library.io)   'image_cache_backend_native.dart'
    if (dart.library.html) 'image_cache_backend_web.dart';

// Web-only CORS bypass for image display (no-op stub on native).
import 'web_img_stub.dart'
    if (dart.library.html) 'web_img_web.dart';

import 'package:http/http.dart' as http;

// ── Entry in the LRU metadata map ────────────────────────────────────────────

class _ImageEntry {
  final String fileKey; // storage key (sequential ID)
  final int    atime;   // last-access epoch ms
  final int    size;    // bytes

  const _ImageEntry({required this.fileKey, required this.atime, required this.size});

  Map<String, dynamic> toJson() => {'f': fileKey, 'a': atime, 's': size};

  factory _ImageEntry.fromJson(Map<String, dynamic> j) => _ImageEntry(
        fileKey: j['f'] as String,
        atime:   (j['a'] as num).toInt(),
        size:    (j['s'] as num).toInt(),
      );
}

// ═════════════════════════════════════════════════════════════════════════════

class OfflineImageCache {
  OfflineImageCache._();

  // url → entry
  static final Map<String, _ImageEntry> _meta = {};
  static int  _totalBytes = 0;
  static int  _nextId     = 0;
  static bool _loaded     = false;

  static const _timeout = Duration(seconds: 8);

  // In-memory copy of recently used images. Without it every rebuild re-read
  // the file from disk (and flashed the placeholder), even for cached images.
  // The SAME Uint8List instance is reused, so Flutter's decoded-image cache
  // also hits and nothing is decoded twice.
  static final Map<String, Uint8List> _mem = {};
  static int _memBytes = 0;
  static const _memMaxBytes   = 64 * 1024 * 1024;
  static const _memMaxEntries = 400;

  static void _memPut(String url, Uint8List bytes) {
    final old = _mem.remove(url);
    if (old != null) _memBytes -= old.length;
    _mem[url] = bytes;
    _memBytes += bytes.length;
    while ((_memBytes > _memMaxBytes || _mem.length > _memMaxEntries) && _mem.isNotEmpty) {
      final k = _mem.keys.first;
      _memBytes -= _mem.remove(k)!.length;
    }
  }

  static Timer? _saveTimer;
  static void _saveMetaLater() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 5), () => _saveMeta().ignore());
  }

  // ── Metadata persistence ──────────────────────────────────────────────────

  static Future<void> _ensureMeta() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await ImageCacheBackend.readMeta();
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _nextId = (json['id'] as num?)?.toInt() ?? 0;
      final entries = (json['e'] as Map<String, dynamic>?) ?? {};
      _meta.clear();
      _totalBytes = 0;
      for (final kv in entries.entries) {
        final e = _ImageEntry.fromJson(kv.value as Map<String, dynamic>);
        _meta[kv.key] = e;
        _totalBytes += e.size;
      }
    } catch (_) {}
  }

  static Future<void> _saveMeta() async {
    try {
      final map = <String, dynamic>{};
      for (final kv in _meta.entries) {
        map[kv.key] = kv.value.toJson();
      }
      await ImageCacheBackend.writeMeta(jsonEncode({'id': _nextId, 'e': map}));
    } catch (_) {}
  }

  // ── Public: get ImageProvider (offline-capable) ───────────────────────────

  /// Returns a MemoryImage if the URL is cached locally, NetworkImage otherwise.
  /// Also triggers a background download so the next call uses local cache.
  static Future<ImageProvider> imageProvider(String url) async {
    if (url.isEmpty) return const AssetImage('');

    await _ensureMeta();

    if (_meta.containsKey(url)) {
      final bytes = await _getBytes(url);
      if (bytes != null) return MemoryImage(bytes);
    }

    // Not cached yet → start background download, return network for now.
    _downloadAndCache(url).ignore();
    return NetworkImage(url);
  }

  // ── Bytes helpers (used for dominant-colour extraction) ───────────────────

  /// Bytes of [url]: from the cache when present, otherwise downloaded once
  /// and stored.
  static Future<Uint8List?> bytesFor(String url) async {
    if (url.isEmpty) return null;
    await _ensureMeta();
    final cached = await _getBytes(url);
    if (cached != null) return cached;
    await _downloadAndCache(url);
    return _getBytes(url);
  }

  /// Same as [bytesFor] but shaped as an http.Response.
  static Future<http.Response> responseFor(String url) async {
    final b = await bytesFor(url);
    return b == null ? http.Response('', 404) : http.Response.bytes(b, 200);
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  static Future<Uint8List?> _getBytes(String url) async {
    final entry = _meta[url];
    if (entry == null) return null;

    var bytes = _mem[url];
    if (bytes != null) {
      _memPut(url, bytes); // bump: most recently used goes last
    } else {
      bytes = await ImageCacheBackend.read(entry.fileKey);
      if (bytes == null) {
        // File gone — remove from meta.
        _totalBytes -= entry.size;
        _meta.remove(url);
        return null;
      }
      _memPut(url, bytes);
    }

    // Update access time for LRU, but write the metadata file rarely.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - entry.atime > 10 * 60 * 1000) {
      _meta[url] = _ImageEntry(fileKey: entry.fileKey, atime: now, size: entry.size);
      _saveMetaLater();
    }
    return bytes;
  }

  // ── Write (with quota enforcement) ───────────────────────────────────────

  static Future<void> put(String url, Uint8List bytes, {int maxBytes = 0}) async {
    await _ensureMeta();

    // Update existing entry.
    if (_meta.containsKey(url)) {
      final old = _meta[url]!;
      _totalBytes += bytes.length - old.size;
      _meta[url] = _ImageEntry(
        fileKey: old.fileKey,
        atime:   DateTime.now().millisecondsSinceEpoch,
        size:    bytes.length,
      );
      await ImageCacheBackend.write(old.fileKey, bytes);
      _memPut(url, bytes);
      await _saveMeta();
      return;
    }

    // Enforce quota before adding.
    if (maxBytes > 0) {
      final overflow = _totalBytes + bytes.length - maxBytes;
      if (overflow > 0) await evictLru(overflow);
      if (bytes.length > maxBytes) return; // single image too big
    }

    final key = '${_nextId++}';
    _meta[url] = _ImageEntry(
      fileKey: key,
      atime:   DateTime.now().millisecondsSinceEpoch,
      size:    bytes.length,
    );
    _totalBytes += bytes.length;
    await ImageCacheBackend.write(key, bytes);
    _memPut(url, bytes);
    await _saveMeta();
  }

  // ── LRU eviction ─────────────────────────────────────────────────────────

  /// Evicts oldest entries until [bytesToFree] bytes have been freed.
  static Future<void> evictLru(int bytesToFree) async {
    await _ensureMeta();
    if (bytesToFree <= 0 || _meta.isEmpty) return;

    final sorted = _meta.entries.toList()
      ..sort((a, b) => a.value.atime.compareTo(b.value.atime));

    int freed = 0;
    for (final kv in sorted) {
      if (freed >= bytesToFree) break;
      await ImageCacheBackend.delete(kv.value.fileKey);
      freed      += kv.value.size;
      _totalBytes -= kv.value.size;
      _meta.remove(kv.key);
      final m = _mem.remove(kv.key);
      if (m != null) _memBytes -= m.length;
    }
    await _saveMeta();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  static Future<int> totalBytes() async {
    await _ensureMeta();
    return _totalBytes;
  }

  static int get totalBytesSync => _totalBytes;

  // ── Clear ─────────────────────────────────────────────────────────────────

  static Future<void> clear() async {
    _mem.clear();
    _memBytes = 0;
    _meta.clear();
    _totalBytes = 0;
    _nextId     = 0;
    _loaded     = false;
    await ImageCacheBackend.clearAll();
  }

  // ── Background download ───────────────────────────────────────────────────

  static Future<void> _downloadAndCache(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        await put(url, res.bodyBytes);
      }
    } catch (_) {}
  }

  // ── Widget helper ─────────────────────────────────────────────────────────

  // Returns a widget that shows the cached image or falls back to network.
  static Widget image({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final ph = placeholder ?? M3ImagePlaceholder(width: width, height: height);
    if (url.isEmpty) return placeholder ?? const SizedBox.shrink();

    // Fast path: already in memory → show it in the same frame, no
    // placeholder flash and no disk read.
    final hot = _mem[url];
    if (hot != null && _meta.containsKey(url)) {
      return Builder(builder: (context) {
        final dpr = MediaQuery.of(context).devicePixelRatio;
        return Image.memory(
          hot,
          width: width,
          height: height,
          fit: fit,
          cacheWidth:  width  != null ? (width * dpr).round()  : null,
          cacheHeight: height != null ? (height * dpr).round() : null,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) =>
              errorWidget ?? placeholder ?? const SizedBox.shrink(),
        );
      });
    }

    // Cache checked FIRST (offline or online) — network is only a fallback.
    return FutureBuilder<Uint8List?>(
      future: _ensureMeta().then((_) => _getBytes(url)),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return ph;
        }

        // Decode at the actual display size (× device pixel ratio) instead
        // of the source's full resolution — a 40dp list thumbnail doesn't
        // need a 3000×3000 bitmap sitting in memory. Only applied when a
        // display size was actually requested; omitted otherwise (e.g. the
        // detail sheet's full-size hero image still wants native quality).
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final cacheWidth  = width  != null ? (width * dpr).round()  : null;
        final cacheHeight = height != null ? (height * dpr).round() : null;

        if (snap.data != null) {
          return Image.memory(
            snap.data!,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                errorWidget ?? placeholder ?? const SizedBox.shrink(),
          );
        }

        // Not cached → download in background, show network meanwhile.
        _downloadAndCache(url).ignore();

        final webImg = buildCorsBypassImage(url, width: width, height: height, fit: fit);
        if (webImg != null) return webImg;

        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          gaplessPlayback: true,
          loadingBuilder: (_, child, p) => p == null ? child : ph,
          errorBuilder: (_, _, _) =>
              errorWidget ?? placeholder ?? const SizedBox.shrink(),
        );
      },
    );
  }
}