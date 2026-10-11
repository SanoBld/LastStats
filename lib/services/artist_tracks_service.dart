// Most recent tracks of an artist (Last.fm has no release dates), found with
// the iTunes Search API: songs sorted by release date, newest first.
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecentTrack {
  final String name;
  final String artist;
  final String album;
  final String date;     // yyyy-MM-dd
  final String image;
  const RecentTrack(this.name, this.artist, this.album, this.date, this.image);
}

class ArtistTracksService {
  static final Map<String, List<RecentTrack>> _cache = {};

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');

  static Future<List<RecentTrack>> recent(String artist, {int limit = 10}) async {
    final key = artist.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key]!;
    final out = <RecentTrack>[];
    try {
      final res = await http.get(Uri.https('itunes.apple.com', '/search', {
        'term': artist, 'entity': 'song', 'attribute': 'artistTerm', 'limit': '200',
      })).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final results = (jsonDecode(utf8.decode(res.bodyBytes))['results'] as List?) ?? [];
        final want = _norm(artist);
        final seen = <String>{};
        final rows = <Map>[];
        for (final r in results.whereType<Map>()) {
          final a = _norm((r['artistName'] ?? '').toString());
          if (a.isEmpty || !(a == want || a.contains(want))) continue;
          final n = _norm((r['trackName'] ?? '').toString());
          if (n.isEmpty || !seen.add(n)) continue;   // same song, other release
          rows.add(r);
        }
        rows.sort((x, y) => (y['releaseDate'] ?? '').toString()
            .compareTo((x['releaseDate'] ?? '').toString()));
        for (final r in rows.take(limit)) {
          final art = (r['artworkUrl100'] ?? '').toString()
              .replaceAll('100x100bb', '300x300bb');
          out.add(RecentTrack(
            (r['trackName'] ?? '').toString(),
            (r['artistName'] ?? '').toString(),
            (r['collectionName'] ?? '').toString(),
            (r['releaseDate'] ?? '').toString().split('T').first,
            art,
          ));
        }
      }
    } catch (_) {}
    _cache[key] = out;
    return out;
  }
}
