// lib/services/auto_backup_service.dart
// ══════════════════════════════════════════════════════════════════════════
//  AutoBackupService — periodic, silent backup writing to a folder the
//  user picked once (Settings > Backup > Automatic backup).
//
//  HOW IT RUNS: there is no reliable cross-platform "wake up my app and run
//  code even when it's fully closed" API that works the same on Windows,
//  macOS, Linux, Android AND iOS. Instead, this does a lightweight check
//  every time the app is launched (see main.dart): "has enough time passed
//  since the last auto-backup?" — if yes, it silently writes one, with no
//  dialog, no user interaction. This is simple, fully cross-platform, and
//  good enough for "back up every day/week/month/year" — it just means the
//  backup actually happens the next time the app is opened after the due
//  date, not at the exact instant it becomes due.
//
//  On Android specifically, this is ALSO called from the existing
//  WorkManager background task (see notification_worker.dart) so it can
//  run periodically even without opening the app.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_service.dart';

class AutoBackupService {
  AutoBackupService._();

  // ── Prefs keys ────────────────────────────────────────────────────────
  static const kEnabled           = 'ls_auto_backup_enabled';
  static const kFreq              = 'ls_auto_backup_freq'; // daily|weekly|monthly|yearly
  static const kLast              = 'ls_auto_backup_last'; // ms since epoch
  static const kDir               = 'ls_auto_backup_dir';  // chosen folder, or '' = app default
  static const kIncludeScrobbles  = 'ls_auto_backup_include_scrobbles';
  static const kKeepCount         = 5; // how many old auto-backups to keep

  /// How long to wait between two automatic backups.
  static DateTime _nextDue(DateTime last, String freq) {
    switch (freq) {
      case 'daily':
        return last.add(const Duration(days: 1));
      case 'monthly':
        // DateTime clamps day overflow itself (e.g. Jan 31 + 1 month
        // rolls into March 2/3, close enough for a reminder date).
        return DateTime(last.year, last.month + 1, last.day, last.hour, last.minute);
      case 'yearly':
        return DateTime(last.year + 1, last.month, last.day, last.hour, last.minute);
      case 'weekly':
      default:
        return last.add(const Duration(days: 7));
    }
  }

  /// Human-readable "next backup" date, for the Settings UI.
  static Future<DateTime?> getNextDueDate() async {
    final p = await SharedPreferences.getInstance();
    if (!(p.getBool(kEnabled) ?? false)) return null;
    final freq   = p.getString(kFreq) ?? 'weekly';
    final lastMs = p.getInt(kLast);
    final last   = lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : DateTime.now();
    return _nextDue(last, freq);
  }

  /// Folder currently used for auto-backups (chosen one, or the app's own
  /// documents folder if the user never picked one).
  static Future<String> getEffectiveDir() async {
    final p = await SharedPreferences.getInstance();
    final chosen = p.getString(kDir);
    if (chosen != null && chosen.isNotEmpty) return chosen;
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Called once on every app startup (see main.dart). Silently does
  /// nothing unless auto-backup is on AND actually due. Never throws.
  static Future<void> checkAndRunIfDue() async {
    if (kIsWeb) return; // no real filesystem to silently write to on web
    try {
      final p = await SharedPreferences.getInstance();
      if (!(p.getBool(kEnabled) ?? false)) return;

      final freq   = p.getString(kFreq) ?? 'weekly';
      final lastMs = p.getInt(kLast);
      final now    = DateTime.now();

      if (lastMs != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
        if (now.isBefore(_nextDue(last, freq))) return; // not due yet
      }

      // No point backing up an empty/unconfigured app.
      final username = p.getString('ls_username') ?? '';
      final apiKey   = p.getString('ls_apikey')    ?? '';
      if (username.isEmpty || apiKey.isEmpty) return;

      final includeScrobbles = p.getBool(kIncludeScrobbles) ?? false;
      final payload = await BackupService.buildBackupJson(
        includeApiKey:     true,
        includeSecretKey:  true,
        includeFolders:    true,
        includeThemes:     true,
        includeScrobbles:  includeScrobbles,
      );

      Directory dir;
      final chosenPath = p.getString(kDir);
      if (chosenPath != null && chosenPath.isNotEmpty) {
        dir = Directory(chosenPath);
        if (!await dir.exists()) {
          // Chosen folder gone (USB drive unplugged, SD card removed…) —
          // fall back instead of failing silently forever.
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final ts   = now.millisecondsSinceEpoch;
      final file = File('${dir.path}${Platform.pathSeparator}laststats_autobackup_$ts.json');
      await file.writeAsBytes(utf8.encode(payload), flush: true);

      await p.setInt(kLast, ts);
      await _pruneOldBackups(dir);
    } catch (_) {
      // Never let a silent background backup crash the app.
    }
  }

  /// Deletes old auto-backups, keeping only the [kKeepCount] most recent
  /// ones — otherwise this would quietly fill up the disk after months.
  static Future<void> _pruneOldBackups(Directory dir) async {
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('laststats_autobackup_'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // newest name (biggest ts) first
      for (final f in files.skip(kKeepCount)) {
        try {
          await f.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }
}
