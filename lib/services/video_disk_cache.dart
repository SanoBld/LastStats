// lib/services/video_disk_cache.dart
// Disk cache for Apple Music motion artwork (animated covers).
// Native implementation on Android only; other platforms keep streaming.
export 'video_disk_cache_stub.dart'
    if (dart.library.io) 'video_disk_cache_native.dart';
