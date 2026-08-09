// lib/services/friends_library_service.dart
// ══════════════════════════════════════════════════════════════════════════
//  FriendsLibraryService — background sync of friends' music libraries
//
//  Unlike AllScrobblesService (single account, raw per-scrobble history),
//  this stores AGGREGATED top artists/albums/tracks with playcounts, paged
//  until Last.fm returns everything. That's all the taste comparator needs,
//  and it avoids the storage/rate-limit blowup of raw scrobble history for
//  every friend.
//
//  Strategy:
//    • First run     : sync every known friend (dashboard "first setup").
//    • Later launches: only friends past the configured interval get
//      re-synced (default 24h, changeable in Settings).
//    • One friend at a time, small delay between pages/friends — this is
//      a low-priority background job, never blocks the UI.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lastfm_service.dart';

class FriendLibrary {
  final List<Map<String, dynamic>> artists;
  final List<Map<String, dynamic>> albums;
  final List<Map<String, dynamic>> tracks;
  final int lastSync; // unix seconds
  const FriendLibrary({
    required this.artists, required this.albums,
    required this.tracks, required this.lastSync,
  });

  Map<String, dynamic> toJson() =>
      {'artists': artists, 'albums': albums, 'tracks': tracks, 'lastSync': lastSync};

  factory FriendLibrary.fromJson(Map<String, dynamic> j) => FriendLibrary(
    artists:  (j['artists'] as List? ?? []).cast<Map<String, dynamic>>(),
    albums:   (j['albums']  as List? ?? []).cast<Map<String, dynamic>>(),
    tracks:   (j['tracks']  as List? ?? []).cast<Map<String, dynamic>>(),
    lastSync: (j['lastSync'] as num? ?? 0).toInt(),
  );
}

class FriendsLibraryService {
  FriendsLibraryService._();

  static const _prefix       = 'friendlib_';
  static const _kIntervalKey = 'ls_friends_sync_interval_h';
  static const _pageDelay    = Duration(milliseconds: 250);
  static const _friendDelay  = Duration(milliseconds: 600);
  static const _pageLimit    = 1000; // Last.fm's max per page

  static SharedPreferences? _prefs;
  static final Map<String, FriendLibrary> _mem = {};

  // Usernames currently being synced — UI can show a small loading state.
  static final ValueNotifier<Set<String>> syncingNotifier = ValueNotifier({});

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    for (final key in _prefs!.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final raw = _prefs!.getString(key);
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _mem[key.substring(_prefix.length)] = FriendLibrary.fromJson(json);
      } catch (_) {}
    }
  }

  // ── Reads ────────────────────────────────────────────────────────────────

  static FriendLibrary? get(String username) => _mem[username.toLowerCase()];
  static bool hasData(String username) => _mem.containsKey(username.toLowerCase());
  static bool isSyncing(String username) =>
      syncingNotifier.value.contains(username.toLowerCase());

  static int get syncIntervalHours => _prefs?.getInt(_kIntervalKey) ?? 24;

  static Future<void> setSyncIntervalHours(int h) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_kIntervalKey, h);
  }

  static bool needsSync(String username) {
    final lib = get(username);
    if (lib == null) return true;
    final ageH = (DateTime.now().millisecondsSinceEpoch / 1000 - lib.lastSync) / 3600;
    return ageH > syncIntervalHours;
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  static Future<void> _save(String username, FriendLibrary lib) async {
    _mem[username.toLowerCase()] = lib;
    await _prefs?.setString('$_prefix${username.toLowerCase()}', jsonEncode(lib.toJson()));
  }

  // Pages a top-list endpoint until Last.fm returns a partial page (done).
  static Future<List<Map<String, dynamic>>> _fetchAll(
    Future<List<dynamic>> Function(int page) call,
  ) async {
    final out = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final items = await call(page);
      out.addAll(items.cast<Map<String, dynamic>>());
      if (items.length < _pageLimit || page > 50) break; // 50 pages = 50k items, plenty
      page++;
      await Future.delayed(_pageDelay);
    }
    return out;
  }

  /// Full sync for one friend — always replaces the cached library.
  static Future<void> syncFriend(String username, LastFmService service) async {
    final key = username.toLowerCase();
    if (syncingNotifier.value.contains(key)) return; // already running
    syncingNotifier.value = {...syncingNotifier.value, key};
    try {
      final artists = await _fetchAll((p) =>
          service.getTopArtists(user: username, period: 'overall', limit: _pageLimit, page: p));
      final albums = await _fetchAll((p) =>
          service.getTopAlbums(user: username, period: 'overall', limit: _pageLimit, page: p));
      final tracks = await _fetchAll((p) =>
          service.getTopTracks(user: username, period: 'overall', limit: _pageLimit, page: p));
      await _save(username, FriendLibrary(
        artists: artists, albums: albums, tracks: tracks,
        lastSync: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ));
    } catch (_) {
      // Network hiccup — the next scheduled sync will retry.
    } finally {
      syncingNotifier.value = {...syncingNotifier.value}..remove(key);
    }
  }

  /// Sync [username] only if it's stale or missing — used when opening a
  /// friend's profile, so the comparator upgrades itself over time.
  static Future<void> syncFriendIfStale(String username, LastFmService service) async {
    if (needsSync(username)) await syncFriend(username, service);
  }

  /// Sync every stale friend, one at a time. Called on app launch — cheap
  /// no-op once everyone is already synced within the interval.
  static Future<void> syncAllStale(List<String> usernames, LastFmService service) async {
    for (final u in usernames) {
      if (!needsSync(u)) continue;
      await syncFriend(u, service);
      await Future.delayed(_friendDelay);
    }
  }

  static Future<void> clear(String username) async {
    _mem.remove(username.toLowerCase());
    await _prefs?.remove('$_prefix${username.toLowerCase()}');
  }

  static Future<void> clearAll() async {
    for (final k in _mem.keys.toList()) { await clear(k); }
  }
}
