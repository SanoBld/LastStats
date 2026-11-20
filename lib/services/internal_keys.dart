// lib/services/internal_keys.dart
//
// Built-in Last.fm API keys, used only as an opt-in backup.
//   - Each install picks one key at random, then keeps it (stable per device).
//   - "Built-in key" mode: the picked key is used as the account key.
//   - "Backup" mode: the user's own key is tried first; on a key/quota error
//     the request is retried once with the built-in key (see LastFmService).
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'lastfm_service.dart';

class InternalKeys {
  InternalKeys._();

  // Keys are NOT in the code. They come from build-time secrets:
  //   --dart-define=LS_KEYS=key1,key2,key3   (apps)
  //   --dart-define=LS_WEB_KEY=key           (web build only)
  static const _rawKeys = String.fromEnvironment('LS_KEYS');
  static const _webKey  = String.fromEnvironment('LS_WEB_KEY');

  // Public backup key, written in the code on purpose (last resort only).
  static const _publicKey = '4b209f5fef22138422d78a337d7518a4';

  // Secret keys (from build-time defines), used first.
  static final List<String> _secret = kIsWeb
      ? (_webKey.isNotEmpty ? [_webKey] : <String>[])
      : _rawKeys.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  // Full pool = secret keys + public key at the end.
  static final List<String> _pool = [..._secret, _publicKey];

  // Installs only pick a secret key; the public one is used when none exist.
  static List<String> get _pickable => _secret.isEmpty ? [_publicKey] : _secret;

  /// Public built-in keys are switched OFF (kept in the code, not deleted).
  /// Set to true to bring them back everywhere (login choice, fallback, key swap).
  static const bool enabled = false;

  static const _kPicked   = 'ls_internal_key';
  static const _kFallback = 'ls_internal_fallback';

  static bool isInternal(String key) => _pool.contains(key);

  /// Index of [key] in the built-in pool, or -1 when it is not a built-in key.
  static int indexOf(String key) => _pool.indexOf(key);

  /// Number of built-in keys.
  static int get poolSize => _pool.length;

  /// Returns this install's random built-in key (picked once, then stored).
  static Future<String> pick([SharedPreferences? prefs]) async {
    if (!enabled) return '';
    final p = prefs ?? await SharedPreferences.getInstance();
    final saved = p.getString(_kPicked) ?? '';
    if (_pool.contains(saved)) return saved;
    // Random.secure: every install draws its own key, so the load is
    // spread evenly over the built-in keys.
    final key = _pickable[Random.secure().nextInt(_pickable.length)];
    await p.setString(_kPicked, key);
    return key;
  }

  static Future<bool> isFallbackEnabled([SharedPreferences? prefs]) async {
    if (!enabled) return false;
    final p = prefs ?? await SharedPreferences.getInstance();
    return p.getBool(_kFallback) ?? false;
  }

  /// Applies the stored backup setting to [LastFmService]. Call at startup
  /// and at the start of any background isolate.
  static Future<void> loadFallback([SharedPreferences? prefs]) async {
    if (!enabled) { LastFmService.fallbackKey = ''; return; }
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
