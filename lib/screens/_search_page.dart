// ignore_for_file: unused_import
part of 'home_screen.dart';

// dart:ui is available via the part-of import from home_screen.dart

const int _kSearchAll      = -1; // all types
const int _kSearchProfiles = 0;
const int _kSearchArtists  = 1;
const int _kSearchAlbums   = 2;
const int _kSearchTracks   = 3;

// Placeholder hash used by Last.fm when there is no image
const String _ph = '2a96cbd8b46e442fc41c2b86b821562f';

// ══════════════════════════════════════════════════════════════════════════════
//  showProfileSheet — open a user profile from any screen.
//  Use this instead of building _FullProfileSheet directly.
// ══════════════════════════════════════════════════════════════════════════════

void showProfileSheet(
  BuildContext context,
  String username,
  LastFmService service, {
  bool isFav = false,
  VoidCallback? onToggleFav,
}) {
  showModalBottomSheet(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    useSafeArea:        true,
    builder: (_) => _FullProfileSheet(
      username:    username,
      service:     service,
      isFav:       isFav,
      onToggleFav: onToggleFav ?? () {},
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  Search page
// ══════════════════════════════════════════════════════════════════════════════

class _SearchPage extends StatefulWidget {
  final LastFmService service;
  const _SearchPage({required this.service});

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _ctrl      = TextEditingController();
  final _focusNode = FocusNode();

  int           _tab       = _kSearchAll;  // default: no filter
  List<dynamic> _results   = [];
  // Per-type results used in "All" mode
  Map<int, List<dynamic>> _allResults = {};
  bool          _searching = false;
  String?       _error;
  Timer?        _debounce;

  Set<String> _favProfiles = {};

  List<(int, String, IconData)> get _kTabs => [
    (_kSearchAll,      L.searchAll,       Icons.apps_rounded),
    (_kSearchProfiles, L.searchProfiles,  Icons.person_rounded),
    (_kSearchArtists,  L.commonArtists,   Icons.mic_rounded),
    (_kSearchAlbums,   L.commonAlbums,    Icons.album_rounded),
    (_kSearchTracks,   L.commonTracks,    Icons.music_note_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favProfiles = Set<String>.from(p.getStringList('ls_fav_profiles') ?? []);
    });
  }

  Future<void> _toggleFavProfile(String username, bool nowFav) async {
    final updated = Set<String>.from(_favProfiles);
    if (nowFav) { updated.add(username); } else { updated.remove(username); }
    final p = await SharedPreferences.getInstance();
    await p.setStringList('ls_fav_profiles', updated.toList());
    if (!mounted) return;
    setState(() => _favProfiles = updated);
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _error = null; _searching = false; });
      return;
    }
    setState(() { _searching = true; _error = null; });
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) return;
    setState(() { _searching = true; _error = null; });
    try {
      if (_tab == _kSearchAll) {
        // Search artists, albums, tracks in parallel; profiles omitted from "all"
        final res = await Future.wait([
          widget.service.searchArtists(q, limit: 10),
          widget.service.searchAlbums(q,  limit: 10),
          widget.service.searchTracks(q,  limit: 10),
        ]);
        if (mounted) setState(() {
          _allResults = {
            _kSearchArtists: res[0],
            _kSearchAlbums:  res[1],
            _kSearchTracks:  res[2],
          };
          _results   = [];
          _searching = false;
        });
      } else {
        List<dynamic> res;
        switch (_tab) {
          case _kSearchProfiles: res = await widget.service.searchUsers(q,   limit: 15); break;
          case _kSearchArtists:  res = await widget.service.searchArtists(q, limit: 15); break;
          case _kSearchAlbums:   res = await widget.service.searchAlbums(q,  limit: 15); break;
          default:               res = await widget.service.searchTracks(q,  limit: 15);
        }
        if (mounted) setState(() { _results = res; _allResults = {}; _searching = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _searching = false;
        });
      }
    }
  }

  void _switchTab(int tab) {
    if (_tab == tab) return;
    setState(() { _tab = tab; _results = []; _allResults = {}; _error = null; });
    final q = _ctrl.text.trim();
    if (q.isNotEmpty) _search(q);
  }

  void _openMusicDetail(BuildContext ctx, Map<String, dynamic> item, String type) =>
      showDetailSheet(ctx, item, type, widget.service);

  // Open a profile using the shared showProfileSheet function
  void _openProfile(BuildContext ctx, String username) {
    showProfileSheet(
      ctx,
      username,
      widget.service,
      isFav:       _favProfiles.contains(username),
      onToggleFav: () => _toggleFavProfile(username, !_favProfiles.contains(username)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(L.searchTitle,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller:      _ctrl,
                focusNode:       _focusNode,
                onChanged:       _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) { if (v.trim().isNotEmpty) _search(v.trim()); },
                decoration: InputDecoration(
                  hintText:  L.searchHintBar,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() { _results = []; _error = null; _searching = false; });
                          },
                        )
                      : null,
                  filled:    true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _kTabs.map((t) {
                  final sel = t.$1 == _tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(t.$3, size: 14,
                          color: sel ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
                      label:  Text(t.$2),
                      selected: sel,
                      showCheckmark: false,
                      onSelected: (_) => _switchTab(t.$1),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(child: _buildResults(context, scheme, Theme.of(context).textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, ColorScheme scheme, TextTheme text) {
    if (_searching) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: () => _search(_ctrl.text.trim()));
    }

    if (_ctrl.text.trim().isEmpty) return _SearchEmptyState(tab: _tab);

    // "All" mode: sectioned results
    if (_tab == _kSearchAll) {
      final artists = _allResults[_kSearchArtists] ?? [];
      final albums  = _allResults[_kSearchAlbums]  ?? [];
      final tracks  = _allResults[_kSearchTracks]  ?? [];
      if (artists.isEmpty && albums.isEmpty && tracks.isEmpty) {
        return Center(child: Text(L.commonNoResults,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)));
      }
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (artists.isNotEmpty) ...[
            _SearchSectionHeader(label: L.commonArtists, icon: Icons.mic_rounded, scheme: scheme, text: text),
            ...artists.map((m) {
              final item = m as Map<String, dynamic>;
              final name = (item['name'] ?? '').toString();
              final raw  = _extractImage(item['image']);
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openMusicDetail(context, item, 'artists'),
                child: _ItemTile(name: name, sub: '', imageUrl: raw, rank: '',
                  imageFuture: ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null)),
              );
            }),
          ],
          if (albums.isNotEmpty) ...[
            _SearchSectionHeader(label: L.commonAlbums, icon: Icons.album_rounded, scheme: scheme, text: text),
            ...albums.map((m) {
              final item   = m as Map<String, dynamic>;
              final name   = (item['name'] ?? '').toString();
              final artist = (item['artist'] ?? '').toString();
              final raw    = _extractImage(item['image']);
              final norm   = Map<String, dynamic>.from(item);
              if (item['artist'] is String) norm['artist'] = {'name': artist};
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openMusicDetail(context, norm, 'albums'),
                child: _ItemTile(name: name, sub: artist, imageUrl: raw, rank: '',
                  imageFuture: ImageService.resolveAlbum(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null)),
              );
            }),
          ],
          if (tracks.isNotEmpty) ...[
            _SearchSectionHeader(label: L.commonTracks, icon: Icons.music_note_rounded, scheme: scheme, text: text),
            ...tracks.map((m) {
              final item   = m as Map<String, dynamic>;
              final name   = (item['name'] ?? '').toString();
              final artist = (item['artist'] ?? '').toString();
              final raw    = _extractImage(item['image']);
              final norm   = Map<String, dynamic>.from(item);
              if (item['artist'] is String) norm['artist'] = {'name': artist};
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openMusicDetail(context, norm, 'tracks'),
                child: _ItemTile(name: name, sub: artist, imageUrl: raw, rank: '',
                  imageFuture: ImageService.resolveTrack(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null)),
              );
            }),
          ],
          const SizedBox(height: 32),
        ],
      );
    }

    if (_results.isEmpty) {
      return Center(child: Text(L.commonNoResults,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)));
    }

    if (_tab == _kSearchProfiles) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: (_results.length / 2).ceil(),
        itemBuilder: (ctx, row) {
          final left     = _results[row * 2] as Map<String, dynamic>;
          final hasRight = row * 2 + 1 < _results.length;
          final right    = hasRight ? _results[row * 2 + 1] as Map<String, dynamic> : null;
          return Row(children: [
            Expanded(child: _buildUserCard(ctx, left)),
            const SizedBox(width: 10),
            Expanded(child: right != null ? _buildUserCard(ctx, right) : const SizedBox()),
          ]);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final m      = _results[i] as Map<String, dynamic>;
        final name   = (m['name']   ?? '').toString();
        final artist = (m['artist'] ?? '').toString();
        final imgRaw = _extractImage(m['image']);

        Future<String> imgF;
        String sub;
        String type;
        final normalized = Map<String, dynamic>.from(m);
        if (m['artist'] is String) normalized['artist'] = {'name': artist};

        switch (_tab) {
          case _kSearchArtists:
            type = 'artists';
            sub  = '${_fmt(int.tryParse((m['listeners'] ?? '0').toString()) ?? 0)} ${L.commonListeners}';
            imgF = ImageService.resolveArtist(name, lastfmUrl: imgRaw.isNotEmpty ? imgRaw : null);
          case _kSearchAlbums:
            type = 'albums';
            sub  = artist;
            imgF = ImageService.resolveAlbum(name, artist, lastfmUrl: imgRaw.isNotEmpty ? imgRaw : null);
          default:
            type = 'tracks';
            sub  = artist;
            imgF = ImageService.resolveTrack(name, artist, lastfmUrl: imgRaw.isNotEmpty ? imgRaw : null);
        }

        return InkWell(
          onTap: () => _openMusicDetail(context, normalized, type),
          borderRadius: BorderRadius.circular(8),
          child: _ItemTile(name: name, sub: sub, imageUrl: imgRaw, imageFuture: imgF, rank: '${i + 1}'),
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext ctx, Map<String, dynamic> u) {
    final uname = (u['name'] ?? '').toString();
    final isFav = _favProfiles.contains(uname);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SearchUserCard(
        user:        u,
        isFav:       isFav,
        onTap:       () => _openProfile(ctx, uname),
        onToggleFav: () => _toggleFavProfile(uname, !isFav),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _SearchEmptyState extends StatelessWidget {
  final int tab;
  const _SearchEmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    final hints = [
      (Icons.person_rounded,     L.searchHintProfiles),
      (Icons.mic_rounded,        L.searchHintArtists),
      (Icons.album_rounded,      L.searchHintAlbums),
      (Icons.music_note_rounded, L.searchHintTracks),
    ];
    final t = hints[tab.clamp(0, 3)];

    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(t.$1, size: 56, color: scheme.outlineVariant),
        const SizedBox(height: 12),
        Text(t.$2, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(L.searchTypePrompt, style: text.bodySmall?.copyWith(color: scheme.outlineVariant)),
      ]),
    );
  }
}

// ── User card in the 2-column search grid ─────────────────────────────────────

class _SearchUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool         isFav;
  final VoidCallback onTap;
  final VoidCallback onToggleFav;

  const _SearchUserCard({
    required this.user, required this.isFav,
    required this.onTap, required this.onToggleFav,
  });

  bool   _hasAvatar(String url) => url.isNotEmpty && !url.contains(_ph);
  String get _avatarUrl => _extractImage(user['image']);

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final text      = Theme.of(context).textTheme;
    final username  = (user['name']      ?? '').toString();
    final plays     = (user['playcount'] ?? '').toString();
    final country   = (user['country']   ?? '').toString();
    final hasAvatar = _hasAvatar(_avatarUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Gradient banner with avatar
          Container(
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.75),
                  scheme.tertiary.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: Stack(children: [
              // Favourite star (top-right)
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: onToggleFav,
                  child: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: isFav ? Colors.amber.shade400 : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              // Centred avatar
              Center(
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage: hasAvatar ? NetworkImage(_avatarUrl) : null,
                  child: hasAvatar ? null : Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ]),
          ),

          // Username + stats below banner
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(username, maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),

              if (plays.isNotEmpty && plays != '0') ...[
                const SizedBox(height: 2),
                Text('${_fmt(int.tryParse(plays) ?? 0)} ${L.commonPlays}',
                  maxLines: 1, textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant, fontSize: 10)),
              ],

              if (country.isNotEmpty && country != 'None') ...[
                const SizedBox(height: 3),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.location_on_outlined, size: 10, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Flexible(child: Text(country, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant, fontSize: 9))),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Full profile sheet — opened by showProfileSheet() from any screen
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

  // -- Data loaded from API --
  Map<String, dynamic>? _info;
  List<dynamic> _topArtists = [];
  List<dynamic> _topAlbums  = [];
  List<dynamic> _recent     = [];

  // -- UI state --
  bool      _loading      = true;
  bool      _isNowPlaying = false;
  String    _bannerUrl    = '';   // artwork used as blurred banner background
  late bool _localIsFav;

  @override
  void initState() {
    super.initState();
    _localIsFav = widget.isFav;
    _load();
  }

  Future<void> _load() async {
    try {
      // All requests run at the same time for speed
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
        // Resolve banner artwork: now-playing track first, then top artist
        _resolveBannerUrl(recentList, isNp);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Resolve the blurred background URL for the profile banner.
  // Prefers the now-playing track artwork; falls back to top artist.
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
      if (mounted && url.isNotEmpty) setState(() => _bannerUrl = url);
    } catch (_) {}
  }

  // -- Computed values --

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

  // True when the avatar URL is a real image (not Last.fm placeholder)
  bool _hasAvatar(String url) => url.isNotEmpty && !url.contains(_ph);

  // Human-readable time since a scrobble (e.g. "2h", "3d")
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
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize:     0.4,
      maxChildSize:     1.0,
      expand: false,
      builder: (ctx, ctrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: scheme.surface,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(ctx, ctrl, scheme),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, ScrollController ctrl, ColorScheme scheme) {
    return CustomScrollView(
      controller: ctrl,
      slivers: [

        // Hero banner (gradient + big avatar + name)
        SliverToBoxAdapter(child: _buildBanner(ctx, scheme)),

        // 3 stat cards: total plays, per day, active days
        SliverToBoxAdapter(child: _buildStatsRow(scheme)),

        // Now playing card (visible only when the user is live)
        if (_isNowPlaying)
          SliverToBoxAdapter(child: _buildNowPlayingCard(scheme)),

        // Top Artists section
        if (_topArtists.isNotEmpty) ...[
          SliverToBoxAdapter(child: _sectionHeader(L.commonTopArtists, scheme)),
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _buildArtistRow(ctx, _topArtists[i], i, scheme),
            childCount: _topArtists.length,
          )),
        ],

        // Top Albums section (new)
        if (_topAlbums.isNotEmpty) ...[
          SliverToBoxAdapter(child: _sectionHeader(L.commonAlbums, scheme)),
          SliverToBoxAdapter(child: _buildAlbumsGrid(ctx, scheme)),
        ],

        // Recent tracks section
        if (_recent.isNotEmpty) ...[
          SliverToBoxAdapter(child: _sectionHeader(L.commonRecentTracks, scheme)),
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _buildRecentRow(_recent[i], scheme),
            childCount: _recent.length,
          )),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }

  // ── Banner: gradient + big avatar + name + meta ───────────────────────────

  Widget _buildBanner(BuildContext ctx, ColorScheme scheme) {
    final info     = _info ?? {};
    final name     = (info['name']     ?? widget.username).toString();
    final realName = (info['realname'] ?? '').toString();
    final country  = (info['country']  ?? '').toString();
    final avatarUrl = _extractImage(info['image']);
    final hasAv    = _hasAvatar(avatarUrl);

    // Build "since YYYY" string from registration timestamp
    String since = '';
    final rawReg = info['registered'];
    if (rawReg != null) {
      int ts = 0;
      if (rawReg is Map) {
        ts = int.tryParse((rawReg['#text'] ?? rawReg['unixtime'] ?? '0').toString()) ?? 0;
      } else {
        ts = int.tryParse(rawReg.toString()) ?? 0;
      }
      if (ts > 0) {
        since = '${DateTime.fromMillisecondsSinceEpoch(ts * 1000).year}';
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.88),
            scheme.tertiary.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Blurred artwork in the background when available
          if (_bannerUrl.isNotEmpty)
            Positioned.fill(
              child: ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22,
                      tileMode: TileMode.mirror),
                  child: Image.network(
                    _bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          // Dark overlay so text stays readable
          if (_bannerUrl.isNotEmpty)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Column(children: [

          // Top row: drag handle (centred) + close button (right)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Handle truly centred relative to full width
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Close button pinned to the right
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Big avatar — green ring when now playing
          Stack(alignment: Alignment.center, children: [
            if (_isNowPlaying)
              Container(
                width: 106, height: 106,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent.shade400, width: 3),
                ),
              ),
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              backgroundImage: hasAv ? NetworkImage(avatarUrl) : null,
              child: hasAv ? null : Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
              ),
            ),
            // Small green dot overlay when live
            if (_isNowPlaying)
              Positioned(
                right: 4, bottom: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color:  Colors.greenAccent.shade400,
                    shape:  BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 2),
                  ),
                ),
              ),
          ]),

          const SizedBox(height: 12),

          // Username row + favourite star
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _localIsFav = !_localIsFav);
                widget.onToggleFav();
              },
              child: Icon(
                _localIsFav ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 22,
                color: _localIsFav
                    ? Colors.amber.shade400
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ]),

          // Real name (if the user set one)
          if (realName.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(realName,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
          ],

          // "Now listening" badge
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
                Icon(Icons.graphic_eq_rounded, size: 12,
                    color: Colors.greenAccent.shade400),
                const SizedBox(width: 4),
                Text(L.commonNowPlayingLong,
                  style: TextStyle(
                    color: Colors.greenAccent.shade400,
                    fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],

          const SizedBox(height: 10),

          // Country + join year
          if (country.isNotEmpty || since.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  if (country.isNotEmpty && country != 'None')
                    _BannerMeta(icon: Icons.location_on_outlined, label: country),
                  if (since.isNotEmpty)
                    _BannerMeta(
                        icon: Icons.calendar_today_outlined,
                        label: L.memberSince(since)),
                ],
              ),
            ),

          const SizedBox(height: 20),
        ]),
        ),   // SafeArea
        ],   // Stack children
      ),     // Stack
    );
  }

  // ── 3 stat cards ──────────────────────────────────────────────────────────

  Widget _buildStatsRow(ColorScheme scheme) {
    final total = _total();
    final avg   = _avg();
    final days  = _days();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Expanded(child: _ProfileStatCard(
          icon:    Icons.headphones_rounded,
          value:   _fmtLarge(total),
          label:   L.dashScrobbles,
          scheme:  scheme,
          primary: true,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ProfileStatCard(
          icon:   Icons.trending_up_rounded,
          value:  '~${_fmt(avg.round())}',
          label:  L.perDay,
          scheme: scheme,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ProfileStatCard(
          icon:   Icons.calendar_month_rounded,
          value:  _fmt(days),
          label:  L.activityDays,
          scheme: scheme,
        )),
      ]),
    );
  }

  // ── Now playing highlighted card ──────────────────────────────────────────

  Widget _buildNowPlayingCard(ColorScheme scheme) {
    // The first item in _recent is always the now-playing track
    final np = _recent.isNotEmpty ? _recent.first as Map<String, dynamic> : null;
    if (np == null) return const SizedBox.shrink();

    final track   = (np['name']                        ?? '').toString();
    final artist  = (np['artist']?['#text']
                  ?? np['artist']?['name'] ?? '').toString();
    final rawUrl  = _extractImage(np['image']);
    final hasImg  = rawUrl.isNotEmpty && !rawUrl.contains(_ph);

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
          color:        Colors.greenAccent.shade400.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(
              color: Colors.greenAccent.shade400.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          // Album art
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

  // ── Section title bar ─────────────────────────────────────────────────────
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

  // ── Artist row: rank + circle avatar + name + plays ───────────────────────

  Widget _buildArtistRow(
      BuildContext ctx, dynamic raw, int idx, ColorScheme scheme) {
    final a      = raw as Map<String, dynamic>;
    final name   = (a['name']      ?? '').toString();
    final plays  = int.tryParse((a['playcount'] ?? '0').toString()) ?? 0;
    final imgUrl = _extractImage(a['image']);

    return InkWell(
      onTap: () {
        Navigator.pop(ctx); // close profile sheet first
        showDetailSheet(ctx, a, 'artists', widget.service);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(children: [
          // Rank number
          SizedBox(
            width: 24,
            child: Text('${idx + 1}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),

          // Circular artist image
          _SmartImage(
            size: 44, borderRadius: 22,
            initialUrl: imgUrl,
            resolver: () => ImageService.resolveArtist(name,
                lastfmUrl: imgUrl.isNotEmpty ? imgUrl : null),
          ),
          const SizedBox(width: 12),

          // Name and play count
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

  // ── Albums: 3-column grid with cover art ─────────────────────────────────

  Widget _buildAlbumsGrid(BuildContext ctx, ColorScheme scheme) {
    final albums = _topAlbums.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   3,
          mainAxisSpacing:  10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: albums.length,
        itemBuilder: (_, i) {
          final al       = albums[i] as Map<String, dynamic>;
          final name     = (al['name']              ?? '').toString();
          final plays    = int.tryParse((al['playcount'] ?? '0').toString()) ?? 0;
          final imgUrl   = _extractImage(al['image']);
          final artName  = (al['artist']?['name']   ?? '').toString();

          return GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              showDetailSheet(ctx, al, 'albums', widget.service);
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Cover art square
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _SmartImage(
                    size: 100, borderRadius: 10,
                    initialUrl: imgUrl,
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

  // ── Recent track row ──────────────────────────────────────────────────────

  Widget _buildRecentRow(dynamic raw, ColorScheme scheme) {
    final t      = raw as Map<String, dynamic>;
    final isNp   = t['@attr']?['nowplaying'] == 'true';
    final track  = (t['name']                        ?? '').toString();
    final artist = (t['artist']?['#text']
                 ?? t['artist']?['name'] ?? '').toString();
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
        // Track artwork with green dot for live track
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

        // "LIVE" label or relative time
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

  // ── Small placeholder box when artwork is missing ─────────────────────────

  Widget _artBox(double size, ColorScheme scheme) {
    return Container(
      width: size, height: size,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded,
        size: size * 0.45,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}

// ── Gradient banner icon+text row ─────────────────────────────────────────────

class _BannerMeta extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _BannerMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.75)),
      const SizedBox(width: 4),
      Text(label,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
    ]);
  }
}

// ── Stat card for the profile stats row ──────────────────────────────────────

class _ProfileStatCard extends StatelessWidget {
  final IconData    icon;
  final String      value;
  final String      label;
  final ColorScheme scheme;
  final bool        primary;

  const _ProfileStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.scheme,
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

// ── Format large numbers compactly (1 200 000 → "1.2M") ─────────────────────

String _fmtLarge(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

// ── Section header for "All" mode search results ─────────────────────────────

class _SearchSectionHeader extends StatelessWidget {
  final String      label;
  final IconData    icon;
  final ColorScheme scheme;
  final TextTheme   text;
  const _SearchSectionHeader({
    required this.label, required this.icon,
    required this.scheme, required this.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
    child: Row(children: [
      Icon(icon, size: 16, color: scheme.primary),
      const SizedBox(width: 6),
      Text(label, style: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w800, color: scheme.onSurface)),
      const SizedBox(width: 8),
      Expanded(child: Divider(
          color: scheme.outlineVariant.withValues(alpha: 0.5), thickness: 1)),
    ]),
  );
}