// lib/services/image_cache_backend_native.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ImageCacheBackend {
  static Directory? _dir;

  static Future<Directory> _ensureDir() async {
    if (_dir != null && _dir!.existsSync()) return _dir!;
    final base = await getApplicationSupportDirectory();
    _dir = Directory('${base.path}/img_cache');
    await _dir!.create(recursive: true);
    return _dir!;
  }

  static Future<String?> readMeta() async {
    try {
      final dir = await _ensureDir();
      final f   = File('${dir.path}/meta.json');
      if (!f.existsSync()) return null;
      return f.readAsStringSync();
    } catch (_) { return null; }
  }

  static Future<void> writeMeta(String json) async {
    try {
      final dir = await _ensureDir();
      await File('${dir.path}/meta.json').writeAsString(json);
    } catch (_) {}
  }

  static Future<Uint8List?> read(String key) async {
    try {
      final dir = await _ensureDir();
      final f   = File('${dir.path}/$key.bin');
      if (!f.existsSync()) return null;
      return f.readAsBytesSync();
    } catch (_) { return null; }
  }

  static Future<void> write(String key, Uint8List bytes) async {
    try {
      final dir = await _ensureDir();
      await File('${dir.path}/$key.bin').writeAsBytes(bytes);
    } catch (_) {}
  }

  static Future<void> delete(String key) async {
    try {
      final dir = await _ensureDir();
      final f   = File('${dir.path}/$key.bin');
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }

  static Future<int> totalBytes() async {
    try {
      final dir   = await _ensureDir();
      int   total = 0;
      await for (final e in dir.list()) {
        if (e is File) {
          try { total += await e.length(); } catch (_) {}
        }
      }
      return total;
    } catch (_) { return 0; }
  }

  static Future<void> clearAll() async {
    try {
      final dir = await _ensureDir();
      _dir = null;
      if (dir.existsSync()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
      _dir = dir;
    } catch (_) {}
  }
}
