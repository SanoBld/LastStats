// lib/services/widget_service.dart
//
// Pushes Last.fm data to Android home screen widgets via home_widget.
// Keep it simple: fetch, save keys, ask Android to redraw each widget.

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lastfm_service.dart';

class WidgetService {
  // Must match the Kotlin provider class names (App Widget IDs).
  static const _providerScrobbles = 'ScrobbleCountWidgetProvider';
  static const _providerNowPlaying = 'NowPlayingWidgetProvider';
  static const _providerLoved = 'LovedCountWidgetProvider';
  static const _providerWeekly = 'WeeklyScrobblesWidgetProvider';
  static const _providerRecap = 'RecapWidgetProvider';

  static const _appGroupId = 'group.com.example.laststats_mobile';

  /// Fetch fresh data and refresh every widget currently on the home screen.
  static Future<void> updateAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('ls_username') ?? '';
      final apiKey = prefs.getString('ls_apikey') ?? '';
      if (username.isEmpty || apiKey.isEmpty) return; // not logged in

      // App theme, passed to Android so widgets match it (style + light/dark).
      final themeStyle = prefs.getString('ls_theme_style') ?? 'default';
      final themeMode = prefs.getString('ls_theme') ?? 'system';
      final accentRaw = prefs.getString('ls_accent') ?? '';
      await HomeWidget.saveWidgetData<String>('theme_style', themeStyle);
      await HomeWidget.saveWidgetData<String>('theme_mode', themeMode);
      await HomeWidget.saveWidgetData<String>('accent_color', accentRaw);

      await HomeWidget.setAppGroupId(_appGroupId);
      final api = LastFmService(apiKey: apiKey, username: username);

      // Total scrobbles + user avatar
      final user = await api.getUserInfo();
      final totalScrobbles = user?['playcount']?.toString() ?? '0';
      final avatarUrl = _pickImage(user?['image']);

      // Now playing (or last played track)
      final recent = await api.getRecentTracks(limit: 1);
      final tracks = (recent['track'] is List)
          ? recent['track'] as List
          : (recent['track'] != null ? [recent['track']] : []);
      String trackName = '', artistName = '', trackArt = '';
      bool isPlaying = false;
      if (tracks.isNotEmpty) {
        final t = tracks.first as Map<String, dynamic>;
        trackName = t['name']?.toString() ?? '';
        artistName = (t['artist'] is Map)
            ? (t['artist']['#text']?.toString() ?? '')
            : t['artist']?.toString() ?? '';
        trackArt = _pickImage(t['image']);
        isPlaying = t['@attr']?['nowplaying'] == 'true';
      }

      // Loved tracks count
      final lovedCount = await api.getLovedTracksCount();

      // Weekly scrobbles: count recent tracks from the last 7 days
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final weekData = await api.getRecentTracks(
        limit: 200,
        from: weekAgo.millisecondsSinceEpoch ~/ 1000,
        to: now.millisecondsSinceEpoch ~/ 1000,
      );
      final weekTracks = (weekData['track'] is List)
          ? weekData['track'] as List
          : (weekData['track'] != null ? [weekData['track']] : []);
      final weeklyTotal = int.tryParse(
              weekData['@attr']?['total']?.toString() ?? '') ??
          weekTracks.length;

      // Save every value the widgets might show.
      await HomeWidget.saveWidgetData<String>('username', username);
      await HomeWidget.saveWidgetData<String>('avatar_url', avatarUrl);
      await HomeWidget.saveWidgetData<String>('total_scrobbles', totalScrobbles);
      await HomeWidget.saveWidgetData<String>('track_name', trackName);
      await HomeWidget.saveWidgetData<String>('artist_name', artistName);
      await HomeWidget.saveWidgetData<String>('track_art', trackArt);
      await HomeWidget.saveWidgetData<bool>('is_playing', isPlaying);
      await HomeWidget.saveWidgetData<String>('loved_count', '$lovedCount');
      await HomeWidget.saveWidgetData<String>('weekly_scrobbles', '$weeklyTotal');
      await HomeWidget.saveWidgetData<String>(
          'updated_at', now.millisecondsSinceEpoch.toString());

      // Ask Android to redraw each installed widget type.
      for (final name in [
        _providerScrobbles,
        _providerNowPlaying,
        _providerLoved,
        _providerWeekly,
        _providerRecap,
      ]) {
        await HomeWidget.updateWidget(
          name: name,
          androidName: name,
        );
      }
    } catch (_) {
      // Widgets are best-effort — never crash the caller (worker or app).
    }
  }

  static String _pickImage(dynamic images) {
    if (images is! List || images.isEmpty) return '';
    // Last.fm gives sizes small→extralarge; take the biggest available.
    for (final img in images.reversed) {
      final url = img['#text']?.toString() ?? '';
      if (url.isNotEmpty) return url;
    }
    return '';
  }
}
