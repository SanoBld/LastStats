import 'package:flutter/material.dart';

// ── Global notifiers ─────────────────────────────────────────────────────────
final themeModeNotifier          = ValueNotifier<ThemeMode>(ThemeMode.system);
final accentNotifier             = ValueNotifier<Color>(const Color(0xFF7C3AED));
final useDynamicColorNotifier    = ValueNotifier<bool>(false);
final useNowPlayingColorNotifier = ValueNotifier<bool>(false);
final localeNotifier             = ValueNotifier<String>('fr'); // 'fr' | 'en'

// Color shown when music-color mode is ON but nothing is currently playing.
// Saved as 'ls_nowplaying_fallback_color' in SharedPreferences.
final nowPlayingFallbackColorNotifier = ValueNotifier<Color>(const Color(0xFF7C3AED));

/// Controls the navigation layout:
///   'auto' → wide rail when screen width ≥ 720 dp (default)
///   'on'   → always use the side rail (even on narrow screens)
///   'off'  → always use the bottom navigation bar
final pcModeNotifier = ValueNotifier<String>('auto');

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
    case 'blue':   return const Color(0xFF1D4ED8);
    case 'green':  return const Color(0xFF059669);
    case 'red':    return const Color(0xFFDC2626);
    case 'orange': return const Color(0xFFD97706);
    case 'pink':   return const Color(0xFFDB2777);
    case 'teal':   return const Color(0xFF0F766E);
    default:       return const Color(0xFF7C3AED);
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
///
/// Near-black and near-white have essentially zero chroma in HCT space.
/// Material 3 can't extract a hue from them and may fall back to an arbitrary
/// default (often teal). We map these extremes to a Blue Grey seed that has
/// just enough chroma to produce a reliable neutral scheme.
Color seedColorForScheme(Color c) {
  final luminance = c.computeLuminance();

  // Near-black → Blue Grey 700: neutral dark slate scheme
  if (luminance < 0.03) return const Color(0xFF455A64);

  // Near-white → Blue Grey 300: neutral light scheme
  if (luminance > 0.97) return const Color(0xFF90A4AE);

  return c;
}