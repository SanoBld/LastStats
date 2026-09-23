// lib/screens/settings/startup_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

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
          SettingChoiceRow(
            icon: Icons.rocket_launch_rounded,
            title: L.settingsStartupTab,
            description: isEn
                ? 'Choose the tab displayed when the app launches.'
                : 'Choisissez l\'onglet affiché au lancement de l\'app.',
            options: [
              for (final e in labels.asMap().entries) ('${e.key}', e.value.$2, e.value.$1),
            ],
            value: '$_startupTab',
            onChanged: (v) async {
              final p = await SharedPreferences.getInstance();
              await p.setInt('ls_startup_tab', int.parse(v));
              if (mounted) setState(() => _startupTab = int.parse(v));
            },
          ),
        ]),

        const SizedBox(height: 16),

        SettingsSection(label: L.settingsMusicPlatform, children: [
          Opacity(
            opacity: _showAll ? 0.45 : 1.0,
            child: IgnorePointer(
              ignoring: _showAll,
              child: SettingChoiceRow(
                icon: Icons.headphones_rounded,
                title: L.settingsMusicPlatform,
                description: _showAll ? L.settingsPlatformDisabledByShowAll : L.settingsMusicPlatformSub,
                options: [
                  ('lastfm',  L.platformLastfm,  Icons.bar_chart_rounded),
                  ('spotify', L.platformSpotify, Icons.spatial_audio_off_rounded),
                  ('ytmusic', L.platformYtMusic, Icons.music_video_rounded),
                  ('other',   L.platformOther,   Icons.apps_rounded),
                ],
                value: _platform,
                onChanged: _setPlatform,
              ),
            ),
          ),
          SettingSwitchRow(
            icon: Icons.link_rounded,
            title: L.settingsShowAllPlatformLinks,
            subtitle: L.settingsShowAllPlatformLinksSub,
            value: _showAll,
            onChanged: _setShowAll,
          ),
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
