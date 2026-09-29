// ignore_for_file: unused_import
part of 'home_screen.dart';


class _RankingsPage extends StatefulWidget {
  final LastFmService service;
  const _RankingsPage({required this.service});

  @override
  State<_RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<_RankingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final String _period       = 'overall';
  int    _selectedMonth = 0; // 0 = whole year, 1-12 = specific month — only used with a year
  int?   _selectedYear;          // null = use period chips; int = year filter
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    localeNotifier.addListener(_rebuild);
    AllScrobblesService.progressNotifier.addListener(_onHistoryProgress);
    _refreshAvailableYears();
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    AllScrobblesService.progressNotifier.removeListener(_onHistoryProgress);
    _tabs.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onHistoryProgress() {
    if (!mounted) return;
    _refreshAvailableYears();
  }

  void _refreshAvailableYears() {
    final years = AllScrobblesService.getCachedYears().toList()..sort((a, b) => b.compareTo(a));
    if (mounted) setState(() => _availableYears = years);
  }

  // Bottom sheet: years then months, animated chips in a wrap.
  Future<void> _pickDate(BuildContext context) async {
    _haptic(_HapticImpact.selection);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sh) => StatefulBuilder(builder: (sh, setSheet) {
        final scheme = Theme.of(sh).colorScheme;
        final text   = Theme.of(sh).textTheme;
        Widget title(String t) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(t, style: text.titleSmall?.copyWith(
                  color: scheme.primary, fontWeight: FontWeight.w700)),
            );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              title(L.rankingsAllYears),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final y in [0, ..._availableYears])
                  M3Chip(
                    label: Text(y == 0 ? L.rankingsAllYears : '$y'),
                    selected: y == 0 ? _selectedYear == null : y == _selectedYear,
                    onSelected: (_) {
                      _haptic(_HapticImpact.selection);
                      setState(() {
                        _selectedYear = y == 0 ? null : y;
                        _selectedMonth = 0;
                      });
                      setSheet(() {});
                    },
                  ),
              ]),
              AnimatedSize(
                duration: M3Motion.spatialFastDuration,
                curve: M3Motion.spatialFast,
                alignment: Alignment.topCenter,
                child: _selectedYear == null
                    ? const SizedBox(width: double.infinity)
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        title(L.rankingsWholeYear),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final m in [0, ...List.generate(12, (i) => i + 1)])
                            M3Chip(
                              label: Text(m == 0 ? L.rankingsWholeYear : L.months[m]),
                              selected: m == _selectedMonth,
                              onSelected: (_) {
                                _haptic(_HapticImpact.selection);
                                setState(() => _selectedMonth = m);
                                setSheet(() {});
                              },
                            ),
                        ]),
                      ]),
              ),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 2),
            child: Row(children: [
              Expanded(
                child: Text(L.rankingsTitle,
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              // Opens a Material You sheet to pick the date
              M3Chip(
                avatar: const Icon(Icons.calendar_month_rounded),
                label: Text(_selectedYear == null
                    ? L.rankingsAllYears
                    : (_selectedMonth == 0
                        ? '$_selectedYear'
                        : '${L.months[_selectedMonth]} $_selectedYear')),
                selected: _selectedYear != null,
                onSelected: (_) => _pickDate(context),
              ),
            ]),
          ),
          const SizedBox(height: 10),

          // Year selector — same FilterChip row, same place as the Charts tab
          if (_availableYears.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  // Android-style stretch at the edges, not the iOS rubber-band bounce.
                  physics: const ClampingScrollPhysics(),
                  children: [0, ..._availableYears].map((year) {
                    final selected = year == 0 ? _selectedYear == null : year == _selectedYear;
                    final label    = year == 0 ? L.rankingsAllYears : '$year';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: M3Chip(
                        label: Text(label),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) {
                          _haptic(_HapticImpact.selection);
                          setState(() => _selectedYear = year == 0 ? null : year);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Month selector — only shown for a specific selected year.
          if (_selectedYear != null)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                children: [0, ...List.generate(12, (i) => i + 1)].map((m) {
                  final sel   = m == _selectedMonth;
                  final label = m == 0 ? L.rankingsWholeYear : L.months[m];
                  return Padding(padding: const EdgeInsets.only(right: 8),
                    child: M3Chip(label: Text(label), selected: sel, showCheckmark: false,
                        onSelected: (_) { if (!sel) { _haptic(_HapticImpact.selection); setState(() => _selectedMonth = m); } }));
                }).toList(),
              ),
            ),

          TabBar(controller: _tabs, tabs: [
            Tab(text: L.commonArtists),
            Tab(text: L.commonAlbums),
            Tab(text: L.commonTracks),
          ]),
          Expanded(child: TabBarView(controller: _tabs, children: [
            _TopListBody(service: widget.service, type: 'artists',
                period: _period, year: _selectedYear, month: _selectedMonth),
            _TopListBody(service: widget.service, type: 'albums',
                period: _period, year: _selectedYear, month: _selectedMonth),
            _TopListBody(service: widget.service, type: 'tracks',
                period: _period, year: _selectedYear, month: _selectedMonth),
          ])),
        ]),
      ),
    );
  }
}

class _TopListBody extends StatefulWidget {
  final LastFmService service;
  final String type, period;
  final int?   year;           // null = API; int = local cached scrobbles
  final int    month;          // 0 = whole year, 1-12 = specific month — only used when year != null
  const _TopListBody({required this.service, required this.type,
      required this.period, this.year, this.month = 0});

  @override
  State<_TopListBody> createState() => _TopListBodyState();
}

class _TopListBodyState extends State<_TopListBody>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _items = [];
  bool _loading = true, _loadingMore = false, _exhausted = false;
  String? _error;
  int _page = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(reset: true); }

  @override
  void didUpdateWidget(_TopListBody old) {
    super.didUpdateWidget(old);
    if (old.period != widget.period ||
        old.type   != widget.type   ||
        old.year   != widget.year   ||
        old.month  != widget.month) { _load(reset: true); }
  }

  // Compute top items from locally-cached scrobbles for a given year.
  Future<List<Map<String, dynamic>>> _computeLocalTop(int year) async {
    var records = AllScrobblesService.getRecordsForYear(year) ?? [];
    if (widget.month != 0) {
      records = records.where((r) =>
          DateTime.fromMillisecondsSinceEpoch(r.ts * 1000).month == widget.month).toList();
    }
    if (records.isEmpty) {
      return [];
    }

    // Honours the "link versions" / "split collabs" options.
    if (LibraryMerge.active) await LibraryMerge.ensureKnown(widget.service, null);
    final tally = LocalTally(LibraryMerge.knownSync(widget.service.username));
    for (final r in records) {
      switch (widget.type) {
        case 'artists':
          if (r.artist.isEmpty) continue;
          tally.addScrobble('artists', name: r.artist, artist: '');
        case 'albums':
          if (r.album.isEmpty && r.artist.isEmpty) continue;
          tally.addScrobble('albums', name: r.album, artist: r.artist);
        default: // tracks
          if (r.track.isEmpty && r.artist.isEmpty) continue;
          tally.addScrobble('tracks', name: r.track, artist: r.artist);
      }
    }

    return tally.sorted().map((e) {
      final playcount = e.plays.toString();
      if (widget.type == 'artists') {
        return <String, dynamic>{'name': e.name, 'playcount': playcount, 'image': <dynamic>[]};
      }
      return <String, dynamic>{
        'name':      e.name,
        'playcount': playcount,
        'image':     <dynamic>[],
        'artist':    {'name': e.artist},
      };
    }).toList();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true; _error = null;
        _page = 1; _exhausted = false; _items = [];
      });
    } else {
      if (_loadingMore || _exhausted) return;
      setState(() => _loadingMore = true);
    }
    try {
      List<dynamic> fresh;
      if (widget.year != null) {
        // Year mode: compute locally (all at once, no pagination)
        fresh      = await _computeLocalTop(widget.year!);
        _exhausted = true;
      } else {
        switch (widget.type) {
          case 'artists':
            fresh = await widget.service.getTopArtists(
                period: widget.period, limit: 50, page: _page); break;
          case 'albums':
            fresh = await widget.service.getTopAlbums(
                period: widget.period, limit: 50, page: _page); break;
          default:
            fresh = await widget.service.getTopTracks(
                period: widget.period, limit: 50, page: _page);
        }
      }
      if (mounted) {
        setState(() {
          _items.addAll(fresh);
          if (widget.year == null) _exhausted = fresh.length < 50;
          _loading = false; _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false; _loadingMore = false;
        });
      }
    }
  }

  void _showDetail(BuildContext ctx, Map<String, dynamic> item) =>
      showDetailSheet(ctx, item, widget.type, widget.service);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    if (_loading || _error != null || _items.isEmpty) {
      return M3Switcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
          ? const SkeletonList(key: ValueKey('rank_load'))
          : _error != null
            ? _ErrorView(message: _error!, onRetry: () => _load(reset: true))
            : Center(key: const ValueKey('rank_empty'), child: Text(L.commonNoResults,
                style: TextStyle(color: scheme.onSurfaceVariant))),
      );
    }

    return M3Switcher(
      duration: const Duration(milliseconds: 300),
      child: NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!_exhausted && !_loadingMore && n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_exhausted && !_loadingMore) { _page++; _load(); }
          });
        }
        return false;
      },
      child: CustomScrollView(slivers: [
        if (_items.length >= 3)
          SliverToBoxAdapter(
            // Keyed on the actual podium names: without this, Flutter can
            // reuse the previous podium's image widgets when a filter swaps
            // in different people at the same 3 positions, so the photos
            // stayed stuck on the old names. A fresh key forces a clean
            // rebuild (and fresh image fetch) every time the top 3 change.
            key: ValueKey('podium_${widget.type}_${widget.year}_${widget.month}_'
                '${_items.take(3).map((e) => (e as Map)['name']).join('|')}'),
            child: _PodiumWidget(
              items: _items.take(3).toList(), type: widget.type,
              onTap: (item) { _haptic(_HapticImpact.light); _showDetail(context, item as Map<String, dynamic>); }),
          ),

        SliverList(delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final items = _items;
            final off = items.length >= 3 ? 3 : 0;
            final idx = i + off;
            if (idx >= items.length) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _loadingMore
                  ? const Padding(key: ValueKey('more'), padding: EdgeInsets.all(16),
                      child: Center(child: M3LoadingIndicator()))
                  : const SizedBox.shrink(),
              );
            }
            final item   = items[idx] as Map<String, dynamic>;
            final name   = (item['name'] ?? '').toString();
            final plays  = _fmt(int.tryParse((item['playcount'] ?? '0').toString()) ?? 0);
            final artist = (item['artist']?['name'] ?? '').toString();
            final raw    = _extractImage(item['image']);
            Future<String> imgF;
            switch (widget.type) {
              case 'artists': imgF = ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              case 'albums':  imgF = ImageService.resolveAlbum(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              default:        imgF = ImageService.resolveTrack(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null);
            }
            return InkWell(
              key: ValueKey('rank_row_${widget.type}_${idx}_$name'),
              onTap: () { _haptic(_HapticImpact.light); _showDetail(ctx, item); },
              borderRadius: AppRadius.smR,
              child: _FadeSlideIn(
                // Stagger each item slightly for a cascade effect
                delay: Duration(milliseconds: (idx * 25).clamp(0, 250)),
                child: _ItemTile(
                name: name, imageUrl: raw, imageFuture: imgF, rank: '${idx + 1}',
                sub:   widget.type != 'artists' ? '$artist · $plays ${L.commonPlays}' : '$plays ${L.commonPlays}',
                plays: null,
              ),
              ), // _FadeSlideIn
            );
          },
          childCount: (_items.length >= 3 ? _items.length - 3 : _items.length) + 1,
        )),
      ]),
    ),  // NotificationListener
    ); // AnimatedSwitcher
  }
}

// ── Podium ───────────────────────────────────────────────────────────────────

class _PodiumWidget extends StatelessWidget {
  final List<dynamic> items;
  final String type;
  final void Function(dynamic) onTap;
  const _PodiumWidget({required this.items, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    // Same podium as the recap: shaped avatar with a rank badge, text
    // under it, then a tonal bar (2nd left, 1st middle, 3rd right).
    const order   = [1, 0, 2];
    const heights = [96.0, 128.0, 78.0];
    const imgSz   = [56.0, 68.0, 48.0];
    final barColors = [scheme.secondaryContainer, scheme.primaryContainer, scheme.tertiaryContainer];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(title: L.rankingsPodium, icon: Icons.emoji_events_rounded),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (col) {
            final di   = order[col];
            final item = items[di] as Map<String, dynamic>;
            final name = (item['name'] ?? '').toString();
            final art  = type != 'artists' ? (item['artist']?['name'] ?? '').toString() : '';
            final plays = _fmt(int.tryParse((item['playcount'] ?? '0').toString()) ?? 0);
            final raw  = _extractImage(item['image']);
            Future<String> imgF;
            switch (type) {
              case 'artists': imgF = ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              case 'albums':  imgF = ImageService.resolveAlbum(name, art, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              default:        imgF = ImageService.resolveTrack(name, art, lastfmUrl: raw.isNotEmpty ? raw : null);
            }

            return Expanded(child: _PressScale(
              onTap: () { _haptic(_HapticImpact.light); onTap(item); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Stack(clipBehavior: Clip.none, children: [
                    M3ShapedBox(
                      key: ValueKey('podium_img_${type}_$name'),
                      size: imgSz[col],
                      shapeIndex: col == 0 ? 0 : (col == 1 ? 2 : 7),
                      child: _SmartImage(size: imgSz[col], borderRadius: 0,
                          initialUrl: raw, resolver: () => imgF),
                    ),
                    Positioned(
                      right: -2, bottom: -2,
                      child: Container(
                        width: 22, height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        child: Text('${di + 1}',
                            style: TextStyle(color: scheme.onPrimary,
                                fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
                  if (art.isNotEmpty)
                    Text(art, maxLines: 1, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
                  Text('$plays ${L.commonPlays}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
                  const SizedBox(height: 8),
                  // Bar grows up from 0 on first render
                  TweenAnimationBuilder<double>(
                    tween:    Tween(begin: 0.0, end: heights[col]),
                    duration: Duration(milliseconds: 550 + col * 80),
                    curve:    M3Motion.emphasizedDecelerate,
                    builder: (_, h, child) => SizedBox(height: h, child: child),
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColors[di],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ),
            ));
          }),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
          child: Text(L.rankingsContinued,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}