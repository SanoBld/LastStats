// lib/widgets/m3_confetti.dart
// One-shot confetti burst drawn over the whole screen.
// Idea inspired by Metrolist (GPL-3.0).
import 'dart:math' as math;
import 'package:flutter/material.dart';

void showM3Confetti(BuildContext context) {
  if (MediaQuery.of(context).disableAnimations) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final scheme = Theme.of(context).colorScheme;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _Confetti(
        colors: [scheme.primary, scheme.secondary, scheme.tertiary, scheme.primaryContainer],
        onDone: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}

class _Confetti extends StatefulWidget {
  final List<Color> colors;
  final VoidCallback onDone;
  const _Confetti({required this.colors, required this.onDone});

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..forward().whenComplete(widget.onDone);
  final _rnd = math.Random();
  late final List<_P> _ps = List.generate(70, (i) => _P(_rnd, widget.colors));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _Painter(_ps, _c));
}

class _P {
  final double x, vx, vy, spin, w, h;
  final Color color;
  _P(math.Random r, List<Color> colors)
      : x = 0.2 + r.nextDouble() * 0.6,
        vx = (r.nextDouble() - 0.5) * 0.9,
        vy = -(0.5 + r.nextDouble() * 0.9),
        spin = r.nextDouble() * 10,
        w = 5 + r.nextDouble() * 5,
        h = 8 + r.nextDouble() * 6,
        color = colors[r.nextInt(colors.length)];
}

class _Painter extends CustomPainter {
  final List<_P> ps;
  final Animation<double> a;
  _Painter(this.ps, this.a) : super(repaint: a);

  @override
  void paint(Canvas canvas, Size s) {
    final t = a.value;
    for (final p in ps) {
      // Fly up from the lower middle, then fall with gravity.
      final dx = p.x * s.width + p.vx * t * s.width * 0.6;
      final dy = s.height * 0.75 + (p.vy * t + 1.6 * t * t) * s.height * 0.6;
      final paint = Paint()..color = p.color.withValues(alpha: (1 - t * t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h), const Radius.circular(2)),
        paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Painter old) => false;
}
