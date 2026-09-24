// Silent, looping video drawn on top of the static cover (Apple Music
// motion artwork). Stays invisible until the first frame is ready and
// disappears again on any error, so the static image is always the fallback.
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MotionArtworkVideo extends StatefulWidget {
  final String url;
  const MotionArtworkVideo({super.key, required this.url});

  @override
  State<MotionArtworkVideo> createState() => _MotionArtworkVideoState();
}

class _MotionArtworkVideoState extends State<MotionArtworkVideo> {
  VideoPlayerController? _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // mixWithOthers: never interrupt the user's music or the 30s preview.
      final c = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _c = c;
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Unsupported stream / network error: keep the static cover.
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
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
