// lib/services/video_disk_cache_stub.dart
// No-op implementation (web): videos are always streamed.
import 'package:video_player/video_player.dart';

class VideoDiskCache {
  VideoDiskCache._();

  static bool get supported => false;
  static int maxBytes = 0;

  static Future<void> init(int maxBytesLimit) async => maxBytes = maxBytesLimit;
  static Future<VideoPlayerController?> localController(
          String url, VideoPlayerOptions options) async => null;
  static void storeInBackground(String url) {}
  static Future<int> totalBytes() async => 0;
  static Future<void> enforce(int maxBytesLimit) async {}
  static Future<void> clear() async {}
}
