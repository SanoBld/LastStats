// lib/services/image_service.dart
//
// Resolves artwork URLs. Priority (best first, Last.fm = last resort because
// its artist images are a grey star since 2019 and albums are only ~300px):
//   Artist: Deezer > YouTube Music > TheAudioDB > MusicBrainz > Wikipedia > Last.fm
//   Album : iTunes > Deezer > YouTube Music > CoverArtArchive > TheAudioDB > Wikipedia > Last.fm
//   Track : iTunes > Deezer > YouTube Music > TheAudioDB > album cover > Wikipedia > Last.fm
// The first 3 sources run in parallel (result keeps priority order).
// Downloads and caches image bytes via OfflineImageCache for offline use.
//
// Main entry points:
//   resolveArtist / resolveAlbum / resolveTrack  → URL string (fast, cached)
//   widgetImage(url, ...)                        → offline-capable Widget
//   prefetchBytes(url)                           → background download

import 'dart:convert';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'api_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_image_cache.dart';
import 'data_cache.dart';
import 'storage_manager.dart';
import '../l10n/extra_strings.dart';
import 'image_sizing.dart';

class _S {
  final String name;
  final Future<String> Function() run;
  const _S(this.name, this.run);
}

class ImageService {
  ImageService._();

  static const _placeholder = '2a96cbd8b46e442fc41c2b86b821562f';
  static const _timeout     = Duration(seconds: 6);
  // Hard cap for one full lookup, so a loading spinner never lasts forever.
  static const _maxResolve  = Duration(seconds: 12);
  static const _diskPrefix  = 'imgcache_';
  static const _diskTtlMs   = 7 * 24 * 60 * 60 * 1000;

  // In-memory URL cache (session).
  // BUG FIX: this used to be a plain Map with no size limit. On a long
  // session (lots of scrolling through history/charts/search), every
  // artist/album/track ever looked up stayed in RAM forever — this was
  // one of the causes of the app using more and more memory the longer
  // it stayed open. LinkedHashMap + a hard cap turns it into a simple
  // LRU cache: oldest-used entries are dropped once the cap is hit.
  static final Map<String, String> _mem = {};
  // Which source produced each cache key's URL — for the small attribution
  // label shown under artwork. Keyed by the same `key` used in `_mem`.
  static final Map<String, String> _sourceOf = {};
  // Max entries kept in RAM at once. Disk cache (SharedPreferences) still
  // has everything, so nothing is lost — it just gets re-read from disk
  // instead of staying in memory forever.
  static const int _memCap = 4000;

  // Marks [key] as recently used and trims the cache if it grew past the
  // cap. Call this every time an entry is read or written.
  static void _touch(String key) {
    final url = _mem.remove(key);
    if (url != null) _mem[key] = url; // re-insert = moves to "most recent"
    final src = _sourceOf.remove(key);
    if (src != null) _sourceOf[key] = src;
    while (_mem.length > _memCap) {
      final oldest = _mem.keys.first;
      _mem.remove(oldest);
      _sourceOf.remove(oldest);
    }
  }

  static SharedPreferences? _prefs;
  static Future<void>? _diskLoading;

  // Artist/album/track lookups that found nothing (or failed because a
  // source was rate-limited / offline). Remembered for a short time only:
  // before, an empty result was cached for the whole session, so one
  // transient failure meant "no artwork" until the app was restarted.
  static final Map<String, int> _negUntil = {};
  static const _negTtlMs = 10 * 60 * 1000;

  static bool _isNegative(String key) {
    final t = _negUntil[key];
    if (t == null) return false;
    if (t > DateTime.now().millisecondsSinceEpoch) return true;
    _negUntil.remove(key);
    return false;
  }

  // One lookup at a time per key: a list showing the same artist 20 times
  // used to run the whole source chain 20 times in parallel.
  static final Map<String, Future<String>> _pending = {};
  static Future<String> _once(String key, Future<String> Function() run) {
    final running = _pending[key];
    if (running != null) return running;
    final f = run().whenComplete(() => _pending.remove(key));
    _pending[key] = f;
    return f;
  }

  // ── URL cache (metadata only, not bytes) ──────────────────────────────────

  static Future<void> _ensureDiskCache() => _diskLoading ??= _loadDiskCache();

  static Future<void> _loadDiskCache() async {
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
          final src = (e['source'] as String?) ?? '';
          // Entries cached before source-tracking existed have no 'source'
          // field — rather than show a guessed/fake source for those, drop
          // them so they get re-resolved (and properly tagged) next time.
          if (url.isEmpty || src.isEmpty || url.contains(_placeholder) || (now - ts) > _diskTtlMs) {
            _prefs!.remove(k).ignore();
            continue;
          }
          _mem[k.substring(_diskPrefix.length)] = url;
          _sourceOf[k.substring(_diskPrefix.length)] = src;
        } catch (_) { _prefs!.remove(k).ignore(); }
      }
    } catch (_) {}
  }

  static String? _getUrl(String key) {
    final url = _mem[key];
    if (url != null) _touch(key); // mark as recently used, keep it in RAM
    return url;
  }

  static Future<String> _persistUrl(String key, String url, [String source = '']) async {
    if (url.isEmpty) {
      _negUntil[key] = DateTime.now().millisecondsSinceEpoch + _negTtlMs;
      if (_negUntil.length > 2000) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _negUntil.removeWhere((_, t) => t < now);
      }
      return url;
    }
    _negUntil.remove(key);
    _mem[key] = url;
    if (source.isNotEmpty) _sourceOf[key] = source;
    _touch(key);
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(
        '$_diskPrefix$key',
        jsonEncode({'url': url, 'ts': DateTime.now().millisecondsSinceEpoch, 'source': source}),
      );
    } catch (_) {}
    // Background download at list size (bigger sizes load on demand).
    _cacheBytes(sizedImageUrl(url, 120, 2.0));
    return url;
  }

  /// Human-readable, translated name of the source that provided the
  /// artwork currently cached for this artist/album/track — for the small
  /// gray attribution label shown under artwork. Returns '' if unknown.
  static String sourceLabel(String type, String artist, {String album = '', String track = ''}) {
    final key = switch (type) {
      'artist' => 'artist|$artist',
      'album'  => 'album|$artist|$album',
      'track'  => 'track|$artist|$track',
      _ => '',
    };
    final raw = _sourceOf[key];
    if (raw == null || raw.isEmpty) return '';
    return _sourceDisplayNames.containsKey(raw) ? tx('img_src_$raw') : '';
  }

  /// Bare brand name (e.g. "YouTube Music"), no "Source:" prefix — for
  /// composing into a longer label like "Artist · YouTube Music".
  static String sourceName(String type, String artist, {String album = '', String track = ''}) {
    final key = switch (type) {
      'artist' => 'artist|$artist',
      'album'  => 'album|$artist|$album',
      'track'  => 'track|$artist|$track',
      _ => '',
    };
    return _sourceDisplayNames[_sourceOf[key]] ?? '';
  }

  static const Map<String, String> _sourceDisplayNames = {
    'lastfm': 'Last.fm', 'ytmusic': 'YouTube Music', 'itunes': 'iTunes',
    'deezer': 'Deezer', 'audiodb': 'TheAudioDB', 'musicbrainz': 'MusicBrainz',
    'wikipedia': 'Wikipedia',
  };

  

  static void _cacheBytes(String url) {
    if (url.isEmpty) return;
    OfflineImageCache.imageProvider(url).then((_) {
      StorageManager.enforceQuota().ignore();
    }).ignore();
  }

  // ── Public: resolve URL ───────────────────────────────────────────────────

  static Future<String> resolveArtist(String artist, {String? lastfmUrl}) =>
      _once('artist|$artist', () => _resolveArtist(artist, lastfmUrl: lastfmUrl))
          .timeout(_maxResolve, onTimeout: () => _ok(lastfmUrl) ? lastfmUrl! : '');

  static Future<String> _resolveArtist(String artist, {String? lastfmUrl}) async {
    final key = 'artist|$artist';
    await _ensureDiskCache();
    final mem = _getUrl(key);
    if (mem != null) return mem;
    if (_isNegative(key)) return '';
    if (DataCache.strictOffline) return _ok(lastfmUrl) ? lastfmUrl! : '';

    final hit = await _pick([
      _S('deezer',  () => _deezerArtist(artist)),
      _S('ytmusic', () => _ytMusicSearch(artist, 'artist', expectArtist: artist)),
      _S('audiodb', () => _audioDbArtist(artist)),
    ], [
      _S('musicbrainz', () => _mbArtistImage(artist)),
      _S('wikipedia',   () => _wikipediaImage(artist, expectName: artist)),
    ]);
    if (hit != null) return _persistUrl(key, hit.value, hit.key);
    if (_ok(lastfmUrl)) return _persistUrl(key, lastfmUrl!, 'lastfm');
    return _persistUrl(key, '');
  }

  static Future<String> resolveAlbum(String album, String artist, {String? lastfmUrl}) =>
      _once('album|$artist|$album', () => _resolveAlbum(album, artist, lastfmUrl: lastfmUrl))
          .timeout(_maxResolve, onTimeout: () => _ok(lastfmUrl) ? lastfmUrl! : '');

  static Future<String> _resolveAlbum(String album, String artist, {String? lastfmUrl}) async {
    final key = 'album|$artist|$album';
    await _ensureDiskCache();
    final mem = _getUrl(key);
    if (mem != null) return mem;
    if (_isNegative(key)) return '';
    if (DataCache.strictOffline) return _ok(lastfmUrl) ? lastfmUrl! : '';

    final hit = await _pick([
      _S('itunes',  () => _itunesSearch('$artist $album', 'album', null, artist, album)),
      _S('deezer',  () => _deezerAlbum(album, artist)),
      _S('ytmusic', () => _ytMusicSearch('$artist $album', 'album', expectArtist: artist, expectTitle: album)),
    ], [
      _S('musicbrainz', () => _mbAlbum(album, artist)),
      _S('audiodb',     () => _audioDbAlbum(album, artist)),
      _S('wikipedia',   () => _wikipediaImage('$artist $album album', expectName: album)),
    ]);
    if (hit != null) return _persistUrl(key, hit.value, hit.key);
    if (_ok(lastfmUrl)) return _persistUrl(key, lastfmUrl!, 'lastfm');
    return _persistUrl(key, '');
  }

  static Future<String> resolveTrack(String track, String artist,
          {String? lastfmUrl, String album = ''}) =>
      _once('track|$artist|$track',
          () => _resolveTrack(track, artist, lastfmUrl: lastfmUrl, album: album))
          .timeout(_maxResolve, onTimeout: () => _ok(lastfmUrl) ? lastfmUrl! : '');

  static Future<String> _resolveTrack(String track, String artist,
      {String? lastfmUrl, String album = ''}) async {
    final key = 'track|$artist|$track';
    await _ensureDiskCache();
    final mem = _getUrl(key);
    if (mem != null) return mem;
    if (_isNegative(key)) return '';
    if (DataCache.strictOffline) return _ok(lastfmUrl) ? lastfmUrl! : '';

    final hit = await _pick([
      _S('itunes',  () => _itunesSearch('$artist $track', 'song', null, artist, track)),
      _S('deezer',  () => _deezerTrack(track, artist)),
      _S('ytmusic', () => _ytMusicSearch('$artist $track', 'song', expectArtist: artist, expectTitle: track)),
    ], [
      _S('audiodb', () => _audioDbTrack(track, artist)),
      if (album.isNotEmpty) _S('musicbrainz', () => _mbAlbum(album, artist)),
      _S('wikipedia', () => _wikipediaImage('$artist $track song', expectName: track)),
    ]);
    if (hit != null) return _persistUrl(key, hit.value, hit.key);
    if (_ok(lastfmUrl)) return _persistUrl(key, lastfmUrl!, 'lastfm');
    return _persistUrl(key, '');
  }

  // ── Source priority helper ────────────────────────────────────────────────
  // [fast] sources start together (parallel) but are read in priority order;
  // [slow] ones (rate-limited MusicBrainz, Wikipedia) only run if all failed.
  static Future<MapEntry<String, String>?> _pick(List<_S> fast, List<_S> slow) async {
    final running = [for (final e in fast) e.run().catchError((_) => '')];
    for (var i = 0; i < fast.length; i++) {
      final u = await running[i];
      if (_ok(u)) return MapEntry(fast[i].name, u);
    }
    for (final e in slow) {
      final u = await e.run().catchError((_) => '');
      if (_ok(u)) return MapEntry(e.name, u);
    }
    return null;
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
  static void clearUrlCache()  { _mem.clear(); _sourceOf.clear(); _negUntil.clear(); }

  static Future<void> clearAllCache() async {
    _mem.clear();
    _sourceOf.clear();
    _negUntil.clear();
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
            _sourceOf.remove(k.substring(_diskPrefix.length));
            removed++;
          }
        } catch (_) { await _prefs!.remove(k); removed++; }
      }
    } catch (_) {}
    return removed;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _ok(String? url) =>
      url != null && url.isNotEmpty && !url.contains(_placeholder) && !_deezerEmpty(url);

  // Deezer serves a grey default image when it has no real picture.
  static bool _deezerEmpty(String u) =>
      u.contains('dzcdn.net') && (u.contains('//1000x1000') || u.contains('/images/artist//') ||
      u.contains('/images/cover//') || u.contains('d41d8cd98f00b204e9800998ecf8427e'));

  /// Artwork URL rewritten for the size it is shown at (logical px).
  static String sized(String url, double logicalPx, double dpr) =>
      sizedImageUrl(url, logicalPx, dpr);

  // Normalizes a name for loose comparison: lowercase, strips diacritics,
  // drops a leading "the/a/le/la/les", keeps only letters/digits.
  static String _normalize(String s) {
    var n = s.toLowerCase().trim();
    const accents = 'àâäáãåèêëéìîïíòôöóõùûüúñçÀÂÄÁÃÅÈÊËÉÌÎÏÍÒÔÖÓÕÙÛÜÚÑÇ';
    const plain   = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC';
    for (var i = 0; i < accents.length; i++) {
      n = n.replaceAll(accents[i], plain[i]);
    }
    n = n.replaceFirst(RegExp(r'^(the|a|le|la|les)\s+'), '');
    return n.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // Loose "is this actually about what we searched for" check — used to
  // reject mismatched results from third-party sources (the cause of
  // unrelated images showing up) rather than blindly trusting whatever
  // each API returns first.
  static bool _similar(String expected, String candidate) {
    final a = _normalize(expected);
    final b = _normalize(candidate);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final shorter = a.length <= b.length ? a : b;
    final longer  = a.length <= b.length ? b : a;
    if (shorter.length >= 4 && longer.contains(shorter)) return true;
    return false;
  }

  // Searches YouTube Music. No public API exists for this — this hits the
  // same unofficial internal endpoint YouTube Music's own web player uses
  // (the one ytmusicapi/InnerTune/Metrolist rely on). It's not documented
  // or guaranteed by Google, so it can break without warning; iTunes/Deezer/
  // MusicBrainz below stay as solid fallbacks either way.
  //
  // Fixed after checking Metrolist's source: the actual request-building
  // code lives in an external submodule they don't ship in exports, so it
  // couldn't be copied directly — but their *response models* (included)
  // confirmed two real bugs here: missing API key/client headers (which was
  // silently failing every request — no logged error, just an empty
  // result), and only handling list results while an artist search's "top
  // result" comes back as a different JSON shape (a single "card", not a
  // list) that was never checked at all.
  static const _ytmApiKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';
  static const _ytmFilters = {
    'artist': 'EgWKAQIgAWoKEAMQBBAJEAoQBQ%3D%3D',
    'album':  'EgWKAQIYAWoKEAMQBBAJEAoQBQ%3D%3D',
    'song':   'EgWKAQIIAWoKEAMQBBAJEAoQBQ%3D%3D',
  };

  static Future<String> _ytMusicSearch(
    String term,
    String type, {
    String? expectArtist,
    String? expectTitle,
  }) async {
    try {
      final res = await ApiHttp.post(
        Uri.https('music.youtube.com', '/youtubei/v1/search', {'key': _ytmApiKey}),
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'https://music.youtube.com',
          'Referer': 'https://music.youtube.com/',
          'X-YouTube-Client-Name': '67',
          'X-YouTube-Client-Version': '1.20240101.01.00',
          // Google's edge servers reject requests without a browser-like UA.
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
              'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20240101.01.00',
              'hl': 'en',
              'gl': 'US',
            }
          },
          'query': term,
          'params': _ytmFilters[type],
        }),
      ).timeout(_timeout);
      if (res.statusCode != 200) {
        debugLog('[ytmusic] HTTP ${res.statusCode} for "$term" ($type)');
        return '';
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final sections = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]
          ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      if (sections == null) {
        debugLog('[ytmusic] no sections in response for "$term" — response shape may have changed');
        return '';
      }

      for (final section in sections) {
        // Artist searches usually surface a single "top result" card first —
        // a different shape than the regular list, and it was never checked.
        final card = section['musicCardShelfRenderer'];
        if (card != null) {
          final title = card['title']?['runs']?[0]?['text']?.toString() ?? '';
          final subtitle = card['subtitle']?['runs']?[0]?['text']?.toString() ?? '';
          final match = expectArtist == null ||
              _similar(expectArtist, type == 'artist' ? title : subtitle);
          if (match && (expectTitle == null || _similar(expectTitle, title))) {
            final url = _bestThumbnail(card['thumbnail']);
            if (url.isNotEmpty) return url;
          }
        }

        final items = section['musicShelfRenderer']?['contents'] as List?;
        if (items == null || items.isEmpty) continue;
        final item = items.first['musicResponsiveListItemRenderer'];
        if (item == null) continue;

        // First flex column = title (song/album) or artist name.
        final flexCols = item['flexColumns'] as List?;
        final title = flexCols?[0]?['musicResponsiveListItemFlexColumnRenderer']
            ?['text']?['runs']?[0]?['text']?.toString() ?? '';
        String subtitleArtist = '';
        if (flexCols != null && flexCols.length > 1) {
          final runs = flexCols[1]['musicResponsiveListItemFlexColumnRenderer']
              ?['text']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) subtitleArtist = runs.first['text']?.toString() ?? '';
        }

        if (expectArtist != null &&
            !_similar(expectArtist, type == 'artist' ? title : subtitleArtist)) {
          continue;
        }
        if (expectTitle != null && !_similar(expectTitle, title)) continue;

        final url = _bestThumbnail(item['thumbnail']);
        if (url.isNotEmpty) return url;
      }
      debugLog('[ytmusic] no matching result for "$term" ($type, expectArtist=$expectArtist, expectTitle=$expectTitle)');
      return '';
    } catch (e) {
      debugLog('[ytmusic] exception for "$term": $e');
      return '';
    }
  }

  // Mirrors Metrolist's ThumbnailRenderer.getThumbnailUrl() fallback chain:
  // regular thumbnail → animated thumbnail's backup → cropped-square variant.
  static String _bestThumbnail(dynamic thumbnailRenderer) {
    if (thumbnailRenderer == null) return '';
    final direct = thumbnailRenderer['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
    final animated = thumbnailRenderer['musicAnimatedThumbnailRenderer']
        ?['backupRenderer']?['thumbnail']?['thumbnails'] as List?;
    final cropped = thumbnailRenderer['croppedSquareThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
    final thumbs = direct ?? animated ?? cropped;
    if (thumbs == null || thumbs.isEmpty) return '';
    final raw = (thumbs.last['url'] ?? '').toString();
    if (raw.isEmpty) return '';
    return _upsizeYtThumbnail(raw);
  }

  // Bumps a YT thumbnail URL's resolution while keeping its original aspect
  // ratio — forcing a fixed w=h square (the old behavior) stretched any
  // non-square source (artist photos, banners) into a distorted square.
  static String _upsizeYtThumbnail(String url) {
    final m = RegExp(r'=w(\d+)-h(\d+)').firstMatch(url);
    if (m == null) return url;
    final w = int.tryParse(m.group(1)!) ?? 0;
    final h = int.tryParse(m.group(2)!) ?? 0;
    if (w <= 0 || h <= 0) return url;
    final scale = 1200 / (w > h ? w : h);
    final newW = (w * scale).round();
    final newH = (h * scale).round();
    return url.replaceFirst(RegExp(r'=w\d+-h\d+.*$'), '=w$newW-h$newH');
  }

  // Searches iTunes and only returns artwork if the result actually matches
  // who/what we asked for (expectArtist / expectTitle) — avoids grabbing the
  // first loosely-related hit when the catalog has an ambiguous match.
  static Future<String> _itunesSearch(
    String term,
    String entity, [
    String? attribute,
    String? expectArtist,
    String? expectTitle,
  ]) async {
    try {
      final params = <String, String>{'term': term, 'entity': entity, 'limit': '1', 'media': 'music'};
      if (attribute != null) params['attribute'] = attribute;
      final res = await ApiHttp.get(Uri.https('itunes.apple.com', '/search', params)).timeout(_timeout);
      if (res.statusCode != 200) return '';
      final results = (jsonDecode(utf8.decode(res.bodyBytes))['results'] as List?) ?? [];
      if (results.isEmpty) return '';
      final item = results.first as Map<String, dynamic>;

      if (expectArtist != null && !_similar(expectArtist, (item['artistName'] ?? '').toString())) return '';
      if (expectTitle != null) {
        final titleField = entity == 'song' ? 'trackName' : 'collectionName';
        if (!_similar(expectTitle, (item[titleField] ?? '').toString())) return '';
      }

      final raw = (item['artworkUrl100'] ?? '').toString();
      return raw.isEmpty ? '' : raw
          .replaceAll('100x100bb', '3000x3000bb')
          .replaceAll('100x100',   '3000x3000');
    } catch (_) { return ''; }
  }

  static Future<String> _deezerArtist(String artist) async {
    try {
      final res = await ApiHttp.get(Uri.https('api.deezer.com', '/search/artist', {'q': artist, 'limit': '1'}))
          .timeout(_timeout);
      if (res.statusCode != 200) return '';
      final items = (jsonDecode(utf8.decode(res.bodyBytes))['data'] as List?) ?? [];
      if (items.isEmpty) return '';
      final item = items.first;
      if (!_similar(artist, (item['name'] ?? '').toString())) return '';
      final pic = (item['picture_xl'] ?? item['picture_big'] ?? '').toString();
      // Deezer sends a grey placeholder when it has no real photo
      // (empty hash in the path). Treat it as "no image".
      if (pic.contains('/artist//') || pic.contains('d41d8cd98f00b204e9800998ecf8427e')) return '';
      return pic;
    } catch (_) { return ''; }
  }

  static Future<String> _deezerAlbum(String album, String artist) async {
    try {
      final res = await ApiHttp.get(Uri.https('api.deezer.com', '/search/album', {'q': '$artist $album', 'limit': '1'}))
          .timeout(_timeout);
      if (res.statusCode != 200) return '';
      final items = (jsonDecode(utf8.decode(res.bodyBytes))['data'] as List?) ?? [];
      if (items.isEmpty) return '';
      final item = items.first;
      if (!_similar(album, (item['title'] ?? '').toString())) return '';
      return (item['cover_xl'] ?? item['cover_big'] ?? '').toString();
    } catch (_) { return ''; }
  }

  // Track search response embeds the parent album object with cover URLs.
  static Future<String> _deezerTrack(String track, String artist) async {
    try {
      final res = await ApiHttp.get(Uri.https('api.deezer.com', '/search/track', {'q': '$artist $track', 'limit': '1'}))
          .timeout(_timeout);
      if (res.statusCode != 200) return '';
      final items = (jsonDecode(utf8.decode(res.bodyBytes))['data'] as List?) ?? [];
      if (items.isEmpty) return '';
      final item = items.first;
      if (!_similar(track, (item['title'] ?? '').toString())) return '';
      final album = item['album'] as Map<String, dynamic>?;
      return (album?['cover_xl'] ?? album?['cover_big'] ?? '').toString();
    } catch (_) { return ''; }
  }

  static Future<String> _audioDbAlbum(String album, String artist) async {
    try {
      final res = await ApiHttp
          .get(Uri.https('www.theaudiodb.com', '/api/v1/json/123/searchalbum.php', {'s': artist, 'a': album}))
          .timeout(_timeout);
      if (res.statusCode != 200) return '';
      final albums = (jsonDecode(utf8.decode(res.bodyBytes))['album'] as List?) ?? [];
      if (albums.isEmpty) return '';
      final item = albums.first;
      if (!_similar(album, (item['strAlbum'] ?? '').toString())) return '';
      return (item['strAlbumThumb'] ?? '').toString();
    } catch (_) { return ''; }
  }

  // Track-level art is rare on TheAudioDB (mostly filled for music videos),
  // best-effort only — empty result just falls through to the next source.
  static Future<String> _audioDbTrack(String track, String artist) async {
    try {
      final res = await ApiHttp
          .get(Uri.https('www.theaudiodb.com', '/api/v1/json/123/searchtrack.php', {'s': artist, 't': track}))
          .timeout(_timeout);
      if (res.statusCode != 200) return '';
      final tracks = (jsonDecode(utf8.decode(res.bodyBytes))['track'] as List?) ?? [];
      if (tracks.isEmpty) return '';
      final item = tracks.first;
      if (!_similar(track, (item['strTrack'] ?? '').toString())) return '';
      return (item['strTrackThumb'] ?? '').toString();
    } catch (_) { return ''; }
  }

  // TheAudioDB — keyless public test key. No CORS support, so this only
  // works on native builds (skipped silently on web, caught by try/catch).
  static Future<String> _audioDbArtist(String artist) async {
    try {
      final res = await ApiHttp
          .get(Uri.https('www.theaudiodb.com', '/api/v1/json/123/search.php', {'s': artist}))
          .timeout(_timeout);
      if (res.statusCode != 200) return '';
      final artists = (jsonDecode(utf8.decode(res.bodyBytes))['artists'] as List?) ?? [];
      if (artists.isEmpty) return '';
      final a = artists.first;
      if (!_similar(artist, (a['strArtist'] ?? '').toString())) return '';
      return (a['strArtistThumb'] ?? a['strArtistFanart'] ?? '').toString();
    } catch (_) { return ''; }
  }

  // MusicBrainz curated "image" relation → resolved to a direct file URL via
  // Wikimedia Commons. Freely licensed and CORS-safe (works on web too).
  static Future<String> _mbArtistImage(String artist) async {
    try {
      final searchRes = await ApiHttp.get(
        Uri.https('musicbrainz.org', '/ws/2/artist/', {
          'query': 'artist:"$artist"', 'limit': '1', 'fmt': 'json',
        }),
        headers: {'User-Agent': 'LastStats/2.0 (contact@laststats.app)'},
      ).timeout(_timeout);
      if (searchRes.statusCode != 200) return '';
      final found = (jsonDecode(utf8.decode(searchRes.bodyBytes))['artists'] as List?) ?? [];
      if (found.isEmpty) return '';
      final candidate = found.first;
      if (!_similar(artist, (candidate['name'] ?? '').toString())) return '';
      final mbid = (candidate['id'] ?? '').toString();
      if (mbid.isEmpty) return '';

      final relRes = await ApiHttp.get(
        Uri.https('musicbrainz.org', '/ws/2/artist/$mbid', {'inc': 'url-rels', 'fmt': 'json'}),
        headers: {'User-Agent': 'LastStats/2.0 (contact@laststats.app)'},
      ).timeout(_timeout);
      if (relRes.statusCode != 200) return '';
      final rels = (jsonDecode(utf8.decode(relRes.bodyBytes))['relations'] as List?) ?? [];
      final imgRel = rels.firstWhere((r) => r['type'] == 'image', orElse: () => null);
      final pageUrl = (imgRel?['url']?['resource'] ?? '').toString();
      if (pageUrl.isEmpty) return '';

      // pageUrl is a Commons "File:" page — resolve to the actual image URL.
      final title = Uri.decodeFull(pageUrl.split('/wiki/').last);
      final fileRes = await ApiHttp.get(Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query', 'titles': title, 'prop': 'imageinfo',
        'iiprop': 'url', 'format': 'json', 'origin': '*',
      })).timeout(_timeout);
      if (fileRes.statusCode != 200) return '';
      final pages = (jsonDecode(utf8.decode(fileRes.bodyBytes))['query']?['pages'] as Map?) ?? {};
      for (final p in pages.values) {
        final info = (p['imageinfo'] as List?) ?? [];
        if (info.isNotEmpty) return (info.first['url'] ?? '').toString();
      }
      return '';
    } catch (_) { return ''; }
  }

  // Wikipedia full-text search → page thumbnail. Broad coverage but the
  // riskiest source for false positives (a plain text search can land on a
  // totally unrelated page) — validated against the page title and, when
  // available, its short description before the thumbnail is trusted.
  static Future<String> _wikipediaImage(String query, {required String expectName}) async {
    try {
      final res = await ApiHttp.get(Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'query', 'generator': 'search', 'gsrsearch': query,
        'gsrlimit': '1', 'prop': 'pageimages|pageterms', 'piprop': 'thumbnail',
        'pithumbsize': '600', 'wbptterms': 'description',
        'format': 'json', 'origin': '*',
      })).timeout(_timeout);
      if (res.statusCode != 200) return '';
      final pages = (jsonDecode(utf8.decode(res.bodyBytes))['query']?['pages'] as Map?) ?? {};
      for (final p in pages.values) {
        final thumb = p['thumbnail']?['source'];
        if (thumb == null) continue;

        final title = (p['title'] ?? '').toString();
        if (!_similar(expectName, title)) continue; // page isn't about what we searched

        final descriptions = (p['terms']?['description'] as List?) ?? [];
        final description  = descriptions.isNotEmpty ? descriptions.first.toString().toLowerCase() : '';
        const musicHints = [
          'singer', 'musician', 'band', 'rapper', 'songwriter', 'composer',
          'dj', 'record producer', 'music group', 'vocalist', 'guitarist',
          'drummer', 'rock band', 'pop group', 'album', 'song by', 'music duo',
          'hip hop group', 'girl group', 'boy band', 'instrumentalist', 'orchestra',
        ];
        if (description.isNotEmpty && !musicHints.any(description.contains)) continue;

        return thumb.toString();
      }
      return '';
    } catch (_) { return ''; }
  }

  static Future<String> _mbAlbum(String album, String artist) async {
    try {
      final searchRes = await ApiHttp.get(
        Uri.https('musicbrainz.org', '/ws/2/release/', {
          'query': 'release:"$album" AND artist:"$artist"',
          'limit': '1', 'fmt': 'json',
        }),
        headers: {'User-Agent': 'LastStats/2.0 (contact@laststats.app)'},
      ).timeout(_timeout);
      if (searchRes.statusCode != 200) return '';
      final releases = (jsonDecode(utf8.decode(searchRes.bodyBytes))['releases'] as List?) ?? [];
      if (releases.isEmpty) return '';
      final candidate = releases.first;
      if (!_similar(album, (candidate['title'] ?? '').toString())) return '';
      final mbid = (candidate['id'] ?? '').toString();
      if (mbid.isEmpty) return '';
      final coverRes = await ApiHttp.get(Uri.https('coverartarchive.org', '/release/$mbid/front')).timeout(_timeout);
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

/// Small gray attribution label — "Source: iTunes" etc. — meant to sit at
/// the bottom of an artist/album/track sheet, under the artwork. Shows
/// nothing if the source isn't known yet (e.g. still resolving).
class ImageSourceLabel extends StatelessWidget {
  final String type; // 'artist' | 'album' | 'track'
  final String artist;
  final String album;
  final String track;
  const ImageSourceLabel({
    super.key,
    required this.type,
    required this.artist,
    this.album = '',
    this.track = '',
  });

  @override
  Widget build(BuildContext context) {
    final label = ImageService.sourceLabel(type, artist, album: album, track: track);
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
            ),
      ),
    );
  }
}

void unawaited(Future<void> f) => f.ignore();