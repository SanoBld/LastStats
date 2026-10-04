// lib/services/eco_mode_controller.dart
//
// Keeps ecoModeActiveNotifier in sync with the 3 triggers:
//   1. manual switch ("always on")
//   2. the phone's own battery saver (Android power saver / iOS low power mode)
//   3. battery level below a chosen %
// One place, so every widget in the app just reads ecoModeActiveNotifier.
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver, AppLifecycleState;
import 'package:flutter_displaymode/flutter_displaymode.dart';
import '../app_state.dart';

class EcoModeController {
  EcoModeController._();

  static final Battery _battery = Battery();
  static int  _lastLevel   = 100;
  static bool _systemSaver = false;
  static bool _resumed     = true;
  static Timer? _fastTimer;

  /// The phone's battery saver can only be read on Android and iOS.
  static bool get systemSaverSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    await _refresh();

    // Recheck on any switch / threshold change.
    ecoModeManualNotifier.addListener(_recompute);
    ecoModeAutoNotifier.addListener(_recompute);
    ecoModeThresholdNotifier.addListener(_recompute);
    ecoModeSystemNotifier.addListener(() { _refresh(); _updateFastPoll(); });
    // Drive the screen refresh-rate cap whenever the effective state flips.
    ecoModeActiveNotifier.addListener(_applyRefreshRate);
    _applyRefreshRate();

    // Charger plugged / unplugged: cheap event, no polling needed.
    try {
      _battery.onBatteryStateChanged.listen((_) => _refresh());
    } catch (_) {}

    // Slow fallback poll: the level drifts while just discharging.
    Timer.periodic(const Duration(minutes: 3), (_) { if (_resumed) _refresh(); });

    // Back in the app: the user may have changed the phone's power saver.
    WidgetsBinding.instance.addObserver(_Lifecycle());
    _updateFastPoll();
  }

  // Every 20 s, only while the app is visible AND the "follow the phone's
  // battery saver" switch is on — so it costs almost nothing.
  static void _updateFastPoll() {
    _fastTimer?.cancel();
    _fastTimer = null;
    if (!_resumed || !ecoModeSystemNotifier.value || !systemSaverSupported) return;
    _fastTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  static Future<void> _refresh() async {
    var known = true;
    try { _lastLevel = await _battery.batteryLevel; } catch (_) { _lastLevel = 100; known = false; }
    if (systemSaverSupported) {
      try { _systemSaver = await _battery.isInBatterySaveMode; } catch (_) { _systemSaver = false; }
    }
    ecoBatteryLevelNotifier.value = known ? _lastLevel : -1;
    ecoSystemSaverNotifier.value  = _systemSaver;
    _recompute();
  }

  static void _recompute() {
    String reason = '';
    if (ecoModeManualNotifier.value) {
      reason = 'manual';
    } else if (ecoModeSystemNotifier.value && _systemSaver) {
      reason = 'system';
    } else if (ecoModeAutoNotifier.value && _lastLevel <= ecoModeThresholdNotifier.value) {
      reason = 'battery';
    }
    ecoModeReasonNotifier.value = reason;
    ecoModeActiveNotifier.value = reason.isNotEmpty;
  }

  // Android only: cap the screen to its lowest refresh rate (~60Hz) in eco
  // mode, then restore the highest one when eco mode turns off.
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

class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      EcoModeController._resumed = true;
      EcoModeController._refresh();
      EcoModeController._updateFastPoll();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      EcoModeController._resumed = false;
      EcoModeController._updateFastPoll();
    }
  }
}
