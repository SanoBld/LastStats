// lib/widgets/skeleton.dart
// ══════════════════════════════════════════════════════════════════════════
//  Skeleton loaders (grey boxes with a soft pulse).
//  Use them instead of a spinner so the layout stays stable while loading
//  and content does not pop in and jump around.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/m3_motion.dart';
import '../theme/m3_shapes.dart';

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
          const M3LoadingIndicator(size: 44),
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
      const Positioned.fill(child: Center(child: M3LoadingIndicator(size: 72))),
    ]);
  }
}

// ── Loading indicator (wavy shape that spins and morphs) ───────────────────
// Material 3 Expressive style: a soft wavy shape inside a round container.
class M3LoadingIndicator extends StatefulWidget {
  const M3LoadingIndicator({super.key, this.size = 48, this.color});
  final double size;
  final Color? color;   // set = only the bumpy shape, in this color (for buttons)

  @override
  State<M3LoadingIndicator> createState() => _M3LoadingIndicatorState();
}

class _M3LoadingIndicatorState extends State<M3LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      label: 'Loading',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _LoaderPainter(
            progress: _c,
            container: widget.color == null ? scheme.primaryContainer : null,
            shape: widget.color ?? scheme.primary,
          ),
        ),
      ),
    );
  }
}

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
    // Bumps get softer and sharper again while it spins.
    final amp = 0.07 + 0.09 * (0.5 - 0.5 * math.cos(t * math.pi * 4));
    final path = M3CookieBorder(lobes: 9, amplitude: amp)
        .getOuterPath(Rect.fromCircle(center: Offset.zero, radius: r * (container == null ? 0.95 : 0.58)));

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
