// Small "alive" effect for artwork thumbnails (title/artist/album cards).
// Only uses Transform, which never changes layout size — so it is safe
// to drop inside any existing card without breaking rows/text next to it.
// Tilt reacts to the phone's accelerometer when available, and silently
// does nothing (still shows the idle zoom) if the sensor is not.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  double _tiltX = 0, _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
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

  @override
  Widget build(BuildContext context) {
    final maxShift = widget.size * 0.035; // small, always fits inside clip
    return ClipRect(
      child: AnimatedBuilder(
        animation: _idle,
        builder: (context, child) => Transform.translate(
          offset: Offset(_tiltX * maxShift, -_tiltY * maxShift),
          child: Transform.scale(
            scale: 1.04 + _idle.value * 0.02,
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
