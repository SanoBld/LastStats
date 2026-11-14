// lib/widgets/m3_equalizer.dart
// Small animated equalizer bars, shown next to the track playing now.
// Idea inspired by Metrolist (GPL-3.0).
import 'dart:math' as math;
import 'package:flutter/material.dart';

class M3EqualizerBars extends StatefulWidget {
  final Color color;
  final double size;
  const M3EqualizerBars({super.key, required this.color, this.size = 14});

  @override
  State<M3EqualizerBars> createState() => _M3EqualizerBarsState();
}

class _M3EqualizerBarsState extends State<M3EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: widget.size, height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: widget.size / 5,
                height: widget.size *
                    (still ? 0.6 : 0.25 + 0.75 * (0.5 + 0.5 * math.sin(_c.value * 2 * math.pi + i * 2.1))),
                decoration: BoxDecoration(
                  color: widget.color, borderRadius: BorderRadius.circular(2)),
              ),
          ],
        ),
      ),
    );
  }
}
