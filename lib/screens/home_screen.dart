// lib/screens/home_screen.dart
// ══════════════════════════════════════════════════════════════════════════
//  Main screen with adaptive navigation.
//
//  Layout modes (controlled by pcModeNotifier in app_state.dart):
//    'auto'  → NavigationRail when width ≥ 720 dp, BottomBar otherwise
//    'on'    → always NavigationRail (side rail)
//    'off'   → always bottom NavigationBar
//
//  Wide layout extras:
//    • Rail is collapsible: icons-only (56 dp) ↔ icons+labels (200 dp)
//    • Settings is a proper tab (#5) instead of a pushed route
//    • Rail destinations are scrollable when they overflow
// ══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'dart:math' show sqrt;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import '../app_state.dart';
import '../l10n.dart';
import '../supported_locales.dart';
import '../services/lastfm_service.dart';
import '../services/image_service.dart';
import '../services/update_service.dart';
import '../services/data_cache.dart';
import '../services/prefetch_service.dart';
import '../services/all_scrobbles_service.dart';
import '../services/translation_service.dart';
import '../services/lyrics_service.dart';
import 'notification_detail_page.dart';


// ── Settings sub-pages ────────────────────────────────────────────────────────
import 'settings/appearance_page.dart';
import 'settings/notifications_page.dart';
import 'settings/dashboard_settings_page.dart';
import 'settings/startup_page.dart';
import 'settings/language_page.dart';
import 'settings/account_page.dart';
import 'settings/backup_page.dart';
import 'settings/cache_page.dart';
import 'settings/updates_page.dart';
import 'settings/about_page.dart';
import 'settings/faq_page.dart';

// Parts
part '_dashboard_page.dart';
part '_search_page.dart';
part '_rankings_page.dart';
part '_detail_sheet.dart';
part '_charts_page.dart';
part '_history_page.dart';
part '_settings_page.dart';
part '_shared_widgets.dart';
part '_taste_compare_sheet.dart';



// ── Breakpoints ───────────────────────────────────────────────────────────────
const double _kWideBreakpoint = 720.0;

// ── Tab indices ───────────────────────────────────────────────────────────────
const int _kTabDashboard = 0;
const int _kTabSearch    = 1;
const int _kTabRankings  = 2;
const int _kTabCharts    = 3;
const int _kTabHistory   = 4;
const int _kTabSettings  = 5; // wide mode only


/// Returns localised (key, label) pairs for period filter chips.
List<(String, String)> _localizedPeriods() => [
  ('7day',    L.period7day),
  ('1month',  L.period1month),
  ('3month',  L.period3month),
  ('6month',  L.period6month),
  ('12month', L.period12month),
  ('overall', L.periodOverall),
];

List<String> get _kMonths => L.months;

BorderSide _cardBorder(ColorScheme s, {double alpha = 0.45}) =>
    BorderSide(color: s.outlineVariant.withValues(alpha: alpha), width: 1);

// ── Haptic feedback ───────────────────────────────────────────────────────────
enum _HapticImpact { selection, light, medium, heavy }

void _haptic([_HapticImpact impact = _HapticImpact.light]) {
  if (!hapticFeedbackNotifier.value) return;
  switch (impact) {
    case _HapticImpact.selection: HapticFeedback.selectionClick();
    case _HapticImpact.light:     HapticFeedback.lightImpact();
    case _HapticImpact.medium:    HapticFeedback.mediumImpact();
    case _HapticImpact.heavy:     HapticFeedback.heavyImpact();
  }
}


// ══════════════════════════════════════════════════════════════════════════════
//  HomeScreen
// ══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  final String username;
  final String apiKey;
  final int    startupTab;
  const HomeScreen({
    super.key,
    required this.username,
    required this.apiKey,
    this.startupTab = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _idx;
  late final LastFmService _service;

  /// Whether the side rail is collapsed (icons only).
  bool _railCollapsed = false;

  @override
  void initState() {
    super.initState();
    _idx     = widget.startupTab.clamp(0, _kTabHistory);
    _service = LastFmService(apiKey: widget.apiKey, username: widget.username);

    localeNotifier.addListener(_onLocaleChange);
    pcModeNotifier.addListener(_onLocaleChange);

    DataCache.init().then((_) {
      PrefetchService.prefetchAll(_service);
      if (AllScrobblesService.isFirstLoad) {
        AllScrobblesService.loadAll(_service);
      } else {
        AllScrobblesService.syncNew(_service);
      }
    });
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_onLocaleChange);
    pcModeNotifier.removeListener(_onLocaleChange);
    super.dispose();
  }

  void _onLocaleChange() => setState(() {});

  // ── Layout decision ─────────────────────────────────────────────────────────

  bool _useWideLayout(BuildContext context) {
    final mode = pcModeNotifier.value;
    if (mode == 'on')  return true;
    if (mode == 'off') return false;
    return MediaQuery.of(context).size.width >= _kWideBreakpoint;
  }

  // ── Pages (index 5 = Settings, only shown in wide mode) ────────────────────

  List<Widget> _buildPages() => [
    _DashboardPage(service: _service, username: widget.username),
    _SearchPage(service: _service),
    _RankingsPage(service: _service),
    _ChartsPage(service: _service),
    _HistoryPage(service: _service),
    _SettingsPage(username: widget.username), // index 5 – wide only
  ];

  Widget _pageStack(List<Widget> pages, int count) {
    return Stack(
      children: List.generate(count, (i) => IgnorePointer(
        ignoring: _idx != i,
        child: AnimatedOpacity(
          opacity: _idx == i ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: pages[i],
        ),
      )),
    );
  }

  // ── Narrow layout ───────────────────────────────────────────────────────────

  List<NavigationDestination> get _narrowDestinations => [
    NavigationDestination(
      icon: const Icon(Icons.dashboard_outlined),
      selectedIcon: const Icon(Icons.dashboard_rounded),
      label: L.navDashboard,
    ),
    NavigationDestination(
      icon: const Icon(Icons.search_outlined),
      selectedIcon: const Icon(Icons.search_rounded),
      label: L.navSearch,
    ),
    NavigationDestination(
      icon: const Icon(Icons.emoji_events_outlined),
      selectedIcon: const Icon(Icons.emoji_events_rounded),
      label: L.navRankings,
    ),
    NavigationDestination(
      icon: const Icon(Icons.auto_graph_outlined),
      selectedIcon: const Icon(Icons.auto_graph_rounded),
      label: L.navCharts,
    ),
    NavigationDestination(
      icon: const Icon(Icons.history_outlined),
      selectedIcon: const Icon(Icons.history_rounded),
      label: L.navHistory,
    ),
  ];

  Widget _buildNarrowLayout(List<Widget> pages) {
    // Clamp index to 0-4 if it was on settings in wide mode
    final narrowIdx = _idx.clamp(0, _kTabHistory);
    if (_idx != narrowIdx) _idx = narrowIdx;

    return Scaffold(
      body: _pageStack(pages, _kTabHistory + 1),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) { _haptic(_HapticImpact.selection); setState(() => _idx = i); },
        destinations: _narrowDestinations,
      ),
    );
  }

  // ── Wide layout ─────────────────────────────────────────────────────────────

  /// All rail destinations including Settings at position 5.
  List<NavigationRailDestination> get _wideDestinations => [
    NavigationRailDestination(
      icon: const Icon(Icons.dashboard_outlined),
      selectedIcon: const Icon(Icons.dashboard_rounded),
      label: Text(L.navDashboard),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.search_outlined),
      selectedIcon: const Icon(Icons.search_rounded),
      label: Text(L.navSearch),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.emoji_events_outlined),
      selectedIcon: const Icon(Icons.emoji_events_rounded),
      label: Text(L.navRankings),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.auto_graph_outlined),
      selectedIcon: const Icon(Icons.auto_graph_rounded),
      label: Text(L.navCharts),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.history_outlined),
      selectedIcon: const Icon(Icons.history_rounded),
      label: Text(L.navHistory),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings_rounded),
      label: Text(L.navSettings),
    ),
  ];

  Widget _buildWideLayout(BuildContext context, List<Widget> pages) {
    final scheme    = Theme.of(context).colorScheme;
    final text      = Theme.of(context).textTheme;
    final collapsed = _railCollapsed;
    final railWidth = collapsed ? 56.0 : 200.0;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // ── Side rail ────────────────────────────────────────────────
            SizedBox(
              width: railWidth,
              child: Column(
                children: [
                  // Logo / app name header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: collapsed
                        ? Icon(Icons.equalizer_rounded,
                              color: scheme.primary, size: 22)
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(children: [
                              Icon(Icons.equalizer_rounded,
                                  color: scheme.primary, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'LastStats',
                                style: text.titleMedium?.copyWith(
                                  color:      scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ]),
                          ),
                  ),

                  // Scrollable destinations
                  Expanded(
                    child: SingleChildScrollView(
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          selectedIndex:         _idx,
                          onDestinationSelected: (i) { _haptic(_HapticImpact.selection); setState(() => _idx = i); },
                          extended:              !collapsed,
                          labelType: collapsed
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.none,
                          minWidth:         56,
                          minExtendedWidth: 200,
                          destinations:    _wideDestinations,
                        ),
                      ),
                    ),
                  ),

                  // Collapse / expand toggle
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IconButton(
                      icon: Icon(
                        collapsed
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                      ),
                      tooltip: collapsed ? 'Expand rail' : 'Collapse rail',
                      onPressed: () =>
                          setState(() => _railCollapsed = !_railCollapsed),
                    ),
                  ),
                ],
              ),
            ),

            // ── Separator ────────────────────────────────────────────────
            VerticalDivider(
              width:     1,
              thickness: 1,
              color:     scheme.outlineVariant.withValues(alpha: 0.35),
            ),

            // ── Content area ─────────────────────────────────────────────
            Expanded(child: _pageStack(pages, pages.length)),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final wide  = _useWideLayout(context);

    return wide
        ? _buildWideLayout(context, pages)
        : _buildNarrowLayout(pages);
  }
}