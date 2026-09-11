// lib/services/crash_log_service.dart
// ══════════════════════════════════════════════════════════════════════════
//  Small file-based crash/error log.
//  Every uncaught error caught in main.dart gets appended here with a
//  timestamp, so a user can grab the file from Settings → Backup and share
//  it when reporting a bug — much more useful than "it crashed once idk".
//  No-op on web (no filesystem to write to there).
// ══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

class CrashLogService {
  CrashLogService._();
  static final CrashLogService instance = CrashLogService._();

  static const int _maxBytes = 512 * 1024; // trim past this, keep it light
  File? _file;

  Future<File?> _ensureFile() async {
    if (kIsWeb) return null;
    if (_file != null) return _file;
    try {
      final base = await getApplicationSupportDirectory();
      final dir  = Directory('${base.path}/logs');
      await dir.create(recursive: true);
      _file = File('${dir.path}/crash_log.txt');
      if (!await _file!.exists()) await _file!.create();
      return _file;
    } catch (_) {
      return null;
    }
  }

  /// Append one error entry. Never throws — logging failing shouldn't take
  /// down whatever was already going wrong.
  Future<void> logError(Object error, StackTrace? stack, {String? context}) async {
    try {
      final f = await _ensureFile();
      if (f == null) return;
      final ts = DateTime.now().toIso8601String();
      final buf = StringBuffer()
        ..writeln('── $ts ${context != null ? '[$context] ' : ''}────────────')
        ..writeln(error.toString());
      if (stack != null) {
        // Keep it readable in a shared text file — a few frames is plenty,
        // the full trace is mostly framework noise for a non-dev reader.
        final lines = stack.toString().split('\n').take(12);
        buf.writeln(lines.join('\n'));
      }
      buf.writeln();
      await f.writeAsString(buf.toString(), mode: FileMode.append, flush: true);

      // Trim from the top once the file gets big, so it doesn't grow forever
      // on a device that keeps hitting the same recurring error.
      final size = await f.length();
      if (size > _maxBytes) {
        final content = await f.readAsString();
        await f.writeAsString(content.substring(content.length - _maxBytes ~/ 2));
      }
    } catch (_) {
      // swallow — logging is best-effort
    }
  }

  /// Path to the log file, or null on web / if it couldn't be created yet.
  Future<File?> getFile() => _ensureFile();

  Future<bool> hasEntries() async {
    final f = await _ensureFile();
    if (f == null) return false;
    try { return (await f.length()) > 0; } catch (_) { return false; }
  }

  Future<void> clear() async {
    final f = await _ensureFile();
    if (f == null) return;
    try { await f.writeAsString(''); } catch (_) {}
  }
}
