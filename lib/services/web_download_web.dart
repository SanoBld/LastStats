// lib/services/web_download_web.dart
// Web: save bytes through a temporary <a download> link.
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadBytes(String name, Uint8List bytes, String mime) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url  = web.URL.createObjectURL(blob);
  final a    = web.HTMLAnchorElement()
    ..href     = url
    ..download = name;
  web.document.body?.append(a);
  a.click();
  a.remove();
  Future<void>.delayed(const Duration(seconds: 2), () => web.URL.revokeObjectURL(url));
}
