// lib/screens/settings/startup_page.dart

import 'package:flutter/material.dart';
import '../../l10n/extra_strings.dart';
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
      appBar: M3AppBar(title: L.settingsStartupPage),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        SettingsSection(label: L.settingsStartupTab, children: [
          SettingChoiceRow(
            icon: Icons.rocket_launch_rounded,
            title: L.settingsStartupTab,
            description: tx('ui_choose_the_tab_display'),
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
          // picking any other platform clears it). "other" used to sit
          // here too, but it read as a second "show everything" chip next
          // to "all" (its label literally said "tout afficher") — dropped,
          // kept as a legacy value only (see platformLinksShowAll).
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (key, icon) in const [
              ('all',     Icons.done_all_rounded),
              ('lastfm',  Icons.bar_chart_rounded),
              ('spotify', Icons.spatial_audio_off_rounded),
              ('ytmusic', Icons.music_video_rounded),
            ])
              M3Chip(
                avatar: Icon(icon, size: 16),
                label: Text(switch (key) {
                  'all'     => L.settingsShowAllPlatformLinks,
                  'lastfm'  => L.platformLastfm,
                  'spotify' => L.platformSpotify,
                  _         => L.platformYtMusic,
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
              tx('ui_the_selected_tab_will_'),
              style: text.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
            )),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}
