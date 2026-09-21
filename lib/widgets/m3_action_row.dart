// lib/widgets/m3_action_row.dart
// ══════════════════════════════════════════════════════════════════════════
//  Material 3 action buttons.
//  • M3CircleButton → cookie shaped round button (heart), accent color
//  • M3PillButton   → wide pill button (play), tonal color
//  Both have an off state (round, calm color) and an on state
//  (cookie / square, vivid accent color) and morph between them.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'skeleton.dart';
import '../theme/m3_motion.dart';
import '../theme/m3_shapes.dart';

// Shared base: colored shape + ripple + press animation.
class _M3Pressable extends StatefulWidget {
  const _M3Pressable({
    required this.height,
    required this.color,
    required this.idleShape,
    required this.pressedShape,
    required this.child,
    this.width,
    this.onTap,
    this.onLongPress,
    this.tooltip,
  });

  final double        height;
  final double?       width;
  final Color         color;
  final OutlinedBorder idleShape;
  final OutlinedBorder pressedShape;
  final Widget        child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String?       tooltip;

  @override
  State<_M3Pressable> createState() => _M3PressableState();
}

class _M3PressableState extends State<_M3Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = M3Motion.reduced(context);
    final shape  = (_down && !reduce) ? widget.pressedShape : widget.idleShape;

    Widget body = AnimatedScale(
      scale: (_down && !reduce) ? 0.95 : 1.0,
      duration: M3Motion.spatialFastDuration,
      curve: M3Motion.spatialFast,
      child: AnimatedContainer(
        duration: M3Motion.spatialDefaultDuration,
        curve: M3Motion.spatialDefault,
        width: widget.width,
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: widget.color.withValues(
              alpha: widget.onTap == null ? 0.6 : 1.0),
          shape: shape,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: shape,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: (v) => setState(() => _down = v),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      body = Semantics(button: true, label: widget.tooltip, child: body);
    }
    return body;
  }
}

/// Round cookie button (56 dp), for example the heart. Uses the accent color.
class M3CircleButton extends StatelessWidget {
  const M3CircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.busy = false,
    this.active = false,
    this.tooltip,
  });

  final IconData      icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool          busy;
  final bool          active;   // on = cookie + vivid color, off = circle
  final String?       tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = active ? scheme.onPrimary : scheme.onSecondaryContainer;
    return _M3Pressable(
      width: 56,
      height: 56,
      color: active ? scheme.primary : scheme.secondaryContainer,
      // amplitude 0 is a perfect circle, so the shape grows its bumps
      idleShape: M3CookieBorder(lobes: 8, amplitude: active ? 0.09 : 0.0),
      pressedShape: M3CookieBorder(lobes: 8, amplitude: active ? 0.0 : 0.05),
      onTap: busy ? null : onTap,
      onLongPress: onLongPress,
      tooltip: tooltip,
      child: M3Switcher(
        duration: M3Motion.short,
        child: busy
            ? SizedBox(
                key: const ValueKey('busy'),
                width: 20, height: 20,
                child: M3Spinner(color: fg),
              )
            : Icon(icon, key: ValueKey(icon), color: fg, size: 26),
      ),
    );
  }
}

/// Wide pill button (56 dp high), for example play / pause.
/// [progress] (0..1) fills the pill from the left, like a progress bar.
class M3PillButton extends StatelessWidget {
  const M3PillButton({
    super.key,
    required this.icon,
    this.onTap,
    this.busy = false,
    this.progress = 0,
    this.active = false,
    this.tooltip,
  });

  final IconData      icon;
  final VoidCallback? onTap;
  final bool          busy;
  final double        progress;
  final bool          active;   // on = square + vivid color, off = round
  final String?       tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = active ? scheme.onPrimary : scheme.onSecondaryContainer;
    return _M3Pressable(
      height: 56,
      color: active ? scheme.primary : scheme.secondaryContainer,
      idleShape: active
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
          : const StadiumBorder(),
      pressedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(active ? 10 : 18)),
      onTap: busy ? null : onTap,
      tooltip: tooltip,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
                duration: M3Motion.short,
                builder: (context, v, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: ColoredBox(
                      color: (active ? scheme.onPrimary : scheme.secondary)
                          .withValues(alpha: 0.22)),
                ),
              ),
            ),
            M3Switcher(
              duration: M3Motion.short,
              child: busy
                  ? SizedBox(
                      key: const ValueKey('busy'),
                      width: 22, height: 22,
                      child: M3Spinner(color: fg),
                    )
                  : Icon(icon, key: ValueKey(icon), color: fg, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round button + wide pill on one row. Any of the two can be null.
class M3ActionRow extends StatelessWidget {
  const M3ActionRow({super.key, this.circle, this.pill});

  final Widget? circle;
  final Widget? pill;

  @override
  Widget build(BuildContext context) {
    if (circle == null && pill == null) return const SizedBox.shrink();
    return Row(children: [
      ?circle,
      if (circle != null && pill != null) const SizedBox(width: 8),
      if (pill != null) Expanded(child: pill!),
    ]);
  }
}
