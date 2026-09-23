// lib/services/listenbrainz_service.dart
// ══════════════════════════════════════════════════════════════════════════
//  Real, time-ranged global charts for the dashboard "Global trends" group.
//
//  Last.fm's chart.* endpoints have no time range (they are a rolling,
//  opaque ranking), so this uses ListenBrainz sitewide statistics instead:
//  public, no API key, and computed per week / month / year / all time.
//
//    GET https://api.listenbrainz.org/1/stats/sitewide/{entity}?range=...
//    entity: artists | recordings | release-groups
//    range : week | month | year | all_time  (last full week / month / year)
//
//  Every entry is normalized to a small map so the UI does not care where
//  the data comes from. Images are not provided by ListenBrainz, except
//  cover art ids for tracks/albums (Cover Art Archive); otherwise the UI
//  resolves them with ImageService like everywhere else.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;

class ChartEntry {
  final String name, artist, imageUrl;
  final int listens;
  const ChartEntry({
    required this.name,
    required this.artist,
    required this.imageUrl,
    required this.listens,
  });
}

class ListenBrainzService {
  static const _host    = 'api.listenbrainz.org';
  static const _timeout = Duration(seconds: 15);

  /// entity: 'artists' | 'tracks' | 'albums'  ·  range: 'week' | 'month' | 'year' | 'all_time'
  static Future<List<ChartEntry>> sitewide(String entity, String range,
      {int limit = 24}) async {
    final path = switch (entity) {
      'tracks' => 'recordings',
      'albums' => 'release-groups',
      _        => 'artists',
    };
    final uri = Uri.https(_host, '/1/stats/sitewide/$path', {
      'range': range,
      'count': '$limit',
    });
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) return [];
    final body    = jsonDecode(utf8.decode(res.bodyBytes));
    final payload = body is Map ? body['payload'] : null;
    if (payload is! Map) return [];
    final key  = switch (entity) {
      'tracks' => 'recordings',
      'albums' => 'release_groups',
      _        => 'artists',
    };
    final list = payload[key];
    if (list is! List) return [];

    final out = <ChartEntry>[];
    for (final e in list) {
      if (e is! Map) continue;
      final String name = switch (entity) {
        'tracks' => (e['track_name'] ?? '').toString(),
        'albums' => (e['release_group_name'] ?? '').toString(),
        _        => (e['artist_name'] ?? '').toString(),
      };
      if (name.isEmpty) continue;
      final artist = entity == 'artists' ? '' : (e['artist_name'] ?? '').toString();
      final caaId  = e['caa_id'];
      final caaMbid = (e['caa_release_mbid'] ?? '').toString();
      final img = (entity != 'artists' && caaId != null && caaMbid.isNotEmpty)
          ? 'https://coverartarchive.org/release/$caaMbid/$caaId-500.jpg'
          : '';
      out.add(ChartEntry(
        name: name,
        artist: artist,
        imageUrl: img,
        listens: int.tryParse((e['listen_count'] ?? '0').toString()) ?? 0,
      ));
    }
    return out;
  }
}
