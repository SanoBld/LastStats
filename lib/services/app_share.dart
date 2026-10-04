// lib/services/app_share.dart
//
// Cross-platform "share this file" helper.
//
// On mobile (Android/iOS), the native share sheet from share_plus works
// out of the box. On desktop — Windows especially — share_plus calls the
// OS share charm ("Essayez à nouveau, nous n'avons pas pu vous montrer
// tous les partages possibles"), which fails for an app that isn't
// packaged as MSIX/Snap with a registered identity. Most builds of this
// app are a plain .exe, so the share button looked broken there.
//
// Fix: on Windows/macOS/Linux, never call the native share charm at all.
// Instead, save the file into the user's Downloads folder and reveal it
// in the file explorer/Finder — that always works, and the user can drag
// it into whatever app they want from there. If even saving/revealing
// fails for some reason, we still don't fall back to the broken native
// share — that would just show the same broken dialog again — so the
// very last resort is silently saving to the app's own documents folder.
import 'dart:io' show Platform, Process, File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'web_download_stub.dart'
    if (dart.library.js_interop) 'web_download_web.dart';

class AppShare {
  AppShare._();

  /// Shares PNG/other bytes. Web: browser download. Native: temp file + share.
  static Future<void> shareBytes(String name, Uint8List bytes,
      {String? text, String mime = 'image/png'}) async {
    if (kIsWeb) {
      downloadBytes(name, bytes, mime);
      return;
    }
    final tmp  = await getTemporaryDirectory();
    final file = File('${tmp.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes);
    await shareFile(file, text: text);
  }

  static Future<void> shareFile(File file, {String? text}) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      final name = file.path.split(Platform.pathSeparator).last;

      // 1) Preferred: Downloads folder, then reveal it.
      try {
        final dir = await getDownloadsDirectory();
        if (dir != null) {
          final dest = File('${dir.path}${Platform.pathSeparator}$name');
          await file.copy(dest.path);
          await _reveal(dest.path, dir.path);
          return;
        }
      } catch (_) {
        // Try the next fallback instead of giving up.
      }

      // 2) Fallback: app's own documents folder (always writable), then
      //    still try to reveal it — but don't let a reveal failure stop us
      //    from at least having saved the file.
      try {
        final dir  = await getApplicationDocumentsDirectory();
        final dest = File('${dir.path}${Platform.pathSeparator}$name');
        await file.copy(dest.path);
        try { await _reveal(dest.path, dir.path); } catch (_) {}
        return;
      } catch (_) {
        // Genuinely nothing worked — do NOT fall back to Share.shareXFiles
        // here, it's the broken native charm this whole file exists to
        // avoid. Just give up quietly rather than show that dialog again.
        return;
      }
    }

    // Android / iOS: the native share sheet works fine.
    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  static Future<void> _reveal(String filePath, String dirPath) async {
    if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', filePath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', filePath]);
    } else {
      await Process.run('xdg-open', [dirPath]);
    }
  }
}
