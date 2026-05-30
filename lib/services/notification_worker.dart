// lib/services/notification_worker.dart
//
// WorkManager integration.
// Runs in a separate Dart isolate — no Flutter widgets available.
// Only SharedPreferences, http, and notification_service are used here.

import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart'             as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

// ── Task names ───────────────────────────────────────────────────────────────
const _kTaskMilestone = 'ls_milestone_check';
const _kTaskRecap     = 'ls_recap_check';

// ── Milestone prefs ──────────────────────────────────────────────────────────
const _kMilestoneEnabled   = 'ls_notif_milestone_enabled';
const _kMilestoneInterval  = 'ls_notif_milestone_interval'; // int, default 500
const _kMilestoneLastCount = 'ls_notif_milestone_last_count';

// ── Grand milestone prefs ────────────────────────────────────────────────────
// Grand = fixed thresholds (1K, 5K, 10K … 1M), independent of the interval.
const _kGrandEnabled      = 'ls_notif_grand_enabled';
const _kGrandMilestoneLast = 'ls_notif_grand_last'; // last threshold fired

// Fixed grand-milestone thresholds in ascending order
const _kGrandThresholds = [
  1000, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000,
];

// ── Daily recap prefs ────────────────────────────────────────────────────────
const _kDailyEnabled = 'ls_notif_daily_enabled';
const _kDailyHour    = 'ls_notif_daily_hour';    // 0–23, default 21
const _kDailyMin     = 'ls_notif_daily_min';     // 0–59, default 0
const _kDailyLastDay = 'ls_notif_daily_last_day'; // yyyyMMdd, last fired

// ── Weekly recap prefs ───────────────────────────────────────────────────────
const _kWeeklyEnabled  = 'ls_notif_weekly_enabled';
const _kWeeklyDay      = 'ls_notif_weekly_day';    // 1–7 (Mon–Sun)
const _kWeeklyHour     = 'ls_notif_weekly_hour';
const _kWeeklyMin      = 'ls_notif_weekly_min';
const _kWeeklyLastWeek = 'ls_notif_weekly_last_week'; // yyyyWW, last fired

// ── Last.fm account prefs ────────────────────────────────────────────────────
const _kUsername = 'ls_username';
const _kApiKey   = 'ls_apikey';

// ══════════════════════════════════════════════════════════════════════════════
//  Top-level callback — MUST be top-level (not inside a class).
//  The @pragma keeps it alive in AOT-compiled (release) builds.
// ══════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    // Background isolate needs its own binding + notification init
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.init();

    try {
      switch (taskName) {
        case _kTaskMilestone:
          await _runMilestoneCheck();
          break;
        case _kTaskRecap:
          await _runRecapCheck();
          break;
      }
    } catch (_) {
      // Never throw from the worker — WorkManager would retry and spam
    }
    return true;
  });
}

// ── Milestone check ──────────────────────────────────────────────────────────

Future<void> _runMilestoneCheck() async {
  final prefs = await SharedPreferences.getInstance();

  final intervalOn = prefs.getBool(_kMilestoneEnabled) ?? false;
  final grandOn    = prefs.getBool(_kGrandEnabled)     ?? true;

  // Nothing to do if both are disabled
  if (!intervalOn && !grandOn) return;

  final username = prefs.getString(_kUsername) ?? '';
  final apiKey   = prefs.getString(_kApiKey)   ?? '';
  if (username.isEmpty || apiKey.isEmpty) return;

  // Fetch current total scrobble count from Last.fm
  final count = await _fetchPlaycount(username, apiKey);
  if (count == null) return; // offline or API error — skip silently

  // ── Interval milestone ───────────────────────────────────────────────────
  if (intervalOn) {
    final interval      = prefs.getInt(_kMilestoneInterval) ?? 500;
    final lastCount     = prefs.getInt(_kMilestoneLastCount) ?? 0;

    // The highest multiple of interval that was already reached
    final lastMultiple = (lastCount ~/ interval) * interval;
    // The highest multiple of interval reached now
    final nowMultiple  = (count     ~/ interval) * interval;

    if (nowMultiple > lastMultiple) {
      await NotificationService.showMilestone(nowMultiple);
    }
  }

  // ── Grand milestone ──────────────────────────────────────────────────────
  if (grandOn) {
    final lastGrand = prefs.getInt(_kGrandMilestoneLast) ?? 0;

    // Find the highest threshold that was just crossed (search highest first)
    for (final threshold in _kGrandThresholds.reversed) {
      if (count >= threshold && lastGrand < threshold) {
        await NotificationService.showGrandMilestone(threshold);
        await prefs.setInt(_kGrandMilestoneLast, threshold);
        break; // only fire the single highest new threshold
      }
    }
  }

  // Always update the stored count so the next run detects new crossings
  await prefs.setInt(_kMilestoneLastCount, count);
}

// ── Recap check (daily + weekly share the same periodic task) ────────────────

Future<void> _runRecapCheck() async {
  final prefs = await SharedPreferences.getInstance();
  final now   = DateTime.now();

  // ── Daily ────────────────────────────────────────────────────────────────
  if (prefs.getBool(_kDailyEnabled) ?? false) {
    final targetH = prefs.getInt(_kDailyHour) ?? 21;
    final targetM = prefs.getInt(_kDailyMin)  ?? 0;
    final lastDay = prefs.getInt(_kDailyLastDay) ?? 0;
    final todayId = _dateId(now);

    // Fire once per day, within ±30 min of the target time
    final diff = (_timeMinutes(now) - (targetH * 60 + targetM)).abs();

    if (lastDay < todayId && diff <= 30) {
      final username = prefs.getString(_kUsername) ?? '';
      final apiKey   = prefs.getString(_kApiKey)   ?? '';
      if (username.isNotEmpty && apiKey.isNotEmpty) {
        final result = await _fetchTodayStats(username, apiKey, now);
        if (result != null) {
          await NotificationService.showDailyRecap(
            count:     result.$1,
            topArtist: result.$2,
            date:      '${now.day} ${_monthAbbr(now.month)}',
          );
          await prefs.setInt(_kDailyLastDay, todayId);
        }
      }
    }
  }

  // ── Weekly ───────────────────────────────────────────────────────────────
  if (prefs.getBool(_kWeeklyEnabled) ?? false) {
    final targetDay  = prefs.getInt(_kWeeklyDay)  ?? 1; // 1 = Monday
    final targetH    = prefs.getInt(_kWeeklyHour) ?? 20;
    final targetM    = prefs.getInt(_kWeeklyMin)  ?? 0;
    final lastWeek   = prefs.getInt(_kWeeklyLastWeek) ?? 0;
    final weekId     = _isoWeekId(now);

    final diff = (_timeMinutes(now) - (targetH * 60 + targetM)).abs();

    if (now.weekday == targetDay && lastWeek < weekId && diff <= 30) {
      final username = prefs.getString(_kUsername) ?? '';
      final apiKey   = prefs.getString(_kApiKey)   ?? '';
      if (username.isNotEmpty && apiKey.isNotEmpty) {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final result    = await _fetchRangeStats(username, apiKey, weekStart, now);
        if (result != null) {
          await NotificationService.showWeeklyRecap(
            count:     result.$1,
            topArtist: result.$2,
            weekLabel: 'Week ${_isoWeek(now)}',
          );
          await prefs.setInt(_kWeeklyLastWeek, weekId);
        }
      }
    }
  }
}

// ── Last.fm API helpers ──────────────────────────────────────────────────────

const _lfmBase = 'https://ws.audioscrobbler.com/2.0/';

/// Returns the total scrobble count for the user, or null on failure.
Future<int?> _fetchPlaycount(String user, String key) async {
  try {
    final uri = Uri.parse(
        '$_lfmBase?method=user.getinfo&user=$user&api_key=$key&format=json');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final json  = jsonDecode(res.body) as Map;
    final count = json['user']?['playcount']?.toString() ?? '';
    return int.tryParse(count);
  } catch (_) {
    return null;
  }
}

/// Returns (scrobble count today, top artist) or null.
Future<(int, String)?> _fetchTodayStats(
    String user, String key, DateTime now) async {
  final dayStart = DateTime(now.year, now.month, now.day);
  return _fetchRangeStats(user, key, dayStart, now);
}

/// Returns (total scrobbles in range, top artist name) or null.
Future<(int, String)?> _fetchRangeStats(
    String user, String key, DateTime from, DateTime to) async {
  try {
    final fromTs = from.millisecondsSinceEpoch ~/ 1000;
    final toTs   = to.millisecondsSinceEpoch   ~/ 1000;

    final uri = Uri.parse(
        '$_lfmBase?method=user.getrecenttracks'
        '&user=$user&api_key=$key&format=json'
        '&from=$fromTs&to=$toTs&limit=50');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;

    final json   = jsonDecode(res.body) as Map;
    final attr   = json['recenttracks']?['@attr'] as Map? ?? {};
    final total  = int.tryParse(attr['total']?.toString() ?? '0') ?? 0;
    final tracks = json['recenttracks']?['track'] as List? ?? [];

    // Count how many scrobbles per artist to find the top one
    final freq = <String, int>{};
    for (final t in tracks) {
      final name = (t['artist']?['#text'] ?? t['artist']?['name'] ?? '')
          .toString()
          .trim();
      if (name.isNotEmpty) freq[name] = (freq[name] ?? 0) + 1;
    }
    final top = freq.isEmpty
        ? '—'
        : (freq.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return (total, top);
  } catch (_) {
    return null;
  }
}

// ── Date / time helpers ──────────────────────────────────────────────────────

/// Current time as total minutes (for ±30 min window check)
int _timeMinutes(DateTime d) => d.hour * 60 + d.minute;

/// Unique date int: 20240523
int _dateId(DateTime d) =>
    d.year * 10000 + d.month * 100 + d.day;

/// ISO week number (1–53)
int _isoWeek(DateTime d) {
  final doy = d.difference(DateTime(d.year, 1, 1)).inDays + 1;
  return ((doy - d.weekday + 10) ~/ 7);
}

/// Unique year+week int: 202423
int _isoWeekId(DateTime d) => d.year * 100 + _isoWeek(d);

const _months = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _monthAbbr(int m) => _months[m.clamp(1, 12)];

// ══════════════════════════════════════════════════════════════════════════════
//  NotificationWorker — public API called from the UI / main.dart
// ══════════════════════════════════════════════════════════════════════════════

class NotificationWorker {
  NotificationWorker._();

  /// Re-register (or cancel) all WorkManager tasks based on current prefs.
  /// Call after changing any notification setting.
  static Future<void> scheduleAll() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Milestone task ───────────────────────────────────────────────────
    // Register if either interval OR grand milestones are enabled,
    // since both run inside the same periodic task.
    await Workmanager().cancelByUniqueName(_kTaskMilestone);
    final intervalOn = prefs.getBool(_kMilestoneEnabled) ?? false;
    final grandOn    = prefs.getBool(_kGrandEnabled)     ?? true;

    if (intervalOn || grandOn) {
      await Workmanager().registerPeriodicTask(
        _kTaskMilestone,
        _kTaskMilestone,
        // 15 min is the Android minimum; good balance between freshness and battery
        frequency:          const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }

    // ── Recap task ───────────────────────────────────────────────────────
    await Workmanager().cancelByUniqueName(_kTaskRecap);
    final dailyOn  = prefs.getBool(_kDailyEnabled)  ?? false;
    final weeklyOn = prefs.getBool(_kWeeklyEnabled) ?? false;
    if (dailyOn || weeklyOn) {
      await Workmanager().registerPeriodicTask(
        _kTaskRecap,
        _kTaskRecap,
        // Fires every hour; the worker checks the ±30 min time window
        frequency:          const Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }
  }

  /// Cancel all background tasks (e.g. when the user disables everything).
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// Reset the stored interval-milestone count (call when the user
  /// changes the interval so the new threshold is detected correctly).
  static Future<void> resetMilestoneCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMilestoneLastCount);
  }

  /// Reset the stored grand-milestone progress (rarely needed).
  static Future<void> resetGrandMilestone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGrandMilestoneLast);
  }
}