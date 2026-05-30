// ignore_for_file: unused_import
part of 'home_screen.dart';


// ── Friend data model ─────────────────────────────────────────────────────────

class _FriendData {
  final String username;
  final String realName;
  final String avatarUrl;
  final bool   isOnline;          // true = currently scrobbling
  final String nowPlayingTrack;
  final String nowPlayingArtist;
  final String lastTrack;         // most recent track when offline
  final String lastArtist;

  const _FriendData({
    required this.username,
    required this.realName,
    required this.avatarUrl,
    required this.isOnline,
    this.nowPlayingTrack  = '',
    this.nowPlayingArtist = '',
    this.lastTrack        = '',
    this.lastArtist       = '',
  });
}


// ── All available stat card definitions ──────────────────────────────────────
// Format: (id, emoji, French label, English label)
const _kAllStatCards = [
  ('top_artist',      '🎤', 'Artiste #1',           'Artist #1'),
  ('top_album',       '💿', 'Album #1',              'Album #1'),
  ('top_track',       '🎵', 'Titre #1',              'Track #1'),
  ('last_track',      '⏱️', 'Dernière écoute',       'Last played'),
  ('total',           '🎯', 'Total scrobbles',        'Total scrobbles'),
  ('avg_day',         '⚡', 'Moy. / jour',            'Avg / day'),
  ('avg_week',        '📅', 'Moy. / semaine',         'Avg / week'),
  ('days_active',     '🗓️', 'Jours actifs',           'Days active'),
  ('since',           '📆', 'Membre depuis',           'Member since'),
  ('country',         '🌍', 'Pays',                   'Country'),
  ('top_artist_week', '🎤', 'Artiste #1 (semaine)',   'Artist #1 (week)'),
  ('top_album_week',  '💿', 'Album #1 (semaine)',     'Album #1 (week)'),
  ('top_track_week',  '🎵', 'Titre #1 (semaine)',     'Track #1 (week)'),
];
const _kDefaultStatCards = ['top_artist', 'top_album', 'top_track', 'last_track'];


// ── Dashboard page ────────────────────────────────────────────────────────────

class _DashboardPage extends StatefulWidget {
  final LastFmService service;
  final String username;
  const _DashboardPage({required this.service, required this.username});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  Map<String, dynamic>? _userInfo;
  List<dynamic> _topArtists    = [];
  List<dynamic> _topAlbums     = [];
  List<dynamic> _topTracks     = [];
  List<dynamic> _recentTracks  = [];
  Map<String, dynamic>? _nowPlaying;
  List<dynamic> _topArtistsWeek = [];
  List<dynamic> _topAlbumsWeek  = [];
  List<dynamic> _topTracksWeek  = [];
  List<String>  _statCards      = List.from(_kDefaultStatCards);

  bool    _loading = true;
  String? _error;
  Timer?  _npTimer;
  Timer?  _topTimer;  // silently refresh top lists every 3 min

  // Header display settings
  String _headerSource          = 'nowplaying';
  String _headerImageUrl        = '';
  double _headerBlur            = 0.0;
  String _headerAnimation       = 'fade';
  String _headerCustomUrl       = '';
  String _headerFallbackUrl     = '';
  bool   _headerFallbackEnabled = false;
  String _fallbackType          = 'none';    // 'none'|'top_track'|'top_album'|'top_artist'|'custom_url'
  String _fallbackPeriod        = 'overall'; // '7day'|'1month'|'overall'
  String _headerPeriod          = 'overall';
  bool   _headerMusicAnim       = false;     // ambient animation when music plays

  // Section visibility flags
  bool _showNowPlay  = true;
  bool _showStats    = true;
  bool _showArtists  = true;
  bool _showTracks   = true;

  // Friends state
  bool              _showFriends    = true;
  List<_FriendData> _friends        = [];
  Set<String>       _favFriends     = {};
  Set<String>       _favProfiles    = {};  // profiles starred from Search
  bool              _friendsLoading = false;

  @override
  void initState() {
    super.initState();
    // Load prefs + cache in parallel for instant display
    _initWithCache();
    // Poll now playing every 10 s — rebuild only when track changes
    _npTimer  = Timer.periodic(const Duration(seconds: 10), (_) => _refreshLive());
    // Silent top-list refresh every 3 min
    _topTimer = Timer.periodic(const Duration(minutes: 3),  (_) => _refreshTopLists());
  }

  @override
  void dispose() {
    _npTimer?.cancel();
    _topTimer?.cancel();
    super.dispose();
  }

  // Load prefs and cache at the same time.
  // If cache has valid data, show it immediately then refresh quietly in background.
  Future<void> _initWithCache() async {
    await _loadPrefs();
    if (!mounted) return;

    final gotCache = _loadFromCache();
    if (gotCache) {
      _resolveHeaderImage();
      if (_showFriends) _loadFriends();
      _load(silent: true);
    } else {
      _load();
    }
  }

  // Read data from in-memory cache (synchronous, instant).
  // Returns true if usable data was found.
  bool _loadFromCache() {
    final userInfo = DataCache.getSync(DataCache.keyUserInfo());
    if (userInfo == null) return false;

    final topArtists = DataCache.getSync(DataCache.keyTopArtists('overall')) as List?;
    final topAlbums  = DataCache.getSync(DataCache.keyTopAlbums('overall'))  as List?;
    final topTracks  = DataCache.getSync(DataCache.keyTopTracks('overall'))  as List?;
    final recentRaw  = DataCache.getSync(DataCache.keyRecentTracks(limit: 10));
    final topArtW    = DataCache.getSync(DataCache.keyTopArtists('7day'))    as List?;
    final topAlbW    = DataCache.getSync(DataCache.keyTopAlbums('7day'))     as List?;
    final topTrkW    = DataCache.getSync(DataCache.keyTopTracks('7day'))     as List?;

    // Separate now-playing from the recent tracks list
    Map<String, dynamic>? np;
    final recentF = <dynamic>[];
    if (recentRaw is Map) {
      final trackRaw  = recentRaw['track'];
      final allRecent = trackRaw is List
          ? trackRaw
          : (trackRaw != null ? [trackRaw] : <dynamic>[]);
      for (final t in allRecent) {
        if ((t as Map?)?['@attr']?['nowplaying'] == 'true') {
          np = t as Map<String, dynamic>;
        } else {
          recentF.add(t);
        }
      }
    }

    setState(() {
      _userInfo       = userInfo as Map<String, dynamic>;
      _topArtists     = topArtists ?? [];
      _topAlbums      = topAlbums  ?? [];
      _topTracks      = topTracks  ?? [];
      _recentTracks   = recentF;
      _nowPlaying     = np;
      _topArtistsWeek = topArtW    ?? [];
      _topAlbumsWeek  = topAlbW    ?? [];
      _topTracksWeek  = topTrkW    ?? [];
      _loading        = false;
    });

    if (np != null) _extractColor(np);
    return true;
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _headerSource          = p.getString('ls_header_source')          ?? 'nowplaying';
      _headerBlur            = p.getDouble('ls_header_blur')             ?? 0.0;
      _headerAnimation       = p.getString('ls_header_animation')       ?? 'fade';
      _headerCustomUrl       = p.getString('ls_header_custom_url')      ?? '';
      _headerFallbackUrl     = p.getString('ls_header_fallback_url')    ?? '';
      _headerFallbackEnabled = p.getBool('ls_header_fallback_enabled')  ?? false;
      _fallbackType          = p.getString('ls_header_fallback_type')   ?? 'none';
      _fallbackPeriod        = p.getString('ls_header_fallback_period') ?? 'overall';
      _headerPeriod          = p.getString('ls_header_period')          ?? 'overall';
      _headerMusicAnim       = p.getBool('ls_header_music_anim')        ?? false;
      _showNowPlay           = p.getBool('ls_show_nowplay')             ?? true;
      _showStats             = p.getBool('ls_show_stats')               ?? true;
      _showArtists           = p.getBool('ls_show_artists')             ?? true;
      _showTracks            = p.getBool('ls_show_tracks')              ?? true;
      _showFriends           = p.getBool('ls_show_friends')             ?? true;
      final rawCards = p.getStringList('ls_stat_cards');
      _statCards   = rawCards != null && rawCards.isNotEmpty
          ? rawCards : List.from(_kDefaultStatCards);
      _favFriends  = Set<String>.from(p.getStringList('ls_fav_friends')  ?? []);
      _favProfiles = Set<String>.from(p.getStringList('ls_fav_profiles') ?? []);
    });
  }

  // silent = true → no skeleton, quiet background update
  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        widget.service.getUserInfo(),
        widget.service.getTopArtists(period: 'overall', limit: 50),
        widget.service.getTopAlbums (period: 'overall', limit: 50),
        widget.service.getTopTracks (period: 'overall', limit: 50),
        widget.service.getRecentTracks(limit: 10),
        widget.service.getNowPlaying(),
        // Week top lists — only fetched when the matching card is enabled
        if (_statCards.contains('top_artist_week'))
          widget.service.getTopArtists(period: '7day', limit: 1)
        else
          Future.value(<dynamic>[]),
        if (_statCards.contains('top_album_week'))
          widget.service.getTopAlbums(period: '7day', limit: 1)
        else
          Future.value(<dynamic>[]),
        if (_statCards.contains('top_track_week'))
          widget.service.getTopTracks(period: '7day', limit: 1)
        else
          Future.value(<dynamic>[]),
      ]);

      final recentRaw = (res[4] as Map<String, dynamic>)['track'];
      final allRecent = recentRaw is List ? recentRaw
          : (recentRaw != null ? [recentRaw] : <dynamic>[]);
      Map<String, dynamic>? np;
      final recentF = <dynamic>[];
      for (final t in allRecent) {
        if ((t as Map?)?['@attr']?['nowplaying'] == 'true') { np = t as Map<String, dynamic>; }
        else { recentF.add(t); }
      }

      if (!mounted) return;
      setState(() {
        _userInfo       = res[0] as Map<String, dynamic>?;
        _topArtists     = res[1] as List<dynamic>;
        _topAlbums      = res[2] as List<dynamic>;
        _topTracks      = res[3] as List<dynamic>;
        _recentTracks   = recentF;
        _nowPlaying     = np ?? res[5] as Map<String, dynamic>?;
        _topArtistsWeek = res.length > 6 ? res[6] as List<dynamic> : [];
        _topAlbumsWeek  = res.length > 7 ? res[7] as List<dynamic> : [];
        _topTracksWeek  = res.length > 8 ? res[8] as List<dynamic> : [];
        _loading        = false;
      });

      if (_nowPlaying != null) _extractColor(_nowPlaying!);
      _resolveHeaderImage();
      _saveToCache(res);
      // Load friends without blocking the main page
      if (_showFriends) _loadFriends();
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
      }
    }
  }

  // Save API results to cache for next startup
  void _saveToCache(List<dynamic> res) {
    DataCache.set(DataCache.keyUserInfo(),            res[0]);
    DataCache.set(DataCache.keyTopArtists('overall'), res[1]);
    DataCache.set(DataCache.keyTopAlbums('overall'),  res[2]);
    DataCache.set(DataCache.keyTopTracks('overall'),  res[3]);
    DataCache.set(DataCache.keyRecentTracks(limit: 10), res[4]);
    if (res.length > 6 && (res[6] as List).isNotEmpty)
      DataCache.set(DataCache.keyTopArtists('7day'), res[6]);
    if (res.length > 7 && (res[7] as List).isNotEmpty)
      DataCache.set(DataCache.keyTopAlbums('7day'),  res[7]);
    if (res.length > 8 && (res[8] as List).isNotEmpty)
      DataCache.set(DataCache.keyTopTracks('7day'),  res[8]);
  }

  // Silent now-playing poll (every 10 s).
  // Rebuilds UI only when the track actually changes — avoids carousel flicker.
  Future<void> _refreshLive() async {
    try {
      final np = await widget.service.getNowPlaying();
      if (!mounted) return;

      final prevName   = _nowPlaying?['name']?.toString() ?? '';
      final prevArtist = (_nowPlaying?['artist']?['#text'] ?? '').toString();
      final newName    = np?['name']?.toString() ?? '';
      final newArtist  = (np?['artist']?['#text'] ?? '').toString();
      final changed    = prevName != newName || prevArtist != newArtist;

      if (changed) {
        // Different track → update UI, accent color, and header image
        setState(() => _nowPlaying = np);
        if (np != null) {
          _extractColor(np);
          DataCache.set(DataCache.keyNowPlaying(), np);
        }
        _resolveHeaderImage();
      } else if (np != null) {
        // Same track → silent cache update, no rebuild
        DataCache.set(DataCache.keyNowPlaying(), np);
      }
    } catch (_) {}
    // Also refresh friends status silently
    if (_showFriends && mounted) _loadFriends(silent: true);
  }

  // Silently refresh top artists and tracks every 3 min
  Future<void> _refreshTopLists() async {
    if (!mounted) return;
    try {
      final results = await Future.wait([
        widget.service.getTopArtists(period: 'overall', limit: 50),
        widget.service.getTopTracks (period: 'overall', limit: 50),
        if (_statCards.contains('top_artist_week'))
          widget.service.getTopArtists(period: '7day', limit: 1)
        else
          Future.value(<dynamic>[]),
        if (_statCards.contains('top_track_week'))
          widget.service.getTopTracks(period: '7day', limit: 1)
        else
          Future.value(<dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _topArtists    = results[0] as List<dynamic>;
        _topTracks     = results[1] as List<dynamic>;
        if (results.length > 2) _topArtistsWeek = results[2] as List<dynamic>;
        if (results.length > 3) _topTracksWeek  = results[3] as List<dynamic>;
      });
      DataCache.set(DataCache.keyTopArtists('overall'), results[0]);
      DataCache.set(DataCache.keyTopTracks('overall'),  results[1]);
      if (results.length > 2 && (results[2] as List).isNotEmpty)
        DataCache.set(DataCache.keyTopArtists('7day'), results[2]);
      if (results.length > 3 && (results[3] as List).isNotEmpty)
        DataCache.set(DataCache.keyTopTracks('7day'),  results[3]);
    } catch (_) {}
  }

  // Load friends. silent = true skips the loading skeleton.
  Future<void> _loadFriends({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _friendsLoading = true);
    try {
      final raw = await widget.service.getFriends(limit: 50, withRecentTrack: false);

      // getFriends doesn't reliably include now-playing info,
      // so we call getRecentTracks(limit:1) for each friend in parallel.
      final usernames = raw.map((u) => (u['name'] ?? '').toString()).toList();

      final recentResults = await Future.wait(
        usernames.map((name) => widget.service
            .getRecentTracks(limit: 1, user: name)
            .catchError((_) => <String, dynamic>{})),
      );

      final friends = <_FriendData>[];

      for (var i = 0; i < raw.length; i++) {
        final u     = raw[i];
        final uname = usernames[i];

        final recentData = recentResults[i];
        final trackRaw   = recentData['track'];
        final tList      = trackRaw is List
            ? trackRaw
            : (trackRaw != null ? [trackRaw] : []);

        bool   isOnline   = false;
        String trackName  = '';
        String artistName = '';

        if (tList.isNotEmpty) {
          final t   = tList.first as Map;
          isOnline  = t['@attr']?['nowplaying'] == 'true';
          trackName = (t['name'] ?? '').toString();
          final ra  = t['artist'];
          if (ra is Map) {
            artistName = (ra['#text'] ?? ra['name'] ?? '').toString();
          } else {
            artistName = ra?.toString() ?? '';
          }
        }

        friends.add(_FriendData(
          username:         uname,
          realName:         (u['realname'] ?? '').toString(),
          avatarUrl:        _extractImage(u['image']),
          isOnline:         isOnline,
          nowPlayingTrack:  isOnline  ? trackName  : '',
          nowPlayingArtist: isOnline  ? artistName : '',
          lastTrack:        !isOnline ? trackName  : '',
          lastArtist:       !isOnline ? artistName : '',
        ));
      }

      // Also include starred profiles from Search that aren't already in the list
      final existingNames = friends.map((f) => f.username.toLowerCase()).toSet();
      for (final favUsername in _favProfiles) {
        if (existingNames.contains(favUsername.toLowerCase())) continue;
        try {
          final info = await widget.service.getUserInfo(user: favUsername);
          if (info == null) continue;
          final uname = (info['name'] ?? favUsername).toString();

          bool   isOnline  = false;
          String npTrack   = '', npArtist   = '';
          String lastTrack = '', lastArtist = '';
          try {
            final recent = await widget.service.getRecentTracks(limit: 1, user: uname);
            final tracks = recent['track'];
            final tList  = tracks is List ? tracks : (tracks != null ? [tracks] : []);
            if (tList.isNotEmpty) {
              final t       = tList.first as Map;
              final nowPlay = t['@attr']?['nowplaying'] == 'true';
              final tName   = (t['name'] ?? '').toString();
              final ra      = t['artist'];
              final tArtist = ra is Map
                  ? (ra['#text'] ?? ra['name'] ?? '').toString()
                  : (ra?.toString() ?? '');
              if (nowPlay) {
                isOnline = true;
                npTrack  = tName;
                npArtist = tArtist;
              } else {
                lastTrack  = tName;
                lastArtist = tArtist;
              }
            }
          } catch (_) {}

          friends.add(_FriendData(
            username:         uname,
            realName:         (info['realname'] ?? '').toString(),
            avatarUrl:        _extractImage(info['image']),
            isOnline:         isOnline,
            nowPlayingTrack:  npTrack,
            nowPlayingArtist: npArtist,
            lastTrack:        lastTrack,
            lastArtist:       lastArtist,
          ));
          existingNames.add(uname.toLowerCase());
        } catch (_) {}
      }

      // Sort: online+fav (3) > online (2) > offline+fav (1) > offline (0)
      friends.sort((a, b) {
        final aFav   = _favFriends.contains(a.username) || _favProfiles.contains(a.username);
        final bFav   = _favFriends.contains(b.username) || _favProfiles.contains(b.username);
        final aScore = (a.isOnline ? 2 : 0) + (aFav ? 1 : 0);
        final bScore = (b.isOnline ? 2 : 0) + (bFav ? 1 : 0);
        if (aScore != bScore) return bScore.compareTo(aScore);
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });

      if (mounted) setState(() { _friends = friends; _friendsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _friendsLoading = false);
    }
  }

  // Toggle a friend's favourite status and persist it
  Future<void> _toggleFav(String username, bool nowFav) async {
    final updatedFriends  = Set<String>.from(_favFriends);
    final updatedProfiles = Set<String>.from(_favProfiles);
    if (nowFav) {
      updatedFriends.add(username);
    } else {
      updatedFriends.remove(username);
      updatedProfiles.remove(username);
    }
    final p = await SharedPreferences.getInstance();
    await p.setStringList('ls_fav_friends',  updatedFriends.toList());
    await p.setStringList('ls_fav_profiles', updatedProfiles.toList());
    if (!mounted) return;
    setState(() {
      _favFriends  = updatedFriends;
      _favProfiles = updatedProfiles;
      _friends.sort((a, b) {
        final aFav   = updatedFriends.contains(a.username) || updatedProfiles.contains(a.username);
        final bFav   = updatedFriends.contains(b.username) || updatedProfiles.contains(b.username);
        final aScore = (a.isOnline ? 2 : 0) + (aFav ? 1 : 0);
        final bScore = (b.isOnline ? 2 : 0) + (bFav ? 1 : 0);
        if (aScore != bScore) return bScore.compareTo(aScore);
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    });
  }

  // Pick the header image based on the user's chosen source
  Future<void> _resolveHeaderImage() async {
    String url = '';
    switch (_headerSource) {
      case 'custom':
        url = _headerCustomUrl;
      case 'nowplaying':
        if (_nowPlaying != null) {
          final raw = _extractImage(_nowPlaying!['image']);
          url = await ImageService.resolveTrack(
            (_nowPlaying!['name'] ?? '').toString(),
            (_nowPlaying!['artist']?['#text'] ?? '').toString(),
            lastfmUrl: raw,
          );
        }
        // No music playing (or image missing) → apply fallback
        if (url.isEmpty && _fallbackType != 'none') {
          url = await _resolveFallbackImage();
        }
      case 'top_track':
        final tracks = _headerPeriod == 'overall'
            ? _topTracks
            : await widget.service.getTopTracks(period: _headerPeriod, limit: 1);
        if (tracks.isNotEmpty) {
          final t = tracks[0] as Map;
          url = await ImageService.resolveTrack(
            (t['name'] ?? '').toString(),
            (t['artist']?['name'] ?? '').toString(),
            lastfmUrl: _extractImage(t['image']),
          );
        }
      case 'top_album':
        final albums = _headerPeriod == 'overall'
            ? _topAlbums
            : await widget.service.getTopAlbums(period: _headerPeriod, limit: 1);
        if (albums.isNotEmpty) {
          final a = albums[0] as Map;
          url = await ImageService.resolveAlbum(
            (a['name'] ?? '').toString(),
            (a['artist']?['name'] ?? '').toString(),
            lastfmUrl: _extractImage(a['image']),
          );
        }
      case 'top_artist':
        final artists = _headerPeriod == 'overall'
            ? _topArtists
            : await widget.service.getTopArtists(period: _headerPeriod, limit: 1);
        if (artists.isNotEmpty) {
          final a = artists[0] as Map;
          url = await ImageService.resolveArtist(
            (a['name'] ?? '').toString(),
            lastfmUrl: _extractImage(a['image']),
          );
        }
      default:
        url = '';
    }
    if (mounted) setState(() => _headerImageUrl = url);
  }

  // Resolve the fallback header image when nowplaying source has no image.
  // Only called when fallbackType != 'none'.
  Future<String> _resolveFallbackImage() async {
    try {
      switch (_fallbackType) {
        case 'top_track':
          final tracks = _fallbackPeriod == 'overall' && _topTracks.isNotEmpty
              ? _topTracks
              : await widget.service.getTopTracks(period: _fallbackPeriod, limit: 1);
          if (tracks.isNotEmpty) {
            final t = tracks[0] as Map;
            return ImageService.resolveTrack(
              (t['name'] ?? '').toString(),
              (t['artist']?['name'] ?? '').toString(),
              lastfmUrl: _extractImage(t['image']),
            );
          }
        case 'top_album':
          final albums = _fallbackPeriod == 'overall' && _topAlbums.isNotEmpty
              ? _topAlbums
              : await widget.service.getTopAlbums(period: _fallbackPeriod, limit: 1);
          if (albums.isNotEmpty) {
            final a = albums[0] as Map;
            return ImageService.resolveAlbum(
              (a['name'] ?? '').toString(),
              (a['artist']?['name'] ?? '').toString(),
              lastfmUrl: _extractImage(a['image']),
            );
          }
        case 'top_artist':
          final artists = _fallbackPeriod == 'overall' && _topArtists.isNotEmpty
              ? _topArtists
              : await widget.service.getTopArtists(period: _fallbackPeriod, limit: 1);
          if (artists.isNotEmpty) {
            final a = artists[0] as Map;
            return ImageService.resolveArtist(
              (a['name'] ?? '').toString(),
              lastfmUrl: _extractImage(a['image']),
            );
          }
        case 'custom_url':
          if (_headerFallbackUrl.isNotEmpty) return _headerFallbackUrl;
      }
    } catch (_) {}
    return '';
  }

  // Extract a dominant color from the now-playing artwork and update the accent
  Future<void> _extractColor(Map<String, dynamic> track) async {
    if (!useNowPlayingColorNotifier.value) return;
    final url = _extractImage(track['image']);
    if (url.isEmpty || url.contains('2a96cbd8b46e442fc41c2b86b821562f')) return;
    try {
      final pal = await PaletteGenerator.fromImageProvider(
        NetworkImage(url), size: const Size(160, 160), maximumColorCount: 16);
      final c = pal.vibrantColor?.color ?? pal.dominantColor?.color;
      if (c != null && mounted) accentNotifier.value = c;
    } catch (_) {}
  }

  // ── Stat helpers ──────────────────────────────────────────────────────────

  int    _total()  => int.tryParse((_userInfo?['playcount'] ?? '0').toString()) ?? 0;
  int    _days()   {
    final raw = _userInfo?['registered'];
    if (raw == null) return 0;
    int ts = 0;
    if (raw is Map) { ts = int.tryParse((raw['#text'] ?? raw['unixtime'] ?? '0').toString()) ?? 0; }
    else            { ts = int.tryParse(raw.toString()) ?? 0; }
    if (ts <= 0) return 0;
    return ((DateTime.now().millisecondsSinceEpoch / 1000 - ts) / 86400).floor();
  }
  double _avg()    { final d = _days(); return d > 0 ? _total() / d : 0; }
  int    _weekly() => (_avg() * 7).round();
  String _regDate() {
    final raw = _userInfo?['registered'];
    if (raw == null) return '';
    int ts = 0;
    if (raw is Map) { ts = int.tryParse((raw['#text'] ?? raw['unixtime'] ?? '0').toString()) ?? 0; }
    else            { ts = int.tryParse(raw.toString()) ?? 0; }
    if (ts <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.day} ${_kMonths[d.month]} ${d.year}';
  }

  // Build a single stat card widget by id
  Widget? _buildStatCard(
    String id, {
    Map? topArtist, Map? topAlbum, Map? topTrack, Map? lastTrack,
    Map? topArtistWeek, Map? topAlbumWeek, Map? topTrackWeek,
    int total = 0, double avg = 0, int weekly = 0,
    int days = 0, String regStr = '', String country = '',
  }) {
    switch (id) {
      case 'top_artist':
        return _DashStatCard(
          emoji: '🎤',
          value: topArtist != null ? (topArtist['name'] ?? '—').toString() : '—',
          label: L.dashArtist1,
          sub:   topArtist != null
              ? '${_fmt(int.tryParse((topArtist['playcount'] ?? '0').toString()) ?? 0)} ${L.commonPlays}'
              : null,
        );
      case 'top_album':
        return _DashStatCard(
          emoji: '💿',
          value: topAlbum != null ? (topAlbum['name'] ?? '—').toString() : '—',
          label: L.dashAlbum1,
          sub:   topAlbum != null ? (topAlbum['artist']?['name'] ?? '').toString() : null,
        );
      case 'top_track':
        return _DashStatCard(
          emoji: '🎵',
          value: topTrack != null ? (topTrack['name'] ?? '—').toString() : '—',
          label: L.dashTrack1,
          sub:   topTrack != null
              ? '${_fmt(int.tryParse((topTrack['playcount'] ?? '0').toString()) ?? 0)} ${L.commonPlays}'
              : null,
        );
      case 'last_track':
        return _DashStatCard(
          emoji: '⏱️',
          value: lastTrack != null ? (lastTrack['name'] ?? '—').toString() : '—',
          label: L.dashLastTrack,
          sub:   lastTrack != null ? _fmtTrackDateLocal(lastTrack) : null,
        );
      case 'total':
        return _DashStatCard(
          emoji:      '🎯',
          value:      _fmtFull(total),
          label:      localeNotifier.value == 'en' ? 'Total scrobbles' : 'Total scrobbles',
          sub:        null,
          rawInt:     total,
          rollPrefix: '',
        );
      case 'avg_day':
        return _DashStatCard(
          emoji:      '⚡',
          value:      '~${_fmt(avg.round())}',
          label:      L.dashScrobblesPerDay,
          sub:        null,
          rawInt:     avg.round(),
          rollPrefix: '~',
        );
      case 'avg_week':
        return _DashStatCard(
          emoji:      '📅',
          value:      '~${_fmt(weekly)}',
          label:      L.dashPerWeek,
          sub:        null,
          rawInt:     weekly,
          rollPrefix: '~',
        );
      case 'days_active':
        return _DashStatCard(
          emoji:      '🗓️',
          value:      '$days j',
          label:      L.dashDaysActive,
          sub:        null,
          rawInt:     days,
          rollSuffix: ' j',
        );
      case 'since':
        return _DashStatCard(
          emoji: '📆',
          value: regStr.isNotEmpty ? regStr : '—',
          label: localeNotifier.value == 'en' ? 'Member since' : 'Membre depuis',
          sub:   null,
        );
      case 'country':
        return _DashStatCard(
          emoji: '🌍',
          value: (country.isNotEmpty && country != 'None') ? country : '—',
          label: localeNotifier.value == 'en' ? 'Country' : 'Pays',
          sub:   null,
        );
      case 'top_artist_week':
        return _DashStatCard(
          emoji: '🎤',
          value: topArtistWeek != null ? (topArtistWeek['name'] ?? '—').toString() : '—',
          label: localeNotifier.value == 'en' ? 'Artist #1 (week)' : 'Artiste #1 (semaine)',
          sub:   topArtistWeek != null
              ? '${_fmt(int.tryParse((topArtistWeek['playcount'] ?? '0').toString()) ?? 0)} ${L.commonPlays}'
              : null,
        );
      case 'top_album_week':
        return _DashStatCard(
          emoji: '💿',
          value: topAlbumWeek != null ? (topAlbumWeek['name'] ?? '—').toString() : '—',
          label: localeNotifier.value == 'en' ? 'Album #1 (week)' : 'Album #1 (semaine)',
          sub:   topAlbumWeek != null ? (topAlbumWeek['artist']?['name'] ?? '').toString() : null,
        );
      case 'top_track_week':
        return _DashStatCard(
          emoji: '🎵',
          value: topTrackWeek != null ? (topTrackWeek['name'] ?? '—').toString() : '—',
          label: localeNotifier.value == 'en' ? 'Track #1 (week)' : 'Titre #1 (semaine)',
          sub:   topTrackWeek != null
              ? '${_fmt(int.tryParse((topTrackWeek['playcount'] ?? '0').toString()) ?? 0)} ${L.commonPlays}'
              : null,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) return _DashboardSkeleton(scheme: Theme.of(context).colorScheme);
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);

    final info      = _userInfo!;
    final name      = (info['name']     ?? widget.username).toString();
    final realName  = (info['realname'] ?? '').toString();
    final country   = (info['country']  ?? '').toString();
    final avatarUrl = _extractImage(info['image']);

    final total  = _total();
    final days   = _days();
    final avg    = _avg();
    final weekly = _weekly();
    final regStr = _regDate();

    final topArtist = _topArtists.isNotEmpty ? _topArtists[0] as Map : null;
    final topAlbum  = _topAlbums.isNotEmpty  ? _topAlbums[0]  as Map : null;
    final topTrack  = _topTracks.isNotEmpty  ? _topTracks[0]  as Map : null;
    final lastTrack = _recentTracks.isNotEmpty ? _recentTracks[0] as Map : null;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(slivers: [

        // ── Profile app bar ────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 230,
          pinned: true,
          stretch: true,
          actions: [
            // Refresh button + scrobble-sync progress chip
            ValueListenableBuilder<AllScrobblesProgress>(
              valueListenable: AllScrobblesService.progressNotifier,
              builder: (_, progress, _) {
                final isSyncing = progress.isLoading;
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isSyncing)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: _SyncProgressChip(progress: progress),
                    ),
                  _SyncRefreshButton(
                    isSyncing: isSyncing,
                    onPressed: isSyncing ? null : _load,
                    tooltip:   L.dashRefresh,
                  ),
                ]);
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () async {
                // Open the settings hub
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text(L.navSettings),
                        scrolledUnderElevation: 0,
                      ),
                      body: _SettingsPage(username: widget.username),
                    ),
                  ),
                );
                // Reload prefs on return so any changes are applied immediately
                if (mounted) {
                  await _loadPrefs();
                  _resolveHeaderImage();
                }
              },
              tooltip: L.navSettings,
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or gradient with animated transition
                AnimatedSwitcher(
                  duration: _headerAnimation == 'none'
                      ? Duration.zero
                      : const Duration(milliseconds: 700),
                  transitionBuilder: (child, anim) {
                    switch (_headerAnimation) {
                      case 'slide':
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.06, 0),
                            end:   Offset.zero,
                          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                          child: FadeTransition(opacity: anim, child: child),
                        );
                      case 'zoom':
                        return ScaleTransition(
                          scale: Tween<double>(begin: 1.10, end: 1.0)
                              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                          child: FadeTransition(opacity: anim, child: child),
                        );
                      default:
                        return FadeTransition(opacity: anim, child: child);
                    }
                  },
                  child: (_headerMusicAnim && _nowPlaying != null)
                      // Apple Music-style: blurred image breathing + drifting
                      ? _AmbientHeader(
                          key: ValueKey('ambient_${_headerImageUrl}'),
                          url: _headerImageUrl,
                          scheme: scheme,
                        )
                      : _headerImageUrl.isNotEmpty
                          ? _BlurredHeaderImage(
                              key: ValueKey(_headerImageUrl),
                              url: _headerImageUrl,
                              blur: _headerBlur,
                              scheme: scheme,
                            )
                          : _GradientHeader(key: const ValueKey('gradient'), scheme: scheme),
                ),

                // Dark gradient overlay for text readability
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end:   Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),

                // Profile info (avatar + name + country + since)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 70, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          // Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: scheme.primary.withValues(alpha: 0.3),
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl.isEmpty
                                  ? const Icon(Icons.person_rounded,
                                      size: 28, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                style: const TextStyle(
                                  color:      Colors.white,
                                  fontSize:   20,
                                  fontWeight: FontWeight.w800,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                )),
                              if (realName.isNotEmpty)
                                Text(realName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                                  )),
                              Row(children: [
                                if (country.isNotEmpty && country != 'None') ...[
                                  Icon(Icons.location_on_outlined,
                                      size: 12,
                                      color: Colors.white.withValues(alpha: 0.75)),
                                  const SizedBox(width: 2),
                                  Text(country,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 12,
                                      shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                                    )),
                                  const SizedBox(width: 8),
                                ],
                                if (regStr.isNotEmpty) ...[
                                  Icon(Icons.calendar_today_outlined,
                                      size: 11,
                                      color: Colors.white.withValues(alpha: 0.75)),
                                  const SizedBox(width: 2),
                                  Text(L.memberSince(regStr),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 12,
                                      shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                                    )),
                                ],
                              ]),
                            ],
                          )),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // Now playing card
              if (_showNowPlay && _nowPlaying != null) ...[
                _NowPlayingCard(track: _nowPlaying!),
                const SizedBox(height: 14),
              ],

              // Stats block
              if (_showStats) ...[
                _SectionHeader(title: L.dashStats, icon: Icons.bar_chart_rounded),
                const SizedBox(height: 10),
                _HeroStatCard(
                  total:  total,
                  avg:    avg.round(),
                  days:   days,
                  weekly: weekly,
                  regStr: regStr,
                ),
                const SizedBox(height: 10),
                _StatGrid(children: _statCards.map((id) {
                  return _buildStatCard(
                    id,
                    total: total, avg: avg, weekly: weekly,
                    days: days, regStr: regStr, country: country,
                    topArtist: topArtist, topAlbum: topAlbum,
                    topTrack: topTrack, lastTrack: lastTrack,
                    topArtistWeek: _topArtistsWeek.isNotEmpty ? _topArtistsWeek[0] as Map : null,
                    topAlbumWeek:  _topAlbumsWeek.isNotEmpty  ? _topAlbumsWeek[0]  as Map : null,
                    topTrackWeek:  _topTracksWeek.isNotEmpty  ? _topTracksWeek[0]  as Map : null,
                  );
                }).whereType<Widget>().toList()),
                const SizedBox(height: 20),
              ],

              // Friends horizontal scroll
              if (_showFriends) ...[
                _FriendsSection(
                  friends:     _friends,
                  favorites:   _favFriends,
                  favProfiles: _favProfiles,
                  service:     widget.service,
                  isLoading:   _friendsLoading,
                  onToggleFav: _toggleFav,
                  onRefresh:   _loadFriends,
                ),
                const SizedBox(height: 20),
              ],

              // Top artists carousel
              if (_showArtists && _topArtists.isNotEmpty) ...[
                _SectionHeader(title: L.commonTopArtists, icon: Icons.mic_rounded),
                const SizedBox(height: 10),
                _HorizontalCarousel(
                  items:   _topArtists.take(10).toList(),
                  type:    'artists',
                  service: widget.service,
                ),
                const SizedBox(height: 20),
              ],

              // Top tracks carousel
              if (_showTracks && _topTracks.isNotEmpty) ...[
                _SectionHeader(title: L.dashTopTracks, icon: Icons.music_note_rounded),
                const SizedBox(height: 10),
                _HorizontalCarousel(
                  items:   _topTracks.take(10).toList(),
                  type:    'tracks',
                  service: widget.service,
                ),
                const SizedBox(height: 20),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}


// ── Horizontal Spotify/Apple Music-style carousel ─────────────────────────────

class _HorizontalCarousel extends StatelessWidget {
  final List<dynamic>  items;
  final String         type;    // 'artists' | 'tracks'
  final LastFmService  service;

  const _HorizontalCarousel({
    required this.items,
    required this.type,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    // Card width ~52 % of screen width, capped at 220
    final cardW = (MediaQuery.of(context).size.width * 0.52).clamp(160.0, 220.0);
    final cardH = cardW * 1.10; // slightly portrait ratio

    return SizedBox(
      height: cardH,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 8),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item   = items[i] as Map<String, dynamic>;
          final name   = (item['name'] ?? '').toString();
          final artist = type != 'artists'
              ? (item['artist']?['name'] ?? '').toString()
              : '';
          final plays  = int.tryParse((item['playcount'] ?? '0').toString()) ?? 0;
          final raw    = _extractImage(item['image']);

          final Future<String> imgFuture;
          switch (type) {
            case 'artists':
              imgFuture = ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null);
            case 'tracks':
              imgFuture = ImageService.resolveTrack(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null);
            default:
              imgFuture = ImageService.resolveAlbum(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null);
          }

          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
            child: _CarouselCard(
              width:       cardW,
              height:      cardH,
              name:        name,
              sub:         type != 'artists' ? artist : '',
              plays:       _fmt(plays),
              rank:        '${i + 1}',
              initialUrl:  raw,
              imageFuture: imgFuture,
              onTap: () => showDetailSheet(
                ctx,
                Map<String, dynamic>.from(item),
                type,
                service,
              ),
            ),
          );
        },
      ),
    );
  }
}


// ── Single carousel card (StatefulWidget for press-scale feedback) ─────────────

class _CarouselCard extends StatefulWidget {
  final double  width, height;
  final String  name, sub, plays, rank;
  final String? initialUrl;
  final Future<String> imageFuture;
  final VoidCallback   onTap;

  const _CarouselCard({
    required this.width,
    required this.height,
    required this.name,
    required this.sub,
    required this.plays,
    required this.rank,
    required this.imageFuture,
    required this.onTap,
    this.initialUrl,
  });

  @override
  State<_CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<_CarouselCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap:       widget.onTap,
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: widget.width, height: widget.height,
            child: Stack(fit: StackFit.expand, children: [

              // Full-bleed background image
              _CarouselImage(
                initialUrl: widget.initialUrl,
                resolver:   () => widget.imageFuture,
                width:      widget.width,
                height:     widget.height,
              ),

              // Bottom gradient for text readability
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.topCenter,
                    end:    Alignment.bottomCenter,
                    stops:  const [0.35, 0.72, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),

              // Text content at the bottom
              Positioned(
                left: 10, right: 10, bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color:      Colors.white,
                        fontWeight: FontWeight.w800,
                        height:     1.2,
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 8),
                        ],
                      ),
                    ),
                    if (widget.sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color:  Colors.white.withValues(alpha: 0.75),
                          height: 1.2,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Plays pill + rank badge
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:        Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border:       Border.all(
                              color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: Text(
                          '${widget.plays} ${L.commonPlays}',
                          style: text.labelSmall?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color:  Colors.white.withValues(alpha: 0.15),
                          shape:  BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35), width: 1),
                        ),
                        child: Center(
                          child: Text(
                            widget.rank,
                            style: text.labelSmall?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}


// ── Full-bleed background image for carousel cards ────────────────────────────

class _CarouselImage extends StatelessWidget {
  final String? initialUrl;
  final Future<String> Function() resolver;
  final double width, height;

  static const _ph = '2a96cbd8b46e442fc41c2b86b821562f';

  bool get _needsResolve =>
      initialUrl == null || initialUrl!.isEmpty || initialUrl!.contains(_ph);

  const _CarouselImage({
    required this.resolver,
    required this.width,
    required this.height,
    this.initialUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_needsResolve) return _img(initialUrl!, scheme);
    return FutureBuilder<String>(
      future: resolver(),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) return _skeleton(scheme);
        final url = snap.data ?? '';
        return url.isEmpty ? _fallback(scheme) : _img(url, scheme);
      },
    );
  }

  Widget _img(String url, ColorScheme s) => Image.network(
    url, width: width, height: height, fit: BoxFit.cover,
    errorBuilder: (_, _, _) => _fallback(s),
  );

  Widget _skeleton(ColorScheme s) => Container(
    width: width, height: height,
    color: s.surfaceContainerHighest,
    child: Center(child: SizedBox(
      width: 28, height: 28,
      child: CircularProgressIndicator(
          strokeWidth: 2, color: s.primary.withValues(alpha: 0.4)),
    )),
  );

  Widget _fallback(ColorScheme s) => Container(
    width: width, height: height,
    color: s.surfaceContainerHighest,
    child: Icon(Icons.music_note_rounded,
        color: s.onSurfaceVariant, size: width * 0.35),
  );
}


// ── Friends section (header + horizontal scroll) ──────────────────────────────

class _FriendsSection extends StatelessWidget {
  final List<_FriendData>                           friends;
  final Set<String>                                 favorites;
  final Set<String>                                 favProfiles;
  final LastFmService                               service;
  final bool                                        isLoading;
  final void Function(String username, bool nowFav) onToggleFav;
  final VoidCallback                                onRefresh;

  const _FriendsSection({
    required this.friends,
    required this.favorites,
    required this.favProfiles,
    required this.service,
    required this.isLoading,
    required this.onToggleFav,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Section header + manual refresh button
      Row(children: [
        _SectionHeader(title: L.dashFriends, icon: Icons.people_rounded),
        const Spacer(),
        if (!isLoading)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onRefresh,
            tooltip: L.dashRefreshFriends,
          ),
      ]),

      const SizedBox(height: 10),

      SizedBox(
        height: 152,
        child: isLoading
            // Shimmer placeholders while loading
            ? ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                padding: EdgeInsets.zero,
                itemBuilder: (_, _) => _FriendCardSkeleton(scheme: scheme),
              )
            : friends.isEmpty
                ? Center(
                    child: Text(
                      L.dashNoFriends,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (ctx, i) {
                      final f     = friends[i];
                      final isFav = favorites.contains(f.username)
                                 || favProfiles.contains(f.username);
                      return _FriendCard(
                        friend:      f,
                        isFav:       isFav,
                        service:     service,
                        onToggleFav: () => onToggleFav(f.username, !isFav),
                      );
                    },
                  ),
      ),
    ]);
  }
}


// ── Single friend card ────────────────────────────────────────────────────────

class _FriendCard extends StatefulWidget {
  final _FriendData   friend;
  final bool          isFav;
  final LastFmService service;
  final VoidCallback  onToggleFav;

  const _FriendCard({
    required this.friend,
    required this.isFav,
    required this.service,
    required this.onToggleFav,
  });

  @override
  State<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<_FriendCard> {
  static const _ph = '2a96cbd8b46e442fc41c2b86b821562f';
  String _bgUrl   = '';
  bool   _pressed = false;

  _FriendData   get friend      => widget.friend;
  bool          get isFav       => widget.isFav;
  LastFmService get service     => widget.service;
  VoidCallback  get onToggleFav => widget.onToggleFav;

  bool get _hasAvatar =>
      friend.avatarUrl.isNotEmpty && !friend.avatarUrl.contains(_ph);

  @override
  void initState() {
    super.initState();
    // Prefetch now-playing artwork for the card background
    if (friend.isOnline && friend.nowPlayingTrack.isNotEmpty) {
      _resolveBg();
    }
  }

  Future<void> _resolveBg() async {
    final url = await ImageService.resolveTrack(
      friend.nowPlayingTrack,
      friend.nowPlayingArtist,
    );
    if (mounted && url.isNotEmpty) setState(() => _bgUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    final subtitle = friend.isOnline
        ? (friend.nowPlayingTrack.isNotEmpty ? friend.nowPlayingTrack : 'En écoute')
        : (friend.lastTrack.isNotEmpty       ? friend.lastTrack       : 'Hors ligne');

    final subtitleArtist = friend.isOnline
        ? friend.nowPlayingArtist
        : friend.lastArtist;

    return GestureDetector(
      onTap:       () => _openProfile(context),
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve:    Curves.easeOut,
        child: Container(
          width: 116,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: friend.isOnline
                ? scheme.primaryContainer.withValues(alpha: 0.45)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: friend.isOnline
                  ? scheme.primary.withValues(alpha: 0.28)
                  : scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(children: [

              // Blurred album art background (online only)
              if (_bgUrl.isNotEmpty)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.35,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                          sigmaX: 14, sigmaY: 14, tileMode: TileMode.clamp),
                      child: Image.network(
                        _bgUrl,
                        fit: BoxFit.cover,
                        width:  double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

              // Subtle tint so text stays readable over blurred art
              if (friend.isOnline)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end:   Alignment.bottomCenter,
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.25),
                          scheme.primaryContainer.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),

              // Card content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Avatar + online/offline status dot
                    SizedBox(
                      width: 60, height: 60,
                      child: Stack(children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: scheme.primary.withValues(alpha: 0.2),
                          backgroundImage: _hasAvatar ? NetworkImage(friend.avatarUrl) : null,
                          child: _hasAvatar
                              ? null
                              : Text(
                                  friend.username.isNotEmpty
                                      ? friend.username[0].toUpperCase()
                                      : '?',
                                  style: text.titleMedium?.copyWith(
                                      color: scheme.primary, fontWeight: FontWeight.w800),
                                ),
                        ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              color:  friend.isOnline ? Colors.green : scheme.outline,
                              shape:  BoxShape.circle,
                              border: Border.all(color: scheme.surface, width: 2),
                            ),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 6),

                    // Username
                    Text(
                      friend.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        shadows: friend.isOnline
                            ? [const Shadow(color: Colors.black26, blurRadius: 4)]
                            : null,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Track or status line
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: text.labelSmall?.copyWith(
                            color: friend.isOnline
                                ? Colors.green.shade700
                                : scheme.onSurfaceVariant,
                            fontWeight: friend.isOnline ? FontWeight.w600 : FontWeight.normal,
                            shadows: friend.isOnline
                                ? [const Shadow(color: Colors.black26, blurRadius: 3)]
                                : null,
                          ),
                        ),
                      ),
                    ]),

                    // Artist name (second line)
                    if (subtitleArtist.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitleArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9,
                          shadows: friend.isOnline
                              ? [const Shadow(color: Colors.black26, blurRadius: 3)]
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            ]),
          ),
        ),
      ),
    );
  }

  // Open the full profile sheet — same widget used in Search for consistency
  void _openProfile(BuildContext context) {
    showProfileSheet(
      context,
      friend.username,
      service,
      isFav:       isFav,
      onToggleFav: onToggleFav,
    );
  }
}


// ── Skeleton placeholder while friends load ───────────────────────────────────

class _FriendCardSkeleton extends StatelessWidget {
  final ColorScheme scheme;
  const _FriendCardSkeleton({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: scheme.outline.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 10, width: 60,
            decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 5),
        Container(height: 8, width: 80,
            decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4))),
      ]),
    );
  }
}


// ── Fallback gradient header ──────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final ColorScheme scheme;
  const _GradientHeader({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary, scheme.tertiary],
        ),
      ),
    );
  }
}


// ── Header image with optional blur ──────────────────────────────────────────

class _BlurredHeaderImage extends StatelessWidget {
  final String      url;
  final double      blur;
  final ColorScheme scheme;

  const _BlurredHeaderImage({
    super.key,
    required this.url,
    required this.blur,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => _GradientHeader(scheme: scheme),
    );
    if (blur > 0.5) {
      img = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp),
        child: img,
      );
    }
    return img;
  }
}


// ── Dashboard loading skeleton ────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  final ColorScheme scheme;
  const _DashboardSkeleton({required this.scheme});

  Widget _bone({double w = double.infinity, double h = 14, double r = 10}) =>
      Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 230,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.55),
                    scheme.secondaryContainer.withValues(alpha: 0.45),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bone(w: 120, h: 16, r: 8),
                            const SizedBox(height: 6),
                            _bone(w: 80,  h: 11, r: 6),
                            const SizedBox(height: 6),
                            _bone(w: 100, h: 10, r: 6),
                          ],
                        )),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SkeletonCard(scheme: scheme, height: 80),
              const SizedBox(height: 14),
              Row(children: [
                _bone(w: 20, h: 20, r: 10),
                const SizedBox(width: 8),
                _bone(w: 90, h: 14, r: 7),
              ]),
              const SizedBox(height: 10),
              _SkeletonCard(scheme: scheme, height: 110,
                  color: scheme.primaryContainer.withValues(alpha: 0.35)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _SkeletonCard(scheme: scheme, height: 90)),
                const SizedBox(width: 10),
                Expanded(child: _SkeletonCard(scheme: scheme, height: 90)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _SkeletonCard(scheme: scheme, height: 90)),
                const SizedBox(width: 10),
                Expanded(child: _SkeletonCard(scheme: scheme, height: 90)),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                _bone(w: 20, h: 20, r: 10),
                const SizedBox(width: 8),
                _bone(w: 70, h: 14, r: 7),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 152,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  padding: EdgeInsets.zero,
                  itemBuilder: (_, _) => _FriendCardSkeleton(scheme: scheme),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                _bone(w: 20, h: 20, r: 10),
                const SizedBox(width: 8),
                _bone(w: 110, h: 14, r: 7),
              ]),
              const SizedBox(height: 8),
              ...List.generate(3, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  const SizedBox(width: 28),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bone(w: 140, h: 13, r: 6),
                      const SizedBox(height: 5),
                      _bone(w: 80,  h: 10, r: 5),
                    ],
                  )),
                ]),
              )),
            ]),
          ),
        ),
      ]),
    );
  }
}


// ── Generic skeleton card ─────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final ColorScheme scheme;
  final double      height;
  final Color?      color;
  const _SkeletonCard({required this.scheme, required this.height, this.color});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: color ?? scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
    ),
  );
}


// ── Casino-style rolling number ───────────────────────────────────────────────
// Counts from 0 to [target] once when first shown.
// Use key: ValueKey(target) at call sites so it replays after a refresh.

class _RollingNumber extends StatefulWidget {
  final int        target;
  final TextStyle? style;
  final String     prefix;
  final String     suffix;
  final Duration   duration;
  final bool       fullFormat; // true = _fmtFull, false = _fmt

  const _RollingNumber({
    super.key,
    required this.target,
    this.style,
    this.prefix     = '',
    this.suffix     = '',
    this.duration   = const Duration(milliseconds: 1100),
    this.fullFormat = false,
  });

  @override
  State<_RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<_RollingNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    // Ease out so it slows down at the end — slot machine feel
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final current   = (_anim.value * widget.target).round();
        final formatted = widget.fullFormat ? _fmtFull(current) : _fmt(current);
        return Text(
          '${widget.prefix}$formatted${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}


// ── Number formatters ─────────────────────────────────────────────────────────

// Full number with narrow no-break space as thousands separator
String _fmtFull(int n) {
  final s   = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
    buf.write(s[i]);
  }
  return buf.toString();
}


// ── Full-width hero stat card (total + avg + weekly + active days) ────────────

class _HeroStatCard extends StatelessWidget {
  final int    total, avg, days, weekly;
  final String regStr;

  const _HeroStatCard({
    required this.total,
    required this.avg,
    required this.days,
    required this.weekly,
    required this.regStr,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: _cardBorder(scheme, alpha: 0.25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Total scrobbles with rolling animation
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('🎯', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            _RollingNumber(
              key:        ValueKey(total),
              target:     total,
              fullFormat: true,
              duration:   const Duration(milliseconds: 1300),
              style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.onPrimaryContainer,
                  height: 1),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(L.dashScrobbles,
                  style: text.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 14),
          // Sub-metrics row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniMetric('⚡', L.dashScrobblesPerDay, scheme.onPrimaryContainer,
                    rawInt: avg, prefix: '~'),
                _vDivider(scheme.onPrimaryContainer),
                _MiniMetric('📅', L.dashPerWeek, scheme.onPrimaryContainer,
                    rawInt: weekly, prefix: '~'),
                _vDivider(scheme.onPrimaryContainer),
                _MiniMetric('🗓️', L.dashDaysActive, scheme.onPrimaryContainer,
                    rawInt: days, suffix: ' j'),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _vDivider(Color c) =>
      Container(width: 1, height: 32, color: c.withValues(alpha: 0.15));
}


// ── Small metric item inside the hero card ────────────────────────────────────

class _MiniMetric extends StatelessWidget {
  final String  emoji, label;
  final Color   color;
  // When set, the value rolls up from 0. Otherwise [staticValue] is shown as-is.
  final int?    rawInt;
  final String  prefix;
  final String  suffix;
  final String? staticValue;

  const _MiniMetric(
    this.emoji,
    this.label,
    this.color, {
    this.rawInt,
    this.prefix      = '',
    this.suffix      = '',
    this.staticValue,
  });

  @override
  Widget build(BuildContext context) {
    final text       = Theme.of(context).textTheme;
    final valueStyle = text.bodyMedium?.copyWith(
        fontWeight: FontWeight.w800, color: color);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 2),
      if (rawInt != null)
        _RollingNumber(
          key:      ValueKey('mini_${rawInt}_$prefix$suffix'),
          target:   rawInt!,
          prefix:   prefix,
          suffix:   suffix,
          duration: const Duration(milliseconds: 1000),
          style:    valueStyle,
        )
      else
        Text(staticValue ?? '—', style: valueStyle),
      const SizedBox(height: 1),
      Text(label,
          style: text.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.65), fontSize: 9)),
    ]);
  }
}


// ── 2-column grid for stat cards ──────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  final List<Widget> children;
  const _StatGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final pairs = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final hasRight = i + 1 < children.length;
      pairs.add(Row(children: [
        Expanded(child: children[i]),
        const SizedBox(width: 10),
        Expanded(child: hasRight ? children[i + 1] : const SizedBox()),
      ]));
      if (i + 2 < children.length) pairs.add(const SizedBox(height: 10));
    }
    return Column(children: pairs);
  }
}


// ── Secondary stat card ───────────────────────────────────────────────────────

class _DashStatCard extends StatelessWidget {
  final String  emoji, value, label;
  final String? sub;
  // When set, the value rolls up from 0 instead of appearing instantly
  final int?    rawInt;
  final String  rollPrefix;
  final String  rollSuffix;

  const _DashStatCard({
    required this.emoji,
    required this.value,
    required this.label,
    this.sub,
    this.rawInt,
    this.rollPrefix = '',
    this.rollSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final scheme     = Theme.of(context).colorScheme;
    final text       = Theme.of(context).textTheme;
    final valueStyle = text.bodyLarge?.copyWith(
        fontWeight: FontWeight.w800, color: scheme.onSurface);

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _cardBorder(scheme),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          // Roll up from 0 if rawInt is given, otherwise cross-fade on change
          if (rawInt != null)
            _RollingNumber(
              key:      ValueKey('dash_${rawInt}_$rollPrefix$rollSuffix'),
              target:   rawInt!,
              prefix:   rollPrefix,
              suffix:   rollSuffix,
              duration: const Duration(milliseconds: 1000),
              style:    valueStyle,
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
              child: Text(
                value,
                key: ValueKey(value),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
          Text(label, style: text.bodySmall?.copyWith(
              color: scheme.primary, fontWeight: FontWeight.w600)),
          if (sub != null)
            Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}


// ── Now playing card ──────────────────────────────────────────────────────────

class _NowPlayingCard extends StatelessWidget {
  final Map<String, dynamic> track;
  const _NowPlayingCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final title  = (track['name']             ?? '').toString();
    final artist = (track['artist']?['#text'] ?? '').toString();
    final rawUrl = _extractImage(track['image']);

    return Card(
      elevation: 0,
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _cardBorder(scheme),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          _SmartImage(
            size: 52, borderRadius: 10, initialUrl: rawUrl,
            resolver: () => ImageService.resolveTrack(title, artist,
                lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Animated pulsing dot — signals live playback
              _PulsingDot(color: scheme.secondary, size: 7),
              const SizedBox(width: 6),
              Text(L.commonNowPlayingBadge, style: text.labelSmall?.copyWith(
                  color: scheme.secondary, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            ]),
            const SizedBox(height: 2),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer.withValues(alpha: 0.7))),
          ])),
        ]),
      ),
    );
  }
}


// ── Refresh button with rotation animation ────────────────────────────────────

class _SyncRefreshButton extends StatefulWidget {
  final bool          isSyncing;
  final VoidCallback? onPressed;
  final String        tooltip;

  const _SyncRefreshButton({
    required this.isSyncing,
    required this.tooltip,
    this.onPressed,
  });

  @override
  State<_SyncRefreshButton> createState() => _SyncRefreshButtonState();
}

class _SyncRefreshButtonState extends State<_SyncRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isSyncing) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_SyncRefreshButton old) {
    super.didUpdateWidget(old);
    if (widget.isSyncing && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isSyncing && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.animateTo(0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: RotationTransition(
        turns: _ctrl,
        child: const Icon(Icons.refresh_rounded),
      ),
      onPressed: widget.onPressed,
      tooltip:   widget.tooltip,
    );
  }
}


// ── Sync progress chip next to the refresh button ────────────────────────────

class _SyncProgressChip extends StatelessWidget {
  final AllScrobblesProgress progress;
  const _SyncProgressChip({required this.progress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final label  = progress.shortLabel;
    final frac   = progress.fraction;

    return AnimatedOpacity(
      opacity:  1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: 26,
        constraints: const BoxConstraints(minWidth: 52, maxWidth: 96),
        decoration: BoxDecoration(
          color:        scheme.surfaceContainerHighest.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(13),
          border:       Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5), width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // Background progress bar
          if (frac > 0)
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: frac,
                alignment: Alignment.centerLeft,
                child: Container(color: scheme.primary.withValues(alpha: 0.15)),
              ),
            ),
          // Label on top
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                style: text.labelSmall?.copyWith(
                  color:      scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize:   10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}


// ── Apple Music-style ambient header animation ────────────────────────────────
// When music is playing and the setting is on, the header slowly breathes:
//   • scale: 1.0 → 1.08 over ~8 s, reversing smoothly
//   • shift: slight diagonal drift, out of phase with scale
//   • blur: forced to at least 18 so the motion looks soft

class _AmbientHeader extends StatefulWidget {
  final String      url;
  final ColorScheme scheme;
  const _AmbientHeader({super.key, required this.url, required this.scheme});

  @override
  State<_AmbientHeader> createState() => _AmbientHeaderState();
}

class _AmbientHeaderState extends State<_AmbientHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;
  late final Animation<double>   _dx;
  late final Animation<double>   _dy;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Slow breathing scale
    _scale = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // Slight diagonal drift with a different curve so it feels independent
    _dx = Tween<double>(begin: -8.0, end: 8.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
    _dy = Tween<double>(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double ambientBlur = 18.0;

    return ClipRect(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(_scale.value)
            ..translate(_dx.value, _dy.value),
          child: child,
        ),
        child: widget.url.isNotEmpty
            // Image available: blur + stretch to fill
            ? ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: ambientBlur,
                  sigmaY: ambientBlur,
                  tileMode: TileMode.mirror,
                ),
                child: Image.network(
                  widget.url,
                  fit: BoxFit.cover,
                  width:  double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      _GradientHeader(scheme: widget.scheme),
                ),
              )
            // No image: animate the gradient itself
            : _GradientHeader(scheme: widget.scheme),
      ),
    );
  }
}