// lib/screens/settings/account_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  AccountPage — Last.fm account management (multi-account, max 3)
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import '../../services/account_manager.dart';
import '../../services/favorites_auth.dart';
import '../setup_screen.dart';
import '../home_screen.dart';
import 'settings_helpers.dart';

class AccountPage extends StatefulWidget {
  final String username;
  const AccountPage({super.key, required this.username});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  List<AccountEntry> _accounts    = [];
  int                _activeIndex = 0;
  bool               _loading     = true;
  String?            _avatarUrl;

  bool   _obscureApiKey  = true;
  bool   _obscureSecret  = true;
  bool   _connectingFav  = false;
  final  _secretCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectFav(AccountEntry active) async {
    setState(() => _connectingFav = true);
    await connectFavorites(
      context, username: active.username, apiKey: active.apiKey, secret: _secretCtrl.text,
    );
    if (mounted) setState(() => _connectingFav = false);
  }

  void _rebuild() => setState(() {});

  Future<void> _load() async {
    final accounts = await AccountManager.getAll();
    final active   = await AccountManager.getActiveIndex();
    if (!mounted) return;
    setState(() {
      _accounts    = accounts;
      _activeIndex = accounts.isEmpty ? 0 : active.clamp(0, accounts.length - 1);
      _loading     = false;
    });
    // Fetch avatar after accounts are loaded.
    if (accounts.isNotEmpty) _fetchAvatar(accounts[_activeIndex].username, accounts[_activeIndex].apiKey);
  }

  // Fetch the Last.fm profile picture URL for the active account.
  Future<void> _fetchAvatar(String username, String apiKey) async {
    try {
      final uri = Uri.parse(
        'https://ws.audioscrobbler.com/2.0/'
        '?method=user.getInfo'
        '&user=$username'
        '&api_key=$apiKey'
        '&format=json',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return;

      final data   = jsonDecode(res.body) as Map<String, dynamic>;
      final images = (data['user']?['image'] as List?)?.cast<Map<String, dynamic>>();
      if (images == null || images.isEmpty) return;

      // Pick the largest available non-empty image.
      String? url;
      for (final img in images.reversed) {
        final t = img['#text'] as String? ?? '';
        if (t.isNotEmpty) { url = t; break; }
      }
      if (url != null && mounted) setState(() => _avatarUrl = url);
    } catch (_) {}
  }

  // ── Switch to another account ────────────────────────────────────────────

  Future<void> _switchTo(int index) async {
    if (index == _activeIndex) return;
    await AccountManager.switchTo(index);
    if (!mounted) return;

    final acc = _accounts[index];
    final p   = await SharedPreferences.getInstance();
    final startupTab = p.getInt('ls_startup_tab') ?? 0;
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          username:   acc.username,
          apiKey:     acc.apiKey,
          startupTab: startupTab,
        ),
      ),
      (_) => false,
    );
  }

  // ── Remove an account ─────────────────────────────────────────────────────

  Future<void> _removeAccount(int index) async {
    final acc  = _accounts[index];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.acctRemoveTitle),
        content: Text(L.acctRemoveBody(acc.username)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L.acctRemoveAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final wasActive = index == _activeIndex;
    await AccountManager.remove(index);

    if (!mounted) return;

    if (wasActive) {
      final remaining = await AccountManager.getAll();
      if (remaining.isEmpty) { _logoutAll(); return; }
      final newAcc = remaining[0];
      final p = await SharedPreferences.getInstance();
      final startupTab = p.getInt('ls_startup_tab') ?? 0;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            username:   newAcc.username,
            apiKey:     newAcc.apiKey,
            startupTab: startupTab,
          ),
        ),
        (_) => false,
      );
    } else {
      await _load();
    }
  }

  // ── Add an account ────────────────────────────────────────────────────────

  Future<void> _addAccount() async {
    if (_accounts.length >= AccountManager.maxAccounts) return;

    final result = await showDialog<AccountEntry>(
      context: context,
      builder: (_) => _AddAccountDialog(
        existingApiKey: _accounts.isNotEmpty
            ? _accounts[_activeIndex].apiKey
            : null,
      ),
    );
    if (result == null || !mounted) return;

    final added = await AccountManager.add(result);
    if (!mounted) return;

    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.acctAlreadyAddedOrFull),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.acctAddedSuccess(result.username)),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Logout all ────────────────────────────────────────────────────────────

  Future<void> _logoutAll() async {
    final ok   = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.settingsLogoutTitle),
        content: Text(L.acctLogoutAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L.settingsLogoutConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final p = await SharedPreferences.getInstance();
    await p.remove('ls_username');
    await p.remove('ls_apikey');
    await p.remove('ls_accounts');
    await p.remove('ls_active_account');

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
      (_) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(L.settingsAccount), centerTitle: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final active = _accounts.isNotEmpty ? _accounts[_activeIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsAccount),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Active account header ──────────────────────────────────────────
        if (active != null) ...[
          Center(child: Column(children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null
                  ? Text(
                      active.username[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 32,
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text('@${active.username}',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(L.settingsConnectedProfile,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
          ])),
        ],

        // ── Account list ───────────────────────────────────────────────────
        SettingsSection(
          label: L.acctMyAccounts(_accounts.length, AccountManager.maxAccounts),
          children: [
            ..._accounts.asMap().entries.map((entry) {
              final idx   = entry.key;
              final acc   = entry.value;
              final isAct = idx == _activeIndex;

              return Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isAct ? scheme.primary : scheme.surfaceContainerHighest,
                    // Show avatar only for active account (others load on demand).
                    backgroundImage: (isAct && _avatarUrl != null)
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: (isAct && _avatarUrl != null)
                        ? null
                        : Text(
                            acc.username[0].toUpperCase(),
                            style: TextStyle(
                                fontSize: 16,
                                color: isAct ? scheme.onPrimary : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                  title: Text('@${acc.username}',
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: isAct
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.circle, size: 8, color: scheme.primary),
                          const SizedBox(width: 5),
                          Text(
                            L.acctActive,
                            style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ])
                      : Text(
                          L.acctTapSwitchToActivate,
                          style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (!isAct)
                      TextButton(
                        onPressed: () => _switchTo(idx),
                        child: Text(L.acctSwitch),
                      ),
                    if (_accounts.length > 1)
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            color: scheme.error, size: 20),
                        tooltip: L.acctRemoveAction,
                        onPressed: () => _removeAccount(idx),
                      ),
                  ]),
                ),
                if (idx < _accounts.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ]);
            }),

            // Add account button
            const Divider(height: 1, indent: 16, endIndent: 16),
            if (_accounts.length < AccountManager.maxAccounts)
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded,
                      color: scheme.onSecondaryContainer, size: 22),
                ),
                title: Text(
                  L.acctAddAnAccount,
                  style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: scheme.primary),
                ),
                subtitle: Text(
                  L.acctSlotsRemaining(AccountManager.maxAccounts - _accounts.length),
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                onTap: _addAccount,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    L.acctMaxReached(AccountManager.maxAccounts),
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ]),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // ── API key info ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.key_rounded, size: 16, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                L.acctApiKeyInfo,
                style: text.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── API keys (favorites) ────────────────────────────────────────────
        if (active != null)
          SettingsSection(
            label: L.acctApiKeysSection,
            children: [
              ListTile(
                leading: Icon(Icons.key_rounded, color: scheme.primary, size: 20),
                title: Text(L.acctApiKeyLabel),
                subtitle: Text(
                  _obscureApiKey ? '•' * 20 : active.apiKey,
                  style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant, fontFamily: 'monospace'),
                ),
                trailing: IconButton(
                  icon: Icon(_obscureApiKey
                      ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ValueListenableBuilder<String>(
                valueListenable: secretKeyNotifier,
                builder: (_, secret, __) => ListTile(
                  leading: Icon(Icons.favorite_rounded,
                      color: secret.isNotEmpty ? Colors.redAccent : scheme.onSurfaceVariant,
                      size: 20),
                  title: Text(L.acctSecretKeyLabel),
                  subtitle: Text(
                    secret.isEmpty
                        ? L.acctSecretKeyNotSet
                        : (_obscureSecret ? '•' * 20 : secret),
                    style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant, fontFamily: 'monospace'),
                  ),
                  trailing: secret.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(_obscureSecret
                              ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                        ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(L.acctFavoritesExplain,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: sessionKeyNotifier,
                    builder: (_, session, __) {
                      if (session.isNotEmpty) {
                        return OutlinedButton.icon(
                          onPressed: disconnectFavorites,
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: Text(L.acctDisconnectFavorites),
                          style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                        );
                      }
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        TextField(
                          controller:  _secretCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText:  L.acctSecretKeyLabel,
                            prefixIcon: const Icon(Icons.vpn_key_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _connectingFav ? null : () => _connectFav(active),
                          icon: _connectingFav
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.favorite_border_rounded, size: 18),
                          label: Text(L.acctConnectFavorites),
                        ),
                      ]);
                    },
                  ),
                ]),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // ── Last.fm profile link ───────────────────────────────────────────
        if (active != null)
          SettingsSection(
            label: L.acctLastfmProfileSection,
            children: [
              ListTile(
                leading: Icon(Icons.open_in_new_rounded, color: scheme.primary, size: 20),
                title: Text(L.acctViewOnLastfm),
                subtitle: Text(
                  'last.fm/user/${active.username}',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // ── Danger zone ────────────────────────────────────────────────────
        SettingsSection(
          label: L.acctDangerZone,
          children: [
            ListTile(
              leading: Icon(Icons.logout_rounded, color: scheme.error),
              title: Text(
                L.settingsLogout,
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                L.acctLogoutAllSub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              onTap: _logoutAll,
            ),
          ],
        ),

        const SizedBox(height: 20),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Add account dialog
// ══════════════════════════════════════════════════════════════════════════

class _AddAccountDialog extends StatefulWidget {
  final String? existingApiKey;

  const _AddAccountDialog({this.existingApiKey});

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _usernameCtrl = TextEditingController();
  final _apiKeyCtrl   = TextEditingController();
  bool  _sameApiKey   = false;
  bool  _obscureKey   = true;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameCtrl.text.trim();
    final apiKey   = _sameApiKey
        ? (widget.existingApiKey ?? '')
        : _apiKeyCtrl.text.trim();

    if (username.isEmpty) {
      setState(() => _error = L.acctUsernameRequired);
      return;
    }
    if (apiKey.isEmpty) {
      setState(() => _error = L.acctApiKeyRequired);
      return;
    }
    Navigator.pop(context, AccountEntry(username: username, apiKey: apiKey));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(L.acctAddAnAccount),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          TextField(
            controller: _usernameCtrl,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: L.acctUsernameLabel,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) { if (_error != null) setState(() => _error = null); },
          ),

          if (widget.existingApiKey != null) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() {
                _sameApiKey = !_sameApiKey;
                if (_error != null) _error = null;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Checkbox(
                    value: _sameApiKey,
                    onChanged: (v) => setState(() {
                      _sameApiKey = v ?? false;
                      if (_error != null) _error = null;
                    }),
                  ),
                  Expanded(
                    child: Text(
                      L.acctSameApiKey,
                      style: text.bodySmall,
                    ),
                  ),
                ]),
              ),
            ),
          ],

          if (!_sameApiKey) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: L.acctApiKeyLabel,
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) { if (_error != null) setState(() => _error = null); },
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: scheme.error, fontSize: 12)),
          ],
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(L.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(L.acctAdd),
        ),
      ],
    );
  }
}