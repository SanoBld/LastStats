// lib/screens/settings/appearance_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../nothing_theme.dart';
import '../../l10n.dart';
import 'settings_helpers.dart';
import 'pc_mode_section.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  String _themeStyle          = 'default';
  String _theme               = 'system';
  String _accent              = 'purple';
  bool   _useDynamicColor     = false;
  bool   _useNowPlayingColor  = false;
  bool   _artworkColorTheme   = false;
  bool   _keepLastArtworkColor = false;
  bool   _oledMode            = false;
  Color  _fallbackAccent      = const Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _load();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _themeStyle           = p.getString('ls_theme_style')             ?? 'default';
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
    });
  }

  Future<void> _set<T>(String key, T v) async {
    final p = await SharedPreferences.getInstance();
    if (v is bool)   await p.setBool(key, v);
    if (v is String) await p.setString(key, v);
  }

  // Switch visual style.
  // When activating Nothing: disable dynamic color and now-playing color.
  // Theme (light/dark/auto) remains user-controlled.
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

  bool get _isCustomAccent =>
      _accent.startsWith('#') ||
      !kSettingsAccentOptions.any((o) => o.$2 == _accent);

  bool get _isNothing => _themeStyle == 'nothing';

  // OLED only available in default style when not in light mode.
  bool get _oledEnabled => _theme != 'light' && !_isNothing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final isEn   = localeNotifier.value == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsAppearance),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ══════════════════════════════════════════════════════════════════
        //  Visual style selector
        // ══════════════════════════════════════════════════════════════════
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            isEn ? 'Visual style' : 'Style visuel',
            style: text.labelMedium?.copyWith(
                color: scheme.primary, fontWeight: FontWeight.w700,
                letterSpacing: 0.8),
          ),
        ),

        Row(children: [
          // ── Default card ──────────────────────────────────────────────
          Expanded(child: _StyleCard(
            selected: !_isNothing,
            onTap:    () => _setStyle('default'),
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
                    style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(isEn ? 'Default' : 'Défaut',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          )),

          const SizedBox(width: 12),

          // ── Nothing OS card ───────────────────────────────────────────
          Expanded(child: _StyleCard(
            selected: _isNothing,
            onTap:    () => _setStyle('nothing'),
            darkMode: true,
            accentColor: kNothingRed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _dot(kNothingRed),
                  const SizedBox(width: 4),
                  _dot(kNothingYellow),
                  const SizedBox(width: 4),
                  _dot(kNothingWhite.withValues(alpha: 0.12)),
                ]),
                const Spacer(),
                const Text('nothing.',
                    style: TextStyle(fontFamily: 'NType82', fontSize: 10,
                        color: kNothingGrey)),
                const SizedBox(height: 2),
                const Text('Nothing OS',
                    style: TextStyle(fontFamily: 'NType82', fontSize: 14,
                        fontWeight: FontWeight.w700, color: kNothingWhite)),
              ],
            ),
          )),
        ]),

        // Nothing active info banner
        if (_isNothing) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: kNothingRed.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kNothingRed.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: kNothingRed),
              const SizedBox(width: 8),
              Expanded(child: Text(
                isEn
                    ? 'Nothing OS style active — red & yellow palette. Accent and dynamic color are overridden.'
                    : 'Style Nothing OS actif — palette rouge & jaune. Accent et couleur dynamique sont ignorés.',
                style: const TextStyle(
                  fontFamily: 'NType82', fontSize: 12, color: kNothingRed,
                ),
              )),
            ]),
          ),
        ],

        const SizedBox(height: 20),

        // ══════════════════════════════════════════════════════════════════
        //  Theme — always active, even in Nothing style.
        //  OLED toggle inside is still disabled under Nothing (redundant).
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
            ],
          )),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // OLED: disabled under Nothing (already pure black) or in light mode.
          Opacity(
            opacity: _oledEnabled ? 1.0 : 0.4,
            child: SwitchListTile(
              secondary: Icon(Icons.phone_android_rounded,
                  color: _oledEnabled ? scheme.primary : scheme.onSurfaceVariant),
              title: Text(isEn ? 'OLED black theme' : 'Thème noir OLED'),
              subtitle: Text(_isNothing
                  ? (isEn ? 'Not available in Nothing OS style' : 'Non disponible avec le style Nothing OS')
                  : (isEn
                      ? 'Pure black backgrounds when dark mode is active'
                      : 'Fonds noirs purs quand le mode sombre est actif')),
              value: _oledMode,
              onChanged: _oledEnabled
                  ? (v) async {
                      await _set('ls_oled_mode', v);
                      setState(() => _oledMode = v);
                      oledModeNotifier.value = v;
                    }
                  : null,
            ),
          ),
        ]),

        const SizedBox(height: 16),

        // ══════════════════════════════════════════════════════════════════
        //  Accent color — disabled when Nothing is active
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
                                              Brightness.dark ? Colors.white : Colors.black)
                                  : null,
                            ),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: (_useDynamicColor || _useNowPlayingColor)
                            ? null : _pickCustomColor,
                        child: Tooltip(
                          message: isEn ? 'Custom color' : 'Couleur personnalisée',
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
                                    ? (ThemeData.estimateBrightnessForColor(accentNotifier.value) ==
                                            Brightness.dark ? Colors.white : Colors.black)
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
                              fontFamily: 'monospace', color: scheme.onSurfaceVariant)),
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
        //  Dynamic color / Material You — disabled when Nothing is active
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
                    color: _useDynamicColor ? scheme.onSurfaceVariant : scheme.primary),
                title:    Text(L.settingsMusicColor),
                subtitle: Text(_useDynamicColor
                    ? L.settingsMusicColorLocked : L.settingsMusicColorSub),
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
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              if (_useNowPlayingColor && !_useDynamicColor) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.music_off_rounded, color: scheme.primary),
                  title: Text(isEn ? 'Color when nothing plays' : 'Couleur quand rien ne joue'),
                  subtitle: Text(
                    isEn ? 'Accent used while no track is scrobbling'
                         : "Accent utilisé quand aucune piste n'est en cours",
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  trailing: GestureDetector(
                    onTap: _pickFallbackColor,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _fallbackAccent, shape: BoxShape.circle,
                        border: Border.all(color: scheme.outlineVariant, width: 2),
                      ),
                    ),
                  ),
                  onTap: _pickFallbackColor,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 0, 16, 10),
                  child: Row(children: [
                    Container(width: 14, height: 14,
                        decoration: BoxDecoration(color: _fallbackAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.outlineVariant))),
                    const SizedBox(width: 6),
                    Text(colorToHex(_fallbackAccent),
                        style: text.bodySmall?.copyWith(
                            fontFamily: 'monospace', color: scheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    TextButton(onPressed: _pickFallbackColor,
                        child: Text(L.settingsCustomColorEdit)),
                  ]),
                ),
              ],
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: Icon(Icons.palette_outlined, color: scheme.primary),
                title: Text(isEn ? 'Keep last artwork color' : 'Garder la dernière couleur'),
                subtitle: Text(isEn
                    ? 'Keep last artwork color instead of resetting when nothing plays'
                    : 'Conserver la dernière couleur de pochette au lieu du fallback'),
                value: _keepLastArtworkColor,
                onChanged: _useNowPlayingColor && !_useDynamicColor
                    ? (v) async {
                        await _set('ls_keep_last_artwork_color', v);
                        setState(() => _keepLastArtworkColor = v);
                        keepLastArtworkColorNotifier.value = v;
                      }
                    : null,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: Icon(Icons.style_rounded, color: scheme.primary),
                title: Row(children: [
                  Flexible(child: Text(isEn
                      ? 'Artwork color theme' : "Thème couleur de l'affiche")),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outlineVariant)),
                    child: Text(isEn ? 'BETA' : 'BÊTA',
                        style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant)),
                  ),
                ]),
                subtitle: Text(isEn
                    ? "Detail pages adapt their colors to the artwork's dominant color"
                    : "Les fiches adaptent leurs couleurs à la couleur dominante de l'affiche"),
                value: _artworkColorTheme,
                onChanged: (v) async {
                  await _set('ls_artwork_color_theme', v);
                  setState(() => _artworkColorTheme = v);
                  artworkColorThemeNotifier.value = v;
                },
              ),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ── PC / responsive layout mode ───────────────────────────────────
        const PcModeSection(),

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

// ══════════════════════════════════════════════════════════════════════════
//  Style selector card
// ══════════════════════════════════════════════════════════════════════════

class _StyleCard extends StatelessWidget {
  final bool      selected;
  final bool      darkMode;
  final Color?    accentColor;
  final VoidCallback onTap;
  final Widget    child;

  const _StyleCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.darkMode   = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ac     = accentColor ?? scheme.primary;

    final bg     = darkMode ? const Color(0xFF0D0D0D) : scheme.surfaceContainerHighest;
    final border = selected ? ac : scheme.outlineVariant.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 96,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: selected ? 2 : 1),
          boxShadow: selected
              ? [BoxShadow(color: ac.withValues(alpha: 0.2),
                    blurRadius: 10, spreadRadius: 1)]
              : null,
        ),
        child: Stack(children: [
          child,
          if (selected)
            Positioned(
              top: 0, right: 0,
              child: Icon(Icons.check_circle_rounded, size: 16, color: ac),
            ),
        ]),
      ),
    );
  }
}