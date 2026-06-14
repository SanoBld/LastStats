// ignore_for_file: unused_import
part of 'home_screen.dart';

// url_launcher is used for music app deep links
// Add 'url_launcher: ^6.0.0' to pubspec.yaml if not already present


void showDetailSheet(
  BuildContext context,
  Map<String, dynamic> item,
  String type,          // 'artists' | 'albums' | 'tracks'
  LastFmService service,
) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    fullscreenDialog: true,
    pageBuilder:        (_, __, ___) => _ItemDetailSheet(item: item, type: type, service: service),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
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
    if (mounted) setState(() => _resolvedImage = url);
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
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: langs.entries.map((e) => ListTile(
            title: Text(e.value),
            trailing: _translatedLang == e.key && _showTranslated
                ? const Icon(Icons.check_rounded) : null,
            onTap: () { Navigator.pop(ctx); _translateTo(e.key); },
          )).toList(),
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

  void _openFullscreen(BuildContext ctx, String url) {
    Navigator.of(ctx).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => _FullscreenImageViewer(url: url),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: _buildContent(context, scheme),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, ColorScheme scheme) {
    final mediaH   = MediaQuery.of(ctx).size.height;
    final topPad   = MediaQuery.of(ctx).padding.top;
    final imgH     = mediaH * 0.44;
    final hasImage = _resolvedImage.isNotEmpty;

    return Stack(
      children: [

        // ── Background image (fullscreen, covers status bar) ──────────────
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

        // ── Gradient: dark top band + fade to surface at bottom ───────────
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
                  scheme.surface.withValues(alpha: 0.82),
                  scheme.surface,
                ],
              ),
            ),
          ),
        ),

        // ── Scrollable body ───────────────────────────────────────────────
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: imgH - 90),
              _buildHeader(ctx, scheme, imgH, hasImage),
              Container(
                color: scheme.surface,
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

        // ── Image zone: tap = fullscreen, swipe down = dismiss ───────────
        if (hasImage)
          Positioned(
            top: 0, left: 0, right: 0,
            height: imgH - 80,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _openFullscreen(ctx, _resolvedImage),
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(ctx);
              },
            ),
          ),

        // ── Back button ───────────────────────────────────────────────────
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
    // Build search query depending on type
    final q = switch (widget.type) {
      'artists' => _name,
      'albums'  => '$_name $_artist',
      _         => '$_name $_artist',
    };
    final encoded = Uri.encodeComponent(q);

    final buttons = [
      (
        label: 'Spotify',
        color: const Color(0xFF1DB954),
        icon:  Icons.spatial_audio_off_rounded,
        url:   'https://open.spotify.com/search/$encoded',
      ),
      (
        label: 'YT Music',
        color: const Color(0xFFFF0033),
        icon:  Icons.music_video_rounded,
        url:   'https://music.youtube.com/search?q=$encoded',
      ),
      (
        label: 'Web',
        color: Colors.white.withValues(alpha: 0.85),
        icon:  Icons.language_rounded,
        url:   'https://www.google.com/search?q=${Uri.encodeComponent(q + " music")}',
      ),
    ];

    return Row(
      children: buttons.map((b) => Padding(
        padding: const EdgeInsets.only(right: 8),
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
                color: (hasImage ? Colors.white : Colors.black)
                    .withValues(alpha: 0.18),
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
      )).toList(),
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

// ── Background image with blur-to-clear fade-in ──────────────────────────────

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _blur = Tween<double>(begin: 16.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
              // loadingBuilder: image stays hidden (opacity 0) until fully loaded
              // avoids the intrinsic-size → BoxFit.cover jump
              loadingBuilder: (_, child, progress) {
                if (progress == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _onLoaded());
                }
                return child;
              },
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    ),
  );
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

// ── Fullscreen image viewer ───────────────────────────────────────────────────

class _FullscreenImageViewer extends StatelessWidget {
  final String url;
  const _FullscreenImageViewer({required this.url});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: GestureDetector(
      onTap: () => Navigator.pop(context),
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity?.abs() ?? 0) > 200) Navigator.pop(context);
      },
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_rounded,
              color: Colors.white54, size: 64,
            ),
          ),
        ),
      ),
    ),
  );
}

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
    final text    = Theme.of(context).textTheme;
    final bg      = highlight ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg      = highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

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