// lib/screens/settings/appearance_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../l10n.dart';
import 'settings_helpers.dart';
import 'pc_mode_section.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  String _theme               = 'system';
  String _accent              = 'purple';
  bool   _useDynamicColor     = false;
  bool   _useNowPlayingColor  = false;
  bool   _artworkColorTheme   = false; // tint detail sheets with artwork color
  bool   _keepLastArtworkColor = false; // keep last artwork color when nothing plays
  bool   _oledMode            = false; // pure black dark theme for OLED
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
      _theme               = p.getString('ls_theme')               ?? 'system';
      _accent              = p.getString('ls_accent')              ?? 'purple';
      _useDynamicColor     = p.getBool('ls_use_dynamic_color')     ?? false;
      _useNowPlayingColor  = p.getBool('ls_use_nowplaying_color')  ?? false;
      _artworkColorTheme   = p.getBool('ls_artwork_color_theme')   ?? false;
      _keepLastArtworkColor = p.getBool('ls_keep_last_artwork_color') ?? false;
      _oledMode            = p.getBool('ls_oled_mode')             ?? false;
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

  // OLED is only relevant when dark mode is active (dark or system).
  bool get _oledEnabled => _theme != 'light';

  @override
  Widget build(BuildContext context) {
    final scheme        = Theme.of(context).colorScheme;
    final text          = Theme.of(context).textTheme;
    final currentAccent = accentNotifier.value;
    final isEn          = localeNotifier.value == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsAppearance),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Theme ─────────────────────────────────────────────────────────
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
                  ButtonSegment(
                      value: 'system',
                      icon: const Icon(Icons.brightness_auto_rounded),
                      label: Text(L.settingsThemeAuto)),
                  ButtonSegment(
                      value: 'light',
                      icon: const Icon(Icons.light_mode_rounded),
                      label: Text(L.settingsThemeLight)),
                  ButtonSegment(
                      value: 'dark',
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

          // OLED mode: replaces all dark surfaces with pure black.
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(
              Icons.phone_android_rounded,
              color: _oledEnabled ? scheme.primary : scheme.onSurfaceVariant,
            ),
            title: Text(isEn ? 'OLED black theme' : 'Thème noir OLED'),
            subtitle: Text(isEn
                ? 'Pure black backgrounds when dark mode is active'
                : 'Fonds noirs purs quand le mode sombre est actif'),
            value: _oledMode,
            onChanged: _oledEnabled
                ? (v) async {
                    await _set('ls_oled_mode', v);
                    setState(() => _oledMode = v);
                    oledModeNotifier.value = v;
                  }
                : null,
          ),
        ]),

        const SizedBox(height: 16),

        // ── Accent colour ─────────────────────────────────────────────────
        SettingsSection(label: L.settingsAccentColor, children: [
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
                        style: text.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant))),
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
                          ? null
                          : () => _setAccentPreset(key, color),
                      child: Tooltip(
                          message: label,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel
                                    ? scheme.onSurface
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: sel
                                  ? [BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 6)]
                                  : null,
                            ),
                            child: sel
                                ? Icon(Icons.check_rounded,
                                    size: 18,
                                    color: ThemeData.estimateBrightnessForColor(color) ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black)
                                : null,
                          )),
                    );
                  }),
                  // Custom color swatch
                  GestureDetector(
                    onTap: (_useDynamicColor || _useNowPlayingColor)
                        ? null
                        : _pickCustomColor,
                    child: Tooltip(
                      message: isEn ? 'Custom color' : 'Couleur personnalisée',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _isCustomAccent ? currentAccent : null,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isCustomAccent
                                ? scheme.onSurface
                                : scheme.outlineVariant,
                            width: _isCustomAccent ? 2.5 : 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.colorize_rounded,
                          size: 18,
                          color: _isCustomAccent
                              ? (ThemeData.estimateBrightnessForColor(currentAccent) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              if (_isCustomAccent && !_useDynamicColor && !_useNowPlayingColor) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                          color: currentAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outlineVariant))),
                  const SizedBox(width: 8),
                  Text(colorToHex(currentAccent),
                      style: text.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  TextButton(
                      onPressed: _pickCustomColor,
                      child: Text(L.settingsCustomColorEdit)),
                ]),
              ],
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // ── Dynamic colour (Material You) ─────────────────────────────────
        SettingsSection(label: L.settingsDynamicColor, children: [
          SwitchListTile(
            secondary: Icon(Icons.colorize_rounded, color: scheme.primary),
            title: Text(L.settingsMaterialYou),
            subtitle: Text(L.settingsMaterialYouSub),
            value: _useDynamicColor,
            onChanged: (v) async {
              await _set('ls_use_dynamic_color', v);
              setState(() {
                _useDynamicColor = v;
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
                    ? scheme.onSurfaceVariant
                    : scheme.primary),
            title: Text(L.settingsMusicColor),
            subtitle: Text(_useDynamicColor
                ? L.settingsMusicColorLocked
                : L.settingsMusicColorSub),
            value: _useNowPlayingColor,
            onChanged: _useDynamicColor
                ? null
                : (v) async {
                    await _set('ls_use_nowplaying_color', v);
                    setState(() => _useNowPlayingColor = v);
                    useNowPlayingColorNotifier.value = v;
                    if (!v) accentNotifier.value = accentFromString(_accent);
                  },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(L.settingsMusicColorNote,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          if (_useNowPlayingColor && !_useDynamicColor) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.music_off_rounded, color: scheme.primary),
              title: Text(
                isEn ? 'Color when nothing plays' : 'Couleur quand rien ne joue',
              ),
              subtitle: Text(
                isEn
                    ? 'Accent used while no track is scrobbling'
                    : "Accent utilisé quand aucune piste n'est en cours",
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              trailing: GestureDetector(
                onTap: _pickFallbackColor,
                child: Tooltip(
                  message: isEn ? 'Pick fallback color' : 'Choisir la couleur de secours',
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _fallbackAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.outlineVariant, width: 2),
                    ),
                  ),
                ),
              ),
              onTap: _pickFallbackColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 10),
              child: Row(children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: _fallbackAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  colorToHex(_fallbackAccent),
                  style: text.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _pickFallbackColor,
                  child: Text(L.settingsCustomColorEdit),
                ),
              ]),
            ),
          ],

          // Keep last artwork color instead of resetting to fallback.
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.palette_outlined, color: scheme.primary),
            title: Text(isEn ? 'Keep last artwork color' : 'Garder la dernière couleur'),
            subtitle: Text(isEn
                ? 'When nothing is playing, keep the last artwork color instead of resetting'
                : 'Quand rien ne joue, conserver la couleur de la dernière pochette au lieu du fallback'),
            value: _keepLastArtworkColor,
            onChanged: _useNowPlayingColor && !_useDynamicColor
                ? (v) async {
                    await _set('ls_keep_last_artwork_color', v);
                    setState(() => _keepLastArtworkColor = v);
                    keepLastArtworkColorNotifier.value = v;
                  }
                : null,
          ),

          // Artwork color theme: tints detail sheet backgrounds and accents.
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.style_rounded, color: scheme.primary),
            title: Row(children: [
              Flexible(
                child: Text(isEn ? 'Artwork color theme' : "Thème couleur de l'affiche"),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant)),
                child: Text(isEn ? 'BETA' : 'BÊTA',
                    style: text.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ]),
            subtitle: Text(isEn
                ? "Detail pages adapt their background and accent colors to the artwork's dominant color"
                : "Les fiches adaptent leur fond et leurs couleurs d'accent à la couleur dominante de l'affiche"),
            value: _artworkColorTheme,
            onChanged: (v) async {
              await _set('ls_artwork_color_theme', v);
              setState(() => _artworkColorTheme = v);
              artworkColorThemeNotifier.value = v;
            },
          ),
        ]),

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