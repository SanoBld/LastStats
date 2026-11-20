// lib/services/lb_auth.dart
// ListenBrainz login: check a user token, save it, repair it after a restore.
// Docs: GET /1/validate-token with header "Authorization: Token <token>"
// answers {"valid": true, "user_name": "..."}.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_manager.dart';
import 'api_http.dart';
import 'data_source.dart';

enum LbAuthStatus { ok, empty, badFormat, invalid, rateLimited, server, network }

class LbAuthResult {
  final LbAuthStatus status;
  final String userName;
  final String token;
  final String detail;
  const LbAuthResult(this.status, {this.userName = '', this.token = '', this.detail = ''});
  bool get ok => status == LbAuthStatus.ok;
}

class LbAuth {
  LbAuth._();

  // A token is a UUID: 8-4-4-4-12 hex characters.
  static final _uuid = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

  /// Removes spaces, quotes and a pasted "Token " prefix.
  static String clean(String s) {
    var t = s.trim().replaceAll(RegExp(r'''["'\s]'''), '');
    if (t.toLowerCase().startsWith('token')) t = t.substring(5);
    final m = _uuid.firstMatch(t);
    return m != null ? m.group(0)! : t;
  }

  static bool looksLikeToken(String s) => _uuid.hasMatch(s);

  static Future<LbAuthResult> validate(String input) async {
    final token = clean(input);
    if (token.isEmpty) return const LbAuthResult(LbAuthStatus.empty);
    if (!looksLikeToken(token)) return const LbAuthResult(LbAuthStatus.badFormat);
    try {
      final res = await ApiHttp.get(
        Uri.https('api.listenbrainz.org', '/1/validate-token'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 20));
      final c = res.statusCode;
      if (c == 429) return const LbAuthResult(LbAuthStatus.rateLimited);
      if (c >= 500) return LbAuthResult(LbAuthStatus.server, detail: 'HTTP $c');
      if (c == 401 || c == 403) return const LbAuthResult(LbAuthStatus.invalid);
      Object? body;
      try { body = jsonDecode(utf8.decode(res.bodyBytes)); } catch (_) {}
      if (c != 200 || body is! Map) {
        return LbAuthResult(LbAuthStatus.server, detail: 'HTTP $c');
      }
      final name = '${body['user_name'] ?? ''}'.trim();
      if (body['valid'] != true || name.isEmpty) {
        return const LbAuthResult(LbAuthStatus.invalid);
      }
      return LbAuthResult(LbAuthStatus.ok, userName: name, token: token);
    } catch (_) {
      return const LbAuthResult(LbAuthStatus.network);
    }
  }

  /// Saves a validated login and switches the app to ListenBrainz mode.
  static Future<void> save(String name, String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_username', name);
    await p.setString('ls_apikey', token);
    await p.setString('ls_lb_username', name);
    await p.setString('ls_lb_token', token);
    await p.remove('ls_secret_key');
    await p.remove('ls_session_key');
    await AccountManager.setSingle(AccountEntry(username: name, apiKey: token));
    await DataSource.set(listenbrainz: true);
  }

  /// After a backup restore: make source, name and token agree.
  static Future<void> reconcileAfterRestore({String? fallbackUser, String? fallbackKey}) async {
    final p = await SharedPreferences.getInstance();
    if (!DataSource.lb) return;
    var u = p.getString('ls_lb_username') ?? '';
    var k = p.getString('ls_lb_token') ?? '';
    if (u.isEmpty) u = (p.getString('ls_username') ?? fallbackUser ?? '').trim();
    if (k.isEmpty) {
      final a = (p.getString('ls_apikey') ?? fallbackKey ?? '').trim();
      if (looksLikeToken(a)) k = clean(a);
    }
    if (u.isEmpty || k.isEmpty) {
      // No usable ListenBrainz login: go back to a consistent Last.fm state.
      await DataSource.set(listenbrainz: false);
      return;
    }
    await p.setString('ls_lb_username', u);
    await p.setString('ls_lb_token', k);
    await p.setString('ls_username', u);
    await p.setString('ls_apikey', k);
    await AccountManager.setSingle(AccountEntry(username: u, apiKey: k));
  }
}
