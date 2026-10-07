// lib/services/internal_keys.dart
//
// Built-in Last.fm API keys, used only as an opt-in backup.
//   - Each install picks one key at random, then keeps it (stable per device).
//   - "Built-in key" mode: the picked key is used as the account key.
//   - "Backup" mode: the user's own key is tried first; on a key/quota error
//     the request is retried once with the built-in key (see LastFmService).
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'lastfm_service.dart';

class InternalKeys {
  InternalKeys._();

  static const _pool = <String>[
    '64ea3292f32f8fdae796d6cd0a12a21b',
    '2f3ca4abee468c40006b104e151553eb',
    'c24da2031c7db6a6bbcba8c486f6e39e',
    '4399f75c4c1cedec886c3365dafb5498',
    'd60cfa9cc84acc54e57971552d9d1ccf',
  ];

  static const _kPicked   = 'ls_internal_key';
  static const _kFallback = 'ls_internal_fallback';

  static bool isInternal(String key) => _pool.contains(key);

  /// Index of [key] in the built-in pool, or -1 when it is not a built-in key.
  static int indexOf(String key) => _pool.indexOf(key);

  /// Number of built-in keys.
  static int get poolSize => _pool.length;

  /// Returns this install's random built-in key (picked once, then stored).
  static Future<String> pick([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final saved = p.getString(_kPicked) ?? '';
    if (_pool.contains(saved)) return saved;
    final key = _pool[Random().nextInt(_pool.length)];
    await p.setString(_kPicked, key);
    return key;
  }

  static Future<bool> isFallbackEnabled([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return p.getBool(_kFallback) ?? false;
  }

  /// Applies the stored backup setting to [LastFmService]. Call at startup
  /// and at the start of any background isolate.
  static Future<void> loadFallback([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    LastFmService.fallbackKey =
        (p.getBool(_kFallback) ?? false) ? await pick(p) : '';
  }

  static Future<void> setFallback(bool on) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFallback, on);
    await loadFallback(p);
  }
}
