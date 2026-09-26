// lib/screens/settings/startup_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import '../../widgets/m3_components.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  int _startupTab = 0;
  Set<String> _platforms = {}; // empty == show every platform link

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
    // Migrates the old separate "show all" switch into the "all" entry.
    final legacyShowAll = p.getBool('ls_show_all_platform_links') ?? false;
    final raw = legacyShowAll ? 'all' : (p.getString('ls_music_platform') ?? '');
    setState(() {
      _startupTab = p.getInt('ls_startup_tab') ?? 0;
      _platforms  = raw.split(',').where((e) => e.isNotEmpty).toSet();
    });
  }

  Future<void> _togglePlatform(String key) async {
    setState(() {
      if (key == 'all') {
        _platforms = _platforms.contains('all') ? {} : {'all'};
      } else {
        _platforms.remove('all');
        if (!_platforms.remove(key)) _platforms.add(key);
      }
    });
    final p = await SharedPreferences.getInstance();
    final joined = _platforms.join(',');
    await p.setString('ls_music_platform', joined);
    await p.remove('ls_show_all_platform_links'); // fully replaced by "all" now
    musicPlatformNotifier.value = joined;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
              L.settingsMusicPlatformSub,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          // Multi-select — pick every platform used; "Tout afficher" is
          // exclusive with the rest (picking it clears the others, and
          // picking any other platform clears it). No more separate
          // duplicate "show all" switch — it's just one of these chips now.
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (key, icon) in const [
              ('all',     Icons.done_all_rounded),
              ('spotify', Icons.spatial_audio_off_rounded),
              ('ytmusic', Icons.music_video_rounded),
              ('other',   Icons.apps_rounded),
            ])
              M3Chip(
                avatar: Icon(icon, size: 16),
                label: Text(switch (key) {
                  'all'     => L.settingsShowAllPlatformLinks,
                  'spotify' => L.platformSpotify,
                  'ytmusic' => L.platformYtMusic,
                  _         => L.platformOther,
                }),
                selected: _platforms.contains(key),
                onSelected: (_) => _togglePlatform(key),
              ),
          ]),
        ]),

        const SizedBox(height: 16),

        // Note de redémarrage
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
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
