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
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, TileMode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../app_state.dart';
import '../services/achievements.dart';
import '../theme/m3_motion.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

class Tilt3DCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double width, height;
  final double radius;
  // Achievement border: bronze → iridescent, based on play count.
  // CardTier.none = no border (default, unaffected layout).
  final CardTier tier;
  // Small tier pill (medal + name) on the front. Off where the front already
  // spells the tier out (badge viewer).
  final bool showTierChip;
  // Material You frame: a tonal rounded card around the artwork (like an M3
  // filled card). [frameColor] defaults to surfaceContainerHigh.
  final bool framed;
  final Color? frameColor;
  const Tilt3DCard({
    super.key,
    required this.front,
    required this.back,
    required this.width,
    required this.height,
    this.radius = 28,
    this.tier = CardTier.none,
    this.showTierChip = true,
    this.framed = false,
    this.frameColor,
  });

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard>
    with TickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  // One-shot entrance: the card rises, grows and sharpens into place.
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650))..forward();
  late final Ticker _smoother;
  StreamSubscription<AccelerometerEvent>? _sub;


  // Raw input target, -1..1. Rendered values chase this smoothly.
  double _targetRx = 0, _targetRy = 0;
  double _rx = 0, _ry = 0;
  bool _dragging = false;

  // Pinch-to-zoom, smoothed like the tilt. Kept small so tilting the card
  // never pushes the art past the camera near the edges.
  static const double _minZoom = 1.0;
  static const double _maxZoom = 1.25;
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
    // Skip the accelerometer entirely in eco mode, and on desktop — there's
    // no accelerometer there, mouse hover already drives the tilt, and the
    // sensors_plus channel can hang/throw repeatedly on Windows/Linux.
    if (ecoModeActiveNotifier.value || _isDesktop) return;
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
    _intro.dispose();
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
      // Two fingers: pinch-zoom, wide range.
      _targetZoom = (_zoomAtGestureStart * d.scale).clamp(_minZoom, _maxZoom);
    } else {
      _tiltFromLocal(d.localFocalPoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    if (M3Motion.reduced(context)) return card;
    return AnimatedBuilder(
      animation: _intro,
      child: card,
      builder: (_, c) {
        final k = M3Motion.spatialDefault.transform(_intro.value.clamp(0.0, 1.0));
        final sg = M3Motion.blurOn ? 10.0 * (1 - _intro.value) : 0.0;
        return Opacity(
          opacity: Curves.easeOut.transform((_intro.value * 2).clamp(0.0, 1.0)),
          child: ImageFiltered(
            enabled: sg > 0.3,
            imageFilter: ImageFilter.blur(sigmaX: sg, sigmaY: sg, tileMode: TileMode.decal),
            child: Transform.translate(
              offset: Offset(0, 48 * (1 - k)),
              child: Transform.scale(scale: 0.86 + 0.14 * k, child: c),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: livingArtworkNotifier,
      builder: (context, enabled, _) {
        final radius = BorderRadius.circular(widget.radius);
        final cs = Theme.of(context).colorScheme;
        final frameC = widget.frameColor ?? cs.surfaceContainerHigh;
        final pad = widget.framed ? 9.0 : 0.0;
        final inner = BorderRadius.circular(math.max(8.0, widget.radius - pad));
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
                    ..scaleByDouble(zoom, zoom, zoom, 1.0)
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
                      padding: EdgeInsets.all(pad),
                      decoration: BoxDecoration(
                        color: widget.framed ? frameC : null,
                        borderRadius: radius,
                        // Depth: shadow slides opposite to the tilt, plus a
                        // soft tonal glow so the card sits in the theme.
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 38, spreadRadius: -8,
                            offset: Offset(-effRy * 12, 18 + effRx * 8),
                          ),
                          if (widget.framed)
                            BoxShadow(
                              color: frameC.withValues(alpha: 0.35),
                              blurRadius: 44, spreadRadius: -4,
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: inner,
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
                            if (showFront && !widget.framed)
                              IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: inner,
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        width: 1.5),
                                  ),
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
              Colors.white.withValues(alpha: 0.12 + strength * 0.10),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}


// ── Grade info, shown OUTSIDE (under) the card ──────────────────────────────
// Arch-shaped tonal card in the tier's Material You colour (big top corners,
// small bottom ones, like the widget cards): dark round medal, grade name,
// plays, and a progress bar towards the next grade.
class TierInfoCard extends StatelessWidget {
  final CardTier tier;
  final String title, subtitle;
  final double? progress; // 0..1, null = hide the bar
  final double? width;
  final VoidCallback? onTap;
  const TierInfoCard({
    super.key,
    required this.tier,
    required this.title,
    required this.subtitle,
    this.progress,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = tierGradient(tier);
    if (g == null) return const SizedBox.shrink();
    final base = g[1];
    final on = tierOnColor(tier);
    return SizedBox(
      width: width,
      child: Material(
        color: base,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30),
            bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: on, shape: BoxShape.circle),
                child: Icon(Icons.workspace_premium_rounded, size: 26, color: base),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, height: 1.1,
                            fontWeight: FontWeight.w800, color: on)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: on.withValues(alpha: 0.72))),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress, minHeight: 5,
                          backgroundColor: on.withValues(alpha: 0.16),
                          valueColor: AlwaysStoppedAnimation(on),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 10),
                Icon(Icons.info_outline_rounded, size: 20,
                    color: on.withValues(alpha: 0.7)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
