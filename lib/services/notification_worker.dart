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
import 'update_service.dart';
import 'lastfm_service.dart';
import 'all_scrobbles_service.dart';
import 'scrobbles_file_cache.dart';

// ── Task names ───────────────────────────────────────────────────────────────
const _kTaskMilestone     = 'ls_milestone_check';
const _kTaskRecap         = 'ls_recap_check';
const _kTaskUpdate        = 'ls_update_check';
const _kTaskNews          = 'ls_news_check';
const _kTaskScrobbleSync  = 'ls_scrobble_sync_task';

// ── Scrobble background sync prefs ──────────────────────────────────────────
const _kSyncEnabled   = 'ls_scrobble_sync_enabled';
const _kSyncFreqHours = 'ls_scrobble_sync_freq_hours'; // 1, 3, 6, 12, 24

// ── Milestone prefs ──────────────────────────────────────────────────────────
const _kMilestoneEnabled   = 'ls_notif_milestone_enabled';
const _kMilestoneInterval  = 'ls_notif_milestone_interval';
const _kMilestoneLastCount = 'ls_notif_milestone_last_count';

// ── Grand milestone prefs ────────────────────────────────────────────────────
const _kGrandEnabled       = 'ls_notif_grand_enabled';
const _kGrandMilestoneLast = 'ls_notif_grand_last';

const _kGrandThresholds = [
  1000, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000,
];

// ── Daily recap prefs ────────────────────────────────────────────────────────
const _kDailyEnabled = 'ls_notif_daily_enabled';
const _kDailyHour    = 'ls_notif_daily_hour';
const _kDailyMin     = 'ls_notif_daily_min';
const _kDailyLastDay = 'ls_notif_daily_last_day';

// ── Weekly recap prefs ───────────────────────────────────────────────────────
const _kWeeklyEnabled  = 'ls_notif_weekly_enabled';
const _kWeeklyDay      = 'ls_notif_weekly_day';
const _kWeeklyHour     = 'ls_notif_weekly_hour';
const _kWeeklyMin      = 'ls_notif_weekly_min';
const _kWeeklyLastWeek = 'ls_notif_weekly_last_week';

// ── Update prefs ─────────────────────────────────────────────────────────────
// Stores the last version for which we already sent a notification,
// to avoid re-notifying every 6 hours for the same release.
const _kUpdateLastNotified = 'ls_last_notified_update_version';
const _kBetaChannel        = 'ls_beta_channel';
// Stores the latest pending update as a local "news" item so it also shows
// up in the dashboard's news bell, merged with the remote news.json feed.
const _kLocalUpdateNews    = 'ls_local_update_news';

// ── News prefs ───────────────────────────────────────────────────────────────
const _kNotifNewsEnabled  = 'ls_notif_news_enabled';
const _kNewsLastNotified  = 'ls_notif_news_last_id';
const _kNewsUrl = 'https://sanobld.github.io/LastStats/news.json';

// ── Last.fm account prefs ────────────────────────────────────────────────────
const _kUsername = 'ls_username';
const _kApiKey   = 'ls_apikey';

// ══════════════════════════════════════════════════════════════════════════════
//  Top-level callback — MUST be top-level (not inside a class).
// ══════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
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
        case _kTaskUpdate:
          await _runUpdateCheck();
          break;
        case _kTaskNews:
          await _runNewsCheck();
          break;
        case _kTaskScrobbleSync:
          await _runScrobbleSync();
          break;
      }
    } catch (_) {
      // Never throw from the worker — WorkManager would retry and spam
    }
    return true;
  });
}

// ── Update check ─────────────────────────────────────────────────────────────

Future<void> _runUpdateCheck() async {
  final prefs     = await SharedPreferences.getInstance();
  final wantsBeta = prefs.getBool(_kBetaChannel) ?? false;
  final channel   = wantsBeta ? UpdateChannel.beta : UpdateChannel.stable;

  final info = await UpdateService.checkForUpdate(channel: channel);
  if (info == null) return; // up to date or offline

  // Always keep the latest pending update as a local "news" item so it
  // shows up in the dashboard's news bell, even if we don't re-notify.
  final downloadUrl = info.hasApk ? info.apkUrl! : info.releaseUrl;
  final localItem = jsonEncode({
    'id':    'local_update_${info.version}',
    'title': 'LastStats ${info.version} disponible',
    'body':  'Une nouvelle version est prête à être téléchargée.',
    'type':  'update',
    'emoji': '🆕',
    'date':  _shortDate(DateTime.now()),
    'url':   downloadUrl,
  });
  await prefs.setString(_kLocalUpdateNews, localItem);

  // Skip the push notification if we already notified for this exact version
  final lastNotified = prefs.getString(_kUpdateLastNotified) ?? '';
  if (lastNotified == info.version) return;

  await NotificationService.showUpdateAvailable(info.version, downloadUrl);
  await prefs.setString(_kUpdateLastNotified, info.version);
}

// ── News check ────────────────────────────────────────────────────────────
// Fetches news.json and fires a local notification for any item published
// since the last check. Only runs when the user enabled it in the
// notifications settings page.

Future<void> _runNewsCheck() async {
  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool(_kNotifNewsEnabled) ?? false)) return;

  try {
    final res = await http
        .get(Uri.parse(_kNewsUrl))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return;

    final json  = jsonDecode(res.body) as Map;
    final items = (json['items'] as List? ?? []).cast<Map>();
    if (items.isEmpty) return;

    // items are newest-first (publish-news.yml prepends new entries)
    final lastId   = prefs.getString(_kNewsLastNotified) ?? '';
    final newestId = (items.first['id'] ?? '').toString();
    if (newestId.isEmpty || newestId == lastId) return;

    // Collect every item published since the last check.
    final unseen = <Map>[];
    for (final it in items) {
      if ((it['id'] ?? '').toString() == lastId) break;
      unseen.add(it);
    }
    // First run (no lastId yet): just notify the newest one, not the backlog.
    final toNotify = lastId.isEmpty
        ? [items.first]
        : unseen.reversed.take(5).toList(); // oldest unseen first, capped

    for (final it in toNotify) {
      await NotificationService.showNews(
        id:    (it['id']    ?? '').toString(),
        title: (it['title'] ?? '').toString(),
        body:  (it['body']  ?? '').toString(),
        type:  (it['type']  ?? 'info').toString(),
        emoji: (it['emoji'] ?? '').toString(),
        date:  (it['date']  ?? '').toString(),
      );
    }
    await prefs.setString(_kNewsLastNotified, newestId);
  } catch (_) {}
}

String _shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

// ── Scrobble background sync ─────────────────────────────────────────────────
// Runs a full load (first time) or incremental sync (subsequent runs) and
// mirrors AllScrobblesService.progressNotifier into an ongoing progress
// notification so the user sees it happening even with the app closed.

Future<void> _runScrobbleSync() async {
  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool(_kSyncEnabled) ?? false)) return;

  final username = prefs.getString(_kUsername) ?? '';
  final apiKey   = prefs.getString(_kApiKey)   ?? '';
  if (username.isEmpty || apiKey.isEmpty) return;

  if (AllScrobblesService.isRunning) return; // avoid overlapping runs

  await ScrobblesFileCache.init();
  final service = LastFmService(apiKey: apiKey, username: username);

  void onProgress() {
    final p = AllScrobblesService.progressNotifier.value;
    if (!p.isLoading) return;
    final subtitle = p.mode == SyncMode.full && p.currentYear != null
        ? 'Year ${p.currentYear}'
        : '';
    NotificationService.showSyncProgress(
      progress: p.loaded,
      max:      p.total,
      subtitle: subtitle,
    );
  }

  AllScrobblesService.progressNotifier.addListener(onProgress);
  try {
    if (AllScrobblesService.isFirstLoad) {
      await AllScrobblesService.loadAll(service);
    } else {
      await AllScrobblesService.syncNew(service);
    }
    final result = AllScrobblesService.progressNotifier.value;
    await NotificationService.showSyncDone(result.newCount);
  } catch (_) {
    await NotificationService.cancelSyncProgress();
  } finally {
    AllScrobblesService.progressNotifier.removeListener(onProgress);
  }
}

// ── Milestone check ──────────────────────────────────────────────────────────

Future<void> _runMilestoneCheck() async {
  final prefs = await SharedPreferences.getInstance();

  final intervalOn = prefs.getBool(_kMilestoneEnabled) ?? false;
  final grandOn    = prefs.getBool(_kGrandEnabled)     ?? true;

  if (!intervalOn && !grandOn) return;

  final username = prefs.getString(_kUsername) ?? '';
  final apiKey   = prefs.getString(_kApiKey)   ?? '';
  if (username.isEmpty || apiKey.isEmpty) return;

  final count = await _fetchPlaycount(username, apiKey);
  if (count == null) return;

  if (intervalOn) {
    final interval    = prefs.getInt(_kMilestoneInterval) ?? 500;
    final lastCount   = prefs.getInt(_kMilestoneLastCount) ?? 0;
    final lastMultiple = (lastCount ~/ interval) * interval;
    final nowMultiple  = (count     ~/ interval) * interval;
    if (nowMultiple > lastMultiple) {
      await NotificationService.showMilestone(nowMultiple);
    }
  }

  if (grandOn) {
    final lastGrand = prefs.getInt(_kGrandMilestoneLast) ?? 0;
    for (final threshold in _kGrandThresholds.reversed) {
      if (count >= threshold && lastGrand < threshold) {
        await NotificationService.showGrandMilestone(threshold);
        await prefs.setInt(_kGrandMilestoneLast, threshold);
        break;
      }
    }
  }

  await prefs.setInt(_kMilestoneLastCount, count);
}

// ── Recap check ──────────────────────────────────────────────────────────────

Future<void> _runRecapCheck() async {
  final prefs = await SharedPreferences.getInstance();
  final now   = DateTime.now();

  if (prefs.getBool(_kDailyEnabled) ?? false) {
    final targetH = prefs.getInt(_kDailyHour) ?? 21;
    final targetM = prefs.getInt(_kDailyMin)  ?? 0;
    final lastDay = prefs.getInt(_kDailyLastDay) ?? 0;
    final todayId = _dateId(now);
    final diff    = (_timeMinutes(now) - (targetH * 60 + targetM)).abs();

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

  if (prefs.getBool(_kWeeklyEnabled) ?? false) {
    final targetDay = prefs.getInt(_kWeeklyDay)  ?? 1;
    final targetH   = prefs.getInt(_kWeeklyHour) ?? 20;
    final targetM   = prefs.getInt(_kWeeklyMin)  ?? 0;
    final lastWeek  = prefs.getInt(_kWeeklyLastWeek) ?? 0;
    final weekId    = _isoWeekId(now);
    final diff      = (_timeMinutes(now) - (targetH * 60 + targetM)).abs();

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

Future<(int, String)?> _fetchTodayStats(
    String user, String key, DateTime now) async {
  final dayStart = DateTime(now.year, now.month, now.day);
  return _fetchRangeStats(user, key, dayStart, now);
}

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

int _timeMinutes(DateTime d) => d.hour * 60 + d.minute;

int _dateId(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

int _isoWeek(DateTime d) {
  final doy = d.difference(DateTime(d.year, 1, 1)).inDays + 1;
  return ((doy - d.weekday + 10) ~/ 7);
}

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

  static Future<void> scheduleAll() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Milestone task ───────────────────────────────────────────────────
    await Workmanager().cancelByUniqueName(_kTaskMilestone);
    final intervalOn = prefs.getBool(_kMilestoneEnabled) ?? false;
    final grandOn    = prefs.getBool(_kGrandEnabled)     ?? true;

    if (intervalOn || grandOn) {
      await Workmanager().registerPeriodicTask(
        _kTaskMilestone,
        _kTaskMilestone,
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
        frequency:          const Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }

    // ── Update check task ────────────────────────────────────────────────
    // Always registered — runs every 6 hours in the background.
    // Only fires a notification when a new version is found AND not yet notified.
    await Workmanager().cancelByUniqueName(_kTaskUpdate);
    await Workmanager().registerPeriodicTask(
      _kTaskUpdate,
      _kTaskUpdate,
      frequency:          const Duration(hours: 6),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );

    // ── News check task ──────────────────────────────────────────────────
    // Only registered when the user enabled "news notifications" in settings.
    await Workmanager().cancelByUniqueName(_kTaskNews);
    final newsOn = prefs.getBool(_kNotifNewsEnabled) ?? false;
    if (newsOn) {
      await Workmanager().registerPeriodicTask(
        _kTaskNews,
        _kTaskNews,
        frequency:          const Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }

    // ── Scrobble background sync task ────────────────────────────────────
    // Only registered when the user enabled auto-sync in settings.
    // Android enforces a 15-minute minimum periodic interval.
    await Workmanager().cancelByUniqueName(_kTaskScrobbleSync);
    final syncOn = prefs.getBool(_kSyncEnabled) ?? false;
    if (syncOn) {
      final freqH = prefs.getInt(_kSyncFreqHours) ?? 6;
      await Workmanager().registerPeriodicTask(
        _kTaskScrobbleSync,
        _kTaskScrobbleSync,
        frequency: Duration(hours: freqH < 1 ? 1 : freqH),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  static Future<void> resetMilestoneCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMilestoneLastCount);
  }

  static Future<void> resetGrandMilestone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGrandMilestoneLast);
  }
}