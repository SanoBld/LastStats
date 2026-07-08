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
import 'dart:typed_data';
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

class BackupService {
  BackupService._();

  // ── Build the backup payload ─────────────────────────────────────────────

  static Future<String> buildBackupJson() async {
    final p = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final key in p.getKeys()) {
      if (!key.startsWith('ls_')) continue;
      if (_kBackupExcludeKeys.contains(key)) continue;
      final v = p.get(key);
      if (v != null) map[key] = v;
    }

    String activeUsername = '';
    String activeApiKey   = '';

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
  static Future<bool> exportToFile() async {
    try {
      final payload = await buildBackupJson();
      final bytes   = Uint8List.fromList(utf8.encode(payload));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save LastStats backup',
        fileName:    defaultFileName(),
        type:        FileType.custom,
        allowedExtensions: ['json'],
        bytes:       bytes, // required on mobile/web; ignored (but harmless) on desktop
      );
      return path != null;
    } catch (_) {
      return false;
    }
  }

  // ── Import: real file picker ─────────────────────────────────────────────

  /// Opens the native file picker, reads + parses the chosen .json, applies
  /// it, and returns the result. Returns null if the user cancelled.
  static Future<BackupResult?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose a LastStats backup file',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return const BackupResult(success: false);

    String raw;
    try {
      raw = utf8.decode(bytes);
    } catch (_) {
      return const BackupResult(success: false);
    }

    return applyBackupJson(raw);
  }

  // ── Apply a parsed backup ────────────────────────────────────────────────

  static Future<BackupResult> applyBackupJson(String raw) async {
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
  }
}
