// lib/screens/settings/pc_mode_section.dart
//
// Reusable widget dropped into AppearancePage.
// Controls pcModeNotifier ('auto' | 'on' | 'off') and persists to prefs.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../l10n/l10n.dart';
import 'settings_helpers.dart';

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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section title ─────────────────────────────────────────
              Row(children: [
                Icon(Icons.desktop_windows_outlined,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  L.pcModeNavLayout,
                  style: text.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ]),

              const SizedBox(height: 12),

              // ── Three-segment toggle ──────────────────────────────────
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'auto',
                    icon: const Icon(Icons.devices_rounded),
                    label: Text(L.pcModeAuto),
                  ),
                  ButtonSegment(
                    value: 'on',
                    icon: const Icon(Icons.view_sidebar_outlined),
                    label: Text(L.pcModeSideRail),
                  ),
                  ButtonSegment(
                    value: 'off',
                    icon: const Icon(Icons.view_headline_rounded),
                    label: Text(L.pcModeBottomBar),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => _setMode(s.first),
                style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),

              const SizedBox(height: 8),

              // ── Contextual hint ───────────────────────────────────────
              Text(
                _hint,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}