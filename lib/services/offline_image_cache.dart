// lib/services/offline_image_cache.dart
//
// Caches image bytes on disk (native) or IndexedDB (web).
// Metadata tracks last-access time for LRU eviction.
// Provides ImageProvider for offline-capable widgets.
//
// Usage:
//   final provider = await OfflineImageCache.imageProvider(url);
//   Image(image: provider, ...)
//
// Fixes in this version (cache audit):
//   • Metadata loading is memoized (a Completer). Before, `_loaded` was set
//     to true BEFORE the metadata was read, so a second caller during startup
//     saw an empty map and could re-download images and reuse file ids that
//     already existed on disk (overwriting other images' bytes).
//   • The same URL is never downloaded twice at once (in-flight map), and a
//     URL that just failed is not retried on every widget rebuild.
//   • The storage quota is now enforced on EVERY download. Widgets used to
//     call put() without a limit, so only ImageService's own downloads were
//     ever trimmed.
//   • meta.json is written one write at a time, coalesced. Overlapping
//     writes could interleave and corrupt the file; reading an image rewrote
//     the whole file every time (now debounced).
//   • A small RAM cache avoids re-reading the same file from disk on every
//     rebuild (and the placeholder flicker that went with it).
//   • Only responses that really are images are stored.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/skeleton.dart';
import 'storage_manager.dart';
import 'image_sizing.dart';

import 'image_cache_backend_stub.dart'
    if (dart.library.io)   'image_cache_backend_native.dart'
    if (dart.library.html) 'image_cache_backend_web.dart';

// Web-only CORS bypass for image display (no-op stub on native).
import 'web_img_stub.dart'
    if (dart.library.html) 'web_img_web.dart';

import 'package:http/http.dart' as http;
import 'api_http.dart';

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
  static Future<void>? _loading;

  static const _timeout = Duration(seconds: 8);

  // Small RAM cache of decoded-source bytes (LRU), so a rebuild does not hit
  // the disk again. Capped by bytes, not by entry count.
  static final LinkedHashMap<String, Uint8List> _ram = LinkedHashMap();
  static int _ramBytes = 0;
  static const _ramCap = 24 * 1024 * 1024;

  // Downloads currently running, and URLs that failed recently.
  static final Map<String, Future<void>> _inflight = {};
  static final Map<String, int> _failedUntil = {};
  static const _failCooldownMs = 2 * 60 * 1000;

  // ── Metadata persistence ──────────────────────────────────────────────────

  static Future<void> _ensureMeta() {
    if (_loaded) return Future.value();
    return _loading ??= _loadMeta();
  }

  static Future<void> _loadMeta() async {
    try {
      final raw = await ImageCacheBackend.readMeta();
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final entries = (json['e'] as Map<String, dynamic>?) ?? {};
        final loaded = <String, _ImageEntry>{};
        var total = 0;
        var maxId = -1;
        for (final kv in entries.entries) {
          final e = _ImageEntry.fromJson(kv.value as Map<String, dynamic>);
          loaded[kv.key] = e;
          total += e.size;
          final id = int.tryParse(e.fileKey);
          if (id != null && id > maxId) maxId = id;
        }
        _meta
          ..clear()
          ..addAll(loaded);
        _totalBytes = total;
        // Never reuse an id that is already referenced.
        final stored = (json['id'] as num?)?.toInt() ?? 0;
        _nextId = stored > maxId + 1 ? stored : maxId + 1;
      }
    } catch (_) {
      // Unreadable metadata: start empty. Files left on disk are simply
      // overwritten as ids are reused (no meta entry points at them).
    } finally {
      _loaded = true;
    }
  }

  static bool _saving = false;
  static bool _dirty  = false;
  static Timer? _lazySave;

  // One write at a time; writes requested while one is running are merged.
  static Future<void> _saveMeta() async {
    _lazySave?.cancel();
    _lazySave = null;
    _dirty = true;
    if (_saving) return;
    _saving = true;
    try {
      while (_dirty) {
        _dirty = false;
        final map = <String, dynamic>{};
        for (final kv in _meta.entries) {
          map[kv.key] = kv.value.toJson();
        }
        await ImageCacheBackend.writeMeta(jsonEncode({'id': _nextId, 'e': map}));
      }
    } catch (_) {
    } finally {
      _saving = false;
    }
  }

  // Access-time updates are not worth a disk write each: batch them.
  static void _saveMetaLater() {
    if (_lazySave != null) return;
    _lazySave = Timer(const Duration(seconds: 5), () {
      _lazySave = null;
      _saveMeta().ignore();
    });
  }

  // ── RAM cache ─────────────────────────────────────────────────────────────

  static Uint8List? _ramGet(String url) {
    final b = _ram.remove(url);
    if (b != null) _ram[url] = b;
    return b;
  }

  static void _ramPut(String url, Uint8List bytes) {
    if (bytes.length > _ramCap ~/ 4) return; // never let one image flush it all
    final old = _ram.remove(url);
    if (old != null) _ramBytes -= old.length;
    _ram[url] = bytes;
    _ramBytes += bytes.length;
    while (_ramBytes > _ramCap && _ram.isNotEmpty) {
      final k = _ram.keys.first;
      _ramBytes -= _ram.remove(k)!.length;
    }
  }

  static void _ramDrop(String url) {
    final b = _ram.remove(url);
    if (b != null) _ramBytes -= b.length;
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

  /// Bytes of [url] — from the cache when present, otherwise downloaded once
  /// and stored. Used where the app needs the raw bytes (dominant-colour
  /// extraction) so it does not download an image that is already cached.
  static Future<Uint8List?> bytesFor(String url) async {
    if (url.isEmpty) return null;
    await _ensureMeta();
    final cached = await _getBytes(url);
    if (cached != null) return cached;
    await _downloadAndCache(url);
    return _getBytes(url);
  }

  /// Same as [bytesFor] but shaped as an http.Response, for call sites that
  /// used to download the image a second time just to read its colours.
  static Future<http.Response> responseFor(String url) async {
    final b = await bytesFor(url);
    return b == null ? http.Response('', 404) : http.Response.bytes(b, 200);
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  static Future<Uint8List?> _getBytes(String url) async {
    final entry = _meta[url];
    if (entry == null) return null;

    var bytes = _ramGet(url);
    bytes ??= await ImageCacheBackend.read(entry.fileKey);
    if (bytes == null) {
      // File gone — remove from meta.
      _totalBytes -= entry.size;
      _meta.remove(url);
      _saveMetaLater();
      return null;
    }
    _ramPut(url, bytes);

    // Update access time for LRU (the entry may have been replaced meanwhile).
    final current = _meta[url];
    if (current != null) {
      _meta[url] = _ImageEntry(
        fileKey: current.fileKey,
        atime:   DateTime.now().millisecondsSinceEpoch,
        size:    current.size,
      );
      _saveMetaLater();
    }
    return bytes;
  }

  // ── Write (with quota enforcement) ───────────────────────────────────────

  static Future<void> put(String url, Uint8List bytes, {int maxBytes = 0}) async {
    await _ensureMeta();

    // A single image larger than the whole quota is never stored — checked
    // first so it does not evict everything else for nothing.
    if (maxBytes > 0 && bytes.length > maxBytes) return;

    // Update existing entry.
    if (_meta.containsKey(url)) {
      final old = _meta[url]!;
      // File first, metadata after: a reader must never see an entry whose
      // file is not on disk yet.
      await ImageCacheBackend.write(old.fileKey, bytes);
      final cur = _meta[url];
      if (cur == null) return; // evicted while writing
      _totalBytes += bytes.length - cur.size;
      _meta[url] = _ImageEntry(
        fileKey: cur.fileKey,
        atime:   DateTime.now().millisecondsSinceEpoch,
        size:    bytes.length,
      );
      _ramPut(url, bytes);
      await _saveMeta();
      return;
    }

    // Enforce quota before adding.
    if (maxBytes > 0) {
      final overflow = _totalBytes + bytes.length - maxBytes;
      if (overflow > 0) await evictLru(overflow);
    }

    final key = '${_nextId++}';
    await ImageCacheBackend.write(key, bytes);
    if (_meta.containsKey(url)) {
      // Another download of the same URL finished first: drop our copy.
      await ImageCacheBackend.delete(key);
      return;
    }
    _meta[url] = _ImageEntry(
      fileKey: key,
      atime:   DateTime.now().millisecondsSinceEpoch,
      size:    bytes.length,
    );
    _totalBytes += bytes.length;
    _ramPut(url, bytes);
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
      _ramDrop(kv.key);
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
    _lazySave?.cancel();
    _lazySave = null;
    _meta.clear();
    _ram.clear();
    _ramBytes   = 0;
    _totalBytes = 0;
    _nextId     = 0;
    _failedUntil.clear();
    // Wait for a metadata write in progress, then wipe the backend and
    // mark the (now empty) metadata as loaded.
    while (_saving) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    await ImageCacheBackend.clearAll();
    _loading = null;
    _loaded  = true;
  }

  // ── Background download ───────────────────────────────────────────────────

  static Future<void> _downloadAndCache(String url) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final blockedUntil = _failedUntil[url];
    if (blockedUntil != null) {
      if (blockedUntil > now) return Future.value();
      _failedUntil.remove(url);
    }
    final running = _inflight[url];
    if (running != null) return running;
    final f = _download(url).whenComplete(() => _inflight.remove(url));
    _inflight[url] = f;
    return f;
  }

  static Future<void> _download(String url) async {
    var ok = false;
    try {
      await _ensureMeta();
      if (_meta.containsKey(url)) { ok = true; return; }
      final res = await ApiHttp.get(Uri.parse(url)).timeout(_timeout);
      final type = (res.headers['content-type'] ?? '').toLowerCase();
      final looksLikeImage = type.isEmpty ||
          type.startsWith('image/') ||
          type.startsWith('application/octet-stream') ||
          type.startsWith('binary/');
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty && looksLikeImage) {
        await put(url, res.bodyBytes, maxBytes: StorageManager.maxBytes);
        ok = true;
      }
    } catch (_) {
    } finally {
      if (!ok) {
        _failedUntil[url] =
            DateTime.now().millisecondsSinceEpoch + _failCooldownMs;
        if (_failedUntil.length > 2000) {
          final now = DateTime.now().millisecondsSinceEpoch;
          _failedUntil.removeWhere((_, t) => t < now);
        }
      }
    }
  }

  // ── Widget helper ─────────────────────────────────────────────────────────

  static Widget _memoryImage(
    BuildContext context,
    Uint8List data, {
    double? width,
    double? height,
    required BoxFit fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Decode at the actual display size (× device pixel ratio) instead
    // of the source's full resolution — a 40dp list thumbnail doesn't
    // need a 3000×3000 bitmap sitting in memory. Only applied when a
    // display size was actually requested; omitted otherwise (e.g. the
    // detail sheet's full-size hero image still wants native quality).
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth  = width  != null ? (width * dpr).round()  : null;
    final cacheHeight = height != null ? (height * dpr).round() : null;
    return Image.memory(
      data,
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

  // Returns a widget that shows the cached image or falls back to network.
  static Widget image({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Download the resolution that matches the on-screen size.
    final side = (width != null && width.isFinite ? width : 0.0) > (height != null && height.isFinite ? height : 0.0)
        ? width! : (height != null && height.isFinite ? height : 0.0);
    if (side > 0) {
      final dpr = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
          ? WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio : 2.0;
      url = sizedImageUrl(url, side, dpr);
    }
    final ph = placeholder ?? M3ImagePlaceholder(width: width, height: height);
    if (url.isEmpty) return placeholder ?? const SizedBox.shrink();

    // Fast path: already in RAM → no FutureBuilder, no placeholder flash.
    final hot = _loaded && _meta.containsKey(url) ? _ramGet(url) : null;
    if (hot != null) {
      return Builder(builder: (context) => _memoryImage(
            context, hot,
            width: width, height: height, fit: fit,
            placeholder: placeholder, errorWidget: errorWidget,
          ));
    }

    // Cache checked FIRST (offline or online) — network is only a fallback.
    return FutureBuilder<Uint8List?>(
      future: _ensureMeta().then((_) => _getBytes(url)),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return ph;
        }

        if (snap.data != null) {
          return _memoryImage(
            context, snap.data!,
            width: width, height: height, fit: fit,
            placeholder: placeholder, errorWidget: errorWidget,
          );
        }

        _downloadAndCache(url).ignore();

        final dpr = MediaQuery.of(context).devicePixelRatio;
        final cacheWidth  = width  != null ? (width * dpr).round()  : null;
        final cacheHeight = height != null ? (height * dpr).round() : null;

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
