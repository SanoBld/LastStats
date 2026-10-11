// ignore_for_file: unused_import
part of 'home_screen.dart';

// New chart widgets for the Charts tab. All colors come from the app theme.

String _monthShort(String key) {
  final m = RegExp(r'^(\d{4})-(\d{1,2})').firstMatch(key);
  return m == null ? key : '${m.group(2)!.padLeft(2, '0')}/${m.group(1)!.substring(2)}';
}

// Draw text around an anchor point (align: 0 left, 1 center, 2 right)
void _paintText(Canvas c, String text, Offset o,
    {required Color color, double size = 10, FontWeight weight = FontWeight.w600, int align = 1}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: weight)),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = align == 0 ? 0.0 : (align == 1 ? -tp.width / 2 : -tp.width);
  tp.paint(c, Offset(o.dx + dx, o.dy - tp.height / 2));
}

// Section wrapper: cookie header + subtitle + chart
class _ChartSec extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final String? sub;
  final Widget child;
  const _ChartSec({required this.index, required this.title, required this.icon,
      this.sub, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return _FadeInSection(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ChartHead(title: title, icon: icon),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  1. Trend: smooth area chart (monthly / cumulative), touch to inspect
// ══════════════════════════════════════════════════════════════════════════

class _TrendChart extends StatefulWidget {
  final Map<String, int> monthly;
  const _TrendChart({super.key, required this.monthly});
  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  bool _cumul = false;
  int? _sel;

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  void _setMode(bool c) {
    setState(() { _cumul = c; _sel = null; });
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final keys = widget.monthly.keys.toList()..sort();
    final raw  = [for (final k in keys) widget.monthly[k]!.toDouble()];
    var acc = 0.0;
    final vals = _cumul ? [for (final v in raw) acc += v] : raw;
    final total = raw.fold<double>(0, (a, b) => a + b).round();
    final avg   = raw.isEmpty ? 0 : (total / raw.length).round();
    var bestI = 0;
    for (var i = 0; i < raw.length; i++) { if (raw[i] > raw[bestI]) bestI = i; }
    final labels = [for (final k in keys) _monthShort(k)];

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _ChipStat(label: tx('ui_total'), value: _fmt(total), s: s, t: t),
          _ChipStat(label: tx('ui_avg_mo'), value: _fmt(avg), s: s, t: t),
          if (raw.isNotEmpty)
            _ChipStat(label: tx('cx_best_month'), value: labels[bestI], s: s, t: t),
        ]),
        const SizedBox(height: 14),
        M3SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(tx('cx_by_month'))),
            ButtonSegment(value: true,  label: Text(tx('cx_cumulative'))),
          ],
          selected: {_cumul},
          onSelectionChanged: (v) => _setMode(v.first),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: LayoutBuilder(builder: (ctx, c) {
            void pick(Offset p) {
              if (vals.isEmpty) return;
              final w = c.maxWidth - _TrendPainter.padL - _TrendPainter.padR;
              final i = vals.length == 1 ? 0
                  : (((p.dx - _TrendPainter.padL) / w) * (vals.length - 1)).round()
                      .clamp(0, vals.length - 1).toInt();
              if (i != _sel) setState(() => _sel = i);
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => pick(d.localPosition),
              onHorizontalDragStart: (d) => pick(d.localPosition),
              onHorizontalDragUpdate: (d) => pick(d.localPosition),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, _) => CustomPaint(
                  size: Size(c.maxWidth, 230),
                  painter: _TrendPainter(
                    v: vals, labels: labels,
                    progress: Curves.easeOutCubic.transform(_anim.value),
                    sel: _sel,
                    line: s.primary, accent: s.tertiary,
                    grid: s.outlineVariant.withValues(alpha: 0.45),
                    text: s.onSurfaceVariant, surface: s.surfaceContainerLow,
                    onSurface: s.onSurface,
                  ),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> v;
  final List<String> labels;
  final double progress;
  final int? sel;
  final Color line, accent, grid, text, surface, onSurface;
  static const padL = 38.0, padR = 10.0, padT = 28.0, padB = 24.0;

  _TrendPainter({required this.v, required this.labels, required this.progress, required this.sel,
      required this.line, required this.accent, required this.grid, required this.text,
      required this.surface, required this.onSurface});

  @override
  void paint(Canvas canvas, Size size) {
    final n = v.length;
    if (n == 0) return;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    var maxV = v.reduce(math.max);
    if (maxV <= 0) maxV = 1;
    double x(int i) => n == 1 ? padL + w / 2 : padL + w * i / (n - 1);
    double y(double val) => padT + h * (1 - val / maxV);

    // grid + y labels
    final gp = Paint()..color = grid..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final yy = padT + h * g / 3;
      canvas.drawLine(Offset(padL, yy), Offset(size.width - padR, yy), gp);
      _paintText(canvas, _fmt((maxV * (1 - g / 3)).round()), Offset(padL - 6, yy),
          color: text, size: 9, align: 2);
    }

    final pts = [for (var i = 0; i < n; i++) Offset(x(i), y(v[i]))];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n - 1; i++) {
      final p0 = pts[math.max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[math.min(i + 2, n - 1)];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy.clamp(padT, padT + h).toDouble(), c2.dx, c2.dy.clamp(padT, padT + h).toDouble(), p2.dx, p2.dy);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, padL + w * progress + 2, size.height));
    final fill = Path.from(path)
      ..lineTo(pts.last.dx, padT + h)
      ..lineTo(pts.first.dx, padT + h)
      ..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [line.withValues(alpha: 0.38), accent.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(padL, padT, w, h)));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(colors: [line, accent])
          .createShader(Rect.fromLTWH(padL, padT, w, h)));
    if (n <= 24) {
      for (final p in pts) {
        canvas.drawCircle(p, 4, Paint()..color = surface);
        canvas.drawCircle(p, 2.5, Paint()..color = line);
      }
    }
    canvas.restore();

    // x labels: first, middle, last
    final idxs = <int>{0, n ~/ 2, n - 1};
    for (final i in idxs) {
      _paintText(canvas, labels[i], Offset(pts[i].dx.clamp(padL + 14, size.width - padR - 14).toDouble(), size.height - 8),
          color: text, size: 9);
    }

    // selection: guide line, dot, bubble
    final si = sel;
    if (si != null && si < n) {
      final p = pts[si];
      canvas.drawLine(Offset(p.dx, padT), Offset(p.dx, padT + h),
          Paint()..color = accent.withValues(alpha: 0.4)..strokeWidth = 1.5);
      canvas.drawCircle(p, 8, Paint()..color = surface);
      canvas.drawCircle(p, 5.5, Paint()..color = accent);
      final tp = TextPainter(
        text: TextSpan(
          text: '${labels[si]} · ${_fmtExact(v[si].round())}',
          style: TextStyle(color: surface, fontSize: 11, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      final bw = tp.width + 18, bh = tp.height + 10;
      final bx = (p.dx - bw / 2).clamp(0.0, size.width - bw).toDouble();
      final by = math.max(0.0, p.dy - bh - 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(12)),
        Paint()..color = onSurface);
      tp.paint(canvas, Offset(bx + 9, by + 5));
    }
  }

  @override
  bool shouldRepaint(_TrendPainter o) =>
      o.progress != progress || o.sel != sel || o.v != v || o.line != line;
}

// ══════════════════════════════════════════════════════════════════════════
//  2. Listening clock: 24 radial bars
// ══════════════════════════════════════════════════════════════════════════

class _ClockChart extends StatelessWidget {
  final Map<int, int> data;
  const _ClockChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final peak = data.isEmpty ? 0
        : data.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tx('cx_clock'), style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          _PeakChip(
            label: '🕗 ${peak.toString().padLeft(2, '0')}:00',
            color: s.primaryContainer, onColor: s.onPrimaryContainer, t: t),
        ]),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, p, _) => AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(painter: _ClockPainter(
              data: data, peak: peak, progress: p,
              low: s.primaryContainer, high: s.primary, peakColor: s.tertiary,
              ring: s.outlineVariant.withValues(alpha: 0.4),
              text: s.onSurfaceVariant, onSurface: s.onSurface)),
          ),
        ),
      ]),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final Map<int, int> data;
  final int peak;
  final double progress;
  final Color low, high, peakColor, ring, text, onSurface;
  _ClockPainter({required this.data, required this.peak, required this.progress,
      required this.low, required this.high, required this.peakColor, required this.ring,
      required this.text, required this.onSurface});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = math.min(size.width, size.height) / 2 - 22;
    final r0 = outer * 0.44;
    final maxV = data.values.fold(0, (a, b) => a > b ? a : b);
    canvas.drawCircle(c, r0 - 8, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 1.5..color = ring);
    final bw = (2 * math.pi * r0 / 24) * 0.62;
    for (var h = 0; h < 24; h++) {
      final ratio = maxV > 0 ? (data[h] ?? 0) / maxV : 0.0;
      final ang = -math.pi / 2 + (h + 0.5) / 24 * 2 * math.pi;
      final dir = Offset(math.cos(ang), math.sin(ang));
      final len = (outer - r0) * (0.1 + 0.9 * ratio) * progress;
      canvas.drawLine(c + dir * r0, c + dir * (r0 + len), Paint()
        ..strokeWidth = bw
        ..strokeCap = StrokeCap.round
        ..color = h == peak && maxV > 0 ? peakColor : Color.lerp(low, high, ratio)!);
    }
    for (final h in const [0, 6, 12, 18]) {
      final ang = -math.pi / 2 + h / 24 * 2 * math.pi;
      _paintText(canvas, h.toString().padLeft(2, '0'),
          c + Offset(math.cos(ang), math.sin(ang)) * (outer + 14), color: text, size: 10);
    }
    _paintText(canvas, '${peak.toString().padLeft(2, '0')}h', c,
        color: onSurface, size: 24, weight: FontWeight.w900);
    _paintText(canvas, tx('cx_peak_hour'), c + const Offset(0, 22), color: text, size: 10);
  }

  @override
  bool shouldRepaint(_ClockPainter o) => o.progress != progress || o.data != data;
}

// ══════════════════════════════════════════════════════════════════════════
//  3. Week: rounded gradient bars
// ══════════════════════════════════════════════════════════════════════════

class _WeekChart extends StatelessWidget {
  final Map<int, int> data;
  const _WeekChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final labels = _chartWeekdayLabels;
    final maxV = data.values.fold(0, (a, b) => a > b ? a : b);
    final peak = data.isEmpty ? 1
        : data.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tx('ui_activity_by_day_of_wee'),
              style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          _PeakChip(label: '📅 ${labels[peak - 1]}',
              color: s.secondaryContainer, onColor: s.onSecondaryContainer, t: t),
        ]),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, p, _) => SizedBox(
            height: 150,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var d = 1; d <= 7; d++)
                Expanded(child: Builder(builder: (_) {
                  final v = data[d] ?? 0;
                  final ratio = maxV > 0 ? v / maxV : 0.0;
                  final isPeak = d == peak && maxV > 0;
                  return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(v > 0 ? _fmt(v) : '', style: t.labelSmall?.copyWith(
                        fontSize: 9,
                        color: isPeak ? s.tertiary : s.onSurfaceVariant,
                        fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500)),
                    const SizedBox(height: 4),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 10 + 96 * ratio * p,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: isPeak
                              ? [s.tertiary.withValues(alpha: 0.6), s.tertiary]
                              : [s.primaryContainer, s.primary.withValues(alpha: 0.4 + 0.6 * ratio)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[d - 1], style: t.labelSmall?.copyWith(
                        color: isPeak ? s.tertiary : s.onSurfaceVariant,
                        fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600)),
                  ]);
                })),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  4. Share donut + legend (artists, albums, genres fallback)
// ══════════════════════════════════════════════════════════════════════════

class _ShareDonut extends StatelessWidget {
  final List<dynamic> items;
  final String Function(dynamic) getLabel;
  final int Function(dynamic) getPlays;
  final void Function(dynamic)? onTap;
  const _ShareDonut({required this.items, required this.getLabel,
      required this.getPlays, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final top = items.take(5).toList();
    final total = items.fold<int>(0, (a, e) => a + getPlays(e));
    final vals = [for (final e in top) getPlays(e)];
    final rest = total - vals.fold<int>(0, (a, b) => a + b);
    final palette = [
      s.primary, s.tertiary, s.secondary,
      Color.lerp(s.primary, s.tertiary, 0.5)!,
      Color.lerp(s.secondary, s.primary, 0.5)!,
      s.outlineVariant,
    ];
    final segs = [...vals, if (rest > 0) rest];
    String pct(int v) => total > 0 ? '${(v * 100 / total).round()}%' : '';

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, p, _) => SizedBox(
            width: 140, height: 140,
            child: CustomPaint(
              painter: _DonutShare(values: segs, colors: palette, progress: p,
                  bg: s.surfaceContainerHighest),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_fmt(total), style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                Text(L.commonPlays, style: t.labelSmall?.copyWith(color: s.onSurfaceVariant)),
              ])),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(children: [
          for (var i = 0; i < top.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap == null ? null : () => onTap!(top[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: palette[i], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(getLabel(top[i]), maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 6),
                  Text(pct(vals[i]), style: t.labelSmall?.copyWith(color: s.onSurfaceVariant)),
                ]),
              ),
            ),
          if (rest > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: palette[5], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(tx('cx_others'), style: t.bodySmall?.copyWith(
                    color: s.onSurfaceVariant, fontWeight: FontWeight.w600))),
                Text(pct(rest), style: t.labelSmall?.copyWith(color: s.onSurfaceVariant)),
              ]),
            ),
        ])),
      ]),
    );
  }
}

class _DonutShare extends CustomPainter {
  final List<int> values;
  final List<Color> colors;
  final double progress;
  final Color bg;
  _DonutShare({required this.values, required this.colors, required this.progress, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final total = values.fold<int>(0, (a, b) => a + b);
    canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = stroke..color = bg);
    if (total <= 0) return;
    final gap = values.length > 1 ? 0.12 : 0.0;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final full = values[i] / total * 2 * math.pi;
      final sweep = math.max(0.0, full - gap) * progress;
      if (sweep > 0) {
        canvas.drawArc(rect, start + gap / 2, sweep, false, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colors[i % colors.length]);
      }
      start += full;
    }
  }

  @override
  bool shouldRepaint(_DonutShare o) => o.progress != progress || o.values != values;
}

// ══════════════════════════════════════════════════════════════════════════
//  5. Genres: radar chart
// ══════════════════════════════════════════════════════════════════════════

class _GenreChart extends StatelessWidget {
  final List<_TagEntry> tags;
  const _GenreChart({required this.tags});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    if (tags.length < 3) {
      return _ShareDonut(items: tags,
          getLabel: (e) => (e as _TagEntry).name, getPlays: (e) => (e as _TagEntry).count);
    }
    final top = tags.take(7).toList();
    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(12),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (_, p, _) => AspectRatio(
          aspectRatio: 1.1,
          child: CustomPaint(painter: _RadarPainter(
            labels: [for (final e in top) e.name.length > 12 ? '${e.name.substring(0, 11)}…' : e.name],
            values: [for (final e in top) e.count.toDouble()],
            progress: p,
            line: s.primary, fill: s.primary.withValues(alpha: 0.25), dot: s.tertiary,
            grid: s.outlineVariant.withValues(alpha: 0.5), text: s.onSurface)),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final double progress;
  final Color line, fill, dot, grid, text;
  _RadarPainter({required this.labels, required this.values, required this.progress,
      required this.line, required this.fill, required this.dot, required this.grid, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final c = size.center(Offset.zero);
    final R = math.min(size.width / 2 - 52, size.height / 2 - 24);
    final maxV = values.reduce(math.max);
    Offset pt(int i, double r) {
      final a = -math.pi / 2 + i / n * 2 * math.pi;
      return c + Offset(math.cos(a), math.sin(a)) * r;
    }
    final gp = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = grid;
    for (var ring = 1; ring <= 4; ring++) {
      final path = Path()..moveTo(pt(0, R * ring / 4).dx, pt(0, R * ring / 4).dy);
      for (var i = 1; i < n; i++) { path.lineTo(pt(i, R * ring / 4).dx, pt(i, R * ring / 4).dy); }
      canvas.drawPath(path..close(), gp);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, pt(i, R), gp);
      _paintText(canvas, labels[i], pt(i, R + 26), color: text, size: 10);
    }
    final pts = [for (var i = 0; i < n; i++) pt(i, R * (0.12 + 0.88 * (maxV > 0 ? values[i] / maxV : 0)) * progress)];
    final poly = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < n; i++) { poly.lineTo(pts[i].dx, pts[i].dy); }
    poly.close();
    canvas.drawPath(poly, Paint()..color = fill);
    canvas.drawPath(poly, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 3..strokeJoin = StrokeJoin.round..color = line);
    for (final p in pts) { canvas.drawCircle(p, 4.5, Paint()..color = dot); }
  }

  @override
  bool shouldRepaint(_RadarPainter o) => o.progress != progress || o.values != values;
}
