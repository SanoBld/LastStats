// lib/nothing_theme.dart
// ══════════════════════════════════════════════════════════════════════════
//  Nothing OS visual theme for LastStats.
//
//  Two modes (both first-class):
//    dark  → OLED black surfaces, white text
//    light → warm off-white surfaces, dark text
//
//  Two accent variants:
//    'classic' → pure red #FF2020 only
//    'mixed'   → red primary + yellow #FFC700 secondary touches
//
//  Design rules (Nothing design system):
//    - No shadows. No blur. Flat surfaces, border separation.
//    - 3 visual hierarchy layers max (display / body / metadata).
//    - Color is an event, not a default. Red = "pay attention now".
//    - Percussive transitions — ease-out only, no bounce/spring.
//    - Buttons: technical (6px) or pill (999px). Never in between.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Nothing palette ────────────────────────────────────────────────────────
const Color kNothingRed    = Color(0xFFFF2020); // primary accent always
const Color kNothingYellow = Color(0xFFFFC700); // secondary accent (mixed only)
const Color kNothingBlack  = Color(0xFF000000);
const Color kNothingWhite  = Color(0xFFF5F5F5);
const Color kNothingGrey   = Color(0xFF888888);
const Color kNothingGrey2  = Color(0xFF444444);

// Warm off-white for light mode (not pure white — "industrial warmth")
const Color kNothingOffWhite  = Color(0xFFF5F0EB);
const Color kNothingDarkText  = Color(0xFF0D0D0D);
const Color kNothingLightBorder = Color(0xFFDDDAD6);

// ── Dark surface stack (OLED) ──────────────────────────────────────────────
const _d0 = Color(0xFF000000);
const _d1 = Color(0xFF0D0D0D);
const _d2 = Color(0xFF111111);
const _d3 = Color(0xFF181818);
const _d4 = Color(0xFF222222);
const _dBorder = Color(0xFF2A2A2A);

// ── Light surface stack (warm off-white) ───────────────────────────────────
const _l0 = Color(0xFFF5F0EB); // scaffold
const _l1 = Color(0xFFFFFFFF); // default surface
const _l2 = Color(0xFFF0EBE5); // slightly tinted cards
const _l3 = Color(0xFFE8E3DD); // elevated surfaces
const _l4 = Color(0xFFDFDAD4); // highest surfaces
const _lBorder = Color(0xFFD0CBC4);

// ── Fonts ──────────────────────────────────────────────────────────────────
const _kBody    = 'NType82';
const _kDisplay = 'Ndot57';
const _kMono    = 'NType82Mono';
const _kCaps    = 'Ndot57Caps';

// ── Shapes ─────────────────────────────────────────────────────────────────
// Technical (6px) — settings tiles, cards, dialogs
const _kR6   = Radius.circular(6);
const _kBR6  = BorderRadius.all(_kR6);
const _shape6 = RoundedRectangleBorder(borderRadius: _kBR6);

// Pill (999px) — primary action buttons, chips, FAB
const _kBRPill  = BorderRadius.all(Radius.circular(999));
const _shapePill = RoundedRectangleBorder(borderRadius: _kBRPill);

// Sharp (0) — bottom sheets (Nothing OS doesn't round them)
const _shapeSharp = RoundedRectangleBorder();

class NothingTheme {
  NothingTheme._();

  static ThemeData build({
    String     accent     = 'classic',
    Brightness brightness = Brightness.dark,
  }) {
    final isDark = brightness == Brightness.dark;

    // Red is always primary. Yellow is secondary only in 'mixed'.
    const primary   = kNothingRed;
    const onPrimary = kNothingBlack; // red is bright enough → black text on it

    final secondary   = accent == 'mixed' ? kNothingYellow  : kNothingRed;
    final onSecondary = accent == 'mixed' ? kNothingBlack   : kNothingBlack;

    // Surface hierarchy
    final s0 = isDark ? _d0 : _l0;
    final s1 = isDark ? _d1 : _l1;
    final s2 = isDark ? _d2 : _l2;
    final s3 = isDark ? _d3 : _l3;
    final s4 = isDark ? _d4 : _l4;
    final sBorder = isDark ? _dBorder : _lBorder;

    final onSurface        = isDark ? kNothingWhite   : kNothingDarkText;
    final onSurfaceVariant = isDark ? kNothingGrey    : const Color(0xFF666058);
    final scaffoldBg       = s0;

    final scheme = ColorScheme(
      brightness:  brightness,
      // ── Primary (red) ──────────────────────────────────────────────────
      primary:             primary,
      onPrimary:           onPrimary,
      primaryContainer:    isDark
          ? const Color(0xFF3D0000)
          : const Color(0xFFFFE0E0),
      onPrimaryContainer:  isDark ? kNothingWhite : kNothingDarkText,
      // ── Secondary (red or yellow in mixed) ────────────────────────────
      secondary:           secondary,
      onSecondary:         onSecondary,
      secondaryContainer:  isDark
          ? Color.lerp(secondary, _d0, 0.82)!
          : Color.lerp(secondary, _l1, 0.70)!,
      onSecondaryContainer: isDark ? kNothingWhite : kNothingDarkText,
      // ── Tertiary (yellow touches if mixed, grey otherwise) ────────────
      tertiary:            accent == 'mixed' ? kNothingYellow : kNothingGrey,
      onTertiary:          kNothingBlack,
      tertiaryContainer:   isDark ? _d3 : _l3,
      onTertiaryContainer: isDark ? kNothingWhite : kNothingDarkText,
      // ── Error (always red) ────────────────────────────────────────────
      error:              primary,
      onError:            onPrimary,
      errorContainer:     isDark ? const Color(0xFF3D0000) : const Color(0xFFFFE0E0),
      onErrorContainer:   isDark ? kNothingWhite : kNothingDarkText,
      // ── Surfaces ──────────────────────────────────────────────────────
      surface:                    s1,
      onSurface:                  onSurface,
      onSurfaceVariant:           onSurfaceVariant,
      surfaceDim:                 s0,
      surfaceBright:              s3,
      surfaceContainerLowest:     s0,
      surfaceContainerLow:        isDark ? const Color(0xFF080808) : const Color(0xFFF8F4EF),
      surfaceContainer:           s2,
      surfaceContainerHigh:       s3,
      surfaceContainerHighest:    s4,
      // ── Misc ──────────────────────────────────────────────────────────
      outline:         isDark ? const Color(0xFF333333) : const Color(0xFFBBB6AF),
      outlineVariant:  sBorder,
      inverseSurface:  isDark ? kNothingWhite : kNothingDarkText,
      onInverseSurface: isDark ? kNothingBlack : kNothingWhite,
      inversePrimary:  primary,
      shadow:          kNothingBlack,
      scrim:           kNothingBlack,
    );

    // ── Typography ─────────────────────────────────────────────────────────
    // Layer 1 (display)  → Ndot57 — dot-matrix, iconic
    // Layer 2 (body)     → NType82 — clean UI text
    // Layer 3 (metadata) → NType82Mono / Ndot57Caps — labels, tags, captions
    final textColor   = onSurface;
    final metaColor   = onSurfaceVariant;

    final textTheme = TextTheme(
      // Display — Ndot57 for numbers, stats, big titles
      displayLarge:  _ts(_kDisplay, 57, weight: FontWeight.w400, spacing: -0.5,  color: textColor),
      displayMedium: _ts(_kDisplay, 45, weight: FontWeight.w400, spacing: -0.25, color: textColor),
      displaySmall:  _ts(_kDisplay, 36, weight: FontWeight.w400,                 color: textColor),
      // Headlines — NType82 Bold
      headlineLarge:  _ts(_kBody, 32, weight: FontWeight.w700, spacing: -0.5, color: textColor),
      headlineMedium: _ts(_kBody, 28, weight: FontWeight.w700, spacing: -0.25, color: textColor),
      headlineSmall:  _ts(_kBody, 24, weight: FontWeight.w700, color: textColor),
      // Titles — NType82
      titleLarge:  _ts(_kBody, 20, weight: FontWeight.w700, spacing: 0.1,  color: textColor),
      titleMedium: _ts(_kBody, 16, weight: FontWeight.w600, spacing: 0.15, color: textColor),
      titleSmall:  _ts(_kBody, 14, weight: FontWeight.w600, spacing: 0.1,  color: textColor),
      // Body — NType82
      bodyLarge:   _ts(_kBody, 16, spacing: 0.15, color: textColor),
      bodyMedium:  _ts(_kBody, 14, spacing: 0.1,  color: textColor),
      bodySmall:   _ts(_kBody, 12, spacing: 0.2,  color: metaColor),
      // Labels — mono for metadata layer
      labelLarge:  _ts(_kBody,  14, weight: FontWeight.w500, spacing: 0.5,  color: textColor),
      labelMedium: _ts(_kMono,  12, weight: FontWeight.w500, spacing: 0.8,  color: metaColor),
      labelSmall:  _ts(_kMono,  11, weight: FontWeight.w400, spacing: 1.0,  color: metaColor),
    );

    return ThemeData(
      colorScheme:             scheme,
      useMaterial3:            true,
      fontFamily:              _kBody,
      textTheme:               textTheme,
      scaffoldBackgroundColor: scaffoldBg,

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:          s0,
        foregroundColor:          onSurface,
        elevation:                0,
        scrolledUnderElevation:   0,
        surfaceTintColor:         Colors.transparent,
        shadowColor:              Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: _ts(_kBody, 19, weight: FontWeight.w700,
            spacing: 0.2, color: onSurface),
        iconTheme:        IconThemeData(color: onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: onSurface, size: 22),
      ),

      // ── Cards — technical corners, no shadow, border ──────────────────
      cardTheme: CardThemeData(
        color:            s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR6,
          side: BorderSide(color: sBorder),
        ),
        margin:      EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Navigation bar ────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:   s0,
        surfaceTintColor:  Colors.transparent,
        indicatorColor:    primary.withValues(alpha: isDark ? 0.12 : 0.10),
        indicatorShape:    const RoundedRectangleBorder(borderRadius: _kBR6),
        labelBehavior:     NavigationDestinationLabelBehavior.alwaysShow,
        height:            64,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? primary : onSurface.withValues(alpha: 0.35),
          size: 22,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final c = s.contains(WidgetState.selected)
              ? primary : onSurface.withValues(alpha: 0.35);
          return _ts(_kBody, 11, weight: FontWeight.w500, spacing: 0.3, color: c);
        }),
      ),

      // ── Navigation rail ───────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:          s0,
        indicatorColor:           primary.withValues(alpha: 0.12),
        indicatorShape:           const RoundedRectangleBorder(borderRadius: _kBR6),
        selectedIconTheme:        IconThemeData(color: primary, size: 22),
        unselectedIconTheme:      IconThemeData(
            color: onSurface.withValues(alpha: 0.3), size: 22),
        selectedLabelTextStyle:   _ts(_kBody, 12,
            weight: FontWeight.w600, color: primary),
        unselectedLabelTextStyle: _ts(_kBody, 12,
            color: onSurface.withValues(alpha: 0.3)),
        useIndicator:    true,
        minWidth:        56,
        minExtendedWidth: 200,
      ),

      // ── Dividers — single-pixel rule ──────────────────────────────────
      dividerTheme: DividerThemeData(
        color:     sBorder,
        thickness: 1,
        space:     1,
      ),

      // ── List tiles ────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor:         Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.08),
        iconColor:         onSurface.withValues(alpha: 0.55),
        textColor:         onSurface,
        subtitleTextStyle: _ts(_kBody, 12, spacing: 0.1, color: metaColor),
        leadingAndTrailingTextStyle: _ts(_kMono, 12, color: metaColor),
        shape: _shape6,
      ),

      // ── Input fields ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  s2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: _kBR6, borderSide: BorderSide(color: sBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: _kBR6, borderSide: BorderSide(color: sBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: _kBR6,
            borderSide: const BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: _kBR6,
            borderSide: const BorderSide(color: primary)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: _kBR6,
            borderSide: const BorderSide(color: primary, width: 1.5)),
        labelStyle: _ts(_kBody, 14, color: metaColor),
        hintStyle:  _ts(_kBody, 14, color: onSurface.withValues(alpha: 0.3)),
        prefixIconColor: metaColor,
        suffixIconColor: metaColor,
      ),

      // ── Segmented button — technical corners ──────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? primary : s2),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? kNothingBlack : onSurface),
          overlayColor: WidgetStateProperty.all(
              onSurface.withValues(alpha: 0.05)),
          side: WidgetStateProperty.all(BorderSide(color: sBorder)),
          shape: WidgetStateProperty.all(_shape6),
          textStyle: WidgetStateProperty.all(
              _ts(_kBody, 13, weight: FontWeight.w500, color: onSurface)),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 14)),
        ),
      ),

      // ── Chips — pill shape ────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:     s2,
        selectedColor:       primary,
        disabledColor:       s2,
        deleteIconColor:     metaColor,
        labelStyle:          _ts(_kBody, 13, color: onSurface),
        secondaryLabelStyle: _ts(_kBody, 13, color: kNothingBlack),
        side:    BorderSide(color: sBorder),
        shape:   const RoundedRectangleBorder(borderRadius: _kBRPill),
        checkmarkColor: kNothingBlack,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Buttons ───────────────────────────────────────────────────────
      // Primary action = pill shape (999px) — dominant, confident
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:         primary,
          foregroundColor:         kNothingBlack,
          disabledBackgroundColor: s3,
          disabledForegroundColor: metaColor,
          shape:     _shapePill,
          elevation: 0,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w700, spacing: 0.5,
              color: kNothingBlack),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: kNothingBlack,
          shape:     _shapePill,
          elevation: 0,
          textStyle: _ts(_kBody, 14, weight: FontWeight.w700, spacing: 0.5,
              color: kNothingBlack),
        ),
      ),
      // Secondary action = technical corners (6px)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side:      const BorderSide(color: primary),
          shape:     _shape6,
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
            s.contains(WidgetState.selected) ? kNothingBlack : metaColor),
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
            s.contains(WidgetState.selected) ? primary : metaColor),
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

      // ── FAB — pill shape ──────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: kNothingBlack,
        shape:           _shapePill,
        elevation:       0,
        focusElevation:  0,
        hoverElevation:  0,
      ),

      // ── Dialog — technical corners ────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:  s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR6,
          side: BorderSide(color: sBorder),
        ),
        titleTextStyle:   _ts(_kBody, 20, weight: FontWeight.w700,
            spacing: 0.1, color: onSurface),
        contentTextStyle: _ts(_kBody, 14, spacing: 0.1, color: metaColor),
      ),

      // ── Bottom sheet — sharp top edge ─────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:  s1,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: sBorder),
        ),
        dragHandleColor: metaColor,
        dragHandleSize:  const Size(32, 3),
      ),

      // ── Snackbar ──────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   s3,
        contentTextStyle:  _ts(_kBody, 14, spacing: 0.1, color: onSurface),
        actionTextColor:   primary,
        shape:             _shape6,
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
          color: s3, borderRadius: _kBR6,
          border: Border.all(color: sBorder),
        ),
        textStyle: _ts(_kBody, 12, spacing: 0.1, color: onSurface),
        padding:   const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Tab bar ───────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:              primary,
        unselectedLabelColor:    metaColor,
        indicatorColor:          primary,
        indicatorSize:           TabBarIndicatorSize.label,
        labelStyle:              _ts(_kBody, 14, weight: FontWeight.w600, color: primary),
        unselectedLabelStyle:    _ts(_kBody, 14, color: metaColor),
        dividerColor:            sBorder,
      ),

      // ── Pop-up menu ───────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color:            s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR6, side: BorderSide(color: sBorder)),
        textStyle:      _ts(_kBody, 14, spacing: 0.1, color: onSurface),
        labelTextStyle: WidgetStateProperty.all(
            _ts(_kBody, 14, spacing: 0.1, color: onSurface)),
      ),

      // ── Search bar ────────────────────────────────────────────────────
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(s2),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        side: WidgetStateProperty.all(BorderSide(color: sBorder)),
        shape: WidgetStateProperty.all(_shape6),
        textStyle: WidgetStateProperty.all(
            _ts(_kBody, 14, spacing: 0.1, color: onSurface)),
        hintStyle: WidgetStateProperty.all(
            _ts(_kBody, 14, color: metaColor)),
      ),

      // ── Icons ─────────────────────────────────────────────────────────
      iconTheme:        IconThemeData(color: onSurface, size: 22),
      primaryIconTheme: const IconThemeData(color: primary, size: 22),
    );
  }
}

// ── TextStyle helper ──────────────────────────────────────────────────────────
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
      color:         color,
      height:        1.35,
    );