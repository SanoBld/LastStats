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
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import 'scrobbles_file_cache.dart';
import 'all_scrobbles_service.dart';
import 'lastfm_service.dart';

/// Runtime-only / session state that should never be exported: timers,
/// "last notified / last seen" markers, scheduled-task ids and one-off
/// migration flags. Everything else under the 'ls_' prefix (including any
/// future key) is exported automatically — nothing to remember to update.
const _kBackupExcludeKeys = {
  'ls_last_update_check',
  'ls_last_notified_update_version',
  'ls_last_artwork_color',
  'ls_update_check',
  'ls_news_check',
  'ls_recap_check',
  'ls_milestone_check',
  'ls_notif_daily_last_day',
  'ls_notif_weekly_last_week',
  'ls_notif_grand_last',
  'ls_notif_milestone_last_count',
  'ls_notif_news_last_id',
  'ls_story_last_seen_date',
  'ls_auto_backup_last',
  'ls_auto_backup_task',
  'ls_scrobble_sync_task',
  'ls_widget_refresh_task',
  'ls_fav_stat_migrated',
};

/// Keys backing the folders feature (favorites_folders_service.dart).
/// Filtered out when the user unchecks "include folders" on export.
const _kFolderKeys = {
  'ls_fav_folders',
  'ls_folder_items',
  'ls_folder_item_meta',
  'ls_folder_order',
};

/// Appearance / theme keys. Filtered out when the user unchecks "include
/// themes" on export — handy to share just the look of the app with
/// someone else without also sending your Last.fm account or folders.
const _kThemeKeys = {
  'ls_theme',
  'ls_accent',
  'ls_use_dynamic_color',
  'ls_use_nowplaying_color',
  'ls_nowplaying_fallback_color',
  'ls_theme_style',
  'ls_nothing_accent',
  'ls_oled_mode',
  'ls_artwork_color_theme',
  'ls_keep_last_artwork_color',
  'ls_living_artwork',
  'ls_motion_artwork',
  'ls_motion_source',
  'ls_motion_quality',
  'ls_motion_tracks',
  'ls_motion_albums',
  'ls_motion_artists',
  'ls_image_shape',
  'ls_nav_labels',
  'ls_rail_collapsed',
  'ls_pc_mode',
  'ls_widget_tint',
  'ls_use_daynight_accent',
  'ls_accent_dark',
  'ls_daynight_use_hours',
  'ls_daynight_day_start_hour',
  'ls_daynight_night_start_hour',
};

/// Library clean-up options (services/library_merge.dart): link versions of
/// a track/album/artist, split collaborations. Own switch on export.
const _kLibraryKeys = {
  'ls_merge_versions',
  'ls_split_collabs',
};

/// Dashboard layout: header, visible sections, stat cards, discover,
/// start-up tab. Own switch on export.
const _kDashboardKeys = {
  'ls_header_source', 'ls_header_animation', 'ls_header_period',
  'ls_header_blur', 'ls_header_custom_url', 'ls_header_music_anim',
  'ls_header_fallback_enabled', 'ls_header_fallback_type',
  'ls_header_fallback_period', 'ls_header_fallback_url',
  'ls_show_nowplay', 'ls_show_stats', 'ls_show_recent', 'ls_show_discover',
  'ls_show_friends', 'ls_show_favorites', 'ls_dashboard_chart',
  'ls_stat_cards', 'ls_section_order', 'ls_infinite_scroll',
  'ls_discover_smart', 'ls_discover_solo', 'ls_discover_sources',
  'ls_startup_tab',
};

/// Notification preferences and news/loved badges. Own switch on export.
const _kNotificationKeys = {
  'ls_notif_news_enabled', 'ls_notif_sync_enabled',
  'ls_notif_sync_progress_detail',
  'ls_notif_daily_enabled', 'ls_notif_daily_hour', 'ls_notif_daily_min',
  'ls_notif_weekly_enabled', 'ls_notif_weekly_day',
  'ls_notif_weekly_hour', 'ls_notif_weekly_min',
  'ls_notif_milestone_enabled', 'ls_notif_milestone_interval',
  'ls_notif_grand_enabled',
  'ls_show_news_badge', 'ls_show_loved_badge',
};

/// Favourite profiles chosen in the app. Own switch on export.
const _kProfileKeys = {
  'ls_fav_profiles',
  'ls_fav_friends',
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
  // Date the backup file was created (from "exported_at"). Shown to the
  // user before they restore, so they know how old the file is.
  final DateTime? exportedAt;
  // True if this backup file also contains the full scrobble history.
  final bool hasScrobbles;
  const BackupPreview({
    required this.raw,
    required this.hasApiKey,
    required this.hasSecretKey,
    this.username,
    this.exportedAt,
    this.hasScrobbles = false,
  });
}

/// What to do with years of scrobble data that failed validation.
enum ScrobbleConflictMode {
  /// Keep going as before: import everything, broken years included.
  keepAnyway,
  /// Cancel: do not import ANY scrobble, keep whatever is already on device.
  cancelScrobbles,
  /// Skip only the broken years and mark them so the app re-downloads
  /// them from Last.fm online next time it syncs.
  skipAndRefetch,
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
    bool includeFolders = true,
    bool includeThemes = true,
    bool includeLibrary = true,
    bool includeDashboard = true,
    bool includeNotifications = true,
    bool includeProfiles = true,
    // NEW: when true, the full scrobble history (every track ever played,
    // as cached on this device) is embedded in the backup file too.
    bool includeScrobbles = false,
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
      if (!includeFolders && _kFolderKeys.contains(key)) {
        continue;
      }
      if (!includeThemes && _kThemeKeys.contains(key)) {
        continue;
      }
      if (!includeLibrary && _kLibraryKeys.contains(key)) continue;
      if (!includeDashboard && _kDashboardKeys.contains(key)) continue;
      if (!includeNotifications && _kNotificationKeys.contains(key)) continue;
      if (!includeProfiles && _kProfileKeys.contains(key)) continue;
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

    // NEW: raw per-year scrobble blobs, only read from disk if the user
    // actually asked for them (this can be a big amount of data).
    Map<String, String>? scrobbles;
    if (includeScrobbles) {
      // Best-effort: pull the latest scrobbles from Last.fm first, so the
      // backup actually has "everything" and not just what was cached the
      // last time the app happened to sync. Use the account credentials
      // even if includeApiKey/includeSecretKey are off — those flags only
      // control what's WRITTEN to the file, not what we're allowed to use
      // to talk to Last.fm right now.
      // Read credentials straight from SharedPreferences (not from `map`,
      // which may have dropped them if includeApiKey is off) — those flags
      // only control what's WRITTEN to the file, not what we're allowed to
      // use to talk to Last.fm right now.
      String syncUsername = p.getString('ls_username') ?? '';
      String syncApiKey   = p.getString('ls_apikey')   ?? '';
      final accountsRaw = p.getString('ls_accounts');
      if (accountsRaw != null && accountsRaw.isNotEmpty) {
        try {
          final accounts  = jsonDecode(accountsRaw) as List;
          final activeIdx = p.getInt('ls_active_account') ?? 0;
          if (accounts.isNotEmpty) {
            final acc = accounts[activeIdx.clamp(0, accounts.length - 1)] as Map<String, dynamic>;
            if ((acc['username'] ?? '').toString().isNotEmpty) syncUsername = acc['username'].toString();
            if ((acc['apiKey']   ?? '').toString().isNotEmpty) syncApiKey   = acc['apiKey'].toString();
          }
        } catch (_) {}
      }
      if (syncUsername.isNotEmpty && syncApiKey.isNotEmpty) {
        try {
          final service = LastFmService(
            apiKey:   syncApiKey,
            username: syncUsername,
          );
          await AllScrobblesService.syncNew(service);
        } catch (_) {
          // Offline or API error: fall back to whatever is already cached.
        }
      }
      scrobbles = await ScrobblesFileCache.exportRawForBackup();
    }

    final now = DateTime.now();
    return jsonEncode({
      'app':         'LastStats',
      'version':     '4', // v4 = added optional full scrobble history
      'exported_at': now.toIso8601String(), // backup date, used on restore
      'username':    activeUsername,
      'api_key':     activeApiKey,
      'prefs':       map,
      'scrobbles':   ?scrobbles,
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
    bool includeFolders = true,
    bool includeThemes = true,
    bool includeLibrary = true,
    bool includeDashboard = true,
    bool includeNotifications = true,
    bool includeProfiles = true,
    bool includeScrobbles = false,
  }) async {
    try {
      final payload = await buildBackupJson(
        includeApiKey: includeApiKey,
        includeSecretKey: includeSecretKey,
        includeFolders: includeFolders,
        includeThemes: includeThemes,
        includeLibrary: includeLibrary,
        includeDashboard: includeDashboard,
        includeNotifications: includeNotifications,
        includeProfiles: includeProfiles,
        includeScrobbles: includeScrobbles,
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

      // BUG FIX: writing the file ourselves only makes sense on desktop.
      // On Android/iOS, file_picker already saves the bytes itself (the
      // returned "path" there is often a content:// URI, not a real
      // filesystem path), so calling File(path).writeAsBytes() on mobile
      // throws — the file was actually saved fine, but we returned false
      // and showed "couldn't save" by mistake. Only do the manual write
      // on Windows/macOS/Linux, where file_picker does NOT write for us.
      final isDesktop = !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
      if (isDesktop) {
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
    bool hasScrobbles = false;
    DateTime? exportedAt;

    if (parsed['app'] == 'LastStats') {
      final prefs = parsed['prefs'];
      if (prefs is Map) {
        hasApiKey = (prefs['ls_apikey']     ?? '').toString().isNotEmpty ||
                    (parsed['api_key']      ?? '').toString().isNotEmpty;
        hasSecretKey = (prefs['ls_secret_key'] ?? '').toString().isNotEmpty;
      }
      username = (parsed['username'] ?? '').toString();
      hasScrobbles = parsed['scrobbles'] is Map && (parsed['scrobbles'] as Map).isNotEmpty;
      final exportedRaw = (parsed['exported_at'] ?? '').toString();
      exportedAt = DateTime.tryParse(exportedRaw);
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
      exportedAt: exportedAt,
      hasScrobbles: hasScrobbles,
    );
  }

  /// Checks the scrobble data inside a backup file for corruption, WITHOUT
  /// importing anything. Call this before [applyBackupJson] when
  /// [BackupPreview.hasScrobbles] is true, so the UI can ask the user what
  /// to do if some years are broken.
  static ScrobbleImportCheck checkScrobbles(String raw) {
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final scrobbles = parsed['scrobbles'];
      if (scrobbles is! Map) {
        return const ScrobbleImportCheck(validYears: [], brokenYears: []);
      }
      return ScrobblesFileCache.checkRawForImport(
        Map<String, dynamic>.from(scrobbles),
      );
    } catch (_) {
      return const ScrobbleImportCheck(validYears: [], brokenYears: []);
    }
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
  /// [restoreScrobbles] controls whether the embedded scrobble history (if
  /// any) is imported at all. [scrobbleMode] only matters when the backup
  /// has broken/corrupted years (see [checkScrobbles]) — it tells us what
  /// the user chose to do about it.
  static Future<BackupResult> applyBackupJson(
    String raw, {
    bool restoreApiKey = true,
    bool restoreSecretKey = true,
    bool restoreScrobbles = false,
    ScrobbleConflictMode scrobbleMode = ScrobbleConflictMode.keepAnyway,
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

    // ── Scrobbles (optional, can be big) ─────────────────────────────────
    // "cancelScrobbles" means: user said no, don't touch scrobbles at all.
    final scrobblesRaw = parsed['scrobbles'];
    if (restoreScrobbles &&
        scrobbleMode != ScrobbleConflictMode.cancelScrobbles &&
        scrobblesRaw is Map) {
      // keepAnyway -> import broken years as-is (best effort).
      // skipAndRefetch -> drop broken years, they'll be re-downloaded from
      // Last.fm the next time the app syncs (online), like a normal user
      // who never had a backup for that year.
      final importMode = scrobbleMode == ScrobbleConflictMode.skipAndRefetch
          ? 'refetch'
          : 'keep';
      await ScrobblesFileCache.importRawFromBackup(
        Map<String, dynamic>.from(scrobblesRaw),
        mode: importMode,
      );
    }

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
      if (v is bool) {
        await p.setBool(e.key, v);
      } else if (v is int) {
        await p.setInt(e.key, v);
      } else if (v is double) {
        await p.setDouble(e.key, v);
      } else if (v is String) {
        await p.setString(e.key, v);
      } else if (v is List) {
        await p.setStringList(e.key, List<String>.from(v));
      }
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
    // Day/night accent colors — these were being written to disk on
    // restore but never pushed into the live notifiers, so a backup
    // restored on a fresh device (or mid-session) silently ignored this
    // whole feature until the app was manually restarted. Fixed here.
    useDayNightAccentNotifier.value     = p.getBool('ls_use_daynight_accent')  ?? false;
    accentDarkNotifier.value            = p.getString('ls_accent_dark') != null
        ? accentFromString(p.getString('ls_accent_dark'))
        : accentNotifier.value;
    dayNightUseHoursNotifier.value      = p.getBool('ls_daynight_use_hours')      ?? false;
    dayStartHourNotifier.value          = p.getInt('ls_daynight_day_start_hour')   ?? 7;
    nightStartHourNotifier.value        = p.getInt('ls_daynight_night_start_hour') ?? 20;
    musicPlatformNotifier.value         = (p.getBool('ls_show_all_platform_links') ?? false)
        ? 'all' : (p.getString('ls_music_platform') ?? '');
    // Last.fm write-access credentials (only present if they were restored).
    secretKeyNotifier.value             = p.getString('ls_secret_key')  ?? '';
    sessionKeyNotifier.value            = p.getString('ls_session_key') ?? '';
    // Remaining misc toggles.
    hapticFeedbackNotifier.value        = p.getBool('ls_haptic_feedback')      ?? true;
    navLabelNotifier.value              = p.getBool('ls_nav_labels')           ?? true;
    livingArtworkNotifier.value         = p.getBool('ls_living_artwork')       ?? true;
    motionArtworkNotifier.value         = p.getBool('ls_motion_artwork')       ?? true;
    imageShapeNotifier.value            = p.getString('ls_image_shape')        ?? 'mix';
    achievementsEnabledNotifier.value   = p.getBool('ls_achievements_enabled') ?? true;
    ecoModeManualNotifier.value         = p.getBool('ls_eco_mode_manual')      ?? false;
    ecoModeAutoNotifier.value           = p.getBool('ls_eco_mode_auto')        ?? false;
    ecoModeThresholdNotifier.value      = p.getInt('ls_eco_mode_threshold')    ?? 20;
    ecoModeSystemNotifier.value         = p.getBool('ls_eco_mode_system')      ?? false;
    displayNameNotifier.value           = p.getString('ls_display_name')       ?? displayNameNotifier.value;
    mergeVersionsNotifier.value         = p.getBool('ls_merge_versions')       ?? false;
    splitCollabsNotifier.value          = p.getBool('ls_split_collabs')        ?? false;
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