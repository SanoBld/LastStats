// Last.fm login on the real website, inside the app. When the user is
// logged in, we read the user name from the page header and close.
import 'package:flutter/material.dart';
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

  // Reads the name from the "/user/NAME" link of the page header.
  static const _js = r'''
(function () {
  var a = document.querySelector('a.auth-link[href^="/user/"]');
  if (!a) {
    var l = document.querySelectorAll('a[href^="/user/"]');
    for (var i = 0; i < l.length; i++) {
      if (/auth|header|nav/i.test(l[i].className)) { a = l[i]; break; }
    }
  }
  if (!a) return '';
  var m = a.getAttribute('href').match(/^\/user\/([^\/?#]+)/);
  return m ? m[1] : '';
})()
''';

  Future<void> _check(InAppWebViewController c, WebUri? url) async {
    if (_done) return;
    final path = url?.path ?? '';
    if (path.contains('login') || path.contains('join')) return;
    final r = await c.evaluateJavascript(source: _js);
    if (r is String && r.isNotEmpty && mounted) {
      _done = true;
      Navigator.of(context).pop(Uri.decodeComponent(r));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tx('lfm_login_t'))),
      body: Column(children: [
        if (_progress < 1) LinearProgressIndicator(value: _progress),
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
      ]),
    );
  }
}
