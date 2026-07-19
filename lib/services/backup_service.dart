// lib/services/backup_service.dart
// ══════════════════════════════════════════════════════════════════════════
//  BackupService — single source of truth for exporting/importing app
//  settings, used by both the Settings > Backup page and the login screen.
//
//  KEY DISCOVERY IS DYNAMIC: every SharedPreferences key prefixed 'ls_' is
//  included automatically (minus a short runtime-only blocklist). This
//  means new settings — new themes, new toggles, whatever gets added later
//  — are backed up automatically, with nothing to remember to update here.
//
//  FILES ARE REAL FILES: export opens the native "Save As" dialog via
//  file_picker (no more copy-pasting JSON by hand); import opens the native
//  file picker and reads the .json directly.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';

/// Runtime-only / session state that should never be exported — everything
/// else under the 'ls_' prefix (including any future theme or setting key)
/// is included automatically.
const _kBackupExcludeKeys = {
  'ls_last_update_check',
};

class BackupResult {
  final bool success;
  final String? username;
  final String? apiKey;
  const BackupResult({required this.success, this.username, this.apiKey});
}

/// Lightweight look at a backup file's content, used to ask the user which
/// sensitive keys they want to restore before actually applying anything.
class BackupPreview {
  final String raw;
  final bool hasApiKey;
  final bool hasSecretKey;
  final String? username;
  const BackupPreview({
    required this.raw,
    required this.hasApiKey,
    required this.hasSecretKey,
    this.username,
  });
}

class BackupService {
  BackupService._();

  // ── Build the backup payload ─────────────────────────────────────────────

  /// Builds the backup JSON.
  /// [includeApiKey] controls whether the Last.fm username + API key (and
  /// the whole multi-account list, which embeds per-account keys) are
  /// written to the file. [includeSecretKey] controls whether the API
  /// secret key (and the session key derived from it) are written.
  /// Both default to true so nothing changes for existing callers.
  static Future<String> buildBackupJson({
    bool includeApiKey = true,
    bool includeSecretKey = true,
  }) async {
    final p = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final key in p.getKeys()) {
      if (!key.startsWith('ls_')) continue;
      if (_kBackupExcludeKeys.contains(key)) continue;
      if (!includeApiKey &&
          (key == 'ls_apikey' || key == 'ls_username' || key == 'ls_accounts' || key == 'ls_active_account')) {
        continue;
      }
      if (!includeSecretKey && (key == 'ls_secret_key' || key == 'ls_session_key')) {
        continue;
      }
      final v = p.get(key);
      if (v != null) map[key] = v;
    }

    String activeUsername = '';
    String activeApiKey   = '';

    if (includeApiKey) {
      final accountsRaw = map['ls_accounts'];
      if (accountsRaw != null) {
        try {
          final accounts  = jsonDecode(accountsRaw.toString()) as List;
          final activeIdx = (map['ls_active_account'] as num?)?.toInt() ?? 0;
          if (accounts.isNotEmpty) {
            final acc      = accounts[activeIdx.clamp(0, accounts.length - 1)] as Map<String, dynamic>;
            activeUsername = (acc['username'] ?? '').toString();
            activeApiKey   = (acc['apiKey']   ?? '').toString();
          }
        } catch (_) {}
      }
      if (activeUsername.isEmpty) activeUsername = (map['ls_username'] ?? '').toString();
      if (activeApiKey.isEmpty)   activeApiKey   = (map['ls_apikey']   ?? '').toString();
    }

    final now = DateTime.now();
    return jsonEncode({
      'app':         'LastStats',
      'version':     '3', // v3 = dynamic key discovery (all ls_* keys)
      'exported_at': now.toIso8601String(),
      'username':    activeUsername,
      'api_key':     activeApiKey,
      'prefs':       map,
    });
  }

  static String defaultFileName() {
    final now = DateTime.now();
    final d = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'laststats_backup_$d.json';
  }

  // ── Export: real "Save As" dialog ────────────────────────────────────────

  /// Returns true if a file was actually written, false if cancelled/failed.
  static Future<bool> exportToFile({
    bool includeApiKey = true,
    bool includeSecretKey = true,
  }) async {
    try {
      final payload = await buildBackupJson(
        includeApiKey: includeApiKey,
        includeSecretKey: includeSecretKey,
      );
      final bytes   = Uint8List.fromList(utf8.encode(payload));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save LastStats backup',
        fileName:    defaultFileName(),
        type:        FileType.custom,
        allowedExtensions: ['json'],
        bytes:       bytes, // used by file_picker itself on web/some mobile targets
      );
      if (path == null) return false; // user cancelled the dialog

      // On desktop (Windows/macOS/Linux), saveFile() only returns the chosen
      // path — it does NOT write the file. We have to do that ourselves.
      // (On web, the bytes are handled by the browser download and `path`
      // is just a filename, not a real filesystem path, so skip writing.)
      if (!kIsWeb) {
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Import: real file picker ─────────────────────────────────────────────

  /// Opens the native file picker and reads the chosen .json, returning a
  /// [BackupPreview] so the caller can ask the user which sensitive keys
  /// (API key, secret key) to actually restore before applying anything.
  /// Returns null if the user cancelled or the file couldn't be read/parsed.
  static Future<BackupPreview?> pickAndPreviewFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose a LastStats backup file',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.single.bytes;
    if (bytes == null) return null;

    String raw;
    try {
      raw = utf8.decode(bytes);
    } catch (_) {
      return null;
    }

    return previewBackup(raw);
  }

  /// Inspects a raw backup JSON string without applying anything, so the UI
  /// can show "restore API key?" / "restore secret key?" checkboxes.
  static BackupPreview? previewBackup(String raw) {
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    String username = '';
    bool hasApiKey = false;
    bool hasSecretKey = false;

    if (parsed['app'] == 'LastStats') {
      final prefs = parsed['prefs'];
      if (prefs is Map) {
        hasApiKey = (prefs['ls_apikey']     ?? '').toString().isNotEmpty ||
                    (parsed['api_key']      ?? '').toString().isNotEmpty;
        hasSecretKey = (prefs['ls_secret_key'] ?? '').toString().isNotEmpty;
      }
      username = (parsed['username'] ?? '').toString();
    } else {
      // Simple format fallback: {"username":"…","api_key":"…"}
      final k = (parsed['api_key'] ?? parsed['apiKey'] ?? parsed['api-key'] ?? '').toString();
      hasApiKey = k.isNotEmpty;
      username  = (parsed['username'] ?? '').toString();
    }

    return BackupPreview(
      raw: raw,
      hasApiKey: hasApiKey,
      hasSecretKey: hasSecretKey,
      username: username.isEmpty ? null : username,
    );
  }

  /// Kept for backward compatibility — reads + applies a backup file in one
  /// shot, restoring the API key and secret key unconditionally. Prefer
  /// [pickAndPreviewFile] + [applyBackupJson] when the caller wants to let
  /// the user choose what to restore.
  static Future<BackupResult?> importFromFile() async {
    final preview = await pickAndPreviewFile();
    if (preview == null) return null;
    return applyBackupJson(preview.raw);
  }

  // ── Apply a parsed backup ────────────────────────────────────────────────

  /// Applies a raw backup JSON string.
  /// [restoreApiKey] controls whether the Last.fm username + API key (and
  /// the whole multi-account list, which embeds per-account keys) are
  /// restored. [restoreSecretKey] controls whether the API secret key (and
  /// the session key derived from it) are restored. Both default to true
  /// for backward compatibility.
  static Future<BackupResult> applyBackupJson(
    String raw, {
    bool restoreApiKey = true,
    bool restoreSecretKey = true,
  }) async {
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const BackupResult(success: false);
    }

    Map<String, dynamic>? prefsMap;
    String? username;
    String? apiKey;

    if (parsed['app'] == 'LastStats') {
      final prefs = parsed['prefs'];
      if (prefs is! Map) return const BackupResult(success: false);
      prefsMap = Map<String, dynamic>.from(prefs);
      username = (parsed['username'] as String?)?.trim();
      apiKey   = (parsed['api_key']  as String?)?.trim();
    } else {
      // Simple format fallback: {"username":"…","api_key":"…"}
      final u = (parsed['username'] ?? '').toString().trim();
      final k = (parsed['api_key'] ?? parsed['apiKey'] ?? parsed['api-key'] ?? '').toString().trim();
      if (u.isEmpty || k.isEmpty) return const BackupResult(success: false);
      prefsMap = {'ls_username': u, 'ls_apikey': k};
      username = u;
      apiKey   = k;
    }

    // Drop sensitive keys the user chose not to restore.
    final exclude = <String>{};
    if (!restoreApiKey) {
      exclude.addAll(['ls_apikey', 'ls_username', 'ls_accounts', 'ls_active_account']);
      username = null;
      apiKey   = null;
    }
    if (!restoreSecretKey) {
      // The session key is only valid alongside the secret it was derived
      // from — restoring it without the secret would silently break
      // favorites, so both are excluded together.
      exclude.addAll(['ls_secret_key', 'ls_session_key']);
    }
    if (exclude.isNotEmpty) {
      prefsMap.removeWhere((k, _) => exclude.contains(k));
    }

    await _applyPrefs(prefsMap);

    final p = await SharedPreferences.getInstance();
    username = p.getString('ls_username') ?? username;
    apiKey   = p.getString('ls_apikey')   ?? apiKey;

    return BackupResult(success: true, username: username, apiKey: apiKey);
  }

  static Future<void> _applyPrefs(Map<String, dynamic> prefs) async {
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

    // Keep ls_username/ls_apikey in sync with the active multi-account entry.
    final accountsRaw = p.getString('ls_accounts');
    if (accountsRaw != null && accountsRaw.isNotEmpty) {
      try {
        final accounts  = jsonDecode(accountsRaw) as List;
        final activeIdx = p.getInt('ls_active_account') ?? 0;
        if (accounts.isNotEmpty) {
          final acc = accounts[activeIdx.clamp(0, accounts.length - 1)] as Map<String, dynamic>;
          final u = (acc['username'] ?? '').toString();
          final k = (acc['apiKey']   ?? '').toString();
          if (u.isNotEmpty) await p.setString('ls_username', u);
          if (k.isNotEmpty) await p.setString('ls_apikey',   k);
        }
      } catch (_) {}
    }

    // Refresh in-memory notifiers so a running app reflects the restore
    // immediately, without needing a manual restart.
    themeModeNotifier.value             = themeFromString(p.getString('ls_theme'));
    accentNotifier.value                = accentFromString(p.getString('ls_accent'));
    useDynamicColorNotifier.value       = p.getBool('ls_use_dynamic_color')    ?? false;
    useNowPlayingColorNotifier.value    = p.getBool('ls_use_nowplaying_color') ?? false;
    localeNotifier.value                = p.getString('ls_locale')             ?? 'fr';
    themeStyleNotifier.value            = p.getString('ls_theme_style')        ?? 'default';
    nothingAccentNotifier.value         = p.getString('ls_nothing_accent')     ?? 'classic';
    oledModeNotifier.value              = p.getBool('ls_oled_mode')            ?? false;
    musicPlatformNotifier.value         = p.getString('ls_music_platform')     ?? 'lastfm';
    showAllPlatformLinksNotifier.value  = p.getBool('ls_show_all_platform_links') ?? false;
    // Last.fm write-access credentials (only present if they were restored).
    secretKeyNotifier.value             = p.getString('ls_secret_key')  ?? '';
    sessionKeyNotifier.value            = p.getString('ls_session_key') ?? '';
    // Remaining misc toggles.
    hapticFeedbackNotifier.value        = p.getBool('ls_haptic_feedback')      ?? true;
    navLabelNotifier.value              = p.getBool('ls_nav_labels')           ?? true;
    notifNewsEnabledNotifier.value      = p.getBool('ls_notif_news_enabled')   ?? false;
    showNewsBadgeNotifier.value         = p.getBool('ls_show_news_badge')      ?? true;
    showLovedBadgeNotifier.value        = p.getBool('ls_show_loved_badge')     ?? true;
    showFavoritesStatNotifier.value     = p.getBool('ls_show_favorites')       ?? true;
    artworkColorThemeNotifier.value     = p.getBool('ls_artwork_color_theme')  ?? false;
    keepLastArtworkColorNotifier.value  = p.getBool('ls_keep_last_artwork_color') ?? false;
    pcModeNotifier.value                = p.getString('ls_pc_mode')            ?? 'auto';
    final fallbackHex = p.getString('ls_nowplaying_fallback_color');
    if (fallbackHex != null) {
      nowPlayingFallbackColorNotifier.value = accentFromString(fallbackHex);
    }
  }
}