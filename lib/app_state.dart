import 'package:flutter/material.dart';

// ── Notifiers globaux ────────────────────────────────────────────────────────
final themeModeNotifier          = ValueNotifier<ThemeMode>(ThemeMode.system);
final accentNotifier             = ValueNotifier<Color>(const Color(0xFF7C3AED));
final useDynamicColorNotifier    = ValueNotifier<bool>(false);
final useNowPlayingColorNotifier = ValueNotifier<bool>(false);

ThemeMode themeFromString(String? s) {
  switch (s) {
    case 'light':  return ThemeMode.light;
    case 'dark':   return ThemeMode.dark;
    default:       return ThemeMode.system;
  }
}

/// Accepte une clé nommée ('purple', 'blue'…) ou un code hex '#RRGGBB'.
Color accentFromString(String? s) {
  if (s == null) return const Color(0xFF7C3AED);
  // Couleur hex personnalisée
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
    default:       return const Color(0xFF7C3AED); // purple
  }
}

/// Convertit une [Color] en chaîne '#RRGGBB' majuscule.
String colorToHex(Color c) {
  final r = (c.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final g = (c.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final b = (c.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}