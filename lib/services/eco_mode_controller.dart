// lib/services/eco_mode_controller.dart
//
// Watches the battery level and keeps ecoModeActiveNotifier in sync with
// the manual switch + the auto/threshold switches. One place, so every
// widget in the app just reads ecoModeActiveNotifier and doesn't need to
// know about battery_plus at all.
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_displaymode/flutter_displaymode.dart';
import '../app_state.dart';

class EcoModeController {
  EcoModeController._();

  static final Battery _battery = Battery();
  static int _lastLevel = 100;

  static Future<void> init() async {
    try {
      _lastLevel = await _battery.batteryLevel;
    } catch (_) {
      _lastLevel = 100; // no battery API (desktop/web) → auto mode never fires
    }
    _recompute();

    // Recheck on manual/auto/threshold changes.
    ecoModeManualNotifier.addListener(_recompute);
    ecoModeAutoNotifier.addListener(_recompute);
    ecoModeThresholdNotifier.addListener(_recompute);
    // Also drive the screen refresh-rate cap whenever the effective state flips.
    ecoModeActiveNotifier.addListener(_applyRefreshRate);
    _applyRefreshRate();

    // Recheck whenever the OS reports a charging-state change (charger
    // plugged/unplugged) — cheap event, no polling needed.
    try {
      _battery.onBatteryStateChanged.listen((_) async {
        try { _lastLevel = await _battery.batteryLevel; } catch (_) {}
        _recompute();
      });
    } catch (_) {}

    // Also poll every 3 minutes as a fallback, since level can drift while
    // just discharging (no state-change event) — deliberately infrequent
    // so this itself doesn't cost meaningful battery.
    Timer.periodic(const Duration(minutes: 3), (_) async {
      try { _lastLevel = await _battery.batteryLevel; } catch (_) { return; }
      _recompute();
    });
  }

  static void _recompute() {
    final auto = ecoModeAutoNotifier.value && _lastLevel <= ecoModeThresholdNotifier.value;
    ecoModeActiveNotifier.value = ecoModeManualNotifier.value || auto;
  }

  // Android only: cap the screen to its lowest refresh rate (~60Hz) in eco
  // mode instead of a 90/120Hz panel mode, then restore the normal/highest
  // mode when eco mode turns off. No-op on other platforms (iOS doesn't
  // expose this, desktop/web don't need it).
  static Future<void> _applyRefreshRate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (ecoModeActiveNotifier.value) {
        final modes = await FlutterDisplayMode.supported;
        if (modes.isEmpty) return;
        final lowest = modes.reduce((a, b) => a.refreshRate < b.refreshRate ? a : b);
        await FlutterDisplayMode.setPreferredMode(lowest);
      } else {
        await FlutterDisplayMode.setHighRefreshRate();
      }
    } catch (_) {}
  }
}
