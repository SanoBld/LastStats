// lib/services/custom_font_service.dart
// User-imported font (.ttf/.otf). Stored base64 in the `ls_custom_font_b64`
// pref, so the existing backup (all `ls_*` keys) carries it automatically.
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomFontService {
  static const family = 'CustomFont';
  static const _kB64 = 'ls_custom_font_b64';
  static const _kName = 'ls_custom_font_name';
  static const maxBytes = 3 * 1024 * 1024;

  /// Display name of the imported font ('' = none).
  static final name = ValueNotifier<String>('');

  /// Registers the saved font with Flutter. Call at startup and after a restore.
  static Future<void> load([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final b64 = p.getString(_kB64) ?? '';
    if (b64.isEmpty) { name.value = ''; return; }
    try {
      final bytes = base64Decode(b64);
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      name.value = p.getString(_kName) ?? family;
    } catch (_) {
      name.value = '';
    }
  }

  /// Opens the file picker. Returns null on success, else an error code
  /// ('size' / 'invalid'); cancel returns 'cancel'.
  static Future<String?> pick() async {
    final r = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['ttf', 'otf'], withData: true);
    if (r == null || r.files.isEmpty) return 'cancel';
    final f = r.files.first;
    final bytes = f.bytes;
    if (bytes == null) return 'invalid';
    if (bytes.length > maxBytes) return 'size';
    final p = await SharedPreferences.getInstance();
    await p.setString(_kB64, base64Encode(bytes));
    await p.setString(_kName, f.name.replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), ''));
    await load(p);
    return name.value.isEmpty ? 'invalid' : null;
  }

  static Future<void> remove() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kB64);
    await p.remove(_kName);
    if (p.getString('ls_app_font') == family) await p.setString('ls_app_font', '');
    name.value = '';
  }
}
