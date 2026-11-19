// lib/services/lb_adapter.dart
// ══════════════════════════════════════════════════════════════════════════
//  ListenBrainz adapter.
//
//  The whole app talks to LastFmService, which asks "Last.fm methods"
//  (user.getTopArtists, user.getRecentTracks, ...) and reads Last.fm-shaped
//  JSON. In ListenBrainz mode, LastFmService._call sends the request here
//  instead: we call the ListenBrainz API and answer with the same JSON shape.
//  So every screen works unchanged and Last.fm is never contacted.
//
//  ListenBrainz API docs:
//  https://listenbrainz.readthedocs.io/en/latest/users/api/index.html
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'api_http.dart';
import 'listenbrainz_service.dart';

class LbAdapter {
  static const _host    = 'api.listenbrainz.org';
  static const _timeout = Duration(seconds: 20);
  static const _maxListens = 100; // listens per request (safe for every server)

  // Last.fm period -> ListenBrainz range
  static const _ranges = {
    'overall': 'all_time', '7day': 'week', '1month': 'month',
    '3month': 'quarter', '6month': 'half_yearly', '12month': 'year',
  };

  // ── HTTP helper: returns the "payload" map, or null (204 / 404 / error) ──
  static Future<Map<String, dynamic>?> _get(String path,
      [Map<String, String>? q]) async {
    final res = await ApiHttp.get(Uri.https(_host, path, q)).timeout(_timeout);
    if (res.statusCode == 204 || res.statusCode == 404) return null;
    if (res.statusCode == 429) throw Exception('ListenBrainz rate limit reached (HTTP 429)');
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map) return null;
    final p = body['payload'];
    return p is Map<String, dynamic> ? p : Map<String, dynamic>.from(body);
  }

  // ── Small builders (Last.fm shape) ──────────────────────────────────────
  static List<Map<String, String>> _img(String url) => [
    for (final s in const ['small', 'medium', 'large', 'extralarge'])
      {'#text': url, 'size': s},
  ];

  static String _cover(dynamic caaId, dynamic releaseMbid) {
    if (caaId == null || releaseMbid == null) return '';
    return 'https://coverartarchive.org/release/$releaseMbid/$caaId-250.jpg';
  }

  static String _s(dynamic v) => v == null ? '' : v.toString();
  static int _i(dynamic v) => v is int ? v : int.tryParse(_s(v)) ?? 0;

  static Map<String, dynamic> _attr(String user, int page, int perPage,
          int total) =>
      {
        'user': user, 'page': '$page', 'perPage': '$perPage', 'total': '$total',
        'totalPages': '${total == 0 ? 0 : ((total + perPage - 1) ~/ perPage)}',
      };

  // ── Entry point ─────────────────────────────────────────────────────────
  static Future<dynamic> call(Map<String, String> p, String username) async {
    final method = p['method'] ?? '';
    final user   = (p['user'] != null && p['user']!.isNotEmpty) ? p['user']! : username;
    final limit  = int.tryParse(p['limit'] ?? '') ?? 50;
    final page   = int.tryParse(p['page'] ?? '') ?? 1;

    switch (method) {
      case 'user.getInfo':         return _userInfo(user);
      case 'user.getTopArtists':   return _topArtists(user, p['period'], limit, page);
      case 'user.getTopAlbums':    return _topAlbums(user, p['period'], limit, page);
      case 'user.getTopTracks':    return _topTracks(user, p['period'], limit, page);
      case 'user.getRecentTracks': return _recent(user, limit, page, p['from'], p['to']);
      case 'user.getLovedTracks':  return _loved(user, limit);
      case 'user.getFriends':      return _friends(user, limit);
      case 'user.search':          return _searchUsers(p['user'] ?? '');

      // Global charts: real, time-ranged ListenBrainz sitewide stats
      case 'chart.getTopArtists':  return _chartArtists(limit);
      case 'chart.getTopTracks':
      case 'geo.getTopTracks':
      case 'tag.getTopTracks':     return _chartTracks(limit);

      // Artist details, tags and search: MusicBrainz (the database behind ListenBrainz)
      case 'artist.getInfo':       return _artistInfo(p['artist'] ?? '', p['mbid']);
      case 'artist.getTopTags':
        return {'toptags': {'tag': await _artistTags(p['artist'] ?? '', p['mbid'])}};
      case 'artist.search':        return _mbSearchArtists(p['artist'] ?? '', limit, page);
      case 'album.search':         return _mbSearchAlbums(p['album'] ?? '', limit, page);
      case 'track.search':         return _mbSearchTracks(p['track'] ?? '', limit, page);

      // Not provided by ListenBrainz: empty answers, the app hides these parts
      case 'album.getInfo':
        return {'album': {
          'name': p['album'] ?? '', 'artist': p['artist'] ?? '', 'url': '',
          'tags': {'tag': []}, 'tracks': {'track': []},
        }};
      case 'track.getInfo':
        return {'track': {
          'name': p['track'] ?? '', 'artist': {'name': p['artist'] ?? ''},
          'toptags': {'tag': []},
        }};
      case 'artist.getSimilar':    return {'similarartists': {'artist': []}};
      case 'artist.getTopTracks':  return {'toptracks': {'track': []}};
      case 'artist.getTopAlbums':  return {'topalbums': {'album': []}};
    }
    throw Exception('Not available with ListenBrainz ($method)');
  }

  // ── user.getInfo ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _userInfo(String user) async {
    final count = await _get('/1/user/${Uri.encodeComponent(user)}/listen-count');
    if (count == null) throw Exception('User not found');
    // The oldest listen gives a "member since" date
    int since = 0;
    try {
      final l = await _get('/1/user/${Uri.encodeComponent(user)}/listens',
          {'count': '1', 'time_range': '1'});
      since = _i(l?['oldest_listen_ts']);
    } catch (_) {}
    return {'user': {
      'name': user, 'realname': user,
      'url': 'https://listenbrainz.org/user/${Uri.encodeComponent(user)}/',
      'playcount': '${_i(count['count'])}', 'country': '',
      'registered': {'unixtime': '$since', '#text': '$since'},
      'image': _img(''),
    }};
  }

  // ── Top lists (ListenBrainz user statistics) ────────────────────────────
  static Future<Map<String, dynamic>?> _stats(
      String user, String entity, String? period, int limit, int page) {
    return _get('/1/stats/user/${Uri.encodeComponent(user)}/$entity', {
      'range':  _ranges[period ?? 'overall'] ?? 'all_time',
      'count':  '$limit',
      'offset': '${(page - 1) * limit}',
    });
  }

  static Future<Map<String, dynamic>> _topArtists(
      String user, String? period, int limit, int page) async {
    final d = await _stats(user, 'artists', period, limit, page);
    final list = (d?['artists'] as List?) ?? [];
    final total = _i(d?['total_artist_count']);
    return {'topartists': {
      'artist': [for (var i = 0; i < list.length; i++) {
        'name': _s(list[i]['artist_name']),
        'mbid': _s(list[i]['artist_mbid']),
        'playcount': '${_i(list[i]['listen_count'])}',
        'url': '', 'image': _img(''),
        '@attr': {'rank': '${(page - 1) * limit + i + 1}'},
      }],
      '@attr': _attr(user, page, limit, total),
    }};
  }

  static Future<Map<String, dynamic>> _topAlbums(
      String user, String? period, int limit, int page) async {
    final d = await _stats(user, 'release-groups', period, limit, page);
    final list = (d?['release_groups'] as List?) ?? [];
    final total = _i(d?['total_release_group_count']);
    return {'topalbums': {
      'album': [for (var i = 0; i < list.length; i++) {
        'name': _s(list[i]['release_group_name']),
        'mbid': _s(list[i]['release_group_mbid']),
        'playcount': '${_i(list[i]['listen_count'])}',
        'artist': {'name': _s(list[i]['artist_name']), 'mbid': ''},
        'url': '',
        'image': _img(_cover(list[i]['caa_id'], list[i]['caa_release_mbid'])),
        '@attr': {'rank': '${(page - 1) * limit + i + 1}'},
      }],
      '@attr': _attr(user, page, limit, total),
    }};
  }

  static Future<Map<String, dynamic>> _topTracks(
      String user, String? period, int limit, int page) async {
    final d = await _stats(user, 'recordings', period, limit, page);
    final list = (d?['recordings'] as List?) ?? [];
    final total = _i(d?['total_recording_count']);
    return {'toptracks': {
      'track': [for (var i = 0; i < list.length; i++) {
        'name': _s(list[i]['track_name']),
        'mbid': _s(list[i]['recording_mbid']),
        'playcount': '${_i(list[i]['listen_count'])}',
        'artist': {'name': _s(list[i]['artist_name']), 'mbid': ''},
        'url': '', 'duration': '0',
        'image': _img(_cover(list[i]['caa_id'], list[i]['caa_release_mbid'])),
        '@attr': {'rank': '${(page - 1) * limit + i + 1}'},
      }],
      '@attr': _attr(user, page, limit, total),
    }};
  }

  // ── Recent listens ──────────────────────────────────────────────────────
  // Last.fm pages by number, ListenBrainz by timestamp: we remember, for each
  // page, the timestamp where the next page starts.
  static final Map<String, int> _cursor = {};
  static final Map<String, ({int at, int n})> _countCache = {};
  static final Map<String, ({int at, Map<int, int> m})> _actCache = {};

  static String _date(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    String t(int v) => v.toString().padLeft(2, '0');
    return '${d.day} ${m[d.month - 1]} ${d.year}, ${t(d.hour)}:${t(d.minute)}';
  }

  static Map<String, dynamic> _trackFrom(Map l, {bool playing = false}) {
    final tm   = (l['track_metadata'] as Map?) ?? {};
    final map  = (tm['mbid_mapping'] as Map?) ?? {};
    final info = (tm['additional_info'] as Map?) ?? {};
    final rel  = _s(tm['release_name']);
    final ts   = _i(l['listened_at']);
    return {
      'name': _s(tm['track_name']),
      'mbid': _s(map['recording_mbid'] ?? info['recording_mbid']),
      'url': '',
      'artist': {'#text': _s(tm['artist_name']), 'name': _s(tm['artist_name']), 'mbid': ''},
      'album':  {'#text': rel, 'mbid': ''},
      'image':  _img(_cover(map['caa_id'], map['caa_release_mbid'])),
      if (!playing) 'date': {'uts': '$ts', '#text': _date(ts)},
      if (playing) '@attr': {'nowplaying': 'true'},
    };
  }

  static Future<int> _listenCount(String user) async {
    final c = _countCache[user];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (c != null && now - c.at < 60000) return c.n;
    final d = await _get('/1/user/${Uri.encodeComponent(user)}/listen-count');
    final n = _i(d?['count']);
    _countCache[user] = (at: now, n: n);
    return n;
  }

  // Number of listens between two timestamps (used by the monthly chart).
  // Uses the per-month "listening activity" statistics.
  static Future<int> _countRange(String user, int from, int to) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    var total = 0;
    for (final range in const ['this_year', 'year']) {
      final key = '$user|$range';
      var c = _actCache[key];
      if (c == null || now - c.at > 600000) {
        final d = await _get(
            '/1/stats/user/${Uri.encodeComponent(user)}/listening-activity',
            {'range': range});
        final list = (d?['listening_activity'] as List?) ?? [];
        c = (at: now, m: {for (final e in list) _i(e['from_ts']): _i(e['listen_count'])});
        _actCache[key] = c;
      }
      c.m.forEach((fromTs, n) { if (fromTs >= from && fromTs < to) total += n; });
    }
    return total;
  }

  static Future<Map<String, dynamic>> _recent(
      String user, int limit, int page, String? from, String? to) async {
    final lim   = limit < 1 ? 1 : (limit > _maxListens ? _maxListens : limit);
    final fromT = int.tryParse(from ?? '');
    final toT   = int.tryParse(to ?? '');
    final enc   = Uri.encodeComponent(user);

    // Monthly counter: only the total matters
    if (fromT != null && toT != null && limit == 1) {
      final n = await _countRange(user, fromT, toT);
      return {'track': [], '@attr': {'user': user, 'page': '1', 'perPage': '1',
          'total': '$n', 'totalPages': '$n'}};
    }

    // Where does this page start?
    final ckey = '$user|$fromT|$toT|$lim';
    int? maxTs = toT;
    if (page > 1) {
      // start from the nearest page we already know, then walk forward
      var p = 1;
      int? max = toT;
      for (var k = page; k >= 2; k--) {
        final c = _cursor['$ckey|$k'];
        if (c != null) { p = k; max = c; break; }
      }
      while (p < page) {
        final w = await _get('/1/user/$enc/listens', {
          'count': '$lim', if (max != null) 'max_ts': '$max',
          if (fromT != null) 'min_ts': '$fromT',
        });
        final wl = (w?['listens'] as List?) ?? [];
        if (wl.isEmpty) {
          return {'track': [], '@attr': _attr(user, page, lim, 0)};
        }
        max = _i(wl.last['listened_at']);
        p++;
        _cursor['$ckey|$p'] = max;
      }
      maxTs = max;
    }

    final r = await _get('/1/user/$enc/listens', {
      'count': '$lim', if (maxTs != null) 'max_ts': '$maxTs',
      if (fromT != null) 'min_ts': '$fromT',
    });
    final ls = ((r?['listens'] as List?) ?? []).whereType<Map>().toList();
    if (ls.isNotEmpty) _cursor['$ckey|${page + 1}'] = _i(ls.last['listened_at']);

    final tracks = <Map<String, dynamic>>[];
    // Now playing comes first (first page, no date range)
    if (page == 1 && fromT == null && toT == null) {
      try {
        final np = await _get('/1/user/$enc/playing-now');
        final pl = (np?['listens'] as List?) ?? [];
        if (np?['playing_now'] == true && pl.isNotEmpty) {
          tracks.add(_trackFrom(pl.first as Map, playing: true));
        }
      } catch (_) {}
    }
    tracks.addAll(ls.map((l) => _trackFrom(l)));

    int total;
    if (fromT == null && toT == null) {
      total = await _listenCount(user);
    } else {
      // unknown total: say "one more page" while the page is full
      total = (page - 1) * lim + ls.length + (ls.length == lim ? 1 : 0);
    }
    return {'track': tracks, '@attr': _attr(user, page, lim, total)};
  }

  // ── Loved tracks = ListenBrainz "love" feedback ─────────────────────────
  static Future<Map<String, dynamic>> _loved(String user, int limit) async {
    final d = await _get(
        '/1/feedback/user/${Uri.encodeComponent(user)}/get-feedback',
        {'score': '1', 'count': '$limit', 'metadata': 'true'});
    final fb = (d?['feedback'] as List?) ?? [];
    return {'lovedtracks': {
      'track': [for (final f in fb.whereType<Map>()) {
        ..._trackFrom({
          'track_metadata': f['track_metadata'] ?? {},
          'listened_at': f['created'] ?? 0,
        }),
      }],
      '@attr': {'user': user, 'total': '${_i(d?['total_count'])}'},
    }};
  }

  // ── Friends = people you follow ─────────────────────────────────────────
  static Future<Map<String, dynamic>> _friends(String user, int limit) async {
    final d = await _get('/1/user/${Uri.encodeComponent(user)}/following');
    final names = ((d?['following'] as List?) ?? []).map(_s).toList();
    return {'friends': {
      'user': [for (final n in names.take(limit)) {
        'name': n, 'realname': n, 'playcount': '0',
        'url': 'https://listenbrainz.org/user/${Uri.encodeComponent(n)}/',
        'image': _img(''),
      }],
    }};
  }

  static Future<Map<String, dynamic>> _searchUsers(String q) async {
    final d = await _get('/1/search/users/', {'search_term': q});
    final users = (d?['users'] as List?) ?? [];
    return {'results': {'usermatches': {
      'user': [for (final u in users.whereType<Map>()) {
        'name': _s(u['user_name']), 'realname': _s(u['user_name']),
        'url': 'https://listenbrainz.org/user/${Uri.encodeComponent(_s(u['user_name']))}/',
        'image': _img(''),
      }],
    }}};
  }

  // ── Global charts (sitewide statistics) ─────────────────────────────────
  static Future<Map<String, dynamic>> _chartArtists(int limit) async {
    final l = await ListenBrainzService.sitewide('artists', 'week', limit: limit);
    return {'artists': {'artist': [for (final e in l) {
      'name': e.name, 'playcount': '${e.listens}', 'listeners': '${e.listens}',
      'url': '', 'image': _img(e.imageUrl),
    }]}};
  }

  static Future<Map<String, dynamic>> _chartTracks(int limit) async {
    final l = await ListenBrainzService.sitewide('tracks', 'week', limit: limit);
    return {'tracks': {'track': [for (final e in l) {
      'name': e.name, 'playcount': '${e.listens}', 'listeners': '${e.listens}',
      'artist': {'name': e.artist}, 'url': '', 'image': _img(e.imageUrl),
    }]}};
  }

  // ══ MusicBrainz (artist details, tags, search) ═══════════════════════════
  // Rules: a descriptive User-Agent is required and max ~1 request/second.
  // Docs: https://musicbrainz.org/doc/MusicBrainz_API
  static DateTime _mbLast = DateTime.fromMillisecondsSinceEpoch(0);
  static final Map<String, dynamic> _mbCache = {};

  static Future<Map<String, dynamic>?> _mb(String path, Map<String, String> q) async {
    final key = '$path?${q.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    if (_mbCache.containsKey(key)) return _mbCache[key];
    final wait = DateTime.now().difference(_mbLast).inMilliseconds;
    if (wait < 1100) await Future.delayed(Duration(milliseconds: 1100 - wait));
    _mbLast = DateTime.now();
    final res = await ApiHttp.get(
      Uri.https('musicbrainz.org', '/ws/2/$path', {...q, 'fmt': 'json'}),
      headers: const {
        'User-Agent': 'LastStats/4 (https://github.com/SanoBld/LastStats)',
        'Accept': 'application/json',
      },
    ).timeout(_timeout);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final m = body is Map<String, dynamic> ? body : null;
    _mbCache[key] = m;
    return m;
  }

  static String _credit(dynamic ac) =>
      ((ac as List?) ?? []).whereType<Map>().map((e) => _s(e['name'])).join('');

  static Future<String?> _artistId(String name, String? mbid) async {
    if (mbid != null && mbid.isNotEmpty) return mbid;
    if (name.isEmpty) return null;
    final d = await _mb('artist', {'query': 'artist:"${name.replaceAll('"', '')}"', 'limit': '1'});
    final l = (d?['artists'] as List?) ?? [];
    return l.isEmpty ? null : _s(l.first['id']);
  }

  static Future<List<Map<String, dynamic>>> _artistTags(String name, String? mbid) async {
    try {
      final id = await _artistId(name, mbid);
      if (id == null) return [];
      final d = await _mb('artist/$id', {'inc': 'tags+genres'});
      final tags = [...((d?['genres'] as List?) ?? []), ...((d?['tags'] as List?) ?? [])]
          .whereType<Map>().toList()
        ..sort((a, b) => _i(b['count']).compareTo(_i(a['count'])));
      final seen = <String>{};
      return <Map<String, dynamic>>[for (final t in tags)
        if (seen.add(_s(t['name']).toLowerCase()))
          {'name': _s(t['name']), 'url': ''}].take(8).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> _artistInfo(String name, String? mbid) async {
    return {'artist': {
      'name': name, 'url': '', 'mbid': mbid ?? '',
      'tags': {'tag': await _artistTags(name, mbid)},
      'similar': {'artist': []},
      // empty bio: the app then loads the Wikipedia summary by itself
      'bio': {'summary': '', 'content': ''},
    }};
  }

  static Map<String, dynamic> _matches(String key, String sub, List items, int total) =>
      {'results': {
        '${key}matches': {sub: items},
        'opensearch:totalResults': '$total',
      }};

  static Future<Map<String, dynamic>> _mbSearchArtists(String q, int limit, int page) async {
    final d = await _mb('artist', {'query': q, 'limit': '$limit', 'offset': '${(page - 1) * limit}'});
    final l = (d?['artists'] as List?) ?? [];
    return _matches('artist', 'artist', [for (final a in l.whereType<Map>()) {
      'name': _s(a['name']), 'mbid': _s(a['id']), 'url': '', 'listeners': '0',
      'image': _img(''),
    }], _i(d?['count']));
  }

  static Future<Map<String, dynamic>> _mbSearchAlbums(String q, int limit, int page) async {
    final d = await _mb('release-group', {'query': q, 'limit': '$limit', 'offset': '${(page - 1) * limit}'});
    final l = (d?['release-groups'] as List?) ?? [];
    return _matches('album', 'album', [for (final a in l.whereType<Map>()) {
      'name': _s(a['title']), 'artist': _credit(a['artist-credit']),
      'mbid': _s(a['id']), 'url': '',
      'image': _img('https://coverartarchive.org/release-group/${_s(a['id'])}/front-250'),
    }], _i(d?['count']));
  }

  static Future<Map<String, dynamic>> _mbSearchTracks(String q, int limit, int page) async {
    final d = await _mb('recording', {'query': q, 'limit': '$limit', 'offset': '${(page - 1) * limit}'});
    final l = (d?['recordings'] as List?) ?? [];
    return _matches('track', 'track', [for (final t in l.whereType<Map>()) {
      'name': _s(t['title']), 'artist': _credit(t['artist-credit']),
      'mbid': _s(t['id']), 'url': '', 'listeners': '0', 'image': _img(''),
    }], _i(d?['count']));
  }

  // ══ Love / unlove = ListenBrainz feedback ════════════════════════════════
  // 1) find the recording MBID: GET /1/metadata/lookup/
  // 2) POST /1/feedback/recording-feedback {"recording_mbid", "score": 1 | 0}
  static Future<dynamic> callSigned(Map<String, String> p, String token) async {
    final method = p['method'] ?? '';
    if (method != 'track.love' && method != 'track.unlove') {
      throw Exception('Not available with ListenBrainz ($method)');
    }
    final look = await _get('/1/metadata/lookup/', {
      'artist_name': p['artist'] ?? '', 'recording_name': p['track'] ?? '',
    });
    final mbid = _s(look?['recording_mbid']);
    if (mbid.isEmpty) throw Exception('Recording not found');
    final res = await ApiHttp.post(
      Uri.https(_host, '/1/feedback/recording-feedback'),
      headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'recording_mbid': mbid, 'score': method == 'track.love' ? 1 : 0}),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return {};
  }
}
