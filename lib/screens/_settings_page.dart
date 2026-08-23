// lib/screens/_settings_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  Settings tab — navigation hub to sub-pages.
// ══════════════════════════════════════════════════════════════════════════
part of 'home_screen.dart';

// ── Quick search results ──────────────────────────────────────────────────
//
// A quick toggle is a single boolean setting from anywhere in the app,
// surfaced directly in search results — matched by keyword and editable
// right there, bound to the app's existing global notifier + pref key.
//
// TO ADD A NEW ONE: just append an entry to `_quickToggles` below with the
// setting's keywords, its global ValueNotifier (from app_state.dart), and
// the SharedPreferences key it's saved under. No other wiring needed —
// search picks it up automatically.
class _QuickToggle {
  final List<String> keywords;
  final IconData icon;
  final String titleFr, titleEn, subFr, subEn;
  final ValueNotifier<bool> notifier;
  final String prefKey;
  const _QuickToggle({
    required this.keywords, required this.icon,
    required this.titleFr, required this.titleEn,
    required this.subFr, required this.subEn,
    required this.notifier, required this.prefKey,
  });
}

final List<_QuickToggle> _quickToggles = [
  _QuickToggle(
    keywords: ['oled', 'noir pur', 'pure black', 'amoled'],
    icon: Icons.contrast_rounded,
    titleFr: 'Mode OLED', titleEn: 'OLED mode',
    subFr: 'Fond noir pur', subEn: 'Pure black background',
    notifier: oledModeNotifier, prefKey: 'ls_oled_mode',
  ),
  _QuickToggle(
    keywords: ['éco', 'eco', 'batterie', 'battery'],
    icon: Icons.battery_saver_rounded,
    titleFr: 'Mode éco (manuel)', titleEn: 'Eco mode (manual)',
    subFr: 'Réduit l\'usage batterie', subEn: 'Cuts battery use',
    notifier: ecoModeManualNotifier, prefKey: 'ls_eco_mode_manual',
  ),
  _QuickToggle(
    keywords: ['actualité', 'news', 'notification'],
    icon: Icons.newspaper_rounded,
    titleFr: 'Notifications actualités', titleEn: 'News notifications',
    subFr: 'Alertes sur les nouveautés Last.fm', subEn: 'Alerts about Last.fm news',
    notifier: notifNewsEnabledNotifier, prefKey: 'ls_notif_news_enabled',
  ),
  _QuickToggle(
    keywords: ['vibration', 'haptique', 'haptic', 'retour'],
    icon: Icons.vibration_rounded,
    titleFr: 'Retour haptique', titleEn: 'Haptic feedback',
    subFr: 'Vibrations lors des interactions', subEn: 'Vibrations on interactions',
    notifier: hapticFeedbackNotifier, prefKey: 'ls_haptic_feedback',
  ),
  _QuickToggle(
    keywords: ['succès', 'achievement', 'trophée', 'badge'],
    icon: Icons.emoji_events_rounded,
    titleFr: 'Succès', titleEn: 'Achievements',
    subFr: 'Affiche les succès débloqués', subEn: 'Shows unlocked achievements',
    notifier: achievementsEnabledNotifier, prefKey: 'ls_achievements_enabled',
  ),
];

// Same idea for options too complex for an inline switch (a color sheet,
// a whole page): shown with a live preview of the current value, tapping
// jumps straight to that page. TO ADD ONE: append below.
class _QuickLink {
  final List<String> keywords;
  final IconData icon;
  final String titleFr, titleEn;
  final Widget Function(BuildContext ctx, ColorScheme s, TextTheme t) trailing;
  final Widget Function(String username) pageBuilder;
  const _QuickLink({
    required this.keywords, required this.icon,
    required this.titleFr, required this.titleEn,
    required this.trailing, required this.pageBuilder,
  });
}

final List<_QuickLink> _quickLinks = [
  _QuickLink(
    keywords: ['couleur', 'accent', 'color', 'palette'],
    icon: Icons.palette_rounded,
    titleFr: 'Couleur d\'accent', titleEn: 'Accent color',
    trailing: (ctx, s, t) => Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        color: accentNotifier.value, shape: BoxShape.circle,
        border: Border.all(color: s.outlineVariant),
      ),
    ),
    pageBuilder: (_) => const AppearancePage(),
  ),
  _QuickLink(
    keywords: ['thème', 'theme', 'sombre', 'dark', 'clair', 'light', 'système', 'system'],
    icon: Icons.dark_mode_rounded,
    titleFr: 'Thème', titleEn: 'Theme',
    trailing: (ctx, s, t) {
      final en = localeNotifier.value == 'en';
      final mode = switch (themeModeNotifier.value) {
        ThemeMode.dark   => en ? 'Dark'   : 'Sombre',
        ThemeMode.light  => en ? 'Light'  : 'Clair',
        ThemeMode.system => en ? 'System' : 'Système',
      };
      return Text(mode, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant));
    },
    pageBuilder: (_) => const AppearancePage(),
  ),
  _QuickLink(
    keywords: ['langue', 'language'],
    icon: Icons.language_rounded,
    titleFr: 'Langue', titleEn: 'Language',
    trailing: (ctx, s, t) => Text(localeNotifier.value.toUpperCase(),
        style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
    pageBuilder: (_) => const LanguagePage(),
  ),
  _QuickLink(
    keywords: ['plateforme', 'platform', 'spotify', 'lastfm', 'last.fm', 'ytmusic'],
    icon: Icons.graphic_eq_rounded,
    titleFr: 'Plateforme musicale', titleEn: 'Music platform',
    trailing: (ctx, s, t) => Text(musicPlatformNotifier.value,
        style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
    pageBuilder: (_) => const StartupPage(),
  ),
  _QuickLink(
    keywords: ['compte', 'account', 'déconnexion', 'logout', 'profil'],
    icon: Icons.person_rounded,
    titleFr: 'Compte', titleEn: 'Account',
    trailing: (ctx, s, t) => Icon(Icons.chevron_right_rounded, color: s.onSurfaceVariant),
    pageBuilder: (username) => AccountPage(username: username),
  ),
  _QuickLink(
    keywords: ['synchro', 'sync', 'arrière-plan', 'background'],
    icon: Icons.sync_rounded,
    titleFr: 'Synchronisation', titleEn: 'Sync',
    trailing: (ctx, s, t) => Icon(Icons.chevron_right_rounded, color: s.onSurfaceVariant),
    pageBuilder: (_) => const SyncPage(),
  ),
  _QuickLink(
    keywords: ['cache', 'stockage', 'storage', 'vider', 'clear', 'hors-ligne', 'offline'],
    icon: Icons.storage_rounded,
    titleFr: 'Cache', titleEn: 'Cache',
    trailing: (ctx, s, t) => Icon(Icons.chevron_right_rounded, color: s.onSurfaceVariant),
    pageBuilder: (_) => const CachePage(),
  ),
];

class _SettingsCardData {
  final IconData icon;
  final Color Function(ColorScheme) iconBgColor;
  final Color Function(ColorScheme) iconFgColor;
  final String Function() title;
  final String Function() subtitle;
  final Widget Function(String username) pageBuilder;

  const _SettingsCardData({
    required this.icon,
    required this.iconBgColor,
    required this.iconFgColor,
    required this.title,
    required this.subtitle,
    required this.pageBuilder,
  });
}

class _SettingsPage extends StatefulWidget {
  final String username;
  const _SettingsPage({required this.username});

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  UpdateInfo? _updateInfo;
  bool        _checkingUpdate = false;
  bool        _autoUpdate     = true;
  String?     _avatarUrl;
  String      _searchQuery    = '';
  final _searchCtrl = TextEditingController();
  // Widget tint has no global ValueNotifier (Android-only setting), so it's
  // tracked locally. Every other quick-toggle below binds straight to the
  // app's existing global notifiers instead.
  bool? _quickWidgetTint;

  @override
  void initState() {
    super.initState();
    _loadAndCheck();
    _fetchAvatar();
    _loadQuickToggles();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _loadQuickToggles() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _quickWidgetTint = p.getBool('ls_widget_tint') ?? false);
  }

  Future<void> _setQuickPref(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  List<Widget> _buildQuickToggleResults(
    BuildContext context, String q, ColorScheme scheme, TextTheme text,
  ) {
    final en = localeNotifier.value == 'en';
    final items = <Widget>[];

    bool matches(List<String> keywords) =>
        keywords.any((k) => k.contains(q) || q.contains(k));

    // Global-notifier-backed toggles — one entry per item in `_quickToggles`.
    for (final t in _quickToggles) {
      if (!matches(t.keywords)) continue;
      items.add(ValueListenableBuilder<bool>(
        valueListenable: t.notifier,
        builder: (context, value, child) => _quickToggleTile(
          icon: t.icon,
          title: en ? t.titleEn : t.titleFr,
          subtitle: en ? t.subEn : t.subFr,
          value: value,
          onChanged: (v) async {
            t.notifier.value = v;
            await _setQuickPref(t.prefKey, v);
          },
          scheme: scheme, text: text,
        ),
      ));
    }

    // Widget tint — Android-only, no global notifier, handled locally.
    if (_quickWidgetTint != null && matches(
        ['widget', 'couleur', 'color', 'accent', 'teinte', 'tint'])) {
      items.add(_quickToggleTile(
        icon: Icons.widgets_rounded,
        title: en ? 'Colored widgets' : 'Widgets colorés',
        subtitle: en
            ? 'Tint home screen widgets with the accent color'
            : 'Teinte les widgets de l\'écran d\'accueil avec l\'accent',
        value: _quickWidgetTint!,
        onChanged: (v) async {
          await _setQuickPref('ls_widget_tint', v);
          setState(() => _quickWidgetTint = v);
          WidgetService.updateAll();
        },
        scheme: scheme, text: text,
      ));
    }

    if (items.isEmpty) return const [];
    return [...items, const SizedBox(height: 8)];
  }

  // "Preview + jump" results, for options too complex to edit inline
  // (a color sheet, a language list…). Shows the current value so it reads
  // as the option itself, not just its category — tapping opens that page.
  List<Widget> _buildQuickLinkResults(
    BuildContext context, String q, ColorScheme scheme, TextTheme text,
  ) {
    final en = localeNotifier.value == 'en';
    final items = <Widget>[];

    bool matches(List<String> keywords) =>
        keywords.any((k) => k.contains(q) || q.contains(k));

    for (final l in _quickLinks) {
      if (!matches(l.keywords)) continue;
      items.add(_quickLinkTile(
        icon: l.icon,
        title: en ? l.titleEn : l.titleFr,
        trailing: l.trailing(context, scheme, text),
        onTap: () => _push(context, l.pageBuilder(widget.username)),
        scheme: scheme, text: text,
      ));
    }

    if (items.isEmpty) return const [];
    return [...items, const SizedBox(height: 8)];
  }

  Widget _quickLinkTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    required ColorScheme scheme,
    required TextTheme text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45), width: 1),
        ),
        child: ListTile(
          leading: Icon(icon, color: scheme.primary),
          title: Text(title),
          trailing: trailing,
          onTap: () { _haptic(_HapticImpact.light); onTap(); },
        ),
      ),
    );
  }

  Widget _quickToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme scheme,
    required TextTheme text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45), width: 1),
        ),
        child: SwitchListTile(
          secondary: Icon(icon, color: scheme.primary),
          title: Text(title),
          subtitle: Text(subtitle, style: text.bodySmall),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Fetch the Last.fm profile picture URL.
  Future<void> _fetchAvatar() async {
    try {
      final p      = await SharedPreferences.getInstance();
      final apiKey = p.getString('ls_apikey') ?? '';
      if (apiKey.isEmpty) return;

      final uri = Uri.parse(
        'https://ws.audioscrobbler.com/2.0/'
        '?method=user.getInfo'
        '&user=${widget.username}'
        '&api_key=$apiKey'
        '&format=json',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return;

      final data   = jsonDecode(res.body) as Map<String, dynamic>;
      final images = (data['user']?['image'] as List?)?.cast<Map<String, dynamic>>();
      if (images == null || images.isEmpty) return;

      // Pick the largest available non-empty image.
      String? url;
      for (final img in images.reversed) {
        final t = img['#text'] as String? ?? '';
        if (t.isNotEmpty) { url = t; break; }
      }
      if (url != null && mounted) setState(() => _avatarUrl = url);
    } catch (_) {}
  }

  Future<void> _loadAndCheck() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    _autoUpdate = p.getBool('ls_auto_update_check') ?? true;
    if (!_autoUpdate) return;
    final last = p.getInt('ls_last_update_check') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - last < const Duration(days: 1).inMilliseconds) return;
    setState(() => _checkingUpdate = true);
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      await p.setInt('ls_last_update_check', DateTime.now().millisecondsSinceEpoch);
      setState(() { _updateInfo = info; _checkingUpdate = false; });
    } catch (_) {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  List<_SettingsCardData> _buildCards() => [
    // 0 — Appearance
    _SettingsCardData(
      icon: Icons.palette_rounded,
      iconBgColor: (s) => s.primaryContainer,
      iconFgColor: (s) => s.onPrimaryContainer,
      title:    () => L.settingsAppearance,
      subtitle: () => L.settingsCardAppearanceSub,
      pageBuilder: (_) => const AppearancePage(),
    ),
    // 1 — Dashboard
    _SettingsCardData(
      icon: Icons.dashboard_rounded,
      iconBgColor: (s) => s.secondaryContainer,
      iconFgColor: (s) => s.onSecondaryContainer,
      title:    () => L.settingsDashboardSection,
      subtitle: () => L.settingsCardDashboardSub,
      pageBuilder: (_) => const DashboardSettingsPage(),
    ),
    // 2 — Startup
    _SettingsCardData(
      icon: Icons.rocket_launch_rounded,
      iconBgColor: (s) => s.tertiaryContainer,
      iconFgColor: (s) => s.onTertiaryContainer,
      title:    () => L.settingsStartupPage,
      subtitle: () => L.settingsCardStartupSub,
      pageBuilder: (_) => const StartupPage(),
    ),
    // 3 — Notifications
    _SettingsCardData(
      icon: Icons.notifications_rounded,
      iconBgColor: (s) => Color.lerp(s.primaryContainer, s.tertiaryContainer, 0.5)!,
      iconFgColor: (s) => s.onPrimaryContainer,
      title:    () => L.settingsNotifications,
      subtitle: () => L.settingsCardNotificationsSub,
      pageBuilder: (_) => const NotificationsPage(),
    ),
    // 3b — Sync
    _SettingsCardData(
      icon: Icons.sync_rounded,
      iconBgColor: (s) => s.secondaryContainer,
      iconFgColor: (s) => s.onSecondaryContainer,
      title:    () => L.settingsSync,
      subtitle: () => L.settingsCardSyncSub,
      pageBuilder: (_) => const SyncPage(),
    ),
    // 3c — Battery saver
    _SettingsCardData(
      icon: Icons.battery_saver_rounded,
      iconBgColor: (s) => s.tertiaryContainer,
      iconFgColor: (s) => s.onTertiaryContainer,
      title:    () => localeNotifier.value == 'en' ? 'Battery saver' : 'Mode éco',
      subtitle: () => localeNotifier.value == 'en'
          ? 'Save battery, fewer effects'
          : 'Économiser la batterie, moins d\'effets',
      pageBuilder: (_) => const BatterySaverPage(),
    ),
    // 4 — Language
    _SettingsCardData(
      icon: Icons.translate_rounded,
      iconBgColor: (s) => Color.lerp(s.primaryContainer, s.secondaryContainer, 0.5)!,
      iconFgColor: (s) => s.onPrimaryContainer,
      title:    () => L.settingsLanguage,
      // Dynamic: shows whichever language is actually active, in its own
      // native name — scales automatically as languages are added to
      // kSupportedLocales, instead of a hardcoded 'French · English'.
      subtitle: () => supportedLocaleFor(localeNotifier.value).nativeName,
      pageBuilder: (_) => const LanguagePage(),
    ),
    // 5 — Account
    _SettingsCardData(
      icon: Icons.person_rounded,
      iconBgColor: (s) => s.primaryContainer,
      iconFgColor: (s) => s.onPrimaryContainer,
      title:    () => L.settingsAccount,
      subtitle: () => L.settingsCardAccountSub,
      pageBuilder: (u) => AccountPage(username: u),
    ),
    // 6 — Cache
    _SettingsCardData(
      icon: Icons.storage_rounded,
      iconBgColor: (s) => Color.lerp(s.primaryContainer, s.tertiaryContainer, 0.5)!,
      iconFgColor: (s) => s.onPrimaryContainer,
      title:    () => L.settingsCache,
      subtitle: () => L.settingsCardCacheSub,
      pageBuilder: (_) => const CachePage(),
    ),
    // 7 — Backup
    _SettingsCardData(
      icon: Icons.backup_rounded,
      iconBgColor: (s) => s.secondaryContainer,
      iconFgColor: (s) => s.onSecondaryContainer,
      title:    () => L.settingsBackup,
      subtitle: () => L.settingsCardBackupSub,
      pageBuilder: (_) => const BackupPage(),
    ),
    // 8 — Updates
    _SettingsCardData(
      icon: Icons.system_update_rounded,
      iconBgColor: (s) => s.tertiaryContainer,
      iconFgColor: (s) => s.onTertiaryContainer,
      title:    () => L.settingsUpdates,
      subtitle: () => L.settingsCardUpdatesSub,
      pageBuilder: (_) => const UpdatesPage(),
    ),
    // 9 — About
    _SettingsCardData(
      icon: Icons.info_outline_rounded,
      iconBgColor: (s) => Color.lerp(s.tertiaryContainer, s.surface, 0.4)!,
      iconFgColor: (s) => s.onTertiaryContainer,
      title:    () => L.settingsAbout,
      subtitle: () => L.settingsCardAboutSub,
      pageBuilder: (_) => const AboutPage(),
    ),
    // 10 — FAQ
    _SettingsCardData(
      icon: Icons.help_outline_rounded,
      iconBgColor: (s) => Color.lerp(s.secondaryContainer, s.tertiaryContainer, 0.5)!,
      iconFgColor: (s) => s.onSecondaryContainer,
      title:    () => L.settingsFaq,
      subtitle: () => L.settingsCardFaqSub,
      pageBuilder: (_) => const FaqPage(),
    ),
  ];

  // Keyword index of specific options living *inside* each category page —
  // so a search for e.g. "couleur" or "notif" finds the right category even
  // though those words aren't in the category's own title/subtitle.
  static const Map<int, List<String>> _subKeywords = {
    0: ['couleur', 'accent', 'color', 'thème', 'theme', 'sombre', 'dark',
        'clair', 'light', 'oled', 'nothing', 'police', 'font', 'widget'],
    1: ['ordre', 'order', 'carte', 'card', 'graphique', 'chart', 'période', 'period'],
    2: ['écran', 'screen', 'accueil', 'home', 'ouverture', 'launch'],
    3: ['notification', 'notif', 'palier', 'milestone', 'récap', 'recap', 'actualité', 'news'],
    4: ['synchro', 'sync', 'arrière-plan', 'background'],
    5: ['batterie', 'battery', 'éco', 'eco'],
    6: ['langue', 'language', 'français', 'french', 'english', 'anglais'],
    7: ['compte', 'account', 'last.fm', 'lastfm', 'déconnexion', 'logout', 'profil'],
    8: ['cache', 'stockage', 'storage', 'vider', 'clear', 'hors-ligne', 'offline'],
    9: ['sauvegarde', 'backup', 'export', 'import', 'restaurer', 'restore'],
    10: ['mise à jour', 'update', 'version'],
    11: ['à propos', 'about', 'contact', 'crédit'],
    12: ['aide', 'faq', 'question'],
  };

  bool _matchesQuery(_SettingsCardData c, int index, String q) {
    if (c.title().toLowerCase().contains(q)) return true;
    if (c.subtitle().toLowerCase().contains(q)) return true;
    final sub = _subKeywords[index];
    if (sub != null && sub.any((k) => k.contains(q) || q.contains(k))) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final text    = Theme.of(context).textTheme;
    final cards   = _buildCards();
    final q = _searchQuery.trim().toLowerCase();
    final filteredCards = q.isEmpty
        ? cards
        : [for (var i = 0; i < cards.length; i++) if (_matchesQuery(cards[i], i, q)) cards[i]];
    final initial = widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?';

    final screenWidth      = MediaQuery.sizeOf(context).width;
    final isWide           = screenWidth >= 720;
    final crossAxisCount   = !isWide ? 2 : (screenWidth >= 1200 ? 4 : 3);
    final maxContentWidth  = isWide ? 1100.0 : double.infinity;
    final gridAspectRatio  = isWide ? 1.35 : 1.1;
    final gridSpacing      = isWide ? 16.0 : 12.0;

    return SafeArea(
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L.settingsTitle,
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Profile card
              GestureDetector(
                onTap: () { _haptic(_HapticImpact.light); _push(context, AccountPage(username: widget.username)); },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: scheme.primary,
                      backgroundImage: _avatarUrl != null
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null
                          ? Text(initial, style: TextStyle(
                              fontSize: 20,
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.username,
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(L.settingsConnectedProfile,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: scheme.primary),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Search bar — filters the category grid below by title/subtitle.
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45), width: 1),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: text.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    hintText: localeNotifier.value == 'en' ? 'Search settings…' : 'Rechercher un réglage…',
                    hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick-toggle search results — editable right here, no need
              // to open the category page.
              if (q.isNotEmpty) ..._buildQuickToggleResults(context, q, scheme, text),
              // Preview + jump results, for options too complex to edit inline.
              if (q.isNotEmpty) ..._buildQuickLinkResults(context, q, scheme, text),

              // Update banner
              if (_updateInfo != null)
                _UpdateBanner(
                  info: _updateInfo!,
                  onTap: () { _haptic(_HapticImpact.light); _push(context, const UpdatesPage()); },
                ),
              if (_updateInfo != null) const SizedBox(height: 16),

              // Restart notice
              const _RestartNotice(),
              const SizedBox(height: 20),
            ]),
          )),

          // ── Category grid ───────────────────────────────────────────────
          if (filteredCards.isEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Center(child: Text(
                localeNotifier.value == 'en' ? 'No settings found' : 'Aucun réglage trouvé',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              )),
            ))
          else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _CategoryCard(
                  data:     filteredCards[i],
                  username: widget.username,
                  compact:  !isWide,
                  // Badge on the Updates card, wherever it lands post-filter.
                  badge: (filteredCards[i].title() == cards[8].title() && _updateInfo != null) ? '!' : null,
                  onTap: () { _haptic(_HapticImpact.light); _push(ctx, filteredCards[i].pageBuilder(widget.username)); },
                ),
                childCount: filteredCards.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   crossAxisCount,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing:  gridSpacing,
                childAspectRatio: gridAspectRatio,
              ),
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(children: [
              const Divider(),
              const SizedBox(height: 10),
              Text(
                  UpdateService.displayVersion == null
                      ? 'LastStats Mobile (dev)'
                      : 'LastStats Mobile ${UpdateService.displayVersion}',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              if (_checkingUpdate) ...[
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 6),
                  Text(L.settingsCheckingUpdates,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
              ],
              const SizedBox(height: 8),
            ]),
          )),
        ],
      ),
      )),
    );
  }

  void _push(BuildContext ctx, Widget page) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final _SettingsCardData data;
  final String username;
  final String? badge;
  final bool compact;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.data,
    required this.username,
    required this.onTap,
    this.badge,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    final iconBox     = compact ? 44.0 : 56.0;
    final iconGlyph   = compact ? 24.0 : 28.0;
    final iconRadius  = compact ? 12.0 : 14.0;
    final cardPad     = compact ? 16.0 : 20.0;
    final titleStyle  = compact ? text.bodyMedium : text.titleSmall;
    final chevronSize = compact ? 14.0 : 17.0;
    final badgeSize   = compact ? 18.0 : 20.0;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
          ),
          padding: EdgeInsets.all(cardPad),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: iconBox, height: iconBox,
                decoration: BoxDecoration(
                  color: data.iconBgColor(scheme),
                  borderRadius: BorderRadius.circular(iconRadius),
                ),
                child: Icon(data.icon, color: data.iconFgColor(scheme), size: iconGlyph),
              ),
              const Spacer(),
              Text(data.title(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: titleStyle?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(data.subtitle(),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant, height: 1.3)),
            ]),

            if (badge != null)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: badgeSize, height: badgeSize,
                  decoration: BoxDecoration(
                      color: scheme.tertiary, shape: BoxShape.circle),
                  child: Center(child: Text(badge!,
                      style: TextStyle(color: scheme.onTertiary,
                          fontSize: compact ? 11 : 12, fontWeight: FontWeight.w800))),
                ),
              ),

            Positioned(
              bottom: 0, right: 0,
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: chevronSize, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Update banner ─────────────────────────────────────────────────────────────

class _UpdateBanner extends StatelessWidget {
  final UpdateInfo info;
  final VoidCallback onTap;
  const _UpdateBanner({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.system_update_rounded, color: scheme.onTertiaryContainer, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.settingsUpdateBanner(info.version),
                style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: scheme.onTertiaryContainer)),
            Text(L.settingsTapToDownload,
                style: text.bodySmall?.copyWith(
                    color: scheme.onTertiaryContainer.withValues(alpha: 0.7))),
          ])),
          Icon(Icons.chevron_right_rounded, color: scheme.onTertiaryContainer),
        ]),
      ),
    );
  }
}

// ── Restart notice ────────────────────────────────────────────────────────────

class _RestartNotice extends StatelessWidget {
  const _RestartNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(Icons.restart_alt_rounded, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(child: Text(
          L.settingsRestartNotice,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        )),
      ]),
    );
  }
}