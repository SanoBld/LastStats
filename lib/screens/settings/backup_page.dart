// lib/screens/settings/backup_page.dart

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/backup_service.dart';
import 'settings_helpers.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _exporting = false;
  bool _importing = false;

  // Whether to include the Last.fm API key / secret key in the exported
  // file. Both default to on; the user can uncheck either before exporting
  // (e.g. to share a backup without sensitive credentials).
  bool _includeApiKey    = true;
  bool _includeSecretKey = true;

  Future<void> _export() async {
    setState(() => _exporting = true);
    final ok = await BackupService.exportToFile(
      includeApiKey:    _includeApiKey,
      includeSecretKey: _includeSecretKey,
    );
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? L.backupFileSaved : L.backupFileSaveFailed),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    final preview = await BackupService.pickAndPreviewFile();
    if (!mounted) return;
    if (preview == null) {
      setState(() => _importing = false);
      return; // user cancelled the picker, or file unreadable
    }

    // Ask which sensitive keys to restore, only for the ones actually
    // present in the backup file.
    bool restoreApiKey    = preview.hasApiKey;
    bool restoreSecretKey = preview.hasSecretKey;

    if (preview.hasApiKey || preview.hasSecretKey) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            title: Text(L.backupRestoreKeysTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.backupRestoreKeysDesc),
                if (preview.hasApiKey)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(L.backupRestoreApiKeyLabel),
                    value: restoreApiKey,
                    onChanged: (v) => setDialogState(() => restoreApiKey = v ?? false),
                  ),
                if (preview.hasSecretKey)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(L.backupRestoreSecretKeyLabel),
                    value: restoreSecretKey,
                    onChanged: (v) => setDialogState(() => restoreSecretKey = v ?? false),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(L.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: Text(L.commonApply),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true) {
        if (mounted) setState(() => _importing = false);
        return; // user cancelled the restore itself
      }
    }

    final result = await BackupService.applyBackupJson(
      preview.raw,
      restoreApiKey:    restoreApiKey,
      restoreSecretKey: restoreSecretKey,
    );
    if (!mounted) return;
    setState(() => _importing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success ? L.importSuccess : L.importInvalidFormat),
      behavior: SnackBarBehavior.floating,
    ));
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
              child: _exporting
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: scheme.onPrimaryContainer))
                  : Icon(Icons.upload_rounded, color: scheme.onPrimaryContainer, size: 22),
            ),
            title: Text(L.settingsExport,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.backupDownloadFile,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            onTap: _exporting ? null : _export,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.vpn_key_rounded, color: scheme.primary),
            title: Text(L.backupRestoreApiKeyLabel,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.backupIncludeKeysDesc,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            value: _includeApiKey,
            onChanged: (v) => setState(() => _includeApiKey = v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.key_rounded, color: scheme.primary),
            title: Text(L.backupRestoreSecretKeyLabel,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            value: _includeSecretKey,
            onChanged: (v) => setState(() => _includeSecretKey = v),
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
              child: _importing
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: scheme.onSecondaryContainer))
                  : Icon(Icons.folder_open_rounded, color: scheme.onSecondaryContainer, size: 22),
            ),
            title: Text(L.settingsImport,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.backupChooseFile,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            onTap: _importing ? null : _import,
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