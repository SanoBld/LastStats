// Spotify Canvas (the short looping videos) for a track or an album.
// Spotify has no public API for it. This uses the same private calls as
// the Spotify web player, with the user's own Spotify login:
//   1. Login in a WebView (see SpotifyLoginPage). We keep the "sp_dc" cookie.
//   2. A hidden web player gives a short token and a copy of its own
//      search request (see SpotifyWebSession).
//   3. That search request, replayed with our words, finds the track id.
//      (api.spotify.com/v1/search is NOT used: it answers 429 all the time.)
//   4. api-partner.spotify.com "canvas" query returns the MP4 link.
// It can break if Spotify changes its private calls (the query hash).
// Returns null when nothing is found, like the other sources.
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/extra_strings.dart';
import 'api_http.dart';
import 'spotify_web_session.dart';

class _Sess {
  final String bearer, clientToken;
  const _Sess(this.bearer, this.clientToken);
}

class _Cand {
  final String uri, name, album;
  final List<String> artists;
  const _Cand(this.uri, this.name, this.artists, this.album);
}

class _Expired implements Exception {}

class SpotifyCanvasService {
  static const kSpDc = 'ls_spotify_sp_dc';
  static const _kTok = 'ls_spotify_token';
  static const _kCt = 'ls_spotify_client_token';
  static const _kExp = 'ls_spotify_token_exp';
  static const _kTpl = 'ls_spotify_search_tpl';
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
    for (final k in [kSpDc, _kTok, _kCt, _kExp, _kTpl]) {
      await p.remove(k);
    }
    await SpotifyWebSession.clear();
  }

  static Future<_Sess?>? _refreshing;
  static DateTime? _lastRefresh;

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
        _lastRefresh = DateTime.now();
        final r = await SpotifyWebSession.refresh(spDc);
        if (r == null) {
          lastError = 'no token (login expired?)';
          return null;
        }
        await _saveToken(p, r.token, r.clientToken);
        if (r.search != null) await p.setString(_kTpl, r.search!);
        return _Sess(r.token, r.clientToken);
      } finally {
        _refreshing = null;
      }
    }();
  }

  // The copied search request. If missing, one refresh is tried
  // (at most every 10 minutes).
  static Future<Map<String, dynamic>?> _template() async {
    final p = await SharedPreferences.getInstance();
    var raw = p.getString(_kTpl);
    if (raw == null) {
      final t = _lastRefresh;
      if (t == null || DateTime.now().difference(t).inMinutes >= 10) {
        await _session(force: true);
        raw = p.getString(_kTpl);
      }
    }
    if (raw == null) {
      lastError = 'no search template';
      return null;
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
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
    final cands = await _search(s, '$lead $core');
    var tried = 0;
    for (final c in cands) {
      if (tried >= 3) break;
      if (!_similar(track, c.name)) continue;
      if (!c.artists.any((n) => _artistMatch(artist, n))) continue;
      tried++;
      final v = await _canvas(s, c.uri);
      if (v != null) return v;
    }
    return null;
  }

  static Future<String?> _albumFlow(
      _Sess s, String artist, String album) async {
    final core = _core(album);
    if (core.isEmpty) return null;
    final lead = artist.split(_artistSplit).first;
    final cands = await _search(s, '$lead $core');
    var tried = 0;
    final seen = <String>{};
    for (final c in cands) {
      if (tried >= 4) break;
      if (!_similar(album, c.album)) continue;
      if (!c.artists.any((n) => _artistMatch(artist, n))) continue;
      if (!seen.add(c.uri)) continue;
      tried++;
      final v = await _canvas(s, c.uri);
      if (v != null) return v;
    }
    return null;
  }

  // ── Calls ──────────────────────────────────────────────────────────────

  static Map<String, String> _headers(_Sess s) => {
        'Authorization': s.bearer,
        'client-token': s.clientToken,
        'Content-Type': 'application/json;charset=UTF-8',
        'Accept': 'application/json',
        'app-platform': 'WebPlayer',
        'Origin': 'https://open.spotify.com',
        'Referer': 'https://open.spotify.com/',
        'User-Agent': SpotifyWebSession.ua,
      };

  // Replays the web player's own search with our words (plain http:
  // not ApiHttp, so its client-side limiter never answers for us).
  static Future<List<_Cand>> _search(_Sess s, String query) async {
    final tpl = await _template();
    if (tpl == null) return [];
    const orig = SpotifyWebSession.searchTerm;
    dynamic swap(dynamic n) {
      if (n is String) return n == orig ? query : n;
      if (n is Map) return {for (final e in n.entries) e.key: swap(e.value)};
      if (n is List) return [for (final e in n) swap(e)];
      return n;
    }

    final url = Uri.parse('https://open.spotify.com')
        .resolve((tpl['url'] ?? '').toString());
    http.Response res;
    if ((tpl['method'] ?? 'GET').toString().toUpperCase() == 'POST' &&
        tpl['body'] != null) {
      final body = jsonEncode(swap(jsonDecode(tpl['body'].toString())));
      res = await http
          .post(url, headers: _headers(s), body: body)
          .timeout(_timeout);
    } else {
      final q = Map<String, String>.from(url.queryParameters);
      if (q['variables'] != null) {
        q['variables'] = jsonEncode(swap(jsonDecode(q['variables']!)));
      }
      res = await http
          .get(url.replace(queryParameters: q), headers: _headers(s))
          .timeout(_timeout);
    }
    if (res.statusCode == 401) throw _Expired();
    if (res.statusCode != 200) {
      lastError = 'search ${res.statusCode}';
      return [];
    }
    final out = <_Cand>[];
    _collect(jsonDecode(utf8.decode(res.bodyBytes)), out);
    if (out.isEmpty) lastError = 'search: no tracks in answer';
    return out;
  }

  // Finds every track object (uri "spotify:track:...") anywhere in the JSON.
  static void _collect(dynamic n, List<_Cand> out) {
    if (n is Map) {
      final uri = n['uri'];
      if (uri is String &&
          uri.startsWith('spotify:track:') &&
          n['name'] is String) {
        final names = <String>[];
        _names(n['artists'], names);
        final alb = n['albumOfTrack'];
        out.add(_Cand(uri, n['name'] as String, names,
            alb is Map ? (alb['name'] ?? '').toString() : ''));
      }
      for (final v in n.values) {
        _collect(v, out);
      }
    } else if (n is List) {
      for (final v in n) {
        _collect(v, out);
      }
    }
  }

  static void _names(dynamic n, List<String> out) {
    if (n is Map) {
      if (n['name'] is String) out.add(n['name'] as String);
      for (final v in n.values) {
        _names(v, out);
      }
    } else if (n is List) {
      for (final v in n) {
        _names(v, out);
      }
    }
  }

  // Raw "canvas" call: HTTP status + body (used by _canvas and diagnose).
  static Future<(int, String)> _canvasRaw(_Sess s, String trackUri) async {
    final p = await SharedPreferences.getInstance();
    final hash = p.getString(_kHash) ?? defaultHash;
    final res = await ApiHttp.post(
      Uri.https('api-partner.spotify.com', '/pathfinder/v2/query'),
      headers: _headers(s),
      body: jsonEncode({
        'operationName': 'canvas',
        'variables': {'trackUri': trackUri},
        'extensions': {
          'persistedQuery': {'version': 1, 'sha256Hash': hash}
        },
      }),
    ).timeout(_timeout);
    return (res.statusCode, utf8.decode(res.bodyBytes));
  }

  static Future<String?> _canvas(_Sess s, String trackUri) async {
    final (code, body) = await _canvasRaw(s, trackUri);
    if (code == 401) throw _Expired();
    if (code != 200) {
      lastError = 'canvas $code';
      return null;
    }
    if (body.contains('PersistedQueryNotFound')) {
      lastError = 'canvas hash outdated';
      return null;
    }
    // The answer's shape may change: look for the MP4 link anywhere.
    final v = _findMp4(jsonDecode(body));
    if (v == null) {
      lastError = 'canvas: no mp4 in answer: ${body.length > 160 ? body.substring(0, 160) : body}';
    }
    return v;
  }

  /// Step-by-step test (for the "Test Spotify" button). Texts come from
  /// the language files (dg_* keys).
  static Future<String> diagnose() async {
    final out = <String>[];
    try {
      final p = await SharedPreferences.getInstance();
      final spDc = p.getString(kSpDc) ?? '';
      out.add('1. ${tx('dg_cookie')}: ${spDc.isEmpty ? tx('dg_missing') : tx('dg_ok')}');
      if (spDc.isEmpty) return out.join('\n');
      final s = await _session(force: true);
      out.add('2. ${tx('dg_token')}: ${s == null ? '${tx('dg_failed')} (${lastError ?? '?'})' : tx('dg_ok')}');
      if (s == null) return out.join('\n');
      final tpl = await _template();
      if (tpl == null) {
        out.add('3. ${tx('dg_search')}: ${tx('dg_notpl')}');
      } else {
        lastError = null;
        final c = await _search(s, 'SZA Kill Bill');
        out.add('3. ${tx('dg_search')}: ${c.isEmpty ? '${tx('dg_failed')} (${lastError ?? '0'})' : '${c.length} ${tx('dg_results')}'}');
      }
      final (code, body) = await _canvasRaw(s, 'spotify:track:3OHfY25tqY28d16oZczHc8');
      final mp4 = code == 200 ? _findMp4(jsonDecode(body)) : null;
      out.add('4. Canvas: HTTP $code, ${mp4 != null ? tx('dg_found') : tx('dg_nofound')}');
      if (mp4 == null) {
        out.add(body.length > 220 ? body.substring(0, 220) : body);
      }
    } catch (e) {
      out.add('$e');
    }
    return out.join('\n');
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
