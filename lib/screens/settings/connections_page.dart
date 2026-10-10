// Profile > Connection page: one card per service, with its status and
// big buttons for each action.
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
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

  // The website logins run in a WebView: phones only.
  bool get _canWebLogin =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _loadSp();
  }

  Future<void> _loadSp() async {
    final on = await SpotifyCanvasService.isConnected();
    if (mounted) setState(() => _sp = on);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _spTap() async {
    if (_sp) {
      await SpotifyCanvasService.disconnect();
      if (!mounted) return;
      setState(() { _sp = false; _test = null; });
      _snack(tx('sp_off_s'));
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

  // Log in on the Last.fm website: the account is added with the
  // built-in API key (no key needed from the user).
  Future<void> _lfmWeb() async {
    final name = await LastfmLoginPage.open(context);
    if (name == null || !mounted) return;
    final ok = await AccountManager.add(
        AccountEntry(username: name, apiKey: await InternalKeys.pick()));
    if (!mounted) return;
    _snack(ok ? L.acctAddedSuccess(name) : L.acctAlreadyAddedOrFull);
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final body = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return Scaffold(
      appBar: M3AppBar(title: tx('conn_btn_t')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // ── Last.fm ──
        _ServiceCard(
          logo: BrandIcon('assets/icons/lastfm.svg', Icons.bar_chart_rounded,
              size: 28, color: scheme.onPrimaryContainer),
          title: 'Last.fm',
          status: '@${widget.username}',
          connected: true,
          description: Text(tx('conn_lfm_desc'), style: body),
          actions: [
            // Method 1: own API key (recommended)
            _ActionButton(
              style: _BtnStyle.filled,
              icon: Icons.key_rounded,
              label: '${tx('conn_keys')} (${tx('rec')})',
              onPressed: () =>
                  _open(AccountPage(username: widget.username, keysOnly: true)),
            ),
            // Method 2: website login (not recommended)
            if (_canWebLogin)
              _ActionButton(
                style: _BtnStyle.outlined,
                icon: Icons.login_rounded,
                label: '${tx('conn_lfm_web')} (${tx('not_rec')})',
                onPressed: _lfmWeb,
              ),
            _ActionButton(
              style: _BtnStyle.tonal,
              icon: Icons.manage_accounts_rounded,
              label: tx('conn_manage'),
              onPressed: () => _open(AccountPage(username: widget.username)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Spotify ──
        _ServiceCard(
          logo: BrandIcon('assets/icons/spotify.svg', Icons.graphic_eq_rounded,
              size: 28, color: scheme.onPrimaryContainer),
          title: 'Spotify',
          status: tx(_sp ? 'sp_on' : 'sp_off'),
          connected: _sp,
          description: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx('conn_sp_desc'), style: body),
            const SizedBox(height: 6),
            Text(tx('conn_q_note'),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
          actions: [
            _ActionButton(
              style: _sp ? _BtnStyle.outlined : _BtnStyle.filled,
              icon: _sp ? Icons.logout_rounded : Icons.login_rounded,
              label: tx(_sp ? 'conn_disconnect' : 'conn_connect'),
              onPressed: _spTap,
            ),
            if (_sp)
              _ActionButton(
                style: _BtnStyle.tonal,
                icon: Icons.network_check_rounded,
                label: tx(_testing ? 'conn_testing' : 'conn_test'),
                onPressed: _testing ? null : _runTest,
              ),
          ],
          footer: _test == null
              ? null
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(_test!,
                      style: text.bodySmall?.copyWith(fontFamily: 'monospace')),
                ),
        ),
      ]),
    );
  }
}

enum _BtnStyle { filled, tonal, outlined }

// One big, full-width action button.
class _ActionButton extends StatelessWidget {
  final _BtnStyle style;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _ActionButton({
    required this.style,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final pad = const EdgeInsets.symmetric(vertical: 14, horizontal: 16);
    final child = Text(label, textAlign: TextAlign.center);
    final btn = switch (style) {
      _BtnStyle.filled => FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: child,
          style: FilledButton.styleFrom(padding: pad, shape: shape)),
      _BtnStyle.tonal => FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: child,
          style: FilledButton.styleFrom(padding: pad, shape: shape)),
      _BtnStyle.outlined => OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: child,
          style: OutlinedButton.styleFrom(padding: pad, shape: shape)),
    };
    return SizedBox(width: double.infinity, child: btn);
  }
}

// Card: logo + name + status pill, a description, then the buttons.
class _ServiceCard extends StatelessWidget {
  final Widget logo;
  final String title, status;
  final bool connected;
  final Widget description;
  final List<Widget> actions;
  final Widget? footer;
  const _ServiceCard({
    required this.logo,
    required this.title,
    required this.status,
    required this.connected,
    required this.description,
    required this.actions,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: scheme.primaryContainer, shape: BoxShape.circle),
              child: logo,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: connected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle,
                    size: 8,
                    color: connected ? scheme.primary : scheme.outline),
                const SizedBox(width: 6),
                Text(status,
                    style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: connected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          description,
          const SizedBox(height: 16),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            actions[i],
          ],
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ]),
      ),
    );
  }
}
