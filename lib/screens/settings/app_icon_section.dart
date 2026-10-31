import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../../l10n/extra_strings.dart';
import '../../services/app_icon_service.dart';
import 'settings_helpers.dart';

/// "App icon" picker shown in Settings > Appearance (Android only).
class AppIconSection extends StatefulWidget {
  const AppIconSection({super.key});

  @override
  State<AppIconSection> createState() => _AppIconSectionState();
}

class _AppIconSectionState extends State<AppIconSection> {
  String _current = 'default';

  @override
  void initState() {
    super.initState();
    AppIconService.current().then((v) { if (mounted) setState(() => _current = v); });
  }

  Future<void> _pick(String key) async {
    if (key == _current) return;
    HapticFeedback.selectionClick();
    final ok = await AppIconService.set(key);
    if (ok && mounted) setState(() => _current = key);
  }

  Future<void> _pin() async {
    HapticFeedback.selectionClick();
    await AppIconService.pin(_current);
  }

  @override
  Widget build(BuildContext context) {
    if (!AppIconService.supported) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Column(children: [
      SettingsSection(label: tx('ic_title'), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final k in AppIconService.keys)
                _tile(k, k == _current, scheme, text),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(tx('ic_note'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: FilledButton.tonalIcon(
            onPressed: _pin,
            icon: const Icon(Icons.add_to_home_screen_rounded),
            label: Text(tx('ic_pin')),
          ),
        ),
      ]),
      const SizedBox(height: 12),
    ]);
  }

  Widget _tile(String key, bool sel, ColorScheme scheme, TextTheme text) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _pick(key),
      child: SizedBox(
        width: 84,
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? scheme.primary : Colors.transparent,
                width: 3,
              ),
              color: sel ? scheme.primaryContainer : Colors.transparent,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset('assets/app_icons/$key.png', width: 64, height: 64),
            ),
          ),
          const SizedBox(height: 6),
          Text(tx('ic_$key'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel ? scheme.primary : scheme.onSurface,
              )),
        ]),
      ),
    );
  }
}
