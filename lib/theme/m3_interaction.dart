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
    filledButtonTheme:   FilledButtonThemeData(style: _noRipple(t.filledButtonTheme.style)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _noRipple(t.elevatedButtonTheme.style)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _noRipple(t.outlinedButtonTheme.style)),
    textButtonTheme:     TextButtonThemeData(style: _noRipple(t.textButtonTheme.style)),
    iconButtonTheme:     IconButtonThemeData(style: _noRipple(t.iconButtonTheme.style)),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: _noRipple(t.segmentedButtonTheme.style)),
  );
}
