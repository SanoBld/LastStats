// lib/nothing_theme.dart
// ══════════════════════════════════════════════════════════════════════════
//  Nothing OS visual theme for LastStats.
//  Always dark. Pure black surfaces, Nothing accent, NType82 body font,
//  Ndot57 for display/numeric contexts.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Nothing palette ────────────────────────────────────────────────────────
const Color kNothingRed    = Color(0xFFFF2020); // classic red
const Color kNothingYellow = Color(0xFFFFC700); // CMF / new era yellow
const Color kNothingBlack  = Color(0xFF000000);
const Color kNothingWhite  = Color(0xFFF5F5F5);
const Color kNothingGrey   = Color(0xFF888888);
const Color kNothingGrey2  = Color(0xFF444444);

// ── Surface hierarchy (OLED) ───────────────────────────────────────────────
const Color _s0 = Color(0xFF000000); // scaffold, nav bars
const Color _s1 = Color(0xFF0D0D0D); // default surface
const Color _s2 = Color(0xFF111111); // cards, list tiles
const Color _s3 = Color(0xFF181818); // elevated surfaces
const Color _s4 = Color(0xFF222222); // highest surfaces
const Color _sBorder = Color(0xFF2A2A2A);

// ── Fonts ──────────────────────────────────────────────────────────────────
const String _kBody    = 'NType82';      // main UI font
const String _kDisplay = 'Ndot57';      // dot-matrix display / numbers
const String _kMono    = 'NType82Mono'; // monospace labels
const String _kCaps    = 'Ndot57Caps';  // dot-matrix all-caps

// ── Shape ──────────────────────────────────────────────────────────────────
const _kR      = Radius.circular(6);
const _kBR     = BorderRadius.all(_kR);
const _kShape  = RoundedRectangleBorder(borderRadius: _kBR);
const _kShape0 = RoundedRectangleBorder(); // sharp — bottom sheets, etc.

class NothingTheme {
  NothingTheme._();

  static ThemeData build({String accent = 'red'}) {
    final primary = accent == 'yellow' ? kNothingYellow : kNothingRed;
    // Yellow needs black text on it; red also needs black text.
    const onPrimary = kNothingBlack;

    // Slightly tinted container colors
    final primaryContainer = Color.lerp(primary, _s0, 0.75)!;

    final scheme = ColorScheme(
      brightness:  Brightness.dark,
      primary:              primary,
      onPrimary:            onPrimary,
      primaryContainer:     primaryContainer,
      onPrimaryContainer:   kNothingWhite,
      secondary:            primary,
      onSecondary:          onPrimary,
      secondaryContainer:   Color.lerp(primary, _s0, 0.88)!,
      onSecondaryContainer: kNothingWhite,
      tertiary:              kNothingGrey,
      onTertiary:            kNothingBlack,
      tertiaryContainer:     _s3,
      onTertiaryContainer:   kNothingWhite,
      error:              primary,
      onError:            onPrimary,
      errorContainer:     Color.lerp(primary, _s0, 0.8)!,
      onErrorContainer:   kNothingWhite,
      // OLED surface stack
      surface:                    _s1,
      onSurface:                  kNothingWhite,
      onSurfaceVariant:           kNothingGrey,
      surfaceDim:                 _s0,
      surfaceBright:              _s3,
      surfaceContainerLowest:     _s0,
      surfaceContainerLow:        const Color(0xFF080808),
      surfaceContainer:           _s2,
      surfaceContainerHigh:       _s3,
      surfaceContainerHighest:    _s4,
      outline:         const Color(0xFF333333),
      outlineVariant:  _sBorder,
      inverseSurface:  kNothingWhite,
      onInverseSurface: kNothingBlack,
      inversePrimary:  primary,
      shadow:          kNothingBlack,
      scrim:           kNothingBlack,
    );

    // ── Typography ─────────────────────────────────────────────────────────
    // Ndot57 for large display numbers/titles (the iconic dot-matrix look).
    // NType82 for all UI text.
    // NType82Mono / Ndot57Caps for tags and monospace labels.
    final textTheme = TextTheme(
      displayLarge:  _ts(_kDisplay, 57, weight: FontWeight.w400, spacing: -0.5),
      displayMedium: _ts(_kDisplay, 45, weight: FontWeight.w400, spacing: -0.25),
      displaySmall:  _ts(_kDisplay, 36, weight: FontWeight.w400),
      headlineLarge:  _ts(_kBody, 32, weight: FontWeight.w700, spacing: -0.5),
      headlineMedium: _ts(_kBody, 28, weight: FontWeight.w700, spacing: -0.25),
      headlineSmall:  _ts(_kBody, 24, weight: FontWeight.w700),
      titleLarge:  _ts(_kBody, 20, weight: FontWeight.w700, spacing: 0.1),
      titleMedium: _ts(_kBody, 16, weight: FontWeight.w600, spacing: 0.15),
      titleSmall:  _ts(_kBody, 14, weight: FontWeight.w600, spacing: 0.1),
      bodyLarge:   _ts(_kBody, 16, spacing: 0.15),
      bodyMedium:  _ts(_kBody, 14, spacing: 0.1),
      bodySmall:   _ts(_kBody, 12, spacing: 0.2, color: kNothingGrey),
      labelLarge:  _ts(_kBody, 14, weight: FontWeight.w500, spacing: 0.5),
      labelMedium: _ts(_kMono,  12, weight: FontWeight.w500, spacing: 0.8),
      labelSmall:  _ts(_kMono,  11, weight: FontWeight.w400, spacing: 1.0, color: kNothingGrey),
    );

    return ThemeData(
      colorScheme:             scheme,
      useMaterial3:            true,
      fontFamily:              _kBody,
      textTheme:               textTheme,
      scaffoldBackgroundColor: _s0,

      // ── System UI overlay: status bar icons are white ─────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:   _s0,
        foregroundColor:   kNothingWhite,
        elevation:         0,
        scrolledUnderElevation: 0,
        surfaceTintColor:  Colors.transparent,
        shadowColor:       Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: _ts(_kBody, 19, weight: FontWeight.w700, spacing: 0.2),
        iconTheme:        const IconThemeData(color: kNothingWhite, size: 22),
        actionsIconTheme: const IconThemeData(color: kNothingWhite, size: 22),
      ),

      // ── Cards ─────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:            _s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR,
          side: const BorderSide(color: _sBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Navigation bar ────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:    _s0,
        surfaceTintColor:   Colors.transparent,
        indicatorColor:     primary.withValues(alpha: 0.12),
        indicatorShape:     const RoundedRectangleBorder(borderRadius: _kBR),
        labelBehavior:      NavigationDestinationLabelBehavior.alwaysShow,
        height:             64,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? primary
              : kNothingWhite.withValues(alpha: 0.35),
          size: 22,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final c = s.contains(WidgetState.selected)
              ? primary
              : kNothingWhite.withValues(alpha: 0.35);
          return _ts(_kBody, 11, weight: FontWeight.w500, spacing: 0.3, color: c);
        }),
      ),

      // ── Navigation rail ───────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:          _s0,
        indicatorColor:           primary.withValues(alpha: 0.12),
        indicatorShape:           const RoundedRectangleBorder(borderRadius: _kBR),
        selectedIconTheme:        IconThemeData(color: primary, size: 22),
        unselectedIconTheme:      IconThemeData(
            color: kNothingWhite.withValues(alpha: 0.3), size: 22),
        selectedLabelTextStyle:   _ts(_kBody, 12, weight: FontWeight.w600, color: primary),
        unselectedLabelTextStyle: _ts(_kBody, 12,
            color: kNothingWhite.withValues(alpha: 0.3)),
        useIndicator: true,
        minWidth:        56,
        minExtendedWidth: 200,
      ),

      // ── Dividers ──────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     _sBorder,
        thickness: 1,
        space:     1,
      ),

      // ── List tiles ────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor:         Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.08),
        iconColor:         kNothingWhite.withValues(alpha: 0.55),
        textColor:         kNothingWhite,
        subtitleTextStyle: _ts(_kBody, 12, spacing: 0.1, color: kNothingGrey),
        leadingAndTrailingTextStyle: _ts(_kMono, 12, color: kNothingGrey),
        shape:             _kShape,
        dense:             false,
      ),

      // ── Input fields ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  _s2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: const BorderSide(color: _sBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: const BorderSide(color: _sBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: BorderSide(color: primary)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: _kBR,
            borderSide: BorderSide(color: primary, width: 1.5)),
        labelStyle: _ts(_kBody, 14, color: kNothingGrey),
        hintStyle:  _ts(_kBody, 14, color: kNothingGrey2),
        prefixIconColor: kNothingGrey,
        suffixIconColor: kNothingGrey,
      ),

      // ── Segmented button ──────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? primary : _s2),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? kNothingBlack : kNothingWhite),
          overlayColor: WidgetStateProperty.all(
              kNothingWhite.withValues(alpha: 0.05)),
          side: WidgetStateProperty.all(const BorderSide(color: _sBorder)),
          shape: WidgetStateProperty.all(_kShape),
          textStyle: WidgetStateProperty.all(
              _ts(_kBody, 13, weight: FontWeight.w500)),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 14)),
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  _s2,
        selectedColor:    primary,
        disabledColor:    _s2,
        deleteIconColor:  kNothingGrey,
        labelStyle:       _ts(_kBody, 13),
        secondaryLabelStyle: _ts(_kBody, 13, color: kNothingBlack),
        side:             const BorderSide(color: _sBorder),
        shape:            const RoundedRectangleBorder(borderRadius: _kBR),
        checkmarkColor:   kNothingBlack,
        padding:          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Buttons ───────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: kNothingBlack,
          disabledBackgroundColor: _s3,
          disabledForegroundColor: kNothingGrey,
          shape:     _kShape,
          elevation: 0,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w700, spacing: 0.5),
          padding:   const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: kNothingBlack,
          shape:     _kShape,
          elevation: 0,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w700, spacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side:      BorderSide(color: primary),
          shape:     _kShape,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w500),
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? kNothingBlack : kNothingGrey),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : _s3),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : _sBorder),
        trackOutlineWidth: WidgetStateProperty.all(1.5),
      ),

      // ── Checkbox ──────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(kNothingBlack),
        side: const BorderSide(color: _sBorder, width: 1.5),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3))),
      ),

      // ── Radio ─────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : kNothingGrey),
      ),

      // ── Slider ────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor:   primary,
        inactiveTrackColor: _s4,
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
        backgroundColor:  _s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR,
          side: const BorderSide(color: _sBorder),
        ),
        titleTextStyle:   _ts(_kBody, 20, weight: FontWeight.w700, spacing: 0.1),
        contentTextStyle: _ts(_kBody, 14, spacing: 0.1, color: kNothingGrey),
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:  _s1,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        // Sharp top edge — Nothing OS doesn't round bottom sheets
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: _sBorder),
        ),
        dragHandleColor: kNothingGrey2,
        dragHandleSize:  const Size(32, 3),
      ),

      // ── Snackbar ──────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   _s3,
        contentTextStyle:  _ts(_kBody, 14, spacing: 0.1),
        actionTextColor:   primary,
        disabledActionTextColor: kNothingGrey,
        shape:             _kShape,
        behavior:          SnackBarBehavior.floating,
        elevation:         0,
      ),

      // ── Progress indicators ───────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:             primary,
        linearTrackColor:  _s4,
        circularTrackColor: _s4,
        linearMinHeight:   2,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _s3,
          borderRadius: _kBR,
          border: Border.all(color: _sBorder),
        ),
        textStyle: _ts(_kBody, 12, spacing: 0.1),
        padding:   const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Tab bar ───────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:         primary,
        unselectedLabelColor: kNothingGrey,
        indicatorColor:     primary,
        indicatorSize:      TabBarIndicatorSize.label,
        labelStyle:         _ts(_kBody, 14, weight: FontWeight.w600),
        unselectedLabelStyle: _ts(_kBody, 14),
        dividerColor:       _sBorder,
      ),

      // ── Pop-up menu ───────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color:            _s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR,
          side: const BorderSide(color: _sBorder),
        ),
        textStyle: _ts(_kBody, 14, spacing: 0.1),
        labelTextStyle: WidgetStateProperty.all(_ts(_kBody, 14, spacing: 0.1)),
      ),

      // ── Search bar ────────────────────────────────────────────────────
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(_s2),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        side: WidgetStateProperty.all(const BorderSide(color: _sBorder)),
        shape: WidgetStateProperty.all(_kShape),
        textStyle: WidgetStateProperty.all(_ts(_kBody, 14, spacing: 0.1)),
        hintStyle: WidgetStateProperty.all(_ts(_kBody, 14, color: kNothingGrey)),
      ),

      // ── Icons ─────────────────────────────────────────────────────────
      iconTheme:        const IconThemeData(color: kNothingWhite, size: 22),
      primaryIconTheme: IconThemeData(color: primary, size: 22),
    );
  }
}

// Build a TextStyle helper with Nothing palette defaults.
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