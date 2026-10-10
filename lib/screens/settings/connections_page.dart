// Profile > Connection page: every account the app can connect to.
// Tap a service to unfold it, then connect or disconnect.
import 'package:flutter/material.dart';
import '../../l10n/extra_strings.dart';
import '../../l10n/l10n.dart';
import '../../services/account_manager.dart';
import '../../services/internal_keys.dart';
import '../../services/spotify_canvas_service.dart';
import '../../widgets/brand_icon.dart';
import '../../widgets/m3_components.dart';
import 'account_page.dart';
import 'lastfm_login_page.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';
import 'spotify_login_page.dart';

class ConnectionsPage extends StatefulWidget {
  final String username;
  const ConnectionsPage({super.key, required this.username});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  bool _sp = false;
  bool _testing = false;
  String? _test;

  @override
  void initState() {
    super.initState();
    _loadSp();
  }

  Future<void> _loadSp() async {
    final on = await SpotifyCanvasService.isConnected();
    if (mounted) setState(() => _sp = on);
  }

  Future<void> _spTap() async {
    if (_sp) {
      await SpotifyCanvasService.disconnect();
      if (!mounted) return;
      setState(() { _sp = false; _test = null; });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tx('sp_off_s'))));
      return;
    }
    final ok = await SpotifyLoginPage.open(context);
    if (mounted) setState(() => _sp = ok);
  }

  Future<void> _runTest() async {
    setState(() { _testing = true; _test = null; });
    final r = await SpotifyCanvasService.diagnose();
    if (mounted) setState(() { _testing = false; _test = r; });
  }

  // Log in on the Last.fm website: the app adds the account with its
  // built-in API key (no key needed from the user).
  Future<void> _lfmWeb() async {
    final name = await LastfmLoginPage.open(context);
    if (name == null || !mounted) return;
    final ok = await AccountManager.add(
        AccountEntry(username: name, apiKey: await InternalKeys.pick()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? L.acctAddedSuccess(name) : L.acctAlreadyAddedOrFull)));
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sub = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return Scaffold(
      appBar: M3AppBar(title: tx('conn_btn_t')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SettingsSection(
          label: tx('conn_title'),
          children: [
            // Last.fm
            SettingExpandable(
              icon: Icons.bar_chart_rounded,
              leadingWidget: BrandIcon('assets/icons/lastfm.svg',
                  Icons.bar_chart_rounded, color: scheme.primary),
              title: 'Last.fm',
              body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${tx('sp_on')}: @${widget.username}',
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(tx('conn_lfm_desc'), style: sub),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton(
                    onPressed: _lfmWeb,
                    child: Text(tx('conn_lfm_web')),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _open(AccountPage(username: widget.username)),
                    child: Text(tx('conn_manage')),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _open(
                        AccountPage(username: widget.username, keysOnly: true)),
                    child: Text(tx('conn_keys')),
                  ),
                ]),
              ]),
            ),
            // Spotify
            SettingExpandable(
              icon: Icons.graphic_eq_rounded,
              leadingWidget: BrandIcon('assets/icons/spotify.svg',
                  Icons.graphic_eq_rounded, color: scheme.primary),
              title: 'Spotify',
              body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tx('conn_sp_desc'), style: sub),
                const SizedBox(height: 8),
                Text(tx(_sp ? 'sp_on' : 'sp_off'),
                    style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _sp ? scheme.primary : scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(tx('conn_q_note'),
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton(
                    onPressed: _spTap,
                    child: Text(tx(_sp ? 'conn_disconnect' : 'conn_connect')),
                  ),
                  if (_sp)
                    FilledButton.tonal(
                      onPressed: _testing ? null : _runTest,
                      child: Text(tx(_testing ? 'conn_testing' : 'conn_test')),
                    ),
                ]),
                if (_test != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(_test!,
                      style: text.bodySmall?.copyWith(fontFamily: 'monospace')),
                ],
              ]),
            ),
          ],
        ),
      ]),
    );
  }
}
