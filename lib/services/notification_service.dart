// lib/services/notification_service.dart

import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

const _kLastFmRed = Color(0xFFD51007);

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

  // ── Notification IDs ─────────────────────────────────────────────────────
  static const _idMilestone   = 1;
  static const _idDailyRecap  = 2;
  static const _idWeeklyRecap = 3;
  static const _idGrand       = 4;
  static const _idUpdate      = 5;
  static const _idTest        = 99;

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
      // The payload is the download URL set in showUpdateAvailable().
      onDidReceiveNotificationResponse: (details) async {
        final payload = details.payload;
        if (payload == null || payload.isEmpty) return;
        final url = Uri.tryParse(payload);
        if (url != null && await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
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

  // ── Launch payload (terminated-state tap) ─────────────────────────────────
  // Call this in main() after init(). Returns the payload URL if the app was
  // launched by tapping a notification (e.g. the update notification).

  static Future<String?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }

  // ── Show helpers ─────────────────────────────────────────────────────────

  static Future<void> showMilestone(int count) {
    final body = 'You just hit ${_fmt(count)} scrobbles on Last.fm 🎶';
    return _plugin.show(
      _idMilestone,
      '🎵 Milestone: ${_fmt(count)} scrobbles',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chMilestoneId, _chMilestoneName,
          icon:    '@mipmap/ic_launcher',
          color:   _kLastFmRed,
          subText: 'LastStats',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: '🎵 Milestone: ${_fmt(count)} scrobbles',
            summaryText:  'LastStats',
          ),
        ),
      ),
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
    );
  }

  static Future<void> showDailyRecap({
    required int    count,
    required String topArtist,
    required String date,
  }) =>
      _plugin.show(
        _idDailyRecap,
        '📊 Daily recap · $date',
        '${_fmt(count)} scrobbles · Top: $topArtist',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _chRecapId, _chRecapName,
            icon:    '@mipmap/ic_launcher',
            color:   _kLastFmRed,
            subText: 'LastStats',
            styleInformation: InboxStyleInformation(
              ['${_fmt(count)} scrobbles today', 'Top artist: $topArtist'],
              contentTitle: '📊 Daily recap · $date',
              summaryText:  'LastStats',
            ),
          ),
        ),
      );

  static Future<void> showWeeklyRecap({
    required int    count,
    required String topArtist,
    required String weekLabel,
  }) =>
      _plugin.show(
        _idWeeklyRecap,
        '📅 Weekly recap · $weekLabel',
        '${_fmt(count)} scrobbles · Top: $topArtist',
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
              contentTitle: '📅 Weekly recap · $weekLabel',
              summaryText:  'LastStats',
            ),
          ),
        ),
      );

  /// Fires a high-importance notification when a new version is available.
  /// [downloadUrl] is stored as the payload so tapping it launches the download
  /// directly — no extra step needed.
  static Future<void> showUpdateAvailable(String version, String downloadUrl) {
    const title = '🆕 Update available';
    final body  = 'LastStats $version is ready — tap to download.';
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
      payload: downloadUrl,
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