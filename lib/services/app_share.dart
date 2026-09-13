// lib/services/app_share.dart
//
// Cross-platform "share this file" helper.
//
// On mobile (Android/iOS), the native share sheet from share_plus works
// out of the box. On desktop — Windows especially — share_plus calls the
// OS share charm, which silently does nothing (or throws) for an app that
// isn't packaged as MSIX/Snap with a registered identity. Most builds of
// this app are a plain .exe, so the share button looked broken there.
//
// Fix: on Windows/macOS/Linux, skip the native share charm entirely.
// Instead, copy the file into the user's Downloads folder and reveal it
// in the file explorer/finder — that always works, and the user can drag
// it into whatever app they want from there.
import 'dart:io' show Platform, Process, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AppShare {
  AppShare._();

  static Future<void> shareFile(File file, {String? text}) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      try {
        final dir  = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final name = file.path.split(Platform.pathSeparator).last;
        final dest = File('${dir.path}${Platform.pathSeparator}$name');
        await file.copy(dest.path);
        if (Platform.isWindows) {
          // Opens Explorer with the file highlighted.
          await Process.run('explorer', ['/select,', dest.path]);
        } else if (Platform.isMacOS) {
          // Opens Finder with the file highlighted.
          await Process.run('open', ['-R', dest.path]);
        } else {
          await Process.run('xdg-open', [dir.path]);
        }
        return;
      } catch (_) {
        // Couldn't spawn a process (sandboxed build, missing binary…) —
        // fall through and at least try the normal share sheet below.
      }
    }
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
