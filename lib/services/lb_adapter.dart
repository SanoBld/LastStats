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

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/extra_strings.dart';
import 'account_manager.dart';
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

  // Network errors (e.g. "Connection terminated during handshake") are often
  // transient: retry a few times (fresh connection each time, growing pause)
  // before giving up, then show a readable message instead of the raw error.
  static bool _isNet(Object e) {
    final m = e.toString().toLowerCase();
    return m.contains('handshake') || m.contains('socket') ||
        m.contains('clientexception') || m.contains('timeout') ||
        m.contains('connection') || m.contains('failed host lookup');
  }

  // Reads with the user token get higher rate limits than anonymous ones
  // (ListenBrainz API docs, "Rate limiting"). Only sent to the main API host.
  static Future<Map<String, String>?> _authHeaders(Uri uri) async {
    if (uri.host != _host) return null;
    try {
      final p = await SharedPreferences.getInstance();
      final t = p.getString('ls_lb_token') ?? '';
      return t.isEmpty ? null : {'Authorization': 'Token $t'};
    } catch (_) {
      return null;
    }
  }

  // Short cache + de-duplication of identical in-flight calls: ListenBrainz
  // allows ~1 call per second, so every avoided call matters.
  static final Map<String, http.Response> _cache = {};
  static final Map<String, int> _cacheAt = {};
  static final Map<String, Future<http.Response>> _inflight = {};
  static const _cacheTtlMs = 60 * 1000;

  // Paths are built with Uri.encodeComponent already. Uri.https would encode
  // the '%' again ("sano%20bld" -> "sano%2520bld") and the server would answer
  // 404 "user not found" for any name with a space or a special character.
  static Uri _uri(String host, String path, Map<String, String>? q) {
    final u = Uri.parse('https://$host$path');
    return (q == null || q.isEmpty) ? u : u.replace(queryParameters: q);
  }

  // Last answer seen, shown with errors so a failure can be traced.
  static String lastCode = '';

  static Future<dynamic> _getRetry(Uri uri) {
    final key = uri.toString();
    final at = _cacheAt[key];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (at != null && now - at < _cacheTtlMs && _cache[key] != null) {
      return Future.value(_cache[key]);
    }
    return _inflight.putIfAbsent(key, () async {
      try {
        final res = await _fetch(uri);
        lastCode = 'HTTP ${res.statusCode} ${uri.path}';
        if (res.statusCode == 200) {
          _cache[key] = res;
          _cacheAt[key] = DateTime.now().millisecondsSinceEpoch;
          if (_cache.length > 150) {
            _cache.clear();
            _cacheAt.clear();
          }
        }
        return res;
      } finally {
        _inflight.remove(key);
      }
    });
  }

  static Future<http.Response> _fetch(Uri uri) async {
    Object? last;
    final headers = await _authHeaders(uri);
    for (var i = 0; i < 4; i++) {
      try {
        final res = await ApiHttp.get(uri, headers: headers, timeout: _timeout);
        // 429: wait for the window the server announces, then try again
        if (res.statusCode == 429 && i < 3) {
          final secs = int.tryParse(res.headers['x-ratelimit-reset-in'] ??
                  res.headers['retry-after'] ?? '') ??
              (i + 1) * 2;
          await Future.delayed(Duration(seconds: secs.clamp(1, 10)));
          continue;
        }
        // 5xx answers are usually momentary too
        if (res.statusCode >= 500 && i < 3) {
          await Future.delayed(Duration(milliseconds: 700 * (i + 1)));
          continue;
        }
        return res;
      } catch (e) {
        last = e;
        await Future.delayed(Duration(milliseconds: 700 * (i + 1)));
      }
    }
    if (last != null && _isNet(last)) {
      // Keep the technical reason visible (blocked TLS, timeout, DNS...)
      var why = last.toString().replaceAll('\n', ' ');
      if (why.length > 110) why = why.substring(0, 110);
      throw Exception('${tx('lb_neterr')}\nCode: $why');
    }
    throw last!;
  }

  // Same as _get, but returns whatever the endpoint answers (some
  // "popularity" / labs endpoints answer with a bare JSON list).
  static Future<dynamic> _getAny(String path,
      [Map<String, String>? q, String host = _host]) async {
    final res = await _getRetry(_uri(host, path, q));
    if (res.statusCode == 204 || res.statusCode == 404 || res.statusCode == 410) return null;
    if (res.statusCode != 200) throw Exception('ListenBrainz error\nCode: HTTP ${res.statusCode} ${res.request?.url.path ?? ''}');
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is Map && body['payload'] != null) return body['payload'];
    return body;
  }

  // ── HTTP helper: returns the "payload" map, or null (204 / 404 / error) ──
  static Future<Map<String, dynamic>?> _get(String path,
      [Map<String, String>? q]) async {
    final res = await _getRetry(_uri(_host, path, q));
    if (res.statusCode == 204 || res.statusCode == 404 || res.statusCode == 410) return null;
    if (res.statusCode == 429) throw Exception('ListenBrainz rate limit reached\nCode: HTTP 429 ${res.headers['x-laststats-skipped'] == '1' ? '(client limiter)' : '(server)'}');
    if (res.statusCode != 200) throw Exception('ListenBrainz error\nCode: HTTP ${res.statusCode} ${res.request?.url.path ?? ''}');
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
    final rawUser = (p['user'] != null && p['user']!.isNotEmpty) ? p['user']! : username;
    final user    = _alias[rawUser] ?? rawUser;
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
      case 'artist.getSimilar':    return _similar(p['artist'] ?? '', p['mbid'], limit);
      case 'artist.getTopTracks':  return _artistTopTracks(p['artist'] ?? '', p['mbid'], limit);
      case 'artist.getTopAlbums':  return _artistTopAlbums(p['artist'] ?? '', p['mbid'], limit);
      case 'album.getInfo':        return _albumInfo(p['album'] ?? '', p['artist'] ?? '', p['mbid']);
      case 'track.getInfo':        return _trackInfo(p['track'] ?? '', p['artist'] ?? '');
      case 'artist.search':        return _mbSearchArtists(p['artist'] ?? '', limit, page);
      case 'album.search':         return _mbSearchAlbums(p['album'] ?? '', limit, page);
      case 'track.search':         return _mbSearchTracks(p['track'] ?? '', limit, page);

    }
    throw Exception('Not available with ListenBrainz ($method)');
  }

  // ── user.getInfo ────────────────────────────────────────────────────────
  // Old Last.fm user names can stay in the saved accounts after a switch to
  // ListenBrainz: "listen-count" then answers 404. We re-ask the token which
  // user it belongs to and use that name from then on.
  static final Map<String, String> _alias = {};

  static Future<String?> _healUser(String stale) async {
    try {
      final p = await SharedPreferences.getInstance();
      final token = p.getString('ls_lb_token') ?? '';
      if (token.isEmpty) return null;
      final res = await ApiHttp.get(
        Uri.https(_host, '/1/validate-token'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(_timeout);
      final b = jsonDecode(utf8.decode(res.bodyBytes));
      final name = (b is Map && b['valid'] == true) ? _s(b['user_name']) : '';
      if (name.isEmpty || name.toLowerCase() == stale.toLowerCase()) return null;
      _alias[stale] = name;
      await p.setString('ls_username', name);
      await p.setString('ls_lb_username', name);
      await AccountManager.setSingle(AccountEntry(username: name, apiKey: token));
      return name;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> _userInfo(String user) async {
    var u = user;
    Future<Map<String, dynamic>?> count() =>
        _get('/1/user/${Uri.encodeComponent(u)}/listen-count');

    var c = await count();
    if (c == null) {
      // The account may exist without any listen yet
      final probe = await _get('/1/user/${Uri.encodeComponent(u)}/listens', {'count': '1'});
      if (probe != null) c = {'count': 0};
    }
    if (c == null) {
      final healed = await _healUser(u);
      if (healed != null) {
        u = healed;
        c = await count();
      }
    }
    if (c == null) throw Exception('User not found\nCode: $lastCode');
    // The oldest listen gives a "member since" date
    int since = 0;
    try {
      final l = await _get('/1/user/${Uri.encodeComponent(u)}/listens',
          {'count': '1', 'time_range': '1'});
      since = _i(l?['oldest_listen_ts']);
    } catch (_) {}
    return {'user': {
      'name': u, 'realname': u,
      'url': 'https://listenbrainz.org/user/${Uri.encodeComponent(u)}/',
      'playcount': '${_i(c['count'])}', 'country': '',
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
    final fromT = int.tryParse(from ?? '');
    final toT   = int.tryParse(to ?? '');
    final ranged = fromT != null || toT != null;
    // History loading (big pages) -> 1000 listens per call = ~10x fewer calls
    final cap = (ranged && limit >= 200) ? 1000 : _maxListens;
    final lim = limit < 1 ? 1 : (limit > cap ? cap : limit);
    final enc = Uri.encodeComponent(user);

    // Monthly counter: only the total matters
    if (fromT != null && toT != null && limit == 1) {
      final n = await _countRange(user, fromT, toT);
      return {'track': [], '@attr': {'user': user, 'page': '1', 'perPage': '1',
          'total': '$n', 'totalPages': '$n'}};
    }

    // ListenBrainz docs: never send min_ts AND max_ts together. We page
    // downwards with max_ts only and cut at fromT on our side.
    Future<List<Map>> fetch(int? max) async {
      final r = await _get('/1/user/$enc/listens', {
        'count': '$lim', if (max != null) 'max_ts': '$max',
      });
      return ((r?['listens'] as List?) ?? []).whereType<Map>().toList();
    }

    final ckey = '$user|$fromT|$toT|$lim';
    int? maxTs = toT;
    if (page > 1) {
      var p = 1;
      int? max = toT;
      for (var k = page; k >= 2; k--) {
        final c = _cursor['$ckey|$k'];
        if (c != null) { p = k; max = c; break; }
      }
      while (p < page) {
        final wl = await fetch(max);
        if (wl.isEmpty || (fromT != null && _i(wl.last['listened_at']) < fromT)) {
          return {'track': [], '@attr': _attr(user, page, lim, 0)};
        }
        max = _i(wl.last['listened_at']);
        p++;
        _cursor['$ckey|$p'] = max;
      }
      maxTs = max;
    }

    var ls = await fetch(maxTs);
    var reachedStart = false;
    if (ls.isNotEmpty) _cursor['$ckey|${page + 1}'] = _i(ls.last['listened_at']);
    if (fromT != null) {
      if (ls.isNotEmpty && _i(ls.last['listened_at']) < fromT) reachedStart = true;
      ls = ls.where((l) => _i(l['listened_at']) >= fromT).toList();
    }

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
      total = (!reachedStart && ls.isNotEmpty)
          ? page * lim + 1 // maybe more: ask for one more page
          : (page - 1) * lim + ls.length;
    }
    return {'track': tracks, '@attr': _attr(user, page, lim, total)};
  }

  // ── History download (local storage) ────────────────────────────────────
  // Direct ListenBrainz loader used by AllScrobblesService: pages downwards
  // with max_ts (1000 listens per call), stops at [fromTs]. Bypasses the
  // short response cache so a sync never reads stale data. Throws on any
  // failed page so the caller never stores a partial range as complete.
  static Future<List<({int ts, String track, String artist, String album})>>
      fetchRange(String user, {int? fromTs, int? toTs,
          void Function(int loaded)? onProgress}) async {
    final name = _alias[user] ?? user;
    final enc = Uri.encodeComponent(name);
    final out = <({int ts, String track, String artist, String album})>[];
    int? max = toTs;
    while (true) {
      final res = await _fetch(_uri(_host, '/1/user/$enc/listens', {
        'count': '1000', if (max != null) 'max_ts': '$max',
      }));
      if (res.statusCode == 204 || res.statusCode == 404) break;
      if (res.statusCode != 200) {
        throw Exception('ListenBrainz error\nCode: HTTP ${res.statusCode}');
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final payload = body is Map ? body['payload'] : null;
      final ls = ((payload is Map ? payload['listens'] : null) as List? ?? [])
          .whereType<Map>().toList();
      if (ls.isEmpty) break;
      var reached = false;
      for (final l in ls) {
        final ts = _i(l['listened_at']);
        if (ts <= 0) continue;
        if (fromTs != null && ts < fromTs) { reached = true; continue; }
        final tm = (l['track_metadata'] as Map?) ?? {};
        out.add((ts: ts, track: _s(tm['track_name']),
            artist: _s(tm['artist_name']), album: _s(tm['release_name'])));
      }
      onProgress?.call(out.length);
      final last = _i(ls.last['listened_at']);
      if (reached || ls.length < 1000 || last <= 0) break;
      max = last; // max_ts is exclusive
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return out;
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
  static final Map<String, Map<String, dynamic>> _mbCache = {};
  // All MusicBrainz calls go through one queue: the "All" search tab asks for
  // artists, albums and tracks at the same time, and without a queue those
  // requests left together and were refused (HTTP 503) -> empty results.
  static Future<void> _mbQueue = Future<void>.value();

  static Future<Map<String, dynamic>?> _mb(String path, Map<String, String> q) {
    final key = '$path?${q.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final hit = _mbCache[key];
    if (hit != null) return Future.value(hit);
    final prev = _mbQueue;
    final gate = Completer<void>();
    _mbQueue = gate.future;
    return () async {
      try {
        await prev;
        final again = _mbCache[key];
        if (again != null) return again;
        for (var attempt = 0; attempt < 2; attempt++) {
          final wait = DateTime.now().difference(_mbLast).inMilliseconds;
          if (wait < 1100) await Future.delayed(Duration(milliseconds: 1100 - wait));
          _mbLast = DateTime.now();
          try {
            final res = await ApiHttp.get(
              Uri.https('musicbrainz.org', '/ws/2/$path', {...q, 'fmt': 'json'}),
              headers: const {
                'User-Agent': ApiHttp.userAgent,
                'Accept': 'application/json',
              },
            ).timeout(_timeout);
            if (res.statusCode == 503 || res.statusCode == 429) {
              await Future.delayed(const Duration(milliseconds: 1500));
              continue; // one more try
            }
            if (res.statusCode != 200) return null;
            final body = jsonDecode(utf8.decode(res.bodyBytes));
            if (body is! Map<String, dynamic>) return null;
            _mbCache[key] = body;
            return body;
          } catch (_) {
            if (attempt == 1) return null;
          }
        }
        return null;
      } finally {
        gate.complete();
      }
    }();
  }

  // Lucene special characters must be escaped, otherwise searches such as
  // "AC/DC", "P!nk" or "Sigur Rós (live)" make MusicBrainz answer an error.
  static final _luceneSpecial = RegExp(r'([+\-!(){}\[\]^"~*?:\\/]|&&|\|\|)');
  static String _esc(String s) =>
      s.replaceAllMapped(_luceneSpecial, (m) => '\\${m[0]}');
  static String _phrase(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');

  /// "daft punk one": every word must be found in one of [fields]; the last
  /// word is a prefix, so results already show while the user is typing.
  static String _qry(String q, List<String> fields) {
    final toks = q.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final parts = <String>[];
    for (var i = 0; i < toks.length; i++) {
      var t = _esc(toks[i].toLowerCase());
      if (i == toks.length - 1 && toks[i].length >= 3) t = '$t*';
      parts.add('+(${fields.map((f) => '$f:$t').join(' ')})');
    }
    return parts.join(' ');
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
    final query = _qry(q, ['artist', 'alias']);
    if (query.isEmpty) return _matches('artist', 'artist', const [], 0);
    final d = await _mb('artist', {'query': query, 'limit': '$limit', 'offset': '${(page - 1) * limit}'});
    final l = (d?['artists'] as List?) ?? [];
    return _matches('artist', 'artist', [for (final a in l.whereType<Map>()) {
      'name': _s(a['name']), 'mbid': _s(a['id']), 'url': '', 'listeners': '0',
      'image': _img(''),
    }], _i(d?['count']));
  }

  static Future<Map<String, dynamic>> _mbSearchAlbums(String q, int limit, int page) async {
    final query = _qry(q, ['releasegroup', 'artist']);
    if (query.isEmpty) return _matches('album', 'album', const [], 0);
    final d = await _mb('release-group', {'query': query, 'limit': '$limit', 'offset': '${(page - 1) * limit}'});
    final l = (d?['release-groups'] as List?) ?? [];
    return _matches('album', 'album', [for (final a in l.whereType<Map>()) {
      'name': _s(a['title']), 'artist': _credit(a['artist-credit']),
      'mbid': _s(a['id']), 'url': '',
      'image': _img('https://coverartarchive.org/release-group/${_s(a['id'])}/front-250'),
    }], _i(d?['count']));
  }

  static Future<Map<String, dynamic>> _mbSearchTracks(String q, int limit, int page) async {
    final query = _qry(q, ['recording', 'artist']);
    if (query.isEmpty) return _matches('track', 'track', const [], 0);
    final d = await _mb('recording', {'query': query, 'limit': '$limit', 'offset': '${(page - 1) * limit}'});
    final l = (d?['recordings'] as List?) ?? [];
    return _matches('track', 'track', [for (final t in l.whereType<Map>()) {
      'name': _s(t['title']), 'artist': _credit(t['artist-credit']),
      'mbid': _s(t['id']), 'url': '', 'listeners': '0', 'image': _img(''),
    }], _i(d?['count']));
  }

  // ══ Artist pages without Last.fm ═════════════════════════════════════════
  // Top tracks / albums: ListenBrainz "popularity" statistics (by artist MBID).
  // Similar artists: ListenBrainz Labs. Album / track details: MusicBrainz.
  static const _simAlgo =
      'session_based_days_9000_session_300_contribution_5_threshold_15_limit_50_skip_30';

  static Future<Map<String, dynamic>> _similar(String name, String? mbid, int limit) async {
    try {
      final id = await _artistId(name, mbid);
      if (id == null) return {'similarartists': {'artist': []}};
      final d = await _getAny('/similar-artists/json',
          {'artist_mbids': id, 'algorithm': _simAlgo}, 'labs.api.listenbrainz.org');
      final list = (d is List ? d : const []).whereType<Map>()
          .where((a) => _s(a['artist_mbid']) != id).take(limit).toList();
      var top = 1;
      for (final a in list) {
        final sc = a['score'] is num ? (a['score'] as num).toInt() : 0;
        if (sc > top) top = sc;
      }
      return {'similarartists': {'artist': [for (final a in list) {
        'name': _s(a['name']), 'mbid': _s(a['artist_mbid']), 'url': '',
        'image': _img(''),
        'match': ((a['score'] is num ? (a['score'] as num) : 0) / top).toStringAsFixed(3),
      }]}};
    } catch (_) {
      return {'similarartists': {'artist': []}};
    }
  }

  static Future<Map<String, dynamic>> _artistTopTracks(String name, String? mbid, int limit) async {
    try {
      final id = await _artistId(name, mbid);
      final d = id == null ? null : await _getAny('/1/popularity/top-recordings-for-artist/$id');
      final list = d is List ? d : (d is Map ? ((d['recordings'] as List?) ?? const []) : const []);
      return {'toptracks': {'track': [for (final t in list.whereType<Map>().take(limit)) {
        'name': _s(t['recording_name']), 'mbid': _s(t['recording_mbid']),
        'playcount': '${_i(t['total_listen_count'])}',
        'listeners': '${_i(t['total_user_count'])}',
        'artist': {'name': _s(t['artist_name']).isEmpty ? name : _s(t['artist_name']), 'mbid': id ?? ''},
        'url': '', 'duration': '0',
        'image': _img(_cover(t['caa_id'], t['caa_release_mbid'])),
      }]}};
    } catch (_) {
      return {'toptracks': {'track': []}};
    }
  }

  static Future<Map<String, dynamic>> _artistTopAlbums(String name, String? mbid, int limit) async {
    try {
      final id = await _artistId(name, mbid);
      final d = id == null ? null : await _getAny('/1/popularity/top-release-groups-for-artist/$id');
      final list = d is List ? d : (d is Map ? ((d['release_groups'] as List?) ?? const []) : const []);
      return {'topalbums': {'album': [for (final a in list.whereType<Map>().take(limit)) {
        'name': _s(a['release_group_name']), 'mbid': _s(a['release_group_mbid']),
        'playcount': '${_i(a['total_listen_count'])}',
        'artist': {'name': _s(a['artist_name']).isEmpty ? name : _s(a['artist_name']), 'mbid': id ?? ''},
        'url': '',
        'image': _img(_cover(a['caa_id'], a['caa_release_mbid'])),
      }]}};
    } catch (_) {
      return {'topalbums': {'album': []}};
    }
  }

  static List<Map<String, dynamic>> _tagList(dynamic tags) {
    final l = ((tags as List?) ?? const []).whereType<Map>().toList()
      ..sort((a, b) => _i(b['count']).compareTo(_i(a['count'])));
    final seen = <String>{};
    return <Map<String, dynamic>>[for (final t in l)
      if (seen.add(_s(t['name']).toLowerCase())) {'name': _s(t['name']), 'url': ''}].take(8).toList();
  }

  static Future<Map<String, dynamic>> _albumInfo(String album, String artist, String? mbid) async {
    Map<String, dynamic> shell([String img = '']) => {'album': {
      'name': album, 'artist': artist, 'url': '', 'mbid': mbid ?? '',
      'image': _img(img), 'tags': {'tag': []}, 'tracks': {'track': []},
    }};
    try {
      var rg = mbid ?? '';
      if (rg.isEmpty) {
        if (album.isEmpty) return shell();
        final q = 'releasegroup:"${_phrase(album)}"'
            '${artist.isEmpty ? '' : ' AND artist:"${_phrase(artist)}"'}';
        final s = await _mb('release-group', {'query': q, 'limit': '1'});
        final l = (s?['release-groups'] as List?) ?? [];
        if (l.isEmpty) return shell();
        rg = _s((l.first as Map)['id']);
      }
      final cover = 'https://coverartarchive.org/release-group/$rg/front-500';
      final d = await _mb('release-group/$rg', {'inc': 'artist-credits+tags+genres+releases'});
      if (d == null) return shell(cover);
      final by = _credit(d['artist-credit']);
      final artistName = by.isEmpty ? artist : by;

      // Track list: the earliest official release of the album
      final rels = ((d['releases'] as List?) ?? const []).whereType<Map>().toList()
        ..sort((a, b) {
          final oa = _s(a['status']) == 'Official' ? 0 : 1;
          final ob = _s(b['status']) == 'Official' ? 0 : 1;
          if (oa != ob) return oa - ob;
          final da = _s(a['date']), db = _s(b['date']);
          if (da.isEmpty != db.isEmpty) return da.isEmpty ? 1 : -1;
          return da.compareTo(db);
        });
      final tracks = <Map<String, dynamic>>[];
      if (rels.isNotEmpty) {
        final r = await _mb('release/${_s(rels.first['id'])}', {'inc': 'recordings'});
        var n = 0;
        for (final m in ((r?['media'] as List?) ?? const []).whereType<Map>()) {
          for (final t in ((m['tracks'] as List?) ?? const []).whereType<Map>()) {
            n++;
            tracks.add({
              'name': _s(t['title']), 'url': '',
              'duration': '${_i(t['length']) ~/ 1000}',
              'artist': {'name': artistName},
              '@attr': {'rank': '$n'},
            });
          }
        }
      }
      return {'album': {
        'name': _s(d['title']).isEmpty ? album : _s(d['title']),
        'artist': artistName, 'mbid': rg,
        'url': 'https://musicbrainz.org/release-group/$rg',
        'image': _img(cover), 'listeners': '0', 'playcount': '0',
        'tags': {'tag': _tagList([...((d['genres'] as List?) ?? const []), ...((d['tags'] as List?) ?? const [])])},
        'tracks': {'track': tracks},
      }};
    } catch (_) {
      return shell();
    }
  }

  static Future<Map<String, dynamic>> _trackInfo(String track, String artist) async {
    Map<String, dynamic> shell() => {'track': {
      'name': track, 'artist': {'name': artist}, 'toptags': {'tag': []},
    }};
    try {
      if (track.isEmpty) return shell();
      final q = 'recording:"${_phrase(track)}"'
          '${artist.isEmpty ? '' : ' AND artist:"${_phrase(artist)}"'}';
      final s = await _mb('recording', {'query': q, 'limit': '1'});
      final l = (s?['recordings'] as List?) ?? [];
      if (l.isEmpty) return shell();
      final t = l.first as Map;
      final by = _credit(t['artist-credit']);
      final rels = ((t['releases'] as List?) ?? const []).whereType<Map>().toList();
      return {'track': {
        'name': _s(t['title']).isEmpty ? track : _s(t['title']),
        'mbid': _s(t['id']),
        'url': 'https://musicbrainz.org/recording/${_s(t['id'])}',
        'duration': '${_i(t['length'])}', // milliseconds, like Last.fm
        'listeners': '0', 'playcount': '0',
        'artist': {'name': by.isEmpty ? artist : by, 'mbid': ''},
        if (rels.isNotEmpty) 'album': {
          'title': _s(rels.first['title']), 'artist': by.isEmpty ? artist : by,
          'image': _img('https://coverartarchive.org/release/${_s(rels.first['id'])}/front-250'),
        },
        'toptags': {'tag': _tagList(t['tags'])},
      }};
    } catch (_) {
      return shell();
    }
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
    if (res.statusCode != 200) throw Exception('ListenBrainz error\nCode: HTTP ${res.statusCode} ${res.request?.url.path ?? ''}');
    return {};
  }
}
