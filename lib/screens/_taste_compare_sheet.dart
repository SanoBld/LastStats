part of 'home_screen.dart';

void showTasteCompareSheet(
  BuildContext context,
  String targetUser,
  LastFmService service,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TasteCompareSheet(targetUser: targetUser, service: service),
  );
}

// ── Data model ────────────────────────────────────────────────────────────────

class _SharedMatch {
  final String type;      // 'track' | 'artist' | 'album'
  final String name;
  final String artist;
  final String imageUrl;
  const _SharedMatch({
    required this.type,
    required this.name,
    required this.artist,
    required this.imageUrl,
  });
}

typedef _TasteAnalysis = ({
  double score,
  _SharedMatch? topMatch,
  List<_SharedMatch> sharedArtists,
  List<_SharedMatch> sharedTracks,
  List<_SharedMatch> sharedAlbums,
  String dataLabel,
});

// ── Weight helpers ────────────────────────────────────────────────────────────

// Normalize a count map to [0..1] weights (most played = 1.0).
Map<String, double> _countWeights(Map<String, int> counts) {
  if (counts.isEmpty) return {};
  final max = counts.values.reduce((a, b) => a > b ? a : b).toDouble();
  return {for (final e in counts.entries) e.key: e.value / max};
}

// Convert a ranked API list to position-based weights (rank 0 = 1.0, last ≈ 0).
Map<String, double> _rankWeights(List<dynamic> items, String Function(dynamic) key) {
  final n = items.length;
  if (n == 0) return {};
  return {for (var i = 0; i < n; i++) key(items[i]): 1.0 - (i / n)};
}

// Weighted Jaccard: sum(min) / sum(max) over the union of keys.
double _weightedJaccard(Map<String, double> a, Map<String, double> b) {
  double num = 0, den = 0;
  for (final k in {...a.keys, ...b.keys}) {
    final wa = a[k] ?? 0.0;
    final wb = b[k] ?? 0.0;
    num += wa < wb ? wa : wb;
    den += wa > wb ? wa : wb;
  }
  return den == 0 ? 0.0 : (num / den).clamp(0.0, 1.0);
}

// ── Compatibility logic ────────────────────────────────────────────────────────

_TasteAnalysis _analyzeTaste({
  required Map<String, double> myArtistW,
  required Map<String, double> myTrackW,
  required Map<String, double> myAlbumW,
  required List<dynamic> theirArtists,
  required List<dynamic> theirTracks,
  required List<dynamic> theirAlbums,
  required String dataLabel,
}) {
  String artistKey(dynamic a) => (a['name'] ?? '').toString().toLowerCase();

  String trackKey(dynamic t) {
    final ar = (t['artist']?['name'] ?? t['artist'] ?? '').toString().toLowerCase();
    return '$ar::${(t['name'] ?? '').toString().toLowerCase()}';
  }

  String albumKey(dynamic a) {
    final ar = (a['artist']?['name'] ?? a['artist'] ?? '').toString().toLowerCase();
    return '$ar::${(a['name'] ?? '').toString().toLowerCase()}';
  }

  final theirArtistW = _rankWeights(theirArtists, artistKey);
  final theirTrackW  = _rankWeights(theirTracks,  trackKey);
  final theirAlbumW  = _rankWeights(theirAlbums,  albumKey);

  // Score: artists carry the most long-term signal.
  final score = (
    _weightedJaccard(myArtistW, theirArtistW) * 0.55 +
    _weightedJaccard(myTrackW,  theirTrackW)  * 0.25 +
    _weightedJaccard(myAlbumW,  theirAlbumW)  * 0.20
  ).clamp(0.0, 1.0);

  // Top match: prefer a shared track (most specific), fall back to artist.
  _SharedMatch? topMatch;
  double bestW = -1;
  String? topMatchTrackKey;

  for (final t in theirTracks) {
    final k  = trackKey(t);
    final my = myTrackW[k] ?? 0;
    if (my == 0) continue;
    final w = my * (theirTrackW[k] ?? 0);
    if (w > bestW) {
      bestW = w;
      topMatchTrackKey = k;
      topMatch = _SharedMatch(
        type:     'track',
        name:     (t['name'] ?? '').toString(),
        artist:   (t['artist']?['name'] ?? t['artist'] ?? '').toString(),
        imageUrl: _extractImage(t['image']),
      );
    }
  }

  if (topMatch == null) {
    for (final a in theirArtists) {
      final k  = artistKey(a);
      final my = myArtistW[k] ?? 0;
      if (my == 0) continue;
      final w = my * (theirArtistW[k] ?? 0);
      if (w > bestW) {
        bestW = w;
        topMatch = _SharedMatch(
          type:     'artist',
          name:     (a['name'] ?? '').toString(),
          artist:   '',
          imageUrl: _extractImage(a['image']),
        );
      }
    }
  }

  final topMatchArtistKey = topMatch?.type == 'artist'
      ? topMatch!.name.toLowerCase() : null;

  // Other shared tracks (sorted by combined weight, skip topMatch).
  final rawTracks = <(double, dynamic)>[];
  for (final t in theirTracks) {
    final k = trackKey(t);
    if (k == topMatchTrackKey) continue;
    final my = myTrackW[k] ?? 0;
    if (my == 0) continue;
    rawTracks.add((my * (theirTrackW[k] ?? 0), t));
  }
  rawTracks.sort((a, b) => b.$1.compareTo(a.$1));
  final sharedTracks = rawTracks.take(8).map((c) {
    final t = c.$2;
    return _SharedMatch(
      type:     'track',
      name:     (t['name'] ?? '').toString(),
      artist:   (t['artist']?['name'] ?? t['artist'] ?? '').toString(),
      imageUrl: _extractImage(t['image']),
    );
  }).toList();

  // Shared artists (skip topMatch if artist).
  final rawArtists = <(double, dynamic)>[];
  for (final a in theirArtists) {
    final k = artistKey(a);
    if (k == topMatchArtistKey) continue;
    final my = myArtistW[k] ?? 0;
    if (my == 0) continue;
    rawArtists.add((my * (theirArtistW[k] ?? 0), a));
  }
  rawArtists.sort((a, b) => b.$1.compareTo(a.$1));
  final sharedArtists = rawArtists.take(16).map((c) {
    final a = c.$2;
    return _SharedMatch(
      type:     'artist',
      name:     (a['name'] ?? '').toString(),
      artist:   '',
      imageUrl: _extractImage(a['image']),
    );
  }).toList();

  // Shared albums.
  final rawAlbums = <(double, dynamic)>[];
  for (final a in theirAlbums) {
    final k  = albumKey(a);
    final my = myAlbumW[k] ?? 0;
    if (my == 0) continue;
    rawAlbums.add((my * (theirAlbumW[k] ?? 0), a));
  }
  rawAlbums.sort((a, b) => b.$1.compareTo(a.$1));
  final sharedAlbums = rawAlbums.take(8).map((c) {
    final a = c.$2;
    return _SharedMatch(
      type:     'album',
      name:     (a['name'] ?? '').toString(),
      artist:   (a['artist']?['name'] ?? '').toString(),
      imageUrl: _extractImage(a['image']),
    );
  }).toList();

  return (
    score:         score,
    topMatch:      topMatch,
    sharedArtists: sharedArtists,
    sharedTracks:  sharedTracks,
    sharedAlbums:  sharedAlbums,
    dataLabel:     dataLabel,
  );
}

String _compatibilityTierLabel(double score) {
  final pct = score * 100;
  if (pct >= 80) return _ct('Âmes musicales sœurs',      'Musical soulmates');
  if (pct >= 60) return _ct('Très belle compatibilité',  'Great compatibility');
  if (pct >= 40) return _ct('Quelques points communs',   'Some common ground');
  if (pct >= 20) return _ct('Goûts plutôt différents',   'Fairly different tastes');
  return _ct('Univers musicaux opposés', 'Worlds apart, musically');
}

// ══════════════════════════════════════════════════════════════════════════════
//  Widget
// ══════════════════════════════════════════════════════════════════════════════

class _TasteCompareSheet extends StatefulWidget {
  final String targetUser;
  final LastFmService service;

  const _TasteCompareSheet({required this.targetUser, required this.service});

  @override
  State<_TasteCompareSheet> createState() => _TasteCompareSheetState();
}

class _TasteCompareSheetState extends State<_TasteCompareSheet> {
  bool   _loading = true;
  String? _error;

  String _myUsername  = '';
  String _myAvatar    = '';
  String _theirAvatar = '';

  double             _score         = 0;
  _SharedMatch?      _topMatch;
  List<_SharedMatch> _sharedArtists = [];
  List<_SharedMatch> _sharedTracks  = [];
  List<_SharedMatch> _sharedAlbums  = [];
  String             _dataLabel     = '';

  @override
  void initState() {
    super.initState();
    _myUsername = widget.service.username;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });

    try {
      final isSelf = widget.targetUser.toLowerCase() == _myUsername.toLowerCase();

      // ── My data from full scrobble cache ─────────────────────────────────
      final cachedYears = AllScrobblesService.getCachedYears();
      final hasCached   = cachedYears.isNotEmpty;

      final artistCounts = <String, int>{};
      final trackCounts  = <String, int>{};
      final albumCounts  = <String, int>{};

      if (hasCached) {
        for (final year in cachedYears) {
          final records = AllScrobblesService.getRecordsForYear(year) ?? [];
          for (final r in records) {
            if (r.artist.isEmpty) continue;
            final ak = r.artist.toLowerCase();
            artistCounts[ak] = (artistCounts[ak] ?? 0) + 1;
            if (r.track.isNotEmpty) {
              final tk = '$ak::${r.track.toLowerCase()}';
              trackCounts[tk] = (trackCounts[tk] ?? 0) + 1;
            }
            if (r.album.isNotEmpty) {
              final abk = '$ak::${r.album.toLowerCase()}';
              albumCounts[abk] = (albumCounts[abk] ?? 0) + 1;
            }
          }
        }
      }

      var myArtistW = hasCached ? _countWeights(artistCounts) : <String, double>{};
      var myTrackW  = hasCached ? _countWeights(trackCounts)  : <String, double>{};
      var myAlbumW  = hasCached ? _countWeights(albumCounts)  : <String, double>{};

      // ── API fetches ───────────────────────────────────────────────────────
      // Always: my avatar + their avatar.
      // Not-self: their top 200 artists/tracks/albums.
      // No cache: my top 200 from API as fallback.
      final futs = <Future>[
        widget.service.getUserInfo(user: _myUsername),
        widget.service.getUserInfo(user: widget.targetUser),
        if (!isSelf) ...[
          widget.service.getTopArtists(user: widget.targetUser, period: 'overall', limit: 200),
          widget.service.getTopTracks( user: widget.targetUser, period: 'overall', limit: 200),
          widget.service.getTopAlbums( user: widget.targetUser, period: 'overall', limit: 200),
        ],
        if (!hasCached && !isSelf) ...[
          widget.service.getTopArtists(user: _myUsername, period: 'overall', limit: 200),
          widget.service.getTopTracks( user: _myUsername, period: 'overall', limit: 200),
          widget.service.getTopAlbums( user: _myUsername, period: 'overall', limit: 200),
        ],
        // isSelf with no cache: fetch a few for display
        if (isSelf && !hasCached) ...[
          widget.service.getTopArtists(user: _myUsername, period: 'overall', limit: 16),
          widget.service.getTopTracks( user: _myUsername, period: 'overall', limit: 1),
        ],
      ];

      final res = await Future.wait(futs);
      int i = 0;

      final myInfo    = res[i++] as Map<String, dynamic>?;
      final theirInfo = res[i++] as Map<String, dynamic>?;

      final theirArtists = !isSelf ? res[i++] as List<dynamic> : <dynamic>[];
      final theirTracks  = !isSelf ? res[i++] as List<dynamic> : <dynamic>[];
      final theirAlbums  = !isSelf ? res[i++] as List<dynamic> : <dynamic>[];

      if (!hasCached && !isSelf) {
        final myArtistsFb = res[i++] as List<dynamic>;
        final myTracksFb  = res[i++] as List<dynamic>;
        final myAlbumsFb  = res[i++] as List<dynamic>;
        myArtistW = _rankWeights(myArtistsFb, (a) => (a['name'] ?? '').toString().toLowerCase());
        myTrackW  = _rankWeights(myTracksFb, (t) {
          final ar = (t['artist']?['name'] ?? '').toString().toLowerCase();
          return '$ar::${(t['name'] ?? '').toString().toLowerCase()}';
        });
        myAlbumW  = _rankWeights(myAlbumsFb, (a) {
          final ar = (a['artist']?['name'] ?? '').toString().toLowerCase();
          return '$ar::${(a['name'] ?? '').toString().toLowerCase()}';
        });
      }

      // ── isSelf path ───────────────────────────────────────────────────────
      if (isSelf) {
        List<_SharedMatch> selfArtists = [];
        _SharedMatch? selfTrack;

        if (hasCached) {
          final sorted = artistCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          selfArtists = sorted.take(16).map((e) => _SharedMatch(
            type: 'artist', name: e.key, artist: '', imageUrl: '',
          )).toList();
        } else {
          final artFb = res[i++] as List<dynamic>;
          final trFb  = res[i++] as List<dynamic>;
          selfArtists = artFb.map((a) => _SharedMatch(
            type: 'artist', name: (a['name'] ?? '').toString(),
            artist: '', imageUrl: _extractImage(a['image']),
          )).toList();
          if (trFb.isNotEmpty) {
            selfTrack = _SharedMatch(
              type:     'track',
              name:     (trFb.first['name'] ?? '').toString(),
              artist:   (trFb.first['artist']?['name'] ?? '').toString(),
              imageUrl: _extractImage(trFb.first['image']),
            );
          }
        }

        if (!mounted) return;
        setState(() {
          _myAvatar      = _extractImage(myInfo?['image']);
          _theirAvatar   = _extractImage(myInfo?['image']);
          _score         = 1.0;
          _topMatch      = selfTrack;
          _sharedArtists = selfArtists;
          _sharedTracks  = [];
          _sharedAlbums  = [];
          _dataLabel     = _ct('C\'est votre propre profil !', 'This is your own profile!');
          _loading       = false;
        });
        return;
      }

      // ── Data source label ─────────────────────────────────────────────────
      final uniqueArtists = myArtistW.length;
      final dataLabel = hasCached
          ? _ct(
              '$uniqueArtists artistes de votre historique · top 200 de ${widget.targetUser}',
              '$uniqueArtists artists from your history · ${widget.targetUser}\'s top 200',
            )
          : _ct(
              'Top 200 artistes & titres (API)',
              'Top 200 artists & tracks (API)',
            );

      final analysis = _analyzeTaste(
        myArtistW:    myArtistW,
        myTrackW:     myTrackW,
        myAlbumW:     myAlbumW,
        theirArtists: theirArtists,
        theirTracks:  theirTracks,
        theirAlbums:  theirAlbums,
        dataLabel:    dataLabel,
      );

      if (!mounted) return;
      setState(() {
        _myAvatar      = _extractImage(myInfo?['image']);
        _theirAvatar   = _extractImage(theirInfo?['image']);
        _score         = analysis.score;
        _topMatch      = analysis.topMatch;
        _sharedArtists = analysis.sharedArtists;
        _sharedTracks  = analysis.sharedTracks;
        _sharedAlbums  = analysis.sharedAlbums;
        _dataLabel     = analysis.dataLabel;
        _loading       = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error   = _ct(
          'Impossible de calculer la compatibilité.',
          'Could not work out the compatibility.',
        );
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _ct('Compatibilité musicale', 'Music compatibility'),
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _loading
                      ? _ct('Analyse des goûts musicaux…', 'Analyzing musical taste…')
                      : _dataLabel,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  _buildLoading(scheme)
                else if (_error != null)
                  _ErrorView(message: _error!, onRetry: _load)
                else
                  _buildContent(scheme, text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(ColorScheme scheme) => SizedBox(
    height: 280,
    child: Center(
      child: CircularProgressIndicator(color: scheme.primary),
    ),
  );

  Widget _buildContent(ColorScheme scheme, TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FadeSlideIn(
          delay: const Duration(milliseconds: 20),
          child: Center(
            child: _DuoAvatars(
              myAvatar:      _myAvatar,
              theirAvatar:   _theirAvatar,
              myUsername:    _myUsername,
              theirUsername: widget.targetUser,
            ),
          ),
        ),
        const SizedBox(height: 22),

        _FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: Center(child: _CompatibilityRing(score: _score)),
        ),
        const SizedBox(height: 8),

        _FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: Center(
            child: Text(
              _compatibilityTierLabel(_score),
              style: text.titleSmall?.copyWith(
                  color: scheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 26),

        // Top match card
        if (_topMatch != null) ...[
          _FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: _TopMatchCard(match: _topMatch!),
          ),
          const SizedBox(height: 22),
        ],

        // Shared tracks
        if (_sharedTracks.isNotEmpty) ...[
          _FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: _SharedSection(
              label: _ct('Titres en commun', 'Shared tracks'),
              icon: Icons.music_note_rounded,
              matches: _sharedTracks,
              scheme: scheme,
              text: text,
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Shared artists
        _FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: _SharedSection(
            label: _ct('Artistes en commun', 'Shared artists'),
            icon: Icons.mic_rounded,
            matches: _sharedArtists,
            emptyText: _ct('Aucun artiste en commun trouvé.', 'No shared artists found.'),
            scheme: scheme,
            text: text,
          ),
        ),

        // Shared albums
        if (_sharedAlbums.isNotEmpty) ...[
          const SizedBox(height: 18),
          _FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: _SharedSection(
              label: _ct('Albums en commun', 'Shared albums'),
              icon: Icons.album_rounded,
              matches: _sharedAlbums,
              scheme: scheme,
              text: text,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Shared section with label + chip wrap ──────────────────────────────────────

class _SharedSection extends StatelessWidget {
  final String             label;
  final IconData           icon;
  final List<_SharedMatch> matches;
  final String?            emptyText;
  final ColorScheme        scheme;
  final TextTheme          text;

  const _SharedSection({
    required this.label,
    required this.icon,
    required this.matches,
    required this.scheme,
    required this.text,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: text.labelLarge?.copyWith(
                fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
          ),
        ]),
        const SizedBox(height: 10),
        matches.isEmpty
            ? Text(
                emptyText ?? '',
                style: text.bodySmall?.copyWith(color: scheme.outlineVariant),
              )
            : Wrap(
                spacing:    8,
                runSpacing: 8,
                children: matches.map((m) => _TasteChip(match: m)).toList(),
              ),
      ],
    );
  }
}

// ── Two overlapping avatars ───────────────────────────────────────────────────

class _DuoAvatars extends StatelessWidget {
  final String myAvatar;
  final String theirAvatar;
  final String myUsername;
  final String theirUsername;

  const _DuoAvatars({
    required this.myAvatar,
    required this.theirAvatar,
    required this.myUsername,
    required this.theirUsername,
  });

  Widget _avatar(BuildContext context, String url) {
    final scheme    = Theme.of(context).colorScheme;
    final hasAvatar = url.isNotEmpty && !url.contains(_ph);
    return Container(
      width:  64, height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.surface, width: 3),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.person_rounded, color: scheme.onSurfaceVariant))
            : Icon(Icons.person_rounded, color: scheme.onSurfaceVariant, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _avatar(context, myAvatar),
                Transform.translate(
                  offset: const Offset(-18, 0),
                  child: _avatar(context, theirAvatar),
                ),
              ],
            ),
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Icon(Icons.graphic_eq_rounded, size: 13, color: scheme.onPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$myUsername  •  $theirUsername',
          style: text.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Animated compatibility ring ───────────────────────────────────────────────

class _CompatibilityRing extends StatelessWidget {
  final double score;
  const _CompatibilityRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0, end: score),
      duration: const Duration(milliseconds: 1100),
      curve:    Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: 152, height: 152,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 152, height: 152,
              child: CircularProgressIndicator(
                value:           value,
                strokeWidth:     12,
                strokeCap:       StrokeCap.round,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor:      AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).round()}%',
                  style: text.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface, height: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  _ct('compatibilité', 'compatibility'),
                  style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant, letterSpacing: 0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top match card ────────────────────────────────────────────────────────────

class _TopMatchCard extends StatelessWidget {
  final _SharedMatch match;
  const _TopMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final text     = Theme.of(context).textTheme;
    final hasImage = match.imageUrl.isNotEmpty && !match.imageUrl.contains(_ph);
    final isTrack  = match.type == 'track';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52, height: 52,
              child: hasImage
                  ? Image.network(match.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback(scheme, isTrack))
                  : _fallback(scheme, isTrack),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTrack
                      ? _ct('VOUS ADOREZ TOUS LES DEUX', 'YOU BOTH LOVE')
                      : _ct('ARTISTE PRÉFÉRÉ EN COMMUN', 'SHARED TOP ARTIST'),
                  style: text.labelSmall?.copyWith(
                    color:         scheme.onPrimaryContainer.withValues(alpha: 0.65),
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize:      10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  match.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer),
                ),
                if (match.artist.isNotEmpty)
                  Text(
                    match.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),
          Icon(Icons.favorite_rounded, color: scheme.primary, size: 20),
        ],
      ),
    );
  }

  Widget _fallback(ColorScheme scheme, bool isTrack) => Container(
    color: scheme.primary.withValues(alpha: 0.12),
    child: Icon(
      isTrack ? Icons.music_note_rounded : Icons.mic_rounded,
      color: scheme.primary,
    ),
  );
}

// ── Chip for shared items ─────────────────────────────────────────────────────

class _TasteChip extends StatelessWidget {
  final _SharedMatch match;
  const _TasteChip({required this.match});

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final text     = Theme.of(context).textTheme;
    final hasImage = match.imageUrl.isNotEmpty && !match.imageUrl.contains(_ph);

    final icon = switch (match.type) {
      'track' => Icons.music_note_rounded,
      'album' => Icons.album_rounded,
      _       => Icons.mic_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              width: 20, height: 20,
              child: hasImage
                  ? Image.network(match.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(icon, size: 12, color: scheme.onSurfaceVariant))
                  : Icon(icon, size: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              match.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}