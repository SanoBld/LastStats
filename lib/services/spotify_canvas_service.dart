// Spotify Canvas (the short looping videos) for a track or an album.
// Spotify has no public API for it. This uses the same private calls as
// the Spotify web player, with the user's own Spotify login:
//   1. Login in a WebView (see SpotifyLoginPage). We keep the "sp_dc" cookie.
//   2. A hidden web player gives a short token (see SpotifyWebSession).
//   3. v1/search finds the track id.
//   4. api-partner.spotify.com "canvas" query returns the MP4 link.
// It can break if Spotify changes its private calls (the query hash).
// Returns null when nothing is found, like the other sources.
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_http.dart';
import 'spotify_web_session.dart';

class _Sess {
  final String bearer, clientToken;
  const _Sess(this.bearer, this.clientToken);
}

class _Expired implements Exception {}

class SpotifyCanvasService {
  static const kSpDc = 'ls_spotify_sp_dc';
  static const _kTok = 'ls_spotify_token';
  static const _kCt = 'ls_spotify_client_token';
  static const _kExp = 'ls_spotify_token_exp';
  static const _kHash = 'ls_spotify_canvas_hash'; // optional override
  // Hash of Spotify's "canvas" query. It changes when Spotify updates
  // the web player: then paste the new one in ls_spotify_canvas_hash.
  static const defaultHash =
      '575138ab27cd5c1b3e54da54d0a7cc8d85485402de26340c2145f0f6bb5e7a9f';
  static const _timeout = Duration(seconds: 10);

  /// Last problem seen (for debugging only).
  static String? lastError;

  static Future<bool> isConnected() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(kSpDc) ?? '').isNotEmpty;
  }

  /// Called by the login page once the web player gave its headers.
  static Future<void> saveLogin(
      String spDc, String bearer, String clientToken) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kSpDc, spDc);
    await _saveToken(p, bearer, clientToken);
  }

  static Future<void> _saveToken(
      SharedPreferences p, String bearer, String ct) async {
    await p.setString(_kTok, bearer);
    await p.setString(_kCt, ct);
    // Web-player tokens last about an hour.
    await p.setInt(_kExp,
        DateTime.now().add(const Duration(minutes: 50)).millisecondsSinceEpoch);
  }

  static Future<void> disconnect() async {
    final p = await SharedPreferences.getInstance();
    for (final k in [kSpDc, _kTok, _kCt, _kExp]) {
      await p.remove(k);
    }
    await SpotifyWebSession.clear();
  }

  static Future<_Sess?>? _refreshing;

  static Future<_Sess?> _session({bool force = false}) async {
    if (kIsWeb) return null;
    final p = await SharedPreferences.getInstance();
    final spDc = p.getString(kSpDc) ?? '';
    if (spDc.isEmpty) return null;
    final tok = p.getString(_kTok), ct = p.getString(_kCt);
    final exp = p.getInt(_kExp) ?? 0;
    if (!force &&
        tok != null &&
        ct != null &&
        DateTime.now().millisecondsSinceEpoch < exp) {
      return _Sess(tok, ct);
    }
    // One refresh at a time, even if many covers ask together.
    return _refreshing ??= () async {
      try {
        final r = await SpotifyWebSession.refresh(spDc);
        if (r == null) {
          lastError = 'no token (login expired?)';
          return null;
        }
        await _saveToken(p, r.token, r.clientToken);
        return _Sess(r.token, r.clientToken);
      } finally {
        _refreshing = null;
      }
    }();
  }

  // ── Public lookups ─────────────────────────────────────────────────────

  static Future<String?> findTrack(String artist, String track) =>
      _withRetry((s) => _trackFlow(s, artist, track));

  /// An album has no Canvas itself: try the Canvas of its first tracks.
  static Future<String?> findAlbum(String artist, String album) =>
      _withRetry((s) => _albumFlow(s, artist, album));

  // Runs [fn]; on an expired token, refreshes once and runs it again.
  static Future<String?> _withRetry(
      Future<String?> Function(_Sess) fn) async {
    try {
      var s = await _session();
      if (s == null) return null;
      try {
        return await fn(s);
      } on _Expired {
        s = await _session(force: true);
        if (s == null) return null;
        return await fn(s);
      }
    } on _Expired {
      return null;
    } catch (e) {
      lastError = '$e';
      return null;
    }
  }

  static Future<String?> _trackFlow(
      _Sess s, String artist, String track) async {
    final core = _core(track);
    if (core.isEmpty) return null;
    final lead = artist.split(_artistSplit).first;
    final j = await _api(s, '/v1/search',
        {'q': '$lead $core', 'type': 'track', 'limit': '10'});
    final items = (j?['tracks']?['items'] as List?) ?? [];
    var tried = 0;
    for (final it in items) {
      if (it is! Map || tried >= 3) continue;
      if (!_similar(track, (it['name'] ?? '').toString())) continue;
      final names = [
        for (final a in (it['artists'] as List? ?? [])) (a['name'] ?? '').toString()
      ];
      if (!names.any((n) => _artistMatch(artist, n))) continue;
      final id = (it['id'] ?? '').toString();
      if (id.isEmpty) continue;
      tried++;
      final v = await _canvas(s, 'spotify:track:$id');
      if (v != null) return v;
    }
    return null;
  }

  static Future<String?> _albumFlow(
      _Sess s, String artist, String album) async {
    final core = _core(album);
    if (core.isEmpty) return null;
    final lead = artist.split(_artistSplit).first;
    final j = await _api(s, '/v1/search',
        {'q': '$lead $core', 'type': 'album', 'limit': '5'});
    final items = (j?['albums']?['items'] as List?) ?? [];
    for (final it in items) {
      if (it is! Map) continue;
      if (!_similar(album, (it['name'] ?? '').toString())) continue;
      final names = [
        for (final a in (it['artists'] as List? ?? [])) (a['name'] ?? '').toString()
      ];
      if (!names.any((n) => _artistMatch(artist, n))) continue;
      final id = (it['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final t = await _api(s, '/v1/albums/$id/tracks', {'limit': '4'});
      for (final tr in (t?['items'] as List? ?? [])) {
        final tid = (tr is Map ? tr['id'] : null)?.toString() ?? '';
        if (tid.isEmpty) continue;
        final v = await _canvas(s, 'spotify:track:$tid');
        if (v != null) return v;
      }
      return null; // first matching album only
    }
    return null;
  }

  // ── Calls ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _api(
      _Sess s, String path, Map<String, String> q) async {
    final res = await ApiHttp.get(Uri.https('api.spotify.com', path, q),
        headers: {
          'Authorization': s.bearer,
          'User-Agent': SpotifyWebSession.ua,
        }).timeout(_timeout);
    if (res.statusCode == 401) throw _Expired();
    if (res.statusCode != 200) {
      lastError = 'api ${res.statusCode}';
      return null;
    }
    final d = jsonDecode(utf8.decode(res.bodyBytes));
    return d is Map<String, dynamic> ? d : null;
  }

  static Future<String?> _canvas(_Sess s, String trackUri) async {
    final p = await SharedPreferences.getInstance();
    final hash = p.getString(_kHash) ?? defaultHash;
    final res = await ApiHttp.post(
      Uri.https('api-partner.spotify.com', '/pathfinder/v2/query'),
      headers: {
        'Authorization': s.bearer,
        'client-token': s.clientToken,
        'Content-Type': 'application/json;charset=UTF-8',
        'Accept': 'application/json',
        'app-platform': 'WebPlayer',
        'Origin': 'https://open.spotify.com',
        'Referer': 'https://open.spotify.com/',
        'User-Agent': SpotifyWebSession.ua,
      },
      body: jsonEncode({
        'operationName': 'canvas',
        'variables': {'trackUri': trackUri},
        'extensions': {
          'persistedQuery': {'version': 1, 'sha256Hash': hash}
        },
      }),
    ).timeout(_timeout);
    if (res.statusCode == 401) throw _Expired();
    if (res.statusCode != 200) {
      lastError = 'canvas ${res.statusCode}';
      return null;
    }
    final body = utf8.decode(res.bodyBytes);
    if (body.contains('PersistedQueryNotFound')) {
      lastError = 'canvas hash outdated';
      return null;
    }
    // The answer's shape may change: look for the MP4 link anywhere.
    return _findMp4(jsonDecode(body));
  }

  static String? _findMp4(dynamic n) {
    if (n is Map) {
      for (final v in n.values) {
        final r = _findMp4(v);
        if (r != null) return r;
      }
    } else if (n is List) {
      for (final v in n) {
        final r = _findMp4(v);
        if (r != null) return r;
      }
    } else if (n is String &&
        n.startsWith('http') &&
        n.contains('canvaz.scdn.co') &&
        n.contains('.mp4')) {
      return n;
    }
    return null;
  }

  // ── Name matching (same rules as the Apple lookup) ─────────────────────

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

  static String _core(String s) => s
      .replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]'), '')
      .replaceAll(RegExp(r'\s+-\s+.*$'), '')
      .trim();

  static bool _similar(String a, String b) {
    for (final pair in [(a, b), (_core(a), _core(b))]) {
      final x = _norm(pair.$1), y = _norm(pair.$2);
      if (x.isEmpty || y.isEmpty) continue;
      if (x == y) return true;
      final sh = x.length <= y.length ? x : y;
      final lo = x.length <= y.length ? y : x;
      if (sh.length >= 4 && lo.contains(sh)) return true;
    }
    return false;
  }

  static final _artistSplit = RegExp(
      r'\s*,\s*|\s+(&|feat\.?|ft\.?|x|and)\s+', caseSensitive: false);

  static bool _artistMatch(String a, String b) =>
      _similar(a, b) ||
      _similar(a.split(_artistSplit).first, b) ||
      _similar(a, b.split(_artistSplit).first);
}
