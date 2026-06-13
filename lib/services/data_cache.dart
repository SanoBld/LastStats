// lib/services/data_cache.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataCache {
  DataCache._();

  static const _prefix = 'lscache_';

  // TTL per category prefix (minutes).
  static const _ttl = <String, int>{
    'userinfo':  60,
    'topartists': 30,
    'topalbums':  30,
    'toptracks':  30,
    'recent':      2,
    'nowplaying':  1,
    'monthly':   360,
    'loved':      60,
    'friends':     5,
    'search':     10,
  };

  // When true, getSync/get return stale (expired) data instead of null.
  // Set this to true when the device is offline.
  static bool offlineMode = false;

  static final Map<String, _CacheEntry> _mem = {};
  static bool _warmedUp = false;
  static SharedPreferences? _prefs;

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _warmUp();
  }

  static Future<void> _warmUp() async {
    if (_warmedUp) return;
    _warmedUp = true;
    final p = _prefs!;
    for (final key in p.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final raw = p.getString(key);
      if (raw == null) continue;
      try {
        final entry    = jsonDecode(raw) as Map<String, dynamic>;
        final ts       = (entry['ts'] as num?)?.toInt() ?? 0;
        final cacheKey = key.substring(_prefix.length);
        final e        = _CacheEntry(ts: ts, data: entry['data']);
        // Load all into memory; expiry is checked at read time.
        _mem[cacheKey] = e;
      } catch (_) {}
    }
  }

  static Future<void> clearExpired() async {
    await init();
    final toRemove = <String>[];
    for (final key in _prefs!.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final raw = _prefs!.getString(key);
      if (raw == null) { toRemove.add(key); continue; }
      try {
        final entry    = jsonDecode(raw) as Map<String, dynamic>;
        final ts       = (entry['ts'] as num?)?.toInt() ?? 0;
        final cacheKey = key.substring(_prefix.length);
        if (_CacheEntry(ts: ts, data: null).isExpired(_ttlOf(cacheKey))) {
          toRemove.add(key);
        }
      } catch (_) { toRemove.add(key); }
    }
    for (final key in toRemove) {
      await _prefs!.remove(key);
      _mem.remove(key.substring(_prefix.length));
    }
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns fresh (non-expired) data from memory, or stale data in offline mode.
  static dynamic getSync(String key) {
    final e = _mem[key];
    if (e == null) return null;
    if (e.isExpired(_ttlOf(key)) && !offlineMode) {
      _mem.remove(key);
      return null;
    }
    return e.data;
  }

  static Future<dynamic> get(String key) async {
    final mem = getSync(key);
    if (mem != null) return mem;

    await init();
    final raw = _prefs!.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final ts    = (entry['ts'] as num?)?.toInt() ?? 0;
      final e     = _CacheEntry(ts: ts, data: entry['data']);
      if (e.isExpired(_ttlOf(key)) && !offlineMode) return null;
      _mem[key] = e;
      return e.data;
    } catch (_) { return null; }
  }

  /// Returns cached data regardless of expiry — for offline fallback.
  static dynamic getStale(String key) => _mem[key]?.data;

  // ── Write ─────────────────────────────────────────────────────────────────

  static Future<void> set(String key, dynamic data) async {
    await init();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final e  = _CacheEntry(ts: ts, data: data);
    _mem[key] = e;
    try {
      await _prefs!.setString('$_prefix$key', jsonEncode({'ts': ts, 'data': data}));
    } catch (_) { _mem.remove(key); }
  }

  static Future<void> invalidate(String key) async {
    _mem.remove(key);
    await init();
    await _prefs!.remove('$_prefix$key');
  }

  static Future<void> clear() async {
    _mem.clear();
    await init();
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) await _prefs!.remove(k);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  static int get memEntries  => _mem.length;
  static int get diskEntries =>
      _prefs?.getKeys().where((k) => k.startsWith(_prefix)).length ?? 0;

  /// Rough estimate of SharedPrefs cache size in bytes.
  static int estimateDiskBytes() {
    int total = 0;
    for (final e in _mem.entries) {
      try {
        total += jsonEncode({'ts': 0, 'data': e.value.data}).length * 2;
      } catch (_) {}
    }
    return total;
  }

  // ── Standard keys ────────────────────────────────────────────────────────

  static String keyUserInfo()                => 'userinfo';
  static String keyTopArtists(String period) => 'topartists_$period';
  static String keyTopAlbums(String period)  => 'topalbums_$period';
  static String keyTopTracks(String period)  => 'toptracks_$period';
  static String keyRecentTracks({String user = '', int limit = 10}) =>
      'recent_${user}_$limit';
  static String keyNowPlaying()   => 'nowplaying';
  static String keyMonthlyScrobbles() => 'monthly';
  static String keyLovedTracks()  => 'loved';
  static String keyFriends()      => 'friends';

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _ttlOf(String key) {
    for (final cat in _ttl.keys) {
      if (key.startsWith(cat)) return _ttl[cat]!;
    }
    return 30;
  }
}

class _CacheEntry {
  final int     ts;
  final dynamic data;
  const _CacheEntry({required this.ts, required this.data});

  bool isExpired(int ttlMinutes) =>
      DateTime.now().millisecondsSinceEpoch - ts > ttlMinutes * 60 * 1000;
}
