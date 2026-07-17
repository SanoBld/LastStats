// lib/main.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:window_manager/window_manager.dart';
import 'app_state.dart';
import 'nothing_theme.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notification_detail_page.dart';
import 'services/data_cache.dart';
import 'services/image_service.dart';
import 'services/scrobbles_file_cache.dart';
import 'services/notification_service.dart';
import 'services/notification_worker.dart';
import 'services/storage_manager.dart';
import 'services/update_startup.dart';
import 'services/update_service.dart';
import 'widgets/custom_title_bar.dart';

// navigatorKey now lives in notification_service.dart so the notification
// tap handler can push screens without importing main.dart (would be circular).

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) => debugPrint('Flutter error: ${details.exception}');

  // ── Custom frameless window (Windows / Linux desktop) ────────────────────
  // macOS keeps its native traffic-light buttons; only Windows and Linux get
  // the fully custom, theme-matched title bar (see widgets/custom_title_bar.dart).
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      minimumSize: Size(420, 500),
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final prefs      = await SharedPreferences.getInstance();
  final username   = prefs.getString('ls_username') ?? '';
  final apiKey     = prefs.getString('ls_apikey')   ?? '';
  final startupTab = prefs.getInt('ls_startup_tab') ?? 0;

  // ── Appearance ──────────────────────────────────────────────────────────
  themeStyleNotifier.value             = prefs.getString('ls_theme_style')           ?? 'default';
  nothingAccentNotifier.value          = prefs.getString('ls_nothing_accent')        ?? 'classic';
  themeModeNotifier.value              = themeFromString(prefs.getString('ls_theme'));
  accentNotifier.value                 = accentFromString(prefs.getString('ls_accent'));
  useDynamicColorNotifier.value        = prefs.getBool('ls_use_dynamic_color')       ?? false;
  useNowPlayingColorNotifier.value     = prefs.getBool('ls_use_nowplaying_color')    ?? false;
  artworkColorThemeNotifier.value      = prefs.getBool('ls_artwork_color_theme')     ?? false;
  keepLastArtworkColorNotifier.value   = prefs.getBool('ls_keep_last_artwork_color') ?? false;
  oledModeNotifier.value               = prefs.getBool('ls_oled_mode')               ?? false;
  localeNotifier.value                 = prefs.getString('ls_locale')                ?? 'fr';
  musicPlatformNotifier.value          = prefs.getString('ls_music_platform')         ?? 'lastfm';
  showAllPlatformLinksNotifier.value   = prefs.getBool('ls_show_all_platform_links')  ?? false;
  secretKeyNotifier.value              = prefs.getString('ls_secret_key')            ?? '';
  sessionKeyNotifier.value             = prefs.getString('ls_session_key')           ?? '';

  // One-time migration: if favorites was already connected before this card
  // existed, make sure it's added to the user's saved stat card selection.
  // Guarded by its own flag so it never re-adds a card the user removed.
  final favMigrated = prefs.getBool('ls_fav_stat_migrated') ?? false;
  if (!favMigrated && sessionKeyNotifier.value.isNotEmpty) {
    final cards = prefs.getStringList('ls_stat_cards');
    if (cards != null && !cards.contains('favorites_count')) {
      await prefs.setStringList('ls_stat_cards', [...cards, 'favorites_count']);
    }
    await prefs.setBool('ls_fav_stat_migrated', true);
  }
  showLovedBadgeNotifier.value         = prefs.getBool('ls_show_loved_badge')        ?? true;
  showFavoritesStatNotifier.value      = prefs.getBool('ls_show_favorites')          ?? true;

  final fallbackHex = prefs.getString('ls_nowplaying_fallback_color');
  nowPlayingFallbackColorNotifier.value =
      fallbackHex != null ? accentFromString(fallbackHex) : accentNotifier.value;

  pcModeNotifier.value   = prefs.getString('ls_pc_mode') ?? 'auto';
  navLabelNotifier.value     = prefs.getBool('ls_nav_labels')      ?? true;
  hapticFeedbackNotifier.value = prefs.getBool('ls_haptic_feedback') ?? true;

  // ── Data caches & storage ────────────────────────────────────────────────
  await DataCache.init();
  await UpdateService.init();
  await DataCache.clearExpired();
  await ScrobblesFileCache.init();
  await StorageManager.init();
  ImageService.pruneExpired();

  DataCache.offlineMode = prefs.getBool('ls_cache_serve_stale') ?? true;

  // ── Notifications & WorkManager ───────────────────────────────────────────
  // Notifications: mobile + Windows. WorkManager (background scheduling):
  // mobile only — Windows has no equivalent OS task scheduler wired up yet,
  // so on Windows sync notifications only fire during a manual/foreground sync.
  Map<String, dynamic>? notifLaunchData;

  if (!kIsWeb) {
    final isMobile  = Platform.isAndroid || Platform.isIOS;
    final isWindows = Platform.isWindows;
    if (isMobile || isWindows) {
      await NotificationService.init();
      notifLaunchData = await NotificationService.getLaunchPayloadData();
    }
    if (isMobile) {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      await NotificationWorker.scheduleAll();
    }
  }

  runApp(LastStatsApp(
    username:   username,
    apiKey:     apiKey,
    startupTab: startupTab,
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (notifLaunchData != null) {
      // App was launched (cold start) by tapping a notification — open the
      // detail page directly instead of silently launching a URL.
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => NotificationDetailPage(data: notifLaunchData!),
      ));
    } else {
      UpdateStartupChecker.run(navigatorKey);
    }
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//  LastStatsApp
// ══════════════════════════════════════════════════════════════════════════════

class LastStatsApp extends StatelessWidget {
  final String username;
  final String apiKey;
  final int    startupTab;

  const LastStatsApp({
    super.key,
    required this.username,
    required this.apiKey,
    this.startupTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return ValueListenableBuilder<String>(
          valueListenable: themeStyleNotifier,
          builder: (_, style, _) {

            // ── Nothing OS style ─────────────────────────────────────────
            if (style == 'nothing') {
              return ValueListenableBuilder<String>(
                valueListenable: nothingAccentNotifier,
                builder: (_, nAccent, _) {
                  return ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeModeNotifier,
                    builder: (_, mode, _) {
                      return ValueListenableBuilder<String>(
                        valueListenable: localeNotifier,
                        builder: (_, _, _) {
                          // Build both light and dark variants — Flutter picks
                          // the right one automatically based on themeMode.
                          final nLight = NothingTheme.build(
                            accent:     nAccent,
                            brightness: Brightness.light,
                          );
                          final nDark = NothingTheme.build(
                            accent:     nAccent,
                            brightness: Brightness.dark,
                          );
                          return ValueListenableBuilder<bool>(
                            valueListenable: navLabelNotifier,
                            builder: (_, showLabels, _) {
                              final navBehavior = showLabels
                                  ? NavigationDestinationLabelBehavior.alwaysShow
                                  : NavigationDestinationLabelBehavior.alwaysHide;
                              // Merge label behavior into Nothing themes
                              final nLightWithNav = nLight.copyWith(
                                navigationBarTheme: nLight.navigationBarTheme
                                    .copyWith(labelBehavior: navBehavior),
                              );
                              final nDarkWithNav = nDark.copyWith(
                                navigationBarTheme: nDark.navigationBarTheme
                                    .copyWith(labelBehavior: navBehavior),
                              );
                              return MaterialApp(
                                navigatorKey:               navigatorKey,
                                title:                      'LastStats',
                                debugShowCheckedModeBanner: false,
                                theme:     nLightWithNav,
                                darkTheme: nDarkWithNav,
                                themeMode: mode,
                                builder: (context, child) =>
                                    DesktopTitleBarShell(child: child!),
                                home: (username.isNotEmpty && apiKey.isNotEmpty)
                                    ? HomeScreen(username: username, apiKey: apiKey,
                                        startupTab: startupTab)
                                    : const SetupScreen(),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            }

            // ── Default style: Material You + accent + OLED ──────────────
            return ValueListenableBuilder<bool>(
              valueListenable: useDynamicColorNotifier,
              builder: (_, useDynamic, _) {
                return ValueListenableBuilder<Color>(
                  valueListenable: accentNotifier,
                  builder: (_, accent, _) {
                    return ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (_, mode, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: oledModeNotifier,
                          builder: (_, oled, _) {
                            return ValueListenableBuilder<String>(
                              valueListenable: localeNotifier,
                              builder: (_, _, _) {
                                final ColorScheme lightScheme =
                                    (useDynamic && lightDynamic != null)
                                        ? lightDynamic.harmonized()
                                        : ColorScheme.fromSeed(
                                            seedColor:  seedColorForScheme(accent),
                                            brightness: Brightness.light,
                                          );
                                final ColorScheme darkSchemeBase =
                                    (useDynamic && darkDynamic != null)
                                        ? darkDynamic.harmonized()
                                        : ColorScheme.fromSeed(
                                            seedColor:  seedColorForScheme(accent),
                                            brightness: Brightness.dark,
                                          );
                                final ColorScheme darkScheme = oled
                                    ? darkSchemeBase.copyWith(
                                        surface:                 Colors.black,
                                        surfaceDim:              Colors.black,
                                        surfaceBright:           const Color(0xFF1C1C1C),
                                        surfaceContainerLowest:  Colors.black,
                                        surfaceContainerLow:     const Color(0xFF080808),
                                        surfaceContainer:        const Color(0xFF0D0D0D),
                                        surfaceContainerHigh:    const Color(0xFF141414),
                                        surfaceContainerHighest: const Color(0xFF1C1C1C),
                                      )
                                    : darkSchemeBase;

                                return ValueListenableBuilder<bool>(
                                  valueListenable: navLabelNotifier,
                                  builder: (_, showLabels, _) {
                                    final navBehavior = showLabels
                                        ? NavigationDestinationLabelBehavior.alwaysShow
                                        : NavigationDestinationLabelBehavior.alwaysHide;
                                    // Inject labelBehavior into both themes so it
                                    // takes effect regardless of widget-level override.
                                    final lTheme = ThemeData(
                                      colorScheme: lightScheme,
                                      useMaterial3: true,
                                      navigationBarTheme: NavigationBarThemeData(
                                          labelBehavior: navBehavior),
                                    );
                                    final dTheme = ThemeData(
                                      colorScheme: darkScheme,
                                      useMaterial3: true,
                                      navigationBarTheme: NavigationBarThemeData(
                                          labelBehavior: navBehavior),
                                    );
                                    return MaterialApp(
                                      navigatorKey:               navigatorKey,
                                      title:                      'LastStats',
                                      debugShowCheckedModeBanner: false,
                                      theme:     lTheme,
                                      darkTheme: dTheme,
                                      themeMode: mode,
                                      builder: (context, child) =>
                                          DesktopTitleBarShell(child: child!),
                                      home: (username.isNotEmpty && apiKey.isNotEmpty)
                                          ? HomeScreen(username: username, apiKey: apiKey,
                                              startupTab: startupTab)
                                          : const SetupScreen(),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}