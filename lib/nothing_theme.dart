// lib/nothing_theme.dart
// ══════════════════════════════════════════════════════════════════════════
//  Nothing OS visual theme for LastStats.
//  Supports light and dark modes.
//  Red (#FF2020) primary — yellow (#FFC700) secondary touches.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Nothing palette ────────────────────────────────────────────────────────
const Color kNothingRed    = Color(0xFFFF2020);
const Color kNothingYellow = Color(0xFFFFC700);
const Color kNothingBlack  = Color(0xFF000000);
const Color kNothingWhite  = Color(0xFFF5F5F5);
const Color kNothingGrey   = Color(0xFF888888);
const Color kNothingGrey2  = Color(0xFF444444);

// ── Dark surface hierarchy (OLED) ─────────────────────────────────────────
const Color _ds0 = Color(0xFF000000);
const Color _ds1 = Color(0xFF0D0D0D);
const Color _ds2 = Color(0xFF111111);
const Color _ds3 = Color(0xFF181818);
const Color _ds4 = Color(0xFF222222);
const Color _dBorder = Color(0xFF2A2A2A);

// ── Light surface hierarchy (warm off-white — Nothing OS 3 light mode) ────
const Color _ls0    = Color(0xFFF5F0EB); // scaffold / nav
const Color _ls1    = Color(0xFFFFFFFF); // default surface
const Color _ls2    = Color(0xFFF0EBE5); // cards / list tiles
const Color _ls3    = Color(0xFFE8E2DC); // elevated surfaces
const Color _ls4    = Color(0xFFDDD8D2); // highest surfaces
const Color _lBorder = Color(0xFFD0CAC3);
const Color _lText   = Color(0xFF0A0A0A);
const Color _lSubtext = Color(0xFF666666);

// ── Fonts ──────────────────────────────────────────────────────────────────
const String _kBody    = 'NType82';
const String _kDisplay = 'Ndot57';
const String _kMono    = 'NType82Mono';

// ── Shape ──────────────────────────────────────────────────────────────────
const _kR     = Radius.circular(6);
const _kBR    = BorderRadius.all(_kR);
const _kShape = RoundedRectangleBorder(borderRadius: _kBR);

class NothingTheme {
  NothingTheme._();

  // Returns a light or dark ThemeData.
  // Red is always primary; yellow is secondary for subtle accent touches.
  static ThemeData build({Brightness brightness = Brightness.dark}) {
    final isDark = brightness == Brightness.dark;

    // ── Accent colors (same in both modes) ────────────────────────────────
    const primary   = kNothingRed;
    const secondary = kNothingYellow;
    const onPrimary = kNothingBlack;

    // ── Surface tokens per mode ────────────────────────────────────────────
    final s0     = isDark ? _ds0     : _ls0;
    final s1     = isDark ? _ds1     : _ls1;
    final s2     = isDark ? _ds2     : _ls2;
    final s3     = isDark ? _ds3     : _ls3;
    final s4     = isDark ? _ds4     : _ls4;
    final sBorder = isDark ? _dBorder : _lBorder;
    final onSurf  = isDark ? kNothingWhite : _lText;
    final onSurfV = isDark ? kNothingGrey  : _lSubtext;

    final scheme = ColorScheme(
      brightness:           brightness,
      primary:              primary,
      onPrimary:            onPrimary,
      primaryContainer:     Color.lerp(primary, isDark ? _ds0 : _ls1, 0.80)!,
      onPrimaryContainer:   onSurf,
      // Yellow as secondary — appears on chips, tabs, selected elements
      secondary:            secondary,
      onSecondary:          kNothingBlack,
      secondaryContainer:   Color.lerp(secondary, isDark ? _ds0 : _ls1, 0.82)!,
      onSecondaryContainer: onSurf,
      tertiary:             isDark ? kNothingGrey : _lSubtext,
      onTertiary:           isDark ? kNothingBlack : _ls1,
      tertiaryContainer:    s3,
      onTertiaryContainer:  onSurf,
      error:                primary,
      onError:              onPrimary,
      errorContainer:       Color.lerp(primary, isDark ? _ds0 : _ls1, 0.82)!,
      onErrorContainer:     onSurf,
      surface:              s1,
      onSurface:            onSurf,
      onSurfaceVariant:     onSurfV,
      surfaceDim:           s0,
      surfaceBright:        s3,
      surfaceContainerLowest:  s0,
      surfaceContainerLow:     isDark ? const Color(0xFF080808) : _ls2,
      surfaceContainer:        s2,
      surfaceContainerHigh:    s3,
      surfaceContainerHighest: s4,
      outline:         isDark ? const Color(0xFF333333) : const Color(0xFFBBB5AE),
      outlineVariant:  sBorder,
      inverseSurface:  isDark ? kNothingWhite : kNothingBlack,
      onInverseSurface: isDark ? kNothingBlack : kNothingWhite,
      inversePrimary:  primary,
      shadow:          kNothingBlack,
      scrim:           kNothingBlack,
    );

    // ── Typography ─────────────────────────────────────────────────────────
    final textTheme = TextTheme(
      displayLarge:  _ts(_kDisplay, 57, weight: FontWeight.w400, spacing: -0.5, color: onSurf),
      displayMedium: _ts(_kDisplay, 45, weight: FontWeight.w400, spacing: -0.25, color: onSurf),
      displaySmall:  _ts(_kDisplay, 36, weight: FontWeight.w400, color: onSurf),
      headlineLarge:  _ts(_kBody, 32, weight: FontWeight.w700, spacing: -0.5, color: onSurf),
      headlineMedium: _ts(_kBody, 28, weight: FontWeight.w700, spacing: -0.25, color: onSurf),
      headlineSmall:  _ts(_kBody, 24, weight: FontWeight.w700, color: onSurf),
      titleLarge:  _ts(_kBody, 20, weight: FontWeight.w700, spacing: 0.1, color: onSurf),
      titleMedium: _ts(_kBody, 16, weight: FontWeight.w600, spacing: 0.15, color: onSurf),
      titleSmall:  _ts(_kBody, 14, weight: FontWeight.w600, spacing: 0.1, color: onSurf),
      bodyLarge:   _ts(_kBody, 16, spacing: 0.15, color: onSurf),
      bodyMedium:  _ts(_kBody, 14, spacing: 0.1, color: onSurf),
      bodySmall:   _ts(_kBody, 12, spacing: 0.2, color: onSurfV),
      labelLarge:  _ts(_kBody, 14, weight: FontWeight.w500, spacing: 0.5, color: onSurf),
      labelMedium: _ts(_kMono, 12, weight: FontWeight.w500, spacing: 0.8, color: onSurf),
      labelSmall:  _ts(_kMono, 11, weight: FontWeight.w400, spacing: 1.0, color: onSurfV),
    );

    return ThemeData(
      colorScheme:             scheme,
      useMaterial3:            true,
      fontFamily:              _kBody,
      textTheme:               textTheme,
      scaffoldBackgroundColor: s0,

      // ── System UI overlay ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:   s0,
        foregroundColor:   onSurf,
        elevation:         0,
        scrolledUnderElevation: 0,
        surfaceTintColor:  Colors.transparent,
        shadowColor:       Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: _ts(_kBody, 19, weight: FontWeight.w700, spacing: 0.2, color: onSurf),
        iconTheme:        IconThemeData(color: onSurf, size: 22),
        actionsIconTheme: IconThemeData(color: onSurf, size: 22),
      ),

      // ── Cards ─────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:            s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR,
          side: BorderSide(color: sBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Navigation bar ────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:    s0,
        surfaceTintColor:   Colors.transparent,
        indicatorColor:     primary.withValues(alpha: 0.12),
        indicatorShape:     const RoundedRectangleBorder(borderRadius: _kBR),
        labelBehavior:      NavigationDestinationLabelBehavior.alwaysShow,
        height:             64,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? primary
              : onSurf.withValues(alpha: isDark ? 0.35 : 0.4),
          size: 22,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final c = s.contains(WidgetState.selected)
              ? primary
              : onSurf.withValues(alpha: isDark ? 0.35 : 0.4);
          return _ts(_kBody, 11, weight: FontWeight.w500, spacing: 0.3, color: c);
        }),
      ),

      // ── Navigation rail ───────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:          s0,
        indicatorColor:           primary.withValues(alpha: 0.12),
        indicatorShape:           const RoundedRectangleBorder(borderRadius: _kBR),
        selectedIconTheme:        const IconThemeData(color: primary, size: 22),
        unselectedIconTheme:      IconThemeData(
            color: onSurf.withValues(alpha: isDark ? 0.3 : 0.4), size: 22),
        selectedLabelTextStyle:   _ts(_kBody, 12, weight: FontWeight.w600, color: primary),
        unselectedLabelTextStyle: _ts(_kBody, 12,
            color: onSurf.withValues(alpha: isDark ? 0.3 : 0.4)),
        useIndicator: true,
        minWidth:        56,
        minExtendedWidth: 200,
      ),

      // ── Dividers ──────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color:     sBorder,
        thickness: 1,
        space:     1,
      ),

      // ── List tiles ────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor:         Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.08),
        iconColor:         onSurf.withValues(alpha: isDark ? 0.55 : 0.6),
        textColor:         onSurf,
        subtitleTextStyle: _ts(_kBody, 12, spacing: 0.1, color: onSurfV),
        leadingAndTrailingTextStyle: _ts(_kMono, 12, color: onSurfV),
        shape:             _kShape,
        dense:             false,
      ),

      // ── Input fields ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  s2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: BorderSide(color: sBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: BorderSide(color: sBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: const BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: const BorderSide(color: primary)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: const BorderSide(color: primary, width: 1.5)),
        labelStyle: _ts(_kBody, 14, color: onSurfV),
        hintStyle:  _ts(_kBody, 14, color: isDark ? kNothingGrey2 : _lSubtext),
        prefixIconColor: onSurfV,
        suffixIconColor: onSurfV,
      ),

      // ── Segmented button ──────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? primary : s2),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? kNothingBlack : onSurf),
          overlayColor: WidgetStateProperty.all(
              onSurf.withValues(alpha: 0.05)),
          side: WidgetStateProperty.all(BorderSide(color: sBorder)),
          shape: WidgetStateProperty.all(_kShape),
          textStyle: WidgetStateProperty.all(
              _ts(_kBody, 13, weight: FontWeight.w500, color: onSurf)),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 14)),
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  s2,
        selectedColor:    primary,
        disabledColor:    s2,
        deleteIconColor:  onSurfV,
        labelStyle:       _ts(_kBody, 13, color: onSurf),
        secondaryLabelStyle: _ts(_kBody, 13, color: kNothingBlack),
        side:             BorderSide(color: sBorder),
        shape:            const RoundedRectangleBorder(borderRadius: _kBR),
        checkmarkColor:   kNothingBlack,
        padding:          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Buttons ───────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: kNothingBlack,
          disabledBackgroundColor: s3,
          disabledForegroundColor: onSurfV,
          shape:     _kShape,
          elevation: 0,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w700, spacing: 0.5,
              color: kNothingBlack),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: kNothingBlack,
          shape:     _kShape,
          elevation: 0,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w700, spacing: 0.5,
              color: kNothingBlack),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side:      const BorderSide(color: primary),
          shape:     _kShape,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w500, color: primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w500, color: primary),
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? kNothingBlack : onSurfV),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : s3),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : sBorder),
        trackOutlineWidth: WidgetStateProperty.all(1.5),
      ),

      // ── Checkbox ──────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(kNothingBlack),
        side: BorderSide(color: sBorder, width: 1.5),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3))),
      ),

      // ── Radio ─────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : onSurfV),
      ),

      // ── Slider ────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor:   primary,
        inactiveTrackColor: s4,
        thumbColor:         primary,
        overlayColor:       primary.withValues(alpha: 0.12),
        trackHeight:        2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),

      // ── FAB ───────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: kNothingBlack,
        shape:           _kShape,
        elevation:       0,
        focusElevation:  0,
        hoverElevation:  0,
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:  s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR,
          side: BorderSide(color: sBorder),
        ),
        titleTextStyle:   _ts(_kBody, 20, weight: FontWeight.w700, spacing: 0.1, color: onSurf),
        contentTextStyle: _ts(_kBody, 14, spacing: 0.1, color: onSurfV),
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:  s1,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: sBorder),
        ),
        dragHandleColor: isDark ? kNothingGrey2 : _lBorder,
        dragHandleSize:  const Size(32, 3),
      ),

      // ── Snackbar ──────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   s3,
        contentTextStyle:  _ts(_kBody, 14, spacing: 0.1, color: onSurf),
        actionTextColor:   primary,
        disabledActionTextColor: onSurfV,
        shape:             _kShape,
        behavior:          SnackBarBehavior.floating,
        elevation:         0,
      ),

      // ── Progress indicators ───────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:              primary,
        linearTrackColor:   s4,
        circularTrackColor: s4,
        linearMinHeight:    2,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: s3,
          borderRadius: _kBR,
          border: Border.all(color: sBorder),
        ),
        textStyle: _ts(_kBody, 12, spacing: 0.1, color: onSurf),
        padding:   const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Tab bar ───────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:           primary,
        unselectedLabelColor: onSurfV,
        indicatorColor:       primary,
        indicatorSize:        TabBarIndicatorSize.label,
        labelStyle:           _ts(_kBody, 14, weight: FontWeight.w600, color: primary),
        unselectedLabelStyle: _ts(_kBody, 14, color: onSurfV),
        dividerColor:         sBorder,
      ),

      // ── Pop-up menu ───────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color:            s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR,
          side: BorderSide(color: sBorder),
        ),
        textStyle: _ts(_kBody, 14, spacing: 0.1, color: onSurf),
        labelTextStyle: WidgetStateProperty.all(_ts(_kBody, 14, spacing: 0.1, color: onSurf)),
      ),

      // ── Search bar ────────────────────────────────────────────────────
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(s2),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        side: WidgetStateProperty.all(BorderSide(color: sBorder)),
        shape: WidgetStateProperty.all(_kShape),
        textStyle: WidgetStateProperty.all(_ts(_kBody, 14, spacing: 0.1, color: onSurf)),
        hintStyle: WidgetStateProperty.all(_ts(_kBody, 14, color: onSurfV)),
      ),

      // ── Icons ─────────────────────────────────────────────────────────
      iconTheme:        IconThemeData(color: onSurf, size: 22),
      primaryIconTheme: const IconThemeData(color: primary, size: 22),
    );
  }
}

// Helper — builds a TextStyle with Nothing defaults.
TextStyle _ts(
  String family,
  double size, {
  FontWeight weight  = FontWeight.w400,
  double     spacing = 0.0,
  Color?     color,
}) =>
    TextStyle(
      fontFamily:    family,
      fontSize:      size,
      fontWeight:    weight,
      letterSpacing: spacing,
      color:         color ?? kNothingWhite,
      height:        1.35,
    );