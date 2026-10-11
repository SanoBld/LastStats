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

// Same hue as the theme (primary), different intensities
List<Color> _themePalette(ColorScheme s) {
  final p = HSLColor.fromColor(s.primary);
  final dark = s.brightness == Brightness.dark;
  final ls = dark ? const [0.82, 0.70, 0.58, 0.47, 0.37]
                  : const [0.28, 0.40, 0.52, 0.64, 0.76];
  return [
    for (final l in ls)
      HSLColor.fromAHSL(1, p.hue, math.max(p.saturation, 0.3), l).toColor(),
    s.outline,
  ];
}

Color _onColor(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : Colors.black;

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

  // Zoom: _zoom >= 1, _lo = first visible index (in index units)
  double _zoom = 1, _lo = 0;
  double _gZoom = 1, _gLo = 0, _gFx = 0;

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  void _setMode(bool c) {
    setState(() { _cumul = c; _sel = null; });
    _anim.forward(from: 0);
  }

  double _maxZoom(int n) => n <= 3 ? 1 : math.min(16.0, (n - 1) / 2);
  double _span(int n, double z) => n <= 1 ? 0 : (n - 1) / z;
  double _clampLo(int n, double lo, double span) =>
      n <= 1 ? 0 : lo.clamp(0.0, math.max(0.0, (n - 1) - span)).toDouble();

  // Zoom around a screen fraction (0..1) of the plot area
  void _zoomTo(int n, double z, double frac) {
    z = z.clamp(1.0, _maxZoom(n)).toDouble();
    final oldSpan = _span(n, _zoom);
    final anchor = _lo + frac * oldSpan;
    final span = _span(n, z);
    setState(() {
      _zoom = z;
      _lo = _clampLo(n, anchor - frac * span, span);
      _sel = null;
    });
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

    final bg = _cardBg(s, s.primaryContainer);
    return Container(
      decoration: _chartCardDecoration(s, s.primaryContainer),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _ChipStat(label: tx('ui_total'), value: _fmt(total), s: s, t: t,
              bg: s.primaryContainer, fg: s.onPrimaryContainer),
          _ChipStat(label: tx('ui_avg_mo'), value: _fmt(avg), s: s, t: t,
              bg: s.secondaryContainer, fg: s.onSecondaryContainer),
          if (raw.isNotEmpty)
            _ChipStat(label: tx('cx_best_month'), value: labels[bestI], s: s, t: t,
                bg: s.tertiaryContainer, fg: s.onTertiaryContainer),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: M3SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(tx('cx_by_month'))),
                ButtonSegment(value: true,  label: Text(tx('cx_cumulative'))),
              ],
              selected: {_cumul},
              onSelectionChanged: (v) => _setMode(v.first),
            ),
          ),
          if (raw.length > 3) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.zoom_out_rounded),
              onPressed: _zoom > 1 ? () => _zoomTo(raw.length, _zoom / 1.6, 0.5) : null,
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.zoom_in_rounded),
              onPressed: _zoom < _maxZoom(raw.length)
                  ? () => _zoomTo(raw.length, _zoom * 1.6, 0.5) : null,
            ),
          ],
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: LayoutBuilder(builder: (ctx, c) {
            final n = vals.length;
            final pw = c.maxWidth - _TrendPainter.padL - _TrendPainter.padR;
            final span = _span(n, _zoom);
            final lo = _clampLo(n, _lo, span);
            void pick(Offset p) {
              if (n == 0) return;
              final i = n == 1 ? 0
                  : (lo + ((p.dx - _TrendPainter.padL) / pw) * span).round()
                      .clamp(0, n - 1).toInt();
              if (i != _sel) setState(() => _sel = i);
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => pick(d.localPosition),
              onDoubleTap: () => _zoomTo(n, 1, 0.5),
              onScaleStart: (d) {
                _gZoom = _zoom; _gLo = lo; _gFx = d.localFocalPoint.dx;
                if (d.pointerCount == 1 && _zoom <= 1) pick(d.localFocalPoint);
              },
              onScaleUpdate: (d) {
                if (n < 2 || pw <= 0) return;
                if (d.pointerCount >= 2) {
                  final z = (_gZoom * d.scale).clamp(1.0, _maxZoom(n)).toDouble();
                  final startSpan = _span(n, _gZoom);
                  final anchor = _gLo + ((_gFx - _TrendPainter.padL) / pw) * startSpan;
                  final ns = _span(n, z);
                  final frac = (d.localFocalPoint.dx - _TrendPainter.padL) / pw;
                  setState(() {
                    _zoom = z;
                    _lo = _clampLo(n, anchor - frac * ns, ns);
                    _sel = null;
                  });
                } else if (_zoom > 1) {
                  final startSpan = _span(n, _gZoom);
                  final dIdx = (d.localFocalPoint.dx - _gFx) / pw * startSpan;
                  setState(() => _lo = _clampLo(n, _gLo - dIdx, startSpan));
                } else {
                  pick(d.localFocalPoint);
                }
              },
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, _) => CustomPaint(
                  size: Size(c.maxWidth, 230),
                  painter: _TrendPainter(
                    v: vals, labels: labels,
                    progress: Curves.easeOutCubic.transform(_anim.value),
                    sel: _sel, lo: lo, hi: lo + span,
                    line: s.primary, accent: s.tertiary,
                    grid: s.outlineVariant.withValues(alpha: 0.45),
                    text: s.onSurfaceVariant, surface: bg,
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
  final double lo, hi;
  final Color line, accent, grid, text, surface, onSurface;
  static const padL = 38.0, padR = 10.0, padT = 28.0, padB = 24.0;

  _TrendPainter({required this.v, required this.labels, required this.progress, required this.sel,
      required this.lo, required this.hi,
      required this.line, required this.accent, required this.grid, required this.text,
      required this.surface, required this.onSurface});

  @override
  void paint(Canvas canvas, Size size) {
    final n = v.length;
    if (n == 0) return;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    final i0 = lo.floor().clamp(0, n - 1).toInt();
    final i1 = hi.ceil().clamp(0, n - 1).toInt();
    var maxV = 0.0;
    for (var i = i0; i <= i1; i++) { if (v[i] > maxV) maxV = v[i]; }
    if (maxV <= 0) maxV = 1;
    final span = hi - lo;
    double x(int i) => (n == 1 || span <= 0) ? padL + w / 2 : padL + w * (i - lo) / span;
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
    canvas.clipRect(Rect.fromLTRB(padL - 6, 0, math.min(size.width, padL + w * progress + 6), size.height));
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
    if (span <= 24) {
      for (var i = i0; i <= i1; i++) {
        canvas.drawCircle(pts[i], 4, Paint()..color = surface);
        canvas.drawCircle(pts[i], 2.5, Paint()..color = line);
      }
    }
    canvas.restore();

    // x labels: first, middle, last
    final idxs = <int>{for (var k = 0; k <= 3; k++) (lo + span * k / 3).round().clamp(0, n - 1).toInt()};
    for (final i in idxs) {
      _paintText(canvas, labels[i], Offset(pts[i].dx.clamp(padL + 14, size.width - padR - 14).toDouble(), size.height - 8),
          color: text, size: 9);
    }

    // selection: guide line, dot, bubble
    final si = sel;
    if (si != null && si < n && si >= lo - 0.5 && si <= hi + 0.5) {
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
      o.progress != progress || o.sel != sel || o.v != v || o.line != line || o.lo != lo || o.hi != hi;
}

// ══════════════════════════════════════════════════════════════════════════
//  2. Listening clock: 24 radial bars
// ══════════════════════════════════════════════════════════════════════════

class _ClockChart extends StatefulWidget {
  final Map<int, int> data;
  const _ClockChart({required this.data});
  @override
  State<_ClockChart> createState() => _ClockChartState();
}

class _ClockChartState extends State<_ClockChart> {
  int? _sel;

  String _hh(int h) => h.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final data = widget.data;
    final peak = data.isEmpty ? 0
        : data.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final cur = _sel ?? peak;
    final cnt = data[cur] ?? 0;
    final pct = total > 0 ? cnt * 100 / total : 0.0;
    final bg = _cardBg(s, s.tertiaryContainer);

    return Container(
      decoration: _chartCardDecoration(s, s.tertiaryContainer),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tx('cx_clock'), style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          _PeakChip(
            label: '🕗 ${_hh(peak)}:00',
            color: s.tertiaryContainer, onColor: s.onTertiaryContainer, t: t),
        ]),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (ctx, c) {
          final side = c.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final off = d.localPosition - Offset(side / 2, side / 2);
              if (off.distance < side * 0.08) { setState(() => _sel = null); return; }
              var a = math.atan2(off.dy, off.dx) + math.pi / 2;
              if (a < 0) a += 2 * math.pi;
              final h = (a / (2 * math.pi) * 24).floor().clamp(0, 23).toInt();
              setState(() => _sel = h == _sel ? null : h);
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, p, _) => AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(painter: _ClockPainter(
                  data: data, peak: peak, hi: cur, selected: _sel != null, progress: p,
                  centerSub: _sel == null ? tx('cx_peak_hour') : '${_fmt(cnt)} ${L.commonPlays}',
                  low: s.primaryContainer, high: s.primary, peakColor: s.tertiary,
                  ring: s.outlineVariant.withValues(alpha: 0.4),
                  text: s.onSurfaceVariant, onSurface: s.onSurface, bg: bg)),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey(cur),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: s.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.schedule_rounded, size: 16, color: s.onTertiaryContainer),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${_hh(cur)}:00 – ${_hh((cur + 1) % 24)}:00  ·  ${_fmt(cnt)} ${L.commonPlays}  ·  ${pct.toStringAsFixed(1)}%',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: t.labelMedium?.copyWith(
                        color: s.onTertiaryContainer, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final Map<int, int> data;
  final int peak, hi;
  final bool selected;
  final String centerSub;
  final double progress;
  final Color low, high, peakColor, ring, text, onSurface, bg;
  _ClockPainter({required this.data, required this.peak, required this.hi,
      required this.selected, required this.centerSub, required this.progress,
      required this.low, required this.high, required this.peakColor, required this.ring,
      required this.text, required this.onSurface, required this.bg});

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
      final isHi = h == hi && maxV > 0;
      canvas.drawLine(c + dir * r0, c + dir * (r0 + len), Paint()
        ..strokeWidth = isHi ? bw * 1.25 : bw
        ..strokeCap = StrokeCap.round
        ..color = isHi ? peakColor : Color.lerp(low, high, ratio)!);
    }
    for (final h in const [0, 6, 12, 18]) {
      final ang = -math.pi / 2 + h / 24 * 2 * math.pi;
      _paintText(canvas, h.toString().padLeft(2, '0'),
          c + Offset(math.cos(ang), math.sin(ang)) * (outer + 14), color: text, size: 10);
    }
    _paintText(canvas, '${hi.toString().padLeft(2, '0')}h', c,
        color: onSurface, size: 24, weight: FontWeight.w900);
    _paintText(canvas, centerSub, c + const Offset(0, 22), color: text, size: 10);
  }

  @override
  bool shouldRepaint(_ClockPainter o) =>
      o.progress != progress || o.data != data || o.hi != hi || o.selected != selected;
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
      decoration: _chartCardDecoration(s, s.secondaryContainer),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tx('ui_activity_by_day_of_wee'),
              style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          _PeakChip(label: '📅 ${labels[peak - 1]}',
              color: s.tertiaryContainer, onColor: s.onTertiaryContainer, t: t),
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
    final palette = _themePalette(s);
    final segs = [...vals, if (rest > 0) rest];
    String pct(int v) => total > 0 ? '${(v * 100 / total).round()}%' : '';

    return Container(
      decoration: _chartCardDecoration(s, s.primaryContainer),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, p, _) => SizedBox(
            width: 150, height: 150,
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
                  Container(width: 12, height: 12,
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
                Container(width: 12, height: 12,
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
    const stroke = 30.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final total = values.fold<int>(0, (a, b) => a + b);
    canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = stroke..color = bg);
    if (total <= 0) return;
    final gap = values.length > 1 ? 0.05 : 0.0;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final full = values[i] / total * 2 * math.pi;
      final sweep = math.max(0.0, full - gap) * progress;
      if (sweep > 0) {
        canvas.drawArc(rect, start + gap / 2, sweep, false, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
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
      decoration: _chartCardDecoration(s, s.secondaryContainer),
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


// ══════════════════════════════════════════════════════════════════════════
//  6. Time of day: stacked bar + 4 accent tiles
// ══════════════════════════════════════════════════════════════════════════

class _DaypartChart extends StatelessWidget {
  final Map<int, int> data;
  const _DaypartChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final parts = <(String, IconData, int, int)>[
      (tx('cx_night'),     Icons.bedtime_rounded,    0, 6),
      (tx('cx_morning'),   Icons.wb_twilight_rounded, 6, 12),
      (tx('cx_afternoon'), Icons.wb_sunny_rounded,   12, 18),
      (tx('cx_evening'),   Icons.nights_stay_rounded, 18, 24),
    ];
    final sums = [
      for (final p in parts)
        [for (var h = p.$3; h < p.$4; h++) data[h] ?? 0].fold<int>(0, (a, b) => a + b),
    ];
    final total = sums.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    var top = 0;
    for (var i = 1; i < 4; i++) { if (sums[i] > sums[top]) top = i; }
    final pal = _themePalette(s).sublist(0, 4);

    Widget tile(int i) {
      final isTop = i == top;
      final pct = (sums[i] * 100 / total).round();
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isTop ? s.primaryContainer : s.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: pal[i], shape: BoxShape.circle),
              child: Icon(parts[i].$2, size: 18, color: _onColor(pal[i])),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(parts[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: t.labelMedium?.copyWith(
                      color: isTop ? s.onPrimaryContainer : s.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
              Text('$pct%', style: t.titleMedium?.copyWith(
                  color: isTop ? s.onPrimaryContainer : s.onSurface,
                  fontWeight: FontWeight.w900)),
            ])),
          ]),
        ),
      );
    }

    return Container(
      decoration: _chartCardDecoration(s, s.secondaryContainer),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, p, _) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 34,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: p,
                  child: Row(children: [
                    for (var i = 0; i < 4; i++)
                      if (sums[i] > 0)
                        Expanded(
                          flex: math.max(1, (sums[i] * 1000 / total).round()),
                          child: Container(
                            margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
                            color: pal[i],
                          ),
                        ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [tile(0), const SizedBox(width: 10), tile(1)]),
        const SizedBox(height: 10),
        Row(children: [tile(2), const SizedBox(width: 10), tile(3)]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  7. Day intensity: how many days fall in each scrobble range (tap a bar)
// ══════════════════════════════════════════════════════════════════════════

class _IntensityChart extends StatefulWidget {
  final Map<String, int> data;
  const _IntensityChart({super.key, required this.data});
  @override
  State<_IntensityChart> createState() => _IntensityChartState();
}

class _IntensityChartState extends State<_IntensityChart> {
  int? _sel;
  static const _edges = [1, 10, 20, 40, 80];
  static const _labels = ['1–9', '10–19', '20–39', '40–79', '80+'];

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final counts = List<int>.filled(5, 0);
    for (final v in widget.data.values) {
      if (v < 1) continue;
      var b = 0;
      for (var i = 0; i < _edges.length; i++) { if (v >= _edges[i]) b = i; }
      counts[b]++;
    }
    final active = counts.fold<int>(0, (a, b) => a + b);
    if (active == 0) return const SizedBox.shrink();
    var top = 0;
    for (var i = 1; i < 5; i++) { if (counts[i] > counts[top]) top = i; }
    final cur = _sel ?? top;
    final maxV = counts[top];
    final pct = (counts[cur] * 100 / active).round();

    return Container(
      decoration: _chartCardDecoration(s, s.primaryContainer),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _PeakChip(label: '$active ${tx('cx_days')}',
              color: s.primaryContainer, onColor: s.onPrimaryContainer, t: t),
        ]),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, p, _) => SizedBox(
            height: 150,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _sel = i == _sel ? null : i),
                    child: Builder(builder: (_) {
                      final ratio = maxV > 0 ? counts[i] / maxV : 0.0;
                      final isCur = i == cur;
                      return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text(counts[i] > 0 ? '${counts[i]}' : '', style: t.labelSmall?.copyWith(
                            fontSize: 10,
                            color: isCur ? s.tertiary : s.onSurfaceVariant,
                            fontWeight: isCur ? FontWeight.w800 : FontWeight.w500)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 10 + 100 * ratio * p,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                              colors: isCur
                                  ? [s.tertiary.withValues(alpha: 0.6), s.tertiary]
                                  : [s.primaryContainer, s.primary.withValues(alpha: 0.4 + 0.6 * ratio)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_labels[i], style: t.labelSmall?.copyWith(
                            fontSize: 10,
                            color: isCur ? s.tertiary : s.onSurfaceVariant,
                            fontWeight: isCur ? FontWeight.w800 : FontWeight.w600)),
                      ]);
                    }),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: s.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${_labels[cur]} ${L.commonPlays}  ·  ${counts[cur]} ${tx('cx_days')}  ·  $pct%',
              style: t.labelMedium?.copyWith(
                  color: s.onTertiaryContainer, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  8. Busiest days: top 5 horizontal bars
// ══════════════════════════════════════════════════════════════════════════

class _BusiestDays extends StatelessWidget {
  final Map<String, int> data;
  const _BusiestDays({required this.data});

  String _date(String k) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(k);
    return m == null ? k : '${m.group(3)}/${m.group(2)}/${m.group(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final top = (data.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    final maxV = top.first.value;

    return Container(
      decoration: _chartCardDecoration(s, s.tertiaryContainer),
      padding: const EdgeInsets.all(16),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, p, _) => Column(children: [
          for (var i = 0; i < top.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < top.length - 1 ? 12 : 0),
              child: Row(children: [
                Container(
                  width: 28, height: 28, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0 ? s.tertiary : s.primaryContainer),
                  child: Text('${i + 1}', style: t.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: i == 0 ? s.onTertiary : s.onPrimaryContainer)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(_date(top[i].key), style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(_fmt(top[i].value), style: t.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: i == 0 ? s.tertiary : s.primary)),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(children: [
                      Container(height: 10, color: s.surfaceContainerHighest),
                      FractionallySizedBox(
                        widthFactor: (top[i].value / maxV * p).clamp(0.02, 1.0).toDouble(),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: i == 0
                                ? [s.tertiary.withValues(alpha: 0.7), s.tertiary]
                                : [s.primary.withValues(alpha: 0.55), s.primary]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ])),
              ]),
            ),
        ]),
      ),
    );
  }
}
