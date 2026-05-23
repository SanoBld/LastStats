// ignore_for_file: unused_import
part of 'home_screen.dart';

String _ct(String fr, String en) => localeNotifier.value == 'en' ? en : fr;

List<String> get _chartWeekdayLabels => localeNotifier.value == 'en'
    ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    : ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

const _kTwoPi  = 6.283185307179586;
const _kHalfPi = 1.5707963267948966;

// ── Page ─────────────────────────────────────────────────────────────────────

class _ChartsPage extends StatefulWidget {
  final LastFmService service;
  const _ChartsPage({required this.service});

  @override
  State<_ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<_ChartsPage>
    with AutomaticKeepAliveClientMixin {

  Map<String, int>? _monthly;
  List<dynamic> _topArtists = [];
  List<dynamic> _topAlbums  = [];
  bool _loading = true;
  String? _error;

  bool _hourlyLoading = false;
  Map<int, int>? _hourlyData;
  Map<int, int>? _weekdayData;
  int _hourlyCount = 0;

  bool _calendarLoading = false;
  Map<String, int>? _calendarData;

  bool _tagsLoading = false;
  List<_TagEntry> _tags = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        widget.service.getMonthlyScrobbles(months: 24),
        widget.service.getTopArtists(period: 'overall', limit: 10),
        widget.service.getTopAlbums(period: 'overall',  limit: 10),
      ]);
      if (!mounted) return;
      setState(() {
        _monthly    = (res[0] as Map).cast<String, int>();
        _topArtists = res[1] as List<dynamic>;
        _topAlbums  = res[2] as List<dynamic>;
        _loading    = false;
      });
      _loadTags();
      _loadHourly();
      _loadCalendar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadHourly() async {
    if (_hourlyLoading) return;
    setState(() {
      _hourlyLoading = true;
      _hourlyData    = null;
      _weekdayData   = null;
      _hourlyCount   = 0;
    });
    try {
      final pages = await Future.wait(
        List.generate(4, (i) => widget.service.getRecentTracks(limit: 50, page: i + 1)),
      );
      final hours    = <int, int>{for (var i = 0; i < 24; i++) i: 0};
      final weekdays = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
      int count = 0;
      for (final page in pages) {
        final raw  = page['track'];
        final list = raw is List ? raw : (raw != null ? [raw] : <dynamic>[]);
        for (final t in list) {
          final m = t as Map?;
          if (m == null) continue;
          if (m['@attr']?['nowplaying'] == 'true') continue;
          final uts = (m['date'] as Map?)?['uts']?.toString() ?? '';
          if (uts.isEmpty) continue;
          final sec = int.tryParse(uts);
          if (sec == null) continue;
          final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          hours[dt.hour]       = (hours[dt.hour]       ?? 0) + 1;
          weekdays[dt.weekday] = (weekdays[dt.weekday] ?? 0) + 1;
          count++;
        }
      }
      if (!mounted) return;
      setState(() {
        _hourlyData    = hours;
        _weekdayData   = weekdays;
        _hourlyCount   = count;
        _hourlyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hourlyLoading = false);
    }
  }

  Future<void> _loadCalendar() async {
    if (_calendarLoading) return;
    setState(() { _calendarLoading = true; _calendarData = null; });
    try {
      final pages = await Future.wait(
        List.generate(8, (i) => widget.service.getRecentTracks(limit: 50, page: i + 1)),
      );
      final data = <String, int>{};
      for (final page in pages) {
        final raw  = page['track'];
        final list = raw is List ? raw : (raw != null ? [raw] : <dynamic>[]);
        for (final t in list) {
          final m = t as Map?;
          if (m == null) continue;
          if (m['@attr']?['nowplaying'] == 'true') continue;
          final uts = (m['date'] as Map?)?['uts']?.toString() ?? '';
          if (uts.isEmpty) continue;
          final sec = int.tryParse(uts);
          if (sec == null) continue;
          final dt  = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
                      '${dt.day.toString().padLeft(2, '0')}';
          data[key] = (data[key] ?? 0) + 1;
        }
      }
      if (!mounted) return;
      setState(() { _calendarData = data; _calendarLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _calendarLoading = false);
    }
  }

  Future<void> _loadTags() async {
    if (_topArtists.isEmpty || _tagsLoading) return;
    setState(() { _tagsLoading = true; _tags = []; });
    try {
      final artists = _topArtists.take(10).toList();
      final tagLists = await Future.wait(
        artists.map((a) => widget.service
            .getArtistTopTags((a['name'] ?? '').toString())
            .catchError((_) => <dynamic>[])),
      );
      final agg = <String, int>{};
      for (var i = 0; i < artists.length; i++) {
        final plays = int.tryParse((artists[i]['playcount'] ?? '1').toString()) ?? 1;
        for (final t in (tagLists[i] as List).take(5)) {
          final name = (t['name'] ?? '').toString().trim();
          if (name.isEmpty || name.length > 20) continue;
          agg[name] = (agg[name] ?? 0) + plays;
        }
      }
      final sorted = agg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (!mounted) return;
      setState(() {
        _tags = sorted.take(8).map((e) => _TagEntry(name: e.key, count: e.value)).toList();
        _tagsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _tagsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    if (_loading)       return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);

    final monthly    = _monthly ?? {};
    final sortedKeys = monthly.keys.toList()..sort();
    int cum = 0;
    final cumulData = <String, int>{};
    for (final k in sortedKeys) { cum += monthly[k]!; cumulData[k] = cum; }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          const SizedBox(height: 16),
          Text(L.chartsTitle,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            _ct('Vos écoutes en images — tendances et évolutions',
                'Your scrobbles visualised — trends and evolutions'),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // ── 1. Monthly bars ───────────────────────────────────────────
          _SectionHeader(title: L.chartsMonthly, icon: Icons.calendar_month_rounded),
          const SizedBox(height: 12),
          if (monthly.isNotEmpty) _MonthlyCard(monthly: monthly),
          const SizedBox(height: 24),

          // ── 2. Cumulative line ────────────────────────────────────────
          if (cumulData.length >= 2) ...[
            _SectionHeader(
              title: _ct("Progression du total d'écoutes", 'Cumulative scrobble progression'),
              icon: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 12),
            _CumulativeLineCard(data: cumulData),
            const SizedBox(height: 24),
          ],

          // ── 3. Genre tags ─────────────────────────────────────────────
          _SectionHeader(
            title: _ct('Vos genres musicaux', 'Your musical genres'),
            icon: Icons.equalizer_rounded,
          ),
          const SizedBox(height: 8),
          Text(_ct('Basé sur vos top artistes', 'Based on your top artists'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          if (_tagsLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_tags.isNotEmpty)
            _TagsCard(tags: _tags),
          const SizedBox(height: 24),

          // ── 4. Listening habits ───────────────────────────────────────
          _SectionHeader(
            title: _ct("Habitudes d'écoute", 'Listening habits'),
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 8),
          Text(
            _hourlyCount > 0
                ? _ct('Basé sur $_hourlyCount scrobbles récents',
                      'Based on $_hourlyCount recent scrobbles')
                : _ct('Analyse vos ~200 derniers scrobbles',
                      'Analyses your last ~200 scrobbles'),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (_hourlyLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_hourlyData != null) ...[
            _HourlyBarCard(data: _hourlyData!),
            const SizedBox(height: 12),
            _WeekdayBarCard(data: _weekdayData!),
          ],
          const SizedBox(height: 24),

          // ── 5. Artist donut ───────────────────────────────────────────
          if (_topArtists.isNotEmpty) ...[
            _SectionHeader(title: L.chartsArtistDist, icon: Icons.mic_rounded),
            const SizedBox(height: 12),
            _DonutDistributionCard(
              items:    _topArtists,
              getLabel: (e) => (e['name'] ?? '').toString(),
              getPlays: (e) => int.tryParse((e['playcount'] ?? '0').toString()) ?? 0,
              baseColor: scheme.primary,
              onTap: (e) => showDetailSheet(context,
                  Map<String, dynamic>.from(e as Map), 'artists', widget.service),
            ),
            const SizedBox(height: 24),
          ],

          // ── 6. Album donut ────────────────────────────────────────────
          if (_topAlbums.isNotEmpty) ...[
            _SectionHeader(
              title: _ct('Répartition par album', 'Album distribution'),
              icon: Icons.album_rounded,
            ),
            const SizedBox(height: 12),
            _DonutDistributionCard(
              items:    _topAlbums,
              getLabel: (e) => (e['name'] ?? '').toString(),
              getPlays: (e) => int.tryParse((e['playcount'] ?? '0').toString()) ?? 0,
              baseColor: scheme.secondary,
              onTap: (e) => showDetailSheet(context,
                  Map<String, dynamic>.from(e as Map), 'albums', widget.service),
            ),
            const SizedBox(height: 24),
          ],

          // ── 7. Calendar heatmap ───────────────────────────────────────
          _SectionHeader(
            title: _ct('Calendrier musical', 'Listening calendar'),
            icon: Icons.grid_on_rounded,
          ),
          const SizedBox(height: 8),
          Text(_ct('Activité récente jour par jour', 'Recent activity day by day'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          if (_calendarLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_calendarData != null)
            _CalendarCard(data: _calendarData!),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Helper: card decoration shared by all chart cards
// ══════════════════════════════════════════════════════════════════════════

BoxDecoration _chartCardDecoration(ColorScheme s) => BoxDecoration(
  color: s.surfaceContainerHighest,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: s.outlineVariant.withValues(alpha: 0.45), width: 1),
);

Widget _scrollHint(BuildContext context) {
  final s = Theme.of(context).colorScheme;
  final t = Theme.of(context).textTheme;
  return Center(
    child: Text(
      _ct('← glisser pour naviguer', '← swipe to navigate'),
      style: t.labelSmall?.copyWith(
          fontSize: 9, color: s.onSurfaceVariant.withValues(alpha: 0.55)),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  _MonthlyCard  — scrollable bar chart (fixed-height bars, no FractionallySizedBox)
// ══════════════════════════════════════════════════════════════════════════

class _MonthlyCard extends StatefulWidget {
  final Map<String, int> monthly;
  const _MonthlyCard({required this.monthly});

  @override
  State<_MonthlyCard> createState() => _MonthlyCardState();
}

class _MonthlyCardState extends State<_MonthlyCard> {
  final _sc = ScrollController();
  static const _colW    = 46.0;
  static const _barMaxH = 100.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients) _sc.jumpTo(_sc.position.maxScrollExtent);
    });
  }

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s      = Theme.of(context).colorScheme;
    final t      = Theme.of(context).textTheme;
    final sorted = widget.monthly.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = sorted.isEmpty ? 1
        : sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final total  = sorted.fold<int>(0, (acc, e) => acc + e.value);
    final avg    = sorted.isEmpty ? 0 : (total / sorted.length).round();

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat chips
          Wrap(spacing: 8, children: [
            _ChipStat(label: _ct('Total', 'Total'), value: _fmt(total), s: s, t: t),
            _ChipStat(label: _ct('Moy./mois', 'Avg/mo'), value: _fmt(avg), s: s, t: t),
          ]),
          const SizedBox(height: 16),

          // Bar area — fixed pixel heights
          SingleChildScrollView(
            controller: _sc,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sorted.map((e) {
                final ratio  = maxVal > 0 ? e.value / maxVal : 0.0;
                final barH   = (_barMaxH * ratio).clamp(2.0, _barMaxH);
                final isMax  = e.value == maxVal;
                final color  = isMax
                    ? s.primary
                    : s.primary.withValues(alpha: 0.28 + ratio * 0.60);
                return SizedBox(
                  width: _colW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        ratio > 0.15 ? _fmt(e.value) : '',
                        textAlign: TextAlign.center,
                        style: t.labelSmall?.copyWith(
                          fontSize: 8,
                          color: isMax ? s.primary : s.onSurfaceVariant,
                          fontWeight: isMax ? FontWeight.w800 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: _colW - 10,
                          height: barH,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.key.substring(5),
                        textAlign: TextAlign.center,
                        style: t.labelSmall?.copyWith(
                          fontSize: 9,
                          color: isMax ? s.primary : s.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          _scrollHint(context),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _CumulativeLineCard  — scrollable line chart via CustomPaint
// ══════════════════════════════════════════════════════════════════════════

class _CumulativeLineCard extends StatefulWidget {
  final Map<String, int> data;
  const _CumulativeLineCard({required this.data});

  @override
  State<_CumulativeLineCard> createState() => _CumulativeLineCardState();
}

class _CumulativeLineCardState extends State<_CumulativeLineCard> {
  final _sc = ScrollController();
  static const _ptW = 42.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients) _sc.jumpTo(_sc.position.maxScrollExtent);
    });
  }

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s    = Theme.of(context).colorScheme;
    final t    = Theme.of(context).textTheme;
    final keys = widget.data.keys.toList()..sort();
    final vals = keys.map((k) => widget.data[k]!.toDouble()).toList();
    final total = vals.isEmpty ? 0 : vals.last.toInt();

    String bestMonth = ''; int bestDelta = 0;
    for (var i = 1; i < keys.length; i++) {
      final delta = widget.data[keys[i]]! - widget.data[keys[i - 1]]!;
      if (delta > bestDelta) { bestDelta = delta; bestMonth = keys[i]; }
    }

    const chartH = 120.0;
    final contentW = (_ptW * keys.length).clamp(1.0, double.infinity);

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, children: [
            _ChipStat(label: _ct('Total', 'Total'), value: _fmt(total), s: s, t: t),
            if (bestMonth.isNotEmpty)
              _ChipStat(
                label: _ct('Meilleur mois', 'Best month'),
                value: '${bestMonth.substring(5)} (+${_fmt(bestDelta)})',
                s: s, t: t,
              ),
          ]),
          const SizedBox(height: 16),
          SingleChildScrollView(
            controller: _sc,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: contentW,
                  height: chartH,
                  child: CustomPaint(
                    painter: _LinePainter(keys: keys, values: vals, color: s.primary),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: contentW,
                  child: Row(
                    children: keys.asMap().entries.map((e) {
                      final show = keys.length <= 12
                          || e.key % (keys.length ~/ 8).clamp(1, 99) == 0
                          || e.key == keys.length - 1;
                      return SizedBox(
                        width: _ptW,
                        child: show
                            ? Text(
                                e.value.substring(5),
                                textAlign: TextAlign.center,
                                style: t.labelSmall?.copyWith(
                                    fontSize: 8, color: s.onSurfaceVariant),
                              )
                            : const SizedBox.shrink(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _scrollHint(context),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<String> keys;
  final List<double> values;
  final Color        color;
  const _LinePainter({required this.keys, required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 2) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final w = size.width; final h = size.height;
    final pts = List.generate(n, (i) => Offset(
      i * w / (n - 1),
      h - (values[i] / maxVal) * h * 0.90,
    ));

    final fill = Path()..moveTo(pts[0].dx, h)..lineTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      fill.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    fill..lineTo(pts.last.dx, h)..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.03)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    final line = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      line.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(line, Paint()
      ..color = color ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round);

    canvas.drawCircle(pts.last, 5, Paint()..color = color.withValues(alpha: 0.22));
    canvas.drawCircle(pts.last, 3, Paint()..color = color);
    canvas.drawCircle(pts.last, 1.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values || old.color != color;
}

// ══════════════════════════════════════════════════════════════════════════
//  _TagsCard
// ══════════════════════════════════════════════════════════════════════════

class _TagsCard extends StatelessWidget {
  final List<_TagEntry> tags;
  const _TagsCard({required this.tags});

  @override
  Widget build(BuildContext context) {
    final s       = Theme.of(context).colorScheme;
    final t       = Theme.of(context).textTheme;
    final palette = _buildPalette(s.primary, tags.length);
    final maxVal  = tags.isEmpty ? 1
        : tags.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: tags.asMap().entries.map((e) {
          final ratio = maxVal > 0 ? e.value.count / maxVal : 0.0;
          final color = palette[e.key % palette.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(e.value.name,
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${(ratio * 100).round()}%',
                    style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio, minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _HourlyBarCard  — scrollable 24h bars, fixed height
// ══════════════════════════════════════════════════════════════════════════

class _HourlyBarCard extends StatefulWidget {
  final Map<int, int> data;
  const _HourlyBarCard({required this.data});

  @override
  State<_HourlyBarCard> createState() => _HourlyBarCardState();
}

class _HourlyBarCardState extends State<_HourlyBarCard> {
  final _sc = ScrollController();
  static const _colW    = 32.0;
  static const _barMaxH = 80.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_sc.hasClients) return;
      final peakH = widget.data.isEmpty ? 0
          : widget.data.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      final target = (peakH * _colW - 120.0)
          .clamp(0.0, _sc.position.maxScrollExtent);
      _sc.animateTo(target,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  static String _emoji(int h) {
    if (h < 6) return '🌙'; if (h < 12) return '☀️';
    if (h < 18) return '🌤'; return '🌆';
  }

  @override
  Widget build(BuildContext context) {
    final s      = Theme.of(context).colorScheme;
    final t      = Theme.of(context).textTheme;
    final maxVal = widget.data.values.fold(0, (a, b) => a > b ? a : b);
    final peakH  = widget.data.isEmpty ? 0
        : widget.data.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_ct('Répartition horaire', 'Hourly distribution'),
                style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            _PeakChip(
              label: '${_emoji(peakH)} ${peakH}h',
              color: s.primaryContainer, onColor: s.onPrimaryContainer, t: t,
            ),
          ]),
          const SizedBox(height: 14),

          SingleChildScrollView(
            controller: _sc,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (h) {
                final v      = widget.data[h] ?? 0;
                final ratio  = maxVal > 0 ? v / maxVal : 0.0;
                final barH   = (_barMaxH * ratio).clamp(2.0, _barMaxH);
                final isPeak = h == peakH;
                final color  = isPeak
                    ? s.primary
                    : s.primary.withValues(alpha: 0.20 + ratio * 0.65);

                return SizedBox(
                  width: _colW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        (isPeak && v > 0) ? _fmt(v) : '',
                        style: t.labelSmall?.copyWith(
                            fontSize: 8, color: s.primary,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: _colW - 8,
                        height: barH,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${h}h',
                          style: t.labelSmall?.copyWith(
                            fontSize: 8,
                            color: isPeak
                                ? s.primary
                                : s.onSurfaceVariant.withValues(alpha: 0.6),
                          )),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _BandLabel('🌙 0–5h',   s.onSurfaceVariant, t),
            _BandLabel('☀️ 6–11h',  s.onSurfaceVariant, t),
            _BandLabel('🌤 12–17h', s.onSurfaceVariant, t),
            _BandLabel('🌆 18–23h', s.onSurfaceVariant, t),
          ]),
          const SizedBox(height: 4),
          _scrollHint(context),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _WeekdayBarCard  — 7 bars, fixed height, fits in width
// ══════════════════════════════════════════════════════════════════════════

class _WeekdayBarCard extends StatelessWidget {
  final Map<int, int> data;
  const _WeekdayBarCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final s       = Theme.of(context).colorScheme;
    final t       = Theme.of(context).textTheme;
    final labels  = _chartWeekdayLabels;
    final maxVal  = data.values.fold(0, (a, b) => a > b ? a : b);
    final peakDay = data.isEmpty ? 1
        : data.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_ct('Activité par jour de la semaine', 'Activity by day of week'),
                style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            _PeakChip(
              label: '📅 ${labels[peakDay - 1]}',
              color: s.secondaryContainer, onColor: s.onSecondaryContainer, t: t,
            ),
          ]),
          const SizedBox(height: 14),
          // Use LayoutBuilder to make bars fill the available width
          LayoutBuilder(builder: (_, constraints) {
            const barMaxH = 90.0;
            final colW    = constraints.maxWidth / 7;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day    = i + 1;
                final v      = data[day] ?? 0;
                final ratio  = maxVal > 0 ? v / maxVal : 0.0;
                final barH   = (barMaxH * ratio).clamp(2.0, barMaxH);
                final isPeak = day == peakDay;
                final color  = isPeak
                    ? s.secondary
                    : s.secondary.withValues(alpha: 0.20 + ratio * 0.65);

                return SizedBox(
                  width: colW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        v > 0 ? _fmt(v) : '',
                        style: t.labelSmall?.copyWith(
                          fontSize: 8,
                          color: isPeak ? s.secondary : s.onSurfaceVariant,
                          fontWeight: isPeak ? FontWeight.w800 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Center(
                        child: Container(
                          width: colW - 10,
                          height: barH,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: t.labelSmall?.copyWith(
                          fontSize: 10,
                          color: isPeak ? s.secondary : s.onSurfaceVariant,
                          fontWeight: isPeak ? FontWeight.w800 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _DonutDistributionCard
// ══════════════════════════════════════════════════════════════════════════

class _DonutDistributionCard extends StatelessWidget {
  final List<dynamic>            items;
  final String Function(dynamic) getLabel;
  final int    Function(dynamic) getPlays;
  final Color                    baseColor;
  final void   Function(dynamic) onTap;
  const _DonutDistributionCard({
    required this.items, required this.getLabel,
    required this.getPlays, required this.baseColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s       = Theme.of(context).colorScheme;
    final t       = Theme.of(context).textTheme;
    final vals    = items.map(getPlays).toList();
    final total   = vals.fold<int>(0, (a, b) => a + b);
    final palette = _buildPalette(baseColor, items.length);

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130, height: 130,
          child: CustomPaint(
            painter: _DonutPainter(
              values:    vals.map((v) => v.toDouble()).toList(),
              colors:    palette,
              holeColor: s.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.asMap().entries.map((e) {
              final plays = getPlays(e.value);
              final pct   = total > 0 ? (plays / total * 100).round() : 0;
              final color = palette[e.key % palette.length];
              return GestureDetector(
                onTap: () => onTap(e.value),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(getLabel(e.value),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Text('$pct%',
                        style: t.bodySmall?.copyWith(
                            color: s.onSurfaceVariant, fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(_fmt(plays),
                        style: t.bodySmall?.copyWith(
                            color: color, fontWeight: FontWeight.w700, fontSize: 10)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color>  colors;
  final Color        holeColor;
  const _DonutPainter({required this.values, required this.colors, required this.holeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final r  = (size.shortestSide / 2) - 4;
    final inner = r * 0.52;
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;

    double sweep = -_kHalfPi;
    const gap = 0.02;
    for (var i = 0; i < values.length; i++) {
      final angle = (values[i] / total) * _kTwoPi - gap;
      if (angle <= 0) continue;
      final path = Path()
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), sweep, angle, false)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: inner),
            sweep + angle, -angle, false)
        ..close();
      canvas.drawPath(path, Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill ..isAntiAlias = true);
      sweep += angle + gap;
    }
    canvas.drawCircle(Offset(cx, cy), inner - 1, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values || old.colors != colors;
}

// ══════════════════════════════════════════════════════════════════════════
//  _CalendarCard  — scrollable heatmap
// ══════════════════════════════════════════════════════════════════════════

class _CalendarCard extends StatefulWidget {
  final Map<String, int> data;
  const _CalendarCard({required this.data});

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients) _sc.jumpTo(_sc.position.maxScrollExtent);
    });
  }

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s      = Theme.of(context).colorScheme;
    final t      = Theme.of(context).textTheme;
    final maxVal = widget.data.values.fold(0, (a, b) => a > b ? a : b);
    final now    = DateTime.now();

    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return DateTime(d.year, d.month, 1);
    }).reversed.toList();

    final yearStr    = '${now.year}';
    final yearTotal  = widget.data.entries
        .where((e) => e.key.startsWith(yearStr))
        .fold(0, (a, b) => a + b.value);
    final activeDays = widget.data.entries
        .where((e) => e.key.startsWith(yearStr) && e.value > 0)
        .length;
    String bestDay = ''; int bestCount = 0;
    for (final e in widget.data.entries) {
      if (e.value > bestCount) { bestCount = e.value; bestDay = e.key; }
    }

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 6, children: [
            _ChipStat(label: yearStr, value: _fmt(yearTotal), s: s, t: t),
            _ChipStat(
              label: _ct('Jours actifs', 'Active days'),
              value: '$activeDays', s: s, t: t,
            ),
            if (bestDay.isNotEmpty)
              _ChipStat(
                label: _ct('Record', 'Record'),
                value: '${bestDay.substring(5)} ($bestCount)',
                s: s, t: t,
              ),
          ]),
          const SizedBox(height: 14),
          SingleChildScrollView(
            controller: _sc,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: months.map((m) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _MonthHeatGrid(month: m, data: widget.data, maxVal: maxVal, s: s, t: t),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _scrollHint(context),
            const Spacer(),
            Text(_ct('Moins', 'Less'),
                style: t.labelSmall?.copyWith(fontSize: 9, color: s.onSurfaceVariant)),
            const SizedBox(width: 4),
            ...List.generate(5, (i) => Container(
              width: 11, height: 11,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: i == 0
                    ? s.surfaceContainerHigh
                    : s.primary.withValues(alpha: 0.15 + i * 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(width: 4),
            Text(_ct('Plus', 'More'),
                style: t.labelSmall?.copyWith(fontSize: 9, color: s.onSurfaceVariant)),
          ]),
        ],
      ),
    );
  }
}

class _MonthHeatGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, int> data;
  final int maxVal;
  final ColorScheme s;
  final TextTheme   t;
  const _MonthHeatGrid({
    required this.month, required this.data,
    required this.maxVal, required this.s, required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWd     = DateTime(month.year, month.month, 1).weekday;
    final label       = L.months[month.month];
    const cellSz      = 18.0;
    const gap         = 3.0;
    const cols        = 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${month.year}',
            style: t.labelSmall?.copyWith(
                color: s.onSurfaceVariant, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SizedBox(
          // 7 columns
          width: cols * (cellSz + gap) - gap,
          child: Wrap(
            spacing: gap, runSpacing: gap,
            children: [
              // offset empty cells
              ...List.generate(firstWd - 1,
                  (_) => SizedBox(width: cellSz, height: cellSz)),
              // day cells
              ...List.generate(daysInMonth, (d) {
                final day   = d + 1;
                final key   = '${month.year}-'
                    '${month.month.toString().padLeft(2, '0')}-'
                    '${day.toString().padLeft(2, '0')}';
                final count = data[key] ?? 0;
                final ratio = (maxVal > 0 && count > 0) ? count / maxVal : 0.0;
                final color = count == 0
                    ? s.surfaceContainerHigh
                    : s.primary.withValues(alpha: 0.18 + ratio.clamp(0, 1) * 0.80);
                return Tooltip(
                  message: count > 0 ? '$day — $count scrobbles' : '',
                  child: Container(
                    width: cellSz, height: cellSz,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(3)),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Small sub-widgets
// ══════════════════════════════════════════════════════════════════════════

class _ChipStat extends StatelessWidget {
  final String label, value;
  final ColorScheme s;
  final TextTheme   t;
  const _ChipStat({required this.label, required this.value,
      required this.s, required this.t});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: s.primaryContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: t.labelSmall
          ?.copyWith(color: s.onPrimaryContainer.withValues(alpha: 0.7))),
      const SizedBox(width: 4),
      Text(value, style: t.labelSmall?.copyWith(
          color: s.onPrimaryContainer, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _PeakChip extends StatelessWidget {
  final String label;
  final Color  color, onColor;
  final TextTheme t;
  const _PeakChip({required this.label, required this.color,
      required this.onColor, required this.t});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: t.labelSmall?.copyWith(color: onColor, fontWeight: FontWeight.w700)),
  );
}

class _BandLabel extends StatelessWidget {
  final String label; final Color color; final TextTheme t;
  const _BandLabel(this.label, this.color, this.t);
  @override
  Widget build(BuildContext context) =>
      Text(label, style: t.labelSmall?.copyWith(fontSize: 9, color: color));
}

List<Color> _buildPalette(Color base, int count) {
  if (count == 0) return [];
  final hsl = HSLColor.fromColor(base);
  return List.generate(count, (i) => HSLColor.fromAHSL(
    1.0,
    (hsl.hue + i * (360.0 / count)) % 360.0,
    hsl.saturation.clamp(0.45, 0.85),
    hsl.lightness.clamp(0.38, 0.62),
  ).toColor());
}

class _TagEntry {
  final String name; final int count;
  const _TagEntry({required this.name, required this.count});
}