part of 'home_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
//  Music Taste Compatibility — "Tasteometer"-style comparison between the
//  active user and another profile (friend / search result).
//
//  Entry point: showTasteCompareSheet(context, targetUser, service)
//  Bind it from any friend tile or search result tap target — see the
//  integration notes at the end of this file.
// ════════════════════════════════════════════════════════════════════════════

// ── Public entry point ───────────────────────────────────────────────────────
// Note: `_ct(fr, en)` is reused from `_charts_page.dart` — already defined
// there, so it isn't redeclared in this file.

/// Opens the taste compatibility sheet for [targetUser].
/// Call this from a friend card, a search result, or a profile sheet action.
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

// ── Shared match model ───────────────────────────────────────────────────────
// A single piece of overlap between the two profiles: either a shared track
// (artist is set) or a shared artist (artist is empty).
class _SharedMatch {
  final String type; // 'track' | 'artist'
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

// Result of comparing two listening profiles.
typedef _TasteAnalysis = ({
  double score, // 0..1 compatibility score
  _SharedMatch? topMatch, // best shared track/artist, if any
  List<_SharedMatch> sharedArtists, // other artists in common
});

// ── Pure comparison logic (no I/O, easy to reason about / unit test) ────────
_TasteAnalysis _analyzeTaste({
  required List<dynamic> myArtists,
  required List<dynamic> theirArtists,
  required List<dynamic> myTracks,
  required List<dynamic> theirTracks,
}) {
  String artistKey(dynamic a) => (a['name'] ?? '').toString().toLowerCase();
  String trackKey(dynamic t) {
    final artist = (t['artist']?['name'] ?? t['artist'] ?? '').toString();
    final name = (t['name'] ?? '').toString();
    // Namespaced by artist so two different artists with a same-named
    // track don't get treated as a match.
    return '${artist.toLowerCase()}::${name.toLowerCase()}';
  }

  // Rank maps: name -> position in the top list (0 = most played).
  final myArtistRank = <String, int>{};
  for (var i = 0; i < myArtists.length; i++) {
    myArtistRank.putIfAbsent(artistKey(myArtists[i]), () => i);
  }
  final theirArtistRank = <String, int>{};
  for (var i = 0; i < theirArtists.length; i++) {
    theirArtistRank.putIfAbsent(artistKey(theirArtists[i]), () => i);
  }
  final myTrackRank = <String, int>{};
  for (var i = 0; i < myTracks.length; i++) {
    myTrackRank.putIfAbsent(trackKey(myTracks[i]), () => i);
  }
  final theirTrackRank = <String, int>{};
  for (var i = 0; i < theirTracks.length; i++) {
    theirTrackRank.putIfAbsent(trackKey(theirTracks[i]), () => i);
  }

  // ── Compatibility score ────────────────────────────────────────────────
  // Jaccard similarity (shared / union) over each top-50 set. It stays
  // meaningful even when the two profiles have very different list sizes,
  // without needing anything beyond basic set math.
  double jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final shared = a.intersection(b).length;
    final union = a.length + b.length - shared;
    return union == 0 ? 0 : shared / union;
  }

  final artistScore = jaccard(myArtistRank.keys.toSet(), theirArtistRank.keys.toSet());
  final trackScore = jaccard(myTrackRank.keys.toSet(), theirTrackRank.keys.toSet());

  // Artists carry more long-term signal than individual tracks, so they
  // get more weight in the final blend.
  final score = ((artistScore * 0.65) + (trackScore * 0.35)).clamp(0.0, 1.0);

  // ── Shared top favorite ────────────────────────────────────────────────
  // Prefer a shared track (the most specific, most impressive match) and
  // fall back to a shared artist. Among candidates, pick whichever is
  // ranked best on both sides (lowest combined rank).
  _SharedMatch? topMatch;
  double bestWeight = -1;

  for (final entry in myTrackRank.entries) {
    final theirRank = theirTrackRank[entry.key];
    if (theirRank == null) continue;
    final weight = 1 / (entry.value + theirRank + 2);
    if (weight > bestWeight) {
      final source = myTracks.firstWhere((t) => trackKey(t) == entry.key);
      final artistName = (source['artist']?['name'] ?? source['artist'] ?? '').toString();
      topMatch = _SharedMatch(
        type: 'track',
        name: (source['name'] ?? '').toString(),
        artist: artistName,
        imageUrl: _extractImage(source['image']),
      );
      bestWeight = weight;
    }
  }

  if (topMatch == null) {
    for (final entry in myArtistRank.entries) {
      final theirRank = theirArtistRank[entry.key];
      if (theirRank == null) continue;
      final weight = 1 / (entry.value + theirRank + 2);
      if (weight > bestWeight) {
        final source = myArtists.firstWhere((a) => artistKey(a) == entry.key);
        topMatch = _SharedMatch(
          type: 'artist',
          name: (source['name'] ?? '').toString(),
          artist: '',
          imageUrl: _extractImage(source['image']),
        );
        bestWeight = weight;
      }
    }
  }

  // ── Other shared artists, best combined rank first ─────────────────────
  final sharedKeys = myArtistRank.keys.toSet().intersection(theirArtistRank.keys.toSet()).toList()
    ..sort((a, b) => (myArtistRank[a]! + theirArtistRank[a]!)
        .compareTo(myArtistRank[b]! + theirArtistRank[b]!));

  final topMatchKey = topMatch?.type == 'artist' ? topMatch!.name.toLowerCase() : null;

  final sharedArtists = sharedKeys
      .where((k) => k != topMatchKey)
      .take(12)
      .map((k) {
        final source = myArtists.firstWhere((a) => artistKey(a) == k);
        return _SharedMatch(
          type: 'artist',
          name: (source['name'] ?? '').toString(),
          artist: '',
          imageUrl: _extractImage(source['image']),
        );
      })
      .toList();

  return (score: score, topMatch: topMatch, sharedArtists: sharedArtists);
}

// Friendly compatibility tier label shown under the percentage ring.
String _compatibilityTierLabel(double score) {
  final pct = score * 100;
  if (pct >= 80) return _ct('Âmes musicales sœurs', 'Musical soulmates');
  if (pct >= 60) return _ct('Très belle compatibilité', 'Great compatibility');
  if (pct >= 40) return _ct('Quelques points communs', 'Some common ground');
  if (pct >= 20) return _ct('Goûts plutôt différents', 'Fairly different tastes');
  return _ct('Univers musicaux opposés', 'Worlds apart, musically');
}

// ════════════════════════════════════════════════════════════════════════════
//  _TasteCompareSheet
// ════════════════════════════════════════════════════════════════════════════

class _TasteCompareSheet extends StatefulWidget {
  final String targetUser;
  final LastFmService service;

  const _TasteCompareSheet({
    required this.targetUser,
    required this.service,
  });

  @override
  State<_TasteCompareSheet> createState() => _TasteCompareSheetState();
}

class _TasteCompareSheetState extends State<_TasteCompareSheet> {
  bool _loading = true;
  String? _error;

  String _myUsername = '';
  String _myAvatar = '';
  String _theirAvatar = '';

  double _score = 0;
  _SharedMatch? _topMatch;
  List<_SharedMatch> _sharedArtists = [];

  @override
  void initState() {
    super.initState();
    // The app doesn't use a Provider-style AppState — LastFmService is
    // already constructed with the logged-in user's username in
    // home_screen.dart, so it's the simplest reliable source here.
    _myUsername = widget.service.username;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Comparing a profile with itself would always read as a perfect
      // match — short-circuit with a lighter, single-profile fetch instead.
      final isSelf = widget.targetUser.toLowerCase() == _myUsername.toLowerCase();

      final results = await Future.wait([
        widget.service.getUserInfo(user: _myUsername),
        isSelf
            ? Future.value(null)
            : widget.service.getUserInfo(user: widget.targetUser),
        widget.service.getTopArtists(user: _myUsername, period: 'overall', limit: 50),
        isSelf
            ? Future.value(<dynamic>[])
            : widget.service.getTopArtists(user: widget.targetUser, period: 'overall', limit: 50),
        widget.service.getTopTracks(user: _myUsername, period: 'overall', limit: 50),
        isSelf
            ? Future.value(<dynamic>[])
            : widget.service.getTopTracks(user: widget.targetUser, period: 'overall', limit: 50),
      ]);

      final myInfo = results[0] as Map<String, dynamic>?;
      final theirInfo = isSelf ? myInfo : results[1] as Map<String, dynamic>?;
      final myArtists = results[2] as List<dynamic>;
      final theirArtists = isSelf ? myArtists : results[3] as List<dynamic>;
      final myTracks = results[4] as List<dynamic>;
      final theirTracks = isSelf ? myTracks : results[5] as List<dynamic>;

      final analysis = isSelf
          ? (
              score: 1.0,
              topMatch: myTracks.isNotEmpty
                  ? _SharedMatch(
                      type: 'track',
                      name: (myTracks.first['name'] ?? '').toString(),
                      artist: (myTracks.first['artist']?['name'] ?? '').toString(),
                      imageUrl: _extractImage(myTracks.first['image']),
                    )
                  : null,
              sharedArtists: myArtists.take(12).map((a) => _SharedMatch(
                    type: 'artist',
                    name: (a['name'] ?? '').toString(),
                    artist: '',
                    imageUrl: _extractImage(a['image']),
                  )).toList(),
            )
          : _analyzeTaste(
              myArtists: myArtists,
              theirArtists: theirArtists,
              myTracks: myTracks,
              theirTracks: theirTracks,
            );

      if (!mounted) return;
      setState(() {
        _myAvatar = _extractImage(myInfo?['image']);
        _theirAvatar = _extractImage(theirInfo?['image']);
        _score = analysis.score;
        _topMatch = analysis.topMatch;
        _sharedArtists = analysis.sharedArtists;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _ct(
          'Impossible de calculer la compatibilité pour le moment.',
          'Could not work out the compatibility right now.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                  _ct(
                    'D\'après les artistes et titres les plus écoutés',
                    'Based on the most played artists and tracks',
                  ),
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  _buildLoading(scheme, text)
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

  Widget _buildLoading(ColorScheme scheme, TextTheme text) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: scheme.primary),
            const SizedBox(height: 14),
            Text(
              _ct('Analyse des goûts musicaux…', 'Analyzing musical taste…'),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme scheme, TextTheme text) {
    final topMatch = _topMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FadeSlideIn(
          delay: const Duration(milliseconds: 20),
          child: Center(
            child: _DuoAvatars(
              myAvatar: _myAvatar,
              theirAvatar: _theirAvatar,
              myUsername: _myUsername,
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
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),

        if (topMatch != null) ...[
          _FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: _TopMatchCard(match: topMatch),
          ),
          const SizedBox(height: 22),
        ],

        _FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _ct('Autres artistes en commun', 'Other shared artists'),
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _sharedArtists.isEmpty
                  ? Text(
                      _ct(
                        'Pas encore d\'artistes communs trouvés.',
                        'No common artists found yet.',
                      ),
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sharedArtists.map((m) => _TasteChip(match: m)).toList(),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Two overlapping avatars with a small connector badge ────────────────────
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
    final scheme = Theme.of(context).colorScheme;
    final hasAvatar = url.isNotEmpty && !url.contains(_ph);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.surface, width: 3),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(Icons.person_rounded, color: scheme.onSurfaceVariant),
              )
            : Icon(Icons.person_rounded, color: scheme.onSurfaceVariant, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

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
              width: 26,
              height: 26,
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
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Circular compatibility gauge with an animated fill + rolling number ─────
class _CompatibilityRing extends StatelessWidget {
  final double score; // 0..1

  const _CompatibilityRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 152,
          height: 152,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 152,
                height: 152,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: text.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ct('compatibilité', 'compatibility'),
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Highlighted card for the single best shared track / artist ─────────────
class _TopMatchCard extends StatelessWidget {
  final _SharedMatch match;

  const _TopMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasImage = match.imageUrl.isNotEmpty && !match.imageUrl.contains(_ph);
    final isTrack = match.type == 'track';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: hasImage
                  ? Image.network(
                      match.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackIcon(scheme, isTrack),
                    )
                  : _fallbackIcon(scheme, isTrack),
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
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  match.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                if (match.artist.isNotEmpty)
                  Text(
                    match.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.favorite_rounded, color: scheme.primary, size: 20),
        ],
      ),
    );
  }

  Widget _fallbackIcon(ColorScheme scheme, bool isTrack) => Container(
        color: scheme.primary.withValues(alpha: 0.12),
        child: Icon(
          isTrack ? Icons.music_note_rounded : Icons.mic_rounded,
          color: scheme.primary,
        ),
      );
}

// ── Small pill used for the "other shared artists" list ─────────────────────
class _TasteChip extends StatelessWidget {
  final _SharedMatch match;

  const _TasteChip({required this.match});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasImage = match.imageUrl.isNotEmpty && !match.imageUrl.contains(_ph);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              width: 20,
              height: 20,
              child: hasImage
                  ? Image.network(
                      match.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.mic_rounded, size: 12, color: scheme.onSurfaceVariant),
                    )
                  : Icon(Icons.mic_rounded, size: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 6),
          Text(match.name, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}