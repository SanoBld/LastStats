import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'api_http.dart';
import 'library_merge.dart';
import 'internal_keys.dart';

class LastFmService {
  final String apiKey;
  final String username;
  // Optional — only needed for signed write calls (favorites auth + love/unlove).
  final String secret;
  final String sessionKey;

  static const _host    = 'ws.audioscrobbler.com';
  static const _path    = '/2.0/';
  static const _timeout = Duration(seconds: 15);

  const LastFmService({
    required this.apiKey,
    required this.username,
    this.secret     = '',
    this.sessionKey = '',
  });

  // ── Core request ────────────────────────────────────────
  // Optional built-in key, retried once when the user's key is INVALID or
  // SUSPENDED. A rate-limit answer (HTTP 429 / error 29) is deliberately NOT
  // retried with another key: the limit is enforced per IP address, and the
  // Last.fm API Terms (clause 4.4) forbid circumventing it. Instead the
  // request fails and ApiHttp pauses Last.fm for a short while.
  static String fallbackKey = '';
  // Last.fm errors tied to the key itself: 10 invalid, 26 suspended.
  static const _keyErrors = {10, 26};

  /// Label used to count requests per key in the API usage screen.
  static String keyLabel(String key) {
    final i = InternalKeys.indexOf(key);
    return i < 0 ? 'user' : 'builtin${i + 1}';
  }

  Future<dynamic> _call(Map<String, String> params) async {
    try {
      return await _get(params, apiKey);
    } on _KeyRejected {
      final fb = fallbackKey;
      if (fb.isEmpty || fb == apiKey) rethrow;
      return _get(params, fb);
    }
  }

  Future<dynamic> _get(Map<String, String> params, String key) async {
    final uri = Uri.https(_host, _path, {
      ...params,
      'api_key': key,
      'format':  'json',
    });
    var res = await ApiHttp.get(uri, keyLabel: keyLabel(key)).timeout(_timeout);
    // One simple retry after a short pause if Last.fm says "too many requests".
    if (res.statusCode == 429) {
      await Future.delayed(const Duration(milliseconds: 1500));
      res = await ApiHttp.get(uri, keyLabel: keyLabel(key)).timeout(_timeout);
    }
    if (res.statusCode == 429) {
      throw Exception('Last.fm rate limit reached (HTTP 429)');
    }
    if (res.statusCode == 403) throw _KeyRejected('HTTP 403');
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body['error'] != null) {
      final msg  = (body['message'] ?? 'Last.fm API error').toString();
      final code = int.tryParse(body['error'].toString());
      if (_keyErrors.contains(code)) throw _KeyRejected(msg);
      throw Exception(msg);
    }
    return body;
  }

  static List<dynamic> _asList(dynamic v) =>
      v == null ? [] : (v is List ? v : [v]);

  // ── Signed requests (needed for auth + write methods) ────
  String _sign(Map<String, String> params) {
    final keys = params.keys.toList()..sort();
    final buf  = StringBuffer();
    for (final k in keys) { buf.write(k); buf.write(params[k]); }
    buf.write(secret);
    return md5.convert(utf8.encode(buf.toString())).toString();
  }

  Future<dynamic> _callSigned(Map<String, String> params, {bool post = false}) async {
    final base   = {...params, 'api_key': apiKey};
    final sig    = _sign(base);
    final full   = {...base, 'api_sig': sig, 'format': 'json'};
    final uri    = Uri.https(_host, _path);
    final res    = post
        ? await ApiHttp.post(uri, body: full, keyLabel: keyLabel(apiKey)).timeout(_timeout)
        : await ApiHttp.get(uri.replace(queryParameters: full), keyLabel: keyLabel(apiKey)).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body['error'] != null) throw Exception(body['message'] ?? 'Last.fm API error');
    return body;
  }

  // ── Favorites auth flow (token → browser authorization → session key) ────
  Future<String> getAuthToken() async {
    final d = await _callSigned({'method': 'auth.getToken'});
    return (d['token'] ?? '').toString();
  }

  String authUrl(String token) =>
      'https://www.last.fm/api/auth/?api_key=$apiKey&token=$token';

  Future<String> getSessionKey(String token) async {
    final d = await _callSigned({'method': 'auth.getSession', 'token': token});
    return (d['session']?['key'] ?? '').toString();
  }

  // ── Loved tracks (write, requires secret + sessionKey) ────
  Future<void> loveTrack(String track, String artist) async {
    await _callSigned({
      'method': 'track.love', 'track': track, 'artist': artist, 'sk': sessionKey,
    }, post: true);
  }

  Future<void> unloveTrack(String track, String artist) async {
    await _callSigned({
      'method': 'track.unlove', 'track': track, 'artist': artist, 'sk': sessionKey,
    }, post: true);
  }

  // ── Discover (charts, similar artists, country) ─────────
  Future<List<dynamic>> getChartTopTracks({int limit = 15}) async {
    final d = await _call({'method': 'chart.getTopTracks', 'limit': '$limit'});
    return _asList(d['tracks']?['track']);
  }

  Future<List<dynamic>> getChartTopArtists({int limit = 15}) async {
    final d = await _call({'method': 'chart.getTopArtists', 'limit': '$limit'});
    return _asList(d['artists']?['artist']);
  }

  Future<List<dynamic>> getSimilarArtists(String artist, {int limit = 15}) async {
    final d = await _call({
      'method': 'artist.getSimilar', 'artist': artist, 'limit': '$limit',
    });
    return _asList(d['similarartists']?['artist']);
  }

  Future<List<dynamic>> getGeoTopTracks(String country, {int limit = 15}) async {
    final d = await _call({
      'method': 'geo.getTopTracks', 'country': country, 'limit': '$limit',
    });
    return _asList(d['tracks']?['track']);
  }

  // Top tracks for a genre/mood tag (e.g. the user's most-listened tag) —
  // used by the dashboard's "Discover" section for a taste-based source
  // that isn't just the global chart.
  Future<List<dynamic>> getTagTopTracks(String tag, {int limit = 15}) async {
    final d = await _call({
      'method': 'tag.getTopTracks', 'tag': tag, 'limit': '$limit',
    });
    return _asList(d['tracks']?['track']);
  }

  // ── User ────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserInfo({String? user}) async {
    final d = await _call({'method': 'user.getInfo', 'user': user ?? username});
    return d['user'] as Map<String, dynamic>?;
  }

  // ── Top lists ───────────────────────────────────────────
  // Public entry point: honours the "link versions" / "split collabs"
  // options (see LibraryMerge); plain Last.fm list when both are off.
  Future<List<dynamic>> getTopArtists({
    String period = 'overall',
    int limit = 50,
    int page = 1,
    String? user,
  }) {
    if (LibraryMerge.active) {
      return LibraryMerge.topList(this,
          type: 'artists', period: period, limit: limit, page: page, user: user);
    }
    return rawTopArtists(period: period, limit: limit, page: page, user: user);
  }

  Future<List<dynamic>> rawTopArtists({
    String period = 'overall',
    int limit = 50,
    int page = 1,
    String? user,
  }) async {
    final d = await _call({
      'method': 'user.getTopArtists',
      'user':   user ?? username,
      'period': period,
      'limit':  '$limit',
      'page':   '$page',
    });
    return _asList(d['topartists']?['artist']);
  }

  // Public entry point: honours the "link versions" / "split collabs"
  // options (see LibraryMerge); plain Last.fm list when both are off.
  Future<List<dynamic>> getTopAlbums({
    String period = 'overall',
    int limit = 50,
    int page = 1,
    String? user,
  }) {
    if (LibraryMerge.active) {
      return LibraryMerge.topList(this,
          type: 'albums', period: period, limit: limit, page: page, user: user);
    }
    return rawTopAlbums(period: period, limit: limit, page: page, user: user);
  }

  Future<List<dynamic>> rawTopAlbums({
    String period = 'overall',
    int limit = 50,
    int page = 1,
    String? user,
  }) async {
    final d = await _call({
      'method': 'user.getTopAlbums',
      'user':   user ?? username,
      'period': period,
      'limit':  '$limit',
      'page':   '$page',
    });
    return _asList(d['topalbums']?['album']);
  }

  // Public entry point: honours the "link versions" / "split collabs"
  // options (see LibraryMerge); plain Last.fm list when both are off.
  Future<List<dynamic>> getTopTracks({
    String period = 'overall',
    int limit = 50,
    int page = 1,
    String? user,
  }) {
    if (LibraryMerge.active) {
      return LibraryMerge.topList(this,
          type: 'tracks', period: period, limit: limit, page: page, user: user);
    }
    return rawTopTracks(period: period, limit: limit, page: page, user: user);
  }

  Future<List<dynamic>> rawTopTracks({
    String period = 'overall',
    int limit = 50,
    int page = 1,
    String? user,
  }) async {
    final d = await _call({
      'method': 'user.getTopTracks',
      'user':   user ?? username,
      'period': period,
      'limit':  '$limit',
      'page':   '$page',
    });
    return _asList(d['toptracks']?['track']);
  }

  // ── Recent tracks ───────────────────────────────────────
  Future<Map<String, dynamic>> getRecentTracks({
    int limit = 50,
    int page  = 1,
    int? from,
    int? to,
    String? user,
  }) async {
    final p = <String, String>{
      'method': 'user.getRecentTracks',
      'user':   user ?? username,
      'limit':  '$limit',
      'page':   '$page',
    };
    if (from != null) p['from'] = '$from';
    if (to   != null) p['to']   = '$to';
    final d = await _call(p);
    return (d['recenttracks'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>?> getNowPlaying() async {
    try {
      final d      = await getRecentTracks(limit: 1);
      final tracks = _asList(d['track']);
      if (tracks.isEmpty) return null;
      final first = tracks.first as Map<String, dynamic>;
      return first['@attr']?['nowplaying'] == 'true' ? first : null;
    } catch (_) {
      return null;
    }
  }

  // ── Monthly scrobble counts ──────────────────────────────
  Future<Map<String, int>> getMonthlyScrobbles({int months = 12}) async {
    final now   = DateTime.now();
    final keys  = <String>[];
    final futs  = <Future>[];

    for (var i = months - 1; i >= 0; i--) {
      final from = DateTime(now.year, now.month - i,     1);
      final to   = DateTime(now.year, now.month - i + 1, 1);
      keys.add('${from.year}-${from.month.toString().padLeft(2, '0')}');
      futs.add(
        _call({
          'method': 'user.getRecentTracks',
          'user':   username,
          'from':   '${from.millisecondsSinceEpoch ~/ 1000}',
          'to':     '${to.millisecondsSinceEpoch   ~/ 1000}',
          'limit':  '1',
        }).catchError((_) => <String, dynamic>{}),
      );
    }

    final results = await Future.wait(futs);
    return {
      for (var i = 0; i < keys.length; i++)
        keys[i]: int.tryParse(
          ((results[i] as Map?))?['recenttracks']?['@attr']?['total']
              ?.toString() ?? '0',
        ) ?? 0,
    };
  }

  // ── Loved tracks ────────────────────────────────────────
  Future<List<dynamic>> getLovedTracks({int limit = 50}) async {
    final d = await _call({
      'method': 'user.getLovedTracks',
      'user':   username,
      'limit':  '$limit',
    });
    return _asList(d['lovedtracks']?['track']);
  }

  Future<int> getLovedTracksCount() async {
    final d = await _call({
      'method': 'user.getLovedTracks',
      'user':   username,
      'limit':  '1',
    });
    return int.tryParse(d['lovedtracks']?['@attr']?['total']?.toString() ?? '0') ?? 0;
  }

  // ── Artist info (global + user context) ─────────────────
  Future<Map<String, dynamic>?> getArtistInfo(String artist) async {
    try {
      final d = await _call({
        'method':   'artist.getInfo',
        'artist':   artist,
        'username': username,
        'lang':     'fr',
        'autocorrect': '1',
      });
      return d['artist'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<int?> getArtistListeners(String artist) async {
    final info = await getArtistInfo(artist);
    return int.tryParse(info?['stats']?['listeners']?.toString() ?? '');
  }

  // ── Artist top tracks (global) ───────────────────────────
  Future<List<dynamic>> getArtistTopTracks(String artist, {int limit = 10}) async {
    try {
      final d = await _call({
        'method':      'artist.getTopTracks',
        'artist':      artist,
        'limit':       '$limit',
        'autocorrect': '1',
      });
      return _asList(d['toptracks']?['track']);
    } catch (_) {
      return [];
    }
  }

  // ── Artist top albums (global) ───────────────────────────
  Future<List<dynamic>> getArtistTopAlbums(String artist, {int limit = 10}) async {
    try {
      final d = await _call({
        'method':      'artist.getTopAlbums',
        'artist':      artist,
        'limit':       '$limit',
        'autocorrect': '1',
      });
      return _asList(d['topalbums']?['album']);
    } catch (_) {
      return [];
    }
  }

  // ── Artist top tags (global) ────────────────────────────
  Future<List<dynamic>> getArtistTopTags(String artist) async {
    try {
      final d = await _call({
        'method':      'artist.getTopTags',
        'artist':      artist,
        'autocorrect': '1',
      });
      final tags = d['toptags']?['tag'];
      if (tags == null) return [];
      return tags is List ? tags : [tags];
    } catch (_) {
      return [];
    }
  }

  // ── Album info (global + user context) ──────────────────
  Future<Map<String, dynamic>?> getAlbumInfo(String album, String artist) async {
    try {
      final d = await _call({
        'method':   'album.getInfo',
        'album':    album,
        'artist':   artist,
        'username': username,
        'lang':     'fr',
        'autocorrect': '1',
      });
      return d['album'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Track info (global + user context) ──────────────────
  Future<Map<String, dynamic>?> getTrackInfo(String track, String artist) async {
    try {
      final d = await _call({
        'method':   'track.getInfo',
        'track':    track,
        'artist':   artist,
        'username': username,
        'autocorrect': '1',
      });
      return d['track'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Friends ─────────────────────────────────────────────
  /// Returns the friend list of [username].
  /// Pass [withRecentTrack] = true to include each friend's most recent
  /// (or currently playing) track in the response — saves extra requests.
  Future<List<dynamic>> getFriends({
    int  limit          = 50,
    int  page           = 1,
    bool withRecentTrack = true,
  }) async {
    final d = await _call({
      'method':       'user.getFriends',
      'user':         username,
      'limit':        '$limit',
      'page':         '$page',
      'recenttracks': withRecentTrack ? '1' : '0',
    });
    return _asList(d['friends']?['user']);
  }

  // ── User rank for an item over a period ─────────────────
  /// Returns (rank, playcount) for an artist/album/track in user's top-200.
  Future<({int rank, int plays})> getUserItemStats({
    required String type,   // 'artists' | 'albums' | 'tracks'
    required String name,
    String artistName = '',
    String period    = 'overall',
  }) async {
    final List<dynamic> items;
    if (type == 'artists') {
      items = await getTopArtists(period: period, limit: 200);
    } else if (type == 'albums') {
      items = await getTopAlbums(period: period, limit: 200);
    } else {
      items = await getTopTracks(period: period, limit: 200);
    }

    final known = LibraryMerge.knownSync(username);
    for (var i = 0; i < items.length; i++) {
      final n = (items[i]['name'] ?? '').toString();
      final a = type != 'artists' ? (items[i]['artist']?['name'] ?? '').toString() : '';
      final match = LibraryMerge.active
          ? LibraryMerge.same(type, n, a, name, artistName, known)
          : n == name && (type == 'artists' || a == artistName);
      if (match) {
        final plays = int.tryParse((items[i]['playcount'] ?? '0').toString()) ?? 0;
        return (rank: i + 1, plays: plays);
      }
    }
    return (rank: -1, plays: 0);
  }

  // ── Global search ────────────────────────────────────────

  /// Searches Last.fm users by username.
  /// Tries user.search first; falls back to user.getInfo for exact matching
  /// (user.search is notoriously unreliable and often returns empty).
  Future<List<dynamic>> searchUsers(
    String query, {
    int limit = 15,
    int page  = 1,
  }) async {
    try {
      final d = await _call({
        'method': 'user.search',
        'user':   query,
        'limit':  '$limit',
        'page':   '$page',
      });
      final raw = d['results']?['usermatches']?['user'];
      // Last.fm returns "" (empty string) when there are no results
      if (raw == null || raw is String) { return await _searchUserFallback(query); }
      final list = _asList(raw);
      final results = list.whereType<Map>().toList();
      // If search returned nothing, try exact match via user.getInfo
      if (results.isEmpty) { return await _searchUserFallback(query); }
      return results;
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('no user') || msg.contains('not found') ||
          msg.contains('http 400') || msg.contains('http 403')) {
        return await _searchUserFallback(query);
      }
      rethrow;
    }
  }

  /// Fallback: looks up a user by exact username via user.getInfo.
  /// Returns a single-element list on success, or [] if not found.
  Future<List<dynamic>> _searchUserFallback(String query) async {
    try {
      final info = await getUserInfo(user: query);
      if (info == null) return [];
      return [info];
    } catch (_) {
      return [];
    }
  }

  /// Searches artists globally via artist.search.
  Future<List<dynamic>> searchArtists(
    String query, {
    int limit = 15,
    int page  = 1,
  }) async {
    final d = await _call({
      'method': 'artist.search',
      'artist': query,
      'limit':  '$limit',
      'page':   '$page',
    });
    return _asList(d['results']?['artistmatches']?['artist']);
  }

  /// Searches albums globally via album.search.
  Future<List<dynamic>> searchAlbums(
    String query, {
    int limit = 15,
    int page  = 1,
  }) async {
    final d = await _call({
      'method': 'album.search',
      'album':  query,
      'limit':  '$limit',
      'page':   '$page',
    });
    return _asList(d['results']?['albummatches']?['album']);
  }

  /// Searches tracks globally via track.search.
  Future<List<dynamic>> searchTracks(
    String query, {
    int limit = 15,
    int page  = 1,
  }) async {
    final d = await _call({
      'method': 'track.search',
      'track':  query,
      'limit':  '$limit',
      'page':   '$page',
    });
    return _asList(d['results']?['trackmatches']?['track']);
  }
}

/// Thrown when the API key itself is refused (invalid, suspended, rate-limited).
class _KeyRejected implements Exception {
  final String message;
  const _KeyRejected(this.message);
  @override
  String toString() => message;
}
