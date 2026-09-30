// lib/screens/settings/battery_saver_page.dart
//
// Eco mode: cuts battery use by turning off tilt parallax, capping the
// screen refresh rate (~60Hz on Android), and slowing down background
// refresh timers. Can be forced on manually, or set to switch on by
// itself once battery drops below a chosen %.
import 'package:flutter/material.dart';
import '../../l10n/extra_strings.dart';
import '../../widgets/m3_components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

class BatterySaverPage extends StatefulWidget {
  const BatterySaverPage({super.key});

  @override
  State<BatterySaverPage> createState() => _BatterySaverPageState();
}

class _BatterySaverPageState extends State<BatterySaverPage> {
  bool _manual   = false;
  bool _auto     = false;
  int  _threshold = 20;

  @override
  void initState() {
    super.initState();
    _manual    = ecoModeManualNotifier.value;
    _auto      = ecoModeAutoNotifier.value;
    _threshold = ecoModeThresholdNotifier.value;
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() { localeNotifier.removeListener(_rebuild); super.dispose(); }

  void _rebuild() => setState(() {});

  Future<void> _setManual(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ls_eco_mode_manual', v);
    ecoModeManualNotifier.value = v;
    setState(() => _manual = v);
  }

  Future<void> _setAuto(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ls_eco_mode_auto', v);
    ecoModeAutoNotifier.value = v;
    setState(() => _auto = v);
  }

  Future<void> _setThreshold(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('ls_eco_mode_threshold', v);
    ecoModeThresholdNotifier.value = v;
    setState(() => _threshold = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final isEn   = localeNotifier.value == 'en';

    return Scaffold(
      appBar: M3AppBar(title: tx('ui_battery_saver')),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        SettingsSection(
          label: tx('ui_battery_saver'),
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 6), child: Text(
              tx('ui_turns_off_tilt_paralla'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )),
            SwitchListTile(
              secondary: Icon(Icons.battery_saver_rounded, color: scheme.primary),
              title: Text(tx('ui_always_on'),
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(tx('ui_force_eco_mode_on_rega'),
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              value: _manual,
              onChanged: _setManual,
            ),
          ],
        ),

        const SizedBox(height: 16),

        SettingsSection(
          label: tx('ui_auto_activate'),
          children: [
            SwitchListTile(
              secondary: Icon(Icons.battery_alert_rounded, color: scheme.primary),
              title: Text(tx('ui_turn_on_below_a_batter'),
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(tx('ui_switches_on_by_itself_'),
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              value: _auto,
              onChanged: _setAuto,
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
      ]),
    );
  }
}
