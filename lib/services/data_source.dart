// lib/services/data_source.dart
// Which service the app reads the listening data from.
//   Last.fm      -> everything works as before
//   ListenBrainz -> no Last.fm request is made at all (see lb_adapter.dart)
import 'package:shared_preferences/shared_preferences.dart';

class DataSource {
  /// true = ListenBrainz mode
  static bool lb = false;

  /// Reads the saved choice (call once at startup).
  /// Update from a version without the service choice: whoever is already
  /// logged in is recorded as a Last.fm user, with no logout. main.dart then
  /// opens the dashboard directly; only logged-out people see the login page.
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString('ls_source') == null) {
      final loggedIn = (p.getString('ls_username') ?? '').isNotEmpty &&
          (p.getString('ls_apikey') ?? '').isNotEmpty;
      if (loggedIn) {
        await p.setString('ls_source', 'lfm');
        await p.setString('ls_cache_source', 'lfm');
      }
    }
    lb = p.getString('ls_source') == 'lb';
  }

  static Future<void> set({required bool listenbrainz}) async {
    lb = listenbrainz;
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_source', listenbrainz ? 'lb' : 'lfm');
  }
}
