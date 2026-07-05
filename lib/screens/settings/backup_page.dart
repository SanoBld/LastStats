// lib/screens/settings/backup_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {

  // Toutes les clés SharedPreferences à inclure dans la sauvegarde.
  // Ordre : compte(s) → apparence → dashboard → démarrage → langue → favoris → mises à jour.
  static const _kBackupKeys = [
    // ── Compte(s) ─────────────────────────────────────────────────────
    'ls_username',        // compte principal (rétrocompat mono-compte)
    'ls_apikey',          // clé API principale
    'ls_accounts',        // JSON multi-comptes (AccountManager)
    'ls_active_account',  // index du compte actif
    // ── Apparence ─────────────────────────────────────────────────────
    'ls_theme',
    'ls_accent',
    'ls_use_dynamic_color',
    'ls_use_nowplaying_color',
    // ── Dashboard — en-tête ───────────────────────────────────────────
    'ls_header_source',
    'ls_header_period',
    'ls_header_animation',
    'ls_header_blur',
    'ls_header_custom_url',
    'ls_header_fallback_enabled',
    'ls_header_fallback_url',
    'ls_header_fallback_type',
    'ls_header_fallback_period',
    // ── Dashboard — sections & cartes ─────────────────────────────────
    'ls_show_nowplay',
    'ls_show_stats',
    'ls_show_artists',
    'ls_show_tracks',
    'ls_show_friends',
    'ls_stat_cards',
    // ── Démarrage ─────────────────────────────────────────────────────
    'ls_startup_tab',
    // ── Langue ────────────────────────────────────────────────────────
    'ls_locale',
    // ── Favoris ───────────────────────────────────────────────────────
    'ls_fav_friends',
    'ls_fav_profiles',
    // ── Mises à jour ──────────────────────────────────────────────────
    'ls_auto_update_check',
    // ls_last_update_check intentionnellement exclu (timestamp runtime)
  ];

  Future<void> _export() async {
    final p   = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final key in _kBackupKeys) {
      final v = p.get(key);
      if (v != null) map[key] = v;
    }

    // ── Résoudre le compte actif pour les champs de compatibilité ─────
    String activeUsername = '';
    String activeApiKey   = '';

    // Priorité 1 : multi-comptes (AccountManager)
    final accountsRaw = map['ls_accounts'];
    if (accountsRaw != null) {
      try {
        final accounts  = jsonDecode(accountsRaw.toString()) as List;
        final activeIdx = (map['ls_active_account'] as num?)?.toInt() ?? 0;
        if (accounts.isNotEmpty) {
          final acc       = accounts[activeIdx.clamp(0, accounts.length - 1)]
              as Map<String, dynamic>;
          activeUsername  = (acc['username'] ?? '').toString();
          activeApiKey    = (acc['apiKey']   ?? '').toString();
        }
      } catch (_) {}
    }
    // Priorité 2 : mono-compte legacy
    if (activeUsername.isEmpty) activeUsername = (map['ls_username'] ?? '').toString();
    if (activeApiKey.isEmpty)   activeApiKey   = (map['ls_apikey']   ?? '').toString();

    final now     = DateTime.now();
    final payload = jsonEncode({
      // ── Champs racine ────────────────────────────────────────────────
      // Compatibles avec le champ JSON de l'écran de connexion :
      //   username / api_key sont reconnus directement par _applyJson().
      'app':         'LastStats',
      'version':     '2',
      'exported_at': now.toIso8601String(),
      'username':    activeUsername,    // ← raccourci connexion rapide
      'api_key':     activeApiKey,      // ← raccourci connexion rapide
      // ── Toutes les préférences ───────────────────────────────────────
      'prefs': map,
    });

    final dateStr = '${now.year}-'
        '${now.month.toString().padLeft(2,'0')}-'
        '${now.day.toString().padLeft(2,'0')}';
    final defName = 'laststats_backup_$dateStr.json';
    if (!mounted) return;
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => ExportSheet(payload: payload, defaultName: defName),
    );
  }

  Future<void> _import() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        String? err;
        return StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
          title: Text(L.importTitle),
          content: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.importHintLabel, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl, maxLines: 5, autofocus: true,
              decoration: InputDecoration(
                hintText: '{"app":"LastStats",...}',
                border: const OutlineInputBorder(),
                errorText: err,
              ),
              onChanged: (_) { if (err != null) setDlg(() => err = null); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(L.commonCancel)),
            FilledButton(
              onPressed: () async {
                final raw = ctrl.text.trim();
                if (raw.isEmpty) { setDlg(() => err = L.importEmpty); return; }
                Map<String, dynamic> parsed;
                try { parsed = jsonDecode(raw) as Map<String, dynamic>; }
                catch (_) { setDlg(() => err = L.importInvalidJson); return; }

                // ── Accepte le format backup LastStats (version 1 ou 2) ─
                if (parsed['app'] == 'LastStats') {
                  final prefs = parsed['prefs'];
                  if (prefs is! Map) { setDlg(() => err = L.importInvalidFormat); return; }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _applyBackup(Map<String, dynamic>.from(prefs));
                  return;
                }

                // ── Accepte le format simple {"username":"…","api_key":"…"} ─
                // (par exemple un export depuis un autre outil)
                final u = (parsed['username'] ?? '').toString().trim();
                final k = (parsed['api_key'] ?? parsed['apiKey'] ?? parsed['api-key'] ?? '').toString().trim();
                if (u.isNotEmpty && k.isNotEmpty) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _applyBackup({'ls_username': u, 'ls_apikey': k});
                  return;
                }

                setDlg(() => err = L.importUnknownFile);
              },
              child: Text(L.importRestore),
            ),
          ],
        ));
      },
    );
    ctrl.dispose();
  }

  Future<void> _applyBackup(Map<String, dynamic> prefs) async {
    final p = await SharedPreferences.getInstance();
    for (final e in prefs.entries) {
      if (!e.key.startsWith('ls_')) continue;
      final v = e.value;
      if (v is bool)        await p.setBool(e.key, v);
      else if (v is int)    await p.setInt(e.key, v);
      else if (v is double) await p.setDouble(e.key, v);
      else if (v is String) await p.setString(e.key, v);
      else if (v is List)   await p.setStringList(e.key, List<String>.from(v));
    }

    // ── Synchroniser ls_username / ls_apikey depuis le compte actif ───
    // Si ls_accounts est restauré, s'assurer que ls_username / ls_apikey
    // correspondent bien au compte actif (AccountManager.switchTo() fait
    // la même chose mais on évite l'import circulaire ici).
    final accountsRaw = p.getString('ls_accounts');
    if (accountsRaw != null && accountsRaw.isNotEmpty) {
      try {
        final accounts  = jsonDecode(accountsRaw) as List;
        final activeIdx = p.getInt('ls_active_account') ?? 0;
        if (accounts.isNotEmpty) {
          final acc = accounts[activeIdx.clamp(0, accounts.length - 1)]
              as Map<String, dynamic>;
          final u = (acc['username'] ?? '').toString();
          final k = (acc['apiKey']   ?? '').toString();
          if (u.isNotEmpty) await p.setString('ls_username', u);
          if (k.isNotEmpty) await p.setString('ls_apikey',   k);
        }
      } catch (_) {}
    }

    // ── Mettre à jour les notifiers en mémoire ────────────────────────
    themeModeNotifier.value          = themeFromString(p.getString('ls_theme'));
    accentNotifier.value             = accentFromString(p.getString('ls_accent'));
    useDynamicColorNotifier.value    = p.getBool('ls_use_dynamic_color')    ?? false;
    useNowPlayingColorNotifier.value = p.getBool('ls_use_nowplaying_color') ?? false;
    localeNotifier.value             = p.getString('ls_locale')             ?? 'fr';

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.importSuccess), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsBackup),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // Info générale
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.backup_rounded, color: scheme.onPrimaryContainer, size: 22),
              const SizedBox(width: 10),
              Text(L.backupWhatsIncluded,
                  style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
            ]),
            const SizedBox(height: 8),
            Text(L.settingsBackupInfo,
                style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer)),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Export ────────────────────────────────────────────────────────
        SettingsSection(label: L.settingsExport, children: [
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.upload_rounded, color: scheme.onPrimaryContainer, size: 22),
            ),
            title: Text(L.settingsExport,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.settingsExportSub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            onTap: _export,
          ),
        ]),

        const SizedBox(height: 16),

        // ── Import ────────────────────────────────────────────────────────
        SettingsSection(label: L.settingsImport, children: [
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.download_rounded, color: scheme.onSecondaryContainer, size: 22),
            ),
            title: Text(L.settingsImport,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.settingsImportSub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            onTap: _import,
          ),
        ]),

        const SizedBox(height: 20),

        // Avertissement données
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(child: Text(
              L.backupOverwriteWarning,
              style: text.bodySmall?.copyWith(color: scheme.error),
            )),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}