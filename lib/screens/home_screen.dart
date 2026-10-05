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
import 'dart:math' show sqrt;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback, rootBundle, LogicalKeyboardKey;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../l10n/l10n.dart';
import '../supported_locales.dart';
import '../services/lastfm_service.dart';
import '../services/library_merge.dart';
import '../l10n/extra_strings.dart';
import '../services/taste_engine.dart';
import '../services/listenbrainz_service.dart';
import '../services/image_service.dart';
import '../services/update_service.dart';
import 'recap_story_page.dart';
import '../services/data_cache.dart';
import '../services/app_share.dart';
import '../services/prefetch_service.dart';
import '../services/all_scrobbles_service.dart';
import '../services/translation_service.dart';
import '../services/lyrics_service.dart';
import '../services/achievements.dart';
import '../services/friends_library_service.dart';
import '../services/qr_link_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/markdown_lite.dart';
import '../widgets/living_artwork.dart';
import '../widgets/motion_artwork_video.dart';
import '../widgets/scroll_status_bar.dart';
import '../services/motion_artwork_service.dart';
import 'favorites_page.dart';
import '../services/favorites_folders_service.dart';
import 'track_row_tile.dart';
import '../theme/m3_motion.dart';
import '../theme/m3_shapes.dart';
import '../widgets/skeleton.dart';
import '../widgets/m3_action_row.dart';
import '../widgets/m3_components.dart';


// ── Settings sub-pages ────────────────────────────────────────────────────────
import 'settings/appearance_page.dart';
import 'settings/notifications_page.dart';
import 'settings/dashboard_settings_page.dart';
import 'settings/settings_helpers.dart';
import 'settings/startup_page.dart';
import 'settings/language_page.dart';
import 'settings/account_page.dart';
import 'settings/backup_page.dart';
import 'settings/cache_page.dart';
import 'settings/updates_page.dart';
import 'settings/about_page.dart';
import 'settings/faq_page.dart';
import 'settings/sync_page.dart';
import 'settings/battery_saver_page.dart';
import '../services/widget_service.dart';
import '../theme/story_style.dart';

// Parts
part '_dashboard_page.dart';
part '_discover_section.dart';
part '_search_page.dart';
part '_rankings_page.dart';
part '_detail_sheet.dart';
part '_charts_page.dart';
part '_history_page.dart';
part '_settings_page.dart';
part '_shared_widgets.dart';
part '_taste_compare_sheet.dart';
part '_achievements_page.dart';
part 'qr_scanner_page.dart';



// ── Breakpoints ───────────────────────────────────────────────────────────────
const double _kWideBreakpoint = 720.0;

/// True when the app shows the PC layout (side rail). Shared by every screen
/// that needs a different arrangement on desktop than on a phone.
bool _isDesktopLayout(BuildContext context) {
  final mode = pcModeNotifier.value;
  if (mode == 'on')  return true;
  if (mode == 'off') return false;
  return MediaQuery.of(context).size.width >= _kWideBreakpoint;
}

// ── Tab indices ───────────────────────────────────────────────────────────────
const int _kTabHistory   = 4;


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

    SharedPreferences.getInstance().then((p) {
      final saved = p.getBool('ls_rail_collapsed');
      if (saved != null && mounted) setState(() => _railCollapsed = saved);
    });

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

  bool _useWideLayout(BuildContext context) => _isDesktopLayout(context);

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
    // Top level tabs: the old page fades out first, then the new page
    // fades in (Material 3 "fade through"). Pages stay alive for state.
    // Solid status bar slides in once a tab's content is scrolled.
    return ScrollStatusBarHost(
      color: Theme.of(context).colorScheme.surfaceContainer,
      resetToken: _idx,
      // Dashboard: wait until its 170dp header image has fully collapsed.
      threshold: _idx == 0
          ? 170 - MediaQuery.of(context).padding.top
          : 24,
      child: M3FadeThroughStack(
        index: _idx,
        children: pages.sublist(0, count),
      ),
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

  /// Rail entries (same icons/labels as the old NavigationRail destinations).
  List<_SideRailItem> get _railItems => [
    _SideRailItem(Icons.dashboard_outlined,     Icons.dashboard_rounded,     L.navDashboard),
    _SideRailItem(Icons.search_outlined,        Icons.search_rounded,        L.navSearch),
    _SideRailItem(Icons.emoji_events_outlined,  Icons.emoji_events_rounded,  L.navRankings),
    _SideRailItem(Icons.auto_graph_outlined,    Icons.auto_graph_rounded,    L.navCharts),
    _SideRailItem(Icons.history_outlined,       Icons.history_rounded,       L.navHistory),
    _SideRailItem(Icons.settings_outlined,      Icons.settings_rounded,      L.navSettings),
  ];

  Widget _buildWideLayout(BuildContext context, List<Widget> pages) {
    final scheme    = Theme.of(context).colorScheme;
    final collapsed = _railCollapsed;
    final railWidth = collapsed ? 80.0 : 240.0;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => setState(() => _idx = 0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => setState(() => _idx = 1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => setState(() => _idx = 2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => setState(() => _idx = 3),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => setState(() => _idx = 4),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => setState(() => _idx = 1),
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.maybePop(context),
        const SingleActivator(LogicalKeyboardKey.f5): () => PrefetchService.prefetchAll(_service),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
        backgroundColor: scheme.surfaceContainer,
        body: SafeArea(
          child: Row(
            children: [
              // ── Side rail ────────────────────────────────────────────────
              SizedBox(
                width: railWidth,
                child: Column(
                  children: [
                    // Logo/title header removed — the custom title bar
                    // already shows the app name.
                    const SizedBox(height: 4),

                    // Destinations: centred in the free space (both ways) and
                    // scrollable if the window is very short.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: box.maxHeight),
                            child: Center(
                              child: _SideRail(
                                selectedIndex: _idx,
                                collapsed:     collapsed,
                                items:         _railItems,
                                onSelected: (i) {
                                  _haptic(_HapticImpact.selection);
                                  setState(() => _idx = i);
                                },
                              ),
                            ),
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
                        onPressed: () {
                          final next = !_railCollapsed;
                          setState(() => _railCollapsed = next);
                          SharedPreferences.getInstance()
                              .then((p) => p.setBool('ls_rail_collapsed', next));
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content area: rounded panel, like the Material 3 tablet layout
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: ColoredBox(
                      color: scheme.surface,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: _pageStack(pages, pages.length),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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


// ══════════════════════════════════════════════════════════════════════════
//  Desktop side rail — custom (replaces NavigationRail so every entry is a
//  full-width pill: icon + label inside the same highlight, centred in the
//  rail, with a generous 52 dp click target).
// ══════════════════════════════════════════════════════════════════════════

class _SideRailItem {
  final IconData icon, selectedIcon;
  final String   label;
  const _SideRailItem(this.icon, this.selectedIcon, this.label);
}

class _SideRail extends StatelessWidget {
  final int                 selectedIndex;
  final bool                collapsed;
  final List<_SideRailItem> items;
  final ValueChanged<int>   onSelected;

  const _SideRail({
    required this.selectedIndex,
    required this.collapsed,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final railTheme = NavigationRailTheme.of(context);
    final shape     = railTheme.indicatorShape ?? const StadiumBorder();
    final pill      = railTheme.indicatorColor ?? scheme.secondaryContainer;
    final onPill    = railTheme.selectedIconTheme?.color ?? scheme.onSecondaryContainer;
    final idle      = railTheme.unselectedIconTheme?.color ?? scheme.onSurfaceVariant;
    final text      = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Tooltip(
                message: collapsed ? items[i].label : '',
                waitDuration: const Duration(milliseconds: 400),
                child: Semantics(
                  button: true,
                  selected: i == selectedIndex,
                  label: items[i].label,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: M3Motion.emphasizedDecelerate,
                    height: 52,
                    decoration: ShapeDecoration(
                      color: i == selectedIndex ? pill : Colors.transparent,
                      shape: shape,
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        customBorder: shape,
                        onTap: () => onSelected(i),
                        child: Row(
                          mainAxisAlignment: collapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            if (!collapsed) const SizedBox(width: 18),
                            Icon(
                              i == selectedIndex ? items[i].selectedIcon : items[i].icon,
                              size: 24,
                              color: i == selectedIndex ? onPill : idle,
                            ),
                            if (!collapsed) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  items[i].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelLarge?.copyWith(
                                    fontSize: 14,
                                    fontWeight: i == selectedIndex
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: i == selectedIndex ? onPill : idle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════
//  Desktop horizontal strip helper: mouse-drag scrolling + left/right
//  arrows. Used by Discover and the Friends row on PC (phones keep their
//  swipe / touch behaviour untouched).
// ══════════════════════════════════════════════════════════════════════════

class _HScrollArrows extends StatefulWidget {
  /// Builds the horizontal scrollable; it MUST use the given controller.
  final Widget Function(ScrollController controller) builder;
  /// Pixels scrolled per arrow click.
  final double step;
  /// Vertical centre of the arrows, measured from the top of the strip.
  final double arrowY;

  const _HScrollArrows({
    required this.builder,
    required this.step,
    required this.arrowY,
  });

  @override
  State<_HScrollArrows> createState() => _HScrollArrowsState();
}

class _HScrollArrowsState extends State<_HScrollArrows> {
  final ScrollController _c = ScrollController();

  @override
  void initState() {
    super.initState();
    // Re-evaluate arrow visibility once the first layout is known.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go(int dir) {
    if (!_c.hasClients) return;
    final max    = _c.position.maxScrollExtent;
    final target = (_c.offset + dir * widget.step).clamp(0.0, max.isFinite ? max : double.maxFinite);
    _c.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: M3Motion.emphasizedDecelerate,
    );
  }

  Widget _arrow(bool left, bool visible) {
    return Positioned(
      left:  left ? 4 : null,
      right: left ? null : 4,
      top:   widget.arrowY - 20,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: IconButton.filledTonal(
            iconSize: 22,
            tooltip: left ? '‹' : '›',
            onPressed: () => _go(left ? -1 : 1),
            icon: Icon(left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: Stack(children: [
        widget.builder(_c),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ready = _c.hasClients && _c.position.hasContentDimensions;
            final canLeft  = ready && _c.offset > 4;
            final canRight = !ready || _c.offset < _c.position.maxScrollExtent - 4;
            return Stack(children: [
              _arrow(true,  canLeft),
              _arrow(false, canRight),
            ]);
          },
        ),
      ]),
    );
  }
}
