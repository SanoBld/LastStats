// lib/services/notification_service.dart

import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Last.fm brand red — shown as the accent color on Android notifications
const _kLastFmRed = Color(0xFFD51007);

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Channel IDs ──────────────────────────────────────────────────────────
  static const _chMilestoneId   = 'ls_milestone';
  static const _chMilestoneName = 'Scrobble milestones';

  // Grand milestones get their own high-importance channel (heads-up popup)
  static const _chGrandId   = 'ls_grand_milestone';
  static const _chGrandName = 'Grand milestones';

  static const _chRecapId   = 'ls_recap';
  static const _chRecapName = 'Listening recaps';

  // ── Notification IDs ─────────────────────────────────────────────────────
  // Stable IDs so we never stack duplicate notifications
  static const _idMilestone   = 1;
  static const _idDailyRecap  = 2;
  static const _idWeeklyRecap = 3;
  static const _idGrand       = 4;
  static const _idTest        = 99;

  // ── Init ─────────────────────────────────────────────────────────────────

  /// Call once at app startup (and at the top of the WorkManager callback).
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(const InitializationSettings(
      android: android,
      iOS:     ios,
    ));

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Regular milestone — default importance (no heads-up)
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chMilestoneId, _chMilestoneName,
        description: 'Notifies when you hit a scrobble milestone',
        importance:  Importance.defaultImportance,
      ),
    );

    // Grand milestone — high importance so Android shows a heads-up popup
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chGrandId, _chGrandName,
        description: 'Special alerts for big milestones (1K, 10K, 100K, 1M…)',
        importance:  Importance.high,
      ),
    );

    // Recap — low importance, no sound, just sits in the drawer
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _chRecapId, _chRecapName,
        description: 'Daily and weekly listening summaries',
        importance:  Importance.low,
      ),
    );
  }

  // ── Permissions ──────────────────────────────────────────────────────────

  /// Ask for permission (Android 13+, iOS). Returns true if granted.
  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final a = await android?.requestNotificationsPermission() ?? true;
    final i = await ios?.requestPermissions(
        alert: true, badge: true, sound: true) ?? true;
    return a && i;
  }

  /// Check whether the app already has notification permission.
  static Future<bool> hasPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  // ── Show helpers ─────────────────────────────────────────────────────────

  /// Regular milestone — fired every X scrobbles set by the user.
  static Future<void> showMilestone(int count) {
    final body = 'You just hit ${_fmt(count)} scrobbles on Last.fm 🎶';
    return _plugin.show(
      _idMilestone,
      '🎵 Milestone: ${_fmt(count)} scrobbles',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chMilestoneId, _chMilestoneName,
          icon:     '@mipmap/ic_launcher',
          color:    _kLastFmRed,
          subText:  'LastStats',
          // BUG FIX: BigTextStyleInformation must receive the body text,
          // not an empty string — otherwise the expanded view was blank.
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: '🎵 Milestone: ${_fmt(count)} scrobbles',
            summaryText:  'LastStats',
          ),
        ),
      ),
    );
  }

  /// Grand milestone — fires once at 1K / 5K / 10K / 25K / 50K /
  /// 100K / 250K / 500K / 1M. Uses a high-importance channel so Android
  /// shows a heads-up banner with a custom message.
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

  /// Daily recap — inbox style so each line is clearly readable.
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

  /// Weekly recap.
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

  /// Test notification — lets the user verify that everything works.
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

  /// Format a number with commas: 1000000 → "1,000,000"
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

  /// Short title for a grand milestone: 1000000 → "1M scrobbles!"
  static String _grandTitle(int count) {
    if (count >= 1000000) return '${count ~/ 1000000}M scrobbles!';
    if (count >= 1000)    return '${count ~/ 1000}K scrobbles!';
    return '${_fmt(count)} scrobbles!';
  }

  /// Personal message shown in the expanded grand milestone notification.
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