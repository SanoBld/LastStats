// lib/supported_locales.dart
//
// Single source of truth for every language the app supports.
// Add a language HERE ONCE and it automatically shows up everywhere that
// reads this list (settings > Language page, first-connection setup
// screen, etc.) — no need to touch those screens again.
//
// To add a language:
//   1. Add its 4 strings (code, flag emoji, native name, English name) below.
//   2. Implement a matching `_AppStringsXx` class in l10n.dart.
//   3. Add the matching case to the `L` accessor's switch in l10n.dart.
// That's it — every screen that uses `kSupportedLocales` picks it up
// automatically, including layouts designed to scale to 10-20+ languages
// (e.g. wrapping chip rows instead of a fixed 2-slot layout).

class SupportedLocale {
  final String code;        // e.g. 'fr' — matches ls_locale / localeNotifier
  final String flag;        // emoji flag shown in pickers
  final String nativeName;  // name written in that language, e.g. 'Français'
  final String englishName; // name in English, e.g. 'French' (subtitle/a11y)

  const SupportedLocale({
    required this.code,
    required this.flag,
    required this.nativeName,
    required this.englishName,
  });
}

/// Every language currently translated in l10n.dart.
/// Order here = display order in every language picker.
const List<SupportedLocale> kSupportedLocales = [
  SupportedLocale(code: 'fr', flag: '🇫🇷', nativeName: 'Français', englishName: 'French'),
  SupportedLocale(code: 'en', flag: '🇬🇧', nativeName: 'English',  englishName: 'English'),
  SupportedLocale(code: 'es', flag: '🇪🇸', nativeName: 'Español',  englishName: 'Spanish'),
  SupportedLocale(code: 'zh', flag: '🇨🇳', nativeName: '中文',      englishName: 'Chinese'),
  SupportedLocale(code: 'pt', flag: '🇧🇷', nativeName: 'Português', englishName: 'Portuguese'),
  SupportedLocale(code: 'de', flag: '🇩🇪', nativeName: 'Deutsch',   englishName: 'German'),
  SupportedLocale(code: 'it', flag: '🇮🇹', nativeName: 'Italiano',  englishName: 'Italian'),
  SupportedLocale(code: 'ja', flag: '🇯🇵', nativeName: '日本語',     englishName: 'Japanese'),
  SupportedLocale(code: 'ru', flag: '🇷🇺', nativeName: 'Русский',   englishName: 'Russian'),
  SupportedLocale(code: 'ar', flag: '🇸🇦', nativeName: 'العربية',   englishName: 'Arabic'),
];

/// Looks up a [SupportedLocale] by code, falling back to French (the app's
/// default) if the stored code is somehow unknown (e.g. an old backup).
SupportedLocale supportedLocaleFor(String code) {
  for (final l in kSupportedLocales) {
    if (l.code == code) return l;
  }
  return kSupportedLocales.first;
}