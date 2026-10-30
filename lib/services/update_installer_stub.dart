import 'update_service.dart' show DownloadKind;

// Web: nothing to install or save, the caller opens the link instead.
Future<String> installUpdate(String url, DownloadKind kind, void Function(double?) onProgress) async => 'fallback';
Future<String> saveDownload(String url, String fileName, void Function(double?) onProgress) async => 'fallback';
