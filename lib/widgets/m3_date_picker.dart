// App-styled calendar dialogs (single date and date range), built only from
// the project's own pieces: M3Chip, M3TonalButton, M3LabelButton and the
// cookie shape. Month and weekday names follow the app language.
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../l10n/extra_strings.dart';
import '../theme/m3_motion.dart';
import '../theme/m3_shapes.dart';
import 'm3_components.dart';

DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

Future<DateTime?> showM3DatePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  String? title,
}) async {
  final r = await showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _M3CalendarDialog(
        range: false, initial: DateTimeRange(start: initial, end: initial),
        first: _d(first), last: _d(last), title: title),
  );
  return r?.start;
}

Future<DateTimeRange?> showM3DateRangePicker(
  BuildContext context, {
  required DateTime first,
  required DateTime last,
  DateTimeRange? initial,
  String? title,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _M3CalendarDialog(
        range: true, initial: initial, first: _d(first), last: _d(last), title: title),
  );
}

class _M3CalendarDialog extends StatefulWidget {
  const _M3CalendarDialog({
    required this.range,
    required this.initial,
    required this.first,
    required this.last,
    this.title,
  });
  final bool range;
  final DateTimeRange? initial;
  final DateTime first, last;
  final String? title;

  @override
  State<_M3CalendarDialog> createState() => _M3CalendarDialogState();
}

class _M3CalendarDialogState extends State<_M3CalendarDialog> {
  late DateTime _month;
  DateTime? _start, _end;
  bool _yearsOpen = false;

  List<String> get _months => tx('yr_months_full').split(',');

  @override
  void initState() {
    super.initState();
    _start = widget.initial == null ? null : _d(widget.initial!.start);
    _end   = widget.initial == null ? null : _d(widget.initial!.end);
    final ref = _start ?? widget.last;
    _month = DateTime(ref.year, ref.month);
  }

  bool get _canPrev => DateTime(_month.year, _month.month) .isAfter(DateTime(widget.first.year, widget.first.month));
  bool get _canNext => DateTime(_month.year, _month.month).isBefore(DateTime(widget.last.year, widget.last.month));

  void _go(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _tap(DateTime day) {
    m3Haptic();
    setState(() {
      if (!widget.range) {
        _start = day; _end = day;
      } else if (_start == null || _end != _start) {
        _start = day; _end = day;          // start a new range
      } else if (day.isBefore(_start!)) {
        _start = day; _end = day;
      } else {
        _end = day;                        // complete the range
      }
    });
  }

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]}';
  String _fmtY(DateTime d) => '${_fmt(d)} ${d.year}';

  String get _headline {
    if (_start == null) return '—';
    if (!widget.range || _end == null || _end == _start) {
      final wd = L.weekdaysShort[_start!.weekday - 1];
      return '$wd ${_fmt(_start!)}';
    }
    return '${_fmt(_start!)} – ${_fmtY(_end!)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    final canOk = _start != null;
    return Dialog(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Headline: what is currently selected.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (widget.title != null)
                  Text(widget.title!.toUpperCase(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: txt.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                if (widget.title != null) const SizedBox(height: 4),
                Text(_headline,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: txt.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 14),
            // Month navigation: arrows + tappable month/year label.
            Row(children: [
              M3TonalButton(
                width: 44, height: 44, padding: EdgeInsets.zero,
                radius: BorderRadius.circular(22),
                color: scheme.secondaryContainer,
                onTap: _canPrev && !_yearsOpen ? () => _go(-1) : null,
                child: Icon(Icons.chevron_left_rounded, color: scheme.onSecondaryContainer),
              ),
              Expanded(
                child: Center(
                  child: M3Chip(
                    selected: _yearsOpen,
                    avatar: Icon(_yearsOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    label: Text('${_months[_month.month - 1]} ${_month.year}'),
                    onSelected: (_) => setState(() => _yearsOpen = !_yearsOpen),
                  ),
                ),
              ),
              M3TonalButton(
                width: 44, height: 44, padding: EdgeInsets.zero,
                radius: BorderRadius.circular(22),
                color: scheme.secondaryContainer,
                onTap: _canNext && !_yearsOpen ? () => _go(1) : null,
                child: Icon(Icons.chevron_right_rounded, color: scheme.onSecondaryContainer),
              ),
            ]),
            const SizedBox(height: 12),
            // Fixed height (6 week rows + weekday header) so the dialog never
            // changes size when scrolling through months or opening years.
            LayoutBuilder(builder: (context, c) {
              final bodyH = 26 + 6 * (c.maxWidth / 7);
              return SizedBox(
                height: bodyH,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _yearsOpen
                      ? KeyedSubtree(key: const ValueKey('years'), child: _years(scheme, c.maxWidth))
                      : KeyedSubtree(
                          key: ValueKey('${_month.year}-${_month.month}'),
                          child: _grid(scheme, txt)),
                ),
              );
            }),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              M3LabelButton(
                kind: M3ButtonKind.text, height: 44, label: L.commonCancel,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              M3LabelButton(
                kind: M3ButtonKind.filled, height: 44, label: 'OK',
                onTap: canOk
                    ? () => Navigator.pop(context,
                        DateTimeRange(start: _start!, end: _end ?? _start!))
                    : null,
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _years(ColorScheme scheme, double width) {
    final ys = [for (var y = widget.last.year; y >= widget.first.year; y--) y];
    const cols = 4;
    const gap = 8.0;
    final cellW = (width - gap * (cols - 1)) / cols;
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: cols,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      childAspectRatio: cellW / 40,
      children: [
        for (final y in ys)
          Center(
            child: M3Chip(
              selected: y == _month.year,
              label: Text('$y'),
              onSelected: (_) => setState(() {
                var m = DateTime(y, _month.month);
                final lo = DateTime(widget.first.year, widget.first.month);
                final hi = DateTime(widget.last.year, widget.last.month);
                if (m.isBefore(lo)) m = lo;
                if (m.isAfter(hi)) m = hi;
                _month = m;
                _yearsOpen = false;
              }),
            ),
          ),
      ],
    );
  }

  Widget _grid(ColorScheme scheme, TextTheme txt) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final lead = firstDay.weekday - 1; // Monday first
    final daysIn = DateTime(_month.year, _month.month + 1, 0).day;
    const rows = 6; // always 6 rows: same height for every month
    final today = _d(DateTime.now());
    final hasRange = widget.range && _start != null && _end != null && _end != _start;

    Widget cell(int index) {
      final n = index - lead + 1;
      if (n < 1 || n > daysIn) return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
      final day = DateTime(_month.year, _month.month, n);
      final enabled = !day.isBefore(widget.first) && !day.isAfter(widget.last);
      final isStart = _start != null && day == _start;
      final isEnd = _end != null && day == _end;
      final selected = isStart || isEnd;
      final inRange = hasRange && day.isAfter(_start!) && day.isBefore(_end!);
      final isToday = day == today;

      final Color fg = selected
          ? scheme.onPrimary
          : !enabled
              ? scheme.onSurface.withValues(alpha: 0.3)
              : scheme.onSurface;

      Widget label = Center(
        child: Text('$n',
            style: txt.bodyMedium?.copyWith(
                color: fg,
                fontWeight: selected || isToday ? FontWeight.w800 : FontWeight.w500)),
      );

      Widget body = Container(
        margin: const EdgeInsets.all(3),
        decoration: selected
            ? ShapeDecoration(
                color: scheme.primary,
                shape: const M3CookieBorder(lobes: 8, amplitude: 0.06))
            : isToday
                ? ShapeDecoration(
                    shape: CircleBorder(side: BorderSide(color: scheme.primary, width: 1.5)))
                : null,
        child: label,
      );

      if (inRange || (hasRange && (isStart || isEnd))) {
        // Continuous band behind the range, cut in half under the endpoints.
        body = Stack(children: [
          Positioned.fill(
            child: Row(children: [
              Expanded(child: ColoredBox(
                  color: (inRange || isEnd) ? scheme.primaryContainer : Colors.transparent)),
              Expanded(child: ColoredBox(
                  color: (inRange || isStart) ? scheme.primaryContainer : Colors.transparent)),
            ]),
          ),
          body,
        ]);
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _tap(day) : null,
        child: AspectRatio(aspectRatio: 1, child: body),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        for (final w in L.weekdaysShort)
          Expanded(
            child: SizedBox(
              height: 20,
              child: Center(
              child: Text(w,
                  maxLines: 1, overflow: TextOverflow.clip,
                  style: txt.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      for (var r = 0; r < rows; r++)
        Row(children: [for (var c = 0; c < 7; c++) Expanded(child: cell(r * 7 + c))]),
    ]);
  }
}
