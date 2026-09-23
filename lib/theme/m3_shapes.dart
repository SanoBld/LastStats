// lib/theme/m3_shapes.dart
// ══════════════════════════════════════════════════════════════════════════
//  Material 3 shapes for buttons.
//
//  • M3CookieBorder    → round shape with soft bumps (like the blob shapes)
//  • applyM3Shapes()   → every Material button becomes a pill (or circle for
//                        icon buttons) and morphs to a softer square while
//                        pressed
//  • kM3SheetAnimation / kM3DialogAnimation → same motion for all sheets
//                        and dialogs
// ══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'm3_motion.dart';

/// A circle with soft bumps. [amplitude] 0 = perfect circle, 0.08 = cookie.
/// Changing the amplitude animates smoothly (used for the press effect).
class M3CookieBorder extends OutlinedBorder {
  const M3CookieBorder({
    this.lobes = 8,
    this.amplitude = 0.07,
    super.side,
  });

  final int    lobes;
  final double amplitude;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  OutlinedBorder copyWith({BorderSide? side, int? lobes, double? amplitude}) =>
      M3CookieBorder(
        lobes: lobes ?? this.lobes,
        amplitude: amplitude ?? this.amplitude,
        side: side ?? this.side,
      );

  @override
  ShapeBorder scale(double t) =>
      M3CookieBorder(lobes: lobes, amplitude: amplitude, side: side.scale(t));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  Path _path(Rect rect) {
    final c = rect.center;
    final r = rect.shortestSide / 2;
    final path = Path();
    const steps = 180;
    for (int i = 0; i <= steps; i++) {
      final a = (i / steps) * math.pi * 2;
      // radius goes between (1 - amplitude) and 1
      final k = 1 - amplitude * (1 - math.cos(lobes * a)) / 2;
      final p = Offset(c.dx + r * k * math.cos(a), c.dy + r * k * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is M3CookieBorder) {
      return M3CookieBorder(
        lobes: lobes,
        amplitude: lerpDouble(a.amplitude, amplitude, t)!,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is M3CookieBorder) {
      return M3CookieBorder(
        lobes: lobes,
        amplitude: lerpDouble(amplitude, b.amplitude, t)!,
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(getOuterPath(rect), side.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is M3CookieBorder &&
      other.lobes == lobes &&
      other.amplitude == amplitude &&
      other.side == side;

  @override
  int get hashCode => Object.hash(lobes, amplitude, side);
}

// ── Theme: all Material buttons ────────────────────────────────────────────
// Idle = pill (or circle). Pressed = softer square. The button animates
// between the two shapes by itself.
final WidgetStateProperty<OutlinedBorder?> _pillShape =
    WidgetStateProperty.resolveWith<OutlinedBorder?>((states) =>
        states.contains(WidgetState.pressed)
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            : const StadiumBorder());

final WidgetStateProperty<OutlinedBorder?> _roundShape =
    WidgetStateProperty.resolveWith<OutlinedBorder?>((states) =>
        states.contains(WidgetState.pressed)
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            : const CircleBorder());

ThemeData applyM3Shapes(ThemeData t) {
  ButtonStyle pill(ButtonStyle? base) =>
      (base ?? const ButtonStyle()).copyWith(shape: _pillShape);
  final cs = t.colorScheme;
  final r20 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
  return t.copyWith(
    // Notification bar: floating, tinted with the app accent, rounded.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.secondaryContainer,
      contentTextStyle: t.textTheme.bodyMedium?.copyWith(
          color: cs.onSecondaryContainer, fontWeight: FontWeight.w600),
      actionTextColor: cs.primary,
      closeIconColor: cs.onSecondaryContainer,
      elevation: 3,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: r20,
    ),
    // Drop-down menus share the same rounded, tonal surface.
    popupMenuTheme: PopupMenuThemeData(
      color: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: r20,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(r20),
      ),
    ),
    filledButtonTheme:   FilledButtonThemeData(style: pill(t.filledButtonTheme.style)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: pill(t.elevatedButtonTheme.style)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: pill(t.outlinedButtonTheme.style)),
    textButtonTheme:     TextButtonThemeData(style: pill(t.textButtonTheme.style)),
    iconButtonTheme: IconButtonThemeData(
      style: (t.iconButtonTheme.style ?? const ButtonStyle())
          .copyWith(shape: _roundShape),
    ),
    floatingActionButtonTheme: t.floatingActionButtonTheme.copyWith(
      shape: const M3CookieBorder(lobes: 8, amplitude: 0.05),
    ),
  );
}

// ── Same motion for every sheet and dialog ─────────────────────────────────
const AnimationStyle kM3SheetAnimation = AnimationStyle(
  duration:        Duration(milliseconds: 400),
  reverseDuration: Duration(milliseconds: 250),
  curve:           M3Motion.emphasizedDecelerate,
  reverseCurve:    M3Motion.emphasizedAccelerate,
);

const AnimationStyle kM3DialogAnimation = AnimationStyle(
  duration:        Duration(milliseconds: 250),
  reverseDuration: Duration(milliseconds: 150),
  curve:           M3Motion.emphasizedDecelerate,
  reverseCurve:    M3Motion.emphasizedAccelerate,
);

/// Shows a snackbar with a soft spring-like slide (emphasized curves) and
/// replaces the one currently on screen instead of queueing behind it.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
    BuildContext context, SnackBar bar) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  return m.showSnackBar(
    bar,
    snackBarAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 220),
      curve: M3Motion.emphasizedDecelerate,
      reverseCurve: M3Motion.emphasizedAccelerate,
    ),
  );
}
