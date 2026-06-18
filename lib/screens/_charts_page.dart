// ignore_for_file: unused_import
part of 'home_screen.dart';

String _ct(String fr, String en) => localeNotifier.value == 'en' ? en : fr;

List<String> get _chartWeekdayLabels => localeNotifier.value == 'en'
    ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    : ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

const _kTwoPi  = 6.283185307179586;
const _kHalfPi = 1.5707963267948966;

/// Exact number for bars (up to 999 999, then M).
String _fmtExact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  return n.toString();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Decode HTML entities from Last.fm API responses (named + numeric/hex refs).
/// Last.fm's recenttracks endpoint leaves apostrophes/accents HTML-encoded
/// (e.g. "&#039;" or "&#x27;"), which otherwise leak into the UI as raw markup.
String _sanitizeName(String s) {
  var out = s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');
  out = out.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
  out = out.replaceAllMapped(
      RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
  return out.trim();
}

/// Filter out MBIDs, [Unknown Album] tags, empty strings, and raw
/// map/object dumps that should never reach the UI as a label.
bool _isValidLabel(String s) {
  if (s.isEmpty) return false;
  if (s.startsWith('[') && s.endsWith(']')) return false;
  if (s.startsWith('{') && s.endsWith('}')) return false;
  if (s.startsWith('Instance of')) return false;
  if (RegExp(r'^[0-9a-f\-]{36}$', caseSensitive: false).hasMatch(s)) return false;
  return true;
}

// ── Page ─────────────────────────────────────────────────────────────────────

class _ChartsPage extends StatefulWidget {
  final LastFmService service;
  const _ChartsPage({required this.service});

  @override
  State<_ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<_ChartsPage>
    with AutomaticKeepAliveClientMixin {

  // ── Global data (all-time tops) ──────────────────────────────────────────
  List<dynamic> _topArtists = [];
  List<dynamic> _topAlbums  = [];
  bool   _loading = true;
  String? _error;

  // ── Data for the selected year ───────────────────────────────────────────
  Map<String, int>? _monthly;
  bool _hourlyLoading    = false;
  Map<int, int>?    _hourlyData;
  Map<int, int>?    _weekdayData;
  int  _hourlyCount      = 0;
  bool _calendarLoading  = false;
  Map<String, int>? _calendarData;
  bool _hasFullYearData  = false;

  // Year-specific top lists (computed from cached records)
  List<dynamic> _topArtistsYear = [];
  List<dynamic> _topAlbumsYear  = [];
  bool _yearDataLoading = false;

  // ── Genres (derived from all-time top artists) ────────────────────────────
  bool _tagsLoading = false;
  List<_TagEntry> _tags = [];

  // ── Year selection ────────────────────────────────────────────────────────
  // _selectedYear == 0 means "All time"
  int        _selectedYear   = DateTime.now().year;
  List<int>  _availableYears = [DateTime.now().year];

  bool get _isAllTime => _selectedYear == 0;

  // ── History loading progress ──────────────────────────────────────────────
  AllScrobblesProgress _historyProgress = AllScrobblesProgress.idle();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    AllScrobblesService.progressNotifier.addListener(_onHistoryProgress);
    _load();
  }

  @override
  void dispose() {
    AllScrobblesService.progressNotifier.removeListener(_onHistoryProgress);
    super.dispose();
  }

  void _onHistoryProgress() {
    if (!mounted) return;
    final p = AllScrobblesService.progressNotifier.value;
    setState(() => _historyProgress = p);
    _refreshAvailableYears();
    if (!_isAllTime && !_hasFullYearData && AllScrobblesService.isYearCached(_selectedYear)) {
      _hasFullYearData = true;
      _loadYearData(_selectedYear);
    }
    // If sync finished and year still not cached, stop the loader
    if (!AllScrobblesService.isRunning && _yearDataLoading) {
      setState(() => _yearDataLoading = false);
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        widget.service.getTopArtists(period: 'overall', limit: 10),
        widget.service.getTopAlbums(period: 'overall',  limit: 10),
      ]);
      if (!mounted) return;
      setState(() {
        _topArtists = res[0];
        _topAlbums  = res[1];
        _loading    = false;
      });
      _refreshAvailableYears();
      _loadTags();
      _hasFullYearData = AllScrobblesService.isYearCached(_selectedYear);
      await _loadYearData(_selectedYear);
      if (!AllScrobblesService.isRunning) {
        AllScrobblesService.loadAll(widget.service);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // Safe field access for records (Map or typed ScrobbleRecord).
  String _recField(dynamic r, String field) {
    dynamic raw;
    try { raw = (r as Map)[field]; } catch (_) {}
    if (raw == null) {
      try {
        if (field == 'artist') raw = r.artist;
        if (field == 'album')  raw = r.album;
      } catch (_) {}
    }
    if (raw is Map)    raw = raw['#text'] ?? raw['name'];
    if (raw is String) return raw;
    // Typed object (e.g. ScrobbleArtist): try .name then .toString()
    if (raw != null) {
      try { final n = raw.name; if (n is String && n.isNotEmpty) return n; } catch (_) {}
      final s = raw.toString();
      if (!s.startsWith('Instance of')) return s;
    }
    return '';
  }

  Future<void> _loadYearData(int year) async {
    // All time: aggregate all cached years for habits, use API tops
    if (year == 0) {
      _loadAllTimeHabits();
      setState(() {
        _yearDataLoading = false;
        _topArtistsYear  = [];
        _topAlbumsYear   = [];
        _calendarData    = null;
        _calendarLoading = false;
      });
      return;
    }

    var records = AllScrobblesService.getRecordsForYear(year);
    // If records not in memory but timestamps exist, try loading from service
    if (records == null && AllScrobblesService.isYearCached(year)) {
      await AllScrobblesService.loadAll(widget.service);
      if (!mounted) return;
      records = AllScrobblesService.getRecordsForYear(year);
    }
    if (records != null) {
      final recs = records!;
      if (!mounted) return;
      // Compute top artists and albums from records
      final artistCounts = <String, int>{};
      final albumCounts  = <String, int>{};
      try {
        for (final r in recs) {
          final a = _sanitizeName(_recField(r, 'artist'));
          final b = _sanitizeName(_recField(r, 'album'));
          if (_isValidLabel(a)) artistCounts[a] = (artistCounts[a] ?? 0) + 1;
          if (_isValidLabel(b)) albumCounts[b]  = (albumCounts[b]  ?? 0) + 1;
        }
      } catch (_) {}
      List<Map<String, dynamic>> rankTop(Map<String, int> counts) =>
          (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .take(10)
              .map((e) => <String, dynamic>{'name': e.key, 'playcount': '${e.value}'})
              .toList();
      setState(() {
        _monthly         = AllScrobblesService.computeMonthly(recs);
        _hourlyData      = AllScrobblesService.computeHourly(recs);
        _weekdayData     = AllScrobblesService.computeWeekday(recs);
        _hourlyCount     = recs.length;
        _calendarData    = AllScrobblesService.computeCalendar(recs);
        _hourlyLoading   = false;
        _calendarLoading = false;
        _yearDataLoading = false;
        _topArtistsYear  = artistCounts.isNotEmpty ? rankTop(artistCounts) : [];
        _topAlbumsYear   = albumCounts.isNotEmpty  ? rankTop(albumCounts)  : [];
      });
      return;
    }
    // Records not cached yet: reset tops but keep yearDataLoading if sync is running
    // so sections 5/6 keep showing a loader until _onHistoryProgress fires.
    setState(() {
      _topArtistsYear  = [];
      _topAlbumsYear   = [];
      _yearDataLoading = AllScrobblesService.isRunning;
    });
    await Future.wait([
      _loadMonthlyFallback(),
      _loadHourlyFallback(),
      _loadCalendarFallback(year),
    ]);
  }

  /// Aggregate hourly & weekday data across ALL cached years.
  Future<void> _loadAllTimeHabits() async {
    setState(() { _hourlyLoading = true; _hourlyData = null; _weekdayData = null; });
    final hours    = <int, int>{for (var i = 0; i < 24; i++) i: 0};
    final weekdays = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    int count = 0;
    for (final year in AllScrobblesService.getCachedYears()) {
      final records = AllScrobblesService.getRecordsForYear(year);
      if (records == null) continue;
      final h = AllScrobblesService.computeHourly(records);
      final w = AllScrobblesService.computeWeekday(records);
      h.forEach((k, v) => hours[k]    = (hours[k]    ?? 0) + v);
      w.forEach((k, v) => weekdays[k] = (weekdays[k] ?? 0) + v);
      count += records.length;
    }
    if (!mounted) return;
    // Fallback to recent scrobbles if nothing cached
    if (count == 0) { await _loadHourlyFallback(); return; }
    setState(() {
      _hourlyData    = hours;
      _weekdayData   = weekdays;
      _hourlyCount   = count;
      _hourlyLoading = false;
    });
  }

  Future<void> _loadMonthlyFallback() async {
    try {
      final data = await widget.service.getMonthlyScrobbles(months: 24);
      if (!mounted) return;
      final filtered = Map.fromEntries(
        data.entries.where((e) => e.key.startsWith('$_selectedYear')),
      );
      setState(() => _monthly = filtered.isNotEmpty ? filtered : data);
    } catch (_) {
      if (mounted) setState(() => _monthly = {});
    }
  }

  Future<void> _loadHourlyFallback() async {
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
      if (mounted) setState(() => _hourlyLoading = false);
    }
  }

  Future<void> _loadCalendarFallback(int year) async {
    if (year != DateTime.now().year) {
      if (mounted) setState(() => _calendarLoading = false);
      return;
    }
    if (_calendarLoading) return;
    setState(() { _calendarLoading = true; _calendarData = null; });
    try {
      final now  = DateTime.now();
      final data = <String, int>{};
      final futures = List.generate(12, (i) {
        final month = DateTime(now.year, now.month - (11 - i), 1);
        final nextM = DateTime(month.year, month.month + 1, 1);
        return widget.service.getRecentTracks(
          limit: 200, page: 1,
          from: month.millisecondsSinceEpoch ~/ 1000,
          to:   nextM.millisecondsSinceEpoch ~/ 1000,
        ).catchError((_) => <String, dynamic>{});
      });
      final pages = await Future.wait(futures);
      for (final pageData in pages) {
        final raw  = pageData['track'];
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
      if (mounted) setState(() => _calendarLoading = false);
    }
  }

  Future<void> _loadTags() async {
    if (_topArtists.isEmpty || _tagsLoading) return;
    setState(() { _tagsLoading = true; _tags = []; });
    try {
      final artists  = _topArtists.take(10).toList();
      final tagLists = await Future.wait(
        artists.map((a) => widget.service
            .getArtistTopTags((a['name'] ?? '').toString())
            .catchError((_) => <dynamic>[])),
      );
      final agg = <String, int>{};
      for (var i = 0; i < artists.length; i++) {
        final plays = int.tryParse((artists[i]['playcount'] ?? '1').toString()) ?? 1;
        for (final t in tagLists[i].take(5)) {
          final name = (t['name'] ?? '').toString().trim();
          if (name.isEmpty || name.length > 20) continue;
          agg[name] = (agg[name] ?? 0) + plays;
        }
      }
      final sorted = agg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (!mounted) return;
      setState(() {
        _tags        = sorted.take(8).map((e) => _TagEntry(name: e.key, count: e.value)).toList();
        _tagsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _tagsLoading = false);
    }
  }

  void _refreshAvailableYears() {
    if (!mounted) return;
    // Only include years that actually have records
    final cached = AllScrobblesService.getCachedYears()
        .where((y) {
          final recs = AllScrobblesService.getRecordsForYear(y);
          return recs != null && recs.isNotEmpty;
        })
        .toSet();
    cached.add(DateTime.now().year);
    final sorted = cached.toList()..sort();
    setState(() => _availableYears = sorted);
    _scrollToSelectedChip();
  }

  // ── Year chips ergonomics: keep the selected chip visible ──────────────────
  final Map<int, GlobalKey> _chipKeys = {};
  GlobalKey _chipKey(int year) => _chipKeys.putIfAbsent(year, () => GlobalKey());

  // ── Export: RepaintBoundary keys for each chart section ──────────────────
  // Add to home_screen.dart if missing:
  //   import 'dart:ui' as ui;
  //   import 'dart:io';
  //   import 'package:share_plus/share_plus.dart';
  //   import 'package:path_provider/path_provider.dart';
  static const _kCharts = [
    ('monthly',  'Barres mensuelles',   'Monthly bars',        Icons.calendar_month_rounded),
    ('cumul',    'Progression',         'Progression',         Icons.trending_up_rounded),
    ('genres',   'Genres musicaux',     'Musical genres',      Icons.equalizer_rounded),
    ('habits',   "Habitudes d'écoute",  'Listening habits',    Icons.access_time_rounded),
    ('artists',  'Top artistes',        'Artist distribution', Icons.mic_rounded),
    ('albums',   'Top albums',          'Album distribution',  Icons.album_rounded),
    ('calendar', 'Calendrier musical',  'Listening calendar',  Icons.grid_on_rounded),
    ('streaks',  "Séries d'écoute",     'Listening streaks',   Icons.local_fire_department_rounded),
  ];
  late final Map<String, GlobalKey> _xkeys = {
    for (final c in _kCharts) c.$1: GlobalKey(),
  };

  void _scrollToSelectedChip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chipKeys[_selectedYear]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: 0.5);
      }
    });
  }

  Map<String, int> _buildAllTimeMonthly() {
    final result = <String, int>{};
    for (final year in _availableYears) {
      final ts = AllScrobblesService.getRecordsForYear(year);
      if (ts != null) {
        AllScrobblesService.computeMonthly(ts)
            .forEach((k, v) => result[k] = (result[k] ?? 0) + v);
      }
    }
    if (result.isEmpty && _monthly != null) result.addAll(_monthly!);
    return result;
  }

  /// Cumulative scrobbles across [monthly], chronologically — works for a
  /// single year or for the merged all-time series.
  Map<String, int> _buildCumulative(Map<String, int> monthly) {
    final now    = DateTime.now();
    final cutoff = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final keys   = monthly.keys
        .where((k) => k.compareTo(cutoff) <= 0)
        .toList()..sort();
    int cum = 0;
    final result = <String, int>{};
    for (final k in keys) {
      cum += monthly[k]!;
      result[k] = cum;
    }
    return result;
  }

  /// Merge daily calendar data across every cached year into one continuous
  /// map, used by the "All time" heatmap.
  Map<String, int> _buildAllTimeCalendar() {
    final result = <String, int>{};
    for (final year in _availableYears) {
      final ts = AllScrobblesService.getRecordsForYear(year);
      if (ts != null) {
        AllScrobblesService.computeCalendar(ts)
            .forEach((k, v) => result[k] = (result[k] ?? 0) + v);
      }
    }
    if (result.isEmpty && _calendarData != null) result.addAll(_calendarData!);
    return result;
  }

  void _onYearChanged(int year) {
    if (year == _selectedYear) return;
    setState(() {
      _selectedYear      = year;
      _yearDataLoading   = true;
      _hasFullYearData   = year == 0
          ? AllScrobblesService.getCachedYears().isNotEmpty
          : AllScrobblesService.isYearCached(year);
      _hourlyData        = null;
      _weekdayData       = null;
      _calendarData      = null;
      _hourlyLoading     = true;
      _calendarLoading   = year != 0;
      _topArtistsYear    = [];
      _topAlbumsYear     = [];
    });
    _loadYearData(year);
    if (!AllScrobblesService.isRunning && !AllScrobblesService.isYearCached(year) && year != 0) {
      AllScrobblesService.loadAll(widget.service);
    }
    _scrollToSelectedChip();
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportFlow(BuildContext ctx) async {
    final scheme = Theme.of(ctx).colorScheme;
    final txt    = Theme.of(ctx).textTheme;

    // Step 1: choose chart
    final chartId = await showModalBottomSheet<String>(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sh) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(alignment: Alignment.centerLeft,
              child: Text(_ct('Quel graphique ?', 'Which chart?'),
                  style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ),
          ..._kCharts.map((c) => ListTile(
            leading: Icon(c.$4, color: scheme.primary),
            title: Text(_ct(c.$2, c.$3)),
            onTap: () => Navigator.pop(sh, c.$1),
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (chartId == null || !ctx.mounted) return;

    // Step 2: choose year
    final years = [0, ..._availableYears];
    final targetYear = await showModalBottomSheet<int>(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sh) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(alignment: Alignment.centerLeft,
              child: Text(_ct('Quelle période ?', 'Which period?'),
                  style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ),
          ...years.map((y) => ListTile(
            title: Text(y == 0 ? _ct('Tout le temps', 'All time') : '$y'),
            onTap: () => Navigator.pop(sh, y),
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (targetYear == null || !ctx.mounted) return;

    await _captureAndShare(ctx, chartId, targetYear);
  }

  Future<void> _captureAndShare(BuildContext ctx, String chartId, int year) async {
    final saved    = _selectedYear;
    final switched = year != saved;

    // Show loading overlay
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_ct('Export en cours…', 'Exporting…')),
              ]),
            ),
          ),
        ),
      ),
    );

    void closeDialog() {
      if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
    }

    try {
      if (switched) {
        // Silently load data for the target year (dialog covers the screen)
        if (mounted) setState(() {
          _selectedYear    = year;
          _yearDataLoading = true;
          _monthly         = null;
          _calendarData    = null;
          _topArtistsYear  = [];
          _topAlbumsYear   = [];
        });
        await _loadYearData(year);
        if (mounted) setState(() { _yearDataLoading = false; });

        // Wait one frame for widgets to rebuild with new data
        final ready = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) => ready.complete());
        await ready.future;
      }

      final rb = _xkeys[chartId]?.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (rb == null || rb.size.isEmpty) {
        closeDialog();
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(
              _ct('Graphique non disponible pour cette période',
                  'Chart not available for this period'))));
        }
        return;
      }

      final img   = await rb.toImage(pixelRatio: 3.0);
      final bd    = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = bd!.buffer.asUint8List();

      final tmp     = await getTemporaryDirectory();
      final yearStr = year == 0 ? 'alltime' : '$year';
      final file    = File('${tmp.path}/laststats_${chartId}_$yearStr.png');
      await file.writeAsBytes(bytes);

      closeDialog();
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      closeDialog();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('${_ct('Erreur', 'Error')}: $e')));
      }
    } finally {
      // Restore original year
      if (switched && mounted) {
        setState(() {
          _selectedYear    = saved;
          _yearDataLoading = true;
          _monthly         = null;
          _calendarData    = null;
          _topArtistsYear  = [];
          _topAlbumsYear   = [];
        });
        await _loadYearData(saved);
        if (mounted) setState(() { _yearDataLoading = false; });
      }
    }
  }

  // ── Year chips ────────────────────────────────────────────────────────────

  Widget _buildYearChips(ColorScheme s, TextTheme t) {
    // 0 = sentinel for "All time"
    final years = [0, ...(_availableYears.isNotEmpty ? _availableYears : [_selectedYear])];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: years.map((year) {
          final selected = year == _selectedYear;
          final label    = year == 0 ? _ct('Tout le temps', 'All time') : '$year';
          return Padding(
            key: _chipKey(year),
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onYearChanged(year),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? s.primary : s.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? s.primary : s.outlineVariant.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(
                          color: s.primary.withValues(alpha: 0.22),
                          blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  label,
                  style: t.labelMedium?.copyWith(
                    color: selected ? s.onPrimary : s.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── History loading banner ────────────────────────────────────────────────

  Widget _buildHistoryBanner(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = _historyProgress;

    if (p.isDone) return const SizedBox.shrink();

    if (p.isLoading) {
      final yearLabel = p.currentYear != null ? ' ${p.currentYear}' : '';
      final pct = (p.fraction * 100).round();
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: s.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: s.primary, width: 3),
            top:    BorderSide(color: s.primary.withValues(alpha: 0.15), width: 1),
            right:  BorderSide(color: s.primary.withValues(alpha: 0.15), width: 1),
            bottom: BorderSide(color: s.primary.withValues(alpha: 0.15), width: 1),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(
              width: 13, height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: s.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _ct('Chargement de l\'historique$yearLabel… $pct %',
                    'Loading history$yearLabel… $pct%'),
                style: t.bodySmall?.copyWith(
                    color: s.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p.fraction,
              minHeight: 5,
              backgroundColor: s.primary.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(s.primary),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _ct('Les graphiques seront plus précis une fois chargé.',
                'Charts will be more accurate once loaded.'),
            style: t.labelSmall?.copyWith(
                color: s.onPrimaryContainer.withValues(alpha: 0.60),
                fontSize: 10),
          ),
        ]),
      );
    }

    if (p.isIdle) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: s.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: s.outlineVariant.withValues(alpha: 0.45), width: 1),
        ),
        child: Row(children: [
          Icon(Icons.cloud_download_outlined, size: 16, color: s.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _ct('Chargez l\'historique complet pour accéder à toutes les années.',
                  'Load the full history to access all years.'),
              style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () => AllScrobblesService.loadAll(widget.service),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: t.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: Text(_ct('Charger', 'Load')),
          ),
        ]),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    if (_loading)       return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);

    final allTimeMonthly = _buildAllTimeMonthly();
    // Charts 1 & 2 show only the selected period: that year's months, or
    // every month from start to end when "All time" is selected.
    final periodMonthly    = _isAllTime ? allTimeMonthly : (_monthly ?? const <String, int>{});
    final periodCumulative = _buildCumulative(periodMonthly);
    final periodLabel      = _isAllTime ? _ct('Tout le temps', 'All time') : '$_selectedYear';

    final cachedTs    = _isAllTime ? null : AllScrobblesService.getTimestampsForYear(_selectedYear);
    final hasFullData = _isAllTime
        ? AllScrobblesService.getCachedYears().isNotEmpty
        : cachedTs != null;

    // Calendar + streaks: merged across all years for "All time", else the
    // currently-loaded year.
    final calendarForView = _isAllTime ? _buildAllTimeCalendar() : _calendarData;
    final heatmapYears = _isAllTime
        ? (_availableYears.isNotEmpty ? _availableYears : [DateTime.now().year])
        : [_selectedYear];
    final heatmapStart = DateTime(heatmapYears.first, 1, 1);
    final heatmapEnd   = heatmapYears.last == DateTime.now().year
        ? DateTime.now()
        : DateTime(heatmapYears.last, 12, 31);

    final habitsSubtitle = _isAllTime
        ? (_hourlyCount > 0
            ? _ct('Basé sur $_hourlyCount scrobbles (toutes les années)',
                  'Based on $_hourlyCount scrobbles (all years)')
            : _ct('Toutes les années disponibles', 'All available years'))
        : hasFullData
            ? _ct('Basé sur $_hourlyCount scrobbles de $_selectedYear',
                  'Based on $_hourlyCount scrobbles from $_selectedYear')
            : _hourlyCount > 0
                ? _ct('Basé sur $_hourlyCount scrobbles récents',
                      'Based on $_hourlyCount recent scrobbles')
                : _ct('Analyse vos ~200 derniers scrobbles',
                      'Analysing your last ~200 scrobbles');

    // Top items: year-specific when cached, fallback to all-time API tops
    // with a note when year records aren't available in memory.
    final yearHasRecords = _availableYears.contains(_selectedYear);
    final artistItems = _isAllTime
        ? _topArtists
        : (_topArtistsYear.isNotEmpty ? _topArtistsYear
           : (yearHasRecords ? _topArtists : <dynamic>[]));
    final albumItems = _isAllTime
        ? _topAlbums
        : (_topAlbumsYear.isNotEmpty ? _topAlbumsYear
           : (yearHasRecords ? _topAlbums : <dynamic>[]));
    final usingFallback = !_isAllTime && _topArtistsYear.isEmpty && yearHasRecords && _topArtists.isNotEmpty;
    final topLabel    = usingFallback ? _ct('All-time (données $_selectedYear en cours)', 'All-time ($_selectedYear loading)') : (_isAllTime ? _ct('All-time', 'All-time') : '$_selectedYear');
    final albumLabel  = topLabel;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Fixed header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
            child: Row(children: [
              Expanded(
                child: Text(L.chartsTitle,
                    style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ),
              IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: _ct('Exporter un graphique', 'Export a chart'),
                onPressed: () => _exportFlow(context),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _buildYearChips(scheme, text),
          ),
          const SizedBox(height: 16),

          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: AnimatedOpacity(
              opacity: _yearDataLoading ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                children: [

                  _buildHistoryBanner(context),

                  // 1. Monthly bars — scoped to the selected period
                  _SectionHeader(title: L.chartsMonthly, icon: Icons.calendar_month_rounded),
                  const SizedBox(height: 4),
                  Text(periodLabel,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    key: _xkeys['monthly'],
                    child: periodMonthly.isNotEmpty
                        ? _MonthlyCard(monthly: periodMonthly)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 28),

                  // 2. Cumulative line — scoped to the selected period
                  if (periodCumulative.length >= 2) ...[
                    _SectionHeader(
                      title: _ct('Progression des scrobbles', 'Scrobble progression'),
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 4),
                    Text(periodLabel,
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    RepaintBoundary(
                      key: _xkeys['cumul'],
                      child: _CumulativeLineCard(data: periodCumulative),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // 3. Musical genres (all-time)
                  _SectionHeader(
                    title: _ct('Vos genres musicaux', 'Your musical genres'),
                    icon: Icons.equalizer_rounded,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ct('Basé sur vos top artistes (all-time)',
                        'Based on your top artists (all-time)'),
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  if (_tagsLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_tags.isNotEmpty)
                    RepaintBoundary(key: _xkeys['genres'], child: _TagsCard(tags: _tags)),
                  const SizedBox(height: 28),

                  // 4. Listening habits
                  _SectionHeader(
                    title: _ct("Habitudes d'écoute", 'Listening habits'),
                    icon: Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 4),
                  Text(habitsSubtitle,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  if (_hourlyLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_hourlyData != null) ...[
                    RepaintBoundary(
                      key: _xkeys['habits'],
                      child: Column(children: [
                        _HourlyBarCard(data: _hourlyData!),
                        const SizedBox(height: 12),
                        _WeekdayBarCard(data: _weekdayData!),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // 5. Artist distribution — always shown, loader inside while year loads
                  _SectionHeader(title: L.chartsArtistDist, icon: Icons.mic_rounded),
                  const SizedBox(height: 4),
                  Text(topLabel,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  if (_yearDataLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ))
                  else if (artistItems.isNotEmpty)
                    RepaintBoundary(
                      key: _xkeys['artists'],
                      child: _SwipeDistributionCard(
                        items:       artistItems,
                        getLabel:    (e) => _sanitizeName((e['name'] ?? '').toString()),
                        getPlays:    (e) => int.tryParse((e['playcount'] ?? '0').toString()) ?? 0,
                        baseColor:   scheme.primary,
                        secondColor: scheme.tertiary,
                        onTap: (e) => showDetailSheet(context,
                            Map<String, dynamic>.from(e as Map), 'artists', widget.service),
                      ),
                    )
                  else
                    _EmptyYearCard(),
                  const SizedBox(height: 28),

                  // 6. Album distribution — always shown, loader inside while year loads
                  _SectionHeader(
                    title: _ct('Répartition par album', 'Album distribution'),
                    icon: Icons.album_rounded,
                  ),
                  const SizedBox(height: 4),
                  Text(albumLabel,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  if (_yearDataLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ))
                  else if (albumItems.isNotEmpty)
                    RepaintBoundary(
                      key: _xkeys['albums'],
                      child: _SwipeDistributionCard(
                        items:       albumItems,
                        getLabel:    (e) => _sanitizeName((e['name'] ?? '').toString()),
                        getPlays:    (e) => int.tryParse((e['playcount'] ?? '0').toString()) ?? 0,
                        baseColor:   scheme.secondary,
                        secondColor: scheme.primary,
                        onTap: (e) => showDetailSheet(context,
                            Map<String, dynamic>.from(e as Map), 'albums', widget.service),
                      ),
                    )
                  else
                    _EmptyYearCard(),
                  const SizedBox(height: 28),

                  // 7. Listening calendar — single year, or every year glued
                  // together (separated by a marker) for "All time"
                  _SectionHeader(
                    title: _ct('Calendrier musical', 'Listening calendar'),
                    icon: Icons.grid_on_rounded,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAllTime
                        ? (heatmapYears.length > 1
                            ? _ct(
                                'Activité journalière — ${heatmapYears.first} à ${heatmapYears.last}',
                                'Daily activity — ${heatmapYears.first} to ${heatmapYears.last}')
                            : _ct('Activité journalière — toutes les années',
                                  'Daily activity — all years'))
                        : hasFullData
                            ? _ct('Activité journalière — $_selectedYear',
                                  'Daily activity — $_selectedYear')
                            : _selectedYear != DateTime.now().year
                                ? _ct('Chargez l\'historique pour voir $_selectedYear',
                                      'Load history to see $_selectedYear')
                                : _ct('Activité journalière — 12 mois',
                                      'Daily activity — last 12 months'),
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  if (_isAllTime)
                    (calendarForView != null && calendarForView.isNotEmpty)
                        ? RepaintBoundary(
                            key: _xkeys['calendar'],
                            child: _HeatmapCard(
                                data: calendarForView, start: heatmapStart, end: heatmapEnd))
                        : _NoDataCard(
                            year: 0,
                            label: _ct('toutes les années', 'all years'),
                            onLoad: () => AllScrobblesService.loadAll(widget.service),
                          )
                  else if (_calendarLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ))
                  else if (calendarForView != null)
                    RepaintBoundary(
                      key: _xkeys['calendar'],
                      child: _HeatmapCard(
                          data: calendarForView, start: heatmapStart, end: heatmapEnd))
                  else if (!hasFullData && _selectedYear != DateTime.now().year)
                    _NoDataCard(year: _selectedYear, onLoad: () => AllScrobblesService.loadAll(widget.service)),
                  const SizedBox(height: 28),

                  // 8. Listening streaks
                  if (calendarForView != null && calendarForView.isNotEmpty) ...[
                    _SectionHeader(
                      title: _ct('Séries d\'écoute', 'Listening streaks'),
                      icon: Icons.local_fire_department_rounded,
                    ),
                    const SizedBox(height: 12),
                    RepaintBoundary(key: _xkeys['streaks'], child: _StreakCard(data: calendarForView)),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

// ══════════════════════════════════════════════════════════════════════════
//  Shared helpers
// ══════════════════════════════════════════════════════════════════════════

/// Shared card decoration: M3 surface, subtle border.
BoxDecoration _chartCardDecoration(ColorScheme s) => BoxDecoration(
  color: s.surfaceContainer,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: s.outlineVariant.withValues(alpha: 0.40), width: 1),
);

/// Gradient bar fill: lighter at base, full color at top.
LinearGradient _barGradient(Color color, {bool vertical = true}) => LinearGradient(
  begin: vertical ? Alignment.bottomCenter : Alignment.centerLeft,
  end:   vertical ? Alignment.topCenter    : Alignment.centerRight,
  colors: [color.withValues(alpha: 0.55), color],
  stops: const [0.0, 1.0],
);

/// M3 palette: interpolates between [base] and [second] via HSL.
List<Color> _buildPalette(Color base, Color second, int count) {
  if (count == 0) return [];
  if (count == 1) return [base];

  final hslA = HSLColor.fromColor(base);
  final hslB = HSLColor.fromColor(second);
  final avgSat = (hslA.saturation + hslB.saturation) / 2;

  if (avgSat < 0.08) {
    return List.generate(count, (i) {
      final t     = count > 1 ? i / (count - 1) : 0.0;
      final light = (0.30 + t * 0.35).clamp(0.25, 0.75);
      return HSLColor.fromAHSL(1.0, hslA.hue, hslA.saturation, light).toColor();
    });
  }

  return List.generate(count, (i) {
    final t       = i / (count - 1);
    final hueDiff = (hslB.hue - hslA.hue + 540) % 360 - 180;
    return HSLColor.fromAHSL(
      1.0,
      (hslA.hue + hueDiff * t + 360) % 360,
      (hslA.saturation + (hslB.saturation - hslA.saturation) * t).clamp(0.40, 0.90),
      (hslA.lightness  + (hslB.lightness  - hslA.lightness)  * t).clamp(0.35, 0.65),
    ).toColor();
  });
}

// ══════════════════════════════════════════════════════════════════════════
//  _MonthlyCard — scrollable monthly bar chart
// ══════════════════════════════════════════════════════════════════════════

class _MonthlyCard extends StatefulWidget {
  final Map<String, int> monthly;
  const _MonthlyCard({required this.monthly});

  @override
  State<_MonthlyCard> createState() => _MonthlyCardState();
}

class _MonthlyCardState extends State<_MonthlyCard> {
  final _sc = ScrollController();
  static const _colW    = 48.0;
  static const _barMaxH = 110.0;

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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, children: [
            _ChipStat(label: _ct('Total', 'Total'), value: _fmt(total), s: s, t: t),
            _ChipStat(label: _ct('Moy./mois', 'Avg/mo'), value: _fmt(avg), s: s, t: t),
          ]),
          const SizedBox(height: 18),

          // Fixed Y-axis + scrollable bars
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            SizedBox(
              width: 34,
              height: _barMaxH + 16,
              child: Stack(children: [
                Positioned(top: 0, right: 4,
                    child: Text(_fmt(maxVal),
                        style: t.labelSmall?.copyWith(
                            fontSize: 8, color: s.onSurfaceVariant))),
                Positioned(top: _barMaxH * 0.5 - 5, right: 4,
                    child: Text(_fmt(maxVal ~/ 2),
                        style: t.labelSmall?.copyWith(
                            fontSize: 8, color: s.onSurfaceVariant.withValues(alpha: 0.5)))),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: () {
                    final widgets = <Widget>[];
                    String? prevYear;
                    for (final e in sorted) {
                      final year  = e.key.substring(0, 4);
                      final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                      final barH  = (_barMaxH * ratio).clamp(2.0, _barMaxH);
                      final isMax = e.value == maxVal;
                      final color = isMax ? s.primary
                          : Color.lerp(s.primaryContainer, s.primary, ratio * 0.75)!;

                      // Year separator line
                      if (prevYear != null && year != prevYear) {
                        widgets.add(SizedBox(
                          width: 26,
                          height: _barMaxH + 16,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(year,
                                  style: t.labelSmall?.copyWith(
                                      fontSize: 8, color: s.primary,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: _barMaxH,
                                child: VerticalDivider(
                                  width: 1, thickness: 1,
                                  color: s.primary.withValues(alpha: 0.35),
                                ),
                              ),
                            ],
                          ),
                        ));
                      }
                      prevYear = year;

                      widgets.add(SizedBox(
                        width: _colW,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              ratio > 0.12 ? _fmtExact(e.value) : '',
                              textAlign: TextAlign.center,
                              style: t.labelSmall?.copyWith(
                                fontSize: 8,
                                color: isMax ? s.primary : s.onSurfaceVariant,
                                fontWeight: isMax ? FontWeight.w800 : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: _colW - 10,
                                height: barH,
                                decoration: BoxDecoration(
                                  gradient: _barGradient(color),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              L.months[int.tryParse(e.key.substring(5)) ?? 1],
                              textAlign: TextAlign.center,
                              style: t.labelSmall?.copyWith(
                                fontSize: 9,
                                color: isMax ? s.primary : s.onSurfaceVariant,
                                fontWeight: isMax ? FontWeight.w700 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ));
                    }
                    return widgets;
                  }(),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _CumulativeLineCard — cumulative line chart with fixed Y-axis
// ══════════════════════════════════════════════════════════════════════════

class _CumulativeLineCard extends StatefulWidget {
  final Map<String, int> data;
  const _CumulativeLineCard({required this.data});

  @override
  State<_CumulativeLineCard> createState() => _CumulativeLineCardState();
}

class _CumulativeLineCardState extends State<_CumulativeLineCard> {
  final _sc = ScrollController();
  static const _ptW    = 42.0;
  static const _chartH = 140.0;

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
    final maxVal = vals.isEmpty ? 0.0 : vals.last;
    final total  = vals.isEmpty ? 0 : vals.last.toInt();

    String bestMonth = ''; int bestDelta = 0;
    for (var i = 1; i < keys.length; i++) {
      final delta = widget.data[keys[i]]! - widget.data[keys[i - 1]]!;
      if (delta > bestDelta) { bestDelta = delta; bestMonth = keys[i]; }
    }

    final contentW = (_ptW * keys.length).clamp(1.0, double.infinity);
    final yLevels  = [1.0, 0.75, 0.50, 0.25];

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
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
          const SizedBox(height: 18),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Fixed Y-axis
            SizedBox(
              width: 38,
              height: _chartH,
              child: Stack(
                children: yLevels.map((ratio) {
                  final topFrac = 1.0 - ratio * 0.88;
                  return Positioned(
                    top: _chartH * topFrac - 7,
                    right: 4,
                    child: Text(
                      _fmt((maxVal * ratio).round()),
                      style: t.labelSmall?.copyWith(
                        fontSize: 8,
                        color: ratio == 1.0
                            ? s.primary
                            : s.onSurfaceVariant.withValues(alpha: 0.55),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Scrollable chart
            Expanded(
              child: SingleChildScrollView(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: contentW,
                      height: _chartH,
                      child: CustomPaint(
                        painter: _LinePainter(
                          keys:          keys,
                          values:        vals,
                          color:         s.primary,
                          gridColor:     s.outlineVariant.withValues(alpha: 0.30),
                          dotInnerColor: s.surface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
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
                                    L.months[int.tryParse(e.value.substring(5)) ?? 1],
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
            ),
          ]),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<String> keys;
  final List<double> values;
  final Color        color;
  final Color        gridColor;
  final Color        dotInnerColor;
  const _LinePainter({
    required this.keys,
    required this.values,
    required this.color,
    required this.gridColor,
    required this.dotInnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 2) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final w = size.width;
    final h = size.height;

    // Horizontal grid lines
    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.8;
    for (final ratio in [1.0, 0.75, 0.50, 0.25]) {
      final y = h - ratio * h * 0.88;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final pts = List.generate(n, (i) => Offset(
      i * w / (n - 1),
      h - (values[i] / maxVal) * h * 0.88,
    ));

    // Gradient fill under curve
    final fill = Path()
      ..moveTo(pts[0].dx, h)
      ..lineTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      fill.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    fill..lineTo(pts.last.dx, h)..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Line
    final line = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      line.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(line, Paint()
      ..color = color ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round);

    // Year separators
    for (var i = 1; i < n; i++) {
      if (keys[i].substring(0, 4) != keys[i - 1].substring(0, 4)) {
        final x = i * w / (n - 1);
        canvas.drawLine(
          Offset(x, 0), Offset(x, h),
          Paint()..color = color.withValues(alpha: 0.40)..strokeWidth = 1.2,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: keys[i].substring(0, 4),
            style: TextStyle(
              color: color, fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 3, 2));
      }
    }

    // Terminal dot
    canvas.drawCircle(pts.last, 7, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawCircle(pts.last, 4, Paint()..color = color);
    canvas.drawCircle(pts.last, 2, Paint()..color = dotInnerColor);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.color != color || old.dotInnerColor != dotInnerColor;
}

// ══════════════════════════════════════════════════════════════════════════
//  _TagsCard — genre list with gradient bars
// ══════════════════════════════════════════════════════════════════════════

class _TagsCard extends StatelessWidget {
  final List<_TagEntry> tags;
  const _TagsCard({required this.tags});

  @override
  Widget build(BuildContext context) {
    final s       = Theme.of(context).colorScheme;
    final t       = Theme.of(context).textTheme;
    final palette = _buildPalette(s.primary, s.tertiary, tags.length);
    final maxVal  = tags.isEmpty ? 1
        : tags.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: tags.asMap().entries.map((e) {
          final ratio = maxVal > 0 ? e.value.count / maxVal : 0.0;
          final color = palette[e.key % palette.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(e.value.name,
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${(ratio * 100).round()}%',
                    style: t.bodySmall?.copyWith(
                        color: s.onSurfaceVariant, fontSize: 10)),
              ]),
              const SizedBox(height: 7),
              LayoutBuilder(builder: (_, box) {
                final barW = box.maxWidth * ratio;
                return Stack(children: [
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: s.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    width: barW.clamp(7.0, box.maxWidth),
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: _barGradient(color, vertical: false),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ]);
              }),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _HourlyBarCard — hourly distribution
// ══════════════════════════════════════════════════════════════════════════

class _HourlyBarCard extends StatefulWidget {
  final Map<int, int> data;
  const _HourlyBarCard({required this.data});

  @override
  State<_HourlyBarCard> createState() => _HourlyBarCardState();
}

class _HourlyBarCardState extends State<_HourlyBarCard> {
  final _sc = ScrollController();
  static const _colW        = 33.0;
  static const _barMaxH     = 96.0;
  static const _kBandLabelH = 20.0;

  static const _bands = [
    (start: 0,  end: 5,  emoji: '🌙', fr: 'Nuit',       en: 'Night'),
    (start: 6,  end: 11, emoji: '☀️', fr: 'Matin',       en: 'Morning'),
    (start: 12, end: 17, emoji: '🌤', fr: 'Après-midi',  en: 'Afternoon'),
    (start: 18, end: 23, emoji: '🌆', fr: 'Soir',        en: 'Evening'),
  ];

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
    if (h <= 5)  return '🌙';
    if (h <= 11) return '☀️';
    if (h <= 17) return '🌤';
    return '🌆';
  }

  @override
  Widget build(BuildContext context) {
    final s      = Theme.of(context).colorScheme;
    final t      = Theme.of(context).textTheme;
    final maxVal = widget.data.values.fold(0, (a, b) => a > b ? a : b);
    final peakH  = widget.data.isEmpty ? 0
        : widget.data.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final isEn   = localeNotifier.value == 'en';

    final bandColors = [
      s.primaryContainer.withValues(alpha: 0.07),
      s.tertiaryContainer.withValues(alpha: 0.09),
      s.secondaryContainer.withValues(alpha: 0.09),
      s.primaryContainer.withValues(alpha: 0.07),
    ];

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 30,
              height: _kBandLabelH + _barMaxH + 26,
              child: Stack(children: [
                Positioned(top: _kBandLabelH, right: 4,
                    child: Text(_fmt(maxVal),
                        style: t.labelSmall?.copyWith(
                            fontSize: 8, color: s.onSurfaceVariant))),
                Positioned(top: _kBandLabelH + _barMaxH * 0.5 - 5, right: 4,
                    child: Text(_fmt(maxVal ~/ 2),
                        style: t.labelSmall?.copyWith(
                            fontSize: 8,
                            color: s.onSurfaceVariant.withValues(alpha: 0.50)))),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: 24 * _colW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Band labels row
                      Row(
                        children: _bands.map((b) {
                          final bandW = (b.end - b.start + 1) * _colW;
                          final label = isEn ? b.en : b.fr;
                          return Container(
                            width: bandW,
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('${b.emoji} $label',
                                textAlign: TextAlign.center,
                                style: t.labelSmall?.copyWith(
                                    fontSize: 9,
                                    color: s.onSurfaceVariant.withValues(alpha: 0.65))),
                          );
                        }).toList(),
                      ),
                      // Bars over band backgrounds
                      Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          // Band backgrounds
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _bands.asMap().entries.map((e) {
                              final b = e.value;
                              final bandW = (b.end - b.start + 1) * _colW;
                              return Container(
                                width: bandW,
                                height: _barMaxH + 22,
                                decoration: BoxDecoration(
                                  color: bandColors[e.key],
                                  border: Border(
                                    left: BorderSide(
                                      color: s.outlineVariant.withValues(alpha: 0.20),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // Bars
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(24, (h) {
                              final v      = widget.data[h] ?? 0;
                              final ratio  = maxVal > 0 ? v / maxVal : 0.0;
                              final barH   = (_barMaxH * ratio).clamp(2.0, _barMaxH);
                              final isPeak = h == peakH;
                              final color  = isPeak
                                  ? s.primary
                                  : Color.lerp(s.primaryContainer, s.primary, ratio * 0.8)!;
                              return SizedBox(
                                width: _colW,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      (isPeak || ratio > 0.20) && v > 0 ? _fmt(v) : '',
                                      style: t.labelSmall?.copyWith(
                                          fontSize: 8,
                                          color: isPeak ? s.primary : s.onSurfaceVariant,
                                          fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Center(
                                      child: Container(
                                        width: _colW - 8,
                                        height: barH,
                                        decoration: BoxDecoration(
                                          gradient: _barGradient(color),
                                          borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(5)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      (h % 6 == 0 || isPeak) ? '${h}h' : '',
                                      style: t.labelSmall?.copyWith(
                                        fontSize: 8,
                                        color: isPeak ? s.primary
                                            : s.onSurfaceVariant.withValues(alpha: 0.65),
                                        fontWeight: isPeak ? FontWeight.w800 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _WeekdayBarCard — 7 full-width bars
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
          const SizedBox(height: 16),
          LayoutBuilder(builder: (_, constraints) {
            const barMaxH = 96.0;
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
                    : Color.lerp(s.secondaryContainer, s.secondary, ratio * 0.8)!;
                return SizedBox(
                  width: colW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(v > 0 ? _fmt(v) : '',
                          style: t.labelSmall?.copyWith(
                            fontSize: 8,
                            color: isPeak ? s.secondary : s.onSurfaceVariant,
                            fontWeight: isPeak ? FontWeight.w800 : FontWeight.normal,
                          )),
                      const SizedBox(height: 3),
                      Center(
                        child: Container(
                          width: colW - 10,
                          height: barH,
                          decoration: BoxDecoration(
                            gradient: _barGradient(color),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(labels[i], textAlign: TextAlign.center,
                          style: t.labelSmall?.copyWith(
                            fontSize: 10,
                            color: isPeak ? s.secondary : s.onSurfaceVariant,
                            fontWeight: isPeak ? FontWeight.w700 : FontWeight.normal,
                          )),
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
  final Color                    secondColor;
  final void   Function(dynamic) onTap;
  const _DonutDistributionCard({
    required this.items,
    required this.getLabel,
    required this.getPlays,
    required this.baseColor,
    required this.secondColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s       = Theme.of(context).colorScheme;
    final t       = Theme.of(context).textTheme;
    final vals    = items.map(getPlays).toList();
    final total   = vals.fold<int>(0, (a, b) => a + b);
    final palette = _buildPalette(baseColor, secondColor, items.length);

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130, height: 130,
          child: CustomPaint(
            painter: _DonutPainter(
              values:    vals.map((v) => v.toDouble()).toList(),
              colors:    palette,
              holeColor: s.surfaceContainer,
            ),
          ),
        ),
        const SizedBox(width: 16),
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
                  padding: const EdgeInsets.only(bottom: 7),
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
    const gap = 0.022;
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
//  _StreakCard — current & best listening streaks from calendar data
// ══════════════════════════════════════════════════════════════════════════

({int current, int best, String bestStart}) _computeStreaks(Map<String, int> data) {
  final today = DateTime.now();

  // Current streak: consecutive days going back from today
  int current = 0;
  for (var i = 0; i < 365; i++) {
    final d   = today.subtract(Duration(days: i));
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}'
                '-${d.day.toString().padLeft(2, '0')}';
    if ((data[key] ?? 0) > 0) { current++; } else { break; }
  }

  // Best streak: longest consecutive run in full dataset
  final active = data.keys.where((k) => (data[k] ?? 0) > 0).toList()..sort();
  int best = 0, run = 0;
  String bestStart = '', runStart = '';
  DateTime? prev;
  for (final k in active) {
    final d = DateTime.parse(k);
    if (prev != null && d.difference(prev).inDays == 1) {
      run++;
    } else {
      run = 1;
      runStart = k;
    }
    if (run > best) { best = run; bestStart = runStart; }
    prev = d;
  }
  return (current: current, best: best, bestStart: bestStart);
}

class _StreakCard extends StatelessWidget {
  final Map<String, int> data;
  const _StreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final s     = Theme.of(context).colorScheme;
    final t     = Theme.of(context).textTheme;
    final str   = _computeStreaks(data);
    final ratio = str.best > 0 ? (str.current / str.best).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: _StreakTile(
                icon: '🔥',
                label: _ct('Série actuelle', 'Current streak'),
                value: '${str.current}',
                unit: _ct('j', 'd'),
                color: s.primary,
                s: s, t: t,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StreakTile(
                icon: '🏆',
                label: _ct('Meilleure série', 'Best streak'),
                value: '${str.best}',
                unit: _ct('j', 'd'),
                color: s.tertiary,
                s: s, t: t,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Current vs best progress bar
          Row(children: [
            Text('0',
                style: t.labelSmall?.copyWith(
                    fontSize: 9, color: s.onSurfaceVariant.withValues(alpha: 0.5))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Stack(children: [
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: s.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: _barGradient(s.primary, vertical: false),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Text('${str.best}${_ct('j', 'd')}',
                style: t.labelSmall?.copyWith(
                    fontSize: 9, color: s.onSurfaceVariant.withValues(alpha: 0.5))),
          ]),
          if (str.bestStart.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _ct('Meilleure série depuis le ${str.bestStart}',
                  'Best streak started on ${str.bestStart}'),
              style: t.labelSmall?.copyWith(
                  fontSize: 9, color: s.onSurfaceVariant.withValues(alpha: 0.55)),
            ),
          ],
        ],
      ),
    );
  }
}

class _StreakTile extends StatelessWidget {
  final String icon, label, value, unit;
  final Color  color;
  final ColorScheme s;
  final TextTheme   t;
  const _StreakTile({
    required this.icon, required this.label, required this.value,
    required this.unit, required this.color, required this.s, required this.t,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.14),
          color.withValues(alpha: 0.06),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.20), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: t.displaySmall?.copyWith(
                    color: color, fontWeight: FontWeight.w800, height: 1,
                    fontSize: 32)),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(unit,
                  style: t.titleSmall?.copyWith(
                      color: color.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(label,
            style: t.labelSmall?.copyWith(
                color: s.onSurfaceVariant, fontSize: 10)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  _TopHorizontalBarCard — ranked horizontal bars
// ══════════════════════════════════════════════════════════════════════════

class _TopHorizontalBarCard extends StatelessWidget {
  final List<dynamic>            items;
  final String Function(dynamic) getLabel;
  final int    Function(dynamic) getPlays;
  final Color                    barColor;
  final void   Function(dynamic) onTap;
  const _TopHorizontalBarCard({
    required this.items,
    required this.getLabel,
    required this.getPlays,
    required this.barColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s      = Theme.of(context).colorScheme;
    final t      = Theme.of(context).textTheme;
    final vals   = items.map(getPlays).toList();
    final maxVal = vals.isEmpty ? 1 : vals.reduce((a, b) => a > b ? a : b);
    final total  = vals.fold<int>(0, (a, b) => a + b);

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: items.asMap().entries.map((e) {
          final plays = getPlays(e.value);
          final ratio = maxVal > 0 ? plays / maxVal : 0.0;
          final rank  = e.key + 1;
          final color = rank <= 3
              ? barColor
              : Color.lerp(s.surfaceContainerHigh, barColor, 0.6)!;

          return GestureDetector(
            onTap: () => onTap(e.value),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$rank',
                      style: t.labelSmall?.copyWith(
                        color: rank <= 3
                            ? barColor
                            : s.onSurfaceVariant.withValues(alpha: 0.45),
                        fontWeight: rank <= 3 ? FontWeight.w800 : FontWeight.w500,
                        fontSize: rank == 1 ? 13 : 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(
                              getLabel(e.value),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                fontWeight: rank <= 3 ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(_fmt(plays),
                              style: t.labelSmall?.copyWith(
                                color: rank <= 3 ? barColor : s.onSurfaceVariant,
                                fontWeight: FontWeight.w700, fontSize: 10)),
                          if (total > 0) ...[
                            const SizedBox(width: 4),
                            Text('${(plays / total * 100).round()}%',
                                style: t.labelSmall?.copyWith(
                                    color: s.onSurfaceVariant.withValues(alpha: 0.50),
                                    fontSize: 9)),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Stack(children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: s.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: _barGradient(color, vertical: false),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _SwipeDistributionCard — donut ↔ horizontal bars, swipe to switch
// ══════════════════════════════════════════════════════════════════════════

class _SwipeDistributionCard extends StatefulWidget {
  final List<dynamic>            items;
  final String Function(dynamic) getLabel;
  final int    Function(dynamic) getPlays;
  final Color                    baseColor;
  final Color                    secondColor;
  final void   Function(dynamic) onTap;
  const _SwipeDistributionCard({
    required this.items,
    required this.getLabel,
    required this.getPlays,
    required this.baseColor,
    required this.secondColor,
    required this.onTap,
  });

  @override
  State<_SwipeDistributionCard> createState() => _SwipeDistributionCardState();
}

class _SwipeDistributionCardState extends State<_SwipeDistributionCard> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // Each legend row ≈ 26px tall + container padding 36
  double _donutHeight() {
    final legendH = widget.items.length * 26.0;
    return (legendH > 130 ? legendH : 130) + 40;
  }

  // Each bar row ≈ 38px (label + gap + bar + bottom padding) + container padding 36
  double _barsHeight() => widget.items.length * 38.0 + 48;

  @override
  Widget build(BuildContext context) {
    final s      = Theme.of(context).colorScheme;
    final height = _page == 0 ? _donutHeight() : _barsHeight();

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          child: SizedBox(
            height: height,
            child: PageView(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _DonutDistributionCard(
                  items:       widget.items,
                  getLabel:    widget.getLabel,
                  getPlays:    widget.getPlays,
                  baseColor:   widget.baseColor,
                  secondColor: widget.secondColor,
                  onTap:       widget.onTap,
                ),
                _TopHorizontalBarCard(
                  items:    widget.items,
                  getLabel: widget.getLabel,
                  getPlays: widget.getPlays,
                  barColor: widget.baseColor,
                  onTap:    widget.onTap,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width:  _page == i ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: _page == i
                  ? widget.baseColor
                  : s.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _EmptyYearCard — no data, no button
// ══════════════════════════════════════════════════════════════════════════

class _EmptyYearCard extends StatelessWidget {
  const _EmptyYearCard();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(children: [
        Icon(Icons.bar_chart_outlined, color: s.onSurfaceVariant.withValues(alpha: 0.45), size: 20),
        const SizedBox(width: 12),
        Text(
          _ct('Aucune donnée pour cette période', 'No data for this period'),
          style: t.bodySmall?.copyWith(color: s.onSurfaceVariant.withValues(alpha: 0.65)),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _NoDataCard — shown when year isn't cached
// ══════════════════════════════════════════════════════════════════════════

class _NoDataCard extends StatelessWidget {
  final int year;
  final VoidCallback onLoad;
  final String? label;
  const _NoDataCard({required this.year, required this.onLoad, this.label});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final what = label ?? '$year';
    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(children: [
        Icon(Icons.cloud_download_outlined, color: s.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _ct('Chargez l\'historique pour afficher $what',
                'Load history to display $what'),
            style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: onLoad,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(_ct('Charger', 'Load'),
              style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _HeatmapCard — continuous GitHub-style heatmap over [start, end]
// ══════════════════════════════════════════════════════════════════════════

class _HeatmapCard extends StatelessWidget {
  final Map<String, int> data;
  final DateTime          start;
  final DateTime          end;
  const _HeatmapCard({required this.data, required this.start, required this.end});

  static const _cell = 10.0;
  static const _gap  = 1.5;

  @override
  Widget build(BuildContext context) {
    final s      = Theme.of(context).colorScheme;
    final t      = Theme.of(context).textTheme;
    final maxVal = data.values.fold(0, (a, b) => a > b ? a : b);

    final startDay   = DateTime(start.year, start.month, start.day);
    final endDay     = DateTime(end.year, end.month, end.day);
    final startWd    = startDay.weekday;
    final totalDays  = endDay.difference(startDay).inDays + 1;
    final totalCells = (startWd - 1) + totalDays;
    final weeks      = (totalCells / 7).ceil();
    final spansYears = endDay.year != startDay.year;

    final weekColumns = List.generate(weeks, (col) {
      return List.generate(7, (row) {
        final offset = col * 7 + row - (startWd - 1);
        if (offset < 0 || offset >= totalDays) return null;
        return offset;
      });
    });

    // Month label for the week column where each month begins. January
    // also carries the year so multi-year spans stay readable.
    final monthStarts = <int, String>{};
    final yearBoundaryCols = <int>{};
    var cursor = DateTime(startDay.year, startDay.month, 1);
    while (!cursor.isAfter(endDay)) {
      final off = cursor.difference(startDay).inDays + (startWd - 1);
      if (off >= 0) {
        final col = off ~/ 7;
        monthStarts[col] = spansYears && cursor.month == 1
            ? '${L.months[cursor.month]} ${cursor.year}'
            : L.months[cursor.month];
        if (cursor.month == 1 && cursor.year != startDay.year) {
          yearBoundaryCols.add(col);
        }
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return Container(
      decoration: _chartCardDecoration(s),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weekColumns.asMap().entries.map((entry) {
                final col  = entry.key;
                final days = entry.value;
                final isYearStart = yearBoundaryCols.contains(col);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thin separator before a new year, columns stay glued
                    if (isYearStart)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: SizedBox(
                          height: _cell + 16,
                          child: VerticalDivider(
                            width: 1, thickness: 1,
                            color: s.primary.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: _gap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month label or empty placeholder
                          SizedBox(
                            height: 14,
                            child: monthStarts.containsKey(col)
                                ? Text(
                                    monthStarts[col]!,
                                    style: t.labelSmall?.copyWith(
                                      fontSize: 8,
                                      color: isYearStart
                                          ? s.primary
                                          : s.onSurfaceVariant.withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 2),
                          ...days.map((offset) {
                            if (offset == null) {
                              return SizedBox(width: _cell, height: _cell + _gap);
                            }
                            final d   = startDay.add(Duration(days: offset));
                            final key = '${d.year}-'
                                '${d.month.toString().padLeft(2, '0')}-'
                                '${d.day.toString().padLeft(2, '0')}';
                            final count = data[key] ?? 0;
                            final ratio = (maxVal > 0 && count > 0)
                                ? count / maxVal : 0.0;
                            final scaled = ratio > 0
                                ? sqrt(ratio).clamp(0.0, 1.0) : 0.0;
                            final color = count == 0
                                ? s.surfaceContainerHigh
                                : Color.lerp(
                                    s.primaryContainer, s.primary,
                                    (scaled * 0.85 + 0.15).clamp(0.0, 1.0))!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: _gap),
                              child: Tooltip(
                                message: count > 0
                                    ? '${d.day}/${d.month}/${d.year} — $count scrobbles' : '',
                                child: Container(
                                  width: _cell, height: _cell,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Spacer(),
            Text(_ct('Moins', 'Less'),
                style: t.labelSmall?.copyWith(fontSize: 9, color: s.onSurfaceVariant)),
            const SizedBox(width: 4),
            ...List.generate(5, (i) => Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: i == 0
                    ? s.surfaceContainerHigh
                    : Color.lerp(s.primaryContainer, s.primary,
                        (i / 4).clamp(0.0, 1.0)),
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: s.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: s.primary.withValues(alpha: 0.18), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: t.labelSmall
          ?.copyWith(color: s.onSurface.withValues(alpha: 0.65), fontSize: 11)),
      const SizedBox(width: 6),
      Text(value, style: t.labelSmall?.copyWith(
          color: s.primary, fontWeight: FontWeight.w800, fontSize: 11)),
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(24)),
    child: Text(label,
        style: t.labelSmall?.copyWith(
            color: onColor, fontWeight: FontWeight.w700)),
  );
}

class _TagEntry {
  final String name; final int count;
  const _TagEntry({required this.name, required this.count});
}