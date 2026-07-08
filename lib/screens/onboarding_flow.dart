// lib/screens/onboarding_flow.dart
//
// Shown once, right after the first scrobble load, before entering HomeScreen.
// 3 pages: appearance, notifications, favorite profiles.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';
import '../app_state.dart';
import '../services/lastfm_service.dart';
import 'home_screen.dart';
import 'settings/settings_helpers.dart';

class OnboardingFlow extends StatefulWidget {
  final String username, apiKey;
  const OnboardingFlow({super.key, required this.username, required this.apiKey});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageCtrl = PageController();
  int _page = 0;
  static const _pages = 7;

  void _goTo(int i) {
    setState(() => _page = i);
    _pageCtrl.animateToPage(i,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _finish() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, _, _) =>
          HomeScreen(username: widget.username, apiKey: widget.apiKey),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // ── Top bar: progress dots + skip ──────────────────────────────
          // ── Top progress bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (_page + 1) / _pages),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v, minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
            child: Row(children: [
              Text('${_page + 1}/$_pages',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(onPressed: _finish, child: Text(L.onboardSkip)),
            ]),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                const _AppearanceStep(), const _NotificationsStep(), const _DashboardStep(),
                const _StartupStep(), const _MusicPlatformStep(), const _UpdatesStep(),
                _FavoritesStep(username: widget.username, apiKey: widget.apiKey),
              ],
            ),
          ),
          // ── Bottom nav ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(children: [
              if (_page > 0)
                TextButton(onPressed: () => _goTo(_page - 1), child: Text(L.onboardBack)),
              const Spacer(),
              FilledButton(
                onPressed: () => _page == _pages - 1 ? _finish() : _goTo(_page + 1),
                child: Text(_page == _pages - 1 ? L.onboardFinish : L.onboardNext),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Shared step scaffold ─────────────────────────────────────────────────────
class _Step extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget child;
  const _Step({required this.icon, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: scheme.onPrimaryContainer, size: 28),
      ),
      const SizedBox(height: 18),
      Text(title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(subtitle, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 26),
      child,
    ]);
  }
}

// ── Step 1: Appearance (theme, accent, Material You) ────────────────────────
class _AppearanceStep extends StatefulWidget {
  const _AppearanceStep();
  @override
  State<_AppearanceStep> createState() => _AppearanceStepState();
}

class _AppearanceStepState extends State<_AppearanceStep> {
  static const _accents = [
    ('purple', Color(0xFF7C3AED)), ('blue', Color(0xFF1D4ED8)),
    ('green', Color(0xFF059669)),  ('red', Color(0xFFDC2626)),
    ('orange', Color(0xFFD97706)), ('pink', Color(0xFFDB2777)),
    ('teal', Color(0xFF0F766E)),   ('neutral', Color(0xFF607D8B)),
  ];

  Future<void> _setTheme(ThemeMode m, String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_theme', key);
    themeModeNotifier.value = m;
  }

  Future<void> _setAccent(String key, Color c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_accent', key);
    await p.setBool('ls_use_dynamic_color', false);
    accentNotifier.value          = c;
    useDynamicColorNotifier.value = false;
    setState(() {});
  }

  Future<void> _setDynamic(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ls_use_dynamic_color', v);
    useDynamicColorNotifier.value = v;
    setState(() {});
  }

  Future<void> _setStyle(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_theme_style', v);
    themeStyleNotifier.value = v;
    setState(() {});
  }

  Future<void> _setOled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ls_oled_mode', v);
    oledModeNotifier.value = v;
    setState(() {});
  }

  Future<void> _setNowPlayingColor(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ls_use_nowplaying_color', v);
    useNowPlayingColorNotifier.value = v;
    if (v) {
      await p.setBool('ls_use_dynamic_color', false);
      useDynamicColorNotifier.value = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<String>(
      valueListenable: themeStyleNotifier,
      builder: (_, style, _) => ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, _) => ValueListenableBuilder<bool>(
        valueListenable: useDynamicColorNotifier,
        builder: (_, dynamic_, _) => ValueListenableBuilder<Color>(
          valueListenable: accentNotifier,
          builder: (_, accent, _) => ValueListenableBuilder<bool>(
            valueListenable: oledModeNotifier,
            builder: (_, oled, _) => ValueListenableBuilder<bool>(
              valueListenable: useNowPlayingColorNotifier,
              builder: (_, nowPlayingColor, _) => _Step(
            icon: Icons.palette_rounded,
            title: L.onboardAppearanceTitle,
            subtitle: L.onboardAppearanceSub,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L.onboardStyle, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'default', icon: const Icon(Icons.auto_awesome_rounded), label: Text(L.onboardStyleMaterialYou)),
                  ButtonSegment(value: 'nothing', icon: const Icon(Icons.grid_on_rounded), label: Text(L.onboardStyleNothing)),
                ],
                selected: {style},
                onSelectionChanged: (s) => _setStyle(s.first),
              ),
              const SizedBox(height: 22),
              Text(L.settingsTheme, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_rounded), label: Text(L.settingsThemeAuto)),
                  ButtonSegment(value: ThemeMode.light,  icon: const Icon(Icons.light_mode_rounded),      label: Text(L.settingsThemeLight)),
                  ButtonSegment(value: ThemeMode.dark,   icon: const Icon(Icons.dark_mode_rounded),       label: Text(L.settingsThemeDark)),
                ],
                selected: {mode},
                onSelectionChanged: (s) => _setTheme(s.first, switch (s.first) {
                  ThemeMode.light => 'light', ThemeMode.dark => 'dark', _ => 'system',
                }),
              ),
              const SizedBox(height: 22),
              if (style == 'default') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(L.settingsDynamicColor, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(L.onboardDynamicColorSub,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  value: dynamic_,
                  onChanged: _setDynamic,
                ),
                if (!dynamic_) ...[
                  const SizedBox(height: 10),
                  Text(L.settingsAccentColor, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 12, runSpacing: 12, children: _accents.map((a) {
                    final sel = !dynamic_ && accent.toARGB32() == a.$2.toARGB32();
                    return GestureDetector(
                      onTap: () => _setAccent(a.$1, a.$2),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: a.$2, shape: BoxShape.circle,
                          border: sel ? Border.all(color: scheme.onSurface, width: 3) : null,
                        ),
                        child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList()),
                ],
                const SizedBox(height: 22),
                Text(L.onboardPreview, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  // Uses the theme's actual resolved colors (scheme.primary…)
                  // rather than the raw accent value, so it stays accurate
                  // and visible in every mode (custom, dynamic, artwork).
                  child: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    FilledButton.tonal(onPressed: () {}, child: Text(L.onboardPreviewButton)),
                    OutlinedButton(onPressed: () {}, child: Text(L.onboardPreviewOutline)),
                    Text(L.onboardPreviewText, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                    Chip(label: Text(L.onboardPreviewBubble),
                        backgroundColor: scheme.secondaryContainer,
                        labelStyle: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
                        side: BorderSide.none),
                  ]),
                ),
              ] else ...[
                Text(L.onboardAccentTint, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: nothingAccentNotifier,
                  builder: (_, nAccent, _) => SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'classic', label: Text(L.onboardNothingRedOnly)),
                      ButtonSegment(value: 'mixed', label: Text(L.onboardNothingRedYellow)),
                    ],
                    selected: {nAccent},
                    onSelectionChanged: (s) async {
                      final p = await SharedPreferences.getInstance();
                      await p.setString('ls_nothing_accent', s.first);
                      nothingAccentNotifier.value = s.first;
                    },
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text(L.onboardDisplay, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.contrast_rounded, color: scheme.primary),
                title: Text(L.onboardOledTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(L.onboardOledSub,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                value: oled,
                onChanged: _setOled,
              ),
              const Divider(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.image_rounded, color: scheme.primary),
                title: Text(L.onboardArtworkColorTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(L.onboardArtworkColorSub,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                value: nowPlayingColor,
                onChanged: _setNowPlayingColor,
              ),
            ]),
          ),
        ),
      ),
      ),
      ),
    ),
    );
  }
}

// ── Step 2: Notifications + haptics ──────────────────────────────────────────
class _NotificationsStep extends StatefulWidget {
  const _NotificationsStep();
  @override
  State<_NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends State<_NotificationsStep> {
  // Local-only prefs (no global ValueNotifier exists for these — same
  // pattern as NotificationsPage, which reads/writes them directly).
  bool _daily = true, _weekly = true, _milestones = true, _grand = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _daily      = p.getBool('ls_notif_daily_enabled')     ?? true;
      _weekly     = p.getBool('ls_notif_weekly_enabled')    ?? true;
      _milestones = p.getBool('ls_notif_milestone_enabled') ?? true;
      _grand      = p.getBool('ls_notif_grand_enabled')     ?? true;
    });
  }

  Future<void> _set(String key, bool v, ValueNotifier<bool> notifier) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
    notifier.value = v;
    if (v) HapticFeedback.selectionClick();
    setState(() {});
  }

  Future<void> _setLocal(String key, bool v, void Function(bool) apply) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
    if (v) HapticFeedback.selectionClick();
    setState(() => apply(v));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: notifNewsEnabledNotifier,
      builder: (_, news, _) => ValueListenableBuilder<bool>(
        valueListenable: hapticFeedbackNotifier,
        builder: (_, haptic, _) => ValueListenableBuilder<bool>(
          valueListenable: showNewsBadgeNotifier,
          builder: (_, badge, _) => _Step(
          icon: Icons.notifications_active_rounded,
          title: L.onboardNotifTitle,
          subtitle: L.onboardNotifSub,
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.campaign_rounded, color: scheme.primary),
              title: Text(L.onboardNewsTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(L.onboardNewsSub,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: news,
              onChanged: (v) => _set('ls_notif_news_enabled', v, notifNewsEnabledNotifier),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.circle_notifications_rounded, color: scheme.primary),
              title: Text(L.onboardNewsBadgeTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(L.onboardNewsBadgeSub,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: badge,
              onChanged: (v) => _set('ls_show_news_badge', v, showNewsBadgeNotifier),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.vibration_rounded, color: scheme.primary),
              title: Text(L.onboardHapticTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(L.onboardHapticSub,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: haptic,
              onChanged: (v) => _set('ls_haptic_feedback', v, hapticFeedbackNotifier),
            ),
            const SizedBox(height: 22),
            Align(alignment: Alignment.centerLeft, child: Text(
              L.onboardRecaps,
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
            )),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.today_rounded, color: scheme.primary),
              title: Text(L.onboardDailyRecapTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(L.onboardDailyRecapSub,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: _daily,
              onChanged: (v) => _setLocal('ls_notif_daily_enabled', v, (x) => _daily = x),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.date_range_rounded, color: scheme.primary),
              title: Text(L.onboardWeeklyRecapTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(L.onboardWeeklyRecapSub,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: _weekly,
              onChanged: (v) => _setLocal('ls_notif_weekly_enabled', v, (x) => _weekly = x),
            ),
            const SizedBox(height: 22),
            Align(alignment: Alignment.centerLeft, child: Text(
              L.onboardMilestonesSection,
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
            )),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.flag_rounded, color: scheme.primary),
              title: Text(L.onboardMilestonesTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(L.onboardMilestonesSub,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: _milestones,
              onChanged: (v) => _setLocal('ls_notif_milestone_enabled', v, (x) => _milestones = x),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.emoji_events_rounded, color: scheme.primary),
              title: Text(L.onboardGrandMilestonesTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(L.onboardGrandMilestonesSub,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: _grand,
              onChanged: (v) => _setLocal('ls_notif_grand_enabled', v, (x) => _grand = x),
            ),
          ]),
        )),
      ),
    );
  }
}

// ── Step 3: Dashboard sections ───────────────────────────────────────────────
class _DashboardStep extends StatefulWidget {
  const _DashboardStep();
  @override
  State<_DashboardStep> createState() => _DashboardStepState();
}

class _DashboardStepState extends State<_DashboardStep> {
  final Map<String, bool> _v = {
    'ls_show_nowplay': true, 'ls_show_stats': true, 'ls_show_artists': true,
    'ls_show_albums': true,
    'ls_show_tracks': true, 'ls_show_friends': true,
  };
  static const _labels = {
    'ls_show_nowplay': (Icons.graphic_eq_rounded, 'En cours d\'écoute', 'Now playing'),
    'ls_show_stats':   (Icons.bar_chart_rounded, 'Statistiques', 'Stats'),
    'ls_show_artists': (Icons.person_rounded, 'Top artistes', 'Top artists'),
    'ls_show_albums':  (Icons.album_rounded, 'Top albums', 'Top albums'),
    'ls_show_tracks':  (Icons.music_note_rounded, 'Top titres', 'Top tracks'),
    'ls_show_friends': (Icons.people_rounded, 'Amis', 'Friends'),
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { for (final k in _v.keys) { _v[k] = p.getBool(k) ?? true; } });
  }

  Future<void> _toggle(String k, bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(k, val);
    setState(() => _v[k] = val);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEn   = localeNotifier.value == 'en';
    return _Step(
      icon: Icons.dashboard_customize_rounded,
      title: L.onboardDashTitle, subtitle: L.onboardDashSub,
      child: Column(children: _v.keys.map((k) {
        final l = _labels[k]!;
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(l.$1, color: scheme.primary),
          title: Text(isEn ? l.$3 : l.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
          value: _v[k]!,
          onChanged: (v) => _toggle(k, v),
        );
      }).toList()),
    );
  }
}

// ── Step 4: Startup tab ──────────────────────────────────────────────────────
class _StartupStep extends StatefulWidget {
  const _StartupStep();
  @override
  State<_StartupStep> createState() => _StartupStepState();
}

class _StartupStepState extends State<_StartupStep> {
  int _tab = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _tab = p.getInt('ls_startup_tab') ?? 0);
  }

  Future<void> _set(int i) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('ls_startup_tab', i);
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = buildStartupLabels();
    return _Step(
      icon: Icons.rocket_launch_rounded,
      title: L.onboardStartupTitle, subtitle: L.onboardStartupSub,
      child: Column(children: labels.asMap().entries.map((e) {
        final sel = _tab == e.key;
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: sel ? scheme.primaryContainer : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: sel ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: ListTile(
            leading: Icon(e.value.$1, color: sel ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
            title: Text(e.value.$2, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
            trailing: sel ? Icon(Icons.check_rounded, color: scheme.onPrimaryContainer) : null,
            onTap: () => _set(e.key),
          ),
        );
      }).toList()),
    );
  }
}

// ── Step: Music platform (filters detail-sheet link pills) ──────────────────
class _MusicPlatformStep extends StatefulWidget {
  const _MusicPlatformStep();
  @override
  State<_MusicPlatformStep> createState() => _MusicPlatformStepState();
}

class _MusicPlatformStepState extends State<_MusicPlatformStep> {
  String _platform = 'lastfm';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _platform = p.getString('ls_music_platform') ?? 'lastfm');
  }

  Future<void> _set(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_music_platform', v);
    musicPlatformNotifier.value = v;
    setState(() => _platform = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = [
      (value: 'lastfm',  icon: Icons.bar_chart_rounded,        label: L.platformLastfm),
      (value: 'spotify', icon: Icons.spatial_audio_off_rounded, label: L.platformSpotify),
      (value: 'ytmusic', icon: Icons.music_video_rounded,      label: L.platformYtMusic),
      (value: 'other',   icon: Icons.apps_rounded,             label: L.platformOther),
    ];
    return _Step(
      icon: Icons.headphones_rounded,
      title: L.onboardPlatformTitle, subtitle: L.onboardPlatformSub,
      child: Column(children: options.map((o) {
        final sel = _platform == o.value;
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: sel ? scheme.primaryContainer : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: sel ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: ListTile(
            leading: Icon(o.icon, color: sel ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
            title: Text(o.label, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
            trailing: sel ? Icon(Icons.check_rounded, color: scheme.onPrimaryContainer) : null,
            onTap: () => _set(o.value),
          ),
        );
      }).toList()),
    );
  }
}

// ── Step 5: Updates ──────────────────────────────────────────────────────────
class _UpdatesStep extends StatefulWidget {
  const _UpdatesStep();
  @override
  State<_UpdatesStep> createState() => _UpdatesStepState();
}

class _UpdatesStepState extends State<_UpdatesStep> {
  bool _auto = true, _beta = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _auto = p.getBool('ls_auto_update_check') ?? true;
      _beta = p.getBool('ls_beta_channel')       ?? false;
    });
  }

  Future<void> _set(String k, bool v, void Function(bool) apply) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(k, v);
    setState(() => apply(v));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Step(
      icon: Icons.system_update_rounded,
      title: L.onboardUpdatesTitle, subtitle: L.onboardUpdatesSub,
      child: Column(children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(Icons.notifications_outlined, color: scheme.primary),
          title: Text(L.settingsAutoUpdate, style: const TextStyle(fontWeight: FontWeight.w700)),
          value: _auto,
          onChanged: (v) => _set('ls_auto_update_check', v, (x) => _auto = x),
        ),
        const Divider(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(Icons.science_outlined, color: scheme.primary),
          title: Text(L.onboardBetaTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(L.onboardBetaSub,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          value: _beta,
          onChanged: (v) => _set('ls_beta_channel', v, (x) => _beta = x),
        ),
      ]),
    );
  }
}

// ── Step 7: Favorite profiles ────────────────────────────────────────────────
class _FavoritesStep extends StatefulWidget {
  final String username, apiKey;
  const _FavoritesStep({required this.username, required this.apiKey});
  @override
  State<_FavoritesStep> createState() => _FavoritesStepState();
}

class _FavoritesStepState extends State<_FavoritesStep> {
  final _searchCtrl = TextEditingController();
  List<String> _favs = [];

  List<Map<String, dynamic>> _friends = [];
  bool _loadingFriends = true;

  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  Timer? _debounce;

  LastFmService get _service =>
      LastFmService(apiKey: widget.apiKey, username: widget.username);

  @override
  void initState() {
    super.initState();
    _load();
    _loadFriends();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Favorites are persisted independently from the live friends/search data —
  // toggling one off here only edits this local list, so a name chosen during
  // onboarding stays a favorite even if it later drops off your Last.fm
  // friends list or a fresh search doesn't return it.
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _favs = p.getStringList('ls_fav_profiles') ?? []);
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('ls_fav_profiles', _favs);
  }

  Future<void> _loadFriends() async {
    try {
      final list = await _service.getFriends(limit: 30, withRecentTrack: false);
      if (!mounted) return;
      setState(() {
        _friends = list.cast<Map<String, dynamic>>();
        _loadingFriends = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.isEmpty) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final list = await _service.searchUsers(query, limit: 10);
        if (!mounted) return;
        setState(() { _results = list.cast<Map<String, dynamic>>(); _searching = false; });
      } catch (_) {
        if (mounted) setState(() { _results = []; _searching = false; });
      }
    });
  }

  void _toggle(String name) {
    setState(() {
      _favs = _favs.contains(name)
          ? _favs.where((f) => f != name).toList()
          : [..._favs, name];
    });
    _persist();
  }

  String? _avatarUrl(Map<String, dynamic> user) {
    final imgs = user['image'];
    if (imgs is! List || imgs.isEmpty) return null;
    for (final img in imgs.reversed) {
      final url = img is Map ? (img['#text'] as String?) : null;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  Widget _userAvatar(String? url) {
    if (url != null) {
      return CircleAvatar(radius: 16, backgroundImage: NetworkImage(url));
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.transparent,
      child: _LastfmGlyph(size: 18, color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _userTile(Map<String, dynamic> user) {
    final name = (user['name'] ?? '').toString();
    if (name.isEmpty) return const SizedBox.shrink();
    final realname = (user['realname'] ?? '').toString();
    final sel = _favs.contains(name);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      color: sel ? scheme.primaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: sel ? scheme.primary.withValues(alpha: 0.6)
                                     : scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: _userAvatar(_avatarUrl(user)),
        title: Text(name, style: TextStyle(
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? scheme.onPrimaryContainer : scheme.onSurface)),
        subtitle: realname.isNotEmpty
            ? Text(realname, style: TextStyle(
                fontSize: 12,
                color: sel ? scheme.onPrimaryContainer.withValues(alpha: 0.8) : scheme.onSurfaceVariant))
            : null,
        trailing: Icon(sel ? Icons.star_rounded : Icons.star_border_rounded,
            color: sel ? scheme.primary : scheme.onSurfaceVariant),
        onTap: () => _toggle(name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Step(
      icon: Icons.favorite_rounded,
      title: L.onboardFavTitle,
      subtitle: L.onboardFavSub,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Search ──────────────────────────────────────────────────────
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: L.onboardFavSearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : null,
            border: const OutlineInputBorder(),
          ),
        ),

        if (_searchCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          if (!_searching && _results.isEmpty)
            Text(L.onboardFavNoResults, style: TextStyle(color: scheme.onSurfaceVariant))
          else
            ..._results.map(_userTile),
        ],

        const SizedBox(height: 20),

        // ── Suggested: your existing Last.fm friends ───────────────────
        Text(L.onboardFavFriendsTitle,
            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
        const SizedBox(height: 8),
        if (_loadingFriends)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_friends.isEmpty)
          Text(L.onboardFavNoFriends, style: TextStyle(color: scheme.onSurfaceVariant))
        else
          ..._friends.map(_userTile),

        const SizedBox(height: 20),

        // ── Currently selected favorites ────────────────────────────────
        if (_favs.isNotEmpty) ...[
          Text(L.onboardFavSelected,
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _favs.map((f) => Chip(
            label: Text(f),
            onDeleted: () => _toggle(f),
            avatar: _LastfmGlyph(size: 16, color: scheme.primary),
          )).toList()),
        ] else
          Text(L.onboardFavEmpty, style: TextStyle(color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

// Small Last.fm glyph reused across this file (separate library from
// home_screen.dart's private _PlatformGlyph, so re-implemented minimally here).
class _LastfmGlyph extends StatelessWidget {
  final double size;
  final Color color;
  const _LastfmGlyph({required this.size, required this.color});

  static bool? _exists;

  Future<bool> _check() async {
    if (_exists != null) return _exists!;
    try {
      await rootBundle.load('assets/icons/lastfm.svg');
      return _exists = true;
    } catch (_) {
      return _exists = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.bar_chart_rounded, size: size, color: color);
    return FutureBuilder<bool>(
      future: _check(),
      builder: (_, snap) {
        if (snap.data != true) return fallback;
        return SvgPicture.asset('assets/icons/lastfm.svg',
            width: size, height: size,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
      },
    );
  }
}