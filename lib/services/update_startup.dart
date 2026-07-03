// lib/services/update_startup.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'update_service.dart';

/// Checks for an update at startup.
/// No dialog — the news bell badge on the dashboard handles visibility.
class UpdateStartupChecker {
  static Future<void> run(GlobalKey<NavigatorState> navigatorKey) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final prefs     = await SharedPreferences.getInstance();
    final wantsBeta = prefs.getBool('ls_beta_channel') ?? false;
    final channel   = wantsBeta ? UpdateChannel.beta : UpdateChannel.stable;
    // Result is consumed by _fetchNews in _dashboard_page via UpdateService.
    await UpdateService.checkForUpdate(channel: channel);
  }
}