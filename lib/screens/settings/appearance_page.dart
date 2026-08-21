// lib/screens/settings/appearance_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../nothing_theme.dart';
import '../../l10n/l10n.dart';
import '../../services/widget_service.dart';
import 'settings_helpers.dart';
import 'pc_mode_section.dart';

// Local haptic helper for appearance page.
void _apHaptic() {
  if (hapticFeedbackNotifier.value) HapticFeedback.lightImpact();
}

// Local 2-language helper (French/English) — this file isn't part of the
// home_screen.dart library so it can't reuse the shared _ct() defined there.
String _ct(String fr, String en) => localeNotifier.value == 'en' ? en : fr;

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  String _themeStyle           = 'default';
  String _nothingAccent        = 'classic';
  String _theme                = 'system';
  String _accent               = 'purple';
  bool   _useDynamicColor      = false;
  bool   _useNowPlayingColor   = false;
  bool   _artworkColorTheme    = false;
  bool   _keepLastArtworkColor = false;
  bool   _oledMode             = false;
  Color  _fallbackAccent       = const Color(0xFF7C3AED);
  bool   _useDayNightAccent    = false;
  String _accentDark           = 'purple';
  bool   _dayNightUseHours     = false;
  int    _dayStartHour         = 7;
  int    _nightStartHour       = 20;

  @override
  void initState() {
    super.initState();
    _load();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    WidgetService.updateAll(); // push new accent/theme to home screen widgets
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _themeStyle           = p.getString('ls_theme_style')             ?? 'default';
      _nothingAccent        = p.getString('ls_nothing_accent')          ?? 'classic';
      _theme                = p.getString('ls_theme')                   ?? 'system';
      _accent               = p.getString('ls_accent')                  ?? 'purple';
      _useDynamicColor      = p.getBool('ls_use_dynamic_color')         ?? false;
      _useNowPlayingColor   = p.getBool('ls_use_nowplaying_color')      ?? false;
      _artworkColorTheme    = p.getBool('ls_artwork_color_theme')       ?? false;
      _keepLastArtworkColor = p.getBool('ls_keep_last_artwork_color')   ?? false;
      _oledMode             = p.getBool('ls_oled_mode')                 ?? false;
      final fbHex = p.getString('ls_nowplaying_fallback_color');
      _fallbackAccent = fbHex != null
          ? accentFromString(fbHex)
          : accentFromString(p.getString('ls_accent'));
      _useDayNightAccent = p.getBool('ls_use_daynight_accent')          ?? false;
      _accentDark        = p.getString('ls_accent_dark')                ?? _accent;
      _dayNightUseHours  = p.getBool('ls_daynight_use_hours')           ?? false;
      _dayStartHour      = p.getInt('ls_daynight_day_start_hour')       ?? 7;
      _nightStartHour    = p.getInt('ls_daynight_night_start_hour')     ?? 20;
    });
  }

  Future<void> _set<T>(String key, T v) async {
    final p = await SharedPreferences.getInstance();
    if (v is bool)   await p.setBool(key, v);
    if (v is String) await p.setString(key, v);
    if (v is int)    await p.setInt(key, v);
  }

  // Switch visual style.
  // When activating Nothing: explicitly disable dynamic and music color
  // so they don't silently stay on in the background.
  Future<void> _setStyle(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_theme_style', v);

    if (v == 'nothing') {
      await p.setBool('ls_use_dynamic_color',    false);
      await p.setBool('ls_use_nowplaying_color', false);
      setState(() {
        _themeStyle         = v;
        _useDynamicColor    = false;
        _useNowPlayingColor = false;
      });
      useDynamicColorNotifier.value    = false;
      useNowPlayingColorNotifier.value = false;
      accentNotifier.value = accentFromString(_accent);
    } else {
      setState(() => _themeStyle = v);
    }
    themeStyleNotifier.value = v;
  }

  Future<void> _setNothingAccent(String v) async {
    await _set('ls_nothing_accent', v);
    setState(() => _nothingAccent = v);
    nothingAccentNotifier.value = v;
  }

  Future<void> _setTheme(String v) async {
    await _set('ls_theme', v);
    setState(() => _theme = v);
    themeModeNotifier.value = themeFromString(v);
  }

  Future<void> _setAccentPreset(String key, Color color) async {
    await _set('ls_accent', key);
    setState(() => _accent = key);
    if (!_useDynamicColor && !_useNowPlayingColor) accentNotifier.value = color;
  }

  Future<void> _pickCustomColor() async {
    if (_useDynamicColor || _useNowPlayingColor) return;
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(initialColor: accentNotifier.value),
    );
    if (result != null && mounted) {
      final hex = colorToHex(result);
      await _set('ls_accent', hex);
      setState(() => _accent = hex);
      accentNotifier.value = result;
    }
  }

  Future<void> _pickFallbackColor() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(initialColor: _fallbackAccent),
    );
    if (result != null && mounted) {
      final hex = colorToHex(result);
      await _set('ls_nowplaying_fallback_color', hex);
      setState(() => _fallbackAccent = result);
      nowPlayingFallbackColorNotifier.value = result;
      accentNotifier.value = result;
    }
  }

  Future<void> _setUseDayNightAccent(bool v) async {
    await _set('ls_use_daynight_accent', v);
    setState(() => _useDayNightAccent = v);
    useDayNightAccentNotifier.value = v;
  }

  Future<void> _setDayNightUseHours(bool v) async {
    await _set('ls_daynight_use_hours', v);
    setState(() => _dayNightUseHours = v);
    dayNightUseHoursNotifier.value = v;
  }

  Future<void> _pickDarkAccentColor() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(initialColor: accentDarkNotifier.value),
    );
    if (result != null && mounted) {
      final hex = colorToHex(result);
      await _set('ls_accent_dark', hex);
      setState(() => _accentDark = hex);
      accentDarkNotifier.value = result;
    }
  }

  Future<void> _setDayStartHour(int h) async {
    await _set('ls_daynight_day_start_hour', h);
    setState(() => _dayStartHour = h);
    dayStartHourNotifier.value = h;
  }

  Future<void> _setNightStartHour(int h) async {
    await _set('ls_daynight_night_start_hour', h);
    setState(() => _nightStartHour = h);
    nightStartHourNotifier.value = h;
  }

  bool get _isCustomAccent =>
      _accent.startsWith('#') ||
      !kSettingsAccentOptions.any((o) => o.$2 == _accent);

  bool get _isNothing => _themeStyle == 'nothing';

  // What's grayed out when Nothing is active:
  //   OLED          → yes (Nothing dark is inherently OLED black — redundant)
  //   Accent color  → yes (Nothing uses its own color system)
  //   Dynamic color → yes (conflicts with Nothing style)
  //   Music color   → yes (conflicts with Nothing style)
  // What stays active:
  //   Theme (light/dark/system) → NO — user can pick light or dark Nothing
  //   Artwork color theme       → NO — affects detail sheets independently
  //   PC/layout mode            → NO — unrelated to visual style

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsAppearance),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ══════════════════════════════════════════════════════════════════
        //  Style selector
        // ══════════════════════════════════════════════════════════════════
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            L.apVisualStyle,
            style: text.labelMedium?.copyWith(
                color: scheme.primary, fontWeight: FontWeight.w700,
                letterSpacing: 0.8),
          ),
        ),

        Row(children: [
          Expanded(child: _StyleCard(
            selected:  !_isNothing,
            onTap:     () => _setStyle('default'),
            showDark:  false, // uses scheme surfaceContainerHighest
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _dot(scheme.primary),
                  const SizedBox(width: 4),
                  _dot(scheme.secondary),
                  const SizedBox(width: 4),
                  _dot(scheme.tertiary),
                ]),
                const Spacer(),
                Text('Material You',
                    style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(L.apStyleDefault,
                    style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700)),
              ],
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: _StyleCard(
            selected:    _isNothing,
            onTap:       () { _apHaptic(); _setStyle('nothing'); },
            showDark:    _theme != 'light', // light preview when light mode chosen
            accentColor: kNothingRed,
            child: Builder(builder: (ctx) {
              final cardDark  = _theme != 'light';
              final textCol   = cardDark ? kNothingWhite      : kNothingDarkText;
              final metaCol   = cardDark ? kNothingGrey       : const Color(0xFF6B6560);
              final dotFaded  = cardDark
                  ? kNothingWhite.withValues(alpha: 0.15)
                  : kNothingDarkText.withValues(alpha: 0.12);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _dot(kNothingRed),
                    const SizedBox(width: 4),
                    if (_nothingAccent == 'mixed') ...[
                      _dot(kNothingYellow),
                      const SizedBox(width: 4),
                    ],
                    _dot(dotFaded),
                  ]),
                  const Spacer(),
                  Text('nothing.',
                      style: TextStyle(fontFamily: 'NType82', fontSize: 10,
                          color: metaCol, letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text('Nothing OS',
                      style: TextStyle(fontFamily: 'NType82', fontSize: 14,
                          fontWeight: FontWeight.w700, color: textCol)),
                ],
              );
            }),
          )),
        ]),

        // ── Nothing sub-options (shown only when Nothing is active) ───────
        if (_isNothing) ...[
          const SizedBox(height: 12),

          // Accent variant picker
          _NothingPanel(
            isDark: _theme != 'light',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NothingLabel(L.apNothingAccentLabel),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _NothingAccentTile(
                    color:    kNothingRed,
                    label:    L.apNothingClassic,
                    sublabel: 'Red #FF2020',
                    desc:     L.apRedOnlyDesc,
                    selected: _nothingAccent == 'classic',
                    isDark:   _theme != 'light',
                    onTap:    () { _apHaptic(); _setNothingAccent('classic'); },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _NothingAccentTile(
                    color:    kNothingRed,
                    color2:   kNothingYellow,
                    label:    L.apNothingMixed,
                    sublabel: '+ Yellow #FFC700',
                    desc:     L.apRedYellowDesc,
                    selected: _nothingAccent == 'mixed',
                    isDark:   _theme != 'light',
                    onTap:    () { _apHaptic(); _setNothingAccent('mixed'); },
                  )),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Active banner
          _NothingInfoBanner(
            L.apNothingActiveBanner,
          ),
        ],

        const SizedBox(height: 20),

        // ══════════════════════════════════════════════════════════════════
        //  Theme — ALWAYS active (Nothing supports light + dark)
        // ══════════════════════════════════════════════════════════════════
        SettingsSection(label: L.settingsTheme, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.contrast_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsTheme,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'system',
                      icon: const Icon(Icons.brightness_auto_rounded),
                      label: Text(L.settingsThemeAuto)),
                  ButtonSegment(value: 'light',
                      icon: const Icon(Icons.light_mode_rounded),
                      label: Text(L.settingsThemeLight)),
                  ButtonSegment(value: 'dark',
                      icon: const Icon(Icons.dark_mode_rounded),
                      label: Text(L.settingsThemeDark)),
                ],
                selected: {_theme},
                onSelectionChanged: (s) => _setTheme(s.first),
                style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
              // When Nothing is active, explain OLED is built-in for dark
              if (_isNothing) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13,
                      color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    L.apNothingOledInherent,
                    style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant),
                  )),
                ]),
              ],
            ],
          )),

          // OLED toggle — grayed out when Nothing is active (redundant)
          const Divider(height: 1, indent: 16, endIndent: 16),
          Opacity(
            opacity: _isNothing ? 0.3 : (_theme == 'light' ? 0.4 : 1.0),
            child: IgnorePointer(
              ignoring: _isNothing || _theme == 'light',
              child: SwitchListTile(
                secondary: Icon(Icons.phone_android_rounded,
                    color: scheme.primary),
                title: Text(L.apOledTitle),
                subtitle: Text(_isNothing
                    ? L.apOledBuiltIntoNothing
                    : L.apOledPureBlack),
                value: _isNothing ? false : _oledMode,
                onChanged: _isNothing || _theme == 'light'
                    ? null
                    : (v) async {
                        await _set('ls_oled_mode', v);
                        setState(() => _oledMode = v);
                        oledModeNotifier.value = v;
                      },
              ),
            ),
          ),
        ]),

        const SizedBox(height: 16),

        // ══════════════════════════════════════════════════════════════════
        //  Accent color — grayed out when Nothing is active
        // ══════════════════════════════════════════════════════════════════
        Opacity(
          opacity: _isNothing ? 0.3 : 1.0,
          child: IgnorePointer(
            ignoring: _isNothing,
            child: SettingsSection(label: L.settingsAccentColor, children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.palette_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(L.settingsAccentColor,
                        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (_useDynamicColor || _useNowPlayingColor) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: scheme.outlineVariant)),
                        child: Text(L.settingsAccentAuto,
                            style: text.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant))),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: (_useDynamicColor || _useNowPlayingColor) ? 0.35 : 1.0,
                    child: Wrap(spacing: 10, runSpacing: 10, children: [
                      ...kSettingsAccentOptions.map((opt) {
                        final (color, key, label) = opt;
                        final sel = _accent == key;
                        return GestureDetector(
                          onTap: (_useDynamicColor || _useNowPlayingColor)
                              ? null : () => _setAccentPreset(key, color),
                          child: Tooltip(
                            message: label,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color:  color,
                                shape:  BoxShape.circle,
                                border: Border.all(
                                    color: sel ? scheme.onSurface : Colors.transparent,
                                    width: 2.5),
                                boxShadow: sel
                                    ? [BoxShadow(color: color.withValues(alpha: 0.5),
                                          blurRadius: 6)]
                                    : null,
                              ),
                              child: sel
                                  ? Icon(Icons.check_rounded, size: 18,
                                      color: ThemeData.estimateBrightnessForColor(color) ==
                                              Brightness.dark
                                          ? Colors.white : Colors.black)
                                  : null,
                            ),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: (_useDynamicColor || _useNowPlayingColor)
                            ? null : _pickCustomColor,
                        child: Tooltip(
                          message: L.apCustomColorTooltip,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color:  _isCustomAccent ? accentNotifier.value : null,
                              shape:  BoxShape.circle,
                              border: Border.all(
                                  color: _isCustomAccent
                                      ? scheme.onSurface : scheme.outlineVariant,
                                  width: _isCustomAccent ? 2.5 : 1.5),
                            ),
                            child: Icon(Icons.colorize_rounded, size: 18,
                                color: _isCustomAccent
                                    ? (ThemeData.estimateBrightnessForColor(
                                            accentNotifier.value) ==
                                        Brightness.dark
                                        ? Colors.white : Colors.black)
                                    : scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  if (_isCustomAccent && !_useDynamicColor && !_useNowPlayingColor) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(width: 18, height: 18,
                          decoration: BoxDecoration(
                              color: accentNotifier.value, shape: BoxShape.circle,
                              border: Border.all(color: scheme.outlineVariant))),
                      const SizedBox(width: 8),
                      Text(colorToHex(accentNotifier.value),
                          style: text.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: scheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      TextButton(onPressed: _pickCustomColor,
                          child: Text(L.settingsCustomColorEdit)),
                    ]),
                  ],
                ],
              )),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ══════════════════════════════════════════════════════════════════
        //  Day/night accent — separate colors for light vs dark theme
        // ══════════════════════════════════════════════════════════════════
        Opacity(
          opacity: (_isNothing || _useDynamicColor || _useNowPlayingColor) ? 0.3 : 1.0,
          child: IgnorePointer(
            ignoring: _isNothing || _useDynamicColor || _useNowPlayingColor,
            child: SettingsSection(label: L.settingsDayNightAccent, children: [
              SwitchListTile(
                secondary: Icon(Icons.brightness_4_rounded, color: scheme.primary),
                title:    Text(L.settingsDayNightAccentToggle),
                subtitle: Text(L.settingsDayNightAccentToggleSub),
                value:    _useDayNightAccent,
                onChanged: _setUseDayNightAccent,
              ),
              if (_useDayNightAccent) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(children: [
                    Icon(Icons.dark_mode_rounded, size: 20, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(L.settingsDayNightAccentDark,
                        style: text.bodyMedium)),
                    GestureDetector(
                      onTap: _pickDarkAccentColor,
                      child: Container(width: 28, height: 28,
                          decoration: BoxDecoration(
                              color: accentDarkNotifier.value, shape: BoxShape.circle,
                              border: Border.all(color: scheme.outlineVariant))),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 16, 8),
                  child: Text(colorToHex(accentDarkNotifier.value),
                      style: text.bodySmall?.copyWith(
                          fontFamily: 'monospace', color: scheme.onSurfaceVariant)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.schedule_rounded, color: scheme.onSurfaceVariant),
                  title:    Text(L.settingsDayNightUseHours),
                  subtitle: Text(L.settingsDayNightUseHoursSub),
                  value:    _dayNightUseHours,
                  onChanged: _setDayNightUseHours,
                ),
                if (_dayNightUseHours) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.wb_sunny_rounded, color: scheme.onSurfaceVariant),
                    title:   Text(L.settingsDayNightDayStart),
                    trailing: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: _dayStartHour, minute: 0));
                        if (t != null) _setDayStartHour(t.hour);
                      },
                      child: Text('${_dayStartHour.toString().padLeft(2, '0')}:00'),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.nightlight_round, color: scheme.onSurfaceVariant),
                    title:   Text(L.settingsDayNightNightStart),
                    trailing: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: _nightStartHour, minute: 0));
                        if (t != null) _setNightStartHour(t.hour);
                      },
                      child: Text('${_nightStartHour.toString().padLeft(2, '0')}:00'),
                    ),
                  ),
                ],
              ],
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ══════════════════════════════════════════════════════════════════
        //  Dynamic color — grayed out when Nothing is active
        // ══════════════════════════════════════════════════════════════════
        Opacity(
          opacity: _isNothing ? 0.3 : 1.0,
          child: IgnorePointer(
            ignoring: _isNothing,
            child: SettingsSection(label: L.settingsDynamicColor, children: [
              SwitchListTile(
                secondary: Icon(Icons.colorize_rounded, color: scheme.primary),
                title:    Text(L.settingsMaterialYou),
                subtitle: Text(L.settingsMaterialYouSub),
                value:    _useDynamicColor,
                onChanged: (v) async {
                  await _set('ls_use_dynamic_color', v);
                  setState(() {
                    _useDynamicColor    = v;
                    if (v) _useNowPlayingColor = false;
                  });
                  useDynamicColorNotifier.value    = v;
                  useNowPlayingColorNotifier.value = false;
                  if (!v) accentNotifier.value = accentFromString(_accent);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: Icon(Icons.album_rounded,
                    color: _useDynamicColor
                        ? scheme.onSurfaceVariant : scheme.primary),
                title:    Text(L.settingsMusicColor),
                subtitle: Text(_useDynamicColor
                    ? L.settingsMusicColorLocked
                    : L.settingsMusicColorSub),
                value:    _useNowPlayingColor,
                onChanged: _useDynamicColor ? null : (v) async {
                  await _set('ls_use_nowplaying_color', v);
                  setState(() => _useNowPlayingColor = v);
                  useNowPlayingColorNotifier.value = v;
                  if (!v) accentNotifier.value = accentFromString(_accent);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(L.settingsMusicColorNote,
                    style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant)),
              ),
              if (_useNowPlayingColor && !_useDynamicColor) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.music_off_rounded, color: scheme.primary),
                  title: Text(L.apColorWhenNothingPlays),
                  subtitle: Text(
                    L.apColorWhenNothingPlaysSub,
                    style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant),
                  ),
                  trailing: GestureDetector(
                    onTap: _pickFallbackColor,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _fallbackAccent, shape: BoxShape.circle,
                        border: Border.all(
                            color: scheme.outlineVariant, width: 2),
                      ),
                    ),
                  ),
                  onTap: _pickFallbackColor,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 0, 16, 10),
                  child: Row(children: [
                    Container(width: 14, height: 14,
                        decoration: BoxDecoration(
                            color: _fallbackAccent, shape: BoxShape.circle,
                            border: Border.all(color: scheme.outlineVariant))),
                    const SizedBox(width: 6),
                    Text(colorToHex(_fallbackAccent),
                        style: text.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: scheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    TextButton(onPressed: _pickFallbackColor,
                        child: Text(L.settingsCustomColorEdit)),
                  ]),
                ),
              ],
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: Icon(Icons.palette_outlined, color: scheme.primary),
                title: Text(L.apKeepLastArtworkTitle),
                subtitle: Text(L.apKeepLastArtworkSub),
                value: _keepLastArtworkColor,
                onChanged: _useNowPlayingColor && !_useDynamicColor
                    ? (v) async {
                        await _set('ls_keep_last_artwork_color', v);
                        setState(() => _keepLastArtworkColor = v);
                        keepLastArtworkColorNotifier.value = v;
                      }
                    : null,
              ),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ══════════════════════════════════════════════════════════════════
        //  Artwork color theme — ALWAYS active (works in all styles)
        // ══════════════════════════════════════════════════════════════════
        SettingsSection(
          label: L.apDetailPagesSection,
          children: [
            SwitchListTile(
              secondary: Icon(Icons.style_rounded, color: scheme.primary),
              title: Row(children: [
                Flexible(child: Text(L.apArtworkColorTheme)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outlineVariant)),
                  child: Text(L.apBeta,
                      style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant)),
                ),
              ]),
              subtitle: Text(L.apArtworkColorThemeSub),
              value: _artworkColorTheme,
              onChanged: (v) async {
                await _set('ls_artwork_color_theme', v);
                setState(() => _artworkColorTheme = v);
                artworkColorThemeNotifier.value = v;
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Navigation bar labels — always active ────────────────────────
        _NavLabelSection(),

        const SizedBox(height: 16),

        // ── PC / responsive layout mode — always active ───────────────────
        const PcModeSection(),

        const SizedBox(height: 16),
        const _HapticSection(),

        const SizedBox(height: 16),
        const _LivingArtworkSection(),

        const SizedBox(height: 20),
        const RestartBanner(),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

Widget _dot(Color c) => Container(
  width: 10, height: 10,
  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
);

// ── Nothing OS panel container ────────────────────────────────────────────────

class _NothingPanel extends StatelessWidget {
  final Widget child;
  final bool   isDark;
  const _NothingPanel({required this.child, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DDD8);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _NothingLabel extends StatelessWidget {
  final String text;
  const _NothingLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 6, height: 6,
        decoration: const BoxDecoration(
            color: kNothingRed, shape: BoxShape.circle)),
    const SizedBox(width: 7),
    Text(text,
        style: const TextStyle(
            fontFamily: 'NType82', fontSize: 11,
            color: kNothingGrey, letterSpacing: 0.8,
            fontWeight: FontWeight.w500)),
  ]);
}

class _NothingInfoBanner extends StatelessWidget {
  final String message;
  const _NothingInfoBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color:        kNothingRed.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: kNothingRed.withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, size: 13, color: kNothingRed),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: const TextStyle(
              fontFamily: 'NType82', fontSize: 11,
              color: kNothingRed, letterSpacing: 0.1))),
    ]),
  );
}

// ── Nothing accent tile ───────────────────────────────────────────────────────

class _NothingAccentTile extends StatelessWidget {
  final Color   color;
  final Color?  color2;
  final String  label;
  final String  sublabel;
  final String  desc;
  final bool    selected;
  final bool    isDark;   // adapts bg to light/dark Nothing mode
  final VoidCallback onTap;

  const _NothingAccentTile({
    required this.color,
    required this.label,
    required this.sublabel,
    required this.desc,
    required this.selected,
    required this.onTap,
    this.color2,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg        = isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
    final bgSel     = color.withValues(alpha: isDark ? 0.08 : 0.06);
    final borderOff = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DDD8);
    final textCol   = isDark ? kNothingWhite : kNothingDarkText;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color:        selected ? bgSel : bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? color : borderOff,
              width: selected ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 11, color: Colors.black)
                  : null,
            ),
            if (color2 != null) ...[
              const SizedBox(width: 4),
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: color2, shape: BoxShape.circle)),
            ],
          ]),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontFamily: 'NType82', fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : textCol)),
          const SizedBox(height: 2),
          Text(sublabel,
              style: TextStyle(
                  fontFamily: 'NType82Mono', fontSize: 9,
                  color: kNothingGrey, letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(desc,
              style: TextStyle(
                  fontFamily: 'NType82', fontSize: 10, color: kNothingGrey)),
        ]),
      ),
    );
  }
}

// ── Style selector card ───────────────────────────────────────────────────────

class _StyleCard extends StatelessWidget {
  final bool         selected;
  final bool         showDark;  // true = dark preview card background
  final Color?       accentColor;
  final VoidCallback onTap;
  final Widget       child;

  const _StyleCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.showDark    = true,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ac     = accentColor ?? scheme.primary;
    // showDark=true → Nothing dark card preview (#0D0D0D)
    // showDark=false → uses current theme's surface (adapts to light/dark app theme)
    // For Nothing card in light mode: warm off-white (#F0EDE8)
    final bg = !showDark
        ? scheme.surfaceContainerHighest
        : const Color(0xFF0D0D0D);
    final border = selected
        ? ac
        : scheme.outlineVariant.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 96,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: selected ? 2 : 1),
          boxShadow: selected
              ? [BoxShadow(color: ac.withValues(alpha: 0.18),
                    blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: Stack(children: [
          child,
          if (selected)
            Positioned(
              top: 0, right: 0,
              child: Icon(Icons.check_circle_rounded,
                  size: 15, color: ac),
            ),
        ]),
      ),
    );
  }
}

// ── Nav label toggle ──────────────────────────────────────────────────────────

class _NavLabelSection extends StatefulWidget {
  const _NavLabelSection();
  @override
  State<_NavLabelSection> createState() => _NavLabelSectionState();
}

class _NavLabelSectionState extends State<_NavLabelSection> {
  bool _labels = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _labels = p.getBool('ls_nav_labels') ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SettingsSection(
      label: L.apNavBarSection,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.label_outline_rounded, color: scheme.primary),
          title: Text(L.apShowTabLabels),
          subtitle: Text(L.apShowTabLabelsSub),
          value: _labels,
          onChanged: (v) async {
            final p = await SharedPreferences.getInstance();
            await p.setBool('ls_nav_labels', v);
            setState(() => _labels = v);
            navLabelNotifier.value = v;
          },
        ),
      ],
    );
  }
}

// ── Living artwork (idle zoom + tilt parallax on covers) toggle ────────────

class _LivingArtworkSection extends StatefulWidget {
  const _LivingArtworkSection();
  @override
  State<_LivingArtworkSection> createState() => _LivingArtworkSectionState();
}

class _LivingArtworkSectionState extends State<_LivingArtworkSection> {
  bool _enabled = true;
  bool _achievementsOn = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() {
          _enabled = p.getBool('ls_living_artwork') ?? true;
          _achievementsOn = p.getBool('ls_achievements_enabled') ?? true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SettingsSection(
      label: L.apInteractionsSection,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.blur_on_rounded, color: scheme.primary),
          title: Text('Pochettes animées'),
          subtitle: Text('Zoom doux et effet de profondeur sur les images'),
          value: _enabled,
          onChanged: (v) async {
            final p = await SharedPreferences.getInstance();
            await p.setBool('ls_living_artwork', v);
            setState(() => _enabled = v);
            livingArtworkNotifier.value = v;
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.emoji_events_outlined, color: scheme.primary),
          title: Text(_ct('Succès et niveaux', 'Achievements and levels')),
          subtitle: Text(_ct('Paliers, badges et niveau de compte',
              'Tiers, badges, and account level')),
          value: _achievementsOn,
          onChanged: (v) async {
            final p = await SharedPreferences.getInstance();
            await p.setBool('ls_achievements_enabled', v);
            setState(() => _achievementsOn = v);
            achievementsEnabledNotifier.value = v;
          },
        ),
      ],
    );
  }
}

// ── Haptic feedback toggle ────────────────────────────────────────────────────

class _HapticSection extends StatefulWidget {
  const _HapticSection();
  @override
  State<_HapticSection> createState() => _HapticSectionState();
}

class _HapticSectionState extends State<_HapticSection> {
  bool _haptic = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _haptic = p.getBool('ls_haptic_feedback') ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SettingsSection(
      label: L.apInteractionsSection,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.vibration_rounded, color: scheme.primary),
          title: Text(L.onboardHapticTitle),
          subtitle: Text(L.apHapticFeedbackSub),
          value: _haptic,
          onChanged: (v) async {
            final p = await SharedPreferences.getInstance();
            await p.setBool('ls_haptic_feedback', v);
            setState(() => _haptic = v);
            hapticFeedbackNotifier.value = v;
            if (v) HapticFeedback.mediumImpact(); // confirm it works
          },
        ),
      ],
    );
  }
}