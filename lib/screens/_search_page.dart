// ignore_for_file: unused_import
part of 'home_screen.dart';

const int _kSearchAll      = -1;
const int _kSearchProfiles = 0;
const int _kSearchArtists  = 1;
const int _kSearchAlbums   = 2;
const int _kSearchTracks   = 3;

const String _ph = '2a96cbd8b46e442fc41c2b86b821562f';

class _SearchPage extends StatefulWidget {
  final LastFmService service;
  const _SearchPage({required this.service});

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _ctrl      = TextEditingController();
  final _focusNode = FocusNode();

  int           _tab       = _kSearchAll;
  List<dynamic> _results   = [];
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

  /// Dismiss keyboard before opening any result detail
  void _dismissKeyboard() => _focusNode.unfocus();

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
        // Include profiles in "All" tab search
        final res = await Future.wait([
          widget.service.searchUsers(q,   limit: 6),
          widget.service.searchArtists(q, limit: 10),
          widget.service.searchAlbums(q,  limit: 10),
          widget.service.searchTracks(q,  limit: 10),
        ]);
        if (mounted) setState(() {
          _allResults = {
            _kSearchProfiles: res[0],
            _kSearchArtists:  res[1],
            _kSearchAlbums:   res[2],
            _kSearchTracks:   res[3],
          };
          _results   = [];
          _searching = false;
        });
      } else {
        List<dynamic> res;
        switch (_tab) {
          // searchUsers returns multiple similar usernames — natural suggestion list
          case _kSearchProfiles: res = await widget.service.searchUsers(q,   limit: 20); break;
          case _kSearchArtists:  res = await widget.service.searchArtists(q, limit: 15); break;
          case _kSearchAlbums:   res = await widget.service.searchAlbums(q,  limit: 15); break;
          default:               res = await widget.service.searchTracks(q,  limit: 15);
        }
        if (mounted) setState(() { _results = res; _allResults = {}; _searching = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error     = e.toString().replaceFirst('Exception: ', '');
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

  void _openMusicDetail(BuildContext ctx, Map<String, dynamic> item, String type) {
    // Dismiss keyboard before opening detail sheet
    _dismissKeyboard();
    showDetailSheet(ctx, item, type, widget.service);
  }

  void _openProfile(BuildContext ctx, String username) {
    // Dismiss keyboard before opening profile sheet
    _dismissKeyboard();
    showProfileSheet(
      ctx, username, widget.service,
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
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 2),
              child: Text(L.searchTitle,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller:      _ctrl,
                focusNode:       _focusNode,
                onChanged:       _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) _search(v.trim());
                  // Dismiss keyboard on submit
                  _dismissKeyboard();
                },
                decoration: InputDecoration(
                  hintText:  L.searchHintBar,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _ctrl.clear();
                            _dismissKeyboard();
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
                      onSelected: (_) { _haptic(_HapticImpact.selection); _switchTab(t.$1); },
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _searching
        ? const Center(key: ValueKey('search_load'), child: CircularProgressIndicator())
        : _buildResultsContent(context, scheme, text),
    );
  }

  Widget _buildResultsContent(BuildContext context, ColorScheme scheme, TextTheme text) {
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: () => _search(_ctrl.text.trim()));
    }

    if (_ctrl.text.trim().isEmpty) return _SearchEmptyState(tab: _tab);

    if (_tab == _kSearchAll) {
      final profiles = _allResults[_kSearchProfiles] ?? [];
      final artists  = _allResults[_kSearchArtists]  ?? [];
      final albums   = _allResults[_kSearchAlbums]   ?? [];
      final tracks   = _allResults[_kSearchTracks]   ?? [];

      if (profiles.isEmpty && artists.isEmpty && albums.isEmpty && tracks.isEmpty) {
        return Center(child: Text(L.commonNoResults,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)));
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // Profiles section in "All" tab — horizontal scrollable row of user cards
          if (profiles.isNotEmpty) ...[
            _SearchSectionHeader(
              label: L.searchProfiles, icon: Icons.person_rounded,
              scheme: scheme, text: text,
            ),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: profiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final u     = profiles[i] as Map<String, dynamic>;
                  final uname = (u['name'] ?? '').toString();
                  final isFav = _favProfiles.contains(uname);
                  return SizedBox(
                    width: 120,
                    child: _SearchUserCard(
                      user:        u,
                      isFav:       isFav,
                      onTap:       () { _haptic(_HapticImpact.light); _openProfile(ctx, uname); },
                      onToggleFav: () => _toggleFavProfile(uname, !isFav),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (artists.isNotEmpty) ...[
            _SearchSectionHeader(label: L.commonArtists, icon: Icons.mic_rounded, scheme: scheme, text: text),
            ...artists.map((m) {
              final item = m as Map<String, dynamic>;
              final name = (item['name'] ?? '').toString();
              final raw  = _extractImage(item['image']);
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () { _haptic(_HapticImpact.light); _openMusicDetail(context, item, 'artists'); },
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
                onTap: () { _haptic(_HapticImpact.light); _openMusicDetail(context, norm, 'albums'); },
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
                onTap: () { _haptic(_HapticImpact.light); _openMusicDetail(context, norm, 'tracks'); },
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
      // Grid of user cards — tapping one unfocuses the search field automatically
      // via _openProfile which calls _dismissKeyboard()
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: _results.length,
        itemBuilder: (ctx, i) {
          final u     = _results[i] as Map<String, dynamic>;
          final uname = (u['name'] ?? '').toString();
          final isFav = _favProfiles.contains(uname);
          return _SearchUserCard(
            user:        u,
            isFav:       isFav,
            onTap:       () { _haptic(_HapticImpact.light); _openProfile(ctx, uname); },
            onToggleFav: () => _toggleFavProfile(uname, !isFav),
          );
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
        onTap:       () { _haptic(_HapticImpact.light); _openProfile(ctx, uname); },
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

// ── User card (search grid) ───────────────────────────────────────────────────

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
    final scheme   = Theme.of(context).colorScheme;
    final text     = Theme.of(context).textTheme;
    final username = (user['name']      ?? '').toString();
    final plays    = (user['playcount'] ?? '').toString();
    final country  = (user['country']   ?? '').toString();
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

// ── Section header for "All" search results ───────────────────────────────────

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