// Silent, looping video drawn on top of the static cover (Apple Music
// motion artwork). Stays invisible until the first frame is ready and
// disappears again on any error, so the static image is always the fallback.
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/motion_artwork_service.dart';
import '../services/video_disk_cache.dart';
import '../services/data_cache.dart';

class MotionArtworkVideo extends StatefulWidget {
  final String url;
  // Called once when the video cannot be played (refused link, unsupported
  // stream, network error), so the page can drop its photo/video toggle
  // instead of offering a video that never starts.
  final VoidCallback? onFailed;
  const MotionArtworkVideo(
      {super.key, required this.url, this.onFailed});

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

  // YouTube links end with "#yt=<start>,<len>" (seconds), optionally
  // followed by "&fb=<url-encoded fallback link>" (the safe 360p stream).
  late final int _ytAt = widget.url.indexOf('#yt=');
  late final String _url =
      _ytAt < 0 ? widget.url : widget.url.substring(0, _ytAt);
  int _ytStart = 0, _ytLen = 12;
  String? _fbUrl;

  Future<void> _init() async {
    final options = VideoPlayerOptions(mixWithOthers: true);
    final isYt = _ytAt >= 0;
    if (isYt) {
      final tail = widget.url.substring(_ytAt + 4);
      final fbAt = tail.indexOf('&fb=');
      final head = fbAt < 0 ? tail : tail.substring(0, fbAt);
      if (fbAt >= 0) _fbUrl = Uri.decodeComponent(tail.substring(fbAt + 4));
      final p = head.split(',');
      _ytStart = int.tryParse(p.first) ?? 0;
      if (p.length > 1) _ytLen = int.tryParse(p[1]) ?? 12;
    }
    // Main link first; for YouTube, the safe 360p link if the main one
    // is refused or never starts.
    for (final url in [_url, if (_fbUrl != null) _fbUrl!]) {
      if (_disposed) return;
      try {
        if (await _open(url, isYt, options)) return;
      } catch (_) {}
    }
    // Nothing plays: keep the static cover and tell the page, which hides
    // its video toggle.
    if (mounted && !_disposed) {
      setState(() => _ready = false);
      widget.onFailed?.call();
    }
  }

  // Tries one link. True = playing (or the widget is gone), false = failed.
  Future<bool> _open(
      String url, bool isYt, VideoPlayerOptions options) async {
    VideoPlayerController? c;
    var fromDisk = false;
    try {
      // Prefer the on-disk copy (offline, no re-download); else stream.
      // mixWithOthers: never interrupt the user's music or the 30s preview.
      // YouTube links expire and are never cached.
      if (!isYt) c = await VideoDiskCache.localController(url, options);
      fromDisk = c != null;
      if (c == null && DataCache.strictOffline) return false;
      // YouTube refuses links sent with another User-Agent than the client
      // that produced them.
      c ??= VideoPlayerController.networkUrl(Uri.parse(url),
          httpHeaders: isYt
              ? {'User-Agent': MotionArtworkService.ytUserAgentFor(url)}
              : const <String, String>{},
          videoPlayerOptions: options);
      try {
        await c.initialize().timeout(const Duration(seconds: 12));
      } catch (_) {
        if (!fromDisk) rethrow;
        // Corrupt/unreadable local copy: fall back to streaming.
        await c.dispose();
        c = VideoPlayerController.networkUrl(Uri.parse(url),
            videoPlayerOptions: options);
        fromDisk = false;
        await c.initialize().timeout(const Duration(seconds: 12));
      }
      // The widget may have been removed while the stream was loading:
      // release the player right away instead of leaking it.
      if (_disposed) { await c.dispose(); return true; }
      await c.setVolume(0);
      final from = Duration(seconds: isYt ? _ytStart : 0);
      if (isYt) {
        // Loop one short moment of the clip instead of the whole video.
        await c.setLooping(false);
        if (from > Duration.zero) await c.seekTo(from);
      } else {
        await c.setLooping(true);
      }
      await c.play();
      // A YouTube link can open fine and then be refused while reading:
      // only accept it once the picture really moves.
      if (isYt && !await _confirmPlaying(c, from)) {
        await c.dispose();
        return _disposed;
      }
      if (_disposed) { await c.dispose(); return true; }
      _c = c;
      MotionArtworkVideo._live.add(c);
      if (isYt) {
        final ctl = c;
        ctl.addListener(() {
          final v = ctl.value;
          if (!v.isInitialized || _disposed) return;
          if (v.hasError) {
            if (mounted && _ready) setState(() => _ready = false);
            return;
          }
          if (v.position.inSeconds >= _ytStart + _ytLen ||
              (v.position >= v.duration && !v.isPlaying)) {
            ctl.seekTo(Duration(seconds: _ytStart));
            ctl.play();
          }
        });
      } else if (!fromDisk) {
        VideoDiskCache.storeInBackground(url);
      }
      if (mounted) setState(() => _ready = true);
      return true;
    } catch (_) {
      try { await c?.dispose(); } catch (_) {}
      return false;
    }
  }

  // Waits (max 10 s) until the video really advances past [from].
  Future<bool> _confirmPlaying(
      VideoPlayerController c, Duration from) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline)) {
      if (_disposed) return false;
      final v = c.value;
      if (v.hasError) return false;
      if (v.isPlaying &&
          v.position > from + const Duration(milliseconds: 250)) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return false;
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
