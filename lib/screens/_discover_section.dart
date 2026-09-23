// lib/screens/_discover_section.dart
// ══════════════════════════════════════════════════════════════════════════
//  Dashboard "Discover": swipeable music ideas.
//    1. "For you" (personal) — built by our own TasteEngine from YOUR
//       listening data (see services/taste_engine.dart): your mix, this
//       month, your genres, deep cuts, forgotten favorites, albums, and
//       your country.
//    2. "Global trends" — real week / month / year charts (tracks, artists,
//       albums) from ListenBrainz (see services/listenbrainz_service.dart),
//       because Last.fm's chart endpoints have no time range.
//  Images use the Material You shapes. Section and sources are set in
//  Settings > Dashboard.
//
//  Notes:
//   - Cards are capped to a max width so the section stays readable on
//     wide (desktop) screens instead of stretching to a huge size.
//   - Each card carries a small count badge (plays / listens) in a
//     rectangular shape; shapes vary per card but are never circular, so
//     the text always fits inside.
//   - Every state change here (_select) is defensive: it never lets an
//     exception escape mid-build, because an uncaught error here used to
//     surface as a plain grey box (Flutter's release-mode ErrorWidget)
//     that only "fixed itself" once the user tapped something else and
//     forced a fresh rebuild.
// ══════════════════════════════════════════════════════════════════════════
part of 'home_screen.dart';

const _kDiscoverPersonal = ['foryou', 'onthisday', 'fresh', 'genre', 'deeper', 'forgotten', 'albums', 'country'];
// gt = tracks, ga = artists, gb = albums  ·  week / month / year
const _kDiscoverGlobal = [
  'gt_week', 'gt_month', 'gt_year',
  'ga_week', 'ga_month', 'ga_year',
  'gb_week', 'gb_month', 'gb_year',
];
const _kDiscoverAll = [..._kDiscoverPersonal, ..._kDiscoverGlobal];
// What a fresh install shows (the rest can be enabled in Settings).
const _kDiscoverDefault = [
  ..._kDiscoverPersonal, 'gt_week', 'gt_month', 'ga_week', 'ga_month',
];

/// Converts a saved source list from an older version: legacy ids are
/// mapped to their new equivalent and unknown ids are dropped.
List<String> _discoverMigrate(List<String> saved) {
  const legacy = {
    'community': ['gt_week', 'gt_month'],
    'artists':   ['ga_week', 'ga_month'],
  };
  final out = <String>[];
  for (final id in saved) {
    for (final n in (legacy[id] ?? [id])) {
      if (_kDiscoverAll.contains(n) && !out.contains(n)) out.add(n);
    }
  }
  return out;
}

// Cards never grow past this width, even on very wide desktop windows.
const double _kDiscoverMaxWidth = 640;
// Items fetched per source (was 15 — bumped so "for you" / "trends" have
// more variety to swipe through).
const int _kDiscoverFetchLimit = 24;

class _DiscoverItem {
  final String name, sub, imageUrl, type;
  final String artist; // real artist name (tracks / albums); sub is display text
  final Map<String, dynamic> raw;
  const _DiscoverItem(this.name, this.sub, this.imageUrl, this.type, this.raw,
      {this.artist = ''});

  int get playcount => int.tryParse((raw['playcount'] ?? '0').toString()) ?? 0;
}

class _DiscoverSection extends StatelessWidget {
  final LastFmService service;
  final String topArtist, country;
  final List<String> sources;
  final bool infiniteScroll;
  final bool smartOrder;      // most relevant filter first
  final List<String> soloSources; // filters shown on their own row
  const _DiscoverSection({
    required this.service,
    required this.topArtist,
    required this.country,
    required this.sources,
    this.infiniteScroll = false,
    this.smartOrder = false,
    this.soloSources = const [],
  });

  static IconData _soloIcon(String s) => switch (s) {
        'foryou'    => Icons.auto_awesome_rounded,
        'onthisday' => Icons.history_rounded,
        'fresh'     => Icons.calendar_month_rounded,
        'genre'     => Icons.category_rounded,
        'deeper'    => Icons.travel_explore_rounded,
        'forgotten' => Icons.replay_rounded,
        'albums'    => Icons.album_rounded,
        'country'   => Icons.flag_rounded,
        _           => Icons.public_rounded,
      };

  // Follows the user's saved order (Settings > Dashboard > filters).
  List<String> _avail(List<String> group) => [
        for (final s in sources)
          if (group.contains(s) &&
              !(s == 'country' && (country.isEmpty || country == 'None')) &&
              !(const {'foryou', 'fresh', 'genre', 'deeper', 'albums'}.contains(s) &&
                  topArtist.isEmpty))
            s
      ];

  @override
  Widget build(BuildContext context) {
    final all      = _avail(_kDiscoverAll);
    final solo     = [for (final s in all) if (soloSources.contains(s)) s];
    final personal = _avail(_kDiscoverPersonal).where((s) => !solo.contains(s)).toList();
    final global   = _avail(_kDiscoverGlobal).where((s) => !solo.contains(s)).toList();
    if (personal.isEmpty && global.isEmpty && solo.isEmpty) return const SizedBox.shrink();

    // Cap the whole section's width so it doesn't blow up on desktop.
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kDiscoverMaxWidth),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Filters the user pulled out of their tab: one row each.
          for (final s in solo) ...[
            _DiscoverGroup(
              key: ValueKey('discover_solo_$s'),
              service: service,
              topArtist: topArtist,
              country: country,
              sources: [s],
              icon: _soloIcon(s),
              title: discoverSourceLabel(s),
              infiniteScroll: infiniteScroll,
            ),
            const SizedBox(height: 20),
          ],
          if (personal.isNotEmpty)
            _DiscoverGroup(
              key: const ValueKey('discover_personal'),
              service: service,
              topArtist: topArtist,
              country: country,
              sources: personal,
              icon: Icons.auto_awesome_rounded,
              title: L.discoverForYou,
              infiniteScroll: infiniteScroll,
              smartOrder: smartOrder,
            ),
          if (personal.isNotEmpty && global.isNotEmpty) const SizedBox(height: 20),
          if (global.isNotEmpty)
            _DiscoverGroup(
              key: const ValueKey('discover_global'),
              service: service,
              topArtist: topArtist,
              country: country,
              sources: global,
              icon: Icons.public_rounded,
              title: L.discoverGlobalTrends,
              infiniteScroll: infiniteScroll,
              smartOrder: smartOrder,
            ),
        ]),
      ),
    );
  }
}

// ── One swipeable group (personal OR global), with its own source tabs ─────
class _DiscoverGroup extends StatefulWidget {
  final LastFmService service;
  final String topArtist, country;
  final List<String> sources;
  final IconData icon;
  final String title;
  final bool infiniteScroll;
  final bool smartOrder;
  const _DiscoverGroup({
    super.key,
    required this.service,
    required this.topArtist,
    required this.country,
    required this.sources,
    required this.icon,
    required this.title,
    this.infiniteScroll = false,
    this.smartOrder = false,
  });

  @override
  State<_DiscoverGroup> createState() => _DiscoverGroupState();
}

class _DiscoverGroupState extends State<_DiscoverGroup> {
  // Kept for the whole session so switching tabs is instant.
  static final Map<String, (DateTime, List<_DiscoverItem>)> _cache = {};

  final PageController _ctrl = PageController(viewportFraction: 0.6);
  String _source = '';
  List<_DiscoverItem> _items = [];
  bool _loading = true;

  // ── Smart order ("most relevant first", Spotify-like) ──────────────────
  // Signals: base usefulness, your habits (taps + opened cards, decaying),
  // the moment (time of day, weekend, start of month), whether "on this
  // day" really has memories today, and rotation (not the same first
  // filter every time you open the app).
  static final Set<String> _emptySources = {}; // came back empty this session
  static const Map<String, double> _prior = {
    'foryou': 10, 'fresh': 8, 'onthisday': 6, 'genre': 6, 'albums': 5,
    'deeper': 5, 'forgotten': 4, 'country': 3,
    'gt_week': 6, 'ga_week': 5, 'gb_week': 4,
    'gt_month': 4, 'ga_month': 3, 'gb_month': 3,
    'gt_year': 2, 'ga_year': 2, 'gb_year': 2,
  };
  Map<String, List<num>> _taps = {}; // source -> [weight, lastEpochMs]
  String _lastFirst = '';            // first filter shown last time
  int _lastFirstMs = 0;
  int _todayCount = -1;              // "on this day" items found (-1 = unknown)
  List<String> _order = [];          // chips order (frozen for the session)

  String get _gid => widget.sources.contains('foryou') ? 'p' : 'g';

  Future<void> _loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString('ls_discover_taps');
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _taps = {
          for (final e in m.entries) e.key: [for (final v in (e.value as List)) v as num]
        };
      }
      final lf = (p.getString('ls_discover_lastfirst_$_gid') ?? '').split('|');
      if (lf.length == 2) {
        _lastFirst = lf[0];
        _lastFirstMs = int.tryParse(lf[1]) ?? 0;
      }
    } catch (_) {
      _taps = {};
    }
  }

  Future<void> _savePrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('ls_discover_taps', jsonEncode(_taps));
    } catch (_) {}
  }

  Future<void> _saveLastFirst(String s) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('ls_discover_lastfirst_$_gid',
          '$s|${DateTime.now().millisecondsSinceEpoch}');
    } catch (_) {}
  }

  // The user picked a filter (weight 1) or opened one of its cards (2).
  void _record(String s, double weight) {
    if (!widget.smartOrder) return;
    final t = _taps[s] ?? [0, 0];
    _taps[s] = [t[0] + weight, DateTime.now().millisecondsSinceEpoch];
    _savePrefs();
  }

  // Bonus / malus that depends on the moment.
  double _context(String s, DateTime now) {
    final h = now.hour;
    final morning = h >= 5 && h < 12;
    final evening = h >= 18 || h < 5;
    final weekend = now.weekday >= 6;
    switch (s) {
      case 'foryou':
        return morning ? 1 : 0;
      case 'fresh':
        return (now.day <= 7 ? 3 : 0) + (morning ? 1 : 0); // new month = new music
      case 'forgotten':
      case 'deeper':
        return (evening ? 2 : 0) + (weekend ? 1.5 : 0);    // time to dig
      case 'albums':
        return (weekend ? 1.5 : 0) + (evening ? 1 : 0);
      case 'genre':
        return (h >= 12 && h < 18) ? 1 : 0;
      case 'onthisday':
        // Only relevant if you really listened on this date in past years.
        if (_todayCount == 0) return -100;
        return _todayCount > 0 ? 6 + math.min(_todayCount, 10) * 0.3 : 0;
      default:
        return 0;
    }
  }

  double _score(String s) {
    final now = DateTime.now();
    var v = (_prior[s] ?? 1) + _context(s, now);
    final t = _taps[s];
    if (t != null) {
      final days = (now.millisecondsSinceEpoch - t[1]) / 86400000;
      final decay = math.pow(0.5, days / 14).toDouble(); // halves every 14 days
      v += 4 * math.log(1 + t[0] * decay);
    }
    // Rotation: it was already first recently -> give another one a turn.
    if (s == _lastFirst) {
      final last = DateTime.fromMillisecondsSinceEpoch(_lastFirstMs);
      if (s == 'onthisday') {
        if (last.year == now.year && last.month == now.month && last.day == now.day) v -= 8;
      } else if (now.difference(last).inHours < 6) {
        v -= 3;
      }
    }
    if (_emptySources.contains(s)) v -= 100;
    return v;
  }

  List<String> _computeOrder() {
    final list = List<String>.from(widget.sources);
    if (!widget.smartOrder || list.length < 2) return list;
    final idx = {for (var i = 0; i < list.length; i++) list[i]: i};
    list.sort((a, b) {
      final c = _score(b).compareTo(_score(a));
      return c != 0 ? c : idx[a]!.compareTo(idx[b]!); // stable on ties
    });
    return list;
  }

  // Loads a source without showing it (used to know if "on this day" has
  // anything today). Result goes in the cache so the tab opens instantly.
  Future<int> _probe(String s) async {
    final key = '$s|${widget.topArtist}|${widget.country}';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1).inMinutes < 30) {
      return hit.$2.length;
    }
    final items = _dedupe(await _fetch(s).timeout(const Duration(seconds: 5)));
    if (items.isNotEmpty) {
      _cache[key] = (DateTime.now(), items);
      _emptySources.remove(s);
    } else {
      _emptySources.add(s);
    }
    return items.length;
  }

  Future<void> _init() async {
    if (widget.smartOrder && widget.sources.length > 1) {
      await _loadPrefs();
      if (widget.sources.contains('onthisday')) {
        try { _todayCount = await _probe('onthisday'); } catch (_) {}
      }
      if (!mounted) return;
    }
    _order = _computeOrder();
    if (_order.isEmpty) return;
    if (widget.smartOrder && _order.length > 1) _saveLastFirst(_order.first);
    _select(_order.first);
  }

  @override
  void initState() {
    super.initState();
    _order = List<String>.from(widget.sources);
    _init();
  }

  @override
  void didUpdateWidget(_DiscoverGroup old) {
    super.didUpdateWidget(old);
    final changed = old.smartOrder != widget.smartOrder ||
        old.sources.join(',') != widget.sources.join(',');
    if (changed) {
      _init();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _label(String s) => discoverSourceLabel(s);

  // Every step here is wrapped so a network hiccup, a missing field, or an
  // empty tag list can never throw up out of this function — a swallowed
  // error used to mean the loading placeholder stayed on screen forever
  // instead of falling back to the empty state.
  Future<void> _select(String source) async {
    if (source.isEmpty) return;
    final key = '$source|${widget.topArtist}|${widget.country}';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1).inMinutes < 30) {
      if (!mounted) return;
      setState(() { _source = source; _items = hit.$2; _loading = false; });
      _safeJumpToStart();
      return;
    }
    if (!mounted) return;
    setState(() { _source = source; _loading = true; });
    List<_DiscoverItem> items = [];
    try {
      items = _dedupe(await _fetch(source));
    } catch (_) {
      items = [];
    }
    if (items.isNotEmpty) {
      _cache[key] = (DateTime.now(), items);
      _emptySources.remove(source);
    } else {
      _emptySources.add(source);
    }
    if (!mounted || _source != source) return;
    setState(() { _items = items; _loading = false; });
    _safeJumpToStart();
  }

  void _safeJumpToStart() {
    try {
      if (_ctrl.hasClients) _ctrl.jumpToPage(0);
    } catch (_) {
      // Controller can be mid-detach right after a source switch — never
      // worth crashing the whole section over a scroll reset.
    }
  }

  // Last.fm's chart / geo endpoints aren't personalized and regularly
  // repeat the same track/artist — drop obvious duplicates.
  List<_DiscoverItem> _dedupe(List<_DiscoverItem> items) {
    final seen = <String>{};
    final out = <_DiscoverItem>[];
    for (final it in items) {
      final k = '${it.name.toLowerCase().trim()}|${it.sub.toLowerCase().trim()}';
      if (seen.add(k)) out.add(it);
    }
    return out;
  }

  // "Like A, B" line shown under artists / albums picked by the engine.
  String _likeSub(List<String> reasons) {
    if (reasons.isEmpty) return '';
    return L.discoverLike(reasons.join(', '));
  }

  _DiscoverItem _fromRec(TasteRec r) {
    final String sub;
    if (r.type == 'artists') {
      sub = _likeSub(r.reasons);
    } else if (r.tag.isNotEmpty) {
      sub = '${r.artist} · ${r.tag}';
    } else {
      sub = r.artist;
    }
    return _DiscoverItem(r.name, sub, _extractImage(r.image), r.type,
        {'image': r.image, 'playcount': r.playcount.toString()},
        artist: r.artist);
  }

  _DiscoverItem _fromChart(ChartEntry e, String type) => _DiscoverItem(
      e.name, e.artist, e.imageUrl, type,
      {
        'image': e.imageUrl.isEmpty
            ? null
            : [{'#text': e.imageUrl, 'size': 'extralarge'}],
        'playcount': e.listens.toString(),
      },
      artist: e.artist);

  Future<List<_DiscoverItem>> _fetch(String source) async {
    final s = widget.service;

    // Global trends: real week / month / year charts (ListenBrainz).
    if (source.startsWith('g') && source.contains('_')) {
      final (entity, type) = switch (source.substring(0, 2)) {
        'gt' => ('tracks', 'tracks'),
        'ga' => ('artists', 'artists'),
        _    => ('albums', 'albums'),
      };
      final list = await ListenBrainzService.sitewide(
          entity, source.substring(3), limit: _kDiscoverFetchLimit);
      return list.map((e) => _fromChart(e, type)).toList();
    }

    // Personal picks: computed from your own listening data.
    final engine = TasteEngine(s);
    switch (source) {
      case 'foryou':
        return (await engine.forYou(limit: _kDiscoverFetchLimit)).map(_fromRec).toList();
      case 'fresh':
        return (await engine.fresh(limit: _kDiscoverFetchLimit)).map(_fromRec).toList();
      case 'genre':
        return (await engine.genre(limit: _kDiscoverFetchLimit)).map(_fromRec).toList();
      case 'deeper':
        return (await engine.deeperCuts(limit: _kDiscoverFetchLimit)).map(_fromRec).toList();
      case 'forgotten':
        return (await engine.forgotten(limit: _kDiscoverFetchLimit)).map(_fromRec).toList();
      case 'onthisday':
        return (await engine.onThisDay(limit: _kDiscoverFetchLimit)).map(_fromRec).toList();
      case 'albums':
        return (await engine.albums(limit: _kDiscoverFetchLimit)).map(_fromRec).toList();
      default:
        String artistOf(Map m) {
          final a = m['artist'];
          return a is Map ? (a['name'] ?? '').toString() : (a ?? '').toString();
        }
        return (await s.getGeoTopTracks(widget.country, limit: _kDiscoverFetchLimit))
            .map((t) {
          final m = Map<String, dynamic>.from(t as Map);
          return _DiscoverItem((m['name'] ?? '').toString(), artistOf(m),
              _extractImage(m['image']), 'tracks', m, artist: artistOf(m));
        }).toList();
    }
  }

  void _open(_DiscoverItem it) {
    _record(_source, 2);
    _haptic(_HapticImpact.light);
    final Map<String, dynamic> item = it.type == 'artists'
        ? {'name': it.name, 'image': it.raw['image']}
        : {
            'name': it.name,
            'artist': {'name': it.artist, '#text': it.artist},
            'image': it.raw['image'],
          };
    showDetailSheet(context, item, it.type, widget.service);
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final text    = Theme.of(context).textTheme;
    final sources = _order.length == widget.sources.length ? _order : widget.sources;
    if (sources.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionHeader(title: widget.title, icon: widget.icon),
      const SizedBox(height: 10),
      if (sources.length > 1) _filters(sources),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, box) {
        final page  = box.maxWidth * 0.6;
        final imgSz = page - 20;
        final h     = imgSz + 76; // a little extra for the play-count badge overhang
        return SizedBox(
          height: h,
          width: double.infinity,
          child: M3Switcher(
            duration: M3Motion.effectsDefaultDuration,
            child: _loading
                // A single card-sized placeholder, not a full-width block,
                // so it never looks like a plain grey rectangle. Explicit
                // width/height (not just Align) so it can never be
                // stretched by a parent that hands out tight constraints.
                ? SizedBox(
                    key: ValueKey('load_$_source'),
                    width: double.infinity,
                    height: h,
                    child: Align(
                      alignment: Alignment.topLeft,
                      widthFactor: 1,
                      heightFactor: 1,
                      // Tappable as a manual retry: if a source ever gets
                      // visually stuck on the placeholder, tapping it
                      // re-triggers the fetch instead of leaving the user
                      // with no way out other than switching tabs.
                      child: GestureDetector(
                        onTap: () => _select(_source),
                        child: _loadingCard(imgSz, scheme),
                      ),
                    ),
                  )
                : _items.isEmpty
                    ? SizedBox(
                        key: const ValueKey('empty'),
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            L.discoverNothing,
                            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : PageView.builder(
                        key: ValueKey('${_source}_${widget.infiniteScroll}'),
                        controller: _ctrl,
                        padEnds: false,
                        physics: const BouncingScrollPhysics(),
                        // Infinite scroll: no bound on itemCount, cards
                        // just repeat by wrapping the index — cheap and
                        // avoids having to keep fetching new pages from
                        // Last.fm/ListenBrainz just to fill an endless list.
                        itemCount: widget.infiniteScroll ? null : _items.length,
                        itemBuilder: (_, i) => _card(i % _items.length, imgSz, scheme, text),
                      ),
          ),
        );
      }),
    ]);
  }

  Widget _chip(String src) => M3Chip(
        label: Text(_label(src)),
        selected: src == _source,
        onSelected: (_) {
          _haptic(_HapticImpact.selection);
          _record(src, 1);
          _select(src);
        },
      );

  // Filter row: one scrolling line.
  Widget _filters(List<String> sources) => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: sources.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _chip(sources[i]),
        ),
      );

  // Same shape + same animated loader as the rest of the app, sized to the
  // card that will replace it once loaded.
  Widget _loadingCard(double imgSz, ColorScheme scheme) => SizedBox(
        width: imgSz,
        height: imgSz + 64,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          M3ShapedBox(
            size: imgSz,
            child: Container(
              color: scheme.surfaceContainerHigh,
              alignment: Alignment.center,
              child: M3LoadingIndicator(size: (imgSz * 0.32).clamp(28.0, 56.0)),
            ),
          ),
        ]),
      );

  // Centered card is big, the ones next to it are smaller (spring feel).
  Widget _card(int i, double imgSz, ColorScheme scheme, TextTheme text) {
    final it = _items[i];
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        double d = 0;
        if (_ctrl.hasClients && _ctrl.position.haveDimensions) {
          d = ((_ctrl.page ?? 0) - i).abs().clamp(0.0, 1.0);
        } else {
          d = i == 0 ? 0 : 1;
        }
        final scale = 1 - 0.12 * d;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: Opacity(opacity: 1 - 0.35 * d, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _open(it),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(right: 12, top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              _SmartImage(
                size: imgSz,
                borderRadius: 24,
                seed: '${it.name}${it.sub}',
                initialUrl: it.imageUrl,
                resolver: () => switch (it.type) {
                  'tracks' => ImageService.resolveTrack(it.name, it.artist,
                      lastfmUrl: it.imageUrl.isNotEmpty ? it.imageUrl : null),
                  'albums' => ImageService.resolveAlbum(it.name, it.artist,
                      lastfmUrl: it.imageUrl.isNotEmpty ? it.imageUrl : null),
                  _ => ImageService.resolveArtist(it.name,
                      lastfmUrl: it.imageUrl.isNotEmpty ? it.imageUrl : null),
                },
              ),
              if (it.playcount > 0)
                Positioned(top: -10, right: -8, child: _PlayBadge(
                  seed: '${it.name}${it.sub}badge',
                  count: it.playcount,
                )),
            ]),
            const SizedBox(height: 8),
            Text(it.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (it.sub.isNotEmpty)
              Text(it.sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

// ── Small count badge on the card image ────────────────────────────────────
// Rectangular shapes only (no circle / cookie): the text is a wide, short
// label, so a round shape always made it overflow. Each card gets one of
// these at random-but-stable (same seed = same shape) for some variation.
ShapeBorder _badgeShape(int idx) {
  switch (idx % 6) {
    case 0: return RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));   // sharp rectangle
    case 1: return RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));  // rounded rectangle
    case 2: return BeveledRectangleBorder(borderRadius: BorderRadius.circular(8));   // cut corners
    case 3: return const RoundedRectangleBorder(                                     // tab / leaf
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14), bottomRight: Radius.circular(14),
            topRight: Radius.circular(3), bottomLeft: Radius.circular(3)));
    case 4: return ContinuousRectangleBorder(borderRadius: BorderRadius.circular(22)); // squircle
    default: return const StadiumBorder();                                           // pill
  }
}

class _PlayBadge extends StatelessWidget {
  final String seed;
  final int count;
  const _PlayBadge({required this.seed, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idx = m3ShapeIndex('badge_$seed');
    final shape = _badgeShape(idx);
    return PhysicalShape(
      color: scheme.primaryContainer,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      clipper: ShapeBorderClipper(shape: shape),
      child: Padding(
        // Generous padding so text never touches a rounded/soft edge.
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.play_arrow_rounded, size: 13, color: scheme.onPrimaryContainer),
          const SizedBox(width: 3),
          Text(_fmt(count),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: scheme.onPrimaryContainer,
              )),
        ]),
      ),
    );
  }
}
