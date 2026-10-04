// lib/screens/settings/battery_saver_page.dart
//
// Power saving mode. Cuts battery use: no tilt parallax, screen capped at
// ~60 Hz (Android), slower background refresh, paused artwork animations.
// It turns on by itself from 3 triggers: always on, the phone's own battery
// saver, or a battery level threshold. The top card shows the live state.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../l10n/extra_strings.dart';
import '../../services/eco_mode_controller.dart';
import '../../theme/m3_motion.dart';
import '../../widgets/m3_components.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

class BatterySaverPage extends StatefulWidget {
  const BatterySaverPage({super.key});

  @override
  State<BatterySaverPage> createState() => _BatterySaverPageState();
}

class _BatterySaverPageState extends State<BatterySaverPage> {
  bool _manual    = false;
  bool _system    = false;
  bool _auto      = false;
  int  _threshold = 20;

  @override
  void initState() {
    super.initState();
    _manual    = ecoModeManualNotifier.value;
    _system    = ecoModeSystemNotifier.value;
    _auto      = ecoModeAutoNotifier.value;
    _threshold = ecoModeThresholdNotifier.value;
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() { localeNotifier.removeListener(_rebuild); super.dispose(); }

  void _rebuild() => setState(() {});

  Future<void> _saveBool(String key, ValueNotifier<bool> n, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
    n.value = v;
  }

  Future<void> _setThreshold(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('ls_eco_mode_threshold', v);
    ecoModeThresholdNotifier.value = v;
    setState(() => _threshold = v);
  }

  // ── Live status card ────────────────────────────────────────────────────
  Widget _statusCard(ColorScheme scheme, TextTheme text) {
    return ValueListenableBuilder<String>(
      valueListenable: ecoModeReasonNotifier,
      builder: (context, reason, _) {
        final on = reason.isNotEmpty;
        final fg = on ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
        final sub = switch (reason) {
          'manual' => tx('eco_why_manual'),
          'system' => tx('eco_why_system'),
          'battery' => tx('eco_why_battery',
              {'n': ecoBatteryLevelNotifier.value.toString()}),
          _ => tx('eco_off_hint'),
        };
        return M3ShapeMorph(
          radius: BorderRadius.circular(on ? 36 : 24),
          color: on ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            M3CookieBadge(
              size: 60,
              color: on ? scheme.primary : scheme.surfaceContainerHighest,
              child: AnimatedSwitcher(
                duration: M3Motion.effectsDefaultDuration,
                switchInCurve: M3Motion.spatialFast,
                transitionBuilder: (c, a) => ScaleTransition(
                    scale: a, child: FadeTransition(opacity: a, child: c)),
                child: Icon(
                  on ? Icons.battery_saver_rounded : Icons.battery_full_rounded,
                  key: ValueKey(on),
                  size: 30,
                  color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: M3Motion.effectsDefaultDuration,
                child: Column(
                  key: ValueKey(reason),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(on ? tx('eco_on') : tx('eco_off'),
                        style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 4),
                    Text(sub,
                        style: text.bodyMedium
                            ?.copyWith(color: fg.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: ecoBatteryLevelNotifier,
              builder: (context, level, _) {
                if (level < 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: M3ShapeMorph(
                    radius: BorderRadius.circular(14),
                    color: scheme.secondaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('$level%',
                        style: text.labelLarge?.copyWith(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final canSystem = EcoModeController.systemSaverSupported;

    return Scaffold(
      appBar: M3AppBar(title: tx('ui_battery_saver')),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        _statusCard(scheme, text),

        const SizedBox(height: 24),

        SettingsSection(
          label: tx('eco_trig'),
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.battery_saver_rounded),
              title: Text(tx('ui_always_on')),
              subtitle: Text(tx('ui_force_eco_mode_on_rega')),
              value: _manual,
              onChanged: (v) {
                setState(() => _manual = v);
                _saveBool('ls_eco_mode_manual', ecoModeManualNotifier, v);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.smartphone_rounded),
              title: Text(tx('eco_sys_t')),
              subtitle: Text(canSystem ? tx('eco_sys_s') : tx('eco_sys_na')),
              value: _system && canSystem,
              onChanged: canSystem
                  ? (v) {
                      setState(() => _system = v);
                      _saveBool('ls_eco_mode_system', ecoModeSystemNotifier, v);
                    }
                  : null,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.battery_alert_rounded),
              title: Text(tx('ui_turn_on_below_a_batter')),
              subtitle: Text(tx('ui_switches_on_by_itself_')),
              value: _auto,
              onChanged: (v) {
                setState(() => _auto = v);
                _saveBool('ls_eco_mode_auto', ecoModeAutoNotifier, v);
              },
            ),
            SettingSliderRow(
              icon: Icons.percent_rounded,
              title: tx('ui_threshold'),
              valueLabel: '$_threshold%',
              value: _threshold.toDouble(), min: 5, max: 90, divisions: 17,
              enabled: _auto,
              onChanged: (v) => setState(() => _threshold = v.round()),
              onChangeEnd: (v) => _setThreshold(v.round()),
            ),
          ],
        ),

        const SizedBox(height: 24),

        SettingsSection(
          label: tx('eco_chg'),
          children: [
            SettingTile(
              leading: const Icon(Icons.screen_rotation_alt_rounded),
              title: Text(tx('eco_chg1')),
            ),
            SettingTile(
              leading: const Icon(Icons.speed_rounded),
              title: Text(tx('eco_chg2')),
            ),
            SettingTile(
              leading: const Icon(Icons.sync_rounded),
              title: Text(tx('eco_chg3')),
            ),
            SettingTile(
              leading: const Icon(Icons.animation_rounded),
              title: Text(tx('eco_chg4')),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(tx('eco_chg_note'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
