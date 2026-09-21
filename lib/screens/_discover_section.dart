// lib/screens/_discover_section.dart
// ══════════════════════════════════════════════════════════════════════════
//  Dashboard "Discover": swipeable music ideas (community, charts,
//  similar artists, your country). Images use the Material You shapes.
//  The section and its sources are set in Settings > Dashboard.
// ══════════════════════════════════════════════════════════════════════════
part of 'home_screen.dart';

const _kDiscoverAll = ['community', 'artists', 'foryou', 'country'];

class _DiscoverItem {
  final String name, sub, imageUrl, type;
  final Map<String, dynamic> raw;
  const _DiscoverItem(this.name, this.sub, this.imageUrl, this.type, this.raw);
}

class _DiscoverSection extends StatefulWidget {
  final LastFmService service;
  final String topArtist, country;
  final List<String> sources;
  const _DiscoverSection({
    required this.service,
    required this.topArtist,
    required this.country,
    required this.sources,
  });

  @override
  State<_DiscoverSection> createState() => _DiscoverSectionState();
}

class _DiscoverSectionState extends State<_DiscoverSection> {
  // Kept for the whole session so switching tabs is instant.
  static final Map<String, (DateTime, List<_DiscoverItem>)> _cache = {};

  final PageController _ctrl = PageController(viewportFraction: 0.6);
  String _source = '';
  List<_DiscoverItem> _items = [];
  bool _loading = true;

  List<String> get _sources => [
        for (final s in _kDiscoverAll)
          if (widget.sources.contains(s) &&
              !(s == 'country' && (widget.country.isEmpty || widget.country == 'None')) &&
              !(s == 'foryou' && widget.topArtist.isEmpty))
            s
      ];

  @override
  void initState() {
    super.initState();
    _select(_sources.isEmpty ? '' : _sources.first);
  }

  @override
  void didUpdateWidget(_DiscoverSection old) {
    super.didUpdateWidget(old);
    final list = _sources;
    if (!list.contains(_source) && list.isNotEmpty) _select(list.first);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _label(String s) => switch (s) {
        'community' => _tr({'fr': 'Communauté', 'en': 'Community', 'es': 'Comunidad', 'de': 'Community', 'it': 'Community', 'pt': 'Comunidade'}),
        'artists'   => _tr({'fr': 'Artistes tendance', 'en': 'Trending artists', 'es': 'Artistas en tendencia', 'de': 'Trend-Künstler', 'it': 'Artisti di tendenza', 'pt': 'Artistas em alta'}),
        'foryou'    => _tr({'fr': 'Pour toi', 'en': 'For you', 'es': 'Para ti', 'de': 'Für dich', 'it': 'Per te', 'pt': 'Para você'}),
        _           => _tr({'fr': 'Ton pays', 'en': 'Your country', 'es': 'Tu país', 'de': 'Dein Land', 'it': 'Il tuo paese', 'pt': 'Seu país'}),
      };

  Future<void> _select(String source) async {
    if (source.isEmpty) return;
    final key = '$source|${widget.topArtist}|${widget.country}';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1).inMinutes < 30) {
      setState(() { _source = source; _items = hit.$2; _loading = false; });
      if (_ctrl.hasClients) _ctrl.jumpToPage(0);
      return;
    }
    setState(() { _source = source; _loading = true; });
    List<_DiscoverItem> items = [];
    try {
      items = await _fetch(source);
    } catch (_) {}
    if (items.isNotEmpty) _cache[key] = (DateTime.now(), items);
    if (!mounted || _source != source) return;
    setState(() { _items = items; _loading = false; });
    if (_ctrl.hasClients) _ctrl.jumpToPage(0);
  }

  Future<List<_DiscoverItem>> _fetch(String source) async {
    final s = widget.service;
    String artistOf(Map m) {
      final a = m['artist'];
      return a is Map ? (a['name'] ?? '').toString() : (a ?? '').toString();
    }
    _DiscoverItem track(dynamic t) {
      final m = Map<String, dynamic>.from(t as Map);
      return _DiscoverItem((m['name'] ?? '').toString(), artistOf(m),
          _extractImage(m['image']), 'tracks', m);
    }
    _DiscoverItem artist(dynamic t, String sub) {
      final m = Map<String, dynamic>.from(t as Map);
      return _DiscoverItem((m['name'] ?? '').toString(), sub,
          _extractImage(m['image']), 'artists', m);
    }
    switch (source) {
      case 'community':
        return (await s.getChartTopTracks()).map(track).toList();
      case 'artists':
        return (await s.getChartTopArtists()).map((a) => artist(a, '')).toList();
      case 'foryou':
        final sub = _tr({'fr': 'Comme ${widget.topArtist}', 'en': 'Like ${widget.topArtist}'});
        return (await s.getSimilarArtists(widget.topArtist))
            .map((a) => artist(a, sub)).toList();
      default:
        return (await s.getGeoTopTracks(widget.country)).map(track).toList();
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
    final sources = _sources;
    if (sources.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionHeader(
        title: _tr({'fr': 'Découvrir', 'en': 'Discover', 'es': 'Descubrir', 'de': 'Entdecken', 'it': 'Scopri', 'pt': 'Descobrir'}),
        icon: Icons.explore_rounded,
      ),
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
        final h     = imgSz + 64;
        return SizedBox(
          height: h,
          child: M3Switcher(
            duration: M3Motion.effectsDefaultDuration,
            child: _loading
                ? const Center(key: ValueKey('load'), child: M3LoadingIndicator(size: 56))
                : _items.isEmpty
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Text(
                          _tr({'fr': 'Rien à afficher pour le moment', 'en': 'Nothing to show right now'}),
                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
          padding: const EdgeInsets.only(right: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
