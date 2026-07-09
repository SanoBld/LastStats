// lib/screens/settings/startup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  int _startupTab = 0;
  String _platform = 'lastfm';
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() { localeNotifier.removeListener(_rebuild); super.dispose(); }

  void _rebuild() => setState(() {});

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _startupTab = p.getInt('ls_startup_tab') ?? 0;
      _platform   = p.getString('ls_music_platform') ?? 'lastfm';
      _showAll    = p.getBool('ls_show_all_platform_links') ?? false;
    });
  }

  Future<void> _setPlatform(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_music_platform', v);
    musicPlatformNotifier.value = v;
    setState(() => _platform = v);
  }

  Future<void> _setShowAll(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ls_show_all_platform_links', v);
    showAllPlatformLinksNotifier.value = v;
    setState(() => _showAll = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final isEn   = localeNotifier.value == 'en';
    final labels = buildStartupLabels();

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsStartupPage),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        SettingsSection(label: L.settingsStartupTab, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.rocket_launch_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsStartupTab,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Text(isEn
                  ? 'Choose the tab displayed when the app launches.'
                  : 'Choisissez l\'onglet affiché au lancement de l\'app.',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              ...labels.asMap().entries.map((e) {
                final sel = _startupTab == e.key;
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  color: sel ? scheme.primaryContainer : scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: sel ? scheme.primary.withValues(alpha: 0.6)
                                 : scheme.outlineVariant.withValues(alpha: 0.4),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final p = await SharedPreferences.getInstance();
                      await p.setInt('ls_startup_tab', e.key);
                      setState(() => _startupTab = e.key);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Icon(e.value.$1,
                            color: sel ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                            size: 22),
                        const SizedBox(width: 14),
                        Text(e.value.$2,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? scheme.onPrimaryContainer : scheme.onSurface,
                            )),
                        const Spacer(),
                        if (sel)
                          Icon(Icons.check_rounded,
                              color: scheme.onPrimaryContainer, size: 20),
                      ]),
                    ),
                  ),
                );
              }),
            ],
          )),
        ]),

        const SizedBox(height: 16),

        SettingsSection(label: L.settingsMusicPlatform, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.headphones_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsMusicPlatform,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Text(L.settingsMusicPlatformSub,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              ...[
                (value: 'lastfm',  icon: Icons.bar_chart_rounded,         asset: 'assets/icons/lastfm.svg',  label: L.platformLastfm),
                (value: 'spotify', icon: Icons.spatial_audio_off_rounded, asset: 'assets/icons/spotify.svg', label: L.platformSpotify),
                (value: 'ytmusic', icon: Icons.music_video_rounded,       asset: 'assets/icons/ytmusic.svg', label: L.platformYtMusic),
                (value: 'other',   icon: Icons.apps_rounded,              asset: null,                       label: L.platformOther),
              ].map((o) {
                final sel = _platform == o.value;
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  color: sel ? scheme.primaryContainer : scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: sel ? scheme.primary.withValues(alpha: 0.6)
                                 : scheme.outlineVariant.withValues(alpha: 0.4),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: _BrandGlyph(
                      asset: o.asset,
                      fallbackIcon: o.icon,
                      size: 22,
                      color: sel ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                    ),
                    title: Text(o.label, style: TextStyle(
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? scheme.onPrimaryContainer : scheme.onSurface)),
                    trailing: sel ? Icon(Icons.check_rounded, color: scheme.onPrimaryContainer) : null,
                    onTap: () => _setPlatform(o.value),
                  ),
                );
              }),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(L.settingsShowAllPlatformLinks,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(L.settingsShowAllPlatformLinksSub,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                value: _showAll,
                onChanged: _setShowAll,
              ),
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // Note de redémarrage
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(child: Text(
              isEn
                  ? 'The selected tab will appear on next launch of the app.'
                  : 'L\'onglet sélectionné apparaîtra au prochain démarrage de l\'app.',
              style: text.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
            )),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// Generic brand glyph: real SVG logo from assets/icons/ if present,
// falls back to a Material icon otherwise.
class _BrandGlyph extends StatelessWidget {
  final String? asset;
  final IconData fallbackIcon;
  final double size;
  final Color color;
  const _BrandGlyph({
    required this.asset,
    required this.fallbackIcon,
    required this.size,
    required this.color,
  });

  static final Map<String, bool> _existsCache = {};

  Future<bool> _exists(String path) async {
    if (_existsCache.containsKey(path)) return _existsCache[path]!;
    try {
      await rootBundle.load(path);
      return _existsCache[path] = true;
    } catch (_) {
      return _existsCache[path] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(fallbackIcon, size: size, color: color);
    if (asset == null) return fallback;
    return FutureBuilder<bool>(
      future: _exists(asset!),
      builder: (_, snap) {
        if (snap.data != true) return fallback;
        return SvgPicture.asset(asset!,
            width: size, height: size,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
      },
    );
  }
}