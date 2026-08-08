// 3D flip card, Pokémon-card style, used in the fullscreen artwork viewer.
// - drag with a finger, tilt the phone, or hover with a mouse: card leans
//   in 3D following the input
// - tap to flip and read info on the back
// Fixed width/height so layout is always stable (no more broken framing).
// Toggle: Settings > Appearance ("Pochettes animées" / livingArtworkNotifier).
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../app_state.dart';

class Tilt3DCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double width, height;
  final double radius;
  const Tilt3DCard({
    super.key,
    required this.front,
    required this.back,
    required this.width,
    required this.height,
    this.radius = 22,
  });

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  StreamSubscription<AccelerometerEvent>? _sub;

  double _rx = 0, _ry = 0;  // tilt, -1..1
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    try {
      _sub = accelerometerEventStream().listen((e) {
        if (!mounted || _dragging) return;
        setState(() {
          _rx = (e.y / 9.8).clamp(-1, 1);
          _ry = (-e.x / 9.8).clamp(-1, 1);
        });
      }, onError: (_) {}, cancelOnError: true);
    } catch (_) {}
  }

  @override
  void dispose() { _flip.dispose(); _sub?.cancel(); super.dispose(); }

  void _tiltFromLocal(Offset local) {
    setState(() {
      _ry = ((local.dx / widget.width) - 0.5) * 2;
      _rx = -((local.dy / widget.height) - 0.5) * 2;
    });
  }

  void _resetTilt() {
    _dragging = false;
    setState(() { _rx = 0; _ry = 0; });
  }

  void _toggleFlip() {
    if (_flip.value < 0.5) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: livingArtworkNotifier,
      builder: (context, enabled, _) {
        final radius = BorderRadius.circular(widget.radius);
        return MouseRegion(
          onHover: enabled ? (e) => _tiltFromLocal(e.localPosition) : null,
          onExit: enabled ? (_) => _resetTilt() : null,
          child: GestureDetector(
            onTap: _toggleFlip,
            onPanStart: enabled ? (_) => _dragging = true : null,
            onPanUpdate: enabled ? (d) => _tiltFromLocal(d.localPosition) : null,
            onPanEnd: enabled ? (_) => _resetTilt() : null,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final flipAngle = _flip.value * math.pi;
                  final showFront = flipAngle <= math.pi / 2;
                  final tiltX = enabled ? _rx * 0.28 : 0.0;
                  final tiltY = enabled ? _ry * 0.28 : 0.0;

                  final m = Matrix4.identity()
                    ..setEntry(3, 2, 0.0018)
                    ..rotateX(tiltX)
                    ..rotateY(flipAngle + tiltY);

                  final side = showFront
                      ? widget.front
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: widget.back,
                        );

                  return Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          side,
                          if (enabled && showFront)
                            IgnorePointer(child: _HoloSheen(rx: _rx, ry: _ry)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// Diagonal light band that follows the tilt direction, like the foil
// sheen on a holographic trading card. Front side only.
class _HoloSheen extends StatelessWidget {
  final double rx, ry;
  const _HoloSheen({required this.rx, required this.ry});

  @override
  Widget build(BuildContext context) {
    final strength = math.sqrt(rx * rx + ry * ry).clamp(0.0, 1.0);
    return Opacity(
      opacity: 0.05 + strength * 0.22,
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
