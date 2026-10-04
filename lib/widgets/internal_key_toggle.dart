// lib/widgets/internal_key_toggle.dart
// Checkbox "Use the app's built-in key" with a "?" button explaining the risks.
import 'package:flutter/material.dart';
import '../l10n/extra_strings.dart';

class InternalKeyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const InternalKeyToggle({super.key, required this.value, required this.onChanged});

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx('key_internal_use')),
        content: Text(tx('key_internal_help')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Row(children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(child: Text(tx('key_internal_use'), style: text.bodySmall)),
        IconButton(
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          tooltip: tx('key_internal_help'),
          visualDensity: VisualDensity.compact,
          onPressed: () => _showHelp(context),
        ),
      ]),
    );
  }
}
