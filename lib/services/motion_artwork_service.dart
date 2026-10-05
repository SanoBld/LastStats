// Finds Apple Music "motion artwork" (the animated album covers) for an
// album or a track. Flow:
//   1. iTunes Search API (no key) -> Apple Music album id + page URL.
//   2. Preferred: Apple Music catalog API (editorialVideo), using the
//      anonymous token that the public web player itself embeds.
//   3. Fallback: read the album page's embedded JSON and pick an HLS
//      (.m3u8) video if the album has one.
//   4. Last resort (tracks only): the official YouTube video. The URL gets
//      a "#yt=<startSec>,<lenSec>" suffix so the player loops one short
//      moment of the clip instead of the whole video.
// Returns null when nothing is found (most albums have no motion artwork),
// so callers just keep showing the static cover.
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MotionArtworkService {
  // In-memory cache: key -> video URL (or null = checked, nothing found).
  static final Map<String, String?> _cache = {};
  static const _maxEntries = 300;
  static const _timeout = Duration(seconds: 8);

  static int get cachedLinks => _cache.values.where((v) => v != null).length;
  static int get cachedLookups => _cache.length;

  /// Forgets every looked-up video link (and the Apple token), freeing memory.
  static void clearMemory() {
    _cache.clear();
    _token = null;
  }
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36';

  // HLS playback is only reliable with the native players on these
  // platforms. Elsewhere the static cover is kept.
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static Future<String?> find({
    required String artist,
    String album = '',
    String track = '',
  }) async {
    final key = '${_norm(artist)}|${_norm(album)}|${_norm(track)}';
    if (_cache.containsKey(key)) return _cache[key];
    // Bounded: the oldest lookups are dropped so the map never grows forever.
    if (_cache.length >= _maxEntries) _cache.remove(_cache.keys.first);
    try {
      // Every release that could carry the video: the song's own catalog
      // entries (single, album, deluxe, compilation...), the album, and
      // singles named after the track. The first hit used to be the only
      // one tried, so a track whose first match was a video-less
      // compilation showed nothing even though its single had one.
      final cands = await _candidates(artist, album, track);
      String? video;
      var pages = 0;
      for (final c in cands) {
        if (c.trackId != null) video = await _videoFromSongApi(c.trackId!);
        video ??= await _videoFromApi(c.collectionId);
        if (video == null && pages < 2) {
          pages++;
          video = await _videoFromPage(c.pageUrl);
        }
        if (video != null) break;
      }
      video ??= await _youtube(artist, track);
      _cache[key] = video;
      return video;
    } catch (_) {
      // Network error: don't cache, allow a retry next time.
      return null;
    }
  }

  /// Motion video for an artist page (Apple Music "artist motion").
  /// Same rules as [find]: null when nothing is found.
  static Future<String?> findArtist(String artist) async {
    final key = 'artist|${_norm(artist)}';
    if (_cache.containsKey(key)) return _cache[key];
    if (_cache.length >= _maxEntries) _cache.remove(_cache.keys.first);
    try {
      final res = await _itunes(artist, 'musicArtist', 5);
      String? video;
      var pages = 0;
      for (final r in res) {
        if (!_similar(artist, (r['artistName'] ?? '').toString())) continue;
        final id  = (r['artistId'] ?? '').toString();
        final url = (r['artistLinkUrl'] ?? '').toString().split('?').first;
        if (id.isNotEmpty) video = await _videoFromArtistApi(id);
        if (video == null && url.isNotEmpty && pages < 2) {
          pages++;
          video = await _videoFromPage(url);
        }
        if (video != null) break;
      }
      _cache[key] = video;
      return video;
    } catch (_) {
      return null; // network error: allow a retry
    }
  }

  static Future<String?> _videoFromArtistApi(String artistId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.https('amp-api.music.apple.com', '/v1/catalog/us/artists/$artistId',
            {'extend': 'editorialVideo'}),
        headers: {
          'Authorization': 'Bearer $token',
          'Origin': 'https://music.apple.com',
          'User-Agent': _ua,
        },
      ).timeout(_timeout);
      if (res.statusCode == 401) _token = null;
      if (res.statusCode != 200) return null;
      final data = (jsonDecode(utf8.decode(res.bodyBytes))['data'] as List?) ?? [];
      if (data.isEmpty) return null;
      final ev = data.first['attributes']?['editorialVideo'];
      if (ev is! Map) return null;
      // Square first, then tall, then wide (the image box crops to fill).
      for (final k in ['motionArtistSquare1x1', 'motionSquareVideo1x1',
                       'motionDetailSquare', 'motionArtistFullscreen16x9',
                       'motionDetailTall', 'motionTallVideo3x4',
                       'motionArtistWide16x9']) {
        final v = ev[k]?['video'];
        if (v is String && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  // ── YouTube fallback ───────────────────────────────────────────────────
  static const _ytBad =
      r'cover|live|reaction|remix|karaoke|instrumental|lyric|slowed|sped|'
      r'8d|nightcore|tutorial|mashup|acoustic|audio only';

  static Future<String?> _youtube(String artist, String track) async {
    if (track.isEmpty) return null;
    final yt = YoutubeExplode();
    try {
      final core  = _norm(_core(track));
      final lead  = _norm(artist.split(_artistSplit).first);
      if (core.isEmpty || lead.isEmpty) return null;
      final res = await yt.search
          .search('$artist ${_core(track)} official video')
          .timeout(_timeout);
      for (final v in res.take(8)) {
        if (v.isLive) continue;
        final d = v.duration?.inSeconds ?? 0;
        if (d < 90 || d > 600) continue;
        final title = v.title.toLowerCase();
        if (RegExp(_ytBad).hasMatch(title) &&
            !RegExp(_ytBad).hasMatch(track.toLowerCase())) continue;
        if (!_norm(v.title).contains(core)) continue;
        if (!_norm('${v.title} ${v.author}').contains(lead)) continue;
        final m = await yt.videos.streams
            .getManifest(v.id)
            .timeout(const Duration(seconds: 15));
        final mp4 = m.muxed.where((s) => s.container.name == 'mp4').toList();
        if (mp4.isEmpty) continue;
        final s = mp4.withHighestBitrate();
        // Guess of a "good moment": ~35% in (usually past the intro, around
        // the first chorus). Loops 12 s from there.
        final start = (d * 0.35).round();
        return '${s.url}#yt=$start,12';
      }
    } catch (_) {
    } finally {
      yt.close();
    }
    return null;
  }

  static String _norm(String s) {
    const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const to   = 'aaaaaaceeeeiiiinooooouuuuyy';
    var t = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      t = t.replaceAll(from[i], to[i]);
    }
    return t.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // Drops "(feat. X)", "[Remastered]", " - Single", " - Live" suffixes so
  // Last.fm titles match Apple's.
  static String _core(String s) => s
      .replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]'), '')
      .replaceAll(RegExp(r'\s+-\s+.*$'), '')
      .trim();

  // Loose match so "Album (Deluxe Edition)" still matches "Album", and
  // "Star Walkin'" matches "STARWALKIN'".
  static bool _similar(String a, String b) {
    for (final pair in [(a, b), (_core(a), _core(b))]) {
      final x = _norm(pair.$1), y = _norm(pair.$2);
      if (x.isEmpty || y.isEmpty) continue;
      if (x == y) return true;
      final s = x.length <= y.length ? x : y;
      final l = x.length <= y.length ? y : x;
      if (s.length >= 4 && l.contains(s)) return true;
    }
    return false;
  }

  static final _artistSplit = RegExp(
      r'\s*,\s*|\s+(&|feat\.?|ft\.?|x|and)\s+', caseSensitive: false);

  // The artist may be credited as "A & B" / "A feat. B" on one side only.
  static bool _artistMatch(String a, String b) =>
      _similar(a, b) ||
      _similar(a.split(_artistSplit).first, b) ||
      _similar(a, b.split(_artistSplit).first);

  static Future<List<Map<String, dynamic>>> _itunes(
      String term, String entity, int limit) async {
    try {
      final res = await http.get(Uri.https('itunes.apple.com', '/search', {
        'term': term, 'entity': entity, 'media': 'music', 'limit': '$limit',
      })).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final list = (jsonDecode(utf8.decode(res.bodyBytes))['results'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<({String collectionId, String pageUrl, String? trackId})>>
      _candidates(String artist, String album, String track) async {
    final out = <({String collectionId, String pageUrl, String? trackId})>[];
    final seen = <String>{};
    void add(Map<String, dynamic> item, {required bool song}) {
      final id  = (item['collectionId'] ?? '').toString();
      final url = (item['collectionViewUrl'] ?? '').toString();
      if (id.isEmpty || url.isEmpty) return;
      final tid = song ? (item['trackId'] ?? '').toString() : '';
      if (!seen.add('$id|$tid')) return;
      out.add((collectionId: id, pageUrl: url.split('?').first,
               trackId: tid.isEmpty ? null : tid));
    }

    final futures = <Future<List<Map<String, dynamic>>>>[
      if (track.isNotEmpty) _itunes('$artist ${_core(track)}', 'song', 25),
      if (album.isNotEmpty) _itunes('$artist ${_core(album)}', 'album', 10),
      if (track.isNotEmpty) _itunes('$artist ${_core(track)}', 'album', 10),
    ];
    final res = await Future.wait(futures);
    var i = 0;
    if (track.isNotEmpty) {
      for (final r in res[i++]) {
        if (_artistMatch(artist, (r['artistName'] ?? '').toString()) &&
            _similar(track, (r['trackName'] ?? '').toString())) {
          add(r, song: true);
        }
      }
    }
    if (album.isNotEmpty) {
      for (final r in res[i++]) {
        if (_artistMatch(artist, (r['artistName'] ?? '').toString()) &&
            _similar(album, (r['collectionName'] ?? '').toString())) {
          add(r, song: false);
        }
      }
    }
    if (track.isNotEmpty) {
      for (final r in res[i++]) {
        if (_artistMatch(artist, (r['artistName'] ?? '').toString()) &&
            _similar(track, (r['collectionName'] ?? '').toString())) {
          add(r, song: false);
        }
      }
    }
    return out.take(8).toList();
  }

  // ── Catalog API path ───────────────────────────────────────────────────
  static String? _token;

  // The web player ships a public, anonymous developer token inside its
  // main JS bundle. We read it from there.
  static Future<String?> _getToken() async {
    if (_token != null) return _token;
    final home = await http.get(Uri.parse('https://music.apple.com/us/browse'),
        headers: {'User-Agent': _ua}).timeout(_timeout);
    if (home.statusCode != 200) return null;
    // Try the main bundle first, then any other script of the page.
    final scripts = RegExp(r'src="(/assets/[^"]+\.js)"')
        .allMatches(home.body).map((m) => m.group(1)!).toList()
      ..sort((a, b) => (b.contains('/index') ? 1 : 0) - (a.contains('/index') ? 1 : 0));
    for (final path in scripts.take(6)) {
      try {
        final js = await http.get(Uri.parse('https://music.apple.com$path'),
            headers: {'User-Agent': _ua}).timeout(const Duration(seconds: 15));
        if (js.statusCode != 200) continue;
        final t = RegExp(r'eyJh[\w-]+\.[\w-]+\.[\w-]+').firstMatch(js.body);
        if (t != null) return _token = t.group(0);
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> _videoFromApi(String albumId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.https('amp-api.music.apple.com', '/v1/catalog/us/albums/$albumId',
            {'extend': 'editorialVideo'}),
        headers: {
          'Authorization': 'Bearer $token',
          'Origin': 'https://music.apple.com',
          'User-Agent': _ua,
        },
      ).timeout(_timeout);
      if (res.statusCode == 401) _token = null; // expired, refetch next time
      if (res.statusCode != 200) return null;
      final data = (jsonDecode(utf8.decode(res.bodyBytes))['data'] as List?) ?? [];
      if (data.isEmpty) return null;
      final ev = data.first['attributes']?['editorialVideo'];
      if (ev is! Map) return null;
      // Square first (matches album art), then tall.
      for (final k in ['motionDetailSquare', 'motionSquareVideo1x1',
                       'motionDetailTall', 'motionTallVideo3x4']) {
        final v = ev[k]?['video'];
        if (v is String && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  // Same lookup as _videoFromApi, but on the *song* catalog entry — a
  // track's own motion video, when Apple only attaches one there instead
  // of (or in addition to) the album's.
  static Future<String?> _videoFromSongApi(String trackId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.https('amp-api.music.apple.com', '/v1/catalog/us/songs/$trackId',
            {'extend': 'editorialVideo'}),
        headers: {
          'Authorization': 'Bearer $token',
          'Origin': 'https://music.apple.com',
          'User-Agent': _ua,
        },
      ).timeout(_timeout);
      if (res.statusCode == 401) _token = null;
      if (res.statusCode != 200) return null;
      final data = (jsonDecode(utf8.decode(res.bodyBytes))['data'] as List?) ?? [];
      if (data.isEmpty) return null;
      final ev = data.first['attributes']?['editorialVideo'];
      if (ev is! Map) return null;
      for (final k in ['motionDetailSquare', 'motionSquareVideo1x1',
                       'motionDetailTall', 'motionTallVideo3x4']) {
        final v = ev[k]?['video'];
        if (v is String && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  // ── Page scraping fallback ─────────────────────────────────────────────
  static Future<String?> _videoFromPage(String pageUrl) async {
    final res = await http.get(Uri.parse(pageUrl), headers: {
      'User-Agent': _ua,
      'Accept-Language': 'en-US,en;q=0.9',
    }).timeout(_timeout);
    if (res.statusCode != 200) return null;
    final html = utf8.decode(res.bodyBytes);

    // Collect every .m3u8 URL with the JSON key that holds it.
    final found = <(String, String)>[];
    final m = RegExp(
      r'<script[^>]*id="serialized-server-data"[^>]*>(.*?)</script>',
      dotAll: true,
    ).firstMatch(html);
    if (m != null) {
      try {
        _walk(jsonDecode(m.group(1)!), '', found);
      } catch (_) {}
    }
    // Fallback: raw scan of the HTML.
    if (found.isEmpty) {
      for (final x in RegExp(r'https:[^"\\\s]+\.m3u8[^"\\\s]*').allMatches(html)) {
        found.add(('', x.group(0)!.replaceAll(r'\/', '/')));
      }
    }
    if (found.isEmpty) return null;

    // Prefer the square video (matches album art), then any non-tall one.
    for (final f in found) {
      if (f.$1.toLowerCase().contains('square')) return f.$2;
    }
    for (final f in found) {
      if (f.$1 == 'video') return f.$2;
    }
    for (final f in found) {
      if (!f.$1.toLowerCase().contains('tall')) return f.$2;
    }
    return found.first.$2;
  }

  static void _walk(dynamic n, String key, List<(String, String)> out) {
    if (n is Map) {
      n.forEach((k, v) => _walk(v, k.toString(), out));
    } else if (n is List) {
      for (final e in n) {
        _walk(e, key, out);
      }
    } else if (n is String && n.startsWith('http') && n.contains('.m3u8')) {
      out.add((key, n));
    }
  }
}
