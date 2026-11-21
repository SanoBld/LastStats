// lib/screens/settings/source_ranker.dart
// Drag to sort + switch to enable: used for image and video sources.
import 'package:flutter/material.dart';
import '../../widgets/brand_icon.dart';

class RankItem {
  final String id, label;
  final String? asset;
  final IconData icon;
  const RankItem(this.id, this.label, this.icon, {this.asset});
}

class SourceRanker extends StatefulWidget {
  final String title, subtitle;
  final List<RankItem> items;   // every possible source
  final List<String> enabled;   // enabled ids, in order
  final ValueChanged<List<String>> onChanged;
  const SourceRanker({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<SourceRanker> createState() => _SourceRankerState();
}

class _SourceRankerState extends State<SourceRanker> {
  late List<String> _all;   // enabled first (in order), then the others
  late Set<String> _on;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    final ids = widget.items.map((e) => e.id).toList();
    final on = widget.enabled.where(ids.contains).toList();
    _on = on.toSet();
    _all = [...on, ...ids.where((i) => !_on.contains(i))];
  }

  void _emit() => widget.onChanged(_all.where(_on.contains).toList());

  RankItem _item(String id) => widget.items.firstWhere((e) => e.id == id);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    var rank = 0;
    final ranks = <String, int>{
      for (final id in _all) if (_on.contains(id)) id: ++rank,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _all.length,
          onReorder: (o, n) {
            setState(() {
              if (n > o) n -= 1;
              _all.insert(n, _all.removeAt(o));
            });
            _emit();
          },
          itemBuilder: (_, i) {
            final id = _all[i];
            final it = _item(id);
            final on = _on.contains(id);
            return Padding(
              key: ValueKey(id),
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Material(
                color: on ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28, height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? scheme.primary : scheme.surfaceContainerHighest,
                      ),
                      child: Text(on ? '${ranks[id]}' : '–',
                          style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: on ? scheme.onPrimary : scheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: it.asset != null
                            ? BrandIcon(it.asset!, it.icon,
                                size: 22, color: scheme.onSecondaryContainer)
                            : Icon(it.icon, size: 22, color: scheme.onSecondaryContainer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(it.label,
                        style: text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: on ? scheme.onSurface : scheme.onSurfaceVariant))),
                    Switch(
                      value: on,
                      // at least one source must stay on
                      onChanged: (v) {
                        if (!v && _on.length <= 1) return;
                        setState(() {
                          if (v) {
                            _on.add(id);
                          } else {
                            _on.remove(id);
                          }
                        });
                        _emit();
                      },
                    ),
                    ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle_rounded,
                            color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}
