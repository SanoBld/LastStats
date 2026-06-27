// lib/nothing_theme.dart
// ══════════════════════════════════════════════════════════════════════════
//  Nothing OS visual theme for LastStats.
//
//  Two modes (both first-class):
//    dark  → OLED black surfaces, white text
//    light → warm off-white scaffold (#F0EDE8), pure white cards
//
//  Two accent variants:
//    'classic' → pure red #FF2020 only
//    'mixed'   → red primary + yellow #FFC700 secondary touches
//
//  Shape system (from Nothing OS screenshots):
//    Content cards  → 16 px   (large, prominent containers)
//    Inputs/dialogs →  6 px   (technical, precise)
//    Buttons        → 999 px  (pill — primary action) or 6 px (secondary)
//    Bottom sheets  →  0 px   (sharp top edge)
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

// Light mode surfaces — warm off-white, inspired by Nothing OS light
const Color kNothingOffWhite = Color(0xFFF0EDE8); // scaffold
const Color kNothingDarkText = Color(0xFF0D0D0D);

// ── Dark surface stack (OLED) ──────────────────────────────────────────────
const _d0 = Color(0xFF000000);
const _d1 = Color(0xFF0D0D0D);
const _d2 = Color(0xFF111111);
const _d3 = Color(0xFF181818);
const _d4 = Color(0xFF222222);
const _dBorder = Color(0xFF2A2A2A);

// ── Light surface stack ────────────────────────────────────────────────────
const _l0 = Color(0xFFF0EDE8); // scaffold — warm off-white
const _l1 = Color(0xFFFFFFFF); // cards — pure white
const _l2 = Color(0xFFF8F6F3); // slightly tinted
const _l3 = Color(0xFFEEEBE6); // elevated
const _l4 = Color(0xFFE5E2DC); // highest
const _lBorder = Color(0xFFE0DDD8); // subtle border

// ── Fonts ──────────────────────────────────────────────────────────────────
const _kBody    = 'NType82';
const _kDisplay = 'Ndot57';
const _kMono    = 'NType82Mono';

// ── Shapes ─────────────────────────────────────────────────────────────────
// Cards (content containers) — 16 px
const _kBR16  = BorderRadius.all(Radius.circular(16));
// Technical (inputs, dialogs, secondary buttons) — 6 px
const _kBR6   = BorderRadius.all(Radius.circular(6));
// Pill (primary buttons, FAB, chips) — 999 px
const _kBRPill = BorderRadius.all(Radius.circular(999));

const _shape16   = RoundedRectangleBorder(borderRadius: _kBR16);
const _shape6    = RoundedRectangleBorder(borderRadius: _kBR6);
const _shapePill = RoundedRectangleBorder(borderRadius: _kBRPill);

class NothingTheme {
  NothingTheme._();

  static ThemeData build({
    String     accent     = 'classic',
    Brightness brightness = Brightness.dark,
  }) {
    final isDark = brightness == Brightness.dark;

    const primary   = kNothingRed;
    const onPrimary = kNothingBlack;

    final secondary   = accent == 'mixed' ? kNothingYellow : kNothingRed;
    final onSecondary = kNothingBlack;

    // Surface hierarchy
    final s0 = isDark ? _d0 : _l0;
    final s1 = isDark ? _d1 : _l1;
    final s2 = isDark ? _d2 : _l2;
    final s3 = isDark ? _d3 : _l3;
    final s4 = isDark ? _d4 : _l4;
    final sBorder = isDark ? _dBorder : _lBorder;

    final onSurface        = isDark ? kNothingWhite   : kNothingDarkText;
    final onSurfaceVariant = isDark ? kNothingGrey    : const Color(0xFF6B6560);
    final scaffoldBg       = s0;

    final scheme = ColorScheme(
      brightness: brightness,
      primary:             primary,
      onPrimary:           onPrimary,
      primaryContainer:    isDark
          ? const Color(0xFF3D0000)
          : const Color(0xFFFFE8E8),
      onPrimaryContainer:  isDark ? kNothingWhite : kNothingDarkText,
      secondary:           secondary,
      onSecondary:         onSecondary,
      secondaryContainer:  isDark
          ? Color.lerp(secondary, _d0, 0.82)!
          : Color.lerp(secondary, _l1, 0.72)!,
      onSecondaryContainer: isDark ? kNothingWhite : kNothingDarkText,
      tertiary:            accent == 'mixed' ? kNothingYellow : kNothingGrey,
      onTertiary:          kNothingBlack,
      tertiaryContainer:   isDark ? _d3 : _l3,
      onTertiaryContainer: isDark ? kNothingWhite : kNothingDarkText,
      error:               primary,
      onError:             onPrimary,
      errorContainer:      isDark ? const Color(0xFF3D0000) : const Color(0xFFFFE8E8),
      onErrorContainer:    isDark ? kNothingWhite : kNothingDarkText,
      // Surfaces
      surface:                    s1,
      onSurface:                  onSurface,
      onSurfaceVariant:           onSurfaceVariant,
      surfaceDim:                 s0,
      surfaceBright:              s3,
      surfaceContainerLowest:     s0,
      surfaceContainerLow:        isDark ? const Color(0xFF080808) : const Color(0xFFFBF9F7),
      surfaceContainer:           s2,
      surfaceContainerHigh:       s3,
      surfaceContainerHighest:    s4,
      outline:        isDark ? const Color(0xFF333333) : const Color(0xFFB8B4AE),
      outlineVariant: sBorder,
      inverseSurface:  isDark ? kNothingWhite : kNothingDarkText,
      onInverseSurface: isDark ? kNothingBlack : kNothingWhite,
      inversePrimary:  primary,
      shadow:          kNothingBlack,
      scrim:           kNothingBlack,
    );

    final textColor = onSurface;
    final metaColor = onSurfaceVariant;

    final textTheme = TextTheme(
      // Display — Ndot57 dot-matrix for big numbers/stats
      displayLarge:  _ts(_kDisplay, 57, w: FontWeight.w400, s: -0.5,  c: textColor),
      displayMedium: _ts(_kDisplay, 45, w: FontWeight.w400, s: -0.25, c: textColor),
      displaySmall:  _ts(_kDisplay, 36, w: FontWeight.w400,            c: textColor),
      // Headlines — NType82 Bold
      headlineLarge:  _ts(_kBody, 32, w: FontWeight.w700, s: -0.5,  c: textColor),
      headlineMedium: _ts(_kBody, 28, w: FontWeight.w700, s: -0.25, c: textColor),
      headlineSmall:  _ts(_kBody, 24, w: FontWeight.w700,            c: textColor),
      // Titles
      titleLarge:  _ts(_kBody, 20, w: FontWeight.w700, s: 0.1,  c: textColor),
      titleMedium: _ts(_kBody, 16, w: FontWeight.w600, s: 0.15, c: textColor),
      titleSmall:  _ts(_kBody, 14, w: FontWeight.w600, s: 0.1,  c: textColor),
      // Body
      bodyLarge:   _ts(_kBody, 16, s: 0.15, c: textColor),
      bodyMedium:  _ts(_kBody, 14, s: 0.1,  c: textColor),
      bodySmall:   _ts(_kBody, 12, s: 0.2,  c: metaColor),
      // Labels — mono for metadata
      labelLarge:  _ts(_kBody,  14, w: FontWeight.w500, s: 0.5,  c: textColor),
      labelMedium: _ts(_kMono,  12, w: FontWeight.w500, s: 0.8,  c: metaColor),
      labelSmall:  _ts(_kMono,  11, w: FontWeight.w400, s: 1.0,  c: metaColor),
    );

    return ThemeData(
      colorScheme:             scheme,
      useMaterial3:            true,
      fontFamily:              _kBody,
      textTheme:               textTheme,
      scaffoldBackgroundColor: scaffoldBg,

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:         s0,
        foregroundColor:         onSurface,
        elevation:               0,
        scrolledUnderElevation:  0,
        surfaceTintColor:        Colors.transparent,
        shadowColor:             Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: _ts(_kBody, 19, w: FontWeight.w700, s: 0.2, c: onSurface),
        iconTheme:        IconThemeData(color: onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: onSurface, size: 22),
      ),

      // ── Cards — 16 px radius (content containers) ─────────────────────
      cardTheme: CardThemeData(
        color:            s1,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR16,
          // Light: very subtle border. Dark: slightly more visible.
          side: BorderSide(
              color: sBorder,
              width: isDark ? 1.0 : 0.8),
        ),
        margin:       EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Navigation bar — Nothing OS style ──────────────────────────────
      // No labels. Red pill indicator. Icons only. Border top separates from content.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:   s0,
        surfaceTintColor:  Colors.transparent,
        // Pill-shaped red indicator behind selected icon
        indicatorColor:    primary.withValues(alpha: isDark ? 0.14 : 0.10),
        indicatorShape:    const RoundedRectangleBorder(borderRadius: _kBRPill),
        // labelBehavior handled at widget level via navLabelNotifier
        height:            60,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? primary
              : onSurface.withValues(alpha: isDark ? 0.38 : 0.45),
          size: 24,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final col = s.contains(WidgetState.selected)
              ? primary : onSurface.withValues(alpha: isDark ? 0.38 : 0.45);
          return _ts(_kBody, 11, w: FontWeight.w500, s: 0.3, c: col);
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
        selectedLabelTextStyle:   _ts(_kBody, 12, w: FontWeight.w600, c: primary),
        unselectedLabelTextStyle: _ts(_kBody, 12,
            c: onSurface.withValues(alpha: 0.3)),
        useIndicator:     true,
        minWidth:         56,
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
        iconColor:         onSurface.withValues(alpha: 0.55),
        textColor:         onSurface,
        subtitleTextStyle: _ts(_kBody, 12, s: 0.1, c: metaColor),
        leadingAndTrailingTextStyle: _ts(_kMono, 12, c: metaColor),
        shape: _shape6,
      ),

      // ── Input fields — 6 px technical ────────────────────────────────
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
        labelStyle:       _ts(_kBody, 14, c: metaColor),
        hintStyle:        _ts(_kBody, 14, c: onSurface.withValues(alpha: 0.3)),
        prefixIconColor:  metaColor,
        suffixIconColor:  metaColor,
      ),

      // ── Segmented button — 6 px technical ─────────────────────────────
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
              _ts(_kBody, 13, w: FontWeight.w500, c: onSurface)),
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
        labelStyle:          _ts(_kBody, 13, c: onSurface),
        secondaryLabelStyle: _ts(_kBody, 13, c: kNothingBlack),
        side:    BorderSide(color: sBorder),
        shape:   const RoundedRectangleBorder(borderRadius: _kBRPill),
        checkmarkColor: kNothingBlack,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Buttons ───────────────────────────────────────────────────────
      // Primary → pill (confident, dominant)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:         primary,
          foregroundColor:         kNothingBlack,
          disabledBackgroundColor: s3,
          disabledForegroundColor: metaColor,
          shape:     _shapePill,
          elevation: 0,
          textStyle: _ts(_kBody, 14, w: FontWeight.w700, s: 0.5, c: kNothingBlack),
          padding:   const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: kNothingBlack,
          shape:     _shapePill,
          elevation: 0,
          textStyle: _ts(_kBody, 14, w: FontWeight.w700, s: 0.5, c: kNothingBlack),
        ),
      ),
      // Secondary → technical (6 px)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side:      const BorderSide(color: primary),
          shape:     _shape6,
          textStyle: _ts(_kBody, 14, w: FontWeight.w500, c: primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _ts(_kBody, 14, w: FontWeight.w500, c: primary),
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

      // ── FAB — pill ────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        // In 'mixed' mode yellow FAB mimics Nothing Key's yellow action button
        backgroundColor: accent == 'mixed' ? kNothingYellow : primary,
        foregroundColor: kNothingBlack,
        shape:           _shapePill,
        elevation:       0,
        focusElevation:  0,
        hoverElevation:  0,
      ),

      // ── Dialog — 6 px technical ───────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:  s1,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR6,
          side: BorderSide(color: sBorder),
        ),
        titleTextStyle:   _ts(_kBody, 20, w: FontWeight.w700, s: 0.1, c: onSurface),
        contentTextStyle: _ts(_kBody, 14, s: 0.1, c: metaColor),
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

      // ── Snackbar — 6 px technical ─────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   s3,
        contentTextStyle:  _ts(_kBody, 14, s: 0.1, c: onSurface),
        actionTextColor:   primary,
        shape:             _shape6,
        behavior:          SnackBarBehavior.floating,
        elevation:         0,
      ),

      // ── Progress ──────────────────────────────────────────────────────
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
        textStyle: _ts(_kBody, 12, s: 0.1, c: onSurface),
        padding:   const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Tab bar ───────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:           primary,
        unselectedLabelColor: metaColor,
        indicatorColor:       primary,
        indicatorSize:        TabBarIndicatorSize.label,
        labelStyle:           _ts(_kBody, 14, w: FontWeight.w600, c: primary),
        unselectedLabelStyle: _ts(_kBody, 14, c: metaColor),
        dividerColor:         sBorder,
      ),

      // ── Pop-up menu ───────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color:            s2,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(
          borderRadius: _kBR6, side: BorderSide(color: sBorder)),
        textStyle:      _ts(_kBody, 14, s: 0.1, c: onSurface),
        labelTextStyle: WidgetStateProperty.all(
            _ts(_kBody, 14, s: 0.1, c: onSurface)),
      ),

      // ── Search bar — 6 px ─────────────────────────────────────────────
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(s2),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        side: WidgetStateProperty.all(BorderSide(color: sBorder)),
        shape: WidgetStateProperty.all(_shape6),
        textStyle: WidgetStateProperty.all(_ts(_kBody, 14, s: 0.1, c: onSurface)),
        hintStyle: WidgetStateProperty.all(_ts(_kBody, 14, c: metaColor)),
      ),

      // ── Icons ─────────────────────────────────────────────────────────
      iconTheme:        IconThemeData(color: onSurface, size: 22),
      primaryIconTheme: const IconThemeData(color: primary, size: 22),
    );
  }
}

TextStyle _ts(
  String family,
  double size, {
  FontWeight w = FontWeight.w400,
  double     s = 0.0,
  Color?     c,
}) =>
    TextStyle(
      fontFamily:    family,
      fontSize:      size,
      fontWeight:    w,
      letterSpacing: s,
      color:         c,
      height:        1.35,
    );