// lib/screens/settings/battery_saver_page.dart
//
// Eco mode: cuts battery use by turning off tilt parallax, capping the
// screen refresh rate (~60Hz on Android), and slowing down background
// refresh timers. Can be forced on manually, or set to switch on by
// itself once battery drops below a chosen %.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';

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
      appBar: AppBar(
        title: Text(isEn ? 'Battery saver' : 'Mode éco'),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        SettingsSection(
          label: isEn ? 'Battery saver' : 'Mode éco',
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 6), child: Text(
              isEn
                  ? 'Turns off tilt parallax, caps the screen refresh rate, '
                    'and slows down background updates — everything else '
                    'stays full quality (images, exports, share cards).'
                  : 'Désactive le parallaxe au mouvement, plafonne le taux de '
                    'rafraîchissement de l\'écran, et ralentit les mises à jour en '
                    'arrière-plan — le reste garde sa pleine qualité (images, '
                    'exports, cartes de partage).',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )),
            SwitchListTile(
              secondary: Icon(Icons.battery_saver_rounded, color: scheme.primary),
              title: Text(isEn ? 'Always on' : 'Toujours activé',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(isEn
                  ? 'Force eco mode on, regardless of battery level.'
                  : 'Force le mode éco, quel que soit le niveau de batterie.',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              value: _manual,
              onChanged: _setManual,
            ),
          ],
        ),

        const SizedBox(height: 16),

        SettingsSection(
          label: isEn ? 'Auto-activate' : 'Activation automatique',
          children: [
            SwitchListTile(
              secondary: Icon(Icons.battery_alert_rounded, color: scheme.primary),
              title: Text(isEn ? 'Turn on below a battery %' : 'Activer sous un % de batterie',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(isEn
                  ? 'Switches on by itself once the battery drops to the level below.'
                  : 'S\'active toute seule dès que la batterie atteint le niveau ci-dessous.',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              value: _auto,
              onChanged: _setAuto,
            ),
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.percent_rounded, size: 18,
                      color: _auto ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(width: 8),
                  Text(isEn ? 'Threshold' : 'Seuil',
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
                          color: _auto ? null : scheme.onSurfaceVariant.withValues(alpha: 0.4))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outlineVariant)),
                    child: Text('$_threshold%',
                        style: text.labelMedium?.copyWith(fontFamily: 'monospace')),
                  ),
                ]),
                Slider(
                  value: _threshold.toDouble(), min: 5, max: 90, divisions: 17,
                  label: '$_threshold%',
                  onChanged: _auto ? (v) => setState(() => _threshold = v.round()) : null,
                  onChangeEnd: (v) => _setThreshold(v.round()),
                ),
              ],
            )),
          ],
        ),
      ]),
    );
  }
}
