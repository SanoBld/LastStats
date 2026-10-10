// Spotify login inside the app. When the web player has loaded, we read
// its token headers and the "sp_dc" login cookie, save them, and close.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../l10n/extra_strings.dart';
import '../../services/spotify_canvas_service.dart';
import '../../services/spotify_web_session.dart';

class SpotifyLoginPage extends StatefulWidget {
  const SpotifyLoginPage({super.key});

  /// True when the user is now connected.
  static Future<bool> open(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const SpotifyLoginPage()));
    return ok ?? false;
  }

  @override
  State<SpotifyLoginPage> createState() => _SpotifyLoginPageState();
}

class _SpotifyLoginPageState extends State<SpotifyLoginPage> {
  bool _done = false;
  double _progress = 0;

  Future<void> _onTokens(String bearer, String ct) async {
    if (_done) return;
    // The cookie can arrive a moment after the first requests: retry.
    String? spDc;
    for (var i = 0; i < 10 && spDc == null; i++) {
      spDc = await SpotifyWebSession.readSpDc();
      if (spDc == null) await Future.delayed(const Duration(milliseconds: 500));
    }
    if (spDc == null || _done || !mounted) return;
    _done = true;
    await SpotifyCanvasService.saveLogin(spDc, bearer, ct);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tx('sp_login_t'))),
      body: Column(children: [
        if (_progress < 1) LinearProgressIndicator(value: _progress),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Text(tx('sp_login_hint'),
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(
                url: WebUri('https://accounts.spotify.com/login'
                    '?continue=https%3A%2F%2Fopen.spotify.com%2F')),
            initialUserScripts: SpotifyWebSession.scripts(),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              userAgent: SpotifyWebSession.ua,
            ),
            onWebViewCreated: (c) {
              c.addJavaScriptHandler(
                handlerName: 'lsTok',
                callback: (a) {
                  if (a.length >= 2) _onTokens(a[0].toString(), a[1].toString());
                  return null;
                },
              );
            },
            onProgressChanged: (_, p) {
              if (mounted) setState(() => _progress = p / 100);
            },
          ),
        ),
      ]),
    );
  }
}
