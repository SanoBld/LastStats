// Dashboard background picked from the device. The image is kept inside the
// app (SharedPreferences, base64), so it works on every platform and survives
// the original file being moved or deleted.
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeaderImageService {
  HeaderImageService._();

  static const _key = 'ls_header_local_b64';
  static const maxBytes = 4 * 1024 * 1024; // 4 MB
  /// Value used in place of an URL when the local image is the one to show.
  static const marker = 'local:header';

  static final ValueNotifier<Uint8List?> bytes = ValueNotifier(null);
  static bool get has => bytes.value != null;

  static Future<void> load() async {
    if (bytes.value != null) return;
    try {
      final p = await SharedPreferences.getInstance();
      final b64 = p.getString(_key);
      if (b64 != null && b64.isNotEmpty) bytes.value = base64Decode(b64);
    } catch (_) {}
  }

  /// null = saved, 'cancel', 'size' or 'invalid'.
  static Future<String?> pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (r == null || r.files.isEmpty) return 'cancel';
    final data = r.files.first.bytes;
    if (data == null || data.isEmpty) return 'invalid';
    if (data.length > maxBytes) return 'size';
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, base64Encode(data));
    bytes.value = data;
    return null;
  }

  static Future<void> remove() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
    bytes.value = null;
  }

  /// The right image widget for an URL or for [marker].
  static Widget image(String url, {required Widget Function() onError}) {
    final b = bytes.value;
    if (url == marker && b != null) {
      return Image.memory(b, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
          errorBuilder: (_, _, _) => onError());
    }
    return Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
        errorBuilder: (_, _, _) => onError());
  }
}
