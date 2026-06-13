// lib/services/translation_service.dart
// Simple translation via the free Google Translate endpoint (no API key).
import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService._();

  static const _timeout = Duration(seconds: 8);

  /// Translates [text] to [target] language code (e.g. 'fr', 'en').
  /// Returns '' on failure.
  static Future<String> translate(String text, String target) async {
    if (text.isEmpty) return '';
    try {
      // Google splits long text into chunks of ~5000 chars internally,
      // but the free endpoint works fine for typical bios.
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl':     'auto',
        'tl':     target,
        'dt':     't',
        'q':      text,
      });
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return '';

      final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      final segments = data[0] as List;
      final buffer = StringBuffer();
      for (final seg in segments) {
        if (seg is List && seg.isNotEmpty) buffer.write(seg[0]);
      }
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }
}
