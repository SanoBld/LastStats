// Wraps an image (album art, header, etc) and makes it feel "alive":
// - slow idle zoom/breathing loop (Ken Burns style)
// - parallax shift driven by phone tilt (accelerometer), with a
//   pointer-drag fallback on desktop/web where there is no sensor
// - soft diagonal gloss sweep on top
//
// Kept as a single small file so it can wrap any image widget:
//   LivingArtwork(child: Image.network(url))
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class LivingArtwork extends StatefulWidget {
  final Widget child;
  final double intensity; // parallax strength in logical pixels
  final bool zoom;        // enable idle breathing zoom
  final bool gloss;       // enable gloss sweep overlay
  final BorderRadius? borderRadius;

  const LivingArtwork({
    super.key,
    required this.child,
    this.intensity = 6,
    this.zoom = true,
    this.gloss = true,
    this.borderRadius,
  });

  @override
  State<LivingArtwork> createState() => _LivingArtworkState();
}

class _LivingArtworkState extends State<LivingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleCtrl;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // Smoothed tilt offset, -1..1 on each axis.
  double _tiltX = 0, _tiltY = 0;
  // Pointer-drag fallback offset (desktop/web without sensors).
  double _dragX = 0, _dragY = 0;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Sensor is not available everywhere (web, desktop, emulators without
    // it) — fail silently and just keep the drag fallback.
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen((event) {
        if (!mounted) return;
        setState(() {
          // Low-pass filter so the motion stays smooth, not jittery.
          _tiltX = _tiltX * 0.85 + (event.x / 10).clamp(-1, 1) * 0.15;
          _tiltY = _tiltY * 0.85 + (event.y / 10).clamp(-1, 1) * 0.15;
        });
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  void _onPan(Offset delta) {
    setState(() {
      _dragX = (_dragX + delta.dx / 40).clamp(-1.0, 1.0);
      _dragY = (_dragY + delta.dy / 40).clamp(-1.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    final offsetX = (_tiltX + _dragX).clamp(-1.0, 1.0) * widget.intensity;
    final offsetY = (-_tiltY + _dragY).clamp(-1.0, 1.0) * widget.intensity;

    return ClipRRect(
      borderRadius: radius,
      child: GestureDetector(
        onPanUpdate: (d) => _onPan(d.delta),
        child: AnimatedBuilder(
          animation: _idleCtrl,
          builder: (context, _) {
            final breathe =
                widget.zoom ? 1.0 + _idleCtrl.value * 0.035 : 1.0;
            return Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: Transform.scale(
                scale: breathe + 0.06, // small margin so parallax has room
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.child,
                    if (widget.gloss) _GlossSweep(progress: _idleCtrl.value),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Thin diagonal light band that drifts across the artwork very slowly.
class _GlossSweep extends StatelessWidget {
  final double progress; // 0..1, comes from the shared idle controller
  const _GlossSweep({required this.progress});

  @override
  Widget build(BuildContext context) {
    final t = (math.sin(progress * math.pi * 2) + 1) / 2; // 0..1 smooth
    return IgnorePointer(
      child: Opacity(
        opacity: 0.10,
        child: Align(
          alignment: Alignment(-1.5 + t * 3, -1),
          child: Transform.rotate(
            angle: -0.6,
            child: Container(
              width: 40,
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white,
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
