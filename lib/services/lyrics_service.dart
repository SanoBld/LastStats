// lib/services/lyrics_service.dart
// Fetches song lyrics. Primary: lrclib.net (good coverage, no key).
// Fallback: lyrics.ovh.
import 'dart:convert';
import 'package:http/http.dart' as http;

class LyricsService {
  LyricsService._();

  static const _timeout = Duration(seconds: 8);

  static Future<String> getLyrics(String artist, String track) async {
    if (artist.isEmpty || track.isEmpty) return '';

    // 1 — lrclib.net
    try {
      final uri = Uri.https('lrclib.net', '/api/get', {
        'artist_name': artist,
        'track_name':  track,
      });
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final plain = (data['plainLyrics'] as String? ?? '').trim();
        if (plain.isNotEmpty) return plain;
      }
    } catch (_) {}

    // 2 — lyrics.ovh fallback
    try {
      final uri = Uri.https(
        'api.lyrics.ovh',
        '/v1/${Uri.encodeComponent(artist)}/${Uri.encodeComponent(track)}',
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return (data['lyrics'] as String? ?? '').trim();
      }
    } catch (_) {}

    return '';
  }
}