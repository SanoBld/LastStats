import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';

/// Selectable launcher icon (Android only): one activity-alias per icon.
class AppIconService {
  static const _ch = MethodChannel('laststats/appicon');
  static const keys = ['default', 'white', 'nothing_black', 'nothing_white', 'blue', 'red'];

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<String> current() async {
    if (!supported) return 'default';
    try {
      return await _ch.invokeMethod<String>('get') ?? 'default';
    } catch (_) {
      return 'default';
    }
  }

  static Future<bool> set(String key) async {
    if (!supported) return false;
    try {
      return await _ch.invokeMethod<bool>('set', {'key': key}) == true;
    } catch (_) {
      return false;
    }
  }
}
