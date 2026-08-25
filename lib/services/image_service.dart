// lib/services/image_service.dart
//
// Resolves artwork URLs from Last.fm → YouTube Music → iTunes → Deezer → MusicBrainz.
// Downloads and caches image bytes via OfflineImageCache for offline use.
//
// Main entry points:
//   resolveArtist / resolveAlbum / resolveTrack  → URL string (fast, cached)
//   widgetImage(url, ...)                        → offline-capable Widget
//   prefetchBytes(url)                           → background download

import 'dart:convert';
import 'package:flutter/material.dart' show Theme, TextStyle;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_image_cache.dart';
import 'storage_manager.dart';
import '../app_state.dart';

/// Full 10-language lookup — falls back to English, then French.
String _tr(Map<String, String> byLocale) =>
    byLocale[localeNotifier.value] ?? byLocale['en'] ?? byLocale['fr'] ?? '';

class ImageService {
  ImageService._();

  static const _placeholder = '2a96cbd8b46e442fc41c2b86b821562f';
  static const _timeout     = Duration(seconds: 6);
  static const _diskPrefix  = 'imgcache_';
  static const _diskTtlMs   = 7 * 24 * 60 * 60 * 1000;

  // In-memory URL cache (session).
  static final Map<String, String> _mem = {};
  // Which source produced each cache key's URL — for the small attribution
  // label shown under artwork. Keyed by the same `key` used in `_mem`.
  static final Map<String, String> _sourceOf = {};

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
          final src = (e['source'] as String?) ?? '';
          // Entries cached before source-tracking existed have no 'source'
          // field — rather than show a guessed/fake source for those, drop
          // them so they get re-resolved (and properly tagged) next time.
          if (url.isEmpty || src.isEmpty || (now - ts) > _diskTtlMs) {
            _prefs!.remove(k).ignore();
            continue;
          }
          _mem[k.substring(_diskPrefix.length)] = url;
          _sourceOf[k.substring(_diskPrefix.length)] = src;
        } catch (_) { _prefs!.remove(k).ignore(); }
      }
    } catch (_) {}
  }

  static String? _getUrl(String key) => _mem[key];

  static Future<String> _persistUrl(String key, String url, [String source = '']) async {
    _mem[key] = url;
    if (source.isNotEmpty) _sourceOf[key] = source;
    if (url.isEmpty) return url;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(
        '$_diskPrefix$key',
        jsonEncode({'url': url, 'ts': DateTime.now().millisecondsSinceEpoch, 'source': source}),
      );
    } catch (_) {}
    // Kick off background byte download.
    _cacheBytes(url);
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
    return _tr(_sourceNames[raw] ?? const {});
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

  static const Map<String, Map<String, String>> _sourceNames = {
    'lastfm': {
      'fr': 'Source : Last.fm', 'en': 'Source: Last.fm', 'es': 'Fuente: Last.fm',
      'de': 'Quelle: Last.fm', 'it': 'Fonte: Last.fm', 'pt': 'Fonte: Last.fm',
      'ru': 'Источник: Last.fm', 'ja': '提供元: Last.fm', 'zh': '来源：Last.fm',
      'ar': 'المصدر: Last.fm',
    },
    'ytmusic': {
      'fr': 'Source : YouTube Music', 'en': 'Source: YouTube Music', 'es': 'Fuente: YouTube Music',
      'de': 'Quelle: YouTube Music', 'it': 'Fonte: YouTube Music', 'pt': 'Fonte: YouTube Music',
      'ru': 'Источник: YouTube Music', 'ja': '提供元: YouTube Music', 'zh': '来源：YouTube Music',
      'ar': 'المصدر: YouTube Music',
    },
    'itunes': {
      'fr': 'Source : iTunes', 'en': 'Source: iTunes', 'es': 'Fuente: iTunes',
      'de': 'Quelle: iTunes', 'it': 'Fonte: iTunes', 'pt': 'Fonte: iTunes',
      'ru': 'Источник: iTunes', 'ja': '提供元: iTunes', 'zh': '来源：iTunes',
      'ar': 'المصدر: iTunes',
    },
    'deezer': {
      'fr': 'Source : Deezer', 'en': 'Source: Deezer', 'es': 'Fuente: Deezer',
      'de': 'Quelle: Deezer', 'it': 'Fonte: Deezer', 'pt': 'Fonte: Deezer',
      'ru': 'Источник: Deezer', 'ja': '提供元: Deezer', 'zh': '来源：Deezer',
      'ar': 'المصدر: Deezer',
    },
    'audiodb': {
      'fr': 'Source : TheAudioDB', 'en': 'Source: TheAudioDB', 'es': 'Fuente: TheAudioDB',
      'de': 'Quelle: TheAudioDB', 'it': 'Fonte: TheAudioDB', 'pt': 'Fonte: TheAudioDB',
      'ru': 'Источник: TheAudioDB', 'ja': '提供元: TheAudioDB', 'zh': '来源：TheAudioDB',
      'ar': 'المصدر: TheAudioDB',
    },
    'musicbrainz': {
      'fr': 'Source : MusicBrainz', 'en': 'Source: MusicBrainz', 'es': 'Fuente: MusicBrainz',
      'de': 'Quelle: MusicBrainz', 'it': 'Fonte: MusicBrainz', 'pt': 'Fonte: MusicBrainz',
      'ru': 'Источник: MusicBrainz', 'ja': '提供元: MusicBrainz', 'zh': '来源：MusicBrainz',
      'ar': 'المصدر: MusicBrainz',
    },
    'wikipedia': {
      'fr': 'Source : Wikipédia', 'en': 'Source: Wikipedia', 'es': 'Fuente: Wikipedia',
      'de': 'Quelle: Wikipedia', 'it': 'Fonte: Wikipedia', 'pt': 'Fonte: Wikipedia',
      'ru': 'Источник: Википедия', 'ja': '提供元: Wikipedia', 'zh': '来源：维基百科',
      'ar': 'المصدر: ويكيبيديا',
    },
  };

  static void _cacheBytes(String url) {
    if (url.isEmpty) return;
    OfflineImageCache.imageProvider(url).then((_) {
      StorageManager.enforceQuota().ignore();
    }).ignore();
  }

  // ── Public: resolve URL ───────────────────────────────────────────────────

  static Future<String> resolveArtist(String artist, {String? lastfmUrl}) async {
    final key = 'artist|$artist';
    await _ensureDiskCache();
    final mem = _getUrl(key);
    if (mem != null) return mem;

    final ytMusic = await _ytMusicSearch(artist, 'artist', expectArtist: artist);
    if (ytMusic.isNotEmpty) return _persistUrl(key, ytMusic, 'ytmusic');

    final itunes = await _itunesSearch(artist, 'musicArtist', 'artistTerm', artist);
    if (itunes.isNotEmpty) return _persistUrl(key, itunes, 'itunes');

    final deezer = await _deezerArtist(artist);
    if (deezer.isNotEmpty) return _persistUrl(key, deezer, 'deezer');

    final audioDb = await _audioDbArtist(artist);
    if (audioDb.isNotEmpty) return _persistUrl(key, audioDb, 'audiodb');

    final mb = await _mbArtistImage(artist);
    if (mb.isNotEmpty) return _persistUrl(key, mb, 'musicbrainz');

    final wiki = await _wikipediaImage(artist, expectName: artist);
    if (wiki.isNotEmpty) return _persistUrl(key, wiki, 'wikipedia');

    // Last.fm last — its own catalog images are usually much lower
    // resolution (~300px) than the sources above, so it's a fallback here
    // rather than an automatic first pick.
    if (_ok(lastfmUrl)) {
      _cacheBytes(lastfmUrl!);
      return _persistUrl(key, lastfmUrl, 'lastfm');
    }

    return _persistUrl(key, '');
  }

  static Future<String> resolveAlbum(String album, String artist, {String? lastfmUrl}) async {
    final key = 'album|$artist|$album';
    await _ensureDiskCache();
    final mem = _getUrl(key);
    if (mem != null) return mem;

    final ytMusic = await _ytMusicSearch('$artist $album', 'album', expectArtist: artist, expectTitle: album);
    if (ytMusic.isNotEmpty) return _persistUrl(key, ytMusic, 'ytmusic');

    final itunes = await _itunesSearch('$artist $album', 'album', null, artist, album);
    if (itunes.isNotEmpty) return _persistUrl(key, itunes, 'itunes');

    final deezer = await _deezerAlbum(album, artist);
    if (deezer.isNotEmpty) return _persistUrl(key, deezer, 'deezer');

    final audioDb = await _audioDbAlbum(album, artist);
    if (audioDb.isNotEmpty) return _persistUrl(key, audioDb, 'audiodb');

    final mb = await _mbAlbum(album, artist);
    if (mb.isNotEmpty) return _persistUrl(key, mb, 'musicbrainz');

    final wiki = await _wikipediaImage('$artist $album album', expectName: album);
    if (wiki.isNotEmpty) return _persistUrl(key, wiki, 'wikipedia');

    if (_ok(lastfmUrl)) {
      _cacheBytes(lastfmUrl!);
      return _persistUrl(key, lastfmUrl, 'lastfm');
    }

    return _persistUrl(key, '');
  }

  static Future<String> resolveTrack(String track, String artist,
      {String? lastfmUrl, String album = ''}) async {
    final key = 'track|$artist|$track';
    await _ensureDiskCache();
    final mem = _getUrl(key);
    if (mem != null) return mem;

    final ytMusic = await _ytMusicSearch('$artist $track', 'song', expectArtist: artist, expectTitle: track);
    if (ytMusic.isNotEmpty) return _persistUrl(key, ytMusic, 'ytmusic');

    final itunes = await _itunesSearch('$artist $track', 'song', null, artist, track);
    if (itunes.isNotEmpty) return _persistUrl(key, itunes, 'itunes');

    final deezer = await _deezerTrack(track, artist);
    if (deezer.isNotEmpty) return _persistUrl(key, deezer, 'deezer');

    final audioDb = await _audioDbTrack(track, artist);
    if (audioDb.isNotEmpty) return _persistUrl(key, audioDb, 'audiodb');

    // Reuses album cover art if the caller knows the parent album.
    if (album.isNotEmpty) {
      final mb = await _mbAlbum(album, artist);
      if (mb.isNotEmpty) return _persistUrl(key, mb, 'musicbrainz');
    }

    final wiki = await _wikipediaImage('$artist $track song', expectName: track);
    if (wiki.isNotEmpty) return _persistUrl(key, wiki, 'wikipedia');

    if (_ok(lastfmUrl)) {
      _cacheBytes(lastfmUrl!);
      return _persistUrl(key, lastfmUrl, 'lastfm');
    }

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
      final res = await http.post(
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
      if (sections == null) return '';

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
    // YT thumbnail URLs take an arbitrary width/height suffix — bump it up.
    return raw.replaceAll(RegExp(r'=w\d+-h\d+.*$'), '=w1200-h1200');
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
      final res = await http.get(Uri.https('itunes.apple.com', '/search', params)).timeout(_timeout);
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
      final res = await http.get(Uri.https('api.deezer.com', '/search/artist', {'q': artist, 'limit': '1'}))
          .timeout(_timeout);
      if (res.statusCode != 200) return '';
      final items = (jsonDecode(utf8.decode(res.bodyBytes))['data'] as List?) ?? [];
      if (items.isEmpty) return '';
      final item = items.first;
      if (!_similar(artist, (item['name'] ?? '').toString())) return '';
      return (item['picture_xl'] ?? item['picture_big'] ?? '').toString();
    } catch (_) { return ''; }
  }

  static Future<String> _deezerAlbum(String album, String artist) async {
    try {
      final res = await http.get(Uri.https('api.deezer.com', '/search/album', {'q': '$artist $album', 'limit': '1'}))
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
      final res = await http.get(Uri.https('api.deezer.com', '/search/track', {'q': '$artist $track', 'limit': '1'}))
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
      final res = await http
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
      final res = await http
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
      final res = await http
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
      final searchRes = await http.get(
        Uri.https('musicbrainz.org', '/ws/2/artist/', {
          'query': 'artist:"$artist"', 'limit': '1', 'fmt': 'json',
        }),
        headers: {'User-Agent': 'LastStatsMobile/2.0 (contact@laststats.app)'},
      ).timeout(_timeout);
      if (searchRes.statusCode != 200) return '';
      final found = (jsonDecode(utf8.decode(searchRes.bodyBytes))['artists'] as List?) ?? [];
      if (found.isEmpty) return '';
      final candidate = found.first;
      if (!_similar(artist, (candidate['name'] ?? '').toString())) return '';
      final mbid = (candidate['id'] ?? '').toString();
      if (mbid.isEmpty) return '';

      final relRes = await http.get(
        Uri.https('musicbrainz.org', '/ws/2/artist/$mbid', {'inc': 'url-rels', 'fmt': 'json'}),
        headers: {'User-Agent': 'LastStatsMobile/2.0 (contact@laststats.app)'},
      ).timeout(_timeout);
      if (relRes.statusCode != 200) return '';
      final rels = (jsonDecode(utf8.decode(relRes.bodyBytes))['relations'] as List?) ?? [];
      final imgRel = rels.firstWhere((r) => r['type'] == 'image', orElse: () => null);
      final pageUrl = (imgRel?['url']?['resource'] ?? '').toString();
      if (pageUrl.isEmpty) return '';

      // pageUrl is a Commons "File:" page — resolve to the actual image URL.
      final title = Uri.decodeFull(pageUrl.split('/wiki/').last);
      final fileRes = await http.get(Uri.https('commons.wikimedia.org', '/w/api.php', {
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
      final res = await http.get(Uri.https('en.wikipedia.org', '/w/api.php', {
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
      final candidate = releases.first;
      if (!_similar(album, (candidate['title'] ?? '').toString())) return '';
      final mbid = (candidate['id'] ?? '').toString();
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