// lib/services/cache_owner.dart
// ══════════════════════════════════════════════════════════════════════════
//  Remembers which Last.fm account the user-bound caches belong to.
//
//  The scrobble history ("year_*" files + sync meta) and the API data cache
//  ("userinfo", "topartists_*", "loved"…) are stored once, not per account.
//  Switching to another account (the app supports up to 3) or logging in
//  with a different user used to leave the previous user's data in place,
//  and the incremental sync then merged the new user's new scrobbles into
//  the old user's history. ensure() wipes those caches when the account
//  changes. Artwork caches are not user-bound and are kept.
// ══════════════════════════════════════════════════════════════════════════

import 'package:shared_preferences/shared_preferences.dart';
import 'data_cache.dart';
import 'scrobbles_file_cache.dart';

class CacheOwner {
  CacheOwner._();

  static const _kOwner = 'ls_cache_owner';

  /// Call with the active username before any cached user data is used.
  static Future<void> ensure(String username) async {
    final user = username.trim().toLowerCase();
    if (user.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final previous = p.getString(_kOwner);
    if (previous == user) return;
    // previous == null: install from before this check existed — its cache
    // almost certainly belongs to the current account, so keep it.
    if (previous != null) {
      await ScrobblesFileCache.clear();
      await DataCache.clear();
    }
    await p.setString(_kOwner, user);
  }

  /// Full logout: drop user-bound data (Last.fm data must not outlive the
  /// session — API Terms, clause 9.3).
  static Future<void> purge() async {
    await ScrobblesFileCache.clear();
    await DataCache.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kOwner);
  }
}
