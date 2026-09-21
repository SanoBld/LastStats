// lib/widgets/skeleton.dart
// ══════════════════════════════════════════════════════════════════════════
//  Skeleton loaders (grey boxes with a soft pulse).
//  Use them instead of a spinner so the layout stays stable while loading
//  and content does not pop in and jump around.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/m3_motion.dart';

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
        color: scheme.onSurface.withValues(alpha: 0.08),
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
  Widget build(BuildContext context) => SkeletonPulse(
        child: SkeletonBox(height: height, radius: radius),
      );
}

/// A full page list of loading rows (square picture + 2 lines).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 8, this.header = false});
  final int rows;
  final bool header; // big card on top (for chart pages)

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
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
  }
}
