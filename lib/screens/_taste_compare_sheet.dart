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
  final int    myPlays;
  final int    theirPlays;
  const _SharedMatch({
    required this.type,
    required this.name,
    required this.artist,
    required this.imageUrl,
    this.myPlays    = 0,
    this.theirPlays = 0,
  });
}

typedef _TasteAnalysis = ({
  double score,
  _SharedMatch? topMatch,
  List<_SharedMatch> sharedArtists,
  List<_SharedMatch> sharedTracks,
  List<_SharedMatch> sharedAlbums,
  String dataLabel,
  int totalSharedArtists,
  int totalSharedTracks,
  int totalSharedAlbums,
  List<String> sharedGenres,
});

// ── Weight helpers ────────────────────────────────────────────────────────────

// Extract integer playcount from a Last.fm item map.
int _playcount(dynamic m) => int.tryParse((m['playcount'] ?? '0').toString()) ?? 0;

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

// Normalize an arbitrary double-weight map to [0..1] (max = 1.0).
Map<String, double> _normalizeWeights(Map<String, double> raw) {
  if (raw.isEmpty) return {};
  final max = raw.values.reduce((a, b) => a > b ? a : b);
  if (max <= 0) return {};
  return {for (final e in raw.entries) e.key: e.value / max};
}

// Build a genre/tag weight map from a list of artists: each artist spreads
// its own weight (how much it matters to that listener) across its top tags.
// Lets two people who share zero artists still match if they both listen to
// e.g. "indie rock" / "synthpop".
Map<String, double> _buildGenreWeights(
  List<String> artistNames,
  Map<String, double> artistWeight,
  Map<String, List<dynamic>> tagsByArtist,
) {
  final raw = <String, double>{};
  for (final name in artistNames) {
    final tags = tagsByArtist[name];
    if (tags == null || tags.isEmpty) continue;
    final aw = artistWeight[name] ?? 0.3;
    for (final t in tags.take(5)) {
      final tag = (t['name'] ?? '').toString().toLowerCase();
      if (tag.isEmpty) continue;
      raw[tag] = (raw[tag] ?? 0) + aw;
    }
  }
  return _normalizeWeights(raw);
}

// Overlap score: avg recall from each side, then x*(2-x) curve.
// 50% shared artists → ~75%, 25% → ~44%. More intuitive than Jaccard.
double _overlapScore(Map<String, double> a, Map<String, double> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  double shared = 0, sumA = 0, sumB = 0;
  for (final wa in a.values) sumA += wa;
  for (final wb in b.values) sumB += wb;
  for (final k in a.keys) {
    final wb = b[k];
    if (wb != null) {
      final wa = a[k]!;
      shared += wa < wb ? wa : wb;
    }
  }
  final recA = sumA > 0 ? (shared / sumA).clamp(0.0, 1.0) : 0.0;
  final recB = sumB > 0 ? (shared / sumB).clamp(0.0, 1.0) : 0.0;
  final raw  = (recA + recB) / 2.0;
  return raw * (2.0 - raw);
}

// ── Compatibility logic ────────────────────────────────────────────────────────

_TasteAnalysis _analyzeTaste({
  required Map<String, double> myArtistW,
  required Map<String, double> myTrackW,
  required Map<String, double> myAlbumW,
  required Map<String, int>    myArtistCounts,
  required Map<String, int>    myTrackCounts,
  required Map<String, int>    myAlbumCounts,
  required List<dynamic> theirArtists,
  required List<dynamic> theirTracks,
  required List<dynamic> theirAlbums,
  required Map<String, double> myGenreW,
  required Map<String, double> theirGenreW,
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

  // Score: artists carry the most long-term signal, but genres catch the
  // case where two people share zero exact artists/tracks yet listen to
  // the same kind of music — that used to drag the score down unfairly.
  final artistScore = _overlapScore(myArtistW, theirArtistW);
  final trackScore  = _overlapScore(myTrackW,  theirTrackW);
  final albumScore  = _overlapScore(myAlbumW,  theirAlbumW);
  final hasGenreData = myGenreW.isNotEmpty && theirGenreW.isNotEmpty;
  final genreScore  = hasGenreData ? _overlapScore(myGenreW, theirGenreW) : 0.0;

  final base = artistScore * 0.45 + trackScore * 0.20 + albumScore * 0.15;
  final score = (hasGenreData
          ? base + genreScore * 0.20   // 0.45+0.20+0.15+0.20 = 1.0
          : base / 0.80)               // rescale to 0..1 when no genre data
      .clamp(0.0, 1.0);

  // Top shared genres (by combined weight), for display.
  final genreOverlap = <(double, String)>[];
  for (final entry in myGenreW.entries) {
    final theirW = theirGenreW[entry.key];
    if (theirW == null) continue;
    final w = entry.value < theirW ? entry.value : theirW;
    genreOverlap.add((w, entry.key));
  }
  genreOverlap.sort((a, b) => b.$1.compareTo(a.$1));
  final sharedGenres = genreOverlap.take(6).map((e) {
    final g = e.$2;
    return g.isEmpty ? g : g[0].toUpperCase() + g.substring(1);
  }).toList();

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
        type:       'track',
        name:       (t['name'] ?? '').toString(),
        artist:     (t['artist']?['name'] ?? t['artist'] ?? '').toString(),
        imageUrl:   _extractImage(t['image']),
        myPlays:    myTrackCounts[k] ?? 0,
        theirPlays: _playcount(t),
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
          type:       'artist',
          name:       (a['name'] ?? '').toString(),
          artist:     '',
          imageUrl:   _extractImage(a['image']),
          myPlays:    myArtistCounts[k] ?? 0,
          theirPlays: _playcount(a),
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
  final totalSharedTracks = rawTracks.length + (topMatchTrackKey != null ? 1 : 0);
  final sharedTracks = rawTracks.take(12).map((c) {
    final t = c.$2;
    final k = trackKey(t);
    return _SharedMatch(
      type:       'track',
      name:       (t['name'] ?? '').toString(),
      artist:     (t['artist']?['name'] ?? t['artist'] ?? '').toString(),
      imageUrl:   _extractImage(t['image']),
      myPlays:    myTrackCounts[k] ?? 0,
      theirPlays: _playcount(t),
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
  final totalSharedArtists = rawArtists.length + (topMatchArtistKey != null ? 1 : 0);
  final sharedArtists = rawArtists.take(20).map((c) {
    final a = c.$2;
    final k = artistKey(a);
    return _SharedMatch(
      type:       'artist',
      name:       (a['name'] ?? '').toString(),
      artist:     '',
      imageUrl:   _extractImage(a['image']),
      myPlays:    myArtistCounts[k] ?? 0,
      theirPlays: _playcount(a),
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
  final totalSharedAlbums = rawAlbums.length;
  final sharedAlbums = rawAlbums.take(12).map((c) {
    final a = c.$2;
    final k = albumKey(a);
    return _SharedMatch(
      type:       'album',
      name:       (a['name'] ?? '').toString(),
      artist:     (a['artist']?['name'] ?? '').toString(),
      imageUrl:   _extractImage(a['image']),
      myPlays:    myAlbumCounts[k] ?? 0,
      theirPlays: _playcount(a),
    );
  }).toList();

  return (
    score:               score,
    topMatch:            topMatch,
    sharedArtists:       sharedArtists,
    sharedTracks:        sharedTracks,
    sharedAlbums:        sharedAlbums,
    dataLabel:           dataLabel,
    totalSharedArtists:  totalSharedArtists,
    totalSharedTracks:   totalSharedTracks,
    totalSharedAlbums:   totalSharedAlbums,
    sharedGenres:        sharedGenres,
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
  int                _totalArtists  = 0;
  int                _totalTracks   = 0;
  int                _totalAlbums   = 0;
  List<String>       _sharedGenres  = [];

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

      // Bug fix: if cache exists but records have no artist metadata (v1 format),
      // myArtistW will be empty. Fall back to API in that case.
      final hasMeaningfulData = myArtistW.isNotEmpty;

      // ── API fetches ───────────────────────────────────────────────────────
      // Always: my avatar + their avatar.
      // Not-self: their top 200 artists/tracks/albums.
      // No meaningful cache: my top 200 from API as fallback.
      final futs = <Future>[
        widget.service.getUserInfo(user: _myUsername),
        widget.service.getUserInfo(user: widget.targetUser),
        if (!isSelf) ...[
          widget.service.getTopArtists(user: widget.targetUser, period: 'overall', limit: 200),
          widget.service.getTopTracks( user: widget.targetUser, period: 'overall', limit: 200),
          widget.service.getTopAlbums( user: widget.targetUser, period: 'overall', limit: 200),
        ],
        if (!hasMeaningfulData && !isSelf) ...[
          widget.service.getTopArtists(user: _myUsername, period: 'overall', limit: 200),
          widget.service.getTopTracks( user: _myUsername, period: 'overall', limit: 200),
          widget.service.getTopAlbums( user: _myUsername, period: 'overall', limit: 200),
        ],
        // isSelf with no cache: fetch a few for display
        if (isSelf && !hasMeaningfulData) ...[
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

      if (!hasMeaningfulData && !isSelf) {
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
        // Real playcounts from the API fallback, for display in detail view.
        for (final a in myArtistsFb) {
          artistCounts[(a['name'] ?? '').toString().toLowerCase()] = _playcount(a);
        }
        for (final t in myTracksFb) {
          final ar = (t['artist']?['name'] ?? '').toString().toLowerCase();
          trackCounts['$ar::${(t['name'] ?? '').toString().toLowerCase()}'] = _playcount(t);
        }
        for (final a in myAlbumsFb) {
          final ar = (a['artist']?['name'] ?? '').toString().toLowerCase();
          albumCounts['$ar::${(a['name'] ?? '').toString().toLowerCase()}'] = _playcount(a);
        }
      }

      // ── Genre signal ─────────────────────────────────────────────────────
      // Pull tags for each side's top artists so two listeners who share
      // few/no exact artists can still match on the kind of music they like.
      var myGenreW    = <String, double>{};
      var theirGenreW = <String, double>{};
      if (!isSelf && myArtistW.isNotEmpty && theirArtists.isNotEmpty) {
        try {
          final myTopNames = (myArtistW.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(12)
              .map((e) => e.key)
              .toList();
          final theirTopNames = theirArtists
              .take(12)
              .map((a) => (a['name'] ?? '').toString().toLowerCase())
              .where((n) => n.isNotEmpty)
              .toList();
          final theirTopW = {
            for (var idx = 0; idx < theirTopNames.length; idx++)
              theirTopNames[idx]: 1.0 - (idx / theirTopNames.length),
          };

          final names = {...myTopNames, ...theirTopNames}.toList();
          final tagLists = await Future.wait(
            names.map((n) => widget.service.getArtistTopTags(n)),
          );
          final tagsByArtist = {
            for (var idx = 0; idx < names.length; idx++) names[idx]: tagLists[idx],
          };

          myGenreW    = _buildGenreWeights(myTopNames,    myArtistW, tagsByArtist);
          theirGenreW = _buildGenreWeights(theirTopNames, theirTopW, tagsByArtist);
        } catch (_) {
          // Tags unavailable (offline / rate-limited) — score falls back
          // gracefully to the artist/track/album-only formula.
        }
      }

      // ── isSelf path ───────────────────────────────────────────────────────
      if (isSelf) {
        List<_SharedMatch> selfArtists = [];
        _SharedMatch? selfTrack;

        if (hasMeaningfulData) {
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
      final dataLabel = hasMeaningfulData
          ? _ct(
              '$uniqueArtists artistes de votre historique · top 200 de ${widget.targetUser}',
              '$uniqueArtists artists from your history · ${widget.targetUser}\'s top 200',
            )
          : _ct(
              'Top 200 artistes & titres (API)',
              'Top 200 artists & tracks (API)',
            );

      final analysis = _analyzeTaste(
        myArtistW:       myArtistW,
        myTrackW:        myTrackW,
        myAlbumW:        myAlbumW,
        myArtistCounts:  artistCounts,
        myTrackCounts:   trackCounts,
        myAlbumCounts:   albumCounts,
        theirArtists:    theirArtists,
        theirTracks:     theirTracks,
        theirAlbums:     theirAlbums,
        myGenreW:        myGenreW,
        theirGenreW:     theirGenreW,
        dataLabel:       dataLabel,
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
        _totalArtists  = analysis.totalSharedArtists;
        _totalTracks   = analysis.totalSharedTracks;
        _totalAlbums   = analysis.totalSharedAlbums;
        _sharedGenres  = analysis.sharedGenres;
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
        const SizedBox(height: 12),

        // Shared counts summary row
        if (_totalArtists > 0 || _totalTracks > 0 || _totalAlbums > 0)
          _FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  if (_totalArtists > 0) _CountPill(
                    icon: Icons.mic_rounded,
                    label: _ct('$_totalArtists artiste${_totalArtists > 1 ? "s" : ""}',
                               '$_totalArtists artist${_totalArtists > 1 ? "s" : ""}'),
                    scheme: scheme, text: text,
                  ),
                  if (_totalTracks > 0) _CountPill(
                    icon: Icons.music_note_rounded,
                    label: _ct('$_totalTracks titre${_totalTracks > 1 ? "s" : ""}',
                               '$_totalTracks track${_totalTracks > 1 ? "s" : ""}'),
                    scheme: scheme, text: text,
                  ),
                  if (_totalAlbums > 0) _CountPill(
                    icon: Icons.album_rounded,
                    label: _ct('$_totalAlbums album${_totalAlbums > 1 ? "s" : ""}',
                               '$_totalAlbums album${_totalAlbums > 1 ? "s" : ""}'),
                    scheme: scheme, text: text,
                  ),
                ],
              ),
            ),
          ),

        // Shared genres row
        if (_sharedGenres.isNotEmpty)
          _FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: _sharedGenres.map((g) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      g,
                      style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),
        if (_topMatch != null) ...[
          _FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openItemDetail(context, _topMatch!),
                child: _TopMatchCard(match: _topMatch!),
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],

        // Shared tracks
        if (_sharedTracks.isNotEmpty) ...[
          _FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: _ExpandableSection(
              label: _ct('Titres en commun', 'Shared tracks'),
              icon: Icons.music_note_rounded,
              totalCount: _totalTracks,
              matches: _sharedTracks,
              onItemTap: (m) => _openItemDetail(context, m),
              scheme: scheme,
              text: text,
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Shared artists
        _FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: _ExpandableSection(
            label: _ct('Artistes en commun', 'Shared artists'),
            icon: Icons.mic_rounded,
            totalCount: _totalArtists,
            matches: _sharedArtists,
            onItemTap: (m) => _openItemDetail(context, m),
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
            child: _ExpandableSection(
              label: _ct('Albums en commun', 'Shared albums'),
              icon: Icons.album_rounded,
              totalCount: _totalAlbums,
              matches: _sharedAlbums,
              onItemTap: (m) => _openItemDetail(context, m),
              scheme: scheme,
              text: text,
            ),
          ),
        ],
      ],
    );
  }

  // Opens the detail sheet comparing my plays vs theirs for one item.
  void _openItemDetail(BuildContext context, _SharedMatch match) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ItemCompareSheet(
        match:         match,
        myUsername:    _myUsername,
        theirUsername: widget.targetUser,
        service:       widget.service,
      ),
    );
  }
}

// ── Expandable ranked list section ──────────────────────────────────────────────

class _ExpandableSection extends StatefulWidget {
  final String                      label;
  final IconData                    icon;
  final int                         totalCount;
  final List<_SharedMatch>          matches;
  final void Function(_SharedMatch) onItemTap;
  final String?                     emptyText;
  final ColorScheme                 scheme;
  final TextTheme                   text;

  const _ExpandableSection({
    required this.label,
    required this.icon,
    required this.totalCount,
    required this.matches,
    required this.onItemTap,
    required this.scheme,
    required this.text,
    this.emptyText,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final text   = widget.text;
    final empty  = widget.matches.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color:        scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: empty ? null : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color:        scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.totalCount}',
                      style: text.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer),
                    ),
                  ),
                  if (!empty) ...[
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns:    _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded,
                          size: 20, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve:    Curves.easeOutCubic,
            child: empty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.emptyText ?? '',
                        style: text.bodySmall?.copyWith(color: scheme.outlineVariant),
                      ),
                    ),
                  )
                : (_expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                        child: Column(
                          children: [
                            for (var i = 0; i < widget.matches.length; i++)
                              _RankedListTile(
                                rank:   i + 1,
                                match:  widget.matches[i],
                                onTap:  () => widget.onItemTap(widget.matches[i]),
                                scheme: scheme,
                                text:   text,
                              ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity)),
          ),
        ],
      ),
    );
  }
}

// ── Single row in an expanded list (rank + image + name + chevron) ──────────────

class _RankedListTile extends StatelessWidget {
  final int          rank;
  final _SharedMatch match;
  final VoidCallback onTap;
  final ColorScheme  scheme;
  final TextTheme    text;

  const _RankedListTile({
    required this.rank,
    required this.match,
    required this.onTap,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isArtist = match.type == 'artist';
    final fallbackIcon = switch (match.type) {
      'track' => Icons.music_note_rounded,
      'album' => Icons.album_rounded,
      _       => Icons.mic_rounded,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                    color: scheme.outline, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(isArtist ? 20 : 8),
              child: SizedBox(
                width: 40, height: 40,
                child: _ResolvedImage(match: match, fallbackIcon: fallbackIcon, iconSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    match.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (match.artist.isNotEmpty)
                    Text(
                      match.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: scheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}

// ── Resolves real art via ImageService — Last.fm rarely has artist/track art ────

class _ResolvedImage extends StatelessWidget {
  final _SharedMatch match;
  final IconData     fallbackIcon;
  final double       iconSize;

  const _ResolvedImage({
    required this.match,
    required this.fallbackIcon,
    required this.iconSize,
  });

  Future<String> _resolve() {
    final hint = match.imageUrl.isNotEmpty ? match.imageUrl : null;
    return switch (match.type) {
      'artist' => ImageService.resolveArtist(match.name, lastfmUrl: hint),
      'album'  => ImageService.resolveAlbum(match.name, match.artist, lastfmUrl: hint),
      _        => ImageService.resolveTrack(match.name, match.artist, lastfmUrl: hint),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget fallback() => Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(fallbackIcon, size: iconSize, color: scheme.onSurfaceVariant),
    );

    return FutureBuilder<String>(
      future: _resolve(),
      builder: (context, snap) {
        final url = snap.data ?? '';
        if (url.isEmpty) return fallback();
        return Image.network(url, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback());
      },
    );
  }
}

// ── Item comparison detail sheet (my plays vs their plays) ──────────────────────

class _ItemCompareSheet extends StatelessWidget {
  final _SharedMatch   match;
  final String         myUsername;
  final String         theirUsername;
  final LastFmService  service;

  const _ItemCompareSheet({
    required this.match,
    required this.myUsername,
    required this.theirUsername,
    required this.service,
  });

  // Maps our internal singular type to the app's plural detail-sheet type.
  String get _detailType => switch (match.type) {
    'artist' => 'artists',
    'album'  => 'albums',
    _        => 'tracks',
  };

  Map<String, dynamic> get _asLastFmItem => {
    'name': match.name,
    if (match.artist.isNotEmpty) 'artist': {'name': match.artist},
  };

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final text     = Theme.of(context).textTheme;
    final isArtist = match.type == 'artist';
    final fallbackIcon = switch (match.type) {
      'track' => Icons.music_note_rounded,
      'album' => Icons.album_rounded,
      _       => Icons.mic_rounded,
    };
    final maxPlays = [match.myPlays, match.theirPlays, 1].reduce((a, b) => a > b ? a : b);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tap the header again to open the full item page (bio, top tracks, etc).
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showDetailSheet(context, _asLastFmItem, _detailType, service),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(isArtist ? 48 : 16),
                      child: SizedBox(
                        width: 88, height: 88,
                        child: _ResolvedImage(
                            match: match, fallbackIcon: fallbackIcon, iconSize: 32),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          match.name,
                          textAlign: TextAlign.center,
                          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
                      ],
                    ),
                    if (match.artist.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          match.artist,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _CompareBar(
              label: myUsername, plays: match.myPlays, maxPlays: maxPlays,
              color: scheme.primary, scheme: scheme, text: text,
            ),
            const SizedBox(height: 12),
            _CompareBar(
              label: theirUsername, plays: match.theirPlays, maxPlays: maxPlays,
              color: scheme.tertiary, scheme: scheme, text: text,
            ),
            const SizedBox(height: 18),
            Text(
              _insight(),
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // Quick textual takeaway from the two play counts.
  String _insight() {
    final my = match.myPlays, their = match.theirPlays;
    if (my == 0 || their == 0) {
      return _ct("Décompte d'écoutes indisponible pour l'un des deux.",
                  'Play count unavailable for one of you.');
    }
    if (my / their > 1.3) {
      final x = (my / their).toStringAsFixed(1);
      return _ct('Tu écoutes ça ${x}x plus que $theirUsername.',
                  'You listen to this ${x}x more than $theirUsername.');
    }
    if (their / my > 1.3) {
      final x = (their / my).toStringAsFixed(1);
      return _ct('$theirUsername écoute ça ${x}x plus que toi.',
                  '$theirUsername listens to this ${x}x more than you.');
    }
    return _ct("Vous l'écoutez à peu près autant tous les deux.",
                'You both listen to this about equally.');
  }
}

// ── Horizontal bar comparing one person's play count ─────────────────────────────

class _CompareBar extends StatelessWidget {
  final String      label;
  final int         plays;
  final int         maxPlays;
  final Color       color;
  final ColorScheme scheme;
  final TextTheme   text;

  const _CompareBar({
    required this.label,
    required this.plays,
    required this.maxPlays,
    required this.color,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxPlays > 0 ? (plays / maxPlays).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              _ct('$plays écoutes', '$plays plays'),
              style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween:    Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve:    Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value:           value,
              minHeight:       10,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor:      AlwaysStoppedAnimation(color),
            ),
          ),
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
    final scheme  = Theme.of(context).colorScheme;
    final text    = Theme.of(context).textTheme;
    final isTrack = match.type == 'track';

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
              child: _ResolvedImage(
                match: match,
                fallbackIcon: isTrack ? Icons.music_note_rounded : Icons.mic_rounded,
                iconSize: 22,
              ),
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
}

// ── Small pill showing a shared count (artists / tracks / albums) ─────────────

class _CountPill extends StatelessWidget {
  final IconData    icon;
  final String      label;
  final ColorScheme scheme;
  final TextTheme   text;

  const _CountPill({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSecondaryContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color:      scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}