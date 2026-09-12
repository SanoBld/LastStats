// lib/screens/settings/backup_page.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/l10n.dart';
import '../../services/backup_service.dart';
import '../../services/crash_log_service.dart';
import 'settings_helpers.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _exporting = false;
  bool _importing = false;
  bool _logBusy   = false;
  int? _logSizeBytes; // null = not checked yet, 0 = empty

  @override
  void initState() {
    super.initState();
    _refreshLogSize();
  }

  Future<void> _refreshLogSize() async {
    final f = await CrashLogService.instance.getFile();
    if (!mounted) return;
    if (f == null || !await f.exists()) { setState(() => _logSizeBytes = 0); return; }
    final len = await f.length();
    if (mounted) setState(() => _logSizeBytes = len);
  }

  Future<void> _shareLog() async {
    setState(() => _logBusy = true);
    final f = await CrashLogService.instance.getFile();
    if (!mounted) return;
    setState(() => _logBusy = false);
    if (f == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.backupCrashLogEmpty), behavior: SnackBarBehavior.floating));
      return;
    }
    final empty = !await f.exists() || await f.length() == 0;
    if (!mounted) return;
    if (empty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.backupCrashLogEmpty), behavior: SnackBarBehavior.floating));
      return;
    }
    await Share.shareXFiles([XFile(f.path)], text: 'LastStats — crash_log.txt');
  }

  Future<void> _clearLog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.backupCrashLogClearConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L.backupCrashLogClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CrashLogService.instance.clear();
    if (!mounted) return;
    setState(() => _logSizeBytes = 0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(L.backupCrashLogCleared), behavior: SnackBarBehavior.floating));
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  // Simple dd/mm/yyyy formatting for the backup date, no extra package.
  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  // Whether to include the Last.fm API key / secret key in the exported
  // file. Both default to on; the user can uncheck either before exporting
  // (e.g. to share a backup without sensitive credentials).
  bool _includeApiKey    = true;
  bool _includeSecretKey = true;
  bool _includeFolders   = true;
  bool _includeThemes    = true;
  // NEW: off by default, since embedding the full listening history makes
  // the backup file much bigger.
  bool _includeScrobbles = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    final ok = await BackupService.exportToFile(
      includeApiKey:    _includeApiKey,
      includeSecretKey: _includeSecretKey,
      includeFolders:   _includeFolders,
      includeThemes:    _includeThemes,
      includeScrobbles: _includeScrobbles,
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
    // present in the backup file. Also offer to restore the scrobble
    // history if this backup has one — shown together in the same dialog,
    // and the dialog's title/subtitle already say when the backup is from.
    bool restoreApiKey    = preview.hasApiKey;
    bool restoreSecretKey = preview.hasSecretKey;
    bool restoreScrobbles = preview.hasScrobbles;

    if (preview.hasApiKey || preview.hasSecretKey || preview.hasScrobbles) {
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
                // Backup date: always shown to the user before restoring.
                if (preview.exportedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    L.backupExportedOn(_fmtDate(preview.exportedAt!)),
                    style: Theme.of(dialogCtx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(dialogCtx).colorScheme.onSurfaceVariant),
                  ),
                ],
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
                if (preview.hasScrobbles)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(L.backupIncludeScrobblesLabel),
                    value: restoreScrobbles,
                    onChanged: (v) => setDialogState(() => restoreScrobbles = v ?? false),
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

    // If we're restoring scrobbles, check them for corruption FIRST and
    // ask the user what to do before touching anything on disk.
    var scrobbleMode = ScrobbleConflictMode.keepAnyway;
    if (restoreScrobbles) {
      final check = BackupService.checkScrobbles(preview.raw);
      if (check.hasErrors) {
        final choice = await showDialog<ScrobbleConflictMode>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(L.backupScrobblesErrorTitle),
            content: Text(L.backupScrobblesErrorDesc),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx)
                    .pop(ScrobbleConflictMode.cancelScrobbles),
                child: Text(L.backupScrobblesCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogCtx)
                    .pop(ScrobbleConflictMode.skipAndRefetch),
                child: Text(L.backupScrobblesSkipRefetch),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx)
                    .pop(ScrobbleConflictMode.keepAnyway),
                child: Text(L.backupScrobblesKeepAnyway),
              ),
            ],
          ),
        );
        // Dialog dismissed (e.g. back button): safest default is to not
        // touch the scrobble history at all.
        scrobbleMode = choice ?? ScrobbleConflictMode.cancelScrobbles;
      }
    }

    final result = await BackupService.applyBackupJson(
      preview.raw,
      restoreApiKey:    restoreApiKey,
      restoreSecretKey: restoreSecretKey,
      restoreScrobbles: restoreScrobbles,
      scrobbleMode:     scrobbleMode,
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
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.folder_rounded, color: scheme.primary),
            title: Text(L.backupIncludeFoldersLabel,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.backupIncludeFoldersDesc,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            value: _includeFolders,
            onChanged: (v) => setState(() => _includeFolders = v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.palette_rounded, color: scheme.primary),
            title: Text(L.backupIncludeThemesLabel,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.backupIncludeThemesDesc,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            value: _includeThemes,
            onChanged: (v) => setState(() => _includeThemes = v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.library_music_rounded, color: scheme.primary),
            title: Text(L.backupIncludeScrobblesLabel,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              // Extra warning: this option can take a while and re-syncs
              // with Last.fm before exporting, so it's slower than a
              // normal backup — the user should know that up front.
              '${L.backupIncludeScrobblesDesc} ${L.backupScrobblesSlowWarning}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            value: _includeScrobbles,
            onChanged: (v) => setState(() => _includeScrobbles = v),
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

        const SizedBox(height: 16),

        // ── Journal d'erreurs ─────────────────────────────────────────────
        SettingsSection(label: L.settingsCrashLog, children: [
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.description_outlined, color: scheme.onTertiaryContainer, size: 22),
            ),
            title: Text(L.settingsCrashLog,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              _logSizeBytes == null
                  ? L.backupCrashLogDesc
                  : (_logSizeBytes == 0 ? L.backupCrashLogEmpty : _fmtSize(_logSizeBytes!)),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_logBusy || (_logSizeBytes ?? 0) == 0) ? null : _shareLog,
                  icon: _logBusy
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(L.backupCrashLogShare),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_logSizeBytes ?? 0) == 0 ? null : _clearLog,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(L.backupCrashLogClear),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error),
                  ),
                ),
              ),
            ]),
          ),
        ]),

        const SizedBox(height: 16),

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