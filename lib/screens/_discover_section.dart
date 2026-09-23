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
  const _DiscoverSection({
    required this.service,
    required this.topArtist,
    required this.country,
    required this.sources,
    this.infiniteScroll = false,
  });

  List<String> _avail(List<String> group) => [
        for (final s in group)
          if (sources.contains(s) &&
              !(s == 'country' && (country.isEmpty || country == 'None')) &&
              !(const {'foryou', 'fresh', 'genre', 'deeper', 'albums'}.contains(s) &&
                  topArtist.isEmpty))
            s
      ];

  @override
  Widget build(BuildContext context) {
    final personal = _avail(_kDiscoverPersonal);
    final global   = _avail(_kDiscoverGlobal);
    if (personal.isEmpty && global.isEmpty) return const SizedBox.shrink();

    // Cap the whole section's width so it doesn't blow up on desktop.
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kDiscoverMaxWidth),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (personal.isNotEmpty)
            _DiscoverGroup(
              key: const ValueKey('discover_personal'),
              service: service,
              topArtist: topArtist,
              country: country,
              sources: personal,
              icon: Icons.auto_awesome_rounded,
              title: _tr({'fr': 'Pour toi', 'en': 'For you', 'es': 'Para ti', 'de': 'Für dich', 'it': 'Per te', 'pt': 'Para você'}),
              infiniteScroll: infiniteScroll,
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
              title: _tr({'fr': 'Tendances mondiales', 'en': 'Global trends', 'es': 'Tendencias globales', 'de': 'Globale Trends', 'it': 'Tendenze globali', 'pt': 'Tendências globais'}),
              infiniteScroll: infiniteScroll,
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
  const _DiscoverGroup({
    super.key,
    required this.service,
    required this.topArtist,
    required this.country,
    required this.sources,
    required this.icon,
    required this.title,
    this.infiniteScroll = false,
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

  @override
  void initState() {
    super.initState();
    _select(widget.sources.first);
  }

  @override
  void didUpdateWidget(_DiscoverGroup old) {
    super.didUpdateWidget(old);
    if (!widget.sources.contains(_source) && widget.sources.isNotEmpty) {
      _select(widget.sources.first);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _label(String s) {
    if (s.startsWith('g') && s.contains('_')) {
      final kind = switch (s.substring(0, 2)) {
        'gt' => _tr({'fr': 'Titres', 'en': 'Tracks', 'es': 'Canciones', 'de': 'Titel', 'it': 'Brani', 'pt': 'Faixas'}),
        'ga' => _tr({'fr': 'Artistes', 'en': 'Artists', 'es': 'Artistas', 'de': 'Künstler', 'it': 'Artisti', 'pt': 'Artistas'}),
        _    => _tr({'fr': 'Albums', 'en': 'Albums', 'es': 'Álbumes', 'de': 'Alben', 'it': 'Album', 'pt': 'Álbuns'}),
      };
      final range = switch (s.substring(3)) {
        'week'  => _tr({'fr': 'semaine', 'en': 'week', 'es': 'semana', 'de': 'Woche', 'it': 'settimana', 'pt': 'semana'}),
        'month' => _tr({'fr': 'mois', 'en': 'month', 'es': 'mes', 'de': 'Monat', 'it': 'mese', 'pt': 'mês'}),
        _       => _tr({'fr': 'année', 'en': 'year', 'es': 'año', 'de': 'Jahr', 'it': 'anno', 'pt': 'ano'}),
      };
      return '$kind · $range';
    }
    return switch (s) {
      'foryou'    => _tr({'fr': 'Ton mix', 'en': 'Your mix', 'es': 'Tu mix', 'de': 'Dein Mix', 'it': 'Il tuo mix', 'pt': 'Seu mix'}),
      'onthisday' => _tr({'fr': 'Ce jour-là', 'en': 'On this day', 'es': 'Un día como hoy', 'de': 'An diesem Tag', 'it': 'In questo giorno', 'pt': 'Neste dia'}),
      'fresh'     => _tr({'fr': 'Ce mois-ci', 'en': 'This month', 'es': 'Este mes', 'de': 'Diesen Monat', 'it': 'Questo mese', 'pt': 'Este mês'}),
      'genre'     => _tr({'fr': 'Tes genres', 'en': 'Your genres', 'es': 'Tus géneros', 'de': 'Deine Genres', 'it': 'I tuoi generi', 'pt': 'Seus gêneros'}),
      'deeper'    => _tr({'fr': 'Titres cachés', 'en': 'Deep cuts', 'es': 'Joyas ocultas', 'de': 'Deep Cuts', 'it': 'Perle nascoste', 'pt': 'Faixas escondidas'}),
      'forgotten' => _tr({'fr': 'Oubliés', 'en': 'Forgotten', 'es': 'Olvidadas', 'de': 'Vergessen', 'it': 'Dimenticate', 'pt': 'Esquecidas'}),
      'albums'    => _tr({'fr': 'Albums', 'en': 'Albums', 'es': 'Álbumes', 'de': 'Alben', 'it': 'Album', 'pt': 'Álbuns'}),
      _           => _tr({'fr': 'Ton pays', 'en': 'Your country', 'es': 'Tu país', 'de': 'Dein Land', 'it': 'Il tuo paese', 'pt': 'Seu país'}),
    };
  }

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
    if (items.isNotEmpty) _cache[key] = (DateTime.now(), items);
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
    final names = reasons.join(', ');
    return _tr({'fr': 'Comme $names', 'en': 'Like $names', 'es': 'Como $names',
        'de': 'Wie $names', 'it': 'Come $names', 'pt': 'Como $names'});
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
    final sources = widget.sources;
    if (sources.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionHeader(title: widget.title, icon: widget.icon),
      const SizedBox(height: 10),
      if (sources.length > 1)
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: sources.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => M3Chip(
              label: Text(_label(sources[i])),
              selected: sources[i] == _source,
              onSelected: (_) { _haptic(_HapticImpact.selection); _select(sources[i]); },
            ),
          ),
        ),
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
                            _tr({'fr': 'Rien à afficher pour le moment', 'en': 'Nothing to show right now'}),
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
