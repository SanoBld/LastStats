// lib/widgets/skeleton.dart
// ══════════════════════════════════════════════════════════════════════════
//  Skeleton loaders (grey boxes with a soft pulse).
//  Use them instead of a spinner so the layout stays stable while loading
//  and content does not pop in and jump around.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/extra_strings.dart' show tx;
import '../theme/m3_motion.dart';
import 'm3_components.dart' show m3ImageShape;

/// Makes everything inside it pulse softly.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});
  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 1.0, end: 0.5)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion → no pulse.
    if (M3Motion.reduced(context)) return widget.child;
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// One grey rounded box.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 10,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A big pulsing card. Good for a chart or an image while it loads.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, this.height = 160, this.radius = 16});
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          SkeletonPulse(child: SkeletonBox(height: height, radius: radius)),
          const M3Loader(size: 44),
        ],
      );
}

/// A full page list of loading rows (square picture + 2 lines).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 8, this.header = false});
  final int rows;
  final bool header; // big card on top (for chart pages)

  @override
  Widget build(BuildContext context) {
    final list = SkeletonPulse(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            if (header) ...[
              const SkeletonBox(height: 180, radius: 20),
              const SizedBox(height: 20),
            ],
            for (int i = 0; i < rows; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  SkeletonBox(width: 48, height: 48, radius: 10),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 14),
                        SizedBox(height: 8),
                        SkeletonBox(width: 120, height: 11),
                      ],
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
    // Loader always in the middle of the page, on top of the grey boxes.
    return Stack(children: [
      Positioned.fill(child: list),
      const Positioned.fill(child: M3Loader()),
    ]);
  }
}

// ── Loading indicator (wavy shape that spins and morphs) ───────────────────
// Material 3 Expressive style: a soft wavy shape inside a round container.
class M3LoadingIndicator extends StatefulWidget {
  const M3LoadingIndicator({super.key, this.size = 48, this.color, this.progress});
  final Animation<double>? progress; // set = this drives the spin (pull to refresh)
  final double size;
  final Color? color;   // set = only the bumpy shape, in this color (for buttons)

  @override
  State<M3LoadingIndicator> createState() => _M3LoadingIndicatorState();
}

class _M3LoadingIndicatorState extends State<M3LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.progress != null) return; // driven from outside
    // Reduced motion → still shape, no spin.
    if (M3Motion.reduced(context)) {
      _c.stop();
      _started = false;
    } else if (!_started) {
      _c.repeat();
      _started = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: tx('a11y_loading'),
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _LoaderPainter(
            progress: widget.progress ?? _c,
            container: widget.color == null ? scheme.primaryContainer : null,
            shape: widget.color ?? scheme.primary,
          ),
        ),
      ),
    );
  }
}

// The loader cycles through the app's own image shapes (cookie, circle,
// clover, arch, burst, squircle, leaf, oval). Each outline is sampled once
// into a radius per angle so two shapes can be blended point by point.
// Only the soft, rounded shapes: squircle, oval.
const _kLoaderShapeIds = [5, 7];
const _kLoaderSteps = 140;
final Map<int, List<double>> _loaderRadiiCache = {};

List<double> _loaderRadii(int index) =>
    _loaderRadiiCache.putIfAbsent(index, () {
      const side = 100.0;
      final path = m3ImageShape(index, side)
          .getOuterPath(const Rect.fromLTWH(0, 0, side, side));
      final c = const Offset(side / 2, side / 2);
      final bins = List<double>.filled(_kLoaderSteps, 0);
      for (final metric in path.computeMetrics()) {
        for (double d = 0; d < metric.length; d += 0.4) {
          final pos = metric.getTangentForOffset(d)!.position - c;
          var a = math.atan2(pos.dy, pos.dx);
          if (a < 0) a += math.pi * 2;
          final k = (a / (math.pi * 2) * _kLoaderSteps).floor() % _kLoaderSteps;
          final dist = pos.distance;
          if (dist > bins[k]) bins[k] = dist;
        }
      }
      for (var k = 0; k < _kLoaderSteps; k++) {
        if (bins[k] == 0) {
          bins[k] = bins[(k + _kLoaderSteps - 1) % _kLoaderSteps];
        }
      }
      final mx = bins.reduce(math.max);
      return [for (final v in bins) v / mx];
    });

class _LoaderPainter extends CustomPainter {
  _LoaderPainter({
    required this.progress,
    required this.container,
    required this.shape,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color? container;
  final Color shape;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    if (container != null) canvas.drawCircle(c, r, Paint()..color = container!);

    final t = progress.value;
    final n = _kLoaderShapeIds.length;
    final f = t * n;
    final i = f.floor() % n;
    final local = f - f.floor();
    // Hold the shape for a moment, then morph into the next one.
    final m = local < 0.35 ? 0.0 : Curves.easeInOutCubic.transform((local - 0.35) / 0.65);
    final rad = r * (container == null ? 0.95 : 0.58);
    final ra = _loaderRadii(_kLoaderShapeIds[i]),
        rb = _loaderRadii(_kLoaderShapeIds[(i + 1) % n]);
    const steps = _kLoaderSteps;
    final rs = List<double>.generate(steps, (k) => ra[k] * (1 - m) + rb[k] * m);
    final path = Path();
    for (var k = 0; k < steps; k++) {
      final th = k / steps * math.pi * 2;
      final p = Offset(math.cos(th), math.sin(th)) * (rad * rs[k]);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * math.pi * 2);
    canvas.drawPath(path, Paint()..color = shape);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoaderPainter old) =>
      old.container != container || old.shape != shape;
}


// ── Small loader that fits its parent ──────────────────────────────────────
// Drop-in for CircularProgressIndicator: takes the size of the SizedBox
// around it (32 when there is none).
class M3Spinner extends StatelessWidget {
  const M3Spinner({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final tight = box.hasTightWidth && box.hasTightHeight;
        final size = tight ? math.min(box.maxWidth, box.maxHeight) : 32.0;
        return Center(child: M3LoadingIndicator(size: size, color: color));
      });
}

// ── Image placeholder: soft box + small loader ─────────────────────────────
class M3ImagePlaceholder extends StatelessWidget {
  const M3ImagePlaceholder({super.key, this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      final w = width ?? (box.maxWidth.isFinite ? box.maxWidth : 48);
      final h = height ?? (box.maxHeight.isFinite ? box.maxHeight : 48);
      final size = (math.min(w, h) * 0.5).clamp(16.0, 56.0);
      return SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: scheme.surfaceContainerHigh,
          child: Center(child: M3LoadingIndicator(size: size)),
        ),
      );
    });
  }
}


// ── One loader for the whole app ───────────────────────────────────────────
// Same shape, same size, same fade + scale entrance on every page and chart.
class M3Loader extends StatelessWidget {
  const M3Loader({super.key, this.size = 48, this.label, this.color, this.shrink = false});
  final bool shrink; // true = only as big as its content (inside a card / dialog)
  final double size;
  final Widget? label;
  final Color? color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: M3Motion.emphasizedDecelerate,
        builder: (_, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.8 + 0.2 * v, child: child),
        ),
        child: _wrap(
          Column(mainAxisSize: MainAxisSize.min, children: [
            M3LoadingIndicator(size: size, color: color),
            if (label != null) ...[const SizedBox(height: 16), label!],
          ]),
        ),
      );

  Widget _wrap(Widget c) => shrink ? c : Center(child: c);
}

// ── One progress bar for the whole app ──────────────────────────────────────
// Rounded pill, two sizes (6 slim / 8 normal), value changes are animated.
class M3LinearProgress extends StatelessWidget {
  const M3LinearProgress({
    super.key,
    this.value,
    this.minHeight = 6,
    this.color,
    this.backgroundColor,
    this.valueColor,
  });
  final double? value; // null = unknown duration
  final double minHeight;
  final Color? color;
  final Color? backgroundColor;
  final Animation<Color?>? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = minHeight >= 8 ? 8.0 : 6.0;
    final fg = color ?? valueColor?.value ?? scheme.primary;
    final bg = backgroundColor ?? scheme.primary.withValues(alpha: 0.15);
    return ClipRRect(
      borderRadius: BorderRadius.circular(h / 2),
      child: value == null
          ? LinearProgressIndicator(minHeight: h, color: fg, backgroundColor: bg)
          : TweenAnimationBuilder<double>(
              tween: Tween(end: value!.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 400),
              curve: M3Motion.emphasizedDecelerate,
              builder: (_, v, _) => LinearProgressIndicator(
                  value: v, minHeight: h, color: fg, backgroundColor: bg),
            ),
    );
  }
}

// ── Pull-to-refresh with the app's own loader ───────────────────────────────
// Pull down at the top: the loader fades in and turns a little more with
// every bit you pull. Release past the mark: it spins while onRefresh runs,
// then fades out.
class M3Refresh extends StatefulWidget {
  const M3Refresh({super.key, required this.onRefresh, required this.child});
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<M3Refresh> createState() => _M3RefreshState();
}

class _M3RefreshState extends State<M3Refresh> with TickerProviderStateMixin {
  static const double _trigger = 80;
  final ValueNotifier<double> _pull = ValueNotifier(0);
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  late final AnimationController _vis =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  bool _refreshing = false;

  @override
  void dispose() {
    _pull.dispose();
    _spin.dispose();
    _vis.dispose();
    super.dispose();
  }

  void _setPull(double v) {
    _pull.value = v;
    if (v > 6) {
      if (_vis.status != AnimationStatus.forward && _vis.value < 1) _vis.forward();
      _spin.value = (v / _trigger * 0.75).clamp(0.0, 1.0); // turns while you pull
    } else if (_vis.value > 0 && _vis.status != AnimationStatus.reverse) {
      _vis.reverse();
    }
  }

  void _release() {
    _pull.value = 0;
    _vis.reverse();
  }

  bool _onScroll(ScrollNotification n) {
    // Only the outer scroll view, not nested lists.
    if (n.depth != 0 || _refreshing) return false;
    if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
      _setPull((_pull.value - n.overscroll).clamp(0.0, _trigger * 1.6));
    } else if (n is ScrollUpdateNotification) {
      final px = n.metrics.pixels;
      if (px < 0 && n.dragDetails != null) {
        _setPull((-px).clamp(0.0, _trigger * 1.6));
      } else if (px > 0 && _pull.value != 0) {
        _release();
      }
    } else if (n is ScrollEndNotification) {
      if (_pull.value >= _trigger) {
        _run();
      } else if (_pull.value != 0) {
        _release();
      }
    }
    return false;
  }

  Future<void> _run() async {
    setState(() => _refreshing = true);
    _pull.value = _trigger;
    if (!M3Motion.reduced(context)) _spin.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        await _vis.reverse();
        _spin.stop();
        _pull.value = 0;
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(children: [
        widget.child,
        Positioned(
          top: top + 8,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pull, _vis]),
              builder: (_, _) {
                final v = Curves.easeOut.transform(_vis.value);
                if (v == 0) return const SizedBox.shrink();
                final dy = _refreshing ? 28.0 : (_pull.value * 0.6).clamp(0.0, 56.0);
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, dy - 20),
                    child: Transform.scale(
                      scale: 0.5 + 0.5 * v,
                      child: Center(child: M3LoadingIndicator(size: 36, progress: _spin)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
