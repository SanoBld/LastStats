// lib/screens/settings/settings_rows.dart
// Shared rows + sheets so every setting looks and behaves the same:
//   SettingSwitchRow  → on/off
//   SettingChoiceRow  → pick ONE option (opens a sheet)
//   SettingActionRow  → opens something (sheet, page…)
//   SettingSliderRow  → a number
//   SettingTextRow    → a text / URL (opens a dialog)
//   PickSortSheet     → choose items + sort them (+ optional "own row")

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../theme/m3_shapes.dart';

// ── Small building blocks ───────────────────────────────────────────────────

class SettingSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const SettingSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        value: value,
        onChanged: onChanged,
      );
}

class SettingActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const SettingActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null || subtitle!.isEmpty ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

/// One option of a [SettingChoiceRow]: id, label, optional icon.
typedef ChoiceOption = (String, String, IconData?);

class SettingChoiceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<ChoiceOption> options;
  final String value;
  final ValueChanged<String> onChanged;
  const SettingChoiceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = options.where((o) => o.$1 == value).map((o) => o.$2);
    return SettingActionRow(
      icon: icon,
      title: title,
      subtitle: current.isEmpty ? '' : current.first,
      onTap: () async {
        final r = await showModalBottomSheet<String>(
          sheetAnimationStyle: kM3SheetAnimation,
          context: context,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (_) => _ChoiceSheet(title: title, options: options, value: value),
        );
        if (r != null && r != value) onChanged(r);
      },
    );
  }
}

class SettingSliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueLabel;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  const SettingSliderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: text.bodyLarge)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(valueLabel, style: text.labelMedium?.copyWith(fontFamily: 'monospace')),
          ),
        ]),
        Slider(
          value: value, min: min, max: max, divisions: divisions,
          label: valueLabel,
          onChanged: onChanged, onChangeEnd: onChangeEnd,
        ),
      ]),
    );
  }
}

class SettingTextRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  const SettingTextRow({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SettingActionRow(
        icon: icon,
        title: title,
        subtitle: value.isEmpty ? hint : value,
        onTap: () async {
          final ctrl = TextEditingController(text: value);
          final r = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(title),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(L.commonCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                    child: Text(L.commonSave)),
              ],
            ),
          );
          ctrl.dispose();
          if (r != null && r != value) onChanged(r);
        },
      );
}

// ── Sheet chrome shared by both sheets ──────────────────────────────────────

Widget _sheetShell(BuildContext context, {required Widget header, required Widget body, double initial = 0.55}) {
  final scheme = Theme.of(context).colorScheme;
  return DraggableScrollableSheet(
    initialChildSize: initial, minChildSize: 0.35, maxChildSize: 0.9, expand: false,
    builder: (ctx, sc) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: scheme.surface,
        child: Column(children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          header,
          Expanded(child: body),
        ]),
      ),
    ),
  );
}

// ── Single choice sheet ─────────────────────────────────────────────────────

class _ChoiceSheet extends StatelessWidget {
  final String title, value;
  final List<ChoiceOption> options;
  const _ChoiceSheet({required this.title, required this.options, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return _sheetShell(
      context,
      initial: 0.5,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
        child: Row(children: [
          Expanded(child: Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), children: [
        for (final o in options)
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: o.$3 == null ? null : Icon(o.$3, color: scheme.primary),
            title: Text(o.$2,
                style: text.bodyLarge?.copyWith(
                    fontWeight: o.$1 == value ? FontWeight.w700 : FontWeight.w500)),
            trailing: o.$1 == value
                ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                : Icon(Icons.radio_button_unchecked_rounded, color: scheme.outlineVariant),
            onTap: () => Navigator.pop(context, o.$1),
          ),
      ]),
    );
  }
}

// ── Choose + sort sheet ─────────────────────────────────────────────────────

class PickItem {
  final String id, label;
  final String? emoji;     // shown before the label (stat cards)
  final IconData? icon;    // or an icon (filters)
  final bool hint;         // small "tappable" hint icon
  const PickItem(this.id, this.label, {this.emoji, this.icon, this.hint = false});
}

class PickSortResult {
  final List<String> selected; // enabled ids, in the chosen order
  final Set<String> solo;      // ids shown on their own row
  const PickSortResult(this.selected, this.solo);
}

class PickSortSheet extends StatefulWidget {
  final String title;
  final List<PickItem> items;
  final List<String> selected;
  final Set<String> solo;
  final bool allowSolo;
  final String? note;
  const PickSortSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selected,
    this.solo = const {},
    this.allowSolo = false,
    this.note,
  });

  @override
  State<PickSortSheet> createState() => _PickSortSheetState();
}

class _PickSortSheetState extends State<PickSortSheet> {
  late List<String> _en;   // enabled, in order
  late List<String> _dis;  // disabled
  late Set<String> _solo;
  bool _sorting = false;

  @override
  void initState() {
    super.initState();
    final ids = widget.items.map((e) => e.id).toList();
    _en = [for (final s in widget.selected) if (ids.contains(s)) s];
    _dis = [for (final i in ids) if (!_en.contains(i)) i];
    _solo = {for (final s in widget.solo) if (_en.contains(s)) s};
  }

  PickItem _item(String id) => widget.items.firstWhere((e) => e.id == id);

  Widget _lead(PickItem it, ColorScheme scheme) {
    if (it.emoji != null) return Text(it.emoji!, style: const TextStyle(fontSize: 20));
    if (it.icon != null) return Icon(it.icon, color: scheme.primary);
    return const SizedBox.shrink();
  }

  void _toggle(String id, bool on) => setState(() {
        if (on) {
          _dis.remove(id);
          _en.add(id);
        } else {
          _en.remove(id);
          _solo.remove(id);
          _dis.insert(0, id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.title,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          FilledButton.tonalIcon(
            icon: Icon(_sorting ? Icons.check_rounded : Icons.swap_vert_rounded, size: 18),
            label: Text(_sorting ? L.dashSortDone : L.dashSortButton),
            onPressed: _en.length < 2 && !_sorting ? null : () => setState(() => _sorting = !_sorting),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context, PickSortResult(List.of(_en), Set.of(_solo))),
            child: Text(L.commonSave),
          ),
        ]),
        if (_sorting || widget.note != null) ...[
          const SizedBox(height: 6),
          Text(_sorting ? L.dashSortHint : widget.note!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ]),
    );

    final Widget body;
    if (_sorting) {
      body = ReorderableListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onReorderItem: (o, n) => setState(() {
          final id = _en.removeAt(o);
          _en.insert(n, id);
        }),
        children: [
          for (final id in _en)
            Card(
              key: ValueKey(id),
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4))),
              child: ListTile(
                leading: _lead(_item(id), scheme),
                title: Text(_item(id).label,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.drag_handle_rounded, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      );
    } else {
      body = ListView(padding: const EdgeInsets.fromLTRB(4, 0, 4, 16), children: [
        for (final id in [..._en, ..._dis])
          Builder(builder: (_) {
            final it = _item(id);
            final on = _en.contains(id);
            return ListTile(
              leading: _lead(it, scheme),
              title: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: Text(it.label)),
                if (it.hint) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.touch_app_rounded, size: 15,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ],
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.allowSolo && on)
                  IconButton(
                    tooltip: L.dashSeparateRow,
                    icon: Icon(Icons.splitscreen_rounded,
                        color: _solo.contains(id) ? scheme.primary : scheme.outlineVariant),
                    onPressed: () => setState(() =>
                        _solo.contains(id) ? _solo.remove(id) : _solo.add(id)),
                  ),
                Checkbox(value: on, onChanged: (v) => _toggle(id, v == true)),
              ]),
              onTap: () => _toggle(id, !on),
            );
          }),
      ]);
    }

    return _sheetShell(context, header: header, body: body, initial: 0.7);
  }
}
