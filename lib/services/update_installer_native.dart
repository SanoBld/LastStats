import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../l10n/extra_strings.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_service.dart';

const _ch = MethodChannel('laststats/installer');

// Downloads [url] into the temp folder. The job does not depend on any widget:
// closing the sheet keeps it running, and a progress notification (plus an
// Android foreground service) keeps it alive in the background when the user
// enabled download notifications.
Future<File?> _fetch(String url, String tempName, String title, void Function(double?) onProgress) async {
  final dir = Directory('${(await getTemporaryDirectory()).path}${Platform.pathSeparator}update');
  if (await dir.exists()) await dir.delete(recursive: true);
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$tempName');
  final client = http.Client();
  var lastTick = 0;
  try {
    await NotificationService.showDownloadProgress(title, 0);
    final res = await client.send(http.Request('GET', Uri.parse(url)));
    if (res.statusCode != 200) throw Exception('http ${res.statusCode}');
    final total = res.contentLength ?? 0;
    var got = 0;
    final sink = file.openWrite();
    await for (final chunk in res.stream) {
      sink.add(chunk);
      got += chunk.length;
      final p = total > 0 ? got / total : null;
      onProgress(p);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastTick > 500) {
        lastTick = now;
        NotificationService.showDownloadProgress(title, p);
      }
    }
    await sink.close();
    if (total > 0 && got != total) throw Exception('incomplete');
    return file;
  } catch (_) {
    await NotificationService.showDownloadDone(title, tx('ntf_dl_failed'));
    return null;
  } finally {
    client.close();
  }
}

/// Downloads the update then launches its installer.
/// Returns 'ok' (installer launched), 'permission' (Android settings opened,
/// user must allow installs then tap again) or 'fallback' (open the link instead).
Future<String> installUpdate(String url, DownloadKind kind, void Function(double?) onProgress, {String? version}) async {
  final android = Platform.isAndroid && kind == DownloadKind.apk;
  final windows = Platform.isWindows && kind == DownloadKind.installer;
  if (!android && !windows) return 'fallback';

  if (android && await _ch.invokeMethod<bool>('canInstall') != true) {
    await _ch.invokeMethod('openSettings');
    return 'permission';
  }

  final file = await _fetch(url, android ? 'update.apk' : 'LastStats-Setup.exe', 'LastStats', onProgress);
  if (file == null) return 'fallback';

  if (android) {
    final p = await SharedPreferences.getInstance();
    if (version != null) await p.setString('ls_update_pending_ver', version);
    await NotificationService.showDownloadDone(tx('ntf_dl_ready'), tx('ntf_dl_install_hint'),
        payload: NotificationService.simplePayload('install', file.path), install: true);
    return await _ch.invokeMethod<bool>('install', {'path': file.path}) == true ? 'ok' : 'fallback';
  }
  await NotificationService.cancelDownload();
  await Process.start(file.path,
      ['/SILENT', '/SUPPRESSMSGBOXES', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS'],
      mode: ProcessStartMode.detached);
  exit(0);
}

/// Downloads a release file and puts it in the default Downloads folder
/// (no browser, no install). Returns 'saved|<where>' or 'fallback'.
Future<String> saveDownload(String url, String fileName, void Function(double?) onProgress) async {
  if (Platform.isIOS) return 'fallback';
  final file = await _fetch(url, fileName, fileName, onProgress);
  if (file == null) return 'fallback';

  String? saved;
  try {
    if (Platform.isAndroid) {
      saved = await _ch.invokeMethod<String>('saveToDownloads', {'path': file.path, 'name': fileName});
    } else {
      final d = await getDownloadsDirectory();
      if (d != null) {
        final dot  = fileName.lastIndexOf('.');
        final base = dot > 0 ? fileName.substring(0, dot) : fileName;
        final ext  = dot > 0 ? fileName.substring(dot) : '';
        var dst = File('${d.path}${Platform.pathSeparator}$fileName');
        var i = 1;
        while (await dst.exists()) {
          dst = File('${d.path}${Platform.pathSeparator}$base ($i)$ext');
          i++;
        }
        await file.copy(dst.path);
        saved = dst.path;
      }
    }
  } catch (_) {}

  if (saved == null || saved.isEmpty) {
    await NotificationService.showDownloadDone(fileName, tx('ntf_dl_failed'));
    return 'fallback';
  }
  try { await file.delete(); } catch (_) {}
  await NotificationService.showDownloadDone(fileName, tx('up_saved'),
      payload: NotificationService.simplePayload('downloads', saved));
  return 'saved|$saved';
}

/// Installs an already downloaded APK (used by the notification action).
Future<void> installApkAt(String path) async {
  if (!Platform.isAndroid || !await File(path).exists()) return;
  if (await _ch.invokeMethod<bool>('canInstall') != true) {
    await _ch.invokeMethod('openSettings');
    return;
  }
  await _ch.invokeMethod('install', {'path': path});
}

/// Opens the Downloads folder in the system file manager.
Future<void> openDownloadsFolder(String? where) async {
  try {
    if (Platform.isAndroid) {
      await _ch.invokeMethod('openDownloads');
    } else if (Platform.isWindows) {
      final ok = where != null && await File(where).exists();
      await Process.start('explorer', [ok ? '/select,$where' : (await getDownloadsDirectory())?.path ?? ''],
          mode: ProcessStartMode.detached);
    } else if (Platform.isMacOS) {
      await Process.start('open', where != null ? ['-R', where] : [(await getDownloadsDirectory())?.path ?? ''],
          mode: ProcessStartMode.detached);
    } else if (Platform.isLinux) {
      final dir = where != null ? File(where).parent.path : (await getDownloadsDirectory())?.path ?? '';
      await Process.start('xdg-open', [dir], mode: ProcessStartMode.detached);
    }
  } catch (_) {}
}

/// Deletes downloaded update files once the update is installed (or never needed).
Future<void> cleanupUpdateFiles() async {
  try {
    final p = await SharedPreferences.getInstance();
    final pending = p.getString('ls_update_pending_ver');
    if (UpdateService.currentVersion == '0.0.0') return;
    if (pending != null && UpdateService.isNewerThanInstalled(pending)) return; // not installed yet
    final dir = Directory('${(await getTemporaryDirectory()).path}${Platform.pathSeparator}update');
    if (await dir.exists()) await dir.delete(recursive: true);
    await p.remove('ls_update_pending_ver');
  } catch (_) {}
}
