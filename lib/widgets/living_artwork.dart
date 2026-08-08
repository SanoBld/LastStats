// 3D tilt card, Pokémon-card style, used in the fullscreen artwork viewer.
// Tilts on phone movement (accelerometer) and on mouse hover (desktop/web).
// A holographic sheen sweeps across the cover following the tilt angle.
// Toggle: Settings > Appearance ("Pochettes animées" / livingArtworkNotifier).
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../app_state.dart';

class Tilt3DCard extends StatefulWidget {
  final Widget child;
  const Tilt3DCard({super.key, required this.child});

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  StreamSubscription<AccelerometerEvent>? _sub;

  // Current tilt, -1..1 on each axis.
  double _rx = 0, _ry = 0;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    try {
      _sub = accelerometerEventStream().listen((e) {
        if (!mounted || _hovering) return; // pointer takes priority when present
        setState(() {
          _rx = (e.y / 9.8).clamp(-1, 1);
          _ry = (-e.x / 9.8).clamp(-1, 1);
        });
      }, onError: (_) {}, cancelOnError: true);
    } catch (_) {}
  }

  @override
  void dispose() { _spring.dispose(); _sub?.cancel(); super.dispose(); }

  void _setTiltFromLocal(Offset local, Size size) {
    setState(() {
      _ry = ((local.dx / size.width) - 0.5) * 2;   // left/right
      _rx = -((local.dy / size.height) - 0.5) * 2;  // up/down
    });
  }

  void _resetTilt() {
    _hovering = false;
    setState(() { _rx = 0; _ry = 0; });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: livingArtworkNotifier,
      builder: (context, enabled, _) {
        if (!enabled) return widget.child;
        return LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            return MouseRegion(
              onEnter: (_) => _hovering = true,
              onHover: (e) => _setTiltFromLocal(e.localPosition, size),
              onExit: (_) => _resetTilt(),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 120),
                builder: (context, _, __) {
                  final angleX = _rx * 0.35; // radians, ~20°
                  final angleY = _ry * 0.35;
                  final m = Matrix4.identity()
                    ..setEntry(3, 2, 0.0016) // perspective
                    ..rotateX(angleX)
                    ..rotateY(angleY);
                  return Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        widget.child,
                        IgnorePointer(
                          child: _HoloSheen(rx: _rx, ry: _ry),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// Diagonal light band that follows the tilt direction, like the foil
// sheen on a holographic trading card.
class _HoloSheen extends StatelessWidget {
  final double rx, ry;
  const _HoloSheen({required this.rx, required this.ry});

  @override
  Widget build(BuildContext context) {
    final strength = math.sqrt(rx * rx + ry * ry).clamp(0.0, 1.0);
    return Opacity(
      opacity: 0.05 + strength * 0.20,
      child: Align(
        alignment: Alignment(ry, rx),
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 500,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white,
                  Colors.cyanAccent.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
