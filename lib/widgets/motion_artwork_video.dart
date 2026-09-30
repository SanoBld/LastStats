// Silent, looping video drawn on top of the static cover (Apple Music
// motion artwork). Stays invisible until the first frame is ready and
// disappears again on any error, so the static image is always the fallback.
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/video_disk_cache.dart';

class MotionArtworkVideo extends StatefulWidget {
  final String url;
  const MotionArtworkVideo({super.key, required this.url});

  // Live players, so Settings > Cache can show the video memory in use.
  static final Set<VideoPlayerController> _live = {};
  static int get liveCount => _live.length;

  /// Rough decoded-frame memory: width x height x 4 bytes x ~4 buffered frames.
  static int get liveBytes {
    var total = 0;
    for (final c in _live) {
      final s = c.value.size;
      total += (s.width * s.height * 4 * 4).round();
    }
    return total;
  }

  /// Stops and releases every running player (the widgets fall back to the
  /// static cover until they are rebuilt).
  static Future<void> releaseAll() async {
    for (final c in _live.toList()) {
      try { await c.pause(); } catch (_) {}
    }
  }

  @override
  State<MotionArtworkVideo> createState() => _MotionArtworkVideoState();
}

class _MotionArtworkVideoState extends State<MotionArtworkVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    VideoPlayerController? c;
    final options = VideoPlayerOptions(mixWithOthers: true);
    var fromDisk = false;
    try {
      // Prefer the on-disk copy (offline, no re-download); else stream.
      // mixWithOthers: never interrupt the user's music or the 30s preview.
      c = await VideoDiskCache.localController(widget.url, options);
      fromDisk = c != null;
      c ??= VideoPlayerController.networkUrl(Uri.parse(widget.url),
          videoPlayerOptions: options);
      _c = c;
      try {
        await c.initialize();
      } catch (_) {
        if (!fromDisk) rethrow;
        // Corrupt/unreadable local copy: fall back to streaming.
        await c.dispose();
        c = VideoPlayerController.networkUrl(Uri.parse(widget.url),
            videoPlayerOptions: options);
        _c = c;
        fromDisk = false;
        await c.initialize();
      }
      if (!fromDisk) VideoDiskCache.storeInBackground(widget.url);
      // The widget may have been removed while the stream was loading:
      // release the player right away instead of leaking it.
      if (_disposed) { await c.dispose(); return; }
      MotionArtworkVideo._live.add(c);
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Unsupported stream / network error: keep the static cover.
      if (mounted) setState(() => _ready = false);
    }
  }

  // No decoding in the background: saves battery, CPU and video memory.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _c;
    if (c == null || !_ready || _disposed) return;
    if (state == AppLifecycleState.resumed) {
      c.play();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      c.pause();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final c = _c;
    if (c != null) {
      MotionArtworkVideo._live.remove(c);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _ready ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: (c == null || !_ready)
            ? const SizedBox.expand()
            : FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
      ),
    );
  }
}
