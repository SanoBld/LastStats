// lib/screens/settings/dashboard_settings_page.dart

import 'package:flutter/material.dart';
import '../../theme/m3_shapes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

// Stat-card ids that open a detail sheet / page when tapped on the
// dashboard (see _DashboardPage._statCardWidget in _dashboard_page.dart).
// Kept in sync manually with that switch — used only for the little
// "tappable" hint icon shown in the customization list below.
const Set<String> _kTappableStatCards = {
  'top_artist', 'top_album', 'top_track', 'last_track',
  'top_artist_week', 'top_album_week', 'top_track_week',
  'favorites_count',
};

class DashboardSettingsPage extends StatefulWidget {
  const DashboardSettingsPage({super.key});

  @override
  State<DashboardSettingsPage> createState() => _DashboardSettingsPageState();
}

class _DashboardSettingsPageState extends State<DashboardSettingsPage> {
  String _headerSource          = 'nowplaying';
  String _headerAnimation       = 'fade';
  String _headerPeriod          = 'overall';
  double _headerBlur            = 0.0;
  String _headerCustomUrl       = '';
  // ── Fallback "musique en cours" ──────────────────────────────────────
  // 'none' | 'top_track' | 'top_album' | 'top_artist' | 'custom_url'
  String _fallbackType          = 'none';
  String _fallbackPeriod        = 'overall';   // '7day' | '1month' | 'overall'
  String _fallbackCustomUrl     = '';
  // ── Sections visibles ────────────────────────────────────────────────
  bool   _showNowPlay           = true;
  bool   _showStats             = true;
  bool   _showRecent            = true;
  bool   _showDiscover          = true;
  List<String> _discoverSources = ['foryou', 'fresh', 'genre', 'deeper', 'forgotten', 'albums', 'country', 'gt_week', 'gt_month', 'ga_week', 'ga_month'];
  // Which chart replaces the old top artists/albums/tracks block.
  // 'calendar' = listening calendar (heatmap), 'monthly' = monthly bars.
  String _dashboardChart        = 'calendar';
  bool   _showFriends           = true;
  bool   _showFavorites         = true;
  bool   _headerMusicAnim       = false; // equalizer animation when music is playing
  List<String> _statCards       = List.from(kDefaultStatCards);
  List<String> _sectionOrder    = List.from(kDefaultSectionOrder);
  bool   _infiniteScroll        = false;
  bool   _discoverSmart         = false;
  List<String> _discoverSolo    = [];

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
      _headerSource          = p.getString('ls_header_source')           ?? 'nowplaying';
      _headerAnimation       = p.getString('ls_header_animation')        ?? 'fade';
      _headerPeriod          = p.getString('ls_header_period')           ?? 'overall';
      _headerBlur            = p.getDouble('ls_header_blur')             ?? 0.0;
      _headerCustomUrl       = p.getString('ls_header_custom_url')       ?? '';
      _fallbackType          = p.getString('ls_header_fallback_type')    ?? 'none';
      _fallbackPeriod        = p.getString('ls_header_fallback_period')  ?? 'overall';
      _fallbackCustomUrl     = p.getString('ls_header_fallback_url')     ?? '';
      _showNowPlay           = p.getBool('ls_show_nowplay')              ?? true;
      _showStats             = p.getBool('ls_show_stats')                ?? true;
      _dashboardChart        = p.getString('ls_dashboard_chart')         ?? 'calendar';
      _showRecent            = p.getBool('ls_show_recent')               ?? true;
      _showDiscover          = p.getBool('ls_show_discover')             ?? true;
      _discoverSources       = p.getStringList('ls_discover_sources') ?? ['foryou', 'fresh', 'genre', 'deeper', 'forgotten', 'albums', 'country', 'gt_week', 'gt_month', 'ga_week', 'ga_month'];
      _showFriends           = p.getBool('ls_show_friends')              ?? true;
      _showFavorites         = p.getBool('ls_show_favorites')            ?? true;
      _headerMusicAnim       = p.getBool('ls_header_music_anim')         ?? false;
      _sectionOrder          = migrateSectionOrder(p.getStringList('ls_section_order'));
      _infiniteScroll        = p.getBool('ls_infinite_scroll')          ?? false;
      _discoverSmart         = p.getBool('ls_discover_smart')           ?? false;
      _discoverSolo          = p.getStringList('ls_discover_solo')      ?? [];
      final raw = p.getStringList('ls_stat_cards');
      _statCards = raw != null && raw.isNotEmpty ? raw : List.from(kDefaultStatCards);
    });
  }

  Future<void> _set<T>(String key, T v) async {
    final p = await SharedPreferences.getInstance();
    if (v is bool)   await p.setBool(key, v);
    if (v is String) await p.setString(key, v);
    if (v is double) await p.setDouble(key, v);
  }

  Future<void> _saveList(String key, List<String> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(key, list);
  }

  static const _personalIds = ['foryou', 'onthisday', 'fresh', 'genre', 'deeper', 'forgotten', 'albums', 'country'];
  static const _globalIds = [
    'gt_week', 'gt_month', 'gt_year',
    'ga_week', 'ga_month', 'ga_year',
    'gb_week', 'gb_month', 'gb_year',
  ];

  static IconData _srcIcon(String s) => switch (s) {
        'foryou'    => Icons.auto_awesome_rounded,
        'onthisday' => Icons.history_rounded,
        'fresh'     => Icons.calendar_month_rounded,
        'genre'     => Icons.category_rounded,
        'deeper'    => Icons.travel_explore_rounded,
        'forgotten' => Icons.replay_rounded,
        'albums'    => Icons.album_rounded,
        'country'   => Icons.flag_rounded,
        _           => s.startsWith('gt') ? Icons.music_note_rounded
                     : s.startsWith('ga') ? Icons.mic_rounded : Icons.album_rounded,
      };

  // Choose + sort the filters of one group (and pick which get their own row).
  Future<void> _pickFilters(List<String> group, String groupTitle) async {
    final current = [for (final s in _discoverSources) if (group.contains(s)) s];
    final res = await showModalBottomSheet<PickSortResult>(
      sheetAnimationStyle: kM3SheetAnimation,
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent, useSafeArea: true,
      builder: (_) => PickSortSheet(
        title: L.dashFiltersOf(groupTitle),
        items: [for (final k in group) PickItem(k, discoverSourceLabel(k), icon: _srcIcon(k))],
        selected: current,
        solo: _discoverSolo.toSet(),
        allowSolo: true,
        note: _discoverSmart ? L.dashSortSmartNote : null,
      ),
    );
    if (res == null || !mounted) return;
    final personal = identical(group, _personalIds) ? res.selected
        : [for (final s in _discoverSources) if (_personalIds.contains(s)) s];
    final global = identical(group, _globalIds) ? res.selected
        : [for (final s in _discoverSources) if (_globalIds.contains(s)) s];
    final next = [...personal, ...global];
    final solo = [
      for (final s in _discoverSolo) if (!group.contains(s)) s,
      ...res.solo,
    ];
    await _saveList('ls_discover_sources', next);
    await _saveList('ls_discover_solo', solo);
    setState(() { _discoverSources = next; _discoverSolo = solo; });
  }

  String _filtersSummary(List<String> group) {
    final on = [for (final s in _discoverSources) if (group.contains(s)) discoverSourceLabel(s)];
    return on.isEmpty ? '—' : on.join(', ');
  }

  // Choose + sort the stat cards.
  Future<void> _pickCards() async {
    final res = await showModalBottomSheet<PickSortResult>(
      sheetAnimationStyle: kM3SheetAnimation,
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent, useSafeArea: true,
      builder: (_) => PickSortSheet(
        title: L.dashStatCardsSectionLabel,
        items: [
          for (final c in kAllStatCards)
            PickItem(c.$1, statCardLabel(c.$1), emoji: c.$2, hint: _kTappableStatCards.contains(c.$1)),
        ],
        selected: _statCards,
      ),
    );
    if (res == null || !mounted) return;
    await _saveList('ls_stat_cards', res.selected);
    setState(() => _statCards = res.selected);
  }

  Future<void> _setStr(String key, String v, void Function() apply) async {
    await _set(key, v);
    if (mounted) setState(apply);
  }

  Future<void> _setBool(String key, bool v, void Function() apply) async {
    await _set(key, v);
    if (mounted) setState(apply);
  }

  @override
  Widget build(BuildContext context) {
    final periods = buildHeaderPeriods();
    final isTop = ['top_track', 'top_album', 'top_artist'].contains(_headerSource);
    final fbTop = ['top_track', 'top_album', 'top_artist'].contains(_fallbackType);
    final fbOptions = <ChoiceOption>[
      ('none',       L.fallbackTypeNothing,     Icons.hide_image_outlined),
      ('top_track',  L.fallbackTypeTopTrack,    Icons.music_note_rounded),
      ('top_album',  L.fallbackTypeTopAlbum,    Icons.album_rounded),
      ('top_artist', L.fallbackTypeTopArtist,   Icons.mic_rounded),
      ('custom_url', L.fallbackTypeCustomImage, Icons.image_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(L.settingsDashboardSection), centerTitle: false),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Header image ──────────────────────────────────────────────────
        SettingsSection(label: L.settingsHeaderImage, children: [
          SettingChoiceRow(
            icon: Icons.wallpaper_rounded,
            title: L.settingsHeaderSource,
            options: [for (final o in buildHeaderSources()) (o.$1, o.$2, o.$3)],
            value: _headerSource,
            onChanged: (v) => _setStr('ls_header_source', v, () => _headerSource = v),
          ),
          if (_headerSource == 'custom')
            SettingTextRow(
              icon: Icons.link_rounded,
              title: L.settingsHeaderCustomUrl,
              hint: L.settingsHeaderCustomUrlHint,
              value: _headerCustomUrl,
              onChanged: (v) => _setStr('ls_header_custom_url', v, () => _headerCustomUrl = v),
            ),
          if (isTop)
            SettingChoiceRow(
              icon: Icons.date_range_rounded,
              title: L.settingsHeaderPeriod,
              options: [for (final o in periods) (o.$1, o.$2, null)],
              value: _headerPeriod,
              onChanged: (v) => _setStr('ls_header_period', v, () => _headerPeriod = v),
            ),
          if (_headerSource == 'nowplaying') ...[
            SettingChoiceRow(
              icon: Icons.music_off_rounded,
              title: L.dashFallbackWhenNoMusic,
              options: fbOptions,
              value: _fallbackType,
              onChanged: (v) async {
                await _set('ls_header_fallback_type', v);
                await _set('ls_header_fallback_enabled', v != 'none'); // old key
                if (mounted) setState(() => _fallbackType = v);
              },
            ),
            if (fbTop)
              SettingChoiceRow(
                icon: Icons.date_range_rounded,
                title: L.dashFallbackPeriodLabel,
                options: [
                  ('7day',    L.fallbackPeriod1Week,   null),
                  ('1month',  L.fallbackPeriod1Month,  null),
                  ('overall', L.fallbackPeriodAllTime, null),
                ],
                value: _fallbackPeriod,
                onChanged: (v) => _setStr('ls_header_fallback_period', v, () => _fallbackPeriod = v),
              ),
            if (_fallbackType == 'custom_url')
              SettingTextRow(
                icon: Icons.image_outlined,
                title: L.settingsHeaderFallbackUrlLabel,
                hint: L.settingsHeaderCustomUrlHint,
                value: _fallbackCustomUrl,
                onChanged: (v) => _setStr('ls_header_fallback_url', v, () => _fallbackCustomUrl = v),
              ),
          ],
        ]),

        const SizedBox(height: 16),

        // ── Animation & blur ──────────────────────────────────────────────
        SettingsSection(label: L.dashAnimationBlurSection, children: [
          SettingChoiceRow(
            icon: Icons.animation_rounded,
            title: L.settingsHeaderAnimation,
            options: [for (final o in buildHeaderAnimations()) (o.$1, o.$2, o.$3)],
            value: _headerAnimation,
            onChanged: (v) => _setStr('ls_header_animation', v, () => _headerAnimation = v),
          ),
          SettingSliderRow(
            icon: Icons.blur_on_rounded,
            title: L.settingsHeaderBlur,
            valueLabel: _headerBlur < 1 ? L.settingsHeaderBlurNone : '${_headerBlur.round()}',
            value: _headerBlur, min: 0, max: 20, divisions: 20,
            onChanged: (v) => setState(() => _headerBlur = v),
            onChangeEnd: (v) async => await _set('ls_header_blur', v),
          ),
          SettingSwitchRow(
            icon: Icons.graphic_eq_rounded,
            title: L.dashMusicAnimationTitle,
            subtitle: _headerMusicAnim
                ? '${L.dashMusicAnimationSub}\n${L.dashMusicAnimationInfo}'
                : L.dashMusicAnimationSub,
            value: _headerMusicAnim,
            onChanged: (v) => _setBool('ls_header_music_anim', v, () => _headerMusicAnim = v),
          ),
        ]),

        const SizedBox(height: 16),

        // ── Visible sections ──────────────────────────────────────────────
        SettingsSection(label: L.settingsVisibleSections, children: [
          SettingActionRow(
            icon: Icons.swap_vert_rounded,
            title: L.dashReorderSections,
            onTap: () async {
              final result = await showModalBottomSheet<List<String>>(
                sheetAnimationStyle: kM3SheetAnimation,
                context: context, isScrollControlled: true,
                backgroundColor: Colors.transparent, useSafeArea: true,
                builder: (_) => SectionOrderSheet(order: List.from(_sectionOrder)),
              );
              if (result != null && mounted) {
                await _saveList('ls_section_order', result);
                setState(() => _sectionOrder = result);
              }
            },
          ),
          SettingSwitchRow(
            icon: Icons.play_circle_outline_rounded,
            title: L.settingsNowPlayingSection,
            value: _showNowPlay,
            onChanged: (v) => _setBool('ls_show_nowplay', v, () => _showNowPlay = v),
          ),
          SettingSwitchRow(
            icon: Icons.bar_chart_rounded,
            title: L.settingsStatsSection,
            value: _showStats,
            onChanged: (v) => _setBool('ls_show_stats', v, () => _showStats = v),
          ),
          SettingSwitchRow(
            icon: Icons.explore_rounded,
            title: L.dashDiscoverTitle,
            subtitle: L.dashDiscoverSub,
            value: _showDiscover,
            onChanged: (v) => _setBool('ls_show_discover', v, () => _showDiscover = v),
          ),
          SettingSwitchRow(
            icon: Icons.history_rounded,
            title: L.dashRecentPlaysLabel,
            value: _showRecent,
            onChanged: (v) => _setBool('ls_show_recent', v, () => _showRecent = v),
          ),
          SettingSwitchRow(
            icon: Icons.people_rounded,
            title: L.settingsFriendsSection,
            subtitle: L.settingsFriendsSectionSub,
            value: _showFriends,
            onChanged: (v) => _setBool('ls_show_friends', v, () => _showFriends = v),
          ),
          ValueListenableBuilder<String>(
            valueListenable: sessionKeyNotifier,
            builder: (_, session, _) {
              final enabled = session.isNotEmpty;
              return Opacity(
                opacity: enabled ? 1.0 : 0.45,
                child: SettingSwitchRow(
                  icon: Icons.favorite_rounded,
                  title: L.settingsFavoritesSection,
                  subtitle: enabled ? L.settingsFavoritesSectionSub : L.settingsFavoritesNeedsKey,
                  value: enabled && _showFavorites,
                  onChanged: !enabled ? null : (v) async {
                    await _set('ls_show_favorites', v);
                    showFavoritesStatNotifier.value = v;
                    if (mounted) setState(() => _showFavorites = v);
                  },
                ),
              );
            },
          ),
        ]),

        // ── Discover ──────────────────────────────────────────────────────
        if (_showDiscover) ...[
          const SizedBox(height: 16),
          SettingsSection(label: L.dashDiscoverTitle, children: [
            SettingSwitchRow(
              icon: Icons.auto_graph_rounded,
              title: L.discoverSmartTitle,
              subtitle: L.discoverSmartSub,
              value: _discoverSmart,
              onChanged: (v) => _setBool('ls_discover_smart', v, () => _discoverSmart = v),
            ),
            SettingSwitchRow(
              icon: Icons.loop_rounded,
              title: L.dashInfiniteTitle,
              subtitle: L.dashInfiniteSub,
              value: _infiniteScroll,
              onChanged: (v) => _setBool('ls_infinite_scroll', v, () => _infiniteScroll = v),
            ),
            SettingActionRow(
              icon: Icons.auto_awesome_rounded,
              title: L.dashFiltersOf(L.discoverForYou),
              subtitle: _filtersSummary(_personalIds),
              onTap: () => _pickFilters(_personalIds, L.discoverForYou),
            ),
            SettingActionRow(
              icon: Icons.public_rounded,
              title: L.dashFiltersOf(L.discoverGlobalTrends),
              subtitle: _filtersSummary(_globalIds),
              onTap: () => _pickFilters(_globalIds, L.discoverGlobalTrends),
            ),
          ]),
        ],

        const SizedBox(height: 16),

        // ── Dashboard chart ───────────────────────────────────────────────
        SettingsSection(label: L.settingsDashboardChartSection, children: [
          SettingChoiceRow(
            icon: Icons.insights_rounded,
            title: L.settingsDashboardChartSection,
            options: [
              ('calendar', L.dashChartCalendarLabel, Icons.grid_on_rounded),
              ('monthly',  L.dashChartMonthlyLabel,  Icons.calendar_month_rounded),
            ],
            value: _dashboardChart,
            onChanged: (v) => _setStr('ls_dashboard_chart', v, () => _dashboardChart = v),
          ),
        ]),

        const SizedBox(height: 16),

        // ── Stat cards ────────────────────────────────────────────────────
        SettingsSection(label: L.dashStatCardsSectionLabel, children: [
          SettingActionRow(
            icon: Icons.grid_view_rounded,
            title: L.dashStatCardsHeading,
            subtitle: '${_statCards.length} / ${kAllStatCards.length}',
            onTap: _pickCards,
          ),
        ]),

        const SizedBox(height: 20),
        const RestartBanner(),
        const SizedBox(height: 20),
      ]),
    );
  }
}
