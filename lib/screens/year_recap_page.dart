// lib/screens/year_recap_page.dart
//
// "Year in review" story: one slide per highlight (total, top artist, top
// tracks / albums, month by month, listening hours, streak, discoveries) and a
// final slide with a shareable summary card.
//
// Everything is built from data the app already has: the per-year scrobble
// cache (AllScrobblesService), the "link versions / split collabs" rules
// (LibraryMerge), the artwork resolver (ImageService), the PNG share helper
// (AppShare) and the current Material You colour scheme.

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../widgets/skeleton.dart';
import '../theme/m3_motion.dart';
import '../theme/story_style.dart';
import '../services/app_share.dart';
import '../services/lastfm_service.dart';
import '../services/library_merge.dart';
import '../services/friends_library_service.dart';
import '../services/image_service.dart';
import '../services/all_scrobbles_service.dart';
import '../services/scrobbles_file_cache.dart';
import '../l10n/l10n.dart';
import '../l10n/extra_strings.dart';

// Average track length used for the "hours of music" estimate (Last.fm does
// not give durations in scrobble history), clearly labelled as an estimate.
const double _kAvgTrackMinutes = 3.5;

class _Ranked {
  final String name;
  final String artist; // empty for artists
  final int count;
  const _Ranked(this.name, this.artist, this.count);
}

class _YearData {
  int total = 0;
  int activeDays = 0;
  int daysInRange = 0;
  int longestStreak = 0;
  String? busiestDay; // YYYY-MM-DD
  int busiestDayCount = 0;
  List<int> monthly = List.filled(12, 0);
  List<int> hourly = List.filled(24, 0);
  List<int> weekday = List.filled(7, 0); // Mon..Sun
  List<_Ranked> artists = [];
  List<_Ranked> tracks = [];
  List<_Ranked> albums = [];
  int uniqueArtists = 0;
  int uniqueTracks = 0;
  int? newArtists; // null = unknown (older years not cached)
  List<String> topArtistNames = []; // top 50, lower-case, for taste matching
}

class _FriendRow {
  final String name;
  final int total;
  const _FriendRow(this.name, this.total);
}

class _FriendsData {
  final List<_FriendRow> board; // friends with scrobbles this year
  final String? twin;           // friend with the most artists in common
  final List<String> shared;    // shared artists (display names, my rank order)
  final int sharedCount;
  const _FriendsData(this.board, this.twin, this.shared, this.sharedCount);
}

class YearRecapPage extends StatefulWidget {
  final LastFmService service;
  final String username;
  const YearRecapPage({super.key, required this.service, required this.username});

  @override
  State<YearRecapPage> createState() => _YearRecapPageState();
}

class _YearRecapPageState extends State<YearRecapPage> {
  late int _year = DateTime.now().year;
  _YearData? _data;
  bool _loading = true;
  bool _error = false;
  double _progress = 0;
  int _slide = 0;
  final PageController _pages = PageController();
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;
  _FriendsData? _friendsData;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<int> get _years {
    final now = DateTime.now().year;
    final first = AllScrobblesService.getRegistrationYear().clamp(2002, now).toInt();
    return [for (var y = now; y >= first; y--) y];
  }

  Future<void> _load() async {
    final token = ++_token;
    setState(() {
      _friendsData = null;
      _loading = true;
      _error = false;
      _progress = 0;
      _data = null;
      _slide = 0;
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
    try {
      final records = await AllScrobblesService.loadYear(
        _year,
        widget.service,
        onProgress: (loaded, total) {
          if (mounted && total > 0) setState(() => _progress = loaded / total);
        },
      );
      if (!mounted) return;
      final data = _compute(records, _year);
      setState(() {
        _data = data;
        _loading = false;
      });
      if (data.total > 0) _loadFriends(_year, data, token);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  // ── Aggregation ──────────────────────────────────────────────────────────
  _YearData _compute(List<ScrobbleRecord> records, int year) {
    final d = _YearData();
    d.total = records.length;
    if (records.isEmpty) return d;

    final known = LibraryMerge.knownSync(widget.service.username);
    final artistCount = <String, int>{};
    final trackCount = <String, int>{};
    final trackRep = <String, ScrobbleRecord>{};
    final albumCount = <String, int>{};
    final albumRep = <String, ScrobbleRecord>{};
    final dayCount = <String, int>{};

    for (final r in records) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.ts * 1000);
      d.monthly[dt.month - 1]++;
      d.hourly[dt.hour]++;
      d.weekday[dt.weekday - 1]++;
      final dayKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      dayCount[dayKey] = (dayCount[dayKey] ?? 0) + 1;

      if (r.artist.isEmpty) continue;
      final parts = LibraryMerge.splitOn
          ? LibraryMerge.artistParts(r.artist, known, ambiguous: true)
          : [r.artist];
      for (final a in parts) {
        artistCount[a] = (artistCount[a] ?? 0) + 1;
      }
      final tKey = LibraryMerge.mergeOn
          ? LibraryMerge.trackKey(r.track, r.artist, known)
          : '${r.artist} — ${r.track}';
      trackCount[tKey] = (trackCount[tKey] ?? 0) + 1;
      trackRep.putIfAbsent(tKey, () => r);
      if (r.album.isNotEmpty) {
        final aKey = '${r.artist} — ${r.album}';
        albumCount[aKey] = (albumCount[aKey] ?? 0) + 1;
        albumRep.putIfAbsent(aKey, () => r);
      }
    }

    List<T> top<T>(Map<String, int> m, T Function(String, int) build) {
      final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return e.take(5).map((x) => build(x.key, x.value)).toList();
    }

    d.artists = top(artistCount, (k, c) => _Ranked(k, '', c));
    d.tracks = top(trackCount, (k, c) => _Ranked(trackRep[k]!.track, trackRep[k]!.artist, c));
    d.albums = top(albumCount, (k, c) => _Ranked(albumRep[k]!.album, albumRep[k]!.artist, c));
    final ranked = artistCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    d.topArtistNames = ranked.take(50).map((e) => e.key).toList();
    d.uniqueArtists = artistCount.length;
    d.uniqueTracks = trackCount.length;

    // Active days, busiest day, longest streak (consecutive calendar days).
    d.activeDays = dayCount.length;
    final days = dayCount.keys.toList()..sort();
    var streak = 0, best = 0;
    DateTime? prev;
    for (final k in days) {
      final p = k.split('-');
      final day = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      streak = (prev != null && day.difference(prev).inHours <= 36) ? streak + 1 : 1;
      if (streak > best) best = streak;
      prev = day;
      final c = dayCount[k]!;
      if (c > d.busiestDayCount) {
        d.busiestDayCount = c;
        d.busiestDay = k;
      }
    }
    d.longestStreak = best;
    final now = DateTime.now();
    final end = year == now.year ? now : DateTime(year, 12, 31);
    d.daysInRange = end.difference(DateTime(year, 1, 1)).inDays + 1;

    // Discoveries: artists never scrobbled in any earlier year. Only computed
    // when every earlier year since registration is in the local cache.
    final reg = AllScrobblesService.getRegistrationYear();
    var allPrior = true;
    final before = <String>{};
    for (var y = reg; y < year; y++) {
      final rs = AllScrobblesService.isYearCached(y) ? AllScrobblesService.getRecordsForYear(y) : null;
      if (rs == null) {
        allPrior = false;
        break;
      }
      for (final r in rs) {
        before.add(r.artist);
      }
    }
    if (allPrior && year > reg) {
      d.newArtists = artistCount.keys.where((a) => !before.contains(a)).length;
    }
    return d;
  }

  // ── Friends ──────────────────────────────────────────────────────────────
  // Yearly totals: one cheap call per friend (limit 1 -> only the total).
  // Taste twin: overlap between your top artists of the year and the friend
  // libraries already synced by FriendsLibraryService (no extra requests).
  Future<void> _loadFriends(int year, _YearData d, int token) async {
    try {
      final raw = await widget.service.getFriends(limit: 30, withRecentTrack: false);
      final names = <String>[
        for (final f in raw)
          if (f is Map && (f['name'] ?? '').toString().isNotEmpty) f['name'].toString()
      ].take(20).toList();
      if (names.isEmpty) return;
      final now = DateTime.now();
      final from = DateTime(year, 1, 1).millisecondsSinceEpoch ~/ 1000;
      final to = (year == now.year ? now.add(const Duration(minutes: 1)) : DateTime(year + 1, 1, 1))
              .millisecondsSinceEpoch ~/ 1000;

      final board = <_FriendRow>[];
      for (var i = 0; i < names.length; i += 5) {
        final batch = names.skip(i).take(5);
        final res = await Future.wait(batch.map((n) async {
          try {
            final r = await widget.service.getRecentTracks(user: n, from: from, to: to, limit: 1);
            final t = int.tryParse((r['@attr']?['total'] ?? '0').toString()) ?? 0;
            return _FriendRow(n, t);
          } catch (_) {
            return _FriendRow(n, 0); // private profile / error: skipped below
          }
        }));
        board.addAll(res.where((r) => r.total > 0));
        if (!mounted || token != _token) return;
      }

      String? twin;
      var shared = <String>[];
      var best = 0;
      final mine = d.topArtistNames;
      for (final n in names) {
        final lib = FriendsLibraryService.get(n);
        if (lib == null) continue;
        final theirs = lib.artists.take(150).map((a) => (a['name'] ?? '').toString().toLowerCase()).toSet();
        final common = mine.where((a) => theirs.contains(a.toLowerCase())).toList();
        if (common.length > best) {
          best = common.length;
          twin = n;
          shared = common;
        }
      }
      if (!mounted || token != _token) return;
      setState(() => _friendsData = _FriendsData(board, twin, shared.take(6).toList(), best));
    } catch (_) {
      // Friends are a bonus: no friends / network error -> no friend slides.
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('\u202f');
      b.write(s[i]);
    }
    return b.toString();
  }

  List<String> get _months => tx('yr_months').split(',');

  String _dayLabel(String key) {
    final p = key.split('-');
    final m = int.parse(p[1]);
    final names = _months;
    return '${int.parse(p[2])} ${m - 1 < names.length ? names[m - 1] : p[1]}';
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final rb = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (rb == null) return;
      final img = await rb.toImage(pixelRatio: 3.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bytes == null) return;
      await AppShare.shareBytes('laststats_year_${widget.username}_$_year.png', bytes.buffer.asUint8List());
    } catch (_) {
      // Render/share failure: nothing to share, fail silently.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _next() {
    if (_data == null) return;
    if (_slide < _slideCount - 1) {
      _pages.nextPage(duration: M3Motion.spatialFastDuration, curve: M3Motion.spatialFast);
    }
  }

  void _prev() {
    if (_slide > 0) {
      _pages.previousPage(duration: M3Motion.spatialFastDuration, curve: M3Motion.spatialFast);
    }
  }

  int get _slideCount => _buildSlides(Theme.of(context).colorScheme).length;

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = _data;
    final ready = d != null && d.total > 0;
    final slides = ready ? _buildSlides(scheme) : const <Widget>[];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primaryContainer.withValues(alpha: 0.6), scheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            if (ready)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: List.generate(slides.length, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: M3Motion.spatialFastDuration,
                        curve: M3Motion.spatialFast,
                        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _slide ? scheme.primary : scheme.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tx('yr_title'), style: AppText.title.copyWith(color: scheme.onSurface)),
                ),
                PopupMenuButton<int>(
                  tooltip: '$_year',
                  initialValue: _year,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.lgR),
                  onSelected: (y) {
                    if (y == _year) return;
                    _year = y;
                    _load();
                  },
                  itemBuilder: (_) => [for (final y in _years) PopupMenuItem(value: y, child: Text('$y'))],
                  child: Chip(
                    label: Text('$_year', style: const TextStyle(fontWeight: FontWeight.w800)),
                    avatar: const Icon(Icons.expand_more_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
              ]),
            ),
            Expanded(child: _content(scheme, slides)),
          ]),
        ),
      ),
    );
  }

  Widget _content(ColorScheme scheme, List<Widget> slides) {
    if (_loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 120, child: LinearProgressIndicator(value: _progress > 0 ? _progress : null, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 16),
          Text(tx('yr_loading'), style: TextStyle(color: scheme.onSurfaceVariant)),
        ]),
      );
    }
    if (_error || _data == null || _data!.total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(_error ? Icons.cloud_off_rounded : Icons.music_off_rounded, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              _error ? tx('yr_error') : tx('yr_empty', {'year': '$_year'}),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
            ),
            if (_error) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: _load, child: Text(tx('yr_retry'))),
            ],
          ]),
        ),
      );
    }
    return Stack(children: [
      PageView(
        controller: _pages,
        onPageChanged: (i) => setState(() => _slide = i),
        children: slides,
      ),
      // Tap zones (left third = back, right two thirds = next), like a story.
      Positioned.fill(
        child: Row(children: [
          Expanded(
            flex: 1,
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _prev),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _next),
          ),
        ]),
      ),
    ]);
  }

  // ── Slides ───────────────────────────────────────────────────────────────
  List<Widget> _buildSlides(ColorScheme s) {
    final d = _data;
    if (d == null || d.total == 0) return const [];
    final hours = (d.total * _kAvgTrackMinutes / 60).round();
    final out = <Widget>[];

    // 1. Intro
    out.add(_Slide(
      scheme: s,
      children: [
        Text(tx('yr_intro_h', {'year': '$_year'}),
            textAlign: TextAlign.center,
            style: TextStyle(color: s.onSurface, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
        const SizedBox(height: 28),
        _CountUp(value: d.total, fmt: _fmt, delayMs: 350, durationMs: 1600,
            style: TextStyle(color: s.primary, fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 6),
        _Reveal(delayMs: 500, child: Text(tx('yr_scrobbles'), style: TextStyle(color: s.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.w700))),
        const SizedBox(height: 20),
        _Reveal(delayMs: 1900, child: Text(tx('yr_hours', {'h': _fmt(hours)}),
            textAlign: TextAlign.center, style: TextStyle(color: s.onSurfaceVariant, fontSize: 14))),
      ],
    ));

    // 2-4. Top artist / track / album: #1 big in the middle, then the rest
    if (d.artists.isNotEmpty) out.add(_topSlide(s, d.artists, 'artists', tx('yr_top_artist')));
    if (d.tracks.isNotEmpty) out.add(_topSlide(s, d.tracks, 'tracks', tx('yr_top_track')));
    if (d.albums.isNotEmpty) out.add(_topSlide(s, d.albums, 'albums', tx('yr_top_album')));

    // 5. Month by month
    final maxM = d.monthly.fold<int>(0, (m, v) => v > m ? v : m);
    final bestMonth = d.monthly.indexOf(maxM);
    out.add(_Slide(
      scheme: s,
      children: [
        _label(s, tx('yr_months_h')),
        const SizedBox(height: 22),
        SizedBox(
          height: 170,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (i) {
              final f = maxM == 0 ? 0.0 : d.monthly[i] / maxM;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: f),
                          duration: Duration(milliseconds: 500 + i * 80),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => FractionallySizedBox(
                            heightFactor: v.clamp(0.02, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == bestMonth ? s.primary : s.primary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(i < _months.length ? _months[i].characters.first : '',
                        style: TextStyle(color: s.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 22),
        Text(tx('yr_best_month', {'m': bestMonth < _months.length ? _months[bestMonth] : '', 'n': _fmt(maxM)}),
            textAlign: TextAlign.center, style: TextStyle(color: s.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
        if (d.busiestDay != null) ...[
          const SizedBox(height: 8),
          Text(tx('yr_best_day', {'d': _dayLabel(d.busiestDay!), 'n': _fmt(d.busiestDayCount)}),
              textAlign: TextAlign.center, style: TextStyle(color: s.onSurfaceVariant, fontSize: 14)),
        ],
      ],
    ));

    // 6. When you listen
    final buckets = <String, int>{
      'night': [for (var h = 0; h < 24; h++) if (h < 5 || h >= 22) d.hourly[h]].fold(0, (a, b) => a + b),
      'morning': [for (var h = 5; h < 12; h++) d.hourly[h]].fold(0, (a, b) => a + b),
      'day': [for (var h = 12; h < 18; h++) d.hourly[h]].fold(0, (a, b) => a + b),
      'evening': [for (var h = 18; h < 22; h++) d.hourly[h]].fold(0, (a, b) => a + b),
    };
    final persona = buckets.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    final maxH = d.hourly.fold<int>(0, (m, v) => v > m ? v : m);
    final peakHour = d.hourly.indexOf(maxH);
    final maxW = d.weekday.fold<int>(0, (m, v) => v > m ? v : m);
    final favDay = d.weekday.indexOf(maxW);
    final wd = L.weekdaysShort;
    out.add(_Slide(
      scheme: s,
      children: [
        _label(s, tx('yr_when_h')),
        const SizedBox(height: 14),
        Text(tx('yr_p_$persona'),
            textAlign: TextAlign.center,
            style: TextStyle(color: s.primary, fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 22),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (h) {
              final f = maxH == 0 ? 0.0 : d.hourly[h] / maxH;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FractionallySizedBox(
                    heightFactor: f.clamp(0.03, 1.0),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: h == peakHour ? s.primary : s.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final t in const ['0h', '6h', '12h', '18h', '23h'])
              Text(t, style: TextStyle(color: s.onSurfaceVariant, fontSize: 10)),
          ]),
        ),
        const SizedBox(height: 22),
        Text(tx('yr_peak', {'h': '$peakHour', 'd': favDay < wd.length ? wd[favDay] : ''}),
            textAlign: TextAlign.center, style: TextStyle(color: s.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    ));

    // 7. Consistency
    out.add(_Slide(
      scheme: s,
      children: [
        _label(s, tx('yr_streak_h')),
        const SizedBox(height: 22),
        _CountUp(value: d.longestStreak, fmt: _fmt, delayMs: 300, durationMs: 1400,
            style: TextStyle(color: s.primary, fontSize: 84, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 6),
        Text(tx('yr_streak', {'n': '${d.longestStreak}'}),
            textAlign: TextAlign.center, style: TextStyle(color: s.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Text(tx('yr_active', {'n': '${d.activeDays}', 't': '${d.daysInRange}'}),
            textAlign: TextAlign.center, style: TextStyle(color: s.onSurfaceVariant, fontSize: 14)),
      ],
    ));

    // 8. Discoveries
    out.add(_Slide(
      scheme: s,
      children: [
        _label(s, tx('yr_disc_h')),
        const SizedBox(height: 22),
        if (d.newArtists != null) ...[
          _CountUp(value: d.newArtists!, fmt: _fmt, delayMs: 300, durationMs: 1400,
              style: TextStyle(color: s.primary, fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 6),
          Text(tx('yr_new'), textAlign: TextAlign.center, style: TextStyle(color: s.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
        ],
        Text(tx('yr_unique', {'a': _fmt(d.uniqueArtists), 't': _fmt(d.uniqueTracks)}),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: d.newArtists != null ? s.onSurfaceVariant : s.onSurface,
                fontSize: d.newArtists != null ? 14 : 20,
                fontWeight: d.newArtists != null ? FontWeight.w600 : FontWeight.w800)),
      ],
    ));

    // 9. Friends: yearly leaderboard
    final fr = _friendsData;
    String? rankLine;
    if (fr != null && fr.board.isNotEmpty) {
      final rows = [...fr.board, _FriendRow('', d.total)]..sort((a, b) => b.total.compareTo(a.total));
      final myRank = rows.indexWhere((r) => r.name.isEmpty) + 1;
      rankLine = tx('yr_rank', {'r': '$myRank', 'n': '${rows.length}'});
      final shown = rows.take(6).toList();
      if (!shown.any((r) => r.name.isEmpty)) shown[shown.length - 1] = rows[myRank - 1];
      final maxT = rows.first.total;
      out.add(_Slide(
        scheme: s,
        children: [
          _label(s, tx('yr_friends_h')),
          const SizedBox(height: 10),
          _Reveal(delayMs: 250, pop: true, child: Text(rankLine,
              textAlign: TextAlign.center,
              style: TextStyle(color: s.primary, fontSize: 26, fontWeight: FontWeight.w900))),
          const SizedBox(height: 20),
          for (var i = 0; i < shown.length; i++)
            _Reveal(
              delayMs: 700 + i * 180,
              child: _friendBar(s, shown[i], maxT, 900 + i * 180, rows.indexOf(shown[i]) + 1),
            ),
        ],
      ));
    }

    // 10. Friends: music twin
    if (fr != null && fr.twin != null) {
      out.add(_Slide(
        scheme: s,
        children: [
          _label(s, tx('yr_twin_h')),
          const SizedBox(height: 20),
          _Reveal(
            delayMs: 300,
            pop: true,
            child: CircleAvatar(
              radius: 52,
              backgroundColor: s.primaryContainer,
              child: Text(fr.twin!.characters.first.toUpperCase(),
                  style: TextStyle(color: s.onPrimaryContainer, fontSize: 44, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 14),
          _Reveal(delayMs: 800, child: Text(fr.twin!,
              textAlign: TextAlign.center,
              style: TextStyle(color: s.onSurface, fontSize: 28, fontWeight: FontWeight.w900))),
          const SizedBox(height: 6),
          _Reveal(delayMs: 1100, child: Text(tx('yr_twin_s', {'n': '${fr.sharedCount}'}),
              textAlign: TextAlign.center, style: TextStyle(color: s.onSurfaceVariant, fontSize: 15))),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < fr.shared.length; i++)
                _Reveal(
                  delayMs: 1400 + i * 160,
                  child: Chip(
                    label: Text(fr.shared[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                    backgroundColor: s.secondaryContainer,
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
        ],
      ));
    }

    // 11. Summary + share
    out.add(_Slide(
      scheme: s,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.contain,
            child: RepaintBoundary(key: _shareKey, child: _ShareCard(scheme: s, year: _year, username: widget.username, data: d, hours: hours, fmt: _fmt, rankLine: rankLine)),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _sharing ? null : _share,
          icon: _sharing
              ? SizedBox(width: 18, height: 18, child: M3Spinner(color: s.onPrimary))
              : const Icon(Icons.ios_share_rounded),
          label: Text(L.commonShare),
        ),
      ],
    ));
    return out;
  }

  // Big #1 (artwork, name, plays counting up) followed by ranks 2..5.
  Widget _topSlide(ColorScheme s, List<_Ranked> items, String type, String label) {
    final first = items.first;
    return _Slide(
      scheme: s,
      children: [
        _label(s, label),
        const SizedBox(height: 18),
        _Reveal(
          delayMs: 300,
          pop: true,
          child: _YImg(name: first.name, artist: first.artist, type: type, size: 190, round: type == 'artists'),
        ),
        const SizedBox(height: 18),
        _Reveal(
          delayMs: 900,
          child: Text(first.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: s.onSurface, fontSize: 28, fontWeight: FontWeight.w900)),
        ),
        if (first.artist.isNotEmpty)
          _Reveal(
            delayMs: 1000,
            child: Text(first.artist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: s.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 4),
        _CountUp(
            value: first.count,
            fmt: (n) => tx('yr_plays', {'n': _fmt(n)}),
            delayMs: 1200,
            durationMs: 1000,
            style: TextStyle(color: s.primary, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 22),
        _rankList(s, items.skip(1).toList(), type, startAt: 2, baseDelay: 1800),
      ],
    );
  }

  Widget _label(ColorScheme s, String t) => Text(t.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(color: s.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4));

  Widget _friendBar(ColorScheme s, _FriendRow r, int maxT, int delayMs, int rank) {
    final me = r.name.isEmpty;
    final f = maxT == 0 ? 0.0 : r.total / maxT;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 26, child: Text('$rank', style: TextStyle(color: me ? s.primary : s.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w900))),
          Expanded(
            child: Text(me ? tx('yr_you') : r.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: s.onSurface, fontSize: 14, fontWeight: me ? FontWeight.w900 : FontWeight.w700)),
          ),
          _CountUp(value: r.total, fmt: _fmt, delayMs: delayMs, durationMs: 1100,
              style: TextStyle(color: me ? s.primary : s.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: f),
            duration: Duration(milliseconds: 900 + (delayMs ~/ 4)),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v.clamp(0.02, 1.0),
                minHeight: 10,
                backgroundColor: s.primary.withValues(alpha: 0.12),
                color: me ? s.primary : s.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // Rows are revealed from the last to the first, so #1 lands last.
  Widget _rankList(ColorScheme s, List<_Ranked> items, String type, {int startAt = 1, int baseDelay = 300}) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _Reveal(
            delayMs: baseDelay + (items.length - 1 - i) * 240,
            pop: i == 0 && startAt == 1,
            child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(
                width: 28,
                child: Text('${startAt + i}',
                    style: TextStyle(color: i == 0 && startAt == 1 ? s.primary : s.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              _YImg(name: items[i].name, artist: items[i].artist, type: type, size: 46, round: type == 'artists'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(items[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.itemTitle.copyWith(color: s.onSurface)),
                  if (items[i].artist.isNotEmpty)
                    Text(items[i].artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(color: s.onSurfaceVariant)),
                ]),
              ),
              const SizedBox(width: 8),
              Text(tx('yr_plays', {'n': _fmt(items[i].count)}), style: AppText.badge.copyWith(color: s.primary)),
            ]),
          ),
          ),
      ],
    );
  }
}

// Fade + slide + scale-in after a delay. [pop] adds an overshoot (the reveal
// of a #1). Replays each time its slide is built, i.e. each time it is shown.
class _Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final bool pop;
  const _Reveal({required this.child, this.delayMs = 0, this.pop = false});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: widget.pop ? 750 : 520));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    final scale = Tween<double>(begin: widget.pop ? 0.5 : 0.94, end: 1)
        .animate(CurvedAnimation(parent: _c, curve: widget.pop ? Curves.easeOutBack : Curves.easeOutCubic));
    final slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: ScaleTransition(scale: scale, child: widget.child)),
    );
  }
}

// Number that counts up from 0 after a delay.
class _CountUp extends StatefulWidget {
  final int value;
  final String Function(int) fmt;
  final TextStyle style;
  final int delayMs;
  final int durationMs;
  const _CountUp({required this.value, required this.fmt, required this.style, this.delayMs = 0, this.durationMs = 1200});

  @override
  State<_CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<_CountUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: widget.durationMs));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Text(widget.fmt((widget.value * v).round()), textAlign: TextAlign.center, style: widget.style);
      },
    );
  }
}

// One story slide: centred column that fades/slides in when first shown.
class _Slide extends StatelessWidget {
  final ColorScheme scheme;
  final List<Widget> children;
  const _Slide({required this.scheme, required this.children});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 40),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
          ),
        ),
      ),
    );
  }
}

// Artwork resolved through the same ImageService chain as the rest of the app.
class _YImg extends StatefulWidget {
  final String name, artist, type; // type: artists | tracks | albums
  final double size;
  final bool round;
  const _YImg({required this.name, required this.artist, required this.type, required this.size, this.round = false});

  @override
  State<_YImg> createState() => _YImgState();
}

class _YImgState extends State<_YImg> {
  late final Future<String> _future = switch (widget.type) {
    'artists' => ImageService.resolveArtist(widget.name),
    'albums' => ImageService.resolveAlbum(widget.name, widget.artist),
    _ => ImageService.resolveTrack(widget.name, widget.artist),
  };

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final fallback = Container(
      width: widget.size,
      height: widget.size,
      color: s.surfaceContainerHighest,
      child: Icon(
        widget.type == 'artists' ? Icons.person_rounded : (widget.type == 'albums' ? Icons.album_rounded : Icons.music_note_rounded),
        color: s.onSurfaceVariant,
        size: widget.size * 0.5,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.round ? widget.size : widget.size * 0.18),
      child: FutureBuilder<String>(
        future: _future,
        builder: (_, snap) {
          final url = snap.data ?? '';
          if (url.isEmpty) return fallback;
          return ImageService.widgetImage(url: url, width: widget.size, height: widget.size, fit: BoxFit.cover, errorWidget: fallback);
        },
      ),
    );
  }
}

// Fixed-size portrait card, exported as a PNG by the share button.
class _ShareCard extends StatelessWidget {
  final ColorScheme scheme;
  final int year;
  final String username;
  final _YearData data;
  final int hours;
  final String Function(int) fmt;
  final String? rankLine; // friends ranking, when known
  const _ShareCard({required this.scheme, required this.year, required this.username, required this.data, required this.hours, required this.fmt, this.rankLine});

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(value, style: TextStyle(color: scheme.primary, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _list(String title, List<_Ranked> items, String type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      const SizedBox(height: 6),
      for (var i = 0; i < items.length && i < 3; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 20, child: Text('${i + 1}', style: TextStyle(color: scheme.primary, fontSize: 14, fontWeight: FontWeight.w900))),
            _YImg(name: items[i].name, artist: items[i].artist, type: type, size: 34, round: type == 'artists'),
            const SizedBox(width: 10),
            Expanded(
              child: Text(items[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurface, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 340,
        height: 600,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primaryContainer, scheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.45],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('LastStats · $username', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(tx('yr_intro_h', {'year': '$year'}), style: TextStyle(color: scheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 14),
          Row(children: [
            _stat(tx('yr_scrobbles'), fmt(data.total)),
            const SizedBox(width: 8),
            _stat(tx('yr_card_hours'), fmt(hours)),
            const SizedBox(width: 8),
            _stat(tx('yr_card_streak'), '${data.longestStreak}'),
          ]),
          if (rankLine != null) ...[
            const SizedBox(height: 10),
            Center(child: Text(rankLine!, style: TextStyle(color: scheme.primary, fontSize: 13, fontWeight: FontWeight.w800))),
          ],
          const SizedBox(height: 14),
          _list(tx('yr_top_artists'), data.artists, 'artists'),
          const SizedBox(height: 12),
          _list(tx('yr_top_tracks'), data.tracks, 'tracks'),
          const SizedBox(height: 12),
          _list(tx('yr_top_albums'), data.albums, 'albums'),
          const Spacer(),
          Center(child: Text('LastStats', style: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}
