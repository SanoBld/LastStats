// lib/screens/settings/pc_mode_section.dart
//
// Reusable widget dropped into AppearancePage.
// Controls pcModeNotifier ('auto' | 'on' | 'off') and persists to prefs.

import 'package:flutter/material.dart';
import '../../widgets/m3_components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../l10n/l10n.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

class PcModeSection extends StatefulWidget {
  const PcModeSection({super.key});

  @override
  State<PcModeSection> createState() => _PcModeSectionState();
}

class _PcModeSectionState extends State<PcModeSection> {
  // Current value — mirrors pcModeNotifier
  String _mode = 'auto';

  @override
  void initState() {
    super.initState();
    _mode = pcModeNotifier.value;
    // Keep local state in sync if notifier changes from elsewhere
    pcModeNotifier.addListener(_onNotifierChange);
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    pcModeNotifier.removeListener(_onNotifierChange);
    localeNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _onNotifierChange() => setState(() => _mode = pcModeNotifier.value);
  void _rebuild()          => setState(() {});

  // Save choice and update the global notifier so HomeScreen reacts instantly
  Future<void> _setMode(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ls_pc_mode', v);
    setState(() => _mode = v);
    pcModeNotifier.value = v; // triggers HomeScreen rebuild
  }

  // Human-readable hint shown below the segmented button
  String get _hint {
    switch (_mode) {
      case 'on':
        return L.pcModeHintOn;
      case 'off':
        return L.pcModeHintOff;
      default:
        return L.pcModeHintAuto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return SettingsSection(
      label: L.pcModeLayout,
      children: [
        SettingChoiceRow(
          icon: Icons.desktop_windows_outlined,
          title: L.pcModeNavLayout,
          options: [
            ('auto', L.pcModeAuto,      Icons.devices_rounded),
            ('on',   L.pcModeSideRail,  Icons.view_sidebar_outlined),
            ('off',  L.pcModeBottomBar, Icons.view_headline_rounded),
          ],
          value: _mode,
          description: _hint,
          onChanged: _setMode,
        ),
      ],
    );
  }
}