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
  final Map<String, String> titles, subs;
  final ValueNotifier<bool> notifier;
  final String prefKey;
  const _QuickToggle({
    required this.keywords, required this.icon,
    required this.titles, required this.subs,
    required this.notifier, required this.prefKey,
  });
}

final List<_QuickToggle> _quickToggles = [
  _QuickToggle(
    keywords: ['oled', 'noir pur', 'pure black', 'amoled', 'negro puro',
        'reines schwarz', 'nero puro', 'preto puro', 'чистый чёрный',
        '純黒', '纯黑', 'أسود خالص'],
    icon: Icons.contrast_rounded,
    titles: {
      'fr': 'Mode OLED', 'en': 'OLED mode', 'es': 'Modo OLED', 'de': 'OLED-Modus',
      'it': 'Modalità OLED', 'pt': 'Modo OLED', 'ru': 'Режим OLED',
      'ja': 'OLED モード', 'zh': 'OLED 模式', 'ar': 'وضع OLED',
    },
    subs: {
      'fr': 'Fond noir pur', 'en': 'Pure black background', 'es': 'Fondo negro puro',
      'de': 'Reiner schwarzer Hintergrund', 'it': 'Sfondo nero puro',
      'pt': 'Fundo preto puro', 'ru': 'Чисто чёрный фон',
      'ja': '純黒の背景', 'zh': '纯黑背景', 'ar': 'خلفية سوداء خالصة',
    },
    notifier: oledModeNotifier, prefKey: 'ls_oled_mode',
  ),
  _QuickToggle(
    keywords: ['éco', 'eco', 'batterie', 'battery', 'batería', 'akku', 'batteria',
        'bateria', 'батарея', 'バッテリー', '电池', 'بطارية'],
    icon: Icons.battery_saver_rounded,
    titles: {
      'fr': 'Mode éco (manuel)', 'en': 'Eco mode (manual)', 'es': 'Modo eco (manual)',
      'de': 'Öko-Modus (manuell)', 'it': 'Modalità eco (manuale)',
      'pt': 'Modo eco (manual)', 'ru': 'Режим экономии (вручную)',
      'ja': 'エコモード（手動）', 'zh': '省电模式（手动）', 'ar': 'وضع توفير الطاقة (يدوي)',
    },
    subs: {
      'fr': 'Réduit l\'usage batterie', 'en': 'Cuts battery use',
      'es': 'Reduce el uso de batería', 'de': 'Reduziert den Akkuverbrauch',
      'it': 'Riduce il consumo della batteria', 'pt': 'Reduz o uso da bateria',
      'ru': 'Снижает расход батареи', 'ja': 'バッテリー消費を抑えます',
      'zh': '降低电池消耗', 'ar': 'يقلل استهلاك البطارية',
    },
    notifier: ecoModeManualNotifier, prefKey: 'ls_eco_mode_manual',
  ),
  _QuickToggle(
    keywords: ['actualité', 'news', 'notification', 'noticias', 'nachrichten',
        'notizie', 'notícias', 'новости', 'ニュース', '新闻', 'أخبار'],
    icon: Icons.newspaper_rounded,
    titles: {
      'fr': 'Notifications actualités', 'en': 'News notifications',
      'es': 'Notificaciones de noticias', 'de': 'Nachrichten-Benachrichtigungen',
      'it': 'Notifiche notizie', 'pt': 'Notificações de notícias',
      'ru': 'Уведомления о новостях', 'ja': 'ニュース通知',
      'zh': '新闻通知', 'ar': 'إشعارات الأخبار',
    },
    subs: {
      'fr': 'Alertes sur les nouveautés Last.fm', 'en': 'Alerts about Last.fm news',
      'es': 'Alertas sobre novedades de Last.fm', 'de': 'Benachrichtigungen zu Last.fm-Neuigkeiten',
      'it': 'Avvisi sulle novità di Last.fm', 'pt': 'Alertas sobre novidades do Last.fm',
      'ru': 'Оповещения о новостях Last.fm', 'ja': 'Last.fm の最新情報の通知',
      'zh': 'Last.fm 最新动态提醒', 'ar': 'تنبيهات حول أخبار Last.fm',
    },
    notifier: notifNewsEnabledNotifier, prefKey: 'ls_notif_news_enabled',
  ),
  _QuickToggle(
    keywords: ['vibration', 'haptique', 'haptic', 'retour', 'vibración', 'vibración háptica',
        'haptisch', 'aptico', 'вибрация', '振動', '振动', 'اهتزاز'],
    icon: Icons.vibration_rounded,
    titles: {
      'fr': 'Retour haptique', 'en': 'Haptic feedback', 'es': 'Retroalimentación háptica',
      'de': 'Haptisches Feedback', 'it': 'Feedback aptico', 'pt': 'Feedback tátil',
      'ru': 'Тактильная отдача', 'ja': '触覚フィードバック', 'zh': '触觉反馈',
      'ar': 'الاستجابة اللمسية',
    },
    subs: {
      'fr': 'Vibrations lors des interactions', 'en': 'Vibrations on interactions',
      'es': 'Vibraciones al interactuar', 'de': 'Vibrationen bei Interaktionen',
      'it': 'Vibrazioni durante le interazioni', 'pt': 'Vibrações nas interações',
      'ru': 'Вибрация при взаимодействии', 'ja': '操作時に振動します',
      'zh': '操作时振动', 'ar': 'اهتزاز عند التفاعل',
    },
    notifier: hapticFeedbackNotifier, prefKey: 'ls_haptic_feedback',
  ),
  _QuickToggle(
    keywords: ['succès', 'achievement', 'trophée', 'badge', 'logro', 'erfolg',
        'obiettivo', 'conquista', 'достижение', '実績', '成就', 'إنجاز'],
    icon: Icons.emoji_events_rounded,
    titles: {
      'fr': 'Succès', 'en': 'Achievements', 'es': 'Logros', 'de': 'Erfolge',
      'it': 'Obiettivi', 'pt': 'Conquistas', 'ru': 'Достижения',
      'ja': '実績', 'zh': '成就', 'ar': 'الإنجازات',
    },
    subs: {
      'fr': 'Affiche les succès débloqués', 'en': 'Shows unlocked achievements',
      'es': 'Muestra los logros desbloqueados', 'de': 'Zeigt freigeschaltete Erfolge',
      'it': 'Mostra gli obiettivi sbloccati', 'pt': 'Mostra as conquistas desbloqueadas',
      'ru': 'Показывает открытые достижения', 'ja': '解除した実績を表示します',
      'zh': '显示已解锁的成就', 'ar': 'يعرض الإنجازات المفتوحة',
    },
    notifier: achievementsEnabledNotifier, prefKey: 'ls_achievements_enabled',
  ),
];

// Same idea for options too complex for an inline switch (a color sheet,
// a whole page): shown with a live preview of the current value, tapping
// jumps straight to that page. TO ADD ONE: append below.
class _QuickLink {
  final List<String> keywords;
  final IconData icon;
  final Map<String, String> titles;
  final Widget Function(BuildContext ctx, ColorScheme s, TextTheme t) trailing;
  final Widget Function(String username) pageBuilder;
  const _QuickLink({
    required this.keywords, required this.icon,
    required this.titles,
    required this.trailing, required this.pageBuilder,
  });
}

final List<_QuickLink> _quickLinks = [
  _QuickLink(
    keywords: ['couleur', 'accent', 'color', 'palette', 'colore', 'farbe',
        'cor', 'цвет', '色', 'لون'],
    icon: Icons.palette_rounded,
    titles: {
      'fr': 'Couleur d\'accent', 'en': 'Accent color', 'es': 'Color de acento',
      'de': 'Akzentfarbe', 'it': 'Colore accento', 'pt': 'Cor de destaque',
      'ru': 'Акцентный цвет', 'ja': 'アクセントカラー', 'zh': '强调色',
      'ar': 'لون التمييز',
    },
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
    keywords: ['thème', 'theme', 'sombre', 'dark', 'clair', 'light', 'système', 'system',
        'tema', 'oscuro', 'claro', 'dunkel', 'hell', 'scuro', 'chiaro',
        'escuro', 'тема', 'тёмная', 'светлая', 'テーマ', '主题', 'المظهر'],
    icon: Icons.dark_mode_rounded,
    titles: {
      'fr': 'Thème', 'en': 'Theme', 'es': 'Tema', 'de': 'Design', 'it': 'Tema',
      'pt': 'Tema', 'ru': 'Тема', 'ja': 'テーマ', 'zh': '主题', 'ar': 'المظهر',
    },
    trailing: (ctx, s, t) {
      final mode = switch (themeModeNotifier.value) {
        ThemeMode.dark   => _tr({'fr': 'Sombre', 'en': 'Dark', 'es': 'Oscuro',
            'de': 'Dunkel', 'it': 'Scuro', 'pt': 'Escuro', 'ru': 'Тёмная',
            'ja': 'ダーク', 'zh': '深色', 'ar': 'داكن'}),
        ThemeMode.light  => _tr({'fr': 'Clair', 'en': 'Light', 'es': 'Claro',
            'de': 'Hell', 'it': 'Chiaro', 'pt': 'Claro', 'ru': 'Светлая',
            'ja': 'ライト', 'zh': '浅色', 'ar': 'فاتح'}),
        ThemeMode.system => _tr({'fr': 'Système', 'en': 'System', 'es': 'Sistema',
            'de': 'System', 'it': 'Sistema', 'pt': 'Sistema', 'ru': 'Системная',
            'ja': 'システム', 'zh': '跟随系统', 'ar': 'النظام'}),
      };
      return Text(mode, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant));
    },
    pageBuilder: (_) => const AppearancePage(),
  ),
  _QuickLink(
    keywords: ['langue', 'language', 'idioma', 'sprache', 'lingua', 'idioma',
        'язык', '言語', '语言', 'اللغة'],
    icon: Icons.language_rounded,
    titles: {
      'fr': 'Langue', 'en': 'Language', 'es': 'Idioma', 'de': 'Sprache',
      'it': 'Lingua', 'pt': 'Idioma', 'ru': 'Язык', 'ja': '言語', 'zh': '语言',
      'ar': 'اللغة',
    },
    trailing: (ctx, s, t) => Text(localeNotifier.value.toUpperCase(),
        style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
    pageBuilder: (_) => const LanguagePage(),
  ),
  _QuickLink(
    keywords: ['plateforme', 'platform', 'spotify', 'lastfm', 'last.fm', 'ytmusic',
        'plataforma', 'piattaforma', 'платформа', 'プラットフォーム', '平台', 'منصة'],
    icon: Icons.graphic_eq_rounded,
    titles: {
      'fr': 'Plateforme musicale', 'en': 'Music platform', 'es': 'Plataforma musical',
      'de': 'Musikplattform', 'it': 'Piattaforma musicale', 'pt': 'Plataforma musical',
      'ru': 'Музыкальная платформа', 'ja': '音楽プラットフォーム', 'zh': '音乐平台',
      'ar': 'منصة الموسيقى',
    },
    trailing: (ctx, s, t) => Text(musicPlatformNotifier.value,
        style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
    pageBuilder: (_) => const StartupPage(),
  ),
  _QuickLink(
    keywords: ['compte', 'account', 'déconnexion', 'logout', 'profil', 'cuenta',
        'konto', 'account', 'conta', 'аккаунт', 'アカウント', '账户', 'الحساب'],
    icon: Icons.person_rounded,
    titles: {
      'fr': 'Compte', 'en': 'Account', 'es': 'Cuenta', 'de': 'Konto', 'it': 'Account',
      'pt': 'Conta', 'ru': 'Аккаунт', 'ja': 'アカウント', 'zh': '账户', 'ar': 'الحساب',
    },
    trailing: (ctx, s, t) => Icon(Icons.chevron_right_rounded, color: s.onSurfaceVariant),
    pageBuilder: (username) => AccountPage(username: username),
  ),
  _QuickLink(
    keywords: ['synchro', 'sync', 'arrière-plan', 'background', 'sincronización',
        'synchronisierung', 'sincronizzazione', 'sincronização', 'синхронизация',
        '同期', '同步', 'مزامنة'],
    icon: Icons.sync_rounded,
    titles: {
      'fr': 'Synchronisation', 'en': 'Sync', 'es': 'Sincronización',
      'de': 'Synchronisierung', 'it': 'Sincronizzazione', 'pt': 'Sincronização',
      'ru': 'Синхронизация', 'ja': '同期', 'zh': '同步', 'ar': 'المزامنة',
    },
    trailing: (ctx, s, t) => Icon(Icons.chevron_right_rounded, color: s.onSurfaceVariant),
    pageBuilder: (_) => const SyncPage(),
  ),
  _QuickLink(
    keywords: ['cache', 'stockage', 'storage', 'vider', 'clear', 'hors-ligne', 'offline',
        'almacenamiento', 'speicher', 'archiviazione', 'armazenamento',
        'хранилище', 'ストレージ', '存储', 'التخزين'],
    icon: Icons.storage_rounded,
    titles: {
      'fr': 'Cache', 'en': 'Cache', 'es': 'Caché', 'de': 'Cache', 'it': 'Cache',
      'pt': 'Cache', 'ru': 'Кэш', 'ja': 'キャッシュ', 'zh': '缓存', 'ar': 'الذاكرة المؤقتة',
    },
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
          title: _tr(t.titles),
          subtitle: _tr(t.subs),
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
        ['widget', 'couleur', 'color', 'accent', 'teinte', 'tint', 'farbe',
         'colore', 'cor', 'цвет', 'ウィジェット', '小组件', 'ودجة'])) {
      items.add(_quickToggleTile(
        icon: Icons.widgets_rounded,
        title: _tr({
          'fr': 'Widgets colorés', 'en': 'Colored widgets',
          'es': 'Widgets con color', 'de': 'Farbige Widgets',
          'it': 'Widget colorati', 'pt': 'Widgets coloridos',
          'ru': 'Цветные виджеты', 'ja': 'カラーウィジェット',
          'zh': '彩色小组件', 'ar': 'ودجات ملونة',
        }),
        subtitle: _tr({
          'fr': 'Teinte les widgets de l\'écran d\'accueil avec l\'accent',
          'en': 'Tint home screen widgets with the accent color',
          'es': 'Aplica el color de acento a los widgets',
          'de': 'Färbt die Homescreen-Widgets mit der Akzentfarbe',
          'it': 'Colora i widget con il colore d\'accento',
          'pt': 'Aplica a cor de destaque aos widgets',
          'ru': 'Окрашивает виджеты акцентным цветом',
          'ja': 'ウィジェットにアクセントカラーを適用',
          'zh': '用强调色为小组件着色', 'ar': 'يلوّن الودجات بلون التمييز',
        }),
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
    final items = <Widget>[];

    bool matches(List<String> keywords) =>
        keywords.any((k) => k.contains(q) || q.contains(k));

    for (final l in _quickLinks) {
      if (!matches(l.keywords)) continue;
      items.add(_quickLinkTile(
        icon: l.icon,
        title: _tr(l.titles),
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
        'clair', 'light', 'oled', 'nothing', 'police', 'font', 'widget',
        'farbe', 'colore', 'cor', 'цвет', 'ウィジェット', '小组件', 'لون'],
    1: ['ordre', 'order', 'carte', 'card', 'graphique', 'chart', 'période', 'period',
        'orden', 'reihenfolge', 'ordine', 'ordem', 'порядок', '順序', '顺序', 'ترتيب'],
    2: ['écran', 'screen', 'accueil', 'home', 'ouverture', 'launch',
        'pantalla', 'bildschirm', 'schermata', 'tela', 'экран', '画面', '屏幕', 'شاشة'],
    3: ['notification', 'notif', 'palier', 'milestone', 'récap', 'recap', 'actualité', 'news',
        'notificación', 'benachrichtigung', 'уведомление', '通知', 'إشعار'],
    4: ['synchro', 'sync', 'arrière-plan', 'background',
        'sincronización', 'synchronisierung', 'синхронизация', '同期', '同步', 'مزامنة'],
    5: ['batterie', 'battery', 'éco', 'eco',
        'batería', 'akku', 'batteria', 'bateria', 'батарея', 'バッテリー', '电池', 'بطارية'],
    6: ['langue', 'language', 'français', 'french', 'english', 'anglais',
        'idioma', 'sprache', 'lingua', 'язык', '言語', '语言', 'اللغة'],
    7: ['compte', 'account', 'last.fm', 'lastfm', 'déconnexion', 'logout', 'profil',
        'cuenta', 'konto', 'conta', 'аккаунт', 'アカウント', '账户', 'الحساب'],
    8: ['cache', 'stockage', 'storage', 'vider', 'clear', 'hors-ligne', 'offline',
        'almacenamiento', 'speicher', 'хранилище', 'ストレージ', '存储', 'التخزين'],
    9: ['sauvegarde', 'backup', 'export', 'import', 'restaurer', 'restore',
        'copia de seguridad', 'sicherung', 'backup', 'резервная копия', 'バックアップ', '备份', 'نسخة احتياطية'],
    10: ['mise à jour', 'update', 'version', 'actualización', 'aktualisierung',
        'aggiornamento', 'atualização', 'обновление', 'アップデート', '更新', 'تحديث'],
    11: ['à propos', 'about', 'contact', 'crédit', 'acerca de', 'über', 'informazioni',
        'sobre', 'о приложении', 'アプリについて', '关于', 'حول'],
    12: ['aide', 'faq', 'question', 'ayuda', 'hilfe', 'aiuto', 'ajuda', 'помощь', 'ヘルプ', '帮助', 'مساعدة'],
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
                    hintText: _tr({
                      'fr': 'Rechercher un réglage…', 'en': 'Search settings…',
                      'es': 'Buscar un ajuste…', 'de': 'Einstellung suchen…',
                      'it': 'Cerca un\'impostazione…', 'pt': 'Pesquisar configuração…',
                      'ru': 'Поиск настройки…', 'ja': '設定を検索…',
                      'zh': '搜索设置…', 'ar': 'ابحث عن إعداد…',
                    }),
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
                _tr({
                  'fr': 'Aucun réglage trouvé', 'en': 'No settings found',
                  'es': 'No se encontraron ajustes', 'de': 'Keine Einstellung gefunden',
                  'it': 'Nessuna impostazione trovata', 'pt': 'Nenhuma configuração encontrada',
                  'ru': 'Настройки не найдены', 'ja': '設定が見つかりません',
                  'zh': '未找到设置', 'ar': 'لم يتم العثور على إعدادات',
                }),
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