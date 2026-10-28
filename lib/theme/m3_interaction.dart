// ─────────────────────────────────────────────────────────────────────────
//  m3_interaction.dart — ONE place for press / ripple / top-bar behaviour.
//  Change the values here and every page of the app follows.
//  (Shapes live in m3_shapes.dart, motion in m3_motion.dart.)
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

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
    // Filter pills / chips: same pressed fill as every other button, inside
    // their own pill shape.
    chipTheme: t.chipTheme.copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>((st) =>
          st.contains(WidgetState.pressed)
              ? s.onSurface.withValues(alpha: kM3PressAlpha)
              : st.contains(WidgetState.hovered)
                  ? s.onSurface.withValues(alpha: kM3PressAlpha / 2)
                  : null),
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

/// THE tappable of the app. Use it instead of InkWell everywhere.
/// - no round Android ripple, the pressed state fills the exact shape
/// - if no shape is given, a rounded one is used (never a sharp square)
/// - same pressed color on every page (see [kM3PressAlpha])
class M3InkWell extends StatelessWidget {
  const M3InkWell({
    super.key,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.borderRadius,
    this.customBorder,
    this.enableFeedback,
  });

  final Widget? child;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final ValueChanged<bool>? onHighlightChanged;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final bool? enableFeedback;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      onHighlightChanged: onHighlightChanged,
      customBorder: customBorder,
      borderRadius: customBorder != null
          ? null
          : (borderRadius ?? BorderRadius.circular(kM3PressRadius)),
      enableFeedback: enableFeedback,
      splashFactory: kM3SplashFactory,
      splashColor: Colors.transparent,
      highlightColor: s.onSurface.withValues(alpha: kM3PressAlpha),
      hoverColor: s.onSurface.withValues(alpha: kM3PressAlpha / 2),
      child: child,
    );
  }
}
