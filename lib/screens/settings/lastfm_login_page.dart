// Last.fm login on the real website, inside the app. When the user is
// logged in, we read the user name from the page header and close.
import 'package:flutter/material.dart';
import '../../widgets/m3_components.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../l10n/extra_strings.dart';
import '../../services/spotify_web_session.dart';

class LastfmLoginPage extends StatefulWidget {
  const LastfmLoginPage({super.key});

  /// The user name, or null if the user closed the page.
  static Future<String?> open(BuildContext context) =>
      Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const LastfmLoginPage()));

  @override
  State<LastfmLoginPage> createState() => _LastfmLoginPageState();
}

class _LastfmLoginPageState extends State<LastfmLoginPage> {
  bool _done = false;
  double _progress = 0;

  // Reads the name from a "/user/NAME" link of the page header. Tries
  // several places, because the page markup is not documented.
  static const _js = r'''
(function () {
  var sels = ['a.auth-link[href^="/user/"]', 'header a[href^="/user/"]',
              'nav a[href^="/user/"]', '[class*="auth"] a[href^="/user/"]'];
  var a = null;
  for (var i = 0; i < sels.length && !a; i++) a = document.querySelector(sels[i]);
  if (a) {
    var m = a.getAttribute('href').match(/^\/user\/([^\/?#]+)/);
    if (m) return m[1];
  }
  var d = document.querySelector('[data-user-name],[data-username]');
  if (d) return d.getAttribute('data-user-name') || d.getAttribute('data-username') || '';
  return '';
})()
''';

  // Shown when the name could not be read: the user types it.
  bool _manual = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submitManual() {
    final n = _ctrl.text.trim().replaceFirst('@', '');
    if (n.isEmpty || _done) return;
    _done = true;
    Navigator.of(context).pop(n);
  }

  Future<void> _check(InAppWebViewController c, WebUri? url) async {
    if (_done) return;
    final path = url?.path ?? '';
    if (path.contains('login') || path.contains('join')) return;
    final r = await c.evaluateJavascript(source: _js);
    if (r is String && r.isNotEmpty && mounted) {
      _done = true;
      Navigator.of(context).pop(Uri.decodeComponent(r));
    } else if (mounted && !_manual) {
      setState(() => _manual = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tx('lfm_login_t'))),
      body: Column(children: [
        if (_progress < 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: M3WavyProgress(value: _progress),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Text(tx('lfm_login_hint'),
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest:
                URLRequest(url: WebUri('https://www.last.fm/login')),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              userAgent: SpotifyWebSession.ua,
            ),
            onLoadStop: (c, url) => _check(c, url),
            onProgressChanged: (_, p) {
              if (mounted) setState(() => _progress = p / 100);
            },
          ),
        ),
        if (_manual)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx('lfm_manual_hint'),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _submitManual(),
                    decoration: InputDecoration(
                        labelText: tx('lfm_manual_label'),
                        border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                    onPressed: _submitManual, child: Text(tx('conn_connect'))),
              ]),
            ]),
          ),
      ]),
    );
  }
}
