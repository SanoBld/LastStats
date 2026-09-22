// lib/screens/_discover_section.dart
// ══════════════════════════════════════════════════════════════════════════
//  Dashboard "Discover": swipeable music ideas.
//    1. "Pour toi" (personal)  — similar to your top artist, your top
//       genre/tag, your country
//    2. "Tendances Last.fm" (global) — worldwide top tracks / top artists
//  Images use the Material You shapes. Section and sources are set in
//  Settings > Dashboard.
//
//  Notes:
//   - Cards are capped to a max width so the section stays readable on
//     wide (desktop) screens instead of stretching to a huge size.
//   - Each card carries a small play-count badge in a Material You shape
//     when Last.fm gives us a count. "community"/"country" come from
//     Last.fm's global chart endpoints, which are not personalized and
//     can include duplicates or unrelated entries — we de-duplicate what
//     we get, but the underlying data quality is Last.fm's, not ours
//     (Last.fm's public API has no real "recommended for you" endpoint
//     anymore — "genre" below is our own stand-in, built from the tags of
//     your own top artist).
//   - Every state change here (_select) is defensive: it never lets an
//     exception escape mid-build, because an uncaught error here used to
//     surface as a plain grey box (Flutter's release-mode ErrorWidget)
//     that only "fixed itself" once the user tapped something else and
//     forced a fresh rebuild.
// ══════════════════════════════════════════════════════════════════════════
part of 'home_screen.dart';

const _kDiscoverAll = ['community', 'artists', 'foryou', 'genre', 'country'];
const _kDiscoverPersonal = ['foryou', 'genre', 'country'];
const _kDiscoverGlobal   = ['community', 'artists'];

// Cards never grow past this width, even on very wide desktop windows.
const double _kDiscoverMaxWidth = 640;
// Items fetched per source (was 15 — bumped so "for you" / "trends" have
// more variety to swipe through).
const int _kDiscoverFetchLimit = 24;

class _DiscoverItem {
  final String name, sub, imageUrl, type;
  final Map<String, dynamic> raw;
  const _DiscoverItem(this.name, this.sub, this.imageUrl, this.type, this.raw);

  int get playcount => int.tryParse((raw['playcount'] ?? '0').toString()) ?? 0;
}

class _DiscoverSection extends StatelessWidget {
  final LastFmService service;
  final String topArtist, country;
  final List<String> sources;
  const _DiscoverSection({
    required this.service,
    required this.topArtist,
    required this.country,
    required this.sources,
  });

  List<String> _avail(List<String> group) => [
        for (final s in group)
          if (sources.contains(s) &&
              !(s == 'country' && (country.isEmpty || country == 'None')) &&
              !(s == 'foryou' && topArtist.isEmpty) &&
              !(s == 'genre' && topArtist.isEmpty))
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
              title: _tr({'fr': 'Tendances Last.fm', 'en': 'Last.fm trends', 'es': 'Tendencias de Last.fm', 'de': 'Last.fm-Trends', 'it': 'Tendenze Last.fm', 'pt': 'Tendências do Last.fm'}),
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
  const _DiscoverGroup({
    super.key,
    required this.service,
    required this.topArtist,
    required this.country,
    required this.sources,
    required this.icon,
    required this.title,
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

  String _label(String s) => switch (s) {
        'community' => _tr({'fr': 'Top titres', 'en': 'Top tracks', 'es': 'Top canciones', 'de': 'Top-Titel', 'it': 'Top brani', 'pt': 'Top faixas'}),
        'artists'   => _tr({'fr': 'Top artistes', 'en': 'Top artists', 'es': 'Top artistas', 'de': 'Top-Künstler', 'it': 'Top artisti', 'pt': 'Top artistas'}),
        'foryou'    => _tr({'fr': 'Comme ${widget.topArtist}', 'en': 'Like ${widget.topArtist}'}),
        'genre'     => _tr({'fr': 'Ton genre', 'en': 'Your genre', 'es': 'Tu género', 'de': 'Dein Genre', 'it': 'Il tuo genere', 'pt': 'Seu gênero'}),
        _           => _tr({'fr': 'Ton pays', 'en': 'Your country', 'es': 'Tu país', 'de': 'Dein Land', 'it': 'Il tuo paese', 'pt': 'Seu país'}),
      };

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

  Future<List<_DiscoverItem>> _fetch(String source) async {
    final s = widget.service;
    String artistOf(Map m) {
      final a = m['artist'];
      return a is Map ? (a['name'] ?? '').toString() : (a ?? '').toString();
    }
    _DiscoverItem track(dynamic t, [String? subOverride]) {
      final m = Map<String, dynamic>.from(t as Map);
      return _DiscoverItem((m['name'] ?? '').toString(), subOverride ?? artistOf(m),
          _extractImage(m['image']), 'tracks', m);
    }
    _DiscoverItem artist(dynamic t, String sub) {
      final m = Map<String, dynamic>.from(t as Map);
      return _DiscoverItem((m['name'] ?? '').toString(), sub,
          _extractImage(m['image']), 'artists', m);
    }
    switch (source) {
      case 'community':
        return (await s.getChartTopTracks(limit: _kDiscoverFetchLimit)).map((t) => track(t)).toList();
      case 'artists':
        return (await s.getChartTopArtists(limit: _kDiscoverFetchLimit)).map((a) => artist(a, '')).toList();
      case 'foryou':
        final sub = _tr({'fr': 'Comme ${widget.topArtist}', 'en': 'Like ${widget.topArtist}'});
        return (await s.getSimilarArtists(widget.topArtist, limit: _kDiscoverFetchLimit))
            .map((a) => artist(a, sub)).toList();
      case 'genre':
        // Derive a taste-based list from your own top artist's tags,
        // instead of Last.fm's generic (non-personalized) charts.
        final tags = await s.getArtistTopTags(widget.topArtist);
        if (tags.isEmpty) return [];
        final tagName = (Map<String, dynamic>.from(tags.first as Map)['name'] ?? '').toString();
        if (tagName.isEmpty) return [];
        final subLabel = _tr({'fr': 'Genre : $tagName', 'en': 'Genre: $tagName'});
        return (await s.getTagTopTracks(tagName, limit: _kDiscoverFetchLimit))
            .map((t) => track(t, subLabel)).toList();
      default:
        return (await s.getGeoTopTracks(widget.country, limit: _kDiscoverFetchLimit)).map((t) => track(t)).toList();
    }
  }

  void _open(_DiscoverItem it) {
    _haptic(_HapticImpact.light);
    final Map<String, dynamic> item = it.type == 'tracks'
        ? {
            'name': it.name,
            'artist': {'name': it.sub, '#text': it.sub},
            'image': it.raw['image'],
          }
        : {'name': it.name, 'image': it.raw['image']};
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
                        key: ValueKey(_source),
                        controller: _ctrl,
                        padEnds: false,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _card(i, imgSz, scheme, text),
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
                resolver: () => it.type == 'tracks'
                    ? ImageService.resolveTrack(it.name, it.sub,
                        lastfmUrl: it.imageUrl.isNotEmpty ? it.imageUrl : null)
                    : ImageService.resolveArtist(it.name,
                        lastfmUrl: it.imageUrl.isNotEmpty ? it.imageUrl : null),
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

// ── Small play-count pill on the card image, in a Material You shape ───────
// Only "safe" shapes for a small text pill: a plain rectangle and a couple
// of rounded/stadium variants. The full 8-shape set used for images
// (cookie, clover, leaf, arch...) has lobes and asymmetric corners that
// clip short text at small sizes, so badges use their own smaller set with
// generous padding instead.
ShapeBorder _badgeShape(int idx) {
  switch (idx % 4) {
    case 0: return const StadiumBorder();                                   // pill
    case 1: return RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));   // rectangle
    case 2: return RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));  // squircle-ish
    default: return const M3CookieBorder(lobes: 10, amplitude: 0.035);      // near-circle, very soft bumps
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.play_arrow_rounded, size: 13, color: scheme.onPrimaryContainer),
          const SizedBox(width: 3),
          Text(_fmt(count),
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
