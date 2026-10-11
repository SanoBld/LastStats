// Wikipedia fallback for biographies: used when Last.fm has no bio for an
// artist, album or track.
import 'dart:convert';
import 'package:http/http.dart' as http;

class WikiBio {
  final String text;
  final String url;
  const WikiBio(this.text, this.url);
}

class WikiBioService {
  static const _timeout = Duration(seconds: 6);
  static const _langs = {'fr', 'en', 'de', 'es', 'it', 'pt', 'ru', 'ja', 'zh', 'ar'};
  static final Map<String, WikiBio?> _cache = {};

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');

  static bool _similar(String a, String b) {
    final x = _norm(a), y = _norm(b);
    if (x.isEmpty || y.isEmpty) return false;
    if (x == y) return true;
    final s = x.length <= y.length ? x : y, l = x.length <= y.length ? y : x;
    return s.length >= 4 && l.contains(s);
  }

  static const _hints = [
    'music', 'singer', 'band', 'rapper', 'album', 'song', 'single', 'musician',
    'record', 'group', 'duo', 'dj', 'composer',
  ];

  /// [type] = artists | albums | tracks. Tries the app language first, then English.
  static Future<WikiBio?> find({
    required String type,
    required String name,
    required String artist,
    required String lang,
  }) async {
    final key = '$type|$artist|$name|$lang';
    if (_cache.containsKey(key)) return _cache[key];
    final query = switch (type) {
      'albums' => '$name $artist album',
      'tracks' => '$name $artist song',
      _        => name,
    };
    final hosts = <String>[
      if (_langs.contains(lang) && lang != 'en') lang,
      'en',
    ];
    WikiBio? out;
    for (final h in hosts) {
      out = await _search(h, query, name, strictMusic: h == 'en');
      if (out != null) break;
    }
    _cache[key] = out;
    return out;
  }

  static Future<WikiBio?> _search(String host, String query, String expect,
      {required bool strictMusic}) async {
    try {
      final res = await http.get(Uri.https('$host.wikipedia.org', '/w/api.php', {
        'action': 'query', 'generator': 'search', 'gsrsearch': query,
        'gsrlimit': '3', 'prop': 'extracts|info', 'inprop': 'url',
        'exintro': '1', 'explaintext': '1', 'exsentences': '8',
        'format': 'json', 'origin': '*',
      })).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final pages = (jsonDecode(utf8.decode(res.bodyBytes))['query']?['pages'] as Map?) ?? {};
      final list = pages.values.whereType<Map>().toList()
        ..sort((a, b) => ((a['index'] ?? 9) as num).compareTo((b['index'] ?? 9) as num));
      for (final p in list) {
        final title   = (p['title'] ?? '').toString();
        final extract = (p['extract'] ?? '').toString().trim();
        if (extract.length < 60 || !_similar(expect, title)) continue;
        if (strictMusic) {
          final low = extract.toLowerCase();
          if (!_hints.any(low.contains)) continue;
        }
        return WikiBio(extract, (p['fullurl'] ?? 'https://$host.wikipedia.org').toString());
      }
    } catch (_) {}
    return null;
  }
}
