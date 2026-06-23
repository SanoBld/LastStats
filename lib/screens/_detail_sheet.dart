// ignore_for_file: unused_import
part of 'home_screen.dart';

// ── Fullscreen image helper (used by detail sheet and profile sheet) ──────────

void _pushFullscreen(BuildContext ctx, String url) {
  Navigator.of(ctx).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black,
    barrierDismissible: true,
    pageBuilder: (_, _, _) => _FullscreenImageViewer(url: url),
    transitionsBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 220),
  ));
}

// ── Artwork color theme (beta) ──────────────────────────────────────────────
// Builds the fully artwork-themed variant of [base]. We only need the two
// endpoints (base vs. themed) — AnimatedTheme cross-fades between them on
// its own, so no manual interpolation is needed here.
// Covers outline/outlineVariant too (not just primary/secondary): those
// drive FilterChip's unselected border and card outlines, and leaving them
// on the old theme is what made the previous accent look unfinished.
({ColorScheme scheme, Color surface}) _artworkScheme(
  ColorScheme base, Color artworkColor,
) {
  final seeded = ColorScheme.fromSeed(
    seedColor:  seedColorForScheme(artworkColor),
    brightness: base.brightness,
  );
  final scheme = base.copyWith(
    primary:                 seeded.primary,
    onPrimary:               seeded.onPrimary,
    primaryContainer:        seeded.primaryContainer,
    onPrimaryContainer:      seeded.onPrimaryContainer,
    secondary:               seeded.secondary,
    onSecondary:             seeded.onSecondary,
    secondaryContainer:      seeded.secondaryContainer,
    onSecondaryContainer:    seeded.onSecondaryContainer,
    outline:                 seeded.outline,
    outlineVariant:          seeded.outlineVariant,
    surfaceContainerHighest: seeded.surfaceContainerHighest,
    onSurfaceVariant:        seeded.onSurfaceVariant,
  );
  final surface = Color.lerp(base.surface, artworkColor, 0.18)!;
  return (scheme: scheme, surface: surface);
}

// ── Dominant color extraction ───────────────────────────────────────────────
// PaletteGenerator.fromImageProvider quantizes colors with a heavy algorithm
// that freezes the UI (flutter/flutter#140325). This replacement decodes at
// a tiny 48×48 target (a true decode-time downscale, unlike palette_generator's
// `size` hint) and buckets pixels into a histogram, favoring saturated tones
// over washed-out ones — cheap enough to run inline without jank.
// Note: this can NOT be moved into compute() — dart:ui's image codec isn't
// available in background isolates ("Failed to access the internal image
// decoder registry on this isolate", flutter/flutter#109701/#95311).
Future<int?> _extractDominantColorArgb(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(
      bytes, targetWidth: 48, targetHeight: 48,
    );
    final frame = await codec.getNextFrame();
    final raw = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    if (raw == null) return null;

    final pixels = raw.buffer.asUint8List();
    final counts = <int, int>{};
    for (int i = 0; i < pixels.length; i += 4) {
      if (pixels[i + 3] < 200) continue; // skip near-transparent pixels
      final r = pixels[i], g = pixels[i + 1], b = pixels[i + 2];
      final maxc = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minc = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final sat  = maxc == 0 ? 0.0 : (maxc - minc) / maxc;
      // Group close colors (5 bits/channel) and weight saturated pixels
      // higher so a vibrant accent wins over a dull/grey background.
      final key    = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
      final weight = 1 + (sat * 4).round();
      counts[key]  = (counts[key] ?? 0) + weight;
    }
    if (counts.isEmpty) return null;

    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final r = ((best >> 10) & 0x1F) << 3;
    final g = ((best >> 5)  & 0x1F) << 3;
    final b = (best & 0x1F) << 3;
    return 0xFF000000 | (r << 16) | (g << 8) | b;
  } catch (_) {
    return null;
  }
}

// ── Pull-down-to-dismiss wrapper ───────────────────────────────────────────
// Tracks accumulated overscroll instead of raw scroll pixels, since
// ClampingScrollPhysics keeps pixels at 0 at the boundary (unlike the iOS
// bounce, which reports negative pixels during overscroll).
class _DismissOnOverscroll extends StatefulWidget {
  final Widget       child;
  final VoidCallback onDismiss;
  const _DismissOnOverscroll({required this.child, required this.onDismiss});

  @override
  State<_DismissOnOverscroll> createState() => _DismissOnOverscrollState();
}

class _DismissOnOverscrollState extends State<_DismissOnOverscroll> {
  double _pulled = 0;

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
    onNotification: (n) {
      if (n is ScrollStartNotification || n is ScrollEndNotification) {
        _pulled = 0;
      } else if (n is OverscrollNotification && n.overscroll < 0) {
        _pulled += n.overscroll;
        if (_pulled < -60) widget.onDismiss();
      }
      return false;
    },
    child: widget.child,
  );
}

// ── Status bar scrim ────────────────────────────────────────────────────────
// Keeps system status bar icons (time, battery, wifi) legible above the
// scrolling content, regardless of scroll position.
class _StatusBarScrim extends StatelessWidget {
  final double height;
  const _StatusBarScrim({required this.height});

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0, left: 0, right: 0, height: height,
    child: IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withValues(alpha: 0.22)),
        ),
      ),
    ),
  );
}

void showDetailSheet(
  BuildContext context,
  Map<String, dynamic> item,
  String type,          // 'artists' | 'albums' | 'tracks'
  LastFmService service,
) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    fullscreenDialog: true,
    pageBuilder:        (_, _, _) => _ItemDetailSheet(item: item, type: type, service: service),
    transitionsBuilder: (_, anim, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration:        const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  ));
}


class _ItemDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String               type;   // 'artists' | 'albums' | 'tracks'
  final LastFmService        service;

  const _ItemDetailSheet({
    required this.item,
    required this.type,
    required this.service,
  });

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {

  bool   _loadingUser  = true;
  bool   _bioExpanded  = false;
  String _period       = 'overall';

  String _resolvedImage = '';
  Color? _artworkColor;  // dominant color extracted from artwork

  Map<String, dynamic>? _info;
  List<dynamic>         _topTracks = [];
  List<dynamic>         _topAlbums = [];
  List<dynamic>         _tracklist = [];

  int _userPlays = 0;
  int _userRank  = -1;

  bool   _translating    = false;
  bool   _showTranslated = false;
  String _translatedBio  = '';
  String _translatedLang = '';

  bool   _loadingLyrics  = false;
  String _lyrics         = '';
  bool   _lyricsExpanded = false;

  String get _name   => (widget.item['name']            ?? '').toString();
  String get _artist => (widget.item['artist']?['name'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    _resolveImage();
    await Future.wait([_fetchMeta(), _fetchUserStats()]);
  }

  Future<void> _resolveImage() async {
    final raw = _extractImage(widget.item['image'], large: true);
    final String url;
    switch (widget.type) {
      case 'artists':
        url = await ImageService.resolveArtist(_name, lastfmUrl: raw.isNotEmpty ? raw : null);
      case 'albums':
        url = await ImageService.resolveAlbum(_name, _artist, lastfmUrl: raw.isNotEmpty ? raw : null);
      default:
        url = await ImageService.resolveTrack(_name, _artist, lastfmUrl: raw.isNotEmpty ? raw : null);
    }
    if (!mounted) return;
    setState(() => _resolvedImage = url);
    // Extract dominant color when the option is enabled
    if (url.isNotEmpty && artworkColorThemeNotifier.value) {
      _extractArtworkColor(url);
    }
  }

  // Downloads the bytes ourselves (instead of handing the URL straight to an
  // ImageProvider) so every failure — network, timeout, decode — stays
  // inside this try/catch. _extractDominantColorArgb decodes a tiny 48×48
  // version and runs a cheap histogram, fast enough to stay on the main
  // isolate (PaletteGenerator's heavier quantization is what froze the UI).
  Future<void> _extractArtworkColor(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (!mounted || response.statusCode != 200 || response.bodyBytes.isEmpty) return;

      final argb = await _extractDominantColorArgb(response.bodyBytes);
      if (argb != null && mounted) setState(() => _artworkColor = Color(argb));
    } catch (_) {
      // Network error, timeout, or decode failure: skip the tint silently.
    }
  }

  Future<void> _fetchMeta() async {
    try {
      switch (widget.type) {
        case 'artists':
          final results = await Future.wait([
            widget.service.getArtistInfo(_name),
            widget.service.getArtistTopTracks(_name, limit: 5),
            widget.service.getArtistTopAlbums(_name, limit: 8),
          ]);
          if (mounted) {
            setState(() {
              _info      = results[0] as Map<String, dynamic>?;
              _topTracks = results[1] as List<dynamic>;
              _topAlbums = results[2] as List<dynamic>;
            });
          }
          // Auto-translate bio for all types
          if (_bio().isNotEmpty) _translateTo(localeNotifier.value);

        case 'albums':
          final info = await widget.service.getAlbumInfo(_name, _artist);
          if (mounted) {
            setState(() {
              _info      = info;
              _tracklist = _asList(info?['tracks']?['track']);
            });
          }
          if (_bio().isNotEmpty) _translateTo(localeNotifier.value);

        case 'tracks':
          final info = await widget.service.getTrackInfo(_name, _artist);
          if (mounted) setState(() => _info = info);
          if (_bio().isNotEmpty) _translateTo(localeNotifier.value);
          _fetchLyrics();
      }
    } catch (_) {}
  }

  Future<void> _fetchUserStats() async {
    try {
      final stats = await widget.service.getUserItemStats(
        type: widget.type, name: _name, artistName: _artist, period: _period,
      );
      if (mounted) {
        setState(() {
          _userPlays   = stats.plays;
          _userRank    = stats.rank;
          _loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _changePeriod(String p) async {
    if (p == _period) return;
    setState(() { _period = p; _loadingUser = true; _userPlays = 0; _userRank = -1; });
    await _fetchUserStats();
  }

  Future<void> _fetchLyrics() async {
    setState(() => _loadingLyrics = true);
    final lyrics = await LyricsService.getLyrics(_artist, _name);
    if (mounted) setState(() { _lyrics = lyrics; _loadingLyrics = false; });
  }

  Future<void> _toggleTranslate() async {
    if (_showTranslated) { setState(() => _showTranslated = false); return; }
    await _translateTo(localeNotifier.value);
  }

  Future<void> _translateTo(String lang) async {
    if (_showTranslated && _translatedLang == lang && _translatedBio.isNotEmpty) return;
    setState(() => _translating = true);
    final result = await TranslationService.translate(_bio(), lang);
    if (mounted) {
      setState(() {
        _translating = false;
        if (result.isNotEmpty) {
          _translatedBio  = result;
          _translatedLang = lang;
          _showTranslated = true;
        }
      });
    }
  }

  void _pickTranslationLanguage() {
    const langs = <String, String>{
      'fr': 'Français', 'en': 'English', 'es': 'Español',
      'de': 'Deutsch',  'it': 'Italiano', 'pt': 'Português',
      'ja': '日本語',     'ko': '한국어',    'ar': 'العربية',
    };
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          // Bounded height so the list scrolls instead of being clipped
          // on screens too short to fit every language.
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            children: langs.entries.map((e) => ListTile(
              title: Text(e.value),
              trailing: _translatedLang == e.key && _showTranslated
                  ? const Icon(Icons.check_rounded) : null,
              onTap: () { Navigator.pop(ctx); _translateTo(e.key); },
            )).toList(),
          ),
        ),
      ),
    );
  }

  static List<dynamic> _asList(dynamic v) =>
      v == null ? [] : (v is List ? v : [v]);

  String _bio() {
    final raw = (_info?['bio']?['content'] ?? _info?['wiki']?['content'] ?? '').toString();
    if (raw.isEmpty) return '';
    final idx = raw.indexOf('<a href="https://www.last.fm');
    return idx > 0 ? raw.substring(0, idx).trim() : raw.trim();
  }

  int _globalListeners() =>
      int.tryParse((_info?['stats']?['listeners'] ?? _info?['listeners'] ?? '0').toString()) ?? 0;

  int _globalPlaycount() =>
      int.tryParse((_info?['stats']?['playcount'] ?? _info?['playcount'] ?? '0').toString()) ?? 0;

  List<Map<String, dynamic>> _tags() {
    final tagsField = _info?['tags'] ?? _info?['toptags'];
    if (tagsField == null) return [];
    dynamic raw;
    if (tagsField is List)     { raw = tagsField; }
    else if (tagsField is Map) { raw = tagsField['tag']; }
    else                       { return []; }
    if (raw == null || raw is String) return [];
    final list = raw is List ? raw : [raw];
    return list.whereType<Map>().take(5)
        .map((t) => Map<String, dynamic>.from(t)).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final baseTheme  = Theme.of(context);
    final baseScheme = baseTheme.colorScheme;
    final artworkOn  = artworkColorThemeNotifier.value && _artworkColor != null;

    final targetTheme = artworkOn
        ? () {
            final themed = _artworkScheme(baseScheme, _artworkColor!);
            return baseTheme.copyWith(
              colorScheme:             themed.scheme,
              scaffoldBackgroundColor: themed.surface,
            );
          }()
        : baseTheme.copyWith(scaffoldBackgroundColor: baseScheme.surface);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // AnimatedTheme cross-fades ThemeData on its own — far safer than a
      // hand-rolled TweenAnimationBuilder that rebuilds Theme+Scaffold every
      // frame, which could show a blank/black frame during page transitions.
      child: AnimatedTheme(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        data: targetTheme,
        child: Builder(builder: (innerContext) {
          final scheme  = Theme.of(innerContext).colorScheme;
          final surface = Theme.of(innerContext).scaffoldBackgroundColor;
          return Scaffold(
            body: _buildContent(innerContext, scheme, surface),
          );
        }),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, ColorScheme scheme, Color surface) {
    final mediaH   = MediaQuery.of(ctx).size.height;
    final topPad   = MediaQuery.of(ctx).padding.top;
    final imgH     = mediaH * 0.44;
    final hasImage = _resolvedImage.isNotEmpty;

    return Stack(
      children: [

        // Background image (fullscreen, covers status bar)
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: hasImage
                ? _BlurFadeImage(
                    key: ValueKey(_resolvedImage),
                    url: _resolvedImage,
                    fallback: _DetailGradientBg(scheme: scheme),
                  )
                : _DetailGradientBg(key: const ValueKey('fallback'), scheme: scheme),
          ),
        ),

        // Gradient: dark top → surface at bottom
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                stops:  const [0.0, 0.28, 0.52, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  surface.withValues(alpha: 0.82),
                  surface,
                ],
              ),
            ),
          ),
        ),

        // Scrollable body — pull-down overscroll dismisses the sheet.
        // ClampingScrollPhysics lets the native Android stretch overscroll
        // show through instead of forcing the iOS-style bounce.
        // Image tap is inline in the scroll so the hitbox follows content
        // and never overlaps underlying items when the user scrolls down.
        _DismissOnOverscroll(
          onDismiss: () => Navigator.pop(ctx),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tappable image zone — moves with scroll, no hitbox drift
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasImage ? () => _pushFullscreen(ctx, _resolvedImage) : null,
                  child: SizedBox(height: imgH - 90, width: double.infinity),
                ),
                _buildHeader(ctx, scheme, imgH, hasImage),
                Container(
                  color: surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(scheme),
                      Divider(height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.4)),
                      _buildStatsRow(scheme),
                      if (_tags().isNotEmpty) _buildTags(scheme),
                      if (_bio().isNotEmpty)  _buildBio(scheme),
                      if (widget.type == 'artists' && _topTracks.isNotEmpty)
                        _buildTopTracks(scheme),
                      if (widget.type == 'artists' && _topAlbums.isNotEmpty)
                        _buildTopAlbums(scheme),
                      if (widget.type == 'albums' && _tracklist.isNotEmpty)
                        _buildTracklist(scheme),
                      if (widget.type == 'tracks') _buildTrackExtra(scheme),
                      if (widget.type == 'tracks') _buildLyrics(scheme),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Status bar scrim — always above the scroll content
        _StatusBarScrim(height: topPad),

        // Back button
        Positioned(
          top: topPad + 8, left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext ctx, ColorScheme scheme, double imgH, bool hasImage) {
    final text = Theme.of(ctx).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              switch (widget.type) {
                'artists' => 'Artiste',
                'albums'  => 'Album',
                _         => 'Titre',
              },
              style: TextStyle(
                color: scheme.onPrimary, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _name,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color:      hasImage ? Colors.white : scheme.onSurface,
              shadows:    hasImage
                  ? [Shadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.5))]
                  : null,
            ),
          ),
          if (_artist.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _artist,
              style: text.bodyLarge?.copyWith(
                color:      hasImage
                    ? Colors.white.withValues(alpha: 0.85)
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                shadows: hasImage
                    ? [Shadow(blurRadius: 6, color: Colors.black.withValues(alpha: 0.5))]
                    : null,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Music app link buttons
          _buildMusicLinks(hasImage),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Music app links ─────────────────────────────────────────────────────────

  Widget _buildMusicLinks(bool hasImage) {
    final encodedName   = Uri.encodeComponent(_name);
    final encodedArtist = Uri.encodeComponent(_artist);

    final lfmUrl = switch (widget.type) {
      'artists' => 'https://www.last.fm/music/$encodedName',
      'albums'  => 'https://www.last.fm/music/$encodedArtist/$encodedName',
      _         => 'https://www.last.fm/music/$encodedArtist/_/$encodedName',
    };
    final q       = widget.type == 'artists' ? _name : '$_name $_artist';
    final encoded = Uri.encodeComponent(q);

    final buttons = [
      (label: 'Last.fm',  color: const Color(0xFFD51007), icon: Icons.bar_chart_rounded,         url: lfmUrl),
      (label: 'Spotify',  color: const Color(0xFF1DB954), icon: Icons.spatial_audio_off_rounded,  url: 'https://open.spotify.com/search/$encoded'),
      (label: 'YT Music', color: const Color(0xFFFF0033), icon: Icons.music_video_rounded,        url: 'https://music.youtube.com/search?q=$encoded'),
      (label: 'Web',      color: Colors.white.withValues(alpha: 0.85), icon: Icons.language_rounded, url: 'https://www.google.com/search?q=${Uri.encodeComponent('$q music')}'),
    ];

    Widget chip(({String label, Color color, IconData icon, String url}) b) => Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(b.url);
          try { await launchUrl(uri, mode: LaunchMode.externalApplication); }
          catch (_) { await launchUrl(uri, mode: LaunchMode.platformDefault); }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: hasImage ? 0.38 : 0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (hasImage ? Colors.white : Colors.black).withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(b.icon, size: 14,
                color: hasImage ? Colors.white.withValues(alpha: 0.90) : b.color),
            const SizedBox(width: 5),
            Text(b.label, style: TextStyle(
              color: hasImage ? Colors.white.withValues(alpha: 0.90) : b.color,
              fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ]),
        ),
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: buttons.map(chip).toList(),
    );
  }

  // ── Period selector ─────────────────────────────────────────────────────────

  Widget _buildPeriodSelector(ColorScheme scheme) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: _localizedPeriods().map((p) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(p.$2),
            selected: p.$1 == _period,
            showCheckmark: false,
            onSelected: (_) => _changePeriod(p.$1),
          ),
        )).toList(),
      ),
    );
  }

  // ── Stats row — fills full width with equal-width segments ─────────────────

  Widget _buildStatsRow(ColorScheme scheme) {
    final gl = _globalListeners();
    final gp = _globalPlaycount();

    // Build list of stat widgets so we can lay them out in a full-width row
    final stats = <Widget>[];

    if (widget.type == 'artists' && gl > 0) {
      stats.add(_StatChip(
        icon: Icons.people_rounded, value: _fmt(gl),
        label: L.detailGlobalListeners, scheme: scheme,
      ));
    }
    if (gp > 0) {
      stats.add(_StatChip(
        icon: Icons.play_circle_rounded, value: _fmt(gp),
        label: L.commonPlays, scheme: scheme,
      ));
    }

    if (_loadingUser) {
      stats.add(Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
        ),
      ));
    } else {
      stats.add(_StatChip(
        icon: Icons.headphones_rounded,
        value: _userPlays > 0 ? _fmt(_userPlays) : '—',
        label: L.detailUserPlays, scheme: scheme, highlight: true,
      ));
    }

    if (!_loadingUser && _userRank > 0 && _userRank <= 200) {
      stats.add(_StatChip(
        icon: Icons.leaderboard_rounded, value: '#$_userRank',
        label: L.detailUserRank, scheme: scheme, highlight: true,
      ));
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    // Build row with separators
    final rowChildren = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      rowChildren.add(Expanded(child: stats[i]));
      if (i < stats.length - 1) {
        rowChildren.add(VerticalDivider(
          width: 1, thickness: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: IntrinsicHeight(
        child: Row(children: rowChildren),
      ),
    );
  }

  // ── Tags ────────────────────────────────────────────────────────────────────

  Widget _buildTags(ColorScheme scheme) {
    final tags = _tags();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: tags.map((t) {
          final name = (t['name'] ?? '').toString();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color:        scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: scheme.outlineVariant),
            ),
            child: Text(name, style: TextStyle(
              fontSize: 12, color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            )),
          );
        }).toList(),
      ),
    );
  }

  // ── Bio ─────────────────────────────────────────────────────────────────────

  Widget _buildBio(ColorScheme scheme) {
    final text = Theme.of(context).textTheme;
    final bio  = _showTranslated && _translatedBio.isNotEmpty ? _translatedBio : _bio();
    const maxChars  = 280;
    final truncated = !_bioExpanded && bio.length > maxChars;
    final shown     = truncated ? '${bio.substring(0, maxChars)}…' : bio;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(L.detailBiography,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              _translating
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                      onLongPress: _pickTranslationLanguage,
                      child: TextButton.icon(
                        onPressed: _toggleTranslate,
                        icon: Icon(
                          _showTranslated ? Icons.undo_rounded : Icons.translate_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _showTranslated ? L.detailShowOriginal : L.detailTranslate,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          padding:         const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize:     const Size(0, 0),
                          backgroundColor: scheme.surfaceContainerHighest,
                          foregroundColor: scheme.onSurfaceVariant,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 8),

          // Animated expand/collapse
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Text(
              shown,
              style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant, height: 1.55),
            ),
          ),

          if (bio.length > maxChars) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _bioExpanded = !_bioExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _bioExpanded ? L.detailBioReadLess : L.detailBioReadMore,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns:    _bioExpanded ? -0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve:    Curves.easeInOutCubic,
                    child: Icon(Icons.expand_more_rounded,
                        size: 18, color: scheme.primary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Top tracks (artist view) ────────────────────────────────────────────────

  Widget _buildTopTracks(ColorScheme scheme) {
    final text   = Theme.of(context).textTheme;
    final tracks = _topTracks.take(5).toList();
    final maxPlay = tracks.fold<int>(0, (m, t) {
      final n = int.tryParse((t['playcount'] ?? t['listeners'] ?? '0').toString()) ?? 0;
      return n > m ? n : m;
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.detailTopTracks,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...tracks.asMap().entries.map((e) {
            final i     = e.key;
            final t     = e.value;
            final tName = (t['name'] ?? '').toString();
            final plays = int.tryParse((t['playcount'] ?? t['listeners'] ?? '0').toString()) ?? 0;
            final frac  = maxPlay > 0 ? plays / maxPlay : 0.0;

            return _FadeSlideIn(
              delay: Duration(milliseconds: i * 55),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final item = Map<String, dynamic>.from(t);
                  item['artist'] ??= {'name': _name};
                  Navigator.pop(context);
                  showDetailSheet(context, item, 'tracks', widget.service);
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(children: [
                    SizedBox(
                      width: 20,
                      child: Text('${i + 1}', style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tName, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: frac.clamp(0.0, 1.0)),
                            duration: Duration(milliseconds: 600 + i * 80),
                            curve: Curves.easeOut,
                            builder: (_, v, _) => LinearProgressIndicator(
                              value: v, minHeight: 5,
                              color:           scheme.primary,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Text(_fmt(plays), style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Top albums grid (artist view) ───────────────────────────────────────────

  Widget _buildTopAlbums(ColorScheme scheme) {
    final text   = Theme.of(context).textTheme;
    final albums = _topAlbums.take(8).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.detailTopAlbums,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 10,
              crossAxisSpacing: 10, childAspectRatio: 0.75,
            ),
            itemCount: albums.length,
            itemBuilder: (_, i) {
              final a      = albums[i];
              final aName  = (a['name'] ?? '').toString();
              final imgUrl = _extractImage(a['image']);

              return _FadeSlideIn(
                delay: Duration(milliseconds: i * 40),
                child: GestureDetector(
                  onTap: () {
                    final item = Map<String, dynamic>.from(a);
                    item['artist'] ??= {'name': _name};
                    Navigator.pop(context);
                    showDetailSheet(context, item, 'albums', widget.service);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _SmartImage(
                            size: 80, borderRadius: 8, initialUrl: imgUrl,
                            resolver: () => ImageService.resolveAlbum(
                              aName, _name,
                              lastfmUrl: imgUrl.isNotEmpty ? imgUrl : null),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(aName, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Album tracklist ─────────────────────────────────────────────────────────

  Widget _buildTracklist(ColorScheme scheme) {
    final text   = Theme.of(context).textTheme;
    final tracks = _tracklist;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.detailTracklist,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...tracks.asMap().entries.map((e) {
            final i      = e.key;
            final t      = e.value;
            final tName  = (t['name'] ?? '').toString();
            final dur    = int.tryParse((t['duration'] ?? '0').toString()) ?? 0;
            final durStr = dur > 0
                ? '${dur ~/ 60}:${(dur % 60).toString().padLeft(2, '0')}' : '';

            return _FadeSlideIn(
              delay: Duration(milliseconds: i * 40),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 28,
                  child: Text('${i + 1}', textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ),
                title: Text(tName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                trailing: Text(durStr,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                dense: true,
                onTap: () {
                  final trackItem = Map<String, dynamic>.from(t);
                  trackItem['artist'] ??= {'name': _name};
                  Navigator.pop(context);
                  showDetailSheet(context, trackItem, 'tracks', widget.service);
                },
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Track extra info ────────────────────────────────────────────────────────

  Widget _buildTrackExtra(ColorScheme scheme) {
    final text   = Theme.of(context).textTheme;
    final album  = (_info?['album']?['title'] ?? '').toString();
    final dur    = int.tryParse((_info?['duration'] ?? '0').toString()) ?? 0;
    final durStr = dur > 0
        ? '${dur ~/ 60000}:${((dur % 60000) ~/ 1000).toString().padLeft(2, '0')}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (album.isNotEmpty) ...[
            Text(L.detailAlbumLabel,
                style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(album, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
          ],
          if (durStr.isNotEmpty) ...[
            Text(L.detailDuration,
                style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(durStr, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Lyrics ──────────────────────────────────────────────────────────────────

  Widget _buildLyrics(ColorScheme scheme) {
    final text     = Theme.of(context).textTheme;
    const maxChars = 320;
    final truncated = !_lyricsExpanded && _lyrics.length > maxChars;
    final shown     = truncated ? '${_lyrics.substring(0, maxChars)}…' : _lyrics;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(L.detailLyrics,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              if (_lyrics.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: L.detailCopyLyrics,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _lyrics));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(L.detailLyricsCopied)),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingLyrics)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (_lyrics.isEmpty)
            Text(L.detailLyricsNotFound,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
          else ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: Text(shown,
                  style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant, height: 1.6)),
            ),
            if (_lyrics.length > maxChars) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _lyricsExpanded = !_lyricsExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _lyricsExpanded ? L.detailBioReadLess : L.detailBioReadMore,
                      style: TextStyle(color: scheme.primary,
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns:    _lyricsExpanded ? -0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve:    Curves.easeInOutCubic,
                      child: Icon(Icons.expand_more_rounded,
                          size: 18, color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Background image with blur-to-clear fade-in ───────────────────────────────

class _BlurFadeImage extends StatefulWidget {
  final String url;
  final Widget fallback;
  const _BlurFadeImage({super.key, required this.url, required this.fallback});

  @override
  State<_BlurFadeImage> createState() => _BlurFadeImageState();
}

class _BlurFadeImageState extends State<_BlurFadeImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _blur;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    // Skip animation if already in Flutter's image cache
    final cached = PaintingBinding.instance.imageCache
        .containsKey(NetworkImage(widget.url));
    _imageLoaded = cached;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _blur = Tween<double>(begin: cached ? 0.0 : 16.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (cached) _ctrl.value = 1.0;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onLoaded() {
    if (!mounted || _imageLoaded) return;
    setState(() => _imageLoaded = true);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.fallback,
        AnimatedBuilder(
          animation: _blur,
          builder: (_, child) => ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: _blur.value, sigmaY: _blur.value,
              // mirror avoids edge clipping (dezoom visual bug)
              tileMode: TileMode.mirror,
            ),
            child: child,
          ),
          child: AnimatedOpacity(
            opacity:  _imageLoaded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Image.network(
              widget.url,
              fit: BoxFit.cover,
              width:  double.infinity,
              height: double.infinity,
              color:          Colors.black.withValues(alpha: 0.55),
              colorBlendMode: BlendMode.darken,
              // loadingBuilder: image stays hidden until fully loaded,
              // preventing the intrinsic-size → BoxFit.cover jump
              loadingBuilder: (_, child, progress) {
                if (progress == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _onLoaded());
                }
                return child;
              },
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Fullscreen image viewer ───────────────────────────────────────────────────

// Fullscreen image viewer — supports pinch zoom, close button, tap to dismiss
class _FullscreenImageViewer extends StatefulWidget {
  final String url;
  const _FullscreenImageViewer({required this.url});

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  final _tc     = TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // InteractiveViewer handles pinch-zoom and pan.
          // Inner GestureDetector handles tap-to-dismiss (only when not zoomed).
          InteractiveViewer(
            transformationController: _tc,
            minScale: 0.8,
            maxScale: 6.0,
            onInteractionEnd: (_) => setState(() {
              _isZoomed = _tc.value != Matrix4.identity();
            }),
            child: GestureDetector(
              onTap: () { if (!_isZoomed) Navigator.pop(context); },
              child: Center(
                child: Image.network(
                  widget.url, fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),

          // Close button — always visible, resets zoom then dismisses
          Positioned(
            top: topPad + 8, right: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient fallback when no image is available ──────────────────────────────

class _DetailGradientBg extends StatelessWidget {
  final ColorScheme scheme;
  const _DetailGradientBg({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) => Container(
    color: scheme.surfaceContainerHighest,
    child: Center(
      child: Icon(Icons.music_note_rounded, size: 96,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.35)),
    ),
  );
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData    icon;
  final String      value;
  final String      label;
  final ColorScheme scheme;
  final bool        highlight;

  const _StatChip({
    required this.icon, required this.value,
    required this.label, required this.scheme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg   = highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: highlight ? scheme.primary : fg),
            const SizedBox(width: 5),
            Text(value, style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: highlight ? scheme.primary : scheme.onSurface)),
          ]),
          const SizedBox(height: 2),
          Text(label, style: text.labelSmall?.copyWith(
              color: fg.withValues(alpha: 0.75), fontSize: 10)),
        ],
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════════════════════
//  showProfileSheet — open a user profile from any screen
// ══════════════════════════════════════════════════════════════════════════════

void showProfileSheet(
  BuildContext context,
  String username,
  LastFmService service, {
  bool isFav = false,
  VoidCallback? onToggleFav,
}) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    fullscreenDialog: true,
    pageBuilder: (_, _, _) => _FullProfileSheet(
      username:    username,
      service:     service,
      isFav:       isFav,
      onToggleFav: onToggleFav ?? () {},
    ),
    transitionsBuilder: (_, anim, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration:        const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  ));
}

// ══════════════════════════════════════════════════════════════════════════════
//  Full profile sheet
// ══════════════════════════════════════════════════════════════════════════════

class _FullProfileSheet extends StatefulWidget {
  final String        username;
  final LastFmService service;
  final bool          isFav;
  final VoidCallback  onToggleFav;

  const _FullProfileSheet({
    required this.username, required this.service,
    required this.isFav,    required this.onToggleFav,
  });

  @override
  State<_FullProfileSheet> createState() => _FullProfileSheetState();
}

class _FullProfileSheetState extends State<_FullProfileSheet> {

  Map<String, dynamic>? _info;
  List<dynamic> _topArtists = [];
  List<dynamic> _topAlbums  = [];
  List<dynamic> _recent     = [];

  bool      _loading      = true;
  bool      _isNowPlaying = false;
  String    _bannerUrl    = '';
  Color?    _artworkColor;  // dominant color extracted from banner image
  late bool _localIsFav;

  @override
  void initState() {
    super.initState();
    _localIsFav = widget.isFav;
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait([
        widget.service.getUserInfo(user: widget.username),
        widget.service.getTopArtists(user: widget.username, period: 'overall', limit: 6),
        widget.service.getTopAlbums( user: widget.username, period: 'overall', limit: 6),
        widget.service.getRecentTracks(user: widget.username, limit: 8),
      ]);

      final recentRaw  = (res[3] as Map<String, dynamic>)['track'];
      final recentList = recentRaw is List ? recentRaw
          : (recentRaw != null ? [recentRaw] : <dynamic>[]);
      final firstTrack = recentList.isNotEmpty ? recentList.first as Map : null;
      final isNp = firstTrack?['@attr']?['nowplaying'] == 'true';

      if (mounted) {
        setState(() {
          _info         = res[0] as Map<String, dynamic>?;
          _topArtists   = res[1] as List<dynamic>;
          _topAlbums    = res[2] as List<dynamic>;
          _recent       = recentList;
          _isNowPlaying = isNp;
          _loading      = false;
        });
        _resolveBannerUrl(recentList, isNp);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolveBannerUrl(List<dynamic> recentList, bool isNp) async {
    try {
      String url = '';
      if (isNp && recentList.isNotEmpty) {
        final t      = recentList.first as Map;
        final track  = (t['name'] ?? '').toString();
        final artist = (t['artist']?['name'] ?? t['artist'] ?? '').toString();
        url = await ImageService.resolveTrack(track, artist);
      }
      if (url.isEmpty && _topArtists.isNotEmpty) {
        final a = _topArtists[0] as Map;
        url = await ImageService.resolveArtist(
            (a['name'] ?? '').toString(),
            lastfmUrl: _extractImage(a['image']));
      }
      if (mounted && url.isNotEmpty) {
        setState(() => _bannerUrl = url);
        if (artworkColorThemeNotifier.value) _extractArtworkColor(url);
      }
    } catch (_) {}
  }

  // Same approach as _ItemDetailSheetState: fetch bytes ourselves, then run
  // the cheap histogram-based color extraction (see _extractDominantColorArgb).
  Future<void> _extractArtworkColor(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (!mounted || response.statusCode != 200 || response.bodyBytes.isEmpty) return;

      final argb = await _extractDominantColorArgb(response.bodyBytes);
      if (argb != null && mounted) setState(() => _artworkColor = Color(argb));
    } catch (_) {
      // Network error, timeout, or decode failure: skip the tint silently.
    }
  }

  int _total() => int.tryParse((_info?['playcount'] ?? '0').toString()) ?? 0;

  int _days() {
    final raw = _info?['registered'];
    if (raw == null) return 0;
    int ts = 0;
    if (raw is Map) {
      ts = int.tryParse((raw['#text'] ?? raw['unixtime'] ?? '0').toString()) ?? 0;
    } else {
      ts = int.tryParse(raw.toString()) ?? 0;
    }
    if (ts <= 0) return 0;
    return ((DateTime.now().millisecondsSinceEpoch / 1000 - ts) / 86400).floor();
  }

  double _avg() {
    final d = _days();
    return d > 0 ? _total() / d : 0;
  }

  bool _hasAvatar(String url) => url.isNotEmpty && !url.contains(_ph);

  String _timeAgo(Map t) {
    final raw = t['date']?['uts'] ?? '';
    final ts  = int.tryParse(raw.toString()) ?? 0;
    if (ts == 0) return '';
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours   < 24) return '${diff.inHours}h';
    if (diff.inDays    < 30) return '${diff.inDays}d';
    return '${diff.inDays ~/ 30}mo';
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme  = Theme.of(context);
    final baseScheme = baseTheme.colorScheme;
    final artworkOn  = artworkColorThemeNotifier.value && _artworkColor != null;

    final targetTheme = artworkOn
        ? () {
            final themed = _artworkScheme(baseScheme, _artworkColor!);
            return baseTheme.copyWith(
              colorScheme:             themed.scheme,
              scaffoldBackgroundColor: themed.surface,
            );
          }()
        : baseTheme.copyWith(scaffoldBackgroundColor: baseScheme.surface);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedTheme(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        data: targetTheme,
        child: Builder(builder: (innerContext) {
          final scheme  = Theme.of(innerContext).colorScheme;
          final surface = Theme.of(innerContext).scaffoldBackgroundColor;
          return Scaffold(
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(innerContext, scheme, surface),
          );
        }),
      ),
    );
  }

  // Full-screen layout matching _ItemDetailSheet: blurred banner + scroll
  Widget _buildContent(BuildContext ctx, ColorScheme scheme, Color surface) {
    final mediaH    = MediaQuery.of(ctx).size.height;
    final topPad    = MediaQuery.of(ctx).padding.top;
    final imgH      = mediaH * 0.42;
    final hasImage  = _bannerUrl.isNotEmpty;
    final info      = _info ?? {};
    final avatarUrl = _extractImage(info['image']);
    final hasAv     = _hasAvatar(avatarUrl);

    return Stack(
      children: [
        // Background: blurred banner image or gradient fallback
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: hasImage
                ? _BlurFadeImage(
                    key: ValueKey(_bannerUrl),
                    url: _bannerUrl,
                    fallback: _DetailGradientBg(scheme: scheme),
                  )
                : _DetailGradientBg(
                    key: const ValueKey('fallback'), scheme: scheme),
          ),
        ),

        // Gradient overlay: dark top → surface at bottom
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                stops:  const [0.0, 0.28, 0.52, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  surface.withValues(alpha: 0.82),
                  surface,
                ],
              ),
            ),
          ),
        ),

        // Scrollable content — pull-down-to-dismiss via overscroll.
        // ClampingScrollPhysics lets the native Android stretch overscroll
        // show through instead of forcing the iOS-style bounce.
        _DismissOnOverscroll(
          onDismiss: () => Navigator.pop(ctx),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar tap zone — inline so hitbox moves with scroll
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasAv ? () => _pushFullscreen(ctx, avatarUrl) : null,
                  child: SizedBox(height: imgH - 90, width: double.infinity),
                ),
                _buildProfileHeader(ctx, scheme, hasAv, avatarUrl),
                Container(
                  color: surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(scheme),
                      _buildCompareButton(context),
                      if (_isNowPlaying) _buildNowPlayingCard(scheme),
                      if (_topArtists.isNotEmpty) ...[
                        _sectionHeader(L.commonTopArtists, scheme),
                        ..._topArtists.asMap().entries.map(
                            (e) => _buildArtistRow(ctx, e.value, e.key, scheme)),
                      ],
                      if (_topAlbums.isNotEmpty) ...[
                        _sectionHeader(L.commonAlbums, scheme),
                        _buildAlbumsGrid(ctx, scheme),
                      ],
                      if (_recent.isNotEmpty) ...[
                        _sectionHeader(L.commonRecentTracks, scheme),
                        ..._recent.map((r) => _buildRecentRow(r, scheme)),
                      ],
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Status bar scrim — always above the scroll content
        _StatusBarScrim(height: topPad),

        // Back button — same style as detail sheets
        Positioned(
          top: topPad + 8, left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),

        // Favourite button top-right
        Positioned(
          top: topPad + 8, right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() => _localIsFav = !_localIsFav);
              widget.onToggleFav();
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _localIsFav ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 20,
                color: _localIsFav ? Colors.amber.shade400 : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Profile header (replaces _buildBanner) — same layout as _buildHeader
  // in _ItemDetailSheet: badge chip + avatar + username + meta
  Widget _buildProfileHeader(
      BuildContext ctx, ColorScheme scheme, bool hasAv, String avatarUrl) {
    final info     = _info ?? {};
    final name     = (info['name']     ?? widget.username).toString();
    final realName = (info['realname'] ?? '').toString();
    final country  = (info['country']  ?? '').toString();
    final text     = Theme.of(ctx).textTheme;

    String since = '';
    final rawReg = info['registered'];
    if (rawReg != null) {
      int ts = 0;
      if (rawReg is Map) {
        ts = int.tryParse(
                (rawReg['#text'] ?? rawReg['unixtime'] ?? '0').toString()) ?? 0;
      } else {
        ts = int.tryParse(rawReg.toString()) ?? 0;
      }
      if (ts > 0) {
        since = '${DateTime.fromMillisecondsSinceEpoch(ts * 1000).year}';
      }
    }

    // Text block: badge, username, realname, now-playing chip, meta —
    // all left-aligned, same as the artist/album/track header.
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Profil',
            style: TextStyle(
              color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Text(
          name,
          style: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.5))],
          ),
        ),

        if (realName.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(realName,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
        ],

        if (_isNowPlaying) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:        Colors.greenAccent.shade400.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: Colors.greenAccent.shade400),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.graphic_eq_rounded,
                  size: 12, color: Colors.greenAccent.shade400),
              const SizedBox(width: 4),
              Text(L.commonNowPlayingLong,
                style: TextStyle(
                  color: Colors.greenAccent.shade400,
                  fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],

        if (country.isNotEmpty || since.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              if (country.isNotEmpty && country != 'None')
                _BannerMeta(icon: Icons.location_on_outlined, label: country),
              if (since.isNotEmpty)
                _BannerMeta(
                    icon: Icons.calendar_today_outlined,
                    label: L.memberSince(since)),
            ],
          ),
        ],
      ],
    );

    // Avatar — anchored bottom-right, next to the text block
    final avatar = Stack(alignment: Alignment.center, children: [
      if (_isNowPlaying)
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent.shade400, width: 3),
          ),
        ),
      CircleAvatar(
        radius: 42,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: hasAv ? NetworkImage(avatarUrl) : null,
        child: hasAv ? null : Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
        ),
      ),
      if (_isNowPlaying)
        Positioned(
          right: 2, bottom: 2,
          child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color:  Colors.greenAccent.shade400,
              shape:  BoxShape.circle,
              border: Border.all(color: Colors.black38, width: 2),
            ),
          ),
        ),
    ]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: textColumn),
              const SizedBox(width: 14),
              avatar,
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }


  Widget _buildStatsRow(ColorScheme scheme) {
    final total = _total();
    final avg   = _avg();
    final days  = _days();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Expanded(child: _ProfileStatCard(
          icon: Icons.headphones_rounded, value: _fmtLarge(total),
          label: L.dashScrobbles, scheme: scheme, primary: true,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ProfileStatCard(
          icon: Icons.trending_up_rounded, value: '~${_fmt(avg.round())}',
          label: L.perDay, scheme: scheme,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ProfileStatCard(
          icon: Icons.calendar_month_rounded, value: _fmt(days),
          label: L.activityDays, scheme: scheme,
        )),
      ]),
    );
  }

  Widget _buildCompareButton(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonal(
          onPressed: () => showTasteCompareSheet(ctx, widget.username, widget.service),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.graphic_eq_rounded, size: 16),
              const SizedBox(width: 8),
              Text(
                _ct('Comparer les goûts musicaux', 'Compare Music Taste'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlayingCard(ColorScheme scheme) {
    final np = _recent.isNotEmpty ? _recent.first as Map<String, dynamic> : null;
    if (np == null) return const SizedBox.shrink();
    final track  = (np['name'] ?? '').toString();
    final artist = (np['artist']?['#text'] ?? np['artist']?['name'] ?? '').toString();
    final rawUrl = _extractImage(np['image']);
    final hasImg = rawUrl.isNotEmpty && !rawUrl.contains(_ph);

    return GestureDetector(
      onTap: () {
        final item = Map<String, dynamic>.from(np);
        item['artist'] ??= {'name': artist};
        showDetailSheet(context, item, 'tracks', widget.service);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:  Colors.greenAccent.shade400.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.greenAccent.shade400.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasImg
                  ? Image.network(rawUrl, width: 46, height: 46, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _artBox(46, scheme))
                  : _artBox(46, scheme),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.graphic_eq_rounded, size: 12,
                    color: Colors.greenAccent.shade700),
                const SizedBox(width: 4),
                Text(L.commonNowPlayingBadge,
                  style: TextStyle(
                      color: Colors.greenAccent.shade700,
                      fontSize: 10, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 3),
              Text(track, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
              Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Text(title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: scheme.outlineVariant, height: 1)),
      ]),
    );
  }

  Widget _buildArtistRow(
      BuildContext ctx, dynamic raw, int idx, ColorScheme scheme) {
    final a      = raw as Map<String, dynamic>;
    final name   = (a['name']      ?? '').toString();
    final plays  = int.tryParse((a['playcount'] ?? '0').toString()) ?? 0;
    final imgUrl = _extractImage(a['image']);

    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        showDetailSheet(ctx, a, 'artists', widget.service);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(children: [
          SizedBox(
            width: 24,
            child: Text('${idx + 1}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          _SmartImage(
            size: 44, borderRadius: 22, initialUrl: imgUrl,
            resolver: () => ImageService.resolveArtist(name,
                lastfmUrl: imgUrl.isNotEmpty ? imgUrl : null),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
            Text('${_fmt(plays)} ${L.commonPlays}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: scheme.outlineVariant),
        ]),
      ),
    );
  }

  Widget _buildAlbumsGrid(BuildContext ctx, ColorScheme scheme) {
    final albums = _topAlbums.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 10,
          crossAxisSpacing: 10, childAspectRatio: 0.78,
        ),
        itemCount: albums.length,
        itemBuilder: (_, i) {
          final al      = albums[i] as Map<String, dynamic>;
          final name    = (al['name'] ?? '').toString();
          final plays   = int.tryParse((al['playcount'] ?? '0').toString()) ?? 0;
          final imgUrl  = _extractImage(al['image']);
          final artName = (al['artist']?['name'] ?? '').toString();

          return GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              showDetailSheet(ctx, al, 'albums', widget.service);
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _SmartImage(
                    size: 100, borderRadius: 10, initialUrl: imgUrl,
                    resolver: () => ImageService.resolveAlbum(name, artName,
                        lastfmUrl: imgUrl.isNotEmpty ? imgUrl : null),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
              Text('${_fmt(plays)} ${L.commonPlays}',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 9)),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildRecentRow(dynamic raw, ColorScheme scheme) {
    final t      = raw as Map<String, dynamic>;
    final isNp   = t['@attr']?['nowplaying'] == 'true';
    final track  = (t['name'] ?? '').toString();
    final artist = (t['artist']?['#text'] ?? t['artist']?['name'] ?? '').toString();
    final rawUrl = _extractImage(t['image']);
    final hasImg = rawUrl.isNotEmpty && !rawUrl.contains(_ph);

    return GestureDetector(
      onTap: () {
        final item = Map<String, dynamic>.from(t);
        item['artist'] ??= {'name': artist};
        showDetailSheet(context, item, 'tracks', widget.service);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(children: [
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasImg
                  ? Image.network(rawUrl, width: 44, height: 44, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _artBox(44, scheme))
                  : _artBox(44, scheme),
            ),
            if (isNp)
              Positioned(right: 0, bottom: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color:  Colors.greenAccent.shade400,
                    shape:  BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 1.5),
                  ),
                )),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
            Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          ])),
          isNp
              ? Text(L.commonNowPlayingBadge,
                  style: TextStyle(
                      color: Colors.greenAccent.shade700,
                      fontSize: 10, fontWeight: FontWeight.w800))
              : Text(_timeAgo(t),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _artBox(double size, ColorScheme scheme) => Container(
    width: size, height: size,
    color: scheme.surfaceContainerHighest,
    child: Icon(Icons.music_note_rounded,
      size: size * 0.45,
      color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
  );
}

// ── Banner meta row ───────────────────────────────────────────────────────────

class _BannerMeta extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _BannerMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.75)),
    const SizedBox(width: 4),
    Text(label,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
  ]);
}

// ── Profile stat card ─────────────────────────────────────────────────────────

class _ProfileStatCard extends StatelessWidget {
  final IconData    icon;
  final String      value;
  final String      label;
  final ColorScheme scheme;
  final bool        primary;

  const _ProfileStatCard({
    required this.icon, required this.value,
    required this.label, required this.scheme,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = primary ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: fg.withValues(alpha: 0.8)),
        const SizedBox(height: 5),
        Text(value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800, color: fg, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label,
          textAlign: TextAlign.center, maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg.withValues(alpha: 0.7), fontSize: 9)),
      ]),
    );
  }
}

// ── Compact large-number formatter ────────────────────────────────────────────

String _fmtLarge(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}