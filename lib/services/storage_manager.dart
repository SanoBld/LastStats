// lib/services/storage_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_image_cache.dart';
import 'data_cache.dart';
import 'scrobbles_file_cache.dart';

// 0 means no limit.
const int kStorageNoLimit = 0;

class StorageStats {
  final int imageBytes;
  final int scrobbleBytes;
  final int apiBytes;
  final int maxBytes;

  const StorageStats({
    required this.imageBytes,
    required this.scrobbleBytes,
    required this.apiBytes,
    required this.maxBytes,
  });

  int get totalBytes => imageBytes + scrobbleBytes + apiBytes;

  // 0.0–1.0, or 0 when unlimited.
  double get usedFraction {
    if (maxBytes <= 0) return 0;
    return (totalBytes / maxBytes).clamp(0.0, 1.0);
  }
}

class StorageManager {
  StorageManager._();

  static const _kPref    = 'ls_max_storage_bytes';
  static const defaultMax = 500 * 1024 * 1024; // 500 MB

  static int _max = defaultMax;
  static int get maxBytes => _max;

  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _max = p.getInt(_kPref) ?? defaultMax;
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
    return StorageStats(
      imageBytes:    img,
      scrobbleBytes: scrobble,
      apiBytes:      api,
      maxBytes:      _max,
    );
  }

  // Call after writing new data to enforce the storage quota via LRU eviction.
  static Future<void> enforceQuota() async {
    if (_max <= 0) return;
    final stats    = await getStats();
    final overflow = stats.totalBytes - _max;
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
