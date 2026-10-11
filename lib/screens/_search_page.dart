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
        if (mounted) {
          setState(() {
          _allResults = {
            _kSearchProfiles: res[0],
            _kSearchArtists:  res[1],
            _kSearchAlbums:   res[2],
            _kSearchTracks:   res[3],
          };
          _results   = [];
          _searching = false;
        });
        }
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

  // ── Smart ordering of the "All" sections ──────────────────────────────
  // The category holding the best match comes first (an artist named like the
  // query beats a random profile), instead of a fixed profile > artist > ...
  int _nameScore(dynamic item, String q) {
    final name = (item is Map ? (item['name'] ?? '') : '').toString().toLowerCase();
    final qq = q.toLowerCase();
    if (name.isEmpty || qq.isEmpty) return 0;
    if (name == qq) return 3;
    if (name.startsWith(qq)) return 2;
    if (name.contains(qq)) return 1;
    return 0;
  }

  List<int> _sectionOrder(String q) {
    const prior = {
      _kSearchArtists: 0.3, _kSearchTracks: 0.2, _kSearchAlbums: 0.1, _kSearchProfiles: 0.0,
    };
    final cats = <(int, double)>[];
    for (final c in prior.keys) {
      final items = _allResults[c] ?? const [];
      if (items.isEmpty) continue;
      var best = 0;
      for (final it in items) {
        final sc = _nameScore(it, q);
        if (sc > best) best = sc;
      }
      cats.add((c, best + prior[c]!));
    }
    cats.sort((x, y) => y.$2.compareTo(x.$2));
    return [for (final c in cats) c.$1];
  }

  // ── Material You pieces ───────────────────────────────────────────────
  Widget _bar(ColorScheme scheme, TextTheme text) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Color.lerp(scheme.surfaceContainerHigh, scheme.primaryContainer, 0.5),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.only(left: 18, right: 6),
      child: Row(children: [
        Icon(Icons.search_rounded, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            cursorColor: scheme.primary,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              hintText: L.searchHintBar,
              hintStyle: text.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) _search(v.trim());
              _dismissKeyboard();
            },
          ),
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: M3LoadingIndicator(size: 28),
          ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _ctrl,
          builder: (_, v, _) => v.text.isEmpty
              ? const SizedBox(width: 12)
              : IconButton(
                  icon: Icon(Icons.close_rounded, color: scheme.primary),
                  onPressed: () {
                    _ctrl.clear();
                    _dismissKeyboard();
                    setState(() { _results = []; _allResults = {}; _error = null; _searching = false; });
                  },
                ),
        ),
      ]),
    );
  }

  Widget _rail(ColorScheme scheme, TextTheme text) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final t in _kTabs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { _haptic(_HapticImpact.selection); _switchTab(t.$1); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: t.$1 == _tab
                        ? scheme.primary
                        : scheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(t.$1 == _tab ? 22 : 14),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(t.$3, size: 18,
                        color: t.$1 == _tab ? scheme.onPrimary : scheme.primary),
                    const SizedBox(width: 8),
                    Text(t.$2, style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: t.$1 == _tab ? scheme.onPrimary : scheme.primary)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(ColorScheme scheme, Widget child, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: Color.lerp(scheme.primaryContainer, scheme.surface, 0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: child,
            ),
          ),
        ),
      );

  Widget _artistRow(ColorScheme scheme, dynamic m, {String rank = '', bool listeners = false}) {
    final item = m as Map<String, dynamic>;
    final name = (item['name'] ?? '').toString();
    final raw  = _extractImage(item['image']);
    final sub  = listeners
        ? '${_fmt(int.tryParse((item['listeners'] ?? '0').toString()) ?? 0)} ${L.commonListeners}'
        : '';
    return _card(scheme,
      _FadeSlideIn(child: _ItemTile(name: name, sub: sub, imageUrl: raw, rank: rank,
          imageFuture: ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null))),
      () { _haptic(_HapticImpact.light); _openMusicDetail(context, item, 'artists'); });
  }

  Widget _albumRow(ColorScheme scheme, dynamic m, {String rank = ''}) {
    final item   = m as Map<String, dynamic>;
    final name   = (item['name'] ?? '').toString();
    final artist = (item['artist'] ?? '').toString();
    final raw    = _extractImage(item['image']);
    final norm   = Map<String, dynamic>.from(item);
    if (item['artist'] is String) norm['artist'] = {'name': artist};
    return _card(scheme,
      _FadeSlideIn(child: _ItemTile(name: name, sub: artist, imageUrl: raw, rank: rank,
          imageFuture: ImageService.resolveAlbum(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null))),
      () { _haptic(_HapticImpact.light); _openMusicDetail(context, norm, 'albums'); });
  }

  Widget _trackRow(ColorScheme scheme, dynamic m, {String rank = ''}) {
    final item   = m as Map<String, dynamic>;
    final name   = (item['name'] ?? '').toString();
    final artist = (item['artist'] ?? '').toString();
    final raw    = _extractImage(item['image']);
    final norm   = Map<String, dynamic>.from(item);
    if (item['artist'] is String) norm['artist'] = {'name': artist};
    return _card(scheme,
      _FadeSlideIn(child: _FolderAwareItemTile(name: name, sub: artist, imageUrl: raw, rank: rank,
          artist: artist, image: raw,
          imageFuture: ImageService.resolveTrack(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null))),
      () { _haptic(_HapticImpact.light); _openMusicDetail(context, norm, 'tracks'); });
  }

  Widget _profilesStrip(ColorScheme scheme, List<dynamic> profiles) => SizedBox(
        height: 164,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: profiles.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (ctx, i) {
            final u     = profiles[i] as Map<String, dynamic>;
            final uname = (u['name'] ?? '').toString();
            final isFav = _favProfiles.contains(uname);
            return SizedBox(
              width: 124,
              child: _SearchUserCard(
                user: u, isFav: isFav,
                onTap: () { _haptic(_HapticImpact.light); _openProfile(ctx, uname); },
                onToggleFav: () => _toggleFavProfile(uname, !isFav),
              ),
            );
          },
        ),
      );

  // One category block of the "All" view: cookie badge + title + count.
  Widget _section(ColorScheme scheme, TextTheme text, int cat) {
    final items = _allResults[cat] ?? const [];
    final (label, icon) = switch (cat) {
      _kSearchProfiles => (L.searchProfiles, Icons.person_rounded),
      _kSearchArtists  => (L.commonArtists,  Icons.mic_rounded),
      _kSearchAlbums   => (L.commonAlbums,   Icons.album_rounded),
      _                => (L.commonTracks,   Icons.music_note_rounded),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          child: Row(children: [
            M3CookieBadge(
              color: scheme.primary, size: 36,
              child: Icon(icon, size: 18, color: scheme.onPrimary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Text('${items.length}', style: text.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        if (cat == _kSearchProfiles)
          _profilesStrip(scheme, items)
        else
          for (final m in items)
            switch (cat) {
              _kSearchArtists => _artistRow(scheme, m),
              _kSearchAlbums  => _albumRow(scheme, m),
              _               => _trackRow(scheme, m),
            },
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 2),
            child: Row(children: [
              Expanded(
                child: Text(L.searchTitle,
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              // Folders are their own page (saved tracks), not a search tab.
              IconButton.filledTonal(
                tooltip: L.searchFolders,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.primary,
                ),
                icon: const Icon(Icons.folder_rounded),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FoldersGridPage(service: widget.service))),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _bar(scheme, text)),
          const SizedBox(height: 12),
          _rail(scheme, text),
          const SizedBox(height: 8),
          Expanded(child: _buildResults(context, scheme, text)),
        ]),
      ),
    );
  }

  Widget _buildResults(BuildContext context, ColorScheme scheme, TextTheme text) {
    return M3Switcher(
      duration: const Duration(milliseconds: 280),
      child: _searching
          ? const SkeletonList(key: ValueKey('search_load'))
          : _buildResultsContent(context, scheme, text),
    );
  }

  Widget _buildResultsContent(BuildContext context, ColorScheme scheme, TextTheme text) {
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: () => _search(_ctrl.text.trim()));
    }
    final q = _ctrl.text.trim();
    if (q.isEmpty) return _SearchEmptyState(tab: _tab);

    if (_tab == _kSearchAll) {
      final order = _sectionOrder(q);
      if (order.isEmpty) {
        return Center(child: Text(L.commonNoResults,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)));
      }
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final c in order) _section(scheme, text, c),
          const SizedBox(height: 32),
        ],
      );
    }

    if (_results.isEmpty) {
      return Center(child: Text(L.commonNoResults,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)));
    }

    if (_tab == _kSearchProfiles) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.0,
        ),
        itemCount: _results.length,
        itemBuilder: (ctx, i) {
          final u     = _results[i] as Map<String, dynamic>;
          final uname = (u['name'] ?? '').toString();
          final isFav = _favProfiles.contains(uname);
          return _FadeSlideIn(
            delay: _staggerDelay(i),
            child: _SearchUserCard(
              user: u, isFav: isFav,
              onTap: () { _haptic(_HapticImpact.light); _openProfile(ctx, uname); },
              onToggleFav: () => _toggleFavProfile(uname, !isFav),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _results.length + 1,
      itemBuilder: (ctx, i) {
        if (i == _results.length) return const SizedBox(height: 32);
        final m = _results[i];
        return switch (_tab) {
          _kSearchArtists => _artistRow(scheme, m, rank: '${i + 1}', listeners: true),
          _kSearchAlbums  => _albumRow(scheme, m, rank: '${i + 1}'),
          _               => _trackRow(scheme, m, rank: '${i + 1}'),
        };
      },
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
        M3CookieBadge(
          color: scheme.primaryContainer, size: 96,
          child: Icon(t.$1, size: 42, color: scheme.primary),
        ),
        const SizedBox(height: 18),
        Text(t.$2, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(L.searchTypePrompt, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
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