// lib/widgets/m3_components.dart
// ══════════════════════════════════════════════════════════════════════════
//  Small Material 3 Expressive building blocks shared by many screens:
//  • M3ShapeMorph    → box whose corners and color animate (spring curves)
//  • M3ButtonGroup   → connected buttons, selected one is a pill
//  • M3SegmentTile   → list item in a group (big outer, small inner corners)
//  • M3PressCard     → card that morphs its corners when pressed
//  • M3PageHeader    → back button + title
//  • M3SearchField   → pill search field
//  • M3EmptyState    → cookie icon + message
//  • M3CookieBadge   → round bumpy badge (emoji / icon)
//  • M3Chip          → animated chip (replaces FilterChip / ChoiceChip)
//  • M3SegmentedButton → animated segmented buttons
//  • M3TonalButton   → button that morphs its corners when pressed
//  • M3MaxWidth      → centers content on wide screens
// ══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/m3_motion.dart';
import '../theme/m3_shapes.dart';

BorderRadius _clampRadius(BorderRadius b) {
  Radius c(Radius r) => Radius.circular(math.max(0.0, r.x));
  return BorderRadius.only(
    topLeft: c(b.topLeft), topRight: c(b.topRight),
    bottomLeft: c(b.bottomLeft), bottomRight: c(b.bottomRight),
  );
}

/// Corners move with a spatial spring (small overshoot),
/// color changes with an effects spring (no overshoot).
class M3ShapeMorph extends StatelessWidget {
  const M3ShapeMorph({
    super.key,
    required this.radius,
    required this.color,
    this.child,
    this.padding,
    this.height,
  });

  final BorderRadius radius;
  final Color        color;
  final Widget?      child;
  final EdgeInsetsGeometry? padding;
  final double?      height;

  @override
  Widget build(BuildContext context) {
    final reduce = M3Motion.reduced(context);
    return TweenAnimationBuilder<BorderRadius?>(
      tween: BorderRadiusTween(end: radius),
      duration: reduce ? Duration.zero : M3Motion.spatialFastDuration,
      curve: M3Motion.spatialFast,
      builder: (context, r, _) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: reduce ? Duration.zero : M3Motion.effectsFastDuration,
        curve: M3Motion.effectsFast,
        builder: (context, c, _) => Container(
          height: height,
          padding: padding,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: c,
            shape: RoundedRectangleBorder(
                borderRadius: _clampRadius(r ?? radius)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Button group ───────────────────────────────────────────────────────────
class M3ButtonGroup<T> extends StatelessWidget {
  const M3ButtonGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<(T, String)> items;
  final T                 selected;
  final ValueChanged<T>   onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final sel = items[i].$1 == selected;
          final r = BorderRadius.circular(sel ? 22 : 12);
          return M3ShapeMorph(
            radius: r,
            color: sel ? scheme.primary : scheme.surfaceContainerHigh,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: r,
                onTap: () => onSelected(items[i].$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: M3Motion.effectsFastDuration,
                      curve: M3Motion.effectsFast,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                      child: Text(items[i].$2),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── List item in a group ───────────────────────────────────────────────────
BorderRadius m3SegmentRadius(int i, int n,
    {double outer = 24, double inner = 6}) {
  final top    = i == 0     ? outer : inner;
  final bottom = i == n - 1 ? outer : inner;
  return BorderRadius.vertical(
    top: Radius.circular(top), bottom: Radius.circular(bottom));
}

class M3SegmentTile extends StatelessWidget {
  const M3SegmentTile({
    super.key,
    required this.index,
    required this.count,
    required this.child,
    this.selected = false,
  });

  final int    index;
  final int    count;
  final bool   selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: M3ShapeMorph(
        radius: m3SegmentRadius(index, count),
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerLow,
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

// ── Card that morphs when pressed ──────────────────────────────────────────
class M3PressCard extends StatefulWidget {
  const M3PressCard({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
  });

  final Color         color;
  final Widget        child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  @override
  State<M3PressCard> createState() => _M3PressCardState();
}

class _M3PressCardState extends State<M3PressCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = M3Motion.reduced(context);
    final down = _down && !reduce;
    final r = BorderRadius.circular(down ? 16 : 28);
    return AnimatedScale(
      scale: down ? 0.97 : 1.0,
      duration: M3Motion.spatialFastDuration,
      curve: M3Motion.spatialFast,
      child: M3ShapeMorph(
        radius: r,
        color: widget.color,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: r,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: (v) => setState(() => _down = v),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

// ── Page header ────────────────────────────────────────────────────────────
class M3PageHeader extends StatelessWidget {
  const M3PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  final String       title;
  final String?      subtitle;
  final Widget?      leading;   // for example an emoji, after the back button
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: 4), a],
      ]),
    );
  }
}

// ── Search field ───────────────────────────────────────────────────────────
class M3SearchField extends StatelessWidget {
  const M3SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: padding,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: scheme.surfaceContainerHigh,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ── Cookie badge + empty state ─────────────────────────────────────────────
class M3CookieBadge extends StatelessWidget {
  const M3CookieBadge({
    super.key,
    required this.color,
    required this.child,
    this.size = 48,
  });

  final Color  color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: color,
          shape: const M3CookieBorder(lobes: 8, amplitude: 0.07),
        ),
        child: child,
      );
}

class M3EmptyState extends StatelessWidget {
  const M3EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String   message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            M3CookieBadge(
              size: 88,
              color: scheme.secondaryContainer,
              child: Icon(icon, size: 36, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ── Animated chip (same API as FilterChip / ChoiceChip) ────────────────────
// Selected: pill shape + primary color. Not selected: soft square.
class M3Chip extends StatelessWidget {
  const M3Chip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.avatar,
    this.showCheckmark,
    this.visualDensity,
    this.selectedColor,
    this.labelStyle,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;
  final bool? showCheckmark;       // ignored, kept for easy replacing
  final VisualDensity? visualDensity;
  final Color? selectedColor;      // ignored
  final TextStyle? labelStyle;     // ignored

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = visualDensity == VisualDensity.compact;
    final r = BorderRadius.circular(selected ? 20 : 10);
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return AnimatedScale(
      scale: selected ? 1.0 : 0.98,
      duration: M3Motion.spatialFastDuration,
      curve: M3Motion.spatialFast,
      child: M3ShapeMorph(
        radius: r,
        height: compact ? 32 : 40,
        color: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHigh,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: r,
            onTap: onSelected == null ? null : () => onSelected!(!selected),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (avatar != null) ...[
                  IconTheme(
                      data: IconThemeData(color: fg, size: 16), child: avatar!),
                  const SizedBox(width: 6),
                ],
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg),
                  child: label,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated segmented button (same API as SegmentedButton) ────────────────
class M3SegmentedButton<T> extends StatelessWidget {
  const M3SegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.style,
    this.showSelectedIcon,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final ButtonStyle? style;        // ignored
  final bool? showSelectedIcon;    // ignored

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      for (var i = 0; i < segments.length; i++) ...[
        if (i > 0) const SizedBox(width: 2),
        Expanded(child: _seg(context, scheme, segments[i], i)),
      ],
    ]);
  }

  Widget _seg(BuildContext context, ColorScheme scheme, ButtonSegment<T> s, int i) {
    final sel = selected.contains(s.value);
    final n = segments.length;
    // Selected = full pill. Others: round outside, small inside.
    final big = 24.0, small = 8.0;
    final r = sel
        ? BorderRadius.circular(big)
        : BorderRadius.horizontal(
            left: Radius.circular(i == 0 ? big : small),
            right: Radius.circular(i == n - 1 ? big : small));
    final fg = sel ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return M3ShapeMorph(
      radius: r,
      height: 48,
      color: sel ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onSelectionChanged == null ? null : () => onSelectionChanged!({s.value}),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (s.icon != null) ...[
                  IconTheme(data: IconThemeData(color: fg, size: 18), child: s.icon!),
                  if (s.label != null) const SizedBox(width: 6),
                ],
                if (s.label != null)
                  Flexible(
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: fg),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      child: s.label!,
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Centers content on wide screens ────────────────────────────────────────
class M3MaxWidth extends StatelessWidget {
  const M3MaxWidth({super.key, required this.child, this.maxWidth = 1100});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

// ── Button that morphs when pressed ────────────────────────────────────────
class M3TonalButton extends StatefulWidget {
  const M3TonalButton({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.radius = const BorderRadius.all(Radius.circular(24)),
    this.width,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final Widget child;
  final VoidCallback? onTap;      // null = disabled
  final Color? color;
  final BorderRadius radius;      // shape at rest
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  State<M3TonalButton> createState() => _M3TonalButtonState();
}

class _M3TonalButtonState extends State<M3TonalButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final down = _down && !M3Motion.reduced(context);
    final r = down ? BorderRadius.circular(12) : widget.radius;
    final base = widget.color ?? scheme.surfaceContainerHigh;
    return AnimatedScale(
      scale: down ? 0.94 : 1.0,
      duration: M3Motion.spatialFastDuration,
      curve: M3Motion.spatialFast,
      child: SizedBox(
        width: widget.width,
        child: M3ShapeMorph(
          radius: r,
          height: widget.height,
          color: widget.onTap == null ? base.withValues(alpha: 0.5) : base,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: r,
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _down = v),
              child: Padding(
                padding: widget.padding,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
