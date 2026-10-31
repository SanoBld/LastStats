// lib/services/notification_service.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/notification_detail_page.dart';
import '../l10n/extra_strings.dart' show tx;
import '../l10n/l10n.dart';
import '../widgets/update_install_sheet.dart' show openUpdateUrl;
import 'update_installer.dart';

const _kLastFmRed = Color(0xFFD51007);

// Global navigator key — lets us push a screen (the notification detail page)
// from outside the widget tree, e.g. when a notification is tapped while the
// app is running in the background. main.dart wires this into MaterialApp.
final navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _kLargeIcon = DrawableResourceAndroidBitmap('ic_notif_large');

  // ── Channel IDs ──────────────────────────────────────────────────────────
  static const _chMilestoneId   = 'ls_milestone';
  static String get _chMilestoneName => L.onboardMilestonesSection;
  static const _chGrandId       = 'ls_grand_milestone';
  static String get _chGrandName => L.onboardGrandMilestonesTitle;
  static const _chRecapId       = 'ls_recap';
  static String get _chRecapName => L.notifRecapsSection;
  static const _chUpdateId      = 'ls_update';
  static String get _chUpdateName => L.settingsUpdates;
  static const _chNewsId        = 'ls_news';
  static String get _chNewsName => L.notifNewsSection;
  static const _chDlId          = 'ls_download';
  static String get _chDlName => tx('ntf_dl_section');
  static const _idDownload      = 20;
  static bool _dlServiceOn = false;

  static const _chSyncId        = 'ls_scrobble_sync';
  static String get _chSyncName => L.notifSyncSection;

  // ── Notification IDs ─────────────────────────────────────────────────────
  static const _idMilestone   = 1;
  static const _idDailyRecap  = 2;
  static const _idWeeklyRecap = 3;
  static const _idGrand       = 4;
  static const _idUpdate      = 5;
  static const _idSync        = 6;
  static const _idYearRecap   = 7;
  static const _idTest        = 99;

  // News notifications use a stable id derived from the item's own id so
  // re-showing the same item (shouldn't happen) doesn't duplicate it.
  static int _idNews(String newsId) => 1000 + (newsId.hashCode & 0x7FFFFFF);

  // ── Init ─────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    const android = AndroidInitializationSettings('ic_stat_laststats');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    // Windows requires a fixed GUID (must not change between releases).
    const windows = WindowsInitializationSettings(
      appName:        'LastStats',
      appUserModelId: 'Com.SanoBld.LastStats',
      guid:           '5c3a1e2a-6b1a-4e9b-9b3b-2f7c1a9d4e10',
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios, windows: windows),
      // Tap handler when app is in foreground or background.
      // Opens the in-app detail page so the user sees the full notification
      // (title + body, larger) and can follow a link if there is one.
      onDidReceiveNotificationResponse: (details) async {
        if (details.notificationResponseType == NotificationResponseType.selectedNotificationAction) {
          await handleAction(details);
          return;
        }
        await _handleTap(details.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _chMilestoneId, _chMilestoneName,
        description: tx('nch_milestone_d'),
        importance:  Importance.defaultImportance,
      ),
    );

    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _chGrandId, _chGrandName,
        description: tx('nch_grand_d'),
        importance:  Importance.high,
      ),
    );

    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _chRecapId, _chRecapName,
        description: tx('nch_recap_d'),
        importance:  Importance.low,
      ),
    );

    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _chUpdateId, _chUpdateName,
        description: tx('nch_update_d'),
        importance:  Importance.high,
      ),
    );

    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _chNewsId, _chNewsName,
        description: tx('nch_news_d'),
        importance:  Importance.defaultImportance,
      ),
    );

    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _chSyncId, _chSyncName,
        description: tx('nch_sync_d'),
        importance:  Importance.low,
      ),
    );
  }

  // ── Permissions ──────────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final a = await android?.requestNotificationsPermission() ?? true;
    final i = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    return a && i;
  }

  static Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  // ── Actions (long-press / expand buttons) ───────────────────────────────

  static List<AndroidNotificationAction> _readActions({bool read = true}) => [
        if (read)
          AndroidNotificationAction('mark_read', tx('ntf_act_read'), cancelNotification: true),
        AndroidNotificationAction('mark_all', tx('ntf_act_read_all'), cancelNotification: true),
      ];

  static List<AndroidNotificationAction> _updateActions() => [
        AndroidNotificationAction('download_update', L.settingsDownload,
            showsUserInterface: true, cancelNotification: true),
        ..._readActions(read: false),
      ];

  static String simplePayload(String type, String path) =>
      jsonEncode({'type': type, 'path': path, 'title': '', 'body': ''});

  /// Runs when the user taps an action button on a notification (also from the
  /// background isolate, see [notificationBackgroundHandler]).
  static Future<void> handleAction(NotificationResponse r) async {
    switch (r.actionId) {
      case 'mark_read':
        await _markSeen(decodePayload(r.payload));
        break;
      case 'mark_all':
        await _markAllRead();
        break;
      case 'install':
        await _handleTap(r.payload);
        break;
      case 'download_update':
        final url = decodePayload(r.payload)?['url']?.toString();
        final ctx = navigatorKey.currentContext;
        if (url != null && url.isNotEmpty && ctx != null) {
          await openUpdateUrl(ctx, url);
        } else {
          await _handleTap(r.payload);
        }
        break;
    }
  }

  static Future<void> _markSeen(Map<String, dynamic>? data) async {
    final id = data?['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final seen = (prefs.getStringList('ls_news_seen') ?? <String>[]).toList();
    if (!seen.contains(id)) {
      seen.add(id);
      await prefs.setStringList('ls_news_seen', seen);
    }
  }

  /// Marks every shown message as read and clears LastStats notifications
  /// (a download still in progress and sync progress are kept).
  static Future<void> _markAllRead([List<String> extraIds = const []]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final seen = (prefs.getStringList('ls_news_seen') ?? <String>[]).toList();
    for (final id in extraIds) {
      if (id.isNotEmpty && !seen.contains(id)) seen.add(id);
    }
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final active = await android?.getActiveNotifications() ?? const <ActiveNotification>[];
      for (final n in active) {
        final nid = n.id;
        if (nid == null) continue;
        if (n.channelId == _chSyncId) continue;
        if (n.channelId == _chDlId && RegExp(r'^\d+ %$').hasMatch(n.body ?? '')) continue;
        final mid = decodePayload(n.payload)?['id']?.toString() ?? '';
        if (mid.isNotEmpty && !seen.contains(mid)) seen.add(mid);
        await _plugin.cancel(nid);
      }
    } catch (_) {}
    // Fallback: in the background isolate the list above can be empty, so
    // also cancel the fixed ids directly.
    for (final id in [_idMilestone, _idDailyRecap, _idWeeklyRecap, _idGrand, _idUpdate, _idYearRecap]) {
      try { await _plugin.cancel(id); } catch (_) {}
    }
    await prefs.setStringList('ls_news_seen', seen);
  }

  /// Public: marks [ids] (all in-app news) as read and clears notifications.
  static Future<void> markAllRead(List<String> ids) => _markAllRead(ids);

  // ── Tap handling ─────────────────────────────────────────────────────────

  // Pushes the detail page using the global navigatorKey. Safe to call even
  // if there's no navigator ready yet (e.g. super-early background tap) —
  // it simply does nothing in that case.
  static Future<void> _handleTap(String? payload) async {
    final data = decodePayload(payload);
    if (data == null) return;
    switch (data['type']) {
      case 'install':   await installApkAt((data['path'] ?? '').toString()); return;
      case 'downloads': await openDownloadsFolder((data['path'] ?? '').toString()); return;
    }
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => NotificationDetailPage(data: data),
    ));
  }

  /// Call this once in main() right after init(). If the app was launched
  /// (cold start) by tapping a notification, returns its decoded payload so
  /// the caller can navigate to the detail page once the app is ready.
  static Future<Map<String, dynamic>?> getLaunchPayloadData() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return decodePayload(details?.notificationResponse?.payload);
    }
    return null;
  }

  /// Decodes a notification payload into a structured map.
  /// Accepts both the new JSON format and the old plain-URL format used by
  /// earlier app versions, so updates from old installs still work.
  static Map<String, dynamic>? decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (!raw.trim().startsWith('{')) {
      // Legacy payload: a bare download URL from showUpdateAvailable().
      return {
        'type':  'update',
        'title': tx('ntf_update_avail'),
        'body':  '',
        'url':   raw,
      };
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static String _payload({
    required String type,
    required String title,
    required String body,
    String? url,
    String? date,
    String? newsType,
    String? emoji,
    String? id,
  }) =>
      jsonEncode({
        'type':  type,
        'title': title,
        'body':  body,
        if (url      != null && url.isNotEmpty)      'url':      url,
        if (date     != null && date.isNotEmpty)     'date':     date,
        if (newsType != null && newsType.isNotEmpty) 'newsType': newsType,
        if (emoji    != null && emoji.isNotEmpty)    'emoji':    emoji,
        if (id       != null && id.isNotEmpty)       'id':       id,
        if (emoji    != null && emoji.isNotEmpty)    'emoji':    emoji,
      });

  // ── Show helpers ─────────────────────────────────────────────────────────

  static Future<void> showMilestone(int count) {
    final title = tx('ntf_milestone_title', {'n': _fmt(count)});
    final body  = tx('ntf_milestone_body', {'n': _fmt(count)});
    return _plugin.show(
      _idMilestone,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chMilestoneId, _chMilestoneName,
          actions: _readActions(read: false),
          icon:    'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:   _kLastFmRed,
          subText: 'LastStats',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText:  'LastStats',
          ),
        ),
      ),
      payload: _payload(type: 'milestone', title: title, body: body),
    );
  }

  static Future<void> showYearRecap(int year) {
    final title = tx('ntf_year_title', {'y': '$year'});
    final body  = tx('ntf_year_body', {'y': '$year'});
    return _plugin.show(
      _idYearRecap,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chRecapId, _chRecapName,
          actions: _readActions(read: false),
          icon:    'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:   _kLastFmRed,
          subText: 'LastStats',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText:  'LastStats',
          ),
        ),
      ),
      payload: _payload(type: 'year', title: title, body: body, emoji: '👀'),
    );
  }

  static Future<void> showGrandMilestone(int count) {
    final title = '🏆 ${_grandTitle(count)}';
    final body  = _grandBody(count);
    return _plugin.show(
      _idGrand,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chGrandId, _chGrandName,
          actions: _readActions(read: false),
          icon:       'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:      _kLastFmRed,
          subText:    'LastStats',
          importance: Importance.high,
          priority:   Priority.high,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText:  'LastStats',
          ),
        ),
      ),
      payload: _payload(type: 'grand', title: title, body: body),
    );
  }

  static Future<void> showDailyRecap({
    required int    count,
    required String topArtist,
    required String date,
  }) {
    final title = tx('ntf_daily_title', {'d': date});
    final body  = tx('ntf_recap_body', {'n': _fmt(count), 'a': topArtist});
    return _plugin.show(
      _idDailyRecap,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chRecapId, _chRecapName,
          actions: _readActions(read: false),
          icon:    'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:   _kLastFmRed,
          subText: 'LastStats',
          styleInformation: InboxStyleInformation(
            [tx('ntf_n_today', {'n': _fmt(count)}), tx('ntf_top_artist', {'a': topArtist})],
            contentTitle: title,
            summaryText:  'LastStats',
          ),
        ),
      ),
      payload: _payload(type: 'daily', title: title, body: body, date: date),
    );
  }

  static Future<void> showWeeklyRecap({
    required int    count,
    required String topArtist,
    required String weekLabel,
  }) {
    final title = tx('ntf_weekly_title', {'w': weekLabel});
    final body  = tx('ntf_recap_body', {'n': _fmt(count), 'a': topArtist});
    return _plugin.show(
      _idWeeklyRecap,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chRecapId, _chRecapName,
          actions: _readActions(read: false),
          icon:    'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:   _kLastFmRed,
          subText: 'LastStats',
          styleInformation: InboxStyleInformation(
            [
              tx('ntf_n_week', {'n': _fmt(count)}),
              tx('ntf_top_artist', {'a': topArtist}),
            ],
            contentTitle: title,
            summaryText:  'LastStats',
          ),
        ),
      ),
      payload: _payload(type: 'weekly', title: title, body: body, date: weekLabel),
    );
  }

  /// Fires a high-importance notification when a new version is available.
  /// Tapping it opens the in-app detail page with an "Open" button that
  /// launches [downloadUrl] — it's no longer launched automatically.
  static Future<void> showUpdateAvailable(String version, String downloadUrl) {
    final title = tx('ntf_update_avail');
    final body  = tx('ntf_update_ready', {'v': version});
    return _plugin.show(
      _idUpdate,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chUpdateId, _chUpdateName,
          actions: _updateActions(),
          icon:       'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:      _kLastFmRed,
          subText:    'LastStats',
          importance: Importance.high,
          priority:   Priority.high,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText:  'LastStats',
          ),
        ),
      ),
      payload: _payload(
        type: 'update', title: title, body: body, url: downloadUrl,
        id: 'update_v$version',
      ),
    );
  }

  /// Fires a notification for a new in-app "actualité" (news) item.
  /// [type] mirrors the dashboard's news types: feature, fix, update, alert, info.
  /// Colors match the in-app news sheet so the experience is consistent.
  static Future<void> showNews({
    required String id,
    required String title,
    required String body,
    required String type,
    String emoji = '',
    String date  = '',
  }) {
    final color    = _newsColor(type);
    final em        = emoji.isNotEmpty ? emoji : _newsEmoji(type);
    final fullTitle = '$em $title';
    return _plugin.show(
      _idNews(id),
      fullTitle,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chNewsId, _chNewsName,
          actions: _readActions(read: true),
          icon:    'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:   color,
          subText: 'LastStats',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: fullTitle,
            summaryText:  'LastStats',
          ),
        ),
      ),
      payload: _payload(
        type: 'news', title: title, body: body,
        date: date, newsType: type, emoji: em, id: id,
      ),
    );
  }

  static String _newsEmoji(String type) => switch (type) {
    'feature' => '✨',
    'fix'     => '🛠️',
    'update'  => '⬆️',
    'alert'   => '⚠️',
    _         => 'ℹ️',
  };

  static Color _newsColor(String type) => switch (type) {
    'feature' => const Color(0xFF7C3AED),
    'fix'     => const Color(0xFFD97706),
    'update'  => const Color(0xFF059669),
    'alert'   => const Color(0xFFDC2626),
    _         => const Color(0xFF1D4ED8),
  };

  /// Shows/updates a low-priority ongoing progress notification while a full
  /// scrobble sync runs in the background. Pass [max] = 0 for an
  /// indeterminate bar (e.g. before the total is known yet).
  static Future<void> showSyncProgress({
    required int progress,
    required int max,
    String subtitle = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('ls_notif_sync_enabled') ?? true)) return;
    final detail = prefs.getBool('ls_notif_sync_progress_detail') ?? true;

    final indeterminate = max <= 0 || !detail;
    final title = tx('ntf_sync_title');
    return _plugin.show(
      _idSync,
      title,
      indeterminate ? subtitle : '$progress / $max  ·  $subtitle',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chSyncId, _chSyncName,
          icon:           'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:          _kLastFmRed,
          subText:        'LastStats',
          importance:     Importance.low,
          priority:       Priority.low,
          onlyAlertOnce:  true,
          ongoing:        true,
          autoCancel:     false,
          showProgress:   true,
          maxProgress:    indeterminate ? 0 : max,
          progress:       indeterminate ? 0 : progress,
          indeterminate:  indeterminate,
        ),
      ),
    );
  }

  /// Dismisses the progress notification once the sync finishes or fails.
  static Future<void> cancelSyncProgress() => _plugin.cancel(_idSync);

  /// Optional short confirmation once a full sync finishes with new data.
  static Future<void> showSyncDone(int newCount) async {
    if (newCount <= 0) return cancelSyncProgress();
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('ls_notif_sync_enabled') ?? true)) {
      return cancelSyncProgress();
    }
    final title = tx('ntf_sync_done');
    final body  = tx('ntf_sync_new', {'n': '$newCount'});
    return _plugin.show(
      _idSync,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chSyncId, _chSyncName,
          icon:    'ic_stat_laststats',
          largeIcon: _kLargeIcon,
          color:   _kLastFmRed,
          subText: 'LastStats',
          autoCancel: true,
          ongoing:    false,
        ),
      ),
      payload: _payload(type: 'sync', title: title, body: body),
    );
  }

  // ── Downloads (progress bar + foreground service so it runs in background) ─

  static Future<bool> _dlEnabled() async {
    if (kIsWeb) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool('ls_notif_download_enabled') ?? true;
  }

  static AndroidNotificationDetails _dlDetails({double? progress, bool done = false, List<AndroidNotificationAction>? actions}) =>
      AndroidNotificationDetails(
        _chDlId, _chDlName,
        icon:          'ic_stat_laststats',
          largeIcon: _kLargeIcon,
        color:         _kLastFmRed,
        subText:       'LastStats',
        importance:    Importance.low,
        priority:      Priority.low,
        onlyAlertOnce: true,
        ongoing:       !done,
        autoCancel:    done,
        showProgress:  !done,
        maxProgress:   100,
        progress:      ((progress ?? 0) * 100).round(),
        indeterminate: !done && progress == null,
        actions:       actions,
      );

  static Future<void> showDownloadProgress(String title, double? progress) async {
    try {
      if (!await _dlEnabled()) return;
      final body = progress == null ? tx('up_downloading') : '${(progress * 100).round()} %';
      final details = _dlDetails(progress: progress);
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null && !_dlServiceOn) {
        _dlServiceOn = true;
        await android.startForegroundService(
          _idDownload, title, body,
          notificationDetails: details,
          foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeDataSync},
        );
        return;
      }
      await _plugin.show(_idDownload, title, body, NotificationDetails(android: details));
    } catch (_) {}
  }

  static Future<void> _stopDownloadService() async {
    if (!_dlServiceOn) return;
    _dlServiceOn = false;
    try {
      await _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.stopForegroundService();
    } catch (_) {}
  }

  static Future<void> cancelDownload() async {
    try {
      await _stopDownloadService();
      await _plugin.cancel(_idDownload);
    } catch (_) {}
  }

  static Future<void> showDownloadDone(String title, String body,
      {String? payload, bool install = false}) async {
    try {
      await _stopDownloadService();
      if (!await _dlEnabled()) { await _plugin.cancel(_idDownload); return; }
      final actions = [
        if (install)
          AndroidNotificationAction('install', tx('ntf_act_install'),
              showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('mark_all', tx('ntf_act_read_all'), cancelNotification: true),
      ];
      await _plugin.show(_idDownload, title, body,
          NotificationDetails(android: _dlDetails(done: true, actions: actions)),
          payload: payload);
    } catch (_) {}
  }

  static Future<void> showTest() async {
    if (kIsWeb) return;
    await _showTest();
  }

  static Future<void> _showTest() => _plugin.show(
        _idTest,
        tx('ntf_test_title'),
        tx('ntf_test_body'),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _chMilestoneId, _chMilestoneName,
          actions: _readActions(read: false),
            icon:    'ic_stat_laststats',
          largeIcon: _kLargeIcon,
            color:   _kLastFmRed,
            subText: 'LastStats',
          ),
        ),
        payload: _payload(
          type:  'test',
          title: tx('ntf_test_title'),
          body:  tx('ntf_test_body'),
        ),
      );

  // ── Formatting helpers ───────────────────────────────────────────────────

  static String _fmt(int n) {
    final s   = n.toString();
    final buf = StringBuffer();
    final rem = s.length % 3;
    if (rem > 0) buf.write(s.substring(0, rem));
    for (var i = rem; i < s.length; i += 3) {
      if (buf.isNotEmpty) buf.write(',');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  static String _grandTitle(int count) {
    if (count >= 1000000) return tx('ntf_grand_t', {'v': '${count ~/ 1000000}M'});
    if (count >= 1000)    return tx('ntf_grand_t', {'v': '${count ~/ 1000}K'});
    return tx('ntf_grand_t', {'v': _fmt(count)});
  }

  static String _grandBody(int count) {
    final n = {'n': _fmt(count)};
    switch (count) {
      case 1000000:
      case 500000:
      case 250000:
      case 100000:
      case 50000:
      case 25000:
      case 10000:
      case 5000:
      case 1000:
        return tx('ntf_grand_$count', n);
      default:
        return tx('ntf_milestone_body', n);
    }
  }
}

@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse r) =>
    NotificationService.handleAction(r);
