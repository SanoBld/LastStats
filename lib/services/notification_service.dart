// lib/services/notification_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/notification_detail_page.dart';

const _kLastFmRed = Color(0xFFD51007);

// Global navigator key — lets us push a screen (the notification detail page)
// from outside the widget tree, e.g. when a notification is tapped while the
// app is running in the background. main.dart wires this into MaterialApp.
final navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Channel IDs ──────────────────────────────────────────────────────────
  static const _chMilestoneId   = 'ls_milestone';
  static const _chMilestoneName = 'Scrobble milestones';
  static const _chGrandId       = 'ls_grand_milestone';
  static const _chGrandName     = 'Grand milestones';
  static const _chRecapId       = 'ls_recap';
  static const _chRecapName     = 'Listening recaps';
  static const _chUpdateId      = 'ls_update';
  static const _chUpdateName    = 'App updates';
  static const _chNewsId        = 'ls_news';
  static const _chNewsName      = 'News & announcements';
  static const _chSyncId        = 'ls_scrobble_sync';
  static const _chSyncName      = 'Scrobble sync';

  // ── Notification IDs ─────────────────────────────────────────────────────
  static const _idMilestone   = 1;
  static const _idDailyRecap  = 2;
  static const _idWeeklyRecap = 3;
  static const _idGrand       = 4;
  static const _idUpdate      = 5;
  static const _idSync        = 6;
  static const _idTest        = 99;

  // News notifications use a stable id derived from the item's own id so
  // re-showing the same item (shouldn't happen) doesn't duplicate it.
  static int _idNews(String newsId) => 1000 + (newsId.hashCode & 0x7FFFFFF);

  // ── Init ─────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      // Tap handler when app is in foreground or background.
      // Opens the in-app detail page so the user sees the full notification
      // (title + body, larger) and can follow a link if there is one.
      onDidReceiveNotificationResponse: (details) async {
        await _handleTap(details.payload);
      },
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chMilestoneId, _chMilestoneName,
        description: 'Notifies when you hit a scrobble milestone',
        importance:  Importance.defaultImportance,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chGrandId, _chGrandName,
        description: 'Special alerts for big milestones (1K, 10K, 100K, 1M…)',
        importance:  Importance.high,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chRecapId, _chRecapName,
        description: 'Daily and weekly listening summaries',
        importance:  Importance.low,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chUpdateId, _chUpdateName,
        description: 'Notifies when a new version of LastStats is available',
        importance:  Importance.high,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chNewsId, _chNewsName,
        description: 'New features, fixes and announcements about LastStats',
        importance:  Importance.defaultImportance,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chSyncId, _chSyncName,
        description: 'Progress while syncing your full scrobble history',
        importance:  Importance.low,
      ),
    );
  }

  // ── Permissions ──────────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final a = await android?.requestNotificationsPermission() ?? true;
    final i = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    return a && i;
  }

  static Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  // ── Tap handling ─────────────────────────────────────────────────────────

  // Pushes the detail page using the global navigatorKey. Safe to call even
  // if there's no navigator ready yet (e.g. super-early background tap) —
  // it simply does nothing in that case.
  static Future<void> _handleTap(String? payload) async {
    final data = decodePayload(payload);
    if (data == null) return;
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
        'title': '🆕 Update available',
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
  }) =>
      jsonEncode({
        'type':  type,
        'title': title,
        'body':  body,
        if (url      != null && url.isNotEmpty)      'url':      url,
        if (date     != null && date.isNotEmpty)     'date':     date,
        if (newsType != null && newsType.isNotEmpty) 'newsType': newsType,
        if (emoji    != null && emoji.isNotEmpty)    'emoji':    emoji,
      });

  // ── Show helpers ─────────────────────────────────────────────────────────

  static Future<void> showMilestone(int count) {
    final title = '🎵 Milestone: ${_fmt(count)} scrobbles';
    final body  = 'You just hit ${_fmt(count)} scrobbles on Last.fm 🎶';
    return _plugin.show(
      _idMilestone,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chMilestoneId, _chMilestoneName,
          icon:    '@mipmap/ic_launcher',
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
          icon:       '@mipmap/ic_launcher',
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
    final title = '📊 Daily recap · $date';
    final body  = '${_fmt(count)} scrobbles · Top: $topArtist';
    return _plugin.show(
      _idDailyRecap,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chRecapId, _chRecapName,
          icon:    '@mipmap/ic_launcher',
          color:   _kLastFmRed,
          subText: 'LastStats',
          styleInformation: InboxStyleInformation(
            ['${_fmt(count)} scrobbles today', 'Top artist: $topArtist'],
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
    final title = '📅 Weekly recap · $weekLabel';
    final body  = '${_fmt(count)} scrobbles · Top: $topArtist';
    return _plugin.show(
      _idWeeklyRecap,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chRecapId, _chRecapName,
          icon:    '@mipmap/ic_launcher',
          color:   _kLastFmRed,
          subText: 'LastStats',
          styleInformation: InboxStyleInformation(
            [
              '${_fmt(count)} scrobbles this week',
              'Top artist: $topArtist',
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
    const title = '🆕 Update available';
    final body  = 'LastStats $version is ready — tap to view.';
    return _plugin.show(
      _idUpdate,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chUpdateId, _chUpdateName,
          icon:       '@mipmap/ic_launcher',
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
    final fullTitle = emoji.isNotEmpty ? '$emoji $title' : title;
    return _plugin.show(
      _idNews(id),
      fullTitle,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chNewsId, _chNewsName,
          icon:    '@mipmap/ic_launcher',
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
        date: date, newsType: type, emoji: emoji,
      ),
    );
  }

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
  }) {
    final indeterminate = max <= 0;
    const title = '🔄 Syncing scrobbles…';
    return _plugin.show(
      _idSync,
      title,
      indeterminate ? subtitle : '$progress / $max  ·  $subtitle',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chSyncId, _chSyncName,
          icon:           '@mipmap/ic_launcher',
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
  static Future<void> showSyncDone(int newCount) {
    if (newCount <= 0) return cancelSyncProgress();
    const title = '✅ Scrobbles synced';
    final body  = '$newCount new scrobble(s) added.';
    return _plugin.show(
      _idSync,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chSyncId, _chSyncName,
          icon:    '@mipmap/ic_launcher',
          color:   _kLastFmRed,
          subText: 'LastStats',
          autoCancel: true,
          ongoing:    false,
        ),
      ),
      payload: _payload(type: 'sync', title: title, body: body),
    );
  }

  static Future<void> showTest() => _plugin.show(
        _idTest,
        '🔔 Test notification',
        'LastStats notifications are working!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _chMilestoneId, _chMilestoneName,
            icon:    '@mipmap/ic_launcher',
            color:   _kLastFmRed,
            subText: 'LastStats',
          ),
        ),
        payload: _payload(
          type:  'test',
          title: '🔔 Test notification',
          body:  'LastStats notifications are working!',
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
    if (count >= 1000000) return '${count ~/ 1000000}M scrobbles!';
    if (count >= 1000)    return '${count ~/ 1000}K scrobbles!';
    return '${_fmt(count)} scrobbles!';
  }

  static String _grandBody(int count) {
    switch (count) {
      case 1000000: return "One million scrobbles. That's legendary. 🎸";
      case 500000:  return 'Half a million scrobbles. You never stop. 🎧';
      case 250000:  return '250,000 scrobbles — the music never ends. 🎶';
      case 100000:  return "100,000 scrobbles! You're a true music addict. 🔥";
      case 50000:   return '50,000 scrobbles. Seriously impressive. 🎵';
      case 25000:   return '25,000 scrobbles and still going strong!';
      case 10000:   return '10,000 scrobbles — you hit five figures! 🎉';
      case 5000:    return '5,000 scrobbles and counting!';
      case 1000:    return 'Your first 1,000 scrobbles. The journey begins. 🎵';
      default:      return 'You just hit ${_grandTitle(count)} on Last.fm!';
    }
  }
}