// Gets a Spotify web-player token from a real web player running inside a
// WebView. A hook injected before the page's own scripts copies the
// "authorization" and "client-token" headers of the page's own requests.
// (Home-made tokens are refused by Spotify, so we reuse the page's.)
// The hook also copies the web player's own search request (a "template"),
// so we can search tracks without api.spotify.com (rate limited).
import 'dart:async';
import 'dart:collection';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SpotifyWebSession {
  // Desktop UA: on a phone UA, open.spotify.com only shows "get the app".
  static const ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36';

  static const _hook = r'''
(function () {
  if (window.__lsHook) return;
  window.__lsHook = true;
  var auth = null, ct = null;
  function push() {
    if (auth && ct && window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('lsTok', auth, ct);
    }
  }
  function look(name, value) {
    if (!name || !value) return;
    name = String(name).toLowerCase();
    value = String(value);
    if (name === 'authorization' && value.indexOf('Bearer ') === 0) auth = value;
    else if (name === 'client-token') ct = value;
    push();
  }
  function scan(h) {
    if (!h) return;
    if (Array.isArray(h)) { h.forEach(function (p) { look(p[0], p[1]); }); }
    else if (typeof h.forEach === 'function') { h.forEach(function (v, k) { look(k, v); }); }
    else { for (var k in h) look(k, h[k]); }
  }
  var tplSent = false;
  function noteSearch(input, init) {
    if (tplSent) return;
    try {
      var url = typeof input === 'string' ? input : (input && input.url);
      url = String(url || '');
      if (url.indexOf('pathfinder') < 0) return;
      var body = init && typeof init.body === 'string' ? init.body : null;
      var op = null;
      if (body) { try { op = JSON.parse(body).operationName; } catch (e) {} }
      if (!op) { var m = url.match(/operationName=([^&]+)/); if (m) op = decodeURIComponent(m[1]); }
      if (!op || !/search/i.test(op) || /suggest|autocomplete/i.test(op)) return;
      tplSent = true;
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('lsSearch', JSON.stringify({
          method: (init && init.method) || 'GET', url: url, body: body, op: op
        }));
      }
    } catch (e) {}
  }
  var f = window.fetch;
  window.fetch = function (input, init) {
    noteSearch(input, init);
    try {
      if (input && input.headers) scan(input.headers);
      if (init && init.headers) scan(init.headers);
    } catch (e) {}
    return f.apply(this, arguments);
  };
  var sh = XMLHttpRequest.prototype.setRequestHeader;
  XMLHttpRequest.prototype.setRequestHeader = function (k, v) {
    try { look(k, v); } catch (e) {}
    return sh.apply(this, arguments);
  };
})();
''';

  static UnmodifiableListView<UserScript> scripts() => UnmodifiableListView([
        UserScript(
          source: _hook,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]);

  static final _site = WebUri('https://open.spotify.com');

  // The login cookie. It stays valid for months.
  static Future<String?> readSpDc() async {
    try {
      final c = await CookieManager.instance()
          .getCookie(url: _site, name: 'sp_dc');
      final v = c?.value;
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _setSpDc(String v) async {
    try {
      await CookieManager.instance().setCookie(
        url: _site,
        name: 'sp_dc',
        value: v,
        domain: '.spotify.com',
        path: '/',
        isSecure: true,
        isHttpOnly: true,
        expiresDate:
            DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await CookieManager.instance().deleteAllCookies();
    } catch (_) {}
  }

  // Search page of the web player: it sends the search request we copy.
  static const searchTerm = 'hello';
  static final _searchPage = WebUri('https://open.spotify.com/search/$searchTerm/tracks');

  // Loads the web player in a hidden WebView and waits for the headers
  // (and the search template). Returns null if no token comes in time.
  static Future<({String token, String clientToken, String? search})?> refresh(
      String spDc) async {
    HeadlessInAppWebView? hw;
    final tok = Completer<({String token, String clientToken})?>();
    final tpl = Completer<String?>();
    try {
      await _setSpDc(spDc);
      hw = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: _searchPage),
        initialUserScripts: scripts(),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent: ua,
        ),
        onWebViewCreated: (c) {
          c.addJavaScriptHandler(
            handlerName: 'lsTok',
            callback: (a) {
              if (a.length >= 2 && !tok.isCompleted) {
                tok.complete(
                    (token: a[0].toString(), clientToken: a[1].toString()));
              }
              return null;
            },
          );
          c.addJavaScriptHandler(
            handlerName: 'lsSearch',
            callback: (a) {
              if (a.isNotEmpty && !tpl.isCompleted) tpl.complete(a[0].toString());
              return null;
            },
          );
        },
      );
      await hw.run();
      final t = await tok.future
          .timeout(const Duration(seconds: 25), onTimeout: () => null);
      if (t == null) return null;
      // The search request usually comes right after the token.
      final q = await tpl.future
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
      return (token: t.token, clientToken: t.clientToken, search: q);
    } catch (_) {
      return null;
    } finally {
      try {
        await hw?.dispose();
      } catch (_) {}
    }
  }
}
