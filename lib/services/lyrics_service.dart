// lib/services/lyrics_service.dart
// Fetches song lyrics.
// 1) lrclib.net exact match  2) lrclib.net search (looser)  3) lyrics.ovh.
// Each step is tried with the clean title/artist too ("feat.", "Remastered"...).
import 'dart:convert';
import 'api_http.dart';

class LyricsService {
  LyricsService._();

  static const _timeout = Duration(seconds: 8);

  // Removes "(feat. X)", "- Remastered 2011", "[Live]" etc. from a title.
  static String _cleanTitle(String t) {
    var s = t.replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]'), '');
    s = s.replaceAll(RegExp(r'\s+-\s+(remaster(ed)?|live|radio edit|single version|mono|stereo|version|deluxe).*$', caseSensitive: false), '');
    return s.trim();
  }

  // "A, B" / "A feat. B" / "A & B" -> "A"
  static String _mainArtist(String a) =>
      a.split(RegExp(r',|\s+feat\.?\s+|\s+ft\.?\s+|\s+&\s+|\s+x\s+', caseSensitive: false)).first.trim();

  // Removes [00:12.34] timestamps from synced lyrics.
  static String _stripLrc(String s) => s
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'^\s*(\[[0-9:.]+\])+\s*'), '').trimRight())
      .join('\n')
      .trim();

  static String _fromLrclib(Map<String, dynamic> d) {
    if (d['instrumental'] == true) return '';
    final plain = (d['plainLyrics'] as String? ?? '').trim();
    if (plain.isNotEmpty) return plain;
    final synced = (d['syncedLyrics'] as String? ?? '').trim();
    return synced.isEmpty ? '' : _stripLrc(synced);
  }

  static Future<String> getLyrics(String artist, String track) async {
    if (artist.isEmpty || track.isEmpty) return '';

    // Try the original names first, then the cleaned ones (if different).
    final pairs = <(String, String)>[(artist, track)];
    final cA = _mainArtist(artist), cT = _cleanTitle(track);
    if ((cA, cT) != (artist, track) && cT.isNotEmpty) pairs.add((cA, cT));

    for (final (a, t) in pairs) {
      // 1 — lrclib exact match
      try {
        final res = await ApiHttp.get(Uri.https('lrclib.net', '/api/get',
            {'artist_name': a, 'track_name': t})).timeout(_timeout);
        if (res.statusCode == 200) {
          final r = _fromLrclib(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
          if (r.isNotEmpty) return r;
        }
      } catch (_) {}

      // 2 — lrclib search (finds tracks the exact match misses)
      try {
        final res = await ApiHttp.get(Uri.https('lrclib.net', '/api/search',
            {'artist_name': a, 'track_name': t})).timeout(_timeout);
        if (res.statusCode == 200) {
          final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
          for (final e in list.take(5)) {
            final r = _fromLrclib(e as Map<String, dynamic>);
            if (r.isNotEmpty) return r;
          }
        }
      } catch (_) {}

      // 3 — lyrics.ovh (plain text only)
      try {
        final res = await ApiHttp.get(Uri.https('api.lyrics.ovh',
            '/v1/${Uri.encodeComponent(a)}/${Uri.encodeComponent(t)}')).timeout(_timeout);
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final r = (data['lyrics'] as String? ?? '').trim();
          if (r.isNotEmpty) return r;
        }
      } catch (_) {}
    }
    return '';
  }
}
