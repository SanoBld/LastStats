// ─────────────────────────────────────────────────────────────────────────
//  m3_interaction.dart — ONE place for press / ripple / top-bar behaviour.
//  Change the values here and every page of the app follows.
//  (Shapes live in m3_shapes.dart, motion in m3_motion.dart.)
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'm3_motion.dart';

/// How strong the "pressed" fill is (drawn inside the widget's own shape).
const double kM3PressAlpha = 0.12;

/// No round Android ripple: the pressed state fills the exact shape instead.
final InteractiveInkFeatureFactory kM3SplashFactory = NoSplash.splashFactory;

/// Top bar: always the same color, never turns grey when content scrolls.
Color m3TopBarColor(ColorScheme s) => s.surface;

ButtonStyle _noRipple(ButtonStyle? base) =>
    (base ?? const ButtonStyle()).copyWith(splashFactory: kM3SplashFactory);

/// Applies the shared interaction style to a whole theme.
ThemeData applyM3Interaction(ThemeData t) {
  final s = t.colorScheme;
  return t.copyWith(
    splashFactory: kM3SplashFactory,
    splashColor: Colors.transparent,
    highlightColor: s.onSurface.withValues(alpha: kM3PressAlpha),
    appBarTheme: t.appBarTheme.copyWith(
      backgroundColor: s.surface,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme:   FilledButtonThemeData(style: _noRipple(t.filledButtonTheme.style)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _noRipple(t.elevatedButtonTheme.style)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _noRipple(t.outlinedButtonTheme.style)),
    textButtonTheme:     TextButtonThemeData(style: _noRipple(t.textButtonTheme.style)),
    iconButtonTheme:     IconButtonThemeData(style: _noRipple(t.iconButtonTheme.style)),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: _noRipple(t.segmentedButtonTheme.style)),
  );
}


/// Default corner radius of the pressed fill when a tappable has no shape.
const double kM3PressRadius = 16;

/// Scale of a tappable while pressed (1 = no bounce).
const double kM3BounceScale = 0.97;

/// THE tappable of the app. Use it instead of InkWell everywhere.
/// - no round Android ripple, the pressed state fills the exact shape
/// - if no shape is given, a rounded one is used (never a sharp square)
/// - same pressed color on every page (see [kM3PressAlpha])
/// - small "bounce" (scale down while the finger is down), like the buttons
///   and cards of the app. Widgets that animate themselves (they pass
///   [onHighlightChanged]) or that set [bounce] to false are left alone.
class M3InkWell extends StatefulWidget {
  const M3InkWell({
    super.key,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.borderRadius,
    this.customBorder,
    this.enableFeedback,
    this.bounce = true,
    this.bounceScale = kM3BounceScale,
  });

  final Widget? child;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final ValueChanged<bool>? onHighlightChanged;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final bool? enableFeedback;
  final bool bounce;
  final double bounceScale;

  @override
  State<M3InkWell> createState() => _M3InkWellState();
}

class _M3InkWellState extends State<M3InkWell> {
  bool _down = false;

  bool get _bounces =>
      widget.bounce &&
      widget.onHighlightChanged == null &&
      (widget.onTap != null || widget.onLongPress != null);

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final ink = InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onHighlightChanged: widget.onHighlightChanged ??
          (_bounces ? (v) { if (mounted) setState(() => _down = v); } : null),
      customBorder: widget.customBorder,
      borderRadius: widget.customBorder != null
          ? null
          : (widget.borderRadius ?? BorderRadius.circular(kM3PressRadius)),
      enableFeedback: widget.enableFeedback ?? true,
      splashFactory: kM3SplashFactory,
      splashColor: Colors.transparent,
      highlightColor: s.onSurface.withValues(alpha: kM3PressAlpha),
      hoverColor: s.onSurface.withValues(alpha: kM3PressAlpha / 2),
      child: widget.child,
    );
    if (!_bounces) return ink;
    final down = _down && !M3Motion.reduced(context);
    return AnimatedScale(
      scale: down ? widget.bounceScale : 1.0,
      duration: M3Motion.spatialFastDuration,
      curve: M3Motion.spatialFast,
      child: ink,
    );
  }
}
