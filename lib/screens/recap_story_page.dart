// lib/screens/recap_story_page.dart
//
// "Story" style recap: 3 pages (Today / This week / This month) with big
// numbers, top artist/track/album and a small bar chart. Opened from the
// dashboard avatar bubble, or from a daily/weekly notification.

import 'package:flutter/material.dart';
import '../services/lastfm_service.dart';
import '../l10n/l10n.dart';

class RecapStoryPage extends StatefulWidget {
  final LastFmService service;
  final String username;
  // 0 = day, 1 = week, 2 = month
  final int initialPeriod;

  const RecapStoryPage({
    super.key,
    required this.service,
    required this.username,
    this.initialPeriod = 1,
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
  Map? topArtist;
  int topArtistPlays = 0;
  Map? topTrack;
  int topTrackPlays = 0;
  Map? topAlbum;
  int topAlbumPlays = 0;
  List<double> bars = [];
  List<String> barLabels = [];
  bool loading = true;
  bool loaded = false;
}

class _RecapStoryPageState extends State<RecapStoryPage> {
  late int _period = widget.initialPeriod.clamp(0, 2).toInt();
  final List<_RecapData> _data = [_RecapData(), _RecapData(), _RecapData()];

  static const _gradients = [
    [Color(0xFF7C3AED), Color(0xFF1D4ED8)], // day: violet -> blue
    [Color(0xFFD51007), Color(0xFFF97316)], // week: last.fm red -> orange
    [Color(0xFF059669), Color(0xFF0D9488)], // month: green -> teal
  ];

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
      // scrobbles once and count everything ourselves.
      final raw = await widget.service.getRecentTracks(
          from: _ts(start), to: _ts(nowEnd), limit: 200);
      final list = raw['track'] is List
          ? raw['track'] as List
          : (raw['track'] != null ? [raw['track']] : const []);

      final artistCount = <String, int>{};
      final artistItem = <String, Map>{};
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
        artistItem[artistName] = t;

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

      if (artistCount.isNotEmpty) {
        final top = artistCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
        data.topArtist = artistItem[top.key];
        data.topArtistPlays = top.value;
      }
      if (trackCount.isNotEmpty) {
        final top = trackCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
        data.topTrack = trackItem[top.key];
        data.topTrackPlays = top.value;
      }

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
        widget.service.getTopArtists(period: apiPeriod, limit: 1),
        widget.service.getTopTracks(period: apiPeriod, limit: 1),
        widget.service.getTopAlbums(period: apiPeriod, limit: 1),
      ]);
      final topArtists = topLists[0];
      final topTracks = topLists[1];
      final topAlbums = topLists[2];
      if (topArtists.isNotEmpty) {
        data.topArtist = topArtists[0] as Map;
        data.topArtistPlays =
            int.tryParse((data.topArtist!['playcount'] ?? '0').toString()) ?? 0;
      }
      if (topTracks.isNotEmpty) {
        data.topTrack = topTracks[0] as Map;
        data.topTrackPlays =
            int.tryParse((data.topTrack!['playcount'] ?? '0').toString()) ?? 0;
      }
      if (topAlbums.isNotEmpty) {
        data.topAlbum = topAlbums[0] as Map;
        data.topAlbumPlays =
            int.tryParse((data.topAlbum!['playcount'] ?? '0').toString()) ?? 0;
      }

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

  // Small helper: best image url from a Last.fm 'image' list.
  String _img(dynamic images) {
    if (images is! List || images.isEmpty) return '';
    final entry = images.lastWhere(
        (i) => i is Map && i['size'] == 'extralarge',
        orElse: () => images.last);
    return (entry is Map ? entry['#text'] ?? '' : '').toString();
  }

  String _artistOf(Map? item) {
    if (item == null) return '';
    final a = item['artist'];
    if (a is Map) return (a['#text'] ?? a['name'] ?? '').toString();
    return (a ?? '').toString();
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  void _go(int p) {
    if (p < 0 || p > 2) return;
    setState(() => _period = p);
    _load(p);
  }

  @override
  Widget build(BuildContext context) {
    final d = _data[_period];
    final labels = [L.recapDay, L.recapWeek, L.recapMonth];
    final gradient = _gradients[_period];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                        color: Colors.white.withValues(alpha: i == _period ? 0.95 : 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              })),
            ),
            // Header: close + period label
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(labels[_period],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ]),
            ),
            Expanded(
              child: d.loading && !d.loaded
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _body(context, d),
            ),
            // Prev / next controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(children: [
                _navBtn(Icons.chevron_left_rounded, _period > 0, () => _go(_period - 1)),
                const Spacer(),
                _navBtn(Icons.chevron_right_rounded, _period < 2, () => _go(_period + 1)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.25,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 30),
        onPressed: enabled ? onTap : null,
      ),
    );
  }

  Widget _body(BuildContext context, _RecapData d) {
    if (d.count == 0) {
      return Center(
        child: Text(L.recapNoData,
            style: const TextStyle(color: Colors.white70, fontSize: 15)),
      );
    }

    final delta = d.prevCount > 0 ? (d.count - d.prevCount) / d.prevCount * 100 : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Big scrobble count
        Text('${d.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 1,
            )),
        Row(children: [
          Text(L.recapScrobbles,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          if (delta != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 20),

        // Unique artists / tracks / avg per day
        Row(children: [
          Expanded(child: _statChip(L.recapArtists, '${d.uniqueArtists}')),
          const SizedBox(width: 10),
          Expanded(child: _statChip(L.recapTracks, '${d.uniqueTracks}')),
          const SizedBox(width: 10),
          Expanded(
              child: _statChip(L.recapAvgDay,
                  (d.count / (_period == 0 ? 1 : (_period == 1 ? 7 : 30))).toStringAsFixed(1))),
        ]),
        const SizedBox(height: 22),

        // Mini bar chart
        if (d.bars.isNotEmpty) _barChart(d),
        const SizedBox(height: 22),

        if (d.topArtist != null)
          _highlightCard(
            icon: Icons.person_rounded,
            label: L.recapTopArtist,
            title: (d.topArtist!['name'] ?? '').toString(),
            sub: '${_fmt(d.topArtistPlays)} ${L.commonPlays}',
            imageUrl: _img(d.topArtist!['image']),
          ),
        const SizedBox(height: 12),
        if (d.topTrack != null)
          _highlightCard(
            icon: Icons.music_note_rounded,
            label: L.recapTopTrack,
            title: (d.topTrack!['name'] ?? '').toString(),
            sub: _artistOf(d.topTrack).isNotEmpty
                ? '${_artistOf(d.topTrack)} · ${_fmt(d.topTrackPlays)} ${L.commonPlays}'
                : '${_fmt(d.topTrackPlays)} ${L.commonPlays}',
            imageUrl: _img(d.topTrack!['image']),
          ),
        if (d.topAlbum != null) ...[
          const SizedBox(height: 12),
          _highlightCard(
            icon: Icons.album_rounded,
            label: L.recapTopAlbum,
            title: (d.topAlbum!['name'] ?? '').toString(),
            sub: _artistOf(d.topAlbum).isNotEmpty
                ? '${_artistOf(d.topAlbum)} · ${_fmt(d.topAlbumPlays)} ${L.commonPlays}'
                : '${_fmt(d.topAlbumPlays)} ${L.commonPlays}',
            imageUrl: _img(d.topAlbum!['image']),
          ),
        ],
      ]),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }

  Widget _barChart(_RecapData d) {
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
                      color: Colors.white.withValues(alpha: 0.35 + d.bars[i] * 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d.barLabels[i],
                      style: const TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _highlightCard({
    required IconData icon,
    required String label,
    required String title,
    required String sub,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _fallbackIcon(icon))
              : _fallbackIcon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _fallbackIcon(IconData icon) => Container(
        width: 52,
        height: 52,
        color: Colors.white.withValues(alpha: 0.15),
        child: Icon(icon, color: Colors.white70, size: 24),
      );
}
