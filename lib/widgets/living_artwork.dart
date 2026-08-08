// Small "alive" effect for artwork thumbnails (title/artist/album cards).
// Only uses Transform, which never changes layout size — safe to drop
// inside any existing card without breaking rows/text next to it.
// Tilt reacts to the phone's accelerometer when available, and to
// mouse/touch drag on desktop/web where there is no sensor.
// Can be turned off in Settings > Appearance (livingArtworkNotifier).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../app_state.dart';

class LivingArtwork extends StatefulWidget {
  final Widget child;
  final double size; // must match the child's fixed width/height
  const LivingArtwork({super.key, required this.child, required this.size});

  @override
  State<LivingArtwork> createState() => _LivingArtworkState();
}

class _LivingArtworkState extends State<LivingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle;
  StreamSubscription<AccelerometerEvent>? _sub;
  double _tiltX = 0, _tiltY = 0; // from sensor
  double _dragX = 0, _dragY = 0; // from pointer, desktop/web fallback

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    // Best-effort only: any platform/plugin issue here must never
    // affect the rest of the widget tree.
    try {
      _sub = accelerometerEventStream().listen((e) {
        if (!mounted) return;
        setState(() {
          _tiltX = _tiltX * 0.85 + (e.x / 12).clamp(-1, 1) * 0.15;
          _tiltY = _tiltY * 0.85 + (e.y / 12).clamp(-1, 1) * 0.15;
        });
      }, onError: (_) {}, cancelOnError: true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _idle.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _onHover(PointerEvent e, BoxConstraints c) {
    final dx = (e.localPosition.dx / c.maxWidth - 0.5) * 2;   // -1..1
    final dy = (e.localPosition.dy / c.maxHeight - 0.5) * 2;  // -1..1
    setState(() { _dragX = dx.clamp(-1, 1); _dragY = dy.clamp(-1, 1); });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: livingArtworkNotifier,
      builder: (context, enabled, _) {
        if (!enabled) return widget.child;

        final maxShift = widget.size * 0.06;
        return LayoutBuilder(
          builder: (context, c) => ClipRect(
            child: MouseRegion(
              onHover: (e) => _onHover(e, c),
              onExit: (_) => setState(() { _dragX = 0; _dragY = 0; }),
              child: AnimatedBuilder(
                animation: _idle,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    (_tiltX + _dragX).clamp(-1, 1) * maxShift,
                    (-_tiltY + _dragY).clamp(-1, 1) * maxShift,
                  ),
                  child: Transform.scale(
                    scale: 1.08 + _idle.value * 0.05,
                    child: child,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
