// ignore_for_file: unused_import
part of 'home_screen.dart';


void showDetailSheet(
  BuildContext context,
  Map<String, dynamic> item,
  String type,          // 'artists' | 'albums' | 'tracks'
  LastFmService service,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ItemDetailSheet(item: item, type: type, service: service),
  );
}


class _ItemDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String               type;    // 'artists' | 'albums' | 'tracks'
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

  // State
  bool _loadingUser   = true;
  bool _bioExpanded   = false;
  String _period      = 'overall';

  String _resolvedImage = '';

  // Global Last.fm data
  Map<String, dynamic>? _info;        // artist.getInfo / album.getInfo / track.getInfo
  List<dynamic>         _topTracks  = [];   // artist top tracks
  List<dynamic>         _topAlbums  = [];   // artist top albums
  List<dynamic>         _tracklist  = [];   // album tracklist

  // User-specific
  int _userPlays = 0;
  int _userRank  = -1;

  // Translation (bio)
  bool   _translating    = false;
  bool   _showTranslated = false;
  String _translatedBio  = '';

  // Lyrics (tracks)
  bool   _loadingLyrics = false;
  String _lyrics        = '';

  // Helpers
  String get _name   => (widget.item['name']             ?? '').toString();
  String get _artist => (widget.item['artist']?['name']  ?? '').toString();

  // Init
  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    _resolveImage();
    await Future.wait([_fetchMeta(), _fetchUserStats()]);
  }

  // Resolve best image URL
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
    if (mounted) { setState(() => _resolvedImage = url); }
  }

  // Fetch Last.fm metadata (bio, global stats, top tracks, top albums, tracklist)
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
            _info       = results[0] as Map<String, dynamic>?;
            _topTracks  = results[1] as List<dynamic>;
            _topAlbums  = results[2] as List<dynamic>;
          });
          }

        case 'albums':
          final info = await widget.service.getAlbumInfo(_name, _artist);
          if (mounted) {
            setState(() {
            _info      = info;
            _tracklist = _asList(info?['tracks']?['track']);
          });
          }

        case 'tracks':
          final info = await widget.service.getTrackInfo(_name, _artist);
          if (mounted) { setState(() => _info = info); }
          _fetchLyrics();
      }
    } catch (_) {
      // Silent fail — show what we have
    } finally {
    }
  }

  // Fetch user's rank + plays for current period
  Future<void> _fetchUserStats() async {
    try {
      final stats = await widget.service.getUserItemStats(
        type:       widget.type,
        name:       _name,
        artistName: _artist,
        period:     _period,
      );
      if (mounted) {
        setState(() {
        _userPlays = stats.plays;
        _userRank  = stats.rank;
        _loadingUser = false;
      });
      }
    } catch (_) {
      if (mounted) { setState(() => _loadingUser = false); }
    }
  }

  Future<void> _changePeriod(String p) async {
    if (p == _period) return;
    setState(() { _period = p; _loadingUser = true; _userPlays = 0; _userRank = -1; });
    await _fetchUserStats();
  }

  // Fetch lyrics from lyrics.ovh (tracks only)
  Future<void> _fetchLyrics() async {
    setState(() => _loadingLyrics = true);
    final lyrics = await LyricsService.getLyrics(_artist, _name);
    if (mounted) {
      setState(() {
        _lyrics = lyrics;
        _loadingLyrics = false;
      });
    }
  }

  // Translate bio to the app's current language (toggle on/off)
  Future<void> _toggleTranslate() async {
    if (_showTranslated) {
      setState(() => _showTranslated = false);
      return;
    }
    if (_translatedBio.isNotEmpty) {
      setState(() => _showTranslated = true);
      return;
    }
    setState(() => _translating = true);
    final result = await TranslationService.translate(_bio(), localeNotifier.value);
    if (mounted) {
      setState(() {
        _translating = false;
        if (result.isNotEmpty) {
          _translatedBio  = result;
          _showTranslated = true;
        }
      });
    }
  }

  // Helpers
  static List<dynamic> _asList(dynamic v) =>
      v == null ? [] : (v is List ? v : [v]);

  String _bio() {
    final raw = (_info?['bio']?['content'] ?? _info?['wiki']?['content'] ?? '').toString();
    if (raw.isEmpty) return '';
    // Remove Last.fm trailing links
    final idx = raw.indexOf('<a href="https://www.last.fm');
    return idx > 0 ? raw.substring(0, idx).trim() : raw.trim();
  }

  int _globalListeners() =>
      int.tryParse((_info?['stats']?['listeners']  ?? _info?['listeners']  ?? '0').toString()) ?? 0;

  int _globalPlaycount() =>
      int.tryParse((_info?['stats']?['playcount']  ?? _info?['playcount']  ?? '0').toString()) ?? 0;

  List<Map<String, dynamic>> _tags() {
    // Last.fm uses 'tags' for albums, 'toptags' for artists/tracks.
    // The value can be a Map {"tag": [...]}, a direct List, or null/String.
    final tagsField = _info?['tags'] ?? _info?['toptags'];
    if (tagsField == null) return [];

    dynamic raw;
    if (tagsField is List) {
      raw = tagsField; // already a flat list, no wrapper key
    } else if (tagsField is Map) {
      raw = tagsField['tag'];
    } else {
      return [];
    }

    if (raw == null || raw is String) return [];
    final list = raw is List ? raw : [raw];
    return list
        .whereType<Map>()
        .take(5)
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize:     0.5,
      maxChildSize:     1.0,
      expand: false,
      builder: (ctx, scrollCtrl) => _buildContent(ctx, scrollCtrl, scheme),
    );
  }

  Widget _buildContent(BuildContext ctx, ScrollController scrollCtrl, ColorScheme scheme) {
    final mediaH   = MediaQuery.of(ctx).size.height;
    final imgH     = mediaH * 0.38;
    final hasImage = _resolvedImage.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Stack(
        children: [
          // ── Background image (or gradient fallback) ──────────
          Positioned.fill(
            child: hasImage
                ? Image.network(
                    _resolvedImage,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.55),
                    colorBlendMode: BlendMode.darken,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => _DetailGradientBg(scheme: scheme),
                  )
                : _DetailGradientBg(scheme: scheme),
          ),

          // ── Frosted overlay (bottom fade to surface) ──────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  stops: const [0.0, 0.30, 0.55, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    scheme.surface.withValues(alpha: 0.85),
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────
          SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space for the image area
                SizedBox(height: imgH - 80),

                // Header
                _buildHeader(ctx, scheme, imgH, hasImage),

                // White surface body
                Container(
                  color: scheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      _buildPeriodSelector(),

                      const Divider(height: 1),

                      // Stats row
                      _buildStatsRow(scheme),

                      const Divider(height: 1),

                      // Tags
                      if (_tags().isNotEmpty) ...[
                        _buildTags(scheme),
                        const Divider(height: 1),
                      ],

                      // Bio
                      if (_bio().isNotEmpty) _buildBio(scheme),

                      // Artist-specific sections
                      if (widget.type == 'artists' && _topTracks.isNotEmpty)
                        _buildTopTracks(scheme),

                      if (widget.type == 'artists' && _topAlbums.isNotEmpty)
                        _buildTopAlbums(scheme),

                      // Album tracklist
                      if (widget.type == 'albums' && _tracklist.isNotEmpty)
                        _buildTracklist(scheme),

                      // Track: album link
                      if (widget.type == 'tracks') _buildTrackExtra(scheme),

                      // Track: lyrics
                      if (widget.type == 'tracks') _buildLyrics(scheme),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Close button ──────────────────────────────────────
          Positioned(
            top: 16, right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color:  Colors.black.withValues(alpha: 0.5),
                    shape:  BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),

          // ── Drag handle ───────────────────────────────────────
          Positioned(
            top: 12, left: 0, right: 0,
            child: Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color:        Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader(BuildContext ctx, ColorScheme scheme, double imgH, bool hasImage) {
    final text = Theme.of(ctx).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color:        scheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              switch (widget.type) {
                'artists' => 'Artiste',
                'albums'  => 'Album',
                _         => 'Titre',
              },
              style: TextStyle(
                color:      scheme.onPrimary,
                fontSize:   11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            _name,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color:      hasImage ? Colors.white : scheme.onSurface,
              shadows: hasImage
                  ? [Shadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.5))]
                  : null,
            ),
          ),

          // Artist name (for albums/tracks)
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Period selector ────────────────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(ColorScheme scheme) {
    final gl     = _globalListeners();
    final gp     = _globalPlaycount();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Wrap(
        spacing: 12, runSpacing: 12,
        children: [
          // Global listeners (artists only)
          if (widget.type == 'artists' && gl > 0)
            _StatChip(
              icon:  Icons.people_rounded,
              value: _fmt(gl),
              label: L.detailGlobalListeners,
              scheme: scheme,
            ),

          // Global plays
          if (gp > 0)
            _StatChip(
              icon:  Icons.play_circle_rounded,
              value: _fmt(gp),
              label: L.commonPlays,
              scheme: scheme,
            ),

          // User plays
          _loadingUser
              ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                )
              : _StatChip(
                  icon:  Icons.headphones_rounded,
                  value: _userPlays > 0 ? _fmt(_userPlays) : '—',
                  label: L.detailUserPlays,
                  scheme: scheme,
                  highlight: true,
                ),

          // User rank
          if (!_loadingUser && _userRank > 0 && _userRank <= 200)
            _StatChip(
              icon:  Icons.leaderboard_rounded,
              value: '#$_userRank',
              label: L.detailUserRank,
              scheme: scheme,
              highlight: true,
            ),
        ],
      ),
    );
  }

  // ── Tags ───────────────────────────────────────────────────────────────────
  Widget _buildTags(ColorScheme scheme) {
    final tags = _tags();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: tags.map((t) {
          final name = (t['name'] ?? '').toString();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: scheme.outlineVariant),
            ),
            child: Text(name,
              style: TextStyle(
                fontSize:   12,
                color:      scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bio ────────────────────────────────────────────────────────────────────
  Widget _buildBio(ColorScheme scheme) {
    final text = Theme.of(context).textTheme;
    final bio  = _showTranslated && _translatedBio.isNotEmpty ? _translatedBio : _bio();
    const maxChars = 280;
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
              // Translate / show-original toggle button
              _translating
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: _toggleTranslate,
                      icon: const Icon(Icons.translate_rounded, size: 16),
                      label: Text(
                        _showTranslated ? L.detailShowOriginal : L.detailTranslate,
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 8),
          Text(shown,
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (bio.length > maxChars) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _bioExpanded = !_bioExpanded),
              child: Text(
                _bioExpanded ? '${L.detailBioReadLess} ▲' : '${L.detailBioReadMore} ▼',
                style: TextStyle(
                  color:      scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: scheme.outlineVariant),
        ],
      ),
    );
  }

  // ── Top tracks (artist view) ───────────────────────────────────────────────
  Widget _buildTopTracks(ColorScheme scheme) {
    final text      = Theme.of(context).textTheme;
    final tracks    = _topTracks.take(5).toList();
    final maxPlay   = tracks.fold<int>(0, (m, t) {
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

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('${i + 1}',
                      style: text.bodySmall?.copyWith(
                        color:      scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: frac.clamp(0.0, 1.0)),
                            duration: Duration(milliseconds: 600 + i * 80),
                            curve:    Curves.easeOut,
                            builder: (_, v, _) => LinearProgressIndicator(
                              value:            v,
                              minHeight:        5,
                              color:            scheme.primary,
                              backgroundColor:  scheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_fmt(plays),
                    style: text.bodySmall?.copyWith(
                      color:      scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(color: scheme.outlineVariant),
        ],
      ),
    );
  }

  // ── Top albums grid (artist view) ─────────────────────────────────────────
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
              crossAxisCount:   4,
              mainAxisSpacing:  10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: albums.length,
            itemBuilder: (_, i) {
              final a     = albums[i];
              final aName = (a['name'] ?? '').toString();
              final imgUrl = _extractImage(a['image']);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _SmartImage(
                        size: 80, borderRadius: 8,
                        initialUrl: imgUrl,
                        resolver: () => ImageService.resolveAlbum(
                          aName, _name, lastfmUrl: imgUrl.isNotEmpty ? imgUrl : null),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(aName,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: scheme.outlineVariant),
        ],
      ),
    );
  }

  // ── Album tracklist ────────────────────────────────────────────────────────
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
            final i    = e.key;
            final t    = e.value;
            final tName = (t['name'] ?? '').toString();
            final dur  = int.tryParse((t['duration'] ?? '0').toString()) ?? 0;
            final durStr = dur > 0
                ? '${dur ~/ 60}:${(dur % 60).toString().padLeft(2, '0')}'
                : '';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 28,
                child: Text('${i + 1}',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              title: Text(tName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              trailing: Text(durStr, style: text.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
              dense: true,
              onTap: () {
                final trackItem = Map<String, dynamic>.from(t);
                trackItem['artist'] ??= {'name': _name};
                Navigator.pop(context);
                showDetailSheet(context, trackItem, 'tracks', widget.service);
              },
            );
          }),
          Divider(color: scheme.outlineVariant),
        ],
      ),
    );
  }

  // ── Track extra info ───────────────────────────────────────────────────────
  Widget _buildTrackExtra(ColorScheme scheme) {
    final text    = Theme.of(context).textTheme;
    final album   = (_info?['album']?['title'] ?? '').toString();
    final dur     = int.tryParse((_info?['duration'] ?? '0').toString()) ?? 0;
    final durStr  = dur > 0
        ? '${dur ~/ 60000}:${((dur % 60000) ~/ 1000).toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (album.isNotEmpty) ...[
            Text(L.detailAlbumLabel, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(album, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
          ],
          if (durStr.isNotEmpty) ...[
            Text(L.detailDuration, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(durStr, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
          Divider(color: scheme.outlineVariant),
        ],
      ),
    );
  }

  // ── Lyrics ──────────────────────────────────────────────────────────────────
  Widget _buildLyrics(ColorScheme scheme) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.detailLyrics,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (_loadingLyrics)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (_lyrics.isEmpty)
            Text(L.detailLyricsNotFound,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
          else
            Text(_lyrics,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          const SizedBox(height: 16),
          Divider(color: scheme.outlineVariant),
        ],
      ),
    );
  }
}


// Solid-color fallback shown in the header area when no cover image is available
class _DetailGradientBg extends StatelessWidget {
  final ColorScheme scheme;
  const _DetailGradientBg({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 96,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// Small stat chip

class _StatChip extends StatelessWidget {
  final IconData    icon;
  final String      value;
  final String      label;
  final ColorScheme scheme;
  final bool        highlight;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.scheme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bg   = highlight ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg   = highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color:      fg,
                )),
              Text(label,
                style: text.labelSmall?.copyWith(
                  color:   fg.withValues(alpha: 0.8),
                  fontSize: 10,
                )),
            ],
          ),
        ],
      ),
    );
  }
}


// Charts