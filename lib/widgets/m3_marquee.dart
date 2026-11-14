// lib/widgets/m3_marquee.dart
// Text that scrolls by itself only when it is too long for its space.
// Idea inspired by Metrolist (GPL-3.0).
import 'package:flutter/material.dart';

class M3Marquee extends StatefulWidget {
  final String text;
  final TextStyle? style;
  const M3Marquee(this.text, {super.key, this.style});

  @override
  State<M3Marquee> createState() => _M3MarqueeState();
}

class _M3MarqueeState extends State<M3Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  double _overflow = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _start(double overflow) {
    if ((overflow - _overflow).abs() < 1 && _c.isAnimating) return;
    _overflow = overflow;
    _c.stop();
    if (overflow <= 0) return;
    // About 30 px per second, with a pause at both ends.
    final ms = (overflow / 30 * 1000).round() + 3000;
    _c.duration = Duration(milliseconds: ms);
    _c.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    return LayoutBuilder(builder: (context, box) {
      final tp = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: 1,
        textDirection: Directionality.of(context),
      )..layout();
      final over = tp.width - box.maxWidth;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start(over);
      });
      if (over <= 0 || MediaQuery.of(context).disableAnimations) {
        return Text(widget.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: widget.style);
      }
      final move = over / (over + 0) ;
      return ClipRect(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            // 0..0.5 s pause, then scroll, then pause (using the 3 s extra).
            final total = _c.duration!.inMilliseconds.toDouble();
            final t = _c.value * total;
            final scrollMs = total - 3000;
            final p = ((t - 1500) / scrollMs).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(-over * p * move, 0),
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Text(widget.text, maxLines: 1, softWrap: false, style: widget.style),
              ),
            );
          },
        ),
      );
    });
  }
}
