import 'update_service.dart' show DownloadKind;

// Web: nothing to install, the caller opens the link instead.
Future<String> installUpdate(String url, DownloadKind kind, void Function(double?) onProgress) async => 'fallback';
