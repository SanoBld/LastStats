// lib/services/image_service.dart
//
// Resolves artwork URLs from Last.fm → iTunes → Deezer → MusicBrainz.
// Downloads and caches image bytes via OfflineImageCache for offline use.
//
// Main entry points:
//   resolveArtist / resolveAlbum / resolveTrack  → URL string (fast, cached)
//   widgetImage(url, ...)                        → offline-capable Widget
//   prefetchBytes(url)                           → background download

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_image_cache.dart';
import 'storage_manager.dart';

class ImageService {
  ImageService._();

  static const _placeholder = '2a96cbd8b46e442fc41c2b86b821562f';
  static const _timeout     = Duration(seconds: 6);
  static const _diskPrefix  = 'imgcache_';
  static const _diskTtlMs   = 7 * 24 * 60 * 60 * 1000;

  // In-memory URL cache (session).
  static final Map<String, String> _mem = {};

  static SharedPreferences? _prefs;
  static bool _diskLoaded = false;

  // ── URL cache (metadata only, not bytes) ──────────────────────────────────

  static Future<void> _ensureDiskCache() async {
    if (_diskLoaded) return;
    _diskLoaded = true;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final k in _prefs!.getKeys()) {
        if (!k.startsWith(_diskPrefix)) continue;
        final raw = _prefs!.getString(k);
        if (raw == null) continue;
        try {
          final e   = jsonDecode(raw) as Map<String, dynamic>;
          final ts  = (e['ts'] as num?)?.toInt() ?? 0;
          final url = (e['url'] as String?) ?? '';
          if (url.isEmpty || (now - ts) > _diskTtlMs) {
            _prefs!.remove(k).ignore();
            continue;
          }
          _mem[k.substring(_diskPrefix.length)] = url;
        } catch (_) { _prefs!.remove(k).ignore(); }
      }
    } catch (_) {}
  }

  static String? _getUrl(String key) => _mem[key];

  static Future<String> _persistUrl(String key, String url) async {
    _mem[key] = url;
    if (url.isEmpty) return url;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(
        '$_diskPrefix$key',
        jsonEncode({'url': url, 'ts': DateTime.now().millisecondsSinceEpoch}),
      );
    } catch (_) {}
    // Kick off background byte download.
    _cacheBytes(url);
    return url;
  }

  static void _cacheBytes(String url) {
    if (url.isEmpty) return;
    OfflineImageCache.imageProvider(url).then((_) {
      StorageManager.enforceQuota().ignore();
    }).ignore();
  }

  // ── Public: resolve URL ───────────────────────────────────────────────────

  static Future<String> resolveArtist(String artist, {String? lastfmUrl}) async {
    if (_ok(lastfmUrl)) { _cacheBytes(lastfmUrl!); return lastfmUrl; }
    await _ensureDiskCache();
    final key = 'artist|$artist';
    final mem = _getUrl(key);
    if (mem != null) return mem;

    final itunes = await _itunesSearch(artist, 'musicArtist', 'artistTerm');
    if (itunes.isNotEmpty) return _persistUrl(key, itunes);

    final deezer = await _deezerArtist(artist);
    if (deezer.isNotEmpty) return _persistUrl(key, deezer);

    return _persistUrl(key, '');
  }

  static Future<String> resolveAlbum(String album, String artist, {String? lastfmUrl}) async {
    if (_ok(lastfmUrl)) { _cacheBytes(lastfmUrl!); return lastfmUrl; }
    await _ensureDiskCache();
    final key = 'album|$artist|$album';
    final mem = _getUrl(key);
    if (mem != null) return mem;

    final itunes = await _itunesSearch('$artist $album', 'album');
    if (itunes.isNotEmpty) return _persistUrl(key, itunes);

    final mb = await _mbAlbum(album, artist);
    if (mb.isNotEmpty) return _persistUrl(key, mb);

    return _persistUrl(key, '');
  }

  static Future<String> resolveTrack(String track, String artist, {String? lastfmUrl}) async {
    if (_ok(lastfmUrl)) { _cacheBytes(lastfmUrl!); return lastfmUrl; }
    await _ensureDiskCache();
    final key = 'track|$artist|$track';
    final mem = _getUrl(key);
    if (mem != null) return mem;

    final itunes = await _itunesSearch('$artist $track', 'song');
    if (itunes.isNotEmpty) return _persistUrl(key, itunes);

    return _persistUrl(key, '');
  }

  // ── Public: widget helper ─────────────────────────────────────────────────

  /// Drop-in replacement for Image.network — uses local cache when offline.
  static Widget widgetImage({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) => OfflineImageCache.image(
        url:         url,
        width:       width,
        height:      height,
        fit:         fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );

  // ── Public: force byte download ───────────────────────────────────────────

  /// Downloads and caches image bytes; enforces storage quota afterwards.
  static Future<void> prefetchBytes(String url) async {
    if (url.isEmpty) return;
    await OfflineImageCache.imageProvider(url);
    await StorageManager.enforceQuota();
  }

  // ── Cache stats ───────────────────────────────────────────────────────────

  static int  get urlCacheSize => _mem.length;
  static void clearUrlCache()  => _mem.clear();

  static Future<void> clearAllCache() async {
    _mem.clear();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_diskPrefix)).toList();
      for (final k in keys) {
        await _prefs!.remove(k);
      }
    } catch (_) {}
    await OfflineImageCache.clear();
  }

  static Future<int> pruneExpired() async {
    int removed = 0;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final now  = DateTime.now().millisecondsSinceEpoch;
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_diskPrefix)).toList();
      for (final k in keys) {
        final raw = _prefs!.getString(k);
        if (raw == null) { await _prefs!.remove(k); removed++; continue; }
        try {
          final e  = jsonDecode(raw) as Map<String, dynamic>;
          final ts = (e['ts'] as num?)?.toInt() ?? 0;
          if ((now - ts) > _diskTtlMs) {
            await _prefs!.remove(k);
            _mem.remove(k.substring(_diskPrefix.length));
            removed++;
          }
        } catch (_) { await _prefs!.remove(k); removed++; }
      }
    } catch (_) {}
    return removed;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _ok(String? url) =>
      url != null && url.isNotEmpty && !url.contains(_placeholder);

  static Future<String> _itunesSearch(String term, String entity, [String? attribute]) async {
    try {
      final params = <String, String>{'term': term, 'entity': entity, 'limit': '1', 'media': 'music'};
      if (attribute != null) params['attribute'] = attribute;
      final res = await http.get(Uri.https('itunes.apple.com', '/search', params)).timeout(_timeout);
      if (res.statusCode != 200) return '';
      final results = (jsonDecode(utf8.decode(res.bodyBytes))['results'] as List?) ?? [];
      if (results.isEmpty) return '';
      final raw = (results.first['artworkUrl100'] ?? '').toString();
      return raw.isEmpty ? '' : raw
          .replaceAll('100x100bb', '3000x3000bb')
          .replaceAll('100x100',   '3000x3000');
    } catch (_) { return ''; }
  }

  static Future<String> _deezerArtist(String artist) async {
    try {
      final res = await http.get(Uri.https('api.deezer.com', '/search/artist', {'q': artist, 'limit': '1'}))
          .timeout(_timeout);
      if (res.statusCode != 200) return '';
      final items = (jsonDecode(utf8.decode(res.bodyBytes))['data'] as List?) ?? [];
      if (items.isEmpty) return '';
      return (items.first['picture_xl'] ?? items.first['picture_big'] ?? '').toString();
    } catch (_) { return ''; }
  }

  static Future<String> _mbAlbum(String album, String artist) async {
    try {
      final searchRes = await http.get(
        Uri.https('musicbrainz.org', '/ws/2/release/', {
          'query': 'release:"$album" AND artist:"$artist"',
          'limit': '1', 'fmt': 'json',
        }),
        headers: {'User-Agent': 'LastStatsMobile/2.0 (contact@laststats.app)'},
      ).timeout(_timeout);
      if (searchRes.statusCode != 200) return '';
      final releases = (jsonDecode(utf8.decode(searchRes.bodyBytes))['releases'] as List?) ?? [];
      if (releases.isEmpty) return '';
      final mbid = (releases.first['id'] ?? '').toString();
      if (mbid.isEmpty) return '';
      final coverRes = await http.get(Uri.https('coverartarchive.org', '/release/$mbid/front')).timeout(_timeout);
      if (coverRes.statusCode == 200 || coverRes.statusCode == 307) {
        final loc = coverRes.headers['location'];
        if (loc != null && loc.isNotEmpty) return loc;
      }
      return 'https://coverartarchive.org/release/$mbid/front-500';
    } catch (_) { return ''; }
  }

  static void debugLog(String msg) {
    assert(() { debugPrint(msg); return true; }());
  }
}

void unawaited(Future<void> f) => f.ignore();