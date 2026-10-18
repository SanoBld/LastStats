// ignore_for_file: unused_import
part of 'home_screen.dart';

class _HistoryPage extends StatefulWidget {
  final LastFmService service;
  const _HistoryPage({required this.service});
  @override
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  DateTime _selectedDate = DateTime.now();
  List<dynamic> _tracks  = [];
  bool   _loading = true;
  String? _error;
  late TabController _tabController;
  int _navDirection = 0; // -1 prev, 1 next, 0 neutral

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _tracks = []; });
    try {
      final from = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final to   = from.add(const Duration(days: 1));
      final List<dynamic> all = [];
      int page = 1;
      while (true) {
        final data = await widget.service.getRecentTracks(
          limit: 200, page: page,
          from: from.millisecondsSinceEpoch ~/ 1000,
          to:   to.millisecondsSinceEpoch   ~/ 1000,
        );
        final raw   = data['track'];
        final fresh = raw is List ? raw : (raw != null ? [raw] : <dynamic>[]);
        all.addAll(fresh.where((t) => (t as Map?)?['@attr']?['nowplaying'] != 'true'));
        final totalP = int.tryParse((data['@attr'] as Map?)?['totalPages']?.toString() ?? '1') ?? 1;
        if (page >= totalP) break;
        page++;
      }
      setState(() { _tracks = all; _loading = false; _navDirection = 0; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; _navDirection = 0; });
    }
  }

  bool get _isToday {
    final n = DateTime.now();
    return _selectedDate.year == n.year && _selectedDate.month == n.month && _selectedDate.day == n.day;
  }

  void _prev()    { setState(() { _navDirection = -1; _selectedDate = _selectedDate.subtract(const Duration(days: 1)); }); _load(); }
  void _next()    { if (!_isToday) { setState(() { _navDirection = 1; _selectedDate = _selectedDate.add(const Duration(days: 1)); }); _load(); } }
  void _goToday() { final n = DateTime.now(); setState(() { _navDirection = 1; _selectedDate = DateTime(n.year, n.month, n.day); }); _load(); }

  Future<void> _pickDate() async {
    final picked = await showM3DatePicker(
      context, initial: _selectedDate,
      first: DateTime(2000), last: DateTime.now(),
      title: L.historySelectDate,
    );
    if (picked != null && mounted) { setState(() => _selectedDate = picked); _load(); }
  }

  int get _uniqueArtists {
    final known = LibraryMerge.knownSync(widget.service.username);
    final set = <String>{};
    for (final t in _tracks) {
      final name = ((t as Map)['artist']?['#text'] ?? '').toString();
      if (name.isEmpty) continue;
      final parts = LibraryMerge.splitOn
          ? LibraryMerge.artistParts(name, known, ambiguous: true) : [name];
      for (final p in parts) { set.add(LibraryMerge.active ? LibraryMerge.artistKey(p) : p); }
    }
    return set.length;
  }
  int get _uniqueAlbums  => _tracks.map((t) => (t as Map)['album']?['#text']  ?? '')
      .where((a) => (a as String).isNotEmpty).toSet().length;

  List<MapEntry<String, List<dynamic>>> get _byHour {
    final map = <String, List<dynamic>>{};
    for (final t in _tracks) {
      final uts = (t as Map)['date']?['uts']?.toString() ?? '';
      String hour = '—';
      if (uts.isNotEmpty) {
        final seconds = int.tryParse(uts);
        if (seconds != null) {
          final local = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          hour = '${((local.hour + 1) % 24).toString().padLeft(2, '0')}:00';
        }
      }
      map.putIfAbsent(hour, () => []).add(t);
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return sorted;
  }

  String _dateFmt() {
    final d = _selectedDate;
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final hasData = !_loading && _error == null && _tracks.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 2),
            child: Row(children: [
              Expanded(child:
                Text(L.historyTitle, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              IconButton.filledTonal(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
            ]),
          ),

          const SizedBox(height: 10),

          // Date navigation: connected buttons (big outer, small inner corners)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              M3TonalButton(
                width: 52,
                padding: EdgeInsets.zero,
                radius: const BorderRadius.horizontal(
                    left: Radius.circular(24), right: Radius.circular(8)),
                onTap: _prev,
                child: Icon(Icons.chevron_left_rounded, color: scheme.onSurface),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: M3TonalButton(
                  radius: BorderRadius.circular(8),
                  onTap: _pickDate,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    M3Switcher(
                      duration: M3Motion.effectsDefaultDuration,
                      child: Text(
                        _dateFmt(),
                        key: ValueKey(_dateFmt()),
                        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_month_rounded, size: 18, color: scheme.primary),
                  ]),
                ),
              ),
              // Today button grows in / out with a spring
              AnimatedSize(
                duration: M3Motion.spatialFastDuration,
                curve: M3Motion.spatialFast,
                alignment: Alignment.centerLeft,
                child: _isToday
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: M3TonalButton(
                          color: scheme.primaryContainer,
                          radius: BorderRadius.circular(8),
                          onTap: _goToday,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.today_rounded, size: 18, color: scheme.onPrimaryContainer),
                            const SizedBox(width: 6),
                            Text(L.historyToday, style: text.labelLarge?.copyWith(
                                color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
              ),
              const SizedBox(width: 2),
              M3TonalButton(
                width: 52,
                padding: EdgeInsets.zero,
                radius: const BorderRadius.horizontal(
                    left: Radius.circular(8), right: Radius.circular(24)),
                onTap: _isToday ? null : _next,
                child: Icon(Icons.chevron_right_rounded, color: scheme.onSurface),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          if (hasData) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(L.dayLabel(_selectedDate),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            SizedBox(height: 32, child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _HistStatPill(icon: Icons.headphones_rounded,
                    label: L.historyScrobbles(_tracks.length), scheme: scheme),
                const SizedBox(width: 8),
                _HistStatPill(icon: Icons.mic_rounded,
                    label: L.historyArtistsCount(_uniqueArtists), scheme: scheme),
                const SizedBox(width: 8),
                _HistStatPill(icon: Icons.album_rounded,
                    label: L.historyAlbumsCount(_uniqueAlbums), scheme: scheme),
              ],
            )),
            const SizedBox(height: 10),
            M3TabSwitch(
              controller: _tabController,
              labels: [L.historyChronological, L.historyList, L.historyStats],
              icons: const [Icons.timeline_rounded, Icons.view_list_rounded, Icons.bar_chart_rounded],
            ),
          ],

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve:  M3Motion.emphasizedDecelerate,
              switchOutCurve: M3Motion.emphasizedAccelerate,
              transitionBuilder: (child, anim) {
                final dir = _navDirection;
                final slideIn = Tween<Offset>(
                  begin: Offset(dir == 0 ? 0.0 : dir < 0 ? -0.22 : 0.22, 0),
                  end:   Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: M3Motion.emphasizedDecelerate));
                return SlideTransition(position: slideIn,
                    child: FadeTransition(opacity: anim, child: child));
              },
              child: _loading
                ? const Center(key: ValueKey('hist_load'), child: M3LoadingIndicator())
                : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : _tracks.isEmpty
                    ? Center(
                        key: ValueKey('hist_empty_$_selectedDate'),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.music_off_rounded, size: 48,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.35)),
                          const SizedBox(height: 12),
                          Text(L.historyNoTracks,
                              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        ]))
                    : TabBarView(
                        key: ValueKey('hist_tabs_$_selectedDate'),
                        controller: _tabController,
                        children: [
                          _HistChronView(tracks: _tracks, byHour: _byHour, service: widget.service),
                          _HistListeView(tracks: _tracks, service: widget.service),
                          _HistStatsView(tracks: _tracks),
                        ],
                      ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Tap-scale feedback (press animation) ────────────────────────────────────
// ── Stat pill ────────────────────────────────────────────────────────────────
class _HistStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;
  const _HistStatPill({required this.icon, required this.label, required this.scheme});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: scheme.primary,
      borderRadius: AppRadius.xlR,
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: scheme.onPrimary),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: scheme.onPrimary)),
    ]),
  );
}

// ── Timestamp helpers ────────────────────────────────────────────────────────
DateTime? _localDateTimeFromTrack(Map t) {
  final uts = t['date']?['uts']?.toString() ?? '';
  if (uts.isEmpty) return null;
  final seconds = int.tryParse(uts);
  if (seconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}

String _localTimeString(Map t) {
  final dt = _localDateTimeFromTrack(t);
  if (dt == null) return '';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Chronological view ───────────────────────────────────────────────────────
class _HistChronView extends StatelessWidget {
  final List<dynamic> tracks;
  final List<MapEntry<String, List<dynamic>>> byHour;
  final LastFmService service;
  const _HistChronView({required this.tracks, required this.byHour, required this.service});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: byHour.length,
        itemBuilder: (_, i) {
          final entry   = byHour[i];
          final hour    = entry.key;
          final hTracks = entry.value;
          final n = hTracks.length;
          final trackWord = L.historyHourTracks;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (i > 0) const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18), bottomRight: Radius.circular(18),
                        topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
                  ),
                  child: Text(hour, style: text.titleSmall?.copyWith(
                      color: scheme.onPrimary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
                const SizedBox(width: 10),
                Text('$n $trackWord${n > 1 ? 's' : ''}',
                    style: text.labelMedium?.copyWith(
                        color: scheme.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
            for (final (i, t) in hTracks.indexed)
              _FadeSlideIn(
                delay: Duration(milliseconds: (i * 20).clamp(0, 200)),
                child: _HistTrackRow(track: t as Map, time: _localTimeString(t), service: service),
              ),
            const SizedBox(height: 6),
          ]);
        },
      ),
    );
  }
}

// ── Track row ────────────────────────────────────────────────────────────────
class _HistTrackRow extends StatelessWidget {
  final Map track;
  final String time;
  final LastFmService service;
  const _HistTrackRow({required this.track, required this.time, required this.service});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final tit    = (track['name']             ?? '').toString();
    final art    = (track['artist']?['#text'] ?? '').toString();
    final alb    = (track['album']?['#text']  ?? '').toString();
    final raw    = _extractImage(track['image']);

    return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
     child: Material(
      color: Color.lerp(scheme.primaryContainer, scheme.surface, 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
      onTap: () {
        _haptic(_HapticImpact.light);
        showDetailSheet(
          context,
          {'name': tit, 'artist': {'name': art}, 'album': {'title': alb}, 'image': track['image']},
          'tracks',
          service,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          SizedBox(width: 40,
            child: Text(time, style: text.labelSmall?.copyWith(
                color: scheme.primary, fontWeight: FontWeight.w800))),
          const SizedBox(width: 8),
          _SmartImage(size: 44, borderRadius: 14, initialUrl: raw,
              resolver: () => ImageService.resolveTrack(tit, art, lastfmUrl: raw.isNotEmpty ? raw : null)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tit, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(art, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            if (alb.isNotEmpty) Row(children: [
              Icon(Icons.album_rounded, size: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
              const SizedBox(width: 3),
              Expanded(child: Text(alb, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                      fontSize: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)))),
            ]),
          ])),
        ]),
      ),
    )));
  }
}

// ── List view ─────────────────────────────────────────────────────────────────
class _HistListeView extends StatelessWidget {
  final List<dynamic> tracks;
  final LastFmService service;
  const _HistListeView({required this.tracks, required this.service});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: tracks.length,
      itemBuilder: (_, i) {
        final t   = tracks[i] as Map;
        final tit = (t['name']             ?? '').toString();
        final art = (t['artist']?['#text'] ?? '').toString();
        final alb = (t['album']?['#text']  ?? '').toString();
        final raw = _extractImage(t['image']);
        final timeOnly = _localTimeString(t);
        return _FadeSlideIn(
          delay: Duration(milliseconds: (i * 20).clamp(0, 200)),
          child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
         // Own Material: a ListTile's tileColor is painted on the page's
         // Material and bled out of the scrolling list over the header.
         child: Material(
          color: Color.lerp(scheme.primaryContainer, scheme.surface, 0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: _SmartImage(size: 44, borderRadius: 14, initialUrl: raw,
              resolver: () => ImageService.resolveTrack(tit, art, lastfmUrl: raw.isNotEmpty ? raw : null)),
          title: Text(tit, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(alb.isNotEmpty ? '$art · $alb' : art,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          trailing: Text(timeOnly,
              style: text.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800)),
          onTap: () {
            _haptic(_HapticImpact.light);
            showDetailSheet(
              context,
              {'name': tit, 'artist': {'name': art}, 'album': {'title': alb}, 'image': t['image']},
              'tracks',
              service,
            );
          },
        ))));
      },
    );
  }
}

// ── Stats view ────────────────────────────────────────────────────────────────
class _HistStatsView extends StatelessWidget {
  final List<dynamic> tracks;
  const _HistStatsView({required this.tracks});

  Map<String, int> _count(Iterable<String> keys) {
    final map = <String, int>{};
    for (final k in keys) { if (k.isNotEmpty) map[k] = (map[k] ?? 0) + 1; }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(10));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final artists = _count(tracks.map((t) => (t as Map)['artist']?['#text']?.toString() ?? ''));
    final albums  = _count(tracks.map((t) => (t as Map)['album']?['#text']?.toString()  ?? ''));
    final tTracks = _count(tracks.map((t) => (t as Map)['name']?.toString()             ?? ''));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _HistStatSection(title: L.historyTopArtists, icon: Icons.mic_rounded,
            data: artists, scheme: scheme, text: text),
        const SizedBox(height: 20),
        _HistStatSection(title: L.historyTopAlbums, icon: Icons.album_rounded,
            data: albums, scheme: scheme, text: text),
        const SizedBox(height: 20),
        _HistStatSection(title: L.historyTopTracks, icon: Icons.music_note_rounded,
            data: tTracks, scheme: scheme, text: text),
      ],
    );
  }
}

class _HistStatSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, int> data;
  final ColorScheme scheme;
  final TextTheme text;
  const _HistStatSection({required this.title, required this.icon,
      required this.data, required this.scheme, required this.text});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList();
    final max = entries.first.value;
    final first = entries.first;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ChartHead(title: title, icon: icon),
      const SizedBox(height: 12),
      Container(
        decoration: _chartCardDecoration(scheme, scheme.secondaryContainer),
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          // #1 hero
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(
                width: 36, height: 36, alignment: Alignment.center,
                decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                child: Text('1', style: text.titleSmall?.copyWith(
                    color: scheme.onPrimary, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(first.key, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                      color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: scheme.tertiaryContainer, borderRadius: AppRadius.xlR),
                child: Text('${first.value}×', style: text.labelMedium?.copyWith(
                    color: scheme.onTertiaryContainer, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          for (var i = 1; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
              child: Row(children: [
                Container(
                  width: 26, height: 26, alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entries[i].key, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: max > 0 ? entries[i].value / max : 0),
                    duration: const Duration(milliseconds: 600),
                    curve: M3Motion.emphasizedDecelerate,
                    builder: (_, v, _) => LayoutBuilder(builder: (_, c) => Stack(children: [
                      Container(height: 8, decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4))),
                      Container(
                        height: 8, width: math.max(8.0, c.maxWidth * v),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(colors: [
                            scheme.primary.withValues(alpha: 0.45), scheme.primary])),
                      ),
                    ])),
                  ),
                ])),
                const SizedBox(width: 12),
                Text('${entries[i].value}×', style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
