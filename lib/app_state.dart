import 'package:flutter/material.dart';

// ── Global notifiers ─────────────────────────────────────────────────────────
final themeModeNotifier          = ValueNotifier<ThemeMode>(ThemeMode.system);
final accentNotifier             = ValueNotifier<Color>(const Color(0xFF7C3AED));
final useDynamicColorNotifier    = ValueNotifier<bool>(false);
final useNowPlayingColorNotifier = ValueNotifier<bool>(false);
final localeNotifier             = ValueNotifier<String>('fr');

// Visual style preset: 'default' | 'nothing'
// Saved as 'ls_theme_style' in SharedPreferences.
final themeStyleNotifier = ValueNotifier<String>('default');

// Nothing OS accent variant: 'classic' (red only) | 'mixed' (red + yellow touches)
// Saved as 'ls_nothing_accent' in SharedPreferences.
final nothingAccentNotifier = ValueNotifier<String>('classic');

// Color used when music-color mode is on but nothing is playing.
// Saved as 'ls_nowplaying_fallback_color' in SharedPreferences.
final nowPlayingFallbackColorNotifier = ValueNotifier<Color>(const Color(0xFF7C3AED));

// Tint detail sheet backgrounds with the dominant color from the artwork.
// Saved as 'ls_artwork_color_theme' in SharedPreferences.
final artworkColorThemeNotifier = ValueNotifier<bool>(false);

// Keep the last extracted artwork color when nothing is playing.
// Saved as 'ls_keep_last_artwork_color' in SharedPreferences.
final keepLastArtworkColorNotifier = ValueNotifier<bool>(false);

// Pure black dark theme for OLED screens (default style only).
// Saved as 'ls_oled_mode' in SharedPreferences.
final oledModeNotifier = ValueNotifier<bool>(false);

/// Controls the navigation layout:
///   'auto' → wide rail when screen width ≥ 720 dp (default)
///   'on'   → always use the side rail
///   'off'  → always use the bottom navigation bar
final pcModeNotifier = ValueNotifier<String>('auto');

// Show labels under nav bar icons. Saved as 'ls_nav_labels'.
final navLabelNotifier = ValueNotifier<bool>(true);

ThemeMode themeFromString(String? s) {
  switch (s) {
    case 'light':  return ThemeMode.light;
    case 'dark':   return ThemeMode.dark;
    default:       return ThemeMode.system;
  }
}

/// Accepts a named key ('purple', 'blue'…) or a hex code '#RRGGBB'.
Color accentFromString(String? s) {
  if (s == null) return const Color(0xFF7C3AED);
  if (s.startsWith('#') && s.length == 7) {
    try {
      return Color(0xFF000000 | int.parse(s.substring(1), radix: 16));
    } catch (_) {}
  }
  switch (s) {
    case 'blue':    return const Color(0xFF1D4ED8);
    case 'green':   return const Color(0xFF059669);
    case 'red':     return const Color(0xFFDC2626);
    case 'orange':  return const Color(0xFFD97706);
    case 'pink':    return const Color(0xFFDB2777);
    case 'teal':    return const Color(0xFF0F766E);
    case 'neutral': return const Color(0xFF607D8B);
    default:        return const Color(0xFF7C3AED);
  }
}

/// Converts a [Color] to an uppercase '#RRGGBB' string.
String colorToHex(Color c) {
  final r = (c.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final g = (c.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final b = (c.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

/// Returns the seed color to pass to ColorScheme.fromSeed.
Color seedColorForScheme(Color c) {
  final luminance = c.computeLuminance();
  if (luminance < 0.008) return const Color(0xFF455A64);
  if (luminance > 0.97)  return const Color(0xFF90A4AE);
  return c;
}