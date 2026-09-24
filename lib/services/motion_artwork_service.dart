// Finds Apple Music "motion artwork" (the animated album covers) for an
// album or a track. Flow:
//   1. iTunes Search API (no key) -> Apple Music album id + page URL.
//   2. Preferred: Apple Music catalog API (editorialVideo), using the
//      anonymous token that the public web player itself embeds.
//   3. Fallback: read the album page's embedded JSON and pick an HLS
//      (.m3u8) video if the album has one.
// Returns null when nothing is found (most albums have no motion artwork),
// so callers just keep showing the static cover.
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class MotionArtworkService {
  // In-memory cache: key -> video URL (or null = checked, nothing found).
  static final Map<String, String?> _cache = {};
  static const _timeout = Duration(seconds: 8);
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
    try {
      final hit = await _albumPageUrl(artist, album, track);
      String? video;
      if (hit != null) {
        video = await _videoFromApi(hit.$1);
        video ??= await _videoFromPage(hit.$2);
      }
      _cache[key] = video;
      return video;
    } catch (_) {
      // Network error: don't cache, allow a retry next time.
      return null;
    }
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  // Loose match so "Album (Deluxe Edition)" still matches "Album".
  static bool _similar(String a, String b) {
    final x = _norm(a), y = _norm(b);
    if (x.isEmpty || y.isEmpty) return false;
    if (x == y) return true;
    final s = x.length <= y.length ? x : y;
    final l = x.length <= y.length ? y : x;
    return s.length >= 4 && l.contains(s);
  }

  // Returns (collectionId, album page URL) of the best match.
  static Future<(String, String)?> _albumPageUrl(
      String artist, String album, String track) async {
    final byAlbum = album.isNotEmpty;
    final res = await http.get(Uri.https('itunes.apple.com', '/search', {
      'term': byAlbum ? '$artist $album' : '$artist $track',
      'entity': byAlbum ? 'album' : 'song',
      'media': 'music',
      'limit': '5',
    })).timeout(_timeout);
    if (res.statusCode != 200) return null;
    final results =
        (jsonDecode(utf8.decode(res.bodyBytes))['results'] as List?) ?? [];
    for (final r in results) {
      final item = r as Map<String, dynamic>;
      if (!_similar(artist, (item['artistName'] ?? '').toString())) continue;
      final title = (byAlbum ? item['collectionName'] : item['trackName'] ?? '')
          .toString();
      if (!_similar(byAlbum ? album : track, title)) continue;
      final url = (item['collectionViewUrl'] ?? '').toString();
      if (url.isEmpty) continue;
      final id = (item['collectionId'] ?? '').toString();
      if (id.isEmpty) continue;
      // Drop the "?i=trackId" part so we get the album page itself.
      return (id, url.split('?').first);
    }
    return null;
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
    final src = RegExp(r'src="(/assets/index[^"]+\.js)"').firstMatch(home.body);
    if (src == null) return null;
    final js = await http.get(Uri.parse('https://music.apple.com${src.group(1)}'),
        headers: {'User-Agent': _ua}).timeout(const Duration(seconds: 15));
    if (js.statusCode != 200) return null;
    final t = RegExp(r'eyJh[\w-]+\.[\w-]+\.[\w-]+').firstMatch(js.body);
    return _token = t?.group(0);
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
