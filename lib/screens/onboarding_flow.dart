// lib/screens/onboarding_flow.dart
//
// Shown once, right after the first scrobble load, before entering HomeScreen.
// 3 pages: appearance, notifications, favorite profiles.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';
import '../app_state.dart';
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
  static const _pages = 6;

  void _goTo(int i) {
    setState(() => _page = i);
    _pageCtrl.animateToPage(i,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _finish() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          HomeScreen(username: widget.username, apiKey: widget.apiKey),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEn   = localeNotifier.value == 'en';

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
                builder: (_, v, __) => LinearProgressIndicator(
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
              children: const [
                _AppearanceStep(), _NotificationsStep(), _DashboardStep(),
                _StartupStep(), _UpdatesStep(), _FavoritesStep(),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEn   = localeNotifier.value == 'en';

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => ValueListenableBuilder<bool>(
        valueListenable: useDynamicColorNotifier,
        builder: (_, dynamic_, __) => ValueListenableBuilder<Color>(
          valueListenable: accentNotifier,
          builder: (_, accent, __) => _Step(
            icon: Icons.palette_rounded,
            title: L.onboardAppearanceTitle,
            subtitle: L.onboardAppearanceSub,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(L.settingsDynamicColor, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(isEn ? 'Use colors from your wallpaper (Android 12+)' : 'Utiliser les couleurs de ton fond d\'écran (Android 12+)',
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
            ]),
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
  Future<void> _set(String key, bool v, ValueNotifier<bool> notifier) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
    notifier.value = v;
    if (v) HapticFeedback.selectionClick();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEn   = localeNotifier.value == 'en';

    return ValueListenableBuilder<bool>(
      valueListenable: notifNewsEnabledNotifier,
      builder: (_, news, __) => ValueListenableBuilder<bool>(
        valueListenable: hapticFeedbackNotifier,
        builder: (_, haptic, __) => _Step(
          icon: Icons.notifications_active_rounded,
          title: L.onboardNotifTitle,
          subtitle: L.onboardNotifSub,
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.campaign_rounded, color: scheme.primary),
              title: Text(isEn ? 'News notifications' : 'Notifications d\'actualités', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(isEn ? 'Get notified about new features and fixes' : 'Sois notifié des nouvelles fonctions et correctifs',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: news,
              onChanged: (v) => _set('ls_notif_news_enabled', v, notifNewsEnabledNotifier),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.vibration_rounded, color: scheme.primary),
              title: Text(isEn ? 'Haptic feedback' : 'Retour haptique', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(isEn ? 'Feel subtle vibrations on key interactions' : 'Ressens de légères vibrations sur les interactions clés',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              value: haptic,
              onChanged: (v) => _set('ls_haptic_feedback', v, hapticFeedbackNotifier),
            ),
          ]),
        ),
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
    'ls_show_tracks': true, 'ls_show_friends': true,
  };
  static const _labels = {
    'ls_show_nowplay': (Icons.graphic_eq_rounded, 'En cours d\'écoute', 'Now playing'),
    'ls_show_stats':   (Icons.bar_chart_rounded, 'Statistiques', 'Stats'),
    'ls_show_artists': (Icons.person_rounded, 'Top artistes', 'Top artists'),
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
    final isEn   = localeNotifier.value == 'en';
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
          title: Text(isEn ? 'Beta updates' : 'Mises à jour bêta', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(isEn ? 'Early access to pre-releases' : 'Accès anticipé aux pré-versions',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          value: _beta,
          onChanged: (v) => _set('ls_beta_channel', v, (x) => _beta = x),
        ),
      ]),
    );
  }
}

// ── Step 6: Favorite profiles ────────────────────────────────────────────────
class _FavoritesStep extends StatefulWidget {
  const _FavoritesStep();
  @override
  State<_FavoritesStep> createState() => _FavoritesStepState();
}

class _FavoritesStepState extends State<_FavoritesStep> {
  final _ctrl = TextEditingController();
  List<String> _favs = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _favs = p.getStringList('ls_fav_profiles') ?? []);
  }

  Future<void> _add() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty || _favs.contains(name)) return;
    final p = await SharedPreferences.getInstance();
    setState(() { _favs = [..._favs, name]; _ctrl.clear(); });
    await p.setStringList('ls_fav_profiles', _favs);
  }

  Future<void> _remove(String name) async {
    final p = await SharedPreferences.getInstance();
    setState(() => _favs = _favs.where((f) => f != name).toList());
    await p.setStringList('ls_fav_profiles', _favs);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Step(
      icon: Icons.favorite_rounded,
      title: L.onboardFavTitle,
      subtitle: L.onboardFavSub,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: TextField(
            controller: _ctrl,
            decoration: InputDecoration(hintText: L.onboardFavHint, border: const OutlineInputBorder()),
            onSubmitted: (_) => _add(),
          )),
          const SizedBox(width: 8),
          FilledButton.tonal(onPressed: _add, child: Text(L.onboardFavAdd)),
        ]),
        const SizedBox(height: 18),
        if (_favs.isEmpty)
          Text(L.onboardFavEmpty, style: TextStyle(color: scheme.onSurfaceVariant))
        else
          Wrap(spacing: 8, runSpacing: 8, children: _favs.map((f) => Chip(
            label: Text(f),
            onDeleted: () => _remove(f),
            avatar: const Icon(Icons.person_rounded, size: 18),
          )).toList()),
      ]),
    );
  }
}l