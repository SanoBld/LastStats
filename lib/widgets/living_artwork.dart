// 3D flip card, Pokémon-card style, used in the fullscreen artwork viewer.
// - drag with a finger, tilt the phone, or hover with a mouse: card leans
//   in 3D following the input, smoothed so it never feels jerky
// - pinch with two fingers to zoom slightly, smooth (replaces the old
//   automatic breathing-zoom loop — zoom is now user-driven only)
// - occasional tiny organic "tremble" on top of the tilt, so it doesn't
//   feel perfectly rigid/mechanical
// - soft moving glass-style highlight (real reflection, not a color band)
// - tap to flip and read info on the back
// Fixed width/height so layout is always stable (no more broken framing).
// Toggle: Settings > Appearance ("Pochettes animées" / livingArtworkNotifier).
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../app_state.dart';
import '../services/achievements.dart';

class Tilt3DCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double width, height;
  final double radius;
  // Achievement border: bronze → iridescent, based on play count.
  // CardTier.none = no border (default, unaffected layout).
  final CardTier tier;
  const Tilt3DCard({
    super.key,
    required this.front,
    required this.back,
    required this.width,
    required this.height,
    this.radius = 22,
    this.tier = CardTier.none,
  });

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard>
    with TickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Ticker _smoother;
  StreamSubscription<AccelerometerEvent>? _sub;


  // Raw input target, -1..1. Rendered values chase this smoothly.
  double _targetRx = 0, _targetRy = 0;
  double _rx = 0, _ry = 0;
  bool _dragging = false;

  // Pinch-to-zoom: subtle range only, smoothed like the tilt.
  double _targetZoom = 1.0;
  double _zoom = 1.0;
  double _zoomAtGestureStart = 1.0;

  // Sensor tilt is calibrated relative to a baseline instead of absolute
  // gravity, so holding the phone normally (vertical, in hand) doesn't
  // leave the card permanently leaning — only movement AWAY from wherever
  // the phone was when last recalibrated (tap) moves the card.
  double _lastAx = 0, _lastAy = 0;
  double _baseAx = 0, _baseAy = 0;
  bool   _calibrated = false;

  @override
  void initState() {
    super.initState();
    _smoother = createTicker(_onTick)..start();
    // Skip the accelerometer entirely in eco mode — no tilt parallax means
    // no sensor stream running, no extra wakeups.
    if (ecoModeActiveNotifier.value) return;
    try {
      _sub = accelerometerEventStream().listen((e) {
        _lastAx = e.x;
        _lastAy = e.y;
        if (!_calibrated) { _baseAx = e.x; _baseAy = e.y; _calibrated = true; }
        if (!mounted || _dragging || ecoModeActiveNotifier.value) return;
        _targetRx = ((e.y - _baseAy) / 4.2).clamp(-1.0, 1.0);
        _targetRy = ((_baseAx - e.x) / 4.2).clamp(-1.0, 1.0);
      }, onError: (_) {}, cancelOnError: true);
    } catch (_) {}
  }

  // Re-zero the baseline to the phone's current position, so tilting can
  // resume from wherever it's held now instead of an old fixed reference.
  void _recalibrate() {
    _baseAx = _lastAx;
    _baseAy = _lastAy;
    _targetRx = 0;
    _targetRy = 0;
  }

  // Frame-rate independent exponential smoothing: rendered rx/ry/zoom ease
  // towards their targets instead of snapping.
  Duration? _lastTick;
  void _onTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dtMs = (elapsed - last).inMilliseconds.clamp(1, 64);

    final t  = 1 - math.pow(1 - 0.22, dtMs / 16.0).toDouble();
    final tz = 1 - math.pow(1 - 0.18, dtMs / 16.0).toDouble();
    final nrx = _rx   + (_targetRx   - _rx)   * t;
    final nry = _ry   + (_targetRy   - _ry)   * t;
    final nz  = _zoom + (_targetZoom - _zoom) * tz;
    if ((nrx - _rx).abs() > 0.0005 || (nry - _ry).abs() > 0.0005 ||
        (nz - _zoom).abs() > 0.0005) {
      setState(() { _rx = nrx; _ry = nry; _zoom = nz; });
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _smoother.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _tiltFromLocal(Offset local) {
    _targetRy = ((local.dx / widget.width) - 0.5) * 2;
    _targetRx = -((local.dy / widget.height) - 0.5) * 2;
  }

  void _resetTilt() {
    _dragging = false;
    _recalibrate();
  }

  void _toggleFlip() {
    _recalibrate();
    if (_flip.value < 0.5) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  void _onScaleStart(ScaleStartDetails d) {
    _dragging = true;
    _zoomAtGestureStart = _targetZoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2) {
      // Two fingers: pinch-zoom. Small range only ("seulement un peu").
      _targetZoom = (_zoomAtGestureStart * d.scale).clamp(1.0, 1.12);
    } else {
      _tiltFromLocal(d.localFocalPoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: livingArtworkNotifier,
      builder: (context, enabled, _) {
        final radius = BorderRadius.circular(widget.radius);
        final effTier = achievementsEnabledNotifier.value ? widget.tier : CardTier.none;
        return MouseRegion(
          onHover: enabled ? (e) => _tiltFromLocal(e.localPosition) : null,
          onExit: enabled ? (_) => _resetTilt() : null,
          child: GestureDetector(
            onTap: _toggleFlip,
            onScaleStart:  enabled ? _onScaleStart : null,
            onScaleUpdate: enabled ? _onScaleUpdate : null,
            onScaleEnd:    enabled ? (_) => _resetTilt() : null,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final flipAngle = _flip.value * math.pi;
                  final showFront = flipAngle <= math.pi / 2;
                  // Full-range tilt: up to ~35° so a real phone pitch reads
                  // as the card leaning all the way, not a tiny nudge.
                  // Jitter is added on top for a slightly organic feel.
                  final effRx = _rx;
                  final effRy = _ry;
                  final tiltX = enabled ? effRx * 0.62 : 0.0;
                  final tiltY = enabled ? effRy * 0.62 : 0.0;
                  final zoom  = enabled ? _zoom : 1.0;

                  final m = Matrix4.identity()
                    ..setEntry(3, 2, 0.0016)
                    ..scale(zoom)
                    ..rotateX(tiltX)
                    ..rotateY(flipAngle + tiltY);

                  final side = showFront
                      ? (enabled
                          // Very light parallax: the artwork shifts a few
                          // pixels opposite the tilt, oversized slightly so
                          // no edge gap ever shows through the clip.
                          ? Transform.translate(
                              offset: Offset(-effRy * 7, -effRx * 7),
                              child: Transform.scale(scale: 1.05, child: widget.front),
                            )
                          : widget.front)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: widget.back,
                        );

                  return Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: Container(
                      decoration: effTier == CardTier.none ? null : BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          colors: tierGradient(effTier)!,
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                          begin: Alignment(-1 - effRy * 0.7, -1 - effRx * 0.7),
                          end: Alignment(1 - effRy * 0.7, 1 - effRx * 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tierGradient(effTier)![1].withValues(alpha: 0.45),
                            blurRadius: 16, spreadRadius: -2,
                          ),
                        ],
                      ),
                      // Thicker rim so the tier border reads as a real edge.
                      padding: effTier == CardTier.none
                          ? EdgeInsets.zero : const EdgeInsets.all(4.5),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            side,
                            if (enabled && showFront)
                              IgnorePointer(
                                child: _GlassReflection(
                                  rx: effRx, ry: effRy,
                                  width: widget.width, height: widget.height,
                                ),
                              ),
                          ],
                        ),
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

// Soft light patch that slides across the artwork as the card tilts,
// like a real reflection off glass rather than a fixed diagonal band.
class _GlassReflection extends StatelessWidget {
  final double rx, ry;
  final double width, height;
  const _GlassReflection({
    required this.rx, required this.ry,
    required this.width, required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // The light source stays put, so the highlight moves opposite the tilt.
    final ax = (-ry).clamp(-1.0, 1.0);
    final ay = (-rx * 0.8 - 0.25).clamp(-1.0, 1.0);
    final strength = math.sqrt(rx * rx + ry * ry).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment(ax, ay),
      child: Container(
        width: width * 1.3,
        height: height * 0.6,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.22 + strength * 0.16),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
