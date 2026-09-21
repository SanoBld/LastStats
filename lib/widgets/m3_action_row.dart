// lib/widgets/m3_action_row.dart
// ══════════════════════════════════════════════════════════════════════════
//  Material 3 action buttons: a round button (heart) next to a wide pill
//  button (play). Both are tonal and change shape a little when pressed.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/m3_motion.dart';

// Shared base: colored shape + ripple + press animation.
class _M3Pressable extends StatefulWidget {
  const _M3Pressable({
    required this.height,
    required this.color,
    required this.child,
    this.width,
    this.onTap,
    this.onLongPress,
    this.tooltip,
  });

  final double        height;
  final double?       width;
  final Color         color;
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
    // Round when idle, a softer square when pressed.
    final radius = BorderRadius.circular(
        (_down && !reduce) ? 18.0 : widget.height / 2);

    Widget body = AnimatedScale(
      scale: (_down && !reduce) ? 0.96 : 1.0,
      duration: M3Motion.short,
      curve: M3Motion.standard,
      child: AnimatedContainer(
        duration: M3Motion.medium,
        curve: M3Motion.emphasized,
        width: widget.width,
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.color.withValues(
              alpha: widget.onTap == null ? 0.6 : 1.0),
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: (v) => setState(() => _down = v),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      body = Semantics(
          button: true, label: widget.tooltip, child: body);
    }
    return body;
  }
}

/// Round button (56 dp), for example the heart.
class M3CircleButton extends StatelessWidget {
  const M3CircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.busy = false,
    this.iconColor,
    this.tooltip,
  });

  final IconData      icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool          busy;
  final Color?        iconColor;
  final String?       tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = iconColor ?? scheme.onTertiaryContainer;
    return _M3Pressable(
      width: 56,
      height: 56,
      color: scheme.tertiaryContainer,
      onTap: busy ? null : onTap,
      onLongPress: onLongPress,
      tooltip: tooltip,
      child: M3Switcher(
        duration: M3Motion.short,
        child: busy
            ? SizedBox(
                key: const ValueKey('busy'),
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
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
    this.tooltip,
  });

  final IconData      icon;
  final VoidCallback? onTap;
  final bool          busy;
  final double        progress;
  final String?       tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onPrimaryContainer;
    return _M3Pressable(
      height: 56,
      color: scheme.primaryContainer,
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
                    color: scheme.primary.withValues(alpha: 0.22)),
              ),
            ),
          ),
          M3Switcher(
            duration: M3Motion.short,
            child: busy
                ? SizedBox(
                    key: const ValueKey('busy'),
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: fg),
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
