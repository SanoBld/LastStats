// lib/screens/settings/settings_rows.dart
// Material 3 Expressive settings kit. Every row (and every row the old
// pages still build with ListTile / SwitchListTile — see SettingsSection)
// looks and moves the same:
//   • cookie-shaped tonal icon badge, 8dp spacing scale (16 / 12 / 8)
//   • spring press feedback, shape-morphing option cards in sheets
//   • the current value is always visible (pill on the right)
//
//   SettingSwitchRow  → on/off          SettingChoiceRow → pick ONE (sheet)
//   SettingActionRow  → opens something SettingSliderRow → a number
//   SettingTextRow    → text / URL      SettingTimeRow   → a time
//   PickSortSheet     → choose items + sort them (+ optional "own row")

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../theme/m3_shapes.dart';
import '../../theme/m3_motion.dart';
import '../../widgets/m3_components.dart';

// ── Base tile ───────────────────────────────────────────────────────────────

class SettingTile extends StatefulWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  const SettingTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final reduce = M3Motion.reduced(context);

    Widget? badge;
    if (widget.leading != null) {
      var inner = widget.leading!;
      if (inner is Icon && inner.icon != null) inner = Icon(inner.icon);
      badge = M3CookieBadge(
        size: 40,
        color: scheme.primaryContainer,
        child: IconTheme(
          data: IconThemeData(color: scheme.onPrimaryContainer, size: 20),
          child: DefaultTextStyle(
            style: TextStyle(fontSize: 18, color: scheme.onPrimaryContainer),
            child: inner,
          ),
        ),
      );
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        if (badge != null) ...[badge, const SizedBox(width: 16)],
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            DefaultTextStyle(
              style: text.titleMedium!.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
              child: widget.title,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 2),
              DefaultTextStyle(
                style: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
                child: widget.subtitle!,
              ),
            ],
          ]),
        ),
        if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!],
      ]),
    );

    return AnimatedOpacity(
      opacity: widget.enabled ? 1 : 0.45,
      duration: M3Motion.effectsFastDuration,
      child: AnimatedScale(
        scale: _down && !reduce ? 0.985 : 1.0,
        duration: M3Motion.spatialFastDuration,
        curve: M3Motion.spatialFast,
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          onLongPress: widget.enabled ? widget.onLongPress : null,
          onHighlightChanged: (v) => setState(() => _down = v),
          child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 64), child: content),
        ),
      ),
    );
  }
}

/// Small tonal pill showing the current value of a row.
class _ValuePill extends StatelessWidget {
  final String label;
  const _ValuePill(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 148),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: scheme.secondaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(
                    color: scheme.onSecondaryContainer, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.unfold_more_rounded, size: 16, color: scheme.onSecondaryContainer),
        ]),
      ),
    );
  }
}

// ── Rows ────────────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) => SettingTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        enabled: onChanged != null,
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: onChanged == null ? null : () => onChanged!(!value),
      );
}

class SettingActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  const SettingActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => SettingTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null || subtitle!.isEmpty ? null : Text(subtitle!),
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
  final String? description; // small explanation under the title
  const SettingChoiceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final current = options.where((o) => o.$1 == value).map((o) => o.$2);
    return SettingTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: description == null || description!.isEmpty ? null : Text(description!),
      trailing: current.isEmpty ? null : _ValuePill(current.first),
      onTap: () async {
        final r = await showModalBottomSheet<String>(
          sheetAnimationStyle: kM3SheetAnimation,
          context: context,
          isScrollControlled: true,
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
  final bool enabled;
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
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: M3Motion.effectsFastDuration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            M3CookieBadge(
              size: 40,
              color: scheme.primaryContainer,
              child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                color: scheme.secondaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(valueLabel,
                  style: text.labelLarge?.copyWith(
                      color: scheme.onSecondaryContainer, fontWeight: FontWeight.w700)),
            ),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: value, min: min, max: max, divisions: divisions,
              label: valueLabel,
              onChanged: enabled ? onChanged : null,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ]),
      ),
    );
  }
}

class SettingTextRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  const SettingTextRow({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.url,
  });

  @override
  Widget build(BuildContext context) => SettingActionRow(
        icon: icon,
        title: title,
        subtitle: value.isEmpty ? hint : value,
        trailing: Icon(Icons.edit_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: () async {
          final ctrl = TextEditingController(text: value);
          final r = await showDialog<String>(
            animationStyle: kM3DialogAnimation,
            context: context,
            builder: (ctx) => AlertDialog(
              icon: Icon(icon),
              title: Text(title),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                autocorrect: false,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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

/// A "pick a time" row: shows hh:mm as a pill, tap opens [onTap].
class SettingTimeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int hour, minute;
  final VoidCallback onTap;
  const SettingTimeRow({
    super.key,
    required this.icon,
    required this.title,
    required this.hour,
    required this.minute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SettingTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: _ValuePill(
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'),
        onTap: onTap,
      );
}

// ── Sheet chrome ────────────────────────────────────────────────────────────
// Sized to its content: every option is visible at once, and the list only
// scrolls when it would not fit on screen.

Widget _sheetShell(BuildContext context, {required Widget header, required Widget body}) {
  final scheme = Theme.of(context).colorScheme;
  final maxH = MediaQuery.of(context).size.height * 0.9;
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: Container(
      color: scheme.surfaceContainerLow,
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 32, height: 4,
            decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        header,
        Flexible(child: body),
      ]),
    ),
  );
}

/// A tonal option card that morphs (corners + color) when selected.
class _OptionCard extends StatelessWidget {
  final bool selected;
  final Widget leading;
  final Widget title;
  final Widget? trailing;
  final VoidCallback onTap;
  const _OptionCard({
    required this.selected,
    required this.leading,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = BorderRadius.circular(selected ? 28 : 16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: M3ShapeMorph(
        radius: r,
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Row(children: [
                  leading,
                  const SizedBox(width: 16),
                  Expanded(
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                          ),
                      child: title,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _badge(BuildContext context, IconData? icon, {bool selected = false}) {
  final scheme = Theme.of(context).colorScheme;
  return M3CookieBadge(
    size: 40,
    color: selected ? scheme.primary : scheme.secondaryContainer,
    child: icon == null
        ? const SizedBox.shrink()
        : Icon(icon, size: 20, color: selected ? scheme.onPrimary : scheme.onSecondaryContainer),
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
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
      ),
      body: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        for (final o in options)
          _OptionCard(
            selected: o.$1 == value,
            leading: _badge(context, o.$3, selected: o.$1 == value),
            title: Text(o.$2),
            trailing: o.$1 == value
                ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                : null,
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

  Widget _lead(PickItem it, bool on) {
    final scheme = Theme.of(context).colorScheme;
    if (it.emoji != null) {
      return M3CookieBadge(
        size: 40,
        color: on ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        child: Text(it.emoji!, style: const TextStyle(fontSize: 20)),
      );
    }
    return _badge(context, it.icon, selected: on);
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
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.title,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
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
          const SizedBox(height: 8),
          Text(_sorting ? L.dashSortHint : widget.note!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ]),
    );

    final Widget body;
    if (_sorting) {
      body = ReorderableListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        onReorderItem: (o, n) => setState(() {
          final id = _en.removeAt(o);
          _en.insert(n, id);
        }),
        children: [
          for (final id in _en)
            Padding(
              key: ValueKey(id),
              padding: const EdgeInsets.only(bottom: 8),
              child: M3ShapeMorph(
                radius: BorderRadius.circular(16),
                color: scheme.surfaceContainerHigh,
                child: ListTile(
                  leading: _lead(_item(id), true),
                  title: Text(_item(id).label,
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.drag_indicator_rounded, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      );
    } else {
      body = ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        for (final id in [..._en, ..._dis])
          Builder(builder: (_) {
            final it = _item(id);
            final on = _en.contains(id);
            return _OptionCard(
              selected: on,
              leading: _lead(it, on),
              title: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: Text(it.label)),
                if (it.hint) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.touch_app_rounded, size: 16,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                ],
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.allowSolo && on)
                  IconButton(
                    tooltip: L.dashSeparateRow,
                    icon: Icon(Icons.splitscreen_rounded,
                        color: _solo.contains(id) ? scheme.primary : scheme.onPrimaryContainer.withValues(alpha: 0.4)),
                    onPressed: () => setState(() =>
                        _solo.contains(id) ? _solo.remove(id) : _solo.add(id)),
                  ),
                Icon(on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: on ? scheme.primary : scheme.outline),
              ]),
              onTap: () => _toggle(id, !on),
            );
          }),
      ]);
    }

    return _sheetShell(context, header: header, body: body);
  }
}
