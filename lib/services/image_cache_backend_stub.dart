// lib/services/image_cache_backend_stub.dart
import 'dart:typed_data';

class ImageCacheBackend {
  static Future<String?>   readMeta()                     async => null;
  static Future<void>      writeMeta(String _)            async {}
  static Future<Uint8List?> read(String _)                async => null;
  static Future<void>      write(String _, Uint8List _)  async {}
  static Future<void>      delete(String _)               async {}
  static Future<int>       totalBytes()                   async => 0;
  static Future<void>      clearAll()                     async {}
}
