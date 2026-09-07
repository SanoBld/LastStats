// lib/screens/recap_story_page.dart
//
// "Story" style recap: 3 pages (Today / This week / This month) with big
// numbers, a Material You podium (top 3 artists/tracks/albums), a top 10
// scroll list and a small bar chart. Opened from the dashboard avatar
// bubble, or from a daily/weekly notification. Uses the app's dynamic
// colorScheme so it always matches the current Material You theme.

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/lastfm_service.dart';
import '../services/image_service.dart';
import '../l10n/l10n.dart';

// Callback used to open the existing item detail sheet (artist/album/track).
// Passed in by the caller since that sheet lives in home_screen.dart's part
// files and can't be imported directly from here.
typedef OpenDetailFn = void Function(
    BuildContext context, Map<String, dynamic> item, String type, LastFmService service);

// Best raw last.fm image url from an item's 'image' list (used only as a
// fallback while the real per-type artwork is being resolved).
String _rawImg(dynamic images) {
  if (images is! List || images.isEmpty) return '';
  final entry = images.lastWhere(
      (i) => i is Map && i['size'] == 'extralarge',
      orElse: () => images.last);
  return (entry is Map ? entry['#text'] ?? '' : '').toString();
}

String _artistOf(Map item) {
  final a = item['artist'];
  if (a is Map) return (a['#text'] ?? a['name'] ?? '').toString();
  return (a ?? '').toString();
}

String _fmtNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

class RecapStoryPage extends StatefulWidget {
  final LastFmService service;
  final String username;
  // 0 = day, 1 = week, 2 = month
  final int initialPeriod;
  final OpenDetailFn? onOpenDetail;

  const RecapStoryPage({
    super.key,
    required this.service,
    required this.username,
    this.initialPeriod = 1,
    this.onOpenDetail,
  });

  @override
  State<RecapStoryPage> createState() => _RecapStoryPageState();
}

// One period's worth of recap data.
class _RecapData {
  int count = 0;
  int prevCount = 0;
  int uniqueArtists = 0;
  int uniqueTracks = 0;
  List<Map<String, dynamic>> topArtists = [];
  List<Map<String, dynamic>> topTracks = [];
  List<Map<String, dynamic>> topAlbums = [];
  List<double> bars = [];
  List<String> barLabels = [];
  bool loading = true;
  bool loaded = false;
}

class _RecapStoryPageState extends State<RecapStoryPage> {
  late int _period = widget.initialPeriod.clamp(0, 2).toInt();
  // 0 = artists, 1 = tracks, 2 = albums
  int _category = 0;
  final List<_RecapData> _data = [_RecapData(), _RecapData(), _RecapData()];

  // Off-screen render target used to export the recap as a shareable image.
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;

  // How many items we fetch/rank per category (top 3 podium + 7 more).
  static const int _topN = 10;

  @override
  void initState() {
    super.initState();
    _load(_period);
  }

  int _ts(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  int _total(Map r) => int.tryParse((r['@attr']?['total'] ?? '0').toString()) ?? 0;

  Future<void> _load(int p) async {
    if (_data[p].loaded) return;
    setState(() => _data[p].loading = true);
    try {
      final fresh = await _fetch(p);
      fresh.loaded = true;
      fresh.loading = false;
      if (!mounted) return;
      setState(() => _data[p] = fresh);
    } catch (_) {
      if (!mounted) return;
      setState(() => _data[p].loading = false);
    }
  }

  Future<_RecapData> _fetch(int p) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final nowEnd = now.add(const Duration(minutes: 1));

    late DateTime start;
    late DateTime prevStart;
    late DateTime prevEnd;
    if (p == 0) {
      start = todayStart;
      prevEnd = start;
      prevStart = start.subtract(const Duration(days: 1));
    } else if (p == 1) {
      start = todayStart.subtract(const Duration(days: 6));
      prevEnd = start;
      prevStart = start.subtract(const Duration(days: 7));
    } else {
      start = todayStart.subtract(const Duration(days: 29));
      prevEnd = start;
      prevStart = start.subtract(const Duration(days: 30));
    }

    final data = _RecapData();

    // Total scrobbles for this period + the previous one (for the delta chip).
    final totals = await Future.wait([
      widget.service.getRecentTracks(from: _ts(start), to: _ts(nowEnd), limit: 1),
      widget.service.getRecentTracks(from: _ts(prevStart), to: _ts(prevEnd), limit: 1),
    ]);
    data.count = _total(totals[0]);
    data.prevCount = _total(totals[1]);

    if (p == 0) {
      // Last.fm has no "1 day" top-list period, so we pull today's raw
      // scrobbles once and rank everything ourselves.
      final raw = await widget.service.getRecentTracks(
          from: _ts(start), to: _ts(nowEnd), limit: 200);
      final list = raw['track'] is List
          ? raw['track'] as List
          : (raw['track'] != null ? [raw['track']] : const []);

      final artistCount = <String, int>{};
      final trackCount = <String, int>{};
      final trackItem = <String, Map>{};
      final hourCount = List<int>.filled(24, 0);

      for (final t in list) {
        if (t is! Map) continue;
        final artistName =
            (t['artist'] is Map ? t['artist']['#text'] : t['artist'])?.toString() ?? '';
        final trackName = (t['name'] ?? '').toString();
        if (artistName.isEmpty) continue;

        artistCount[artistName] = (artistCount[artistName] ?? 0) + 1;

        final key = '$artistName — $trackName';
        trackCount[key] = (trackCount[key] ?? 0) + 1;
        trackItem[key] = t;

        final uts = int.tryParse((t['date']?['uts'] ?? '').toString());
        if (uts != null) {
          hourCount[DateTime.fromMillisecondsSinceEpoch(uts * 1000).hour]++;
        }
      }

      data.uniqueArtists = artistCount.length;
      data.uniqueTracks = trackCount.length;

      // Top artists — name + playcount only. Real artist artwork is
      // resolved later by _ItemImg (never the track cover art, which is
      // all recenttracks gives us here).
      final artistEntries = artistCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      data.topArtists = artistEntries.take(_topN).map((e) {
        return {'name': e.key, 'playcount': '${e.value}'};
      }).toList();

      final trackEntries = trackCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      data.topTracks = trackEntries.take(_topN).map((e) {
        final src = Map<String, dynamic>.from(trackItem[e.key]!);
        src['playcount'] = '${e.value}';
        return src;
      }).toList();

      // No album breakdown for "today" — would need per-scrobble album
      // grouping with little payoff for a single day.

      // Condense the 24 hours into 8 buckets of 3h for the mini chart.
      final buckets = List<int>.filled(8, 0);
      for (var h = 0; h < 24; h++) {
        buckets[h ~/ 3] += hourCount[h];
      }
      final maxB = buckets.fold<int>(0, (m, v) => v > m ? v : m);
      data.bars = buckets.map((v) => maxB == 0 ? 0.0 : v / maxB).toList();
      data.barLabels = const ['0h', '3h', '6h', '9h', '12h', '15h', '18h', '21h'];
    } else {
      final apiPeriod = p == 1 ? '7day' : '1month';
      final topLists = await Future.wait([
        widget.service.getTopArtists(period: apiPeriod, limit: _topN),
        widget.service.getTopTracks(period: apiPeriod, limit: _topN),
        widget.service.getTopAlbums(period: apiPeriod, limit: _topN),
      ]);
      data.topArtists = topLists[0].cast<Map<String, dynamic>>();
      data.topTracks = topLists[1].cast<Map<String, dynamic>>();
      data.topAlbums = topLists[2].cast<Map<String, dynamic>>();

      // Full top-200 lists just to count how many distinct artists/tracks.
      final wide = await Future.wait([
        widget.service.getTopArtists(period: apiPeriod, limit: 200),
        widget.service.getTopTracks(period: apiPeriod, limit: 200),
      ]);
      data.uniqueArtists = wide[0].length;
      data.uniqueTracks = wide[1].length;

      // Bar chart: 7 daily buckets for the week, 5 weekly buckets for the month.
      final bucketStarts = <DateTime>[];
      if (p == 1) {
        for (var i = 0; i < 7; i++) {
          bucketStarts.add(start.add(Duration(days: i)));
        }
      } else {
        for (var i = 0; i < 5; i++) {
          bucketStarts.add(start.add(Duration(days: i * 6)));
        }
      }
      final bucketFutures = <Future<Map<String, dynamic>>>[];
      for (var i = 0; i < bucketStarts.length; i++) {
        final bStart = bucketStarts[i];
        final bEnd = i + 1 < bucketStarts.length ? bucketStarts[i + 1] : nowEnd;
        bucketFutures.add(
            widget.service.getRecentTracks(from: _ts(bStart), to: _ts(bEnd), limit: 1));
      }
      final bucketRes = await Future.wait(bucketFutures);
      final counts = bucketRes.map(_total).toList();
      final maxB = counts.fold<int>(0, (m, v) => v > m ? v : m);
      data.bars = counts.map((v) => maxB == 0 ? 0.0 : v / maxB).toList();
      data.barLabels = p == 1
          ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
          : List.generate(5, (i) => 'W${i + 1}');
    }

    return data;
  }

  void _go(int p) {
    if (p < 0 || p > 2) return;
    setState(() => _period = p);
    _load(p);
  }

  String _detailType(int category) =>
      switch (category) { 0 => 'artists', 1 => 'tracks', _ => 'albums' };

  // Renders the current recap off-screen (clean layout, no controls) and
  // shares it as a PNG. Same technique used for achievement badge cards.
  Future<void> _shareRecap() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final rb = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (rb == null) return;
      final img = await rb.toImage(pixelRatio: 3.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bytes == null) return;
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/laststats_recap_${widget.username}_$_period.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      // Render/share failure: fail silently, nothing to share.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = _data[_period];
    final labels = [L.recapDay, L.recapWeek, L.recapMonth];
    final lists = [d.topArtists, d.topTracks, d.topAlbums];
    final category = (_period == 0 && _category == 2) ? 1 : _category;
    final categoryItems = lists[category];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primaryContainer.withValues(alpha: 0.55), scheme.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.32],
            ),
          ),
          child: SafeArea(
            child: Column(children: [
              // Story-style progress segments
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(children: List.generate(3, (i) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _go(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i == _period
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                })),
              ),
              // Header: close + period label + share
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                child: Row(children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: scheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(labels[_period],
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  IconButton(
                    tooltip: L.commonShare,
                    icon: _sharing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: scheme.onSurface))
                        : Icon(Icons.ios_share_rounded, color: scheme.onSurface),
                    onPressed: (d.count == 0 || _sharing) ? null : _shareRecap,
                  ),
                ]),
              ),
              Expanded(
                child: d.loading && !d.loaded
                    ? Center(child: CircularProgressIndicator(color: scheme.primary))
                    // Cross-fade whenever the period or category changes.
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOut,
                        child: _body(context, scheme, d, category, categoryItems,
                            key: ValueKey('$_period-$category')),
                      ),
              ),
              // Prev / next controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(children: [
                  _navBtn(scheme, Icons.chevron_left_rounded, _period > 0, () => _go(_period - 1)),
                  const Spacer(),
                  _navBtn(scheme, Icons.chevron_right_rounded, _period < 2, () => _go(_period + 1)),
                ]),
              ),
            ]),
          ),
        ),

        // Off-screen clean copy used only for the share export.
        Positioned(
          left: -9999,
          top: -9999,
          child: RepaintBoundary(
            key: _shareKey,
            child: _ShareCard(
              scheme: scheme,
              periodLabel: labels[_period],
              username: widget.username,
              data: d,
              type: _detailType(category),
              items: categoryItems,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _navBtn(ColorScheme scheme, IconData icon, bool enabled, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.25,
      child: IconButton(
        icon: Icon(icon, color: scheme.onSurface, size: 30),
        onPressed: enabled ? onTap : null,
      ),
    );
  }

  Widget _body(BuildContext context, ColorScheme scheme, _RecapData d, int category,
      List<Map<String, dynamic>> categoryItems, {Key? key}) {
    if (d.count == 0) {
      return Center(
        key: key,
        child: Text(L.recapNoData,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15)),
      );
    }

    final delta = d.prevCount > 0 ? (d.count - d.prevCount) / d.prevCount * 100 : null;
    final podiumItems = categoryItems.take(3).toList();
    final List<Map<String, dynamic>> restItems =
        categoryItems.length > 3 ? categoryItems.sublist(3, categoryItems.length) : [];

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Big scrobble count, with a small pop-in animation
        _FadeInUp(
          child: Text('${d.count}',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 56,
                fontWeight: FontWeight.w900,
                height: 1,
              )),
        ),
        Row(children: [
          Text(L.recapScrobbles,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
          if (delta != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 20),

        // Unique artists / tracks / avg per day
        _FadeInUp(
          delayMs: 60,
          child: Row(children: [
            Expanded(child: _statChip(scheme, L.recapArtists, '${d.uniqueArtists}')),
            const SizedBox(width: 10),
            Expanded(child: _statChip(scheme, L.recapTracks, '${d.uniqueTracks}')),
            const SizedBox(width: 10),
            Expanded(
                child: _statChip(scheme, L.recapAvgDay,
                    (d.count / (_period == 0 ? 1 : (_period == 1 ? 7 : 30))).toStringAsFixed(1))),
          ]),
        ),
        const SizedBox(height: 22),

        // Mini bar chart
        if (d.bars.isNotEmpty) _barChart(scheme, d),
        const SizedBox(height: 26),

        // Category switcher: Artists / Tracks / Albums
        Row(children: [
          _categoryChip(scheme, L.recapArtists, 0),
          const SizedBox(width: 8),
          _categoryChip(scheme, L.recapTracks, 1),
          if (_period != 0) ...[
            const SizedBox(width: 8),
            _categoryChip(scheme, L.recapTopAlbum, 2),
          ],
        ]),
        const SizedBox(height: 18),

        if (podiumItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(L.recapNoData,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            ),
          )
        else
          _podium(context, scheme, podiumItems, _detailType(category)),

        if (restItems.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(L.recapTop10,
              style:
                  TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _top10Scroll(context, scheme, restItems, _detailType(category)),
        ],
      ]),
    );
  }

  // Horizontally scrollable ranks 4-10, cover art + name + play count.
  Widget _top10Scroll(
      BuildContext context, ColorScheme scheme, List<Map<String, dynamic>> items, String type) {
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final item = items[i];
          final rank = i + 4;
          final plays = int.tryParse((item['playcount'] ?? '0').toString()) ?? 0;
          final title = (item['name'] ?? '').toString();
          return _FadeInUp(
            delayMs: i * 60,
            child: GestureDetector(
              onTap: widget.onOpenDetail == null
                  ? null
                  : () => widget.onOpenDetail!(context, item, type, widget.service),
              child: SizedBox(
                width: 104,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _ItemImg(item: item, type: type, size: 104, round: false),
                    ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#$rank',
                            style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: scheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
                  Text('${_fmtNum(plays)} ${L.commonPlays}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryChip(ColorScheme scheme, String label, int index) {
    final selected = _category == index;
    return GestureDetector(
      onTap: () => setState(() => _category = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }

  Widget _statChip(ColorScheme scheme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
      ]),
    );
  }

  Widget _barChart(ColorScheme scheme, _RecapData d) {
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(d.bars.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6 + d.bars[i] * 58,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.35 + d.bars[i] * 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d.barLabels[i],
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // Podium: rank 1 in the middle (tallest), 2 on the left, 3 on the right —
  // classic podium layout. Falls back to a simple stacked list under 3 items.
  Widget _podium(
      BuildContext context, ColorScheme scheme, List<Map<String, dynamic>> items, String type) {
    if (items.length < 3) {
      return Column(children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _FadeInUp(delayMs: i * 80, child: _podiumRow(context, scheme, items[i], i, type)),
        ],
      ]);
    }

    // [1st, 2nd, 3rd] -> display order [2nd, 1st, 3rd]
    const order = [1, 0, 2];
    const heights = [96.0, 128.0, 78.0];
    const avatarSizes = [56.0, 68.0, 48.0];
    final colors = [scheme.secondaryContainer, scheme.primaryContainer, scheme.tertiaryContainer];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (slot) {
        final rank = order[slot];
        final item = items[rank];
        final plays = int.tryParse((item['playcount'] ?? '0').toString()) ?? 0;
        final title = (item['name'] ?? '').toString();
        final sub = type == 'artists' ? '' : _artistOf(item);

        return Expanded(
          child: _FadeInUp(
            delayMs: slot * 90,
            child: GestureDetector(
              onTap: widget.onOpenDetail == null
                  ? null
                  : () => widget.onOpenDetail!(context, item, type, widget.service),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Stack(clipBehavior: Clip.none, children: [
                    ClipOval(
                      child: _ItemImg(
                          item: item, type: type, size: avatarSizes[slot], round: true),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        child: Text('${rank + 1}',
                            style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: scheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
                  Text('${_fmtNum(plays)} ${L.commonPlays}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
                  const SizedBox(height: 8),
                  Container(
                    height: heights[slot],
                    decoration: BoxDecoration(
                      color: colors[slot],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _podiumRow(
      BuildContext context, ColorScheme scheme, Map<String, dynamic> item, int rank, String type) {
    final plays = int.tryParse((item['playcount'] ?? '0').toString()) ?? 0;
    final title = (item['name'] ?? '').toString();
    final sub = type == 'artists' ? '' : _artistOf(item);

    return GestureDetector(
      onTap: widget.onOpenDetail == null
          ? null
          : () => widget.onOpenDetail!(context, item, type, widget.service),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          ClipOval(child: _ItemImg(item: item, type: type, size: 44, round: true)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
              if (sub.isNotEmpty)
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
            ]),
          ),
          Text('${_fmtNum(plays)} ${L.commonPlays}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ]),
      ),
    );
  }
}

// Simple staggered fade + slide-up entrance for list/podium items.
class _FadeInUp extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _FadeInUp({required this.child, this.delayMs = 0});

  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _show ? 1 : 0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _show ? Offset.zero : const Offset(0, 0.15),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// Resolves the correct artwork per item type (artist photo / album cover /
// track cover) via ImageService, instead of just reusing whatever raw
// last.fm 'image' field the item happened to carry (which for "today"'s
// artists was actually the track's cover art, not the artist's photo).
class _ItemImg extends StatefulWidget {
  final Map<String, dynamic> item;
  final String type; // artists | tracks | albums
  final double size;
  final bool round;

  const _ItemImg({required this.item, required this.type, required this.size, this.round = true});

  @override
  State<_ItemImg> createState() => _ItemImgState();
}

class _ItemImgState extends State<_ItemImg> {
  late final Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  Future<String> _resolve() {
    final name = (widget.item['name'] ?? '').toString();
    final artist = _artistOf(widget.item);
    final raw = _rawImg(widget.item['image']);
    final lastfmUrl = raw.isNotEmpty ? raw : null;
    switch (widget.type) {
      case 'artists':
        return ImageService.resolveArtist(name, lastfmUrl: lastfmUrl);
      case 'albums':
        return ImageService.resolveAlbum(name, artist, lastfmUrl: lastfmUrl);
      default:
        return ImageService.resolveTrack(name, artist, lastfmUrl: lastfmUrl);
    }
  }

  Widget _fallback(ColorScheme scheme) => Container(
        width: widget.size,
        height: widget.size,
        color: scheme.surfaceContainerHighest,
        child: Icon(
          widget.type == 'artists'
              ? Icons.person_rounded
              : widget.type == 'albums'
                  ? Icons.album_rounded
                  : Icons.music_note_rounded,
          color: scheme.onSurfaceVariant,
          size: widget.size * 0.5,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        final url = snap.data ?? '';
        if (url.isEmpty) return _fallback(scheme);
        return ImageService.widgetImage(
          url: url,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorWidget: _fallback(scheme),
        );
      },
    );
  }
}

// Clean, control-free layout rendered off-screen and exported as a PNG
// when the user taps "share". Portrait story ratio.
class _ShareCard extends StatelessWidget {
  final ColorScheme scheme;
  final String periodLabel;
  final String username;
  final _RecapData data;
  final String type;
  final List<Map<String, dynamic>> items;

  const _ShareCard({
    required this.scheme,
    required this.periodLabel,
    required this.username,
    required this.data,
    required this.type,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final top3 = items.take(3).toList();
    return Material(
      color: scheme.surface,
      child: Container(
        width: 360,
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primaryContainer, scheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.4],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('LastStats · $username',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(periodLabel,
              style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Text('${data.count}',
              style: TextStyle(color: scheme.onSurface, fontSize: 60, fontWeight: FontWeight.w900, height: 1)),
          Text(L.recapScrobbles, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 26),
          for (var i = 0; i < top3.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(children: [
              Text('${i + 1}',
                  style: TextStyle(color: scheme.primary, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _ItemImg(item: top3[i], type: type, size: 40, round: false),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text((top3[i]['name'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
