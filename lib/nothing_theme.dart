// lib/nothing_theme.dart
// ══════════════════════════════════════════════════════════════════════════
//  Nothing OS visual theme for LastStats.
//  Always dark. Pure black background, Nothing red accent, NType82 font.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

const Color kNothingRed    = Color(0xFFFF2020);
const Color kNothingBlack  = Color(0xFF000000);
const Color kNothingWhite  = Color(0xFFF5F5F5);
const Color kNothingGrey   = Color(0xFF888888);

const String _kBody    = 'NType82';
const String _kDisplay = 'Ndot57';
const String _kMono    = 'NType82Mono';

const _kRadius   = Radius.circular(6);
const _kBorderR  = BorderRadius.all(_kRadius);
const _kShape    = RoundedRectangleBorder(borderRadius: _kBorderR);
const _kBorder   = Color(0xFF2A2A2A);
const _kSurface1 = Color(0xFF0D0D0D);
const _kSurface2 = Color(0xFF111111);
const _kSurface3 = Color(0xFF181818);
const _kSurface4 = Color(0xFF222222);

class NothingTheme {
  NothingTheme._();

  static ThemeData build() {
    final scheme = ColorScheme(
      brightness:  Brightness.dark,
      // Primary = Nothing red
      primary:              kNothingRed,
      onPrimary:            kNothingBlack,
      primaryContainer:     const Color(0xFF3D0000),
      onPrimaryContainer:   kNothingWhite,
      // Secondary = subtle red
      secondary:            kNothingRed,
      onSecondary:          kNothingBlack,
      secondaryContainer:   const Color(0xFF1F0000),
      onSecondaryContainer: kNothingWhite,
      // Tertiary = neutral grey
      tertiary:              kNothingGrey,
      onTertiary:            kNothingBlack,
      tertiaryContainer:     _kSurface3,
      onTertiaryContainer:   kNothingWhite,
      // Error
      error:              kNothingRed,
      onError:            kNothingBlack,
      errorContainer:     const Color(0xFF3D0000),
      onErrorContainer:   kNothingWhite,
      // Surfaces — OLED black hierarchy
      surface:                   _kSurface1,
      onSurface:                 kNothingWhite,
      surfaceDim:                kNothingBlack,
      surfaceBright:             _kSurface3,
      surfaceContainerLowest:    kNothingBlack,
      surfaceContainerLow:       const Color(0xFF080808),
      surfaceContainer:          _kSurface2,
      surfaceContainerHigh:      _kSurface3,
      surfaceContainerHighest:   _kSurface4,
      // Misc
      outline:         const Color(0xFF333333),
      outlineVariant:  _kBorder,
      inverseSurface:  kNothingWhite,
      onInverseSurface: kNothingBlack,
      inversePrimary:  kNothingRed,
      shadow:          kNothingBlack,
      scrim:           kNothingBlack,
      onSurfaceVariant: kNothingGrey,
    );

    final textTheme = TextTheme(
      // Dot-matrix display style for big numbers / titles
      displayLarge:  _ts(_kDisplay, 57, weight: FontWeight.w400, spacing: -0.25),
      displayMedium: _ts(_kDisplay, 45, weight: FontWeight.w400),
      displaySmall:  _ts(_kDisplay, 36, weight: FontWeight.w400),
      // NType82 headline variants
      headlineLarge:  _ts(_kBody, 32, weight: FontWeight.w700),
      headlineMedium: _ts(_kBody, 28, weight: FontWeight.w700),
      headlineSmall:  _ts(_kBody, 24, weight: FontWeight.w700),
      // Titles
      titleLarge:  _ts(_kBody, 22, weight: FontWeight.w600),
      titleMedium: _ts(_kBody, 16, weight: FontWeight.w600, spacing: 0.15),
      titleSmall:  _ts(_kBody, 14, weight: FontWeight.w600, spacing: 0.1),
      // Body
      bodyLarge:   _ts(_kBody, 16, spacing: 0.5),
      bodyMedium:  _ts(_kBody, 14, spacing: 0.25),
      bodySmall:   _ts(_kBody, 12, spacing: 0.4, color: kNothingGrey),
      // Labels
      labelLarge:  _ts(_kBody, 14, weight: FontWeight.w500, spacing: 0.1),
      labelMedium: _ts(_kBody, 12, weight: FontWeight.w500, spacing: 0.5),
      labelSmall:  _ts(_kMono,  11, weight: FontWeight.w500, spacing: 0.5, color: kNothingGrey),
    );

    return ThemeData(
      colorScheme:        scheme,
      useMaterial3:       true,
      fontFamily:         _kBody,
      textTheme:          textTheme,
      scaffoldBackgroundColor: kNothingBlack,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:    kNothingBlack,
        foregroundColor:    kNothingWhite,
        elevation:          0,
        surfaceTintColor:   Colors.transparent,
        shadowColor:        Colors.transparent,
        titleTextStyle: _ts(_kBody, 20, weight: FontWeight.w700),
        iconTheme:          const IconThemeData(color: kNothingWhite),
        actionsIconTheme:   const IconThemeData(color: kNothingWhite),
      ),

      // ── Cards ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:            _kSurface2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBorderR,
          side: const BorderSide(color: _kBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Navigation bar ──────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:   kNothingBlack,
        surfaceTintColor:  Colors.transparent,
        indicatorColor:    kNothingRed.withValues(alpha: 0.15),
        labelBehavior:     NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? kNothingRed
              : kNothingWhite.withValues(alpha: 0.45),
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final c = s.contains(WidgetState.selected)
              ? kNothingRed
              : kNothingWhite.withValues(alpha: 0.45);
          return TextStyle(fontFamily: _kBody, fontSize: 12,
              fontWeight: FontWeight.w500, color: c);
        }),
      ),

      // ── Navigation rail ─────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:        kNothingBlack,
        indicatorColor:         kNothingRed.withValues(alpha: 0.12),
        selectedIconTheme:      const IconThemeData(color: kNothingRed),
        unselectedIconTheme:    IconThemeData(color: kNothingWhite.withValues(alpha: 0.35)),
        selectedLabelTextStyle: _ts(_kBody, 12, weight: FontWeight.w600, color: kNothingRed),
        unselectedLabelTextStyle: _ts(_kBody, 12, color: kNothingWhite.withValues(alpha: 0.35)),
      ),

      // ── Dividers ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     _kBorder,
        thickness: 1,
        space:     1,
      ),

      // ── List tiles ───────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor:         Colors.transparent,
        iconColor:         kNothingWhite.withValues(alpha: 0.6),
        textColor:         kNothingWhite,
        subtitleTextStyle: _ts(_kBody, 12, color: kNothingGrey),
        shape:             _kShape,
      ),

      // ── Input fields ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: _kSurface2,
        border: OutlineInputBorder(
            borderRadius: _kBorderR,
            borderSide:   const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: _kBorderR,
            borderSide:   const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: _kBorderR,
            borderSide:   const BorderSide(color: kNothingRed, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: _kBorderR,
            borderSide:   const BorderSide(color: kNothingRed)),
        labelStyle: _ts(_kBody, 14, color: kNothingGrey),
        hintStyle:  _ts(_kBody, 14, color: kNothingGrey),
      ),

      // ── Segmented button ─────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? kNothingRed : _kSurface2),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? kNothingBlack : kNothingWhite),
          side: WidgetStateProperty.all(const BorderSide(color: _kBorder)),
          textStyle: WidgetStateProperty.all(
              _ts(_kBody, 13, weight: FontWeight.w500)),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  _kSurface2,
        selectedColor:    kNothingRed,
        disabledColor:    _kSurface2,
        labelStyle:       _ts(_kBody, 13),
        side:             const BorderSide(color: _kBorder),
        shape:            const RoundedRectangleBorder(borderRadius: _kBorderR),
        checkmarkColor:   kNothingBlack,
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kNothingRed,
          foregroundColor: kNothingBlack,
          shape:           _kShape,
          textStyle:       _ts(_kBody, 14, weight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kNothingRed,
          foregroundColor: kNothingBlack,
          shape:           _kShape,
          elevation:       0,
          textStyle:       _ts(_kBody, 14, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kNothingRed,
          side:            const BorderSide(color: kNothingRed),
          shape:           _kShape,
          textStyle:       _ts(_kBody, 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kNothingRed,
          textStyle:       _ts(_kBody, 14),
        ),
      ),

      // ── Switch ───────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? kNothingBlack : kNothingGrey),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? kNothingRed : _kSurface4),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? kNothingRed : _kBorder),
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kNothingRed,
        foregroundColor: kNothingBlack,
        shape:           _kShape,
        elevation:       0,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:  _kSurface2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape:            RoundedRectangleBorder(
          borderRadius: _kBorderR,
          side:         const BorderSide(color: _kBorder),
        ),
        titleTextStyle:   _ts(_kBody, 20, weight: FontWeight.w700),
        contentTextStyle: _ts(_kBody, 14, color: kNothingGrey),
      ),

      // ── Bottom sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:  _kSurface1,
        surfaceTintColor: Colors.transparent,
        shape:            const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          side:         BorderSide(color: _kBorder),
        ),
        dragHandleColor: kNothingGrey,
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   _kSurface3,
        contentTextStyle:  _ts(_kBody, 14),
        actionTextColor:   kNothingRed,
        shape:             _kShape,
        behavior:          SnackBarBehavior.floating,
      ),

      // ── Progress ─────────────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:             kNothingRed,
        linearTrackColor:  _kSurface4,
        circularTrackColor: _kSurface4,
      ),

      // ── Tooltip ──────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _kSurface3,
          borderRadius: _kBorderR,
          border: Border.all(color: _kBorder),
        ),
        textStyle: _ts(_kBody, 12),
      ),

      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: kNothingWhite),
      primaryIconTheme: const IconThemeData(color: kNothingRed),
    );
  }
}

// Build a TextStyle with the Nothing palette defaults.
TextStyle _ts(
  String family,
  double size, {
  FontWeight weight  = FontWeight.w400,
  double     spacing = 0.0,
  Color?     color,
}) =>
    TextStyle(
      fontFamily:      family,
      fontSize:        size,
      fontWeight:      weight,
      letterSpacing:   spacing,
      color:           color ?? kNothingWhite,
    );
