// lib/screens/settings/account_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  AccountPage — gestion des comptes Last.fm (multi-comptes, max 3)
//
//  Fonctionnalités :
//    • Affiche le compte actif en en-tête.
//    • Liste tous les comptes avec indicateur actif / bouton de bascule.
//    • Ajout d'un nouveau compte (jusqu'à 3) avec option "même clé API".
//    • Suppression d'un compte secondaire.
//    • Déconnexion globale (supprime tous les comptes).
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n.dart';
import '../../app_state.dart';
import '../../services/account_manager.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    super.dispose();
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
  }

  // ── Basculer vers un autre compte ────────────────────────────────────────

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

  // ── Supprimer un compte ───────────────────────────────────────────────────

  Future<void> _removeAccount(int index) async {
    final isEn = localeNotifier.value == 'en';
    final acc  = _accounts[index];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Remove account?' : 'Supprimer le compte ?'),
        content: Text(isEn
            ? 'Remove @${acc.username} from your accounts?'
            : 'Supprimer @${acc.username} de vos comptes ?'),
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
            child: Text(isEn ? 'Remove' : 'Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final wasActive = index == _activeIndex;
    await AccountManager.remove(index);

    if (!mounted) return;

    if (wasActive) {
      // Le compte actif a été supprimé → rebascule sur le premier compte restant
      final remaining = await AccountManager.getAll();
      if (remaining.isEmpty) {
        _logoutAll();
        return;
      }
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

  // ── Ajouter un compte ────────────────────────────────────────────────────

  Future<void> _addAccount() async {
    if (_accounts.length >= AccountManager.maxAccounts) return;
    final isEn = localeNotifier.value == 'en';

    final result = await showDialog<AccountEntry>(
      context: context,
      builder: (_) => _AddAccountDialog(
        existingApiKey: _accounts.isNotEmpty
            ? _accounts[_activeIndex].apiKey
            : null,
        isEn: isEn,
      ),
    );
    if (result == null || !mounted) return;

    final added = await AccountManager.add(result);
    if (!mounted) return;

    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEn
            ? 'This account is already added or the list is full.'
            : 'Ce compte est déjà ajouté ou la liste est pleine.'),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEn
            ? '@${result.username} added successfully.'
            : '@${result.username} ajouté avec succès.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Déconnexion globale ───────────────────────────────────────────────────

  Future<void> _logoutAll() async {
    final isEn = localeNotifier.value == 'en';
    final ok   = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.settingsLogoutTitle),
        content: Text(isEn
            ? 'All accounts will be removed. You will return to the setup screen.'
            : 'Tous les comptes seront supprimés. Vous retournerez à l\'écran de configuration.'),
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
    final isEn   = localeNotifier.value == 'en';

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

        // ── En-tête : compte actif ─────────────────────────────────────────
        if (active != null) ...[
          Center(child: Column(children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                active.username[0].toUpperCase(),
                style: TextStyle(
                    fontSize: 32,
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700),
              ),
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

        // ── Liste des comptes ──────────────────────────────────────────────
        SettingsSection(
          label: isEn
              ? 'My accounts (${_accounts.length}/${AccountManager.maxAccounts})'
              : 'Mes comptes (${_accounts.length}/${AccountManager.maxAccounts})',
          children: [
            ..._accounts.asMap().entries.map((entry) {
              final idx    = entry.key;
              final acc    = entry.value;
              final isAct  = idx == _activeIndex;

              return Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isAct ? scheme.primary : scheme.surfaceContainerHighest,
                    child: Text(
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
                            isEn ? 'Active' : 'Actif',
                            style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ])
                      : Text(
                          isEn ? 'Tap "Switch" to activate' : 'Touchez "Activer" pour basculer',
                          style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    // Bouton de bascule (comptes non-actifs)
                    if (!isAct)
                      TextButton(
                        onPressed: () => _switchTo(idx),
                        child: Text(isEn ? 'Switch' : 'Activer'),
                      ),
                    // Bouton de suppression (si plus d'un compte)
                    if (_accounts.length > 1)
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            color: scheme.error, size: 20),
                        tooltip: isEn ? 'Remove' : 'Supprimer',
                        onPressed: () => _removeAccount(idx),
                      ),
                  ]),
                ),
                if (idx < _accounts.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ]);
            }),

            // ── Bouton ajouter un compte ──────────────────────────────────
            const Divider(height: 1, indent: 16, endIndent: 16),
            if (_accounts.length < AccountManager.maxAccounts)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded,
                      color: scheme.onSecondaryContainer, size: 22),
                ),
                title: Text(
                  isEn ? 'Add an account' : 'Ajouter un compte',
                  style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: scheme.primary),
                ),
                subtitle: Text(
                  isEn
                      ? '${AccountManager.maxAccounts - _accounts.length} slot(s) remaining'
                      : '${AccountManager.maxAccounts - _accounts.length} emplacement(s) restant(s)',
                  style:
                      text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                onTap: _addAccount,
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    isEn
                        ? 'Maximum of 3 accounts reached.'
                        : 'Maximum de 3 comptes atteint.',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ]),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Info clé API ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.key_rounded, size: 16, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn
                    ? 'Each account can use a different API key or the same one. You can find your API key at last.fm/api/accounts.'
                    : 'Chaque compte peut utiliser une clé API différente ou la même. Votre clé API est disponible sur last.fm/api/accounts.',
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Profil Last.fm (lien) ──────────────────────────────────────────
        if (active != null)
          SettingsSection(
            label: isEn ? 'Last.fm Profile' : 'Profil Last.fm',
            children: [
              ListTile(
                leading:
                    Icon(Icons.open_in_new_rounded, color: scheme.primary, size: 20),
                title: Text(isEn ? 'View on Last.fm' : 'Voir sur Last.fm'),
                subtitle: Text(
                  'last.fm/user/${active.username}',
                  style:
                      text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // ── Danger zone ────────────────────────────────────────────────────
        SettingsSection(
          label: isEn ? 'Danger Zone' : 'Zone de danger',
          children: [
            ListTile(
              leading: Icon(Icons.logout_rounded, color: scheme.error),
              title: Text(
                L.settingsLogout,
                style: TextStyle(
                    color: scheme.error, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isEn
                    ? 'Remove all accounts and return to the setup screen.'
                    : 'Supprimer tous les comptes et revenir à la configuration.',
                style:
                    text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
//  Dialogue d'ajout de compte
// ══════════════════════════════════════════════════════════════════════════

class _AddAccountDialog extends StatefulWidget {
  final String? existingApiKey;
  final bool    isEn;

  const _AddAccountDialog({this.existingApiKey, required this.isEn});

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
      setState(() => _error = widget.isEn
          ? 'Username is required.'
          : 'Le pseudo est requis.');
      return;
    }
    if (apiKey.isEmpty) {
      setState(() => _error = widget.isEn
          ? 'API key is required.'
          : 'La clé API est requise.');
      return;
    }
    Navigator.pop(context, AccountEntry(username: username, apiKey: apiKey));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(widget.isEn ? 'Add an account' : 'Ajouter un compte'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // ── Pseudo ──────────────────────────────────────────────────────
          TextField(
            controller: _usernameCtrl,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: widget.isEn ? 'Last.fm username' : 'Pseudo Last.fm',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),

          // ── Option : même clé API ────────────────────────────────────
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
                      widget.isEn
                          ? 'Same API key as the active account'
                          : 'Même clé API que le compte actif',
                      style: text.bodySmall,
                    ),
                  ),
                ]),
              ),
            ),
          ],

          // ── Clé API (masquée si même clé) ───────────────────────────
          if (!_sameApiKey) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: widget.isEn ? 'API key' : 'Clé API',
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],

          // ── Erreur ──────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
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
          child: Text(widget.isEn ? 'Add' : 'Ajouter'),
        ),
      ],
    );
  }
}