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
  String _period       = 'overall';
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

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final text    = Theme.of(context).textTheme;
    final periods = _localizedPeriods();

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(children: [
              Expanded(
                child: Text(L.rankingsTitle,
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              // Year dropdown — only shown when cached years exist
              if (_availableYears.isNotEmpty)
                _YearDropdown(
                  years:        _availableYears,
                  selectedYear: _selectedYear,
                  scheme:       scheme,
                  text:         text,
                  onChanged: (y) => setState(() {
                    _selectedYear = y;
                  }),
                ),
            ]),
          ),

          // Period chips — hidden when a year is selected (local data used instead)
          if (_selectedYear == null)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                children: periods.map((p) {
                  final sel = p.$1 == _period;
                  return Padding(padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(label: Text(p.$2), selected: sel,
                        onSelected: (_) { if (!sel) setState(() => _period = p.$1); }));
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
                period: _period, year: _selectedYear),
            _TopListBody(service: widget.service, type: 'albums',
                period: _period, year: _selectedYear),
            _TopListBody(service: widget.service, type: 'tracks',
                period: _period, year: _selectedYear),
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
  const _TopListBody({required this.service, required this.type,
      required this.period, this.year});

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
        old.year   != widget.year) _load(reset: true);
  }

  // Decode common HTML entities returned by Last.fm's API.
  static String _decode(String s) => s
      .replaceAll('&amp;',  '&')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;',  "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;',   '<')
      .replaceAll('&gt;',   '>');

  // Compute top items from locally-cached scrobbles for a given year.
  Future<List<Map<String, dynamic>>> _computeLocalTop(int year) async {
    final records = AllScrobblesService.getRecordsForYear(year) ?? [];
    if (records.isEmpty) {
      return [];
    }

    final counts   = <String, int>{};
    final artistOf = <String, String>{}; // key → artist name

    for (final r in records) {
      // Decode HTML entities so names display correctly and image lookups work
      final artist = _decode(r.artist);
      final album  = _decode(r.album);
      final track  = _decode(r.track);

      final String key;
      switch (widget.type) {
        case 'artists':
          key = artist;
        case 'albums':
          key = '$album|||$artist';
          artistOf[key] = artist;
        default: // tracks
          key = '$track|||$artist';
          artistOf[key] = artist;
      }
      if (key.isEmpty || key.startsWith('|||')) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) {
      final playcount = e.value.toString();
      if (widget.type == 'artists') {
        return {'name': e.key, 'playcount': playcount, 'image': <dynamic>[]};
      }
      final parts  = e.key.split('|||');
      final name   = parts[0];
      final artist = parts.length > 1 ? parts[1] : '';
      return {
        'name':      name,
        'playcount': playcount,
        'image':     <dynamic>[],
        'artist':    {'name': artist},
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

    if (_loading) { return const Center(child: CircularProgressIndicator()); }
    if (_error != null) { return _ErrorView(message: _error!, onRetry: () => _load(reset: true)); }
    if (_items.isEmpty) {
      return Center(child: Text(L.commonNoResults,
        style: TextStyle(color: scheme.onSurfaceVariant)));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!_exhausted && !_loadingMore && n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          _page++; _load();
        }
        return false;
      },
      child: CustomScrollView(slivers: [
        if (_items.length >= 3)
          SliverToBoxAdapter(child: _PodiumWidget(
              items: _items.take(3).toList(), type: widget.type,
              onTap: (item) => _showDetail(context, item as Map<String, dynamic>))),

        SliverList(delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final off = _items.length >= 3 ? 3 : 0;
            final idx = i + off;
            if (idx >= _items.length) {
              return _loadingMore ? const Padding(padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator())) : const SizedBox.shrink();
            }
            final item   = _items[idx] as Map<String, dynamic>;
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
              onTap: () => _showDetail(ctx, item),
              borderRadius: BorderRadius.circular(8),
              child: _FadeSlideIn(
                // Stagger each item slightly for a cascade effect
                delay: Duration(milliseconds: (idx * 25).clamp(0, 250)),
                child: _ItemTile(
                name: name, imageUrl: raw, imageFuture: imgF, rank: '${idx + 1}',
                sub:   widget.type != 'artists' ? '$artist · $plays ${L.commonPlays}' : '$plays ${L.commonPlays}',
                plays: widget.type != 'artists' ? plays : null,
              ),
              ), // _FadeSlideIn
            );
          },
          childCount: (_items.length >= 3 ? _items.length - 3 : _items.length) + 1,
        )),
      ]),
    );
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

    const order   = [1, 0, 2];
    const heights = [100.0, 130.0, 80.0];
    const medals  = ['🥈', '🥇', '🥉'];
    const imgSz   = [54.0, 68.0, 46.0];

    final podiumColors = [
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.primaryContainer,   scheme.onPrimaryContainer),
      (scheme.tertiaryContainer,  scheme.onTertiaryContainer),
    ];

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
            final raw  = _extractImage(item['image'], large: true);
            Future<String> imgF;
            switch (type) {
              case 'artists': imgF = ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              case 'albums':  imgF = ImageService.resolveAlbum(name, art, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              default:        imgF = ImageService.resolveTrack(name, art, lastfmUrl: raw.isNotEmpty ? raw : null);
            }
            final (podC, podOn) = podiumColors[di];

            return Expanded(child: GestureDetector(
              onTap: () => onTap(item),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(imgSz[col] / 4),
                  child: _SmartImage(size: imgSz[col], borderRadius: imgSz[col] / 4,
                      initialUrl: raw, resolver: () => imgF),
                ),
                const SizedBox(height: 5),
                Text(medals[col], style: TextStyle(fontSize: di == 0 ? 22 : 18)),
                const SizedBox(height: 3),
                // Bar grows up from 0 on first render
                TweenAnimationBuilder<double>(
                  tween:    Tween(begin: 0.0, end: heights[col]),
                  duration: Duration(milliseconds: 550 + col * 80),
                  curve:    Curves.easeOutCubic,
                  builder: (_, h, child) => SizedBox(height: h, child: child),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: podC,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border(
                        top:   BorderSide(color: podOn.withValues(alpha: 0.15), width: 1),
                        left:  BorderSide(color: podOn.withValues(alpha: 0.15), width: 1),
                        right: BorderSide(color: podOn.withValues(alpha: 0.15), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.all(7),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: podOn.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('#${di + 1}', style: text.labelSmall?.copyWith(
                            color: podOn, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 3),
                      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: text.bodySmall?.copyWith(
                              color: podOn, fontWeight: FontWeight.w700, fontSize: di == 0 ? 11 : 10)),
                      if (heights[col] >= 100) ...[
                        const SizedBox(height: 2),
                        Text(plays, style: text.bodySmall
                            ?.copyWith(color: podOn.withValues(alpha: 0.65), fontSize: 9)),
                      ],
                    ]),
                  ),
                ),
              ]),
            ));
          }),
        ),
        const SizedBox(height: 12),
        Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
          child: Text(L.rankingsContinued,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}

// ── Year selector dropdown ─────────────────────────────────────────────────────

class _YearDropdown extends StatelessWidget {
  final List<int>   years;
  final int?        selectedYear;
  final ColorScheme scheme;
  final TextTheme   text;
  final void Function(int?) onChanged;

  const _YearDropdown({
    required this.years,
    required this.selectedYear,
    required this.scheme,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: selectedYear != null
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value:       selectedYear,
          isDense:     true,
          icon: Icon(Icons.arrow_drop_down_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          style: text.labelMedium?.copyWith(
            color:      selectedYear != null
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          hint: Text(L.rankingsAllYears,
              style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          onChanged: onChanged,
          items: [
            // "All years" option resets to null (period chips)
            DropdownMenuItem<int?>(
              value: null,
              child: Text(L.rankingsAllYears,
                  style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            ...years.map((y) => DropdownMenuItem<int?>(
              value: y,
              child: Text('$y',
                  style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            )),
          ],
        ),
      ),
    );
  }
}