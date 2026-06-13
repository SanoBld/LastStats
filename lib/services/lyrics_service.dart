// lib/services/lyrics_service.dart
// Fetches song lyrics from the free lyrics.ovh API (no API key).
import 'dart:convert';
import 'package:http/http.dart' as http;

class LyricsService {
  LyricsService._();

  static const _timeout = Duration(seconds: 8);

  /// Returns the lyrics for [artist]/[track], or '' if not found.
  static Future<String> getLyrics(String artist, String track) async {
    if (artist.isEmpty || track.isEmpty) return '';
    try {
      final uri = Uri.https(
        'api.lyrics.ovh',
        '/v1/${Uri.encodeComponent(artist)}/${Uri.encodeComponent(track)}',
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return '';

      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return (data['lyrics'] as String? ?? '').trim();
    } catch (_) {
      return '';
    }
  }
}
