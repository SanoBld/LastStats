// lib/services/storage_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_image_cache.dart';
import 'data_cache.dart';
import 'scrobbles_file_cache.dart';
import 'video_disk_cache.dart';

// 0 means no limit.
const int kStorageNoLimit = 0;

class StorageStats {
  final int imageBytes;
  final int scrobbleBytes;
  final int apiBytes;
  final int videoBytes;   // Apple Music motion artwork stored on disk
  final int maxBytes;     // photo (image) cache limit, 0 = unlimited
  final int videoMaxBytes; // video cache limit: 0 = unlimited, <0 = off

  const StorageStats({
    required this.imageBytes,
    required this.scrobbleBytes,
    required this.apiBytes,
    required this.videoBytes,
    required this.maxBytes,
    required this.videoMaxBytes,
  });

  int get totalBytes => imageBytes + scrobbleBytes + apiBytes + videoBytes;

  // 0.0–1.0 of the photo cache limit, or 0 when unlimited.
  double get usedFraction {
    if (maxBytes <= 0) return 0;
    return (imageBytes / maxBytes).clamp(0.0, 1.0);
  }
}

class StorageManager {
  StorageManager._();

  // Photo cache limit (key kept from the old global limit, so it migrates).
  static const _kPref      = 'ls_max_storage_bytes';
  static const _kVideoPref = 'ls_max_video_bytes';
  static const defaultMax      = 500 * 1024 * 1024; // 500 MB
  static const defaultVideoMax = 500 * 1024 * 1024; // 500 MB

  static int _max      = defaultMax;
  static int _videoMax = defaultVideoMax;
  static int get maxBytes      => _max;
  static int get videoMaxBytes => _videoMax;

  // Scrobbles and API data are never limited: only photos and videos are.
  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _max      = p.getInt(_kPref) ?? defaultMax;
    _videoMax = p.getInt(_kVideoPref) ?? defaultVideoMax;
    await VideoDiskCache.init(_videoMax);
  }

  static Future<void> setVideoMaxBytes(int bytes) async {
    _videoMax = bytes;
    await VideoDiskCache.init(bytes);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kVideoPref, bytes);
    await VideoDiskCache.enforce(bytes);
  }

  static Future<void> setMaxBytes(int bytes) async {
    _max = bytes;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kPref, bytes);
  }

  static Future<StorageStats> getStats() async {
    final img      = await OfflineImageCache.totalBytes();
    final scrobble = await ScrobblesFileCache.getDiskUsageBytes();
    final api      = DataCache.estimateDiskBytes();
    final video    = await VideoDiskCache.totalBytes();
    return StorageStats(
      imageBytes:    img,
      scrobbleBytes: scrobble,
      apiBytes:      api,
      videoBytes:    video,
      maxBytes:      _max,
      videoMaxBytes: _videoMax,
    );
  }

  // Call after writing new data: LRU eviction of photos down to their own
  // limit (videos are trimmed by VideoDiskCache itself).
  static Future<void> enforceQuota() async {
    if (_max <= 0) return;
    final images   = await OfflineImageCache.totalBytes();
    final overflow = images - _max;
    if (overflow > 0) await OfflineImageCache.evictLru(overflow);
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
