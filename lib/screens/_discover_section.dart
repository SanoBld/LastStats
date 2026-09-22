// lib/screens/_discover_section.dart
// ══════════════════════════════════════════════════════════════════════════
//  Dashboard "Discover": swipeable music ideas.
//    1. "Pour toi" (personal)  — similar to your top artist, your country
//    2. "Tendances Last.fm" (global) — worldwide top tracks / top artists
//  Images use the Material You shapes. Section and sources are set in
//  Settings > Dashboard.
// ══════════════════════════════════════════════════════════════════════════
part of 'home_screen.dart';

const _kDiscoverAll = ['community', 'artists', 'foryou', 'country'];
const _kDiscoverPersonal = ['foryou', 'country'];
const _kDiscoverGlobal   = ['community', 'artists'];

class _DiscoverItem {
  final String name, sub, imageUrl, type;
  final Map<String, dynamic> raw;
  const _DiscoverItem(this.name, this.sub, this.imageUrl, this.type, this.raw);
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
              !(s == 'foryou' && topArtist.isEmpty))
            s
      ];

  @override
  Widget build(BuildContext context) {
    final personal = _avail(_kDiscoverPersonal);
    final global   = _avail(_kDiscoverGlobal);
    if (personal.isEmpty && global.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]);
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
        final h     = imgSz + 64;
        return SizedBox(
          height: h,
          width: double.infinity,
          child: M3Switcher(
            duration: M3Motion.effectsDefaultDuration,
            child: _loading
                // A single card-sized placeholder, not a full-width block,
                // so it never looks like a plain grey rectangle.
                ? Align(
                    key: const ValueKey('load'),
                    alignment: Alignment.topLeft,
                    child: _loadingCard(imgSz, scheme),
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
