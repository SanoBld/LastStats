import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'update_service.dart' show DownloadKind;

const _ch = MethodChannel('laststats/installer');

/// Downloads the update then launches its installer.
/// Returns 'ok' (installer launched), 'permission' (Android settings opened,
/// user must allow installs then tap again) or 'fallback' (open the link instead).
Future<String> installUpdate(String url, DownloadKind kind, void Function(double?) onProgress) async {
  final android = Platform.isAndroid && kind == DownloadKind.apk;
  final windows = Platform.isWindows && kind == DownloadKind.installer;
  if (!android && !windows) return 'fallback';

  if (android && await _ch.invokeMethod<bool>('canInstall') != true) {
    await _ch.invokeMethod('openSettings');
    return 'permission';
  }

  final dir = Directory('${(await getTemporaryDirectory()).path}${Platform.pathSeparator}update');
  if (await dir.exists()) await dir.delete(recursive: true);
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}${android ? 'update.apk' : 'LastStats-Setup.exe'}');

  final client = http.Client();
  try {
    final res = await client.send(http.Request('GET', Uri.parse(url)));
    if (res.statusCode != 200) return 'fallback';
    final total = res.contentLength ?? 0;
    var got = 0;
    final sink = file.openWrite();
    await for (final chunk in res.stream) {
      sink.add(chunk);
      got += chunk.length;
      onProgress(total > 0 ? got / total : null);
    }
    await sink.close();
    if (total > 0 && got != total) return 'fallback';
  } catch (_) {
    return 'fallback';
  } finally {
    client.close();
  }

  if (android) {
    return await _ch.invokeMethod<bool>('install', {'path': file.path}) == true ? 'ok' : 'fallback';
  }
  await Process.start(file.path,
      ['/SILENT', '/SUPPRESSMSGBOXES', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS'],
      mode: ProcessStartMode.detached);
  exit(0);
}
