// ignore_for_file: unused_import
part of 'home_screen.dart';


// ── Friend data model ─────────────────────────────────────────────────────────

class _FriendData {
  final String username;
  final String realName;
  final String avatarUrl;
  final bool   isOnline;
  final String nowPlayingTrack;
  final String nowPlayingArtist;
  final String lastTrack;
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
  ('artist_count',    '🎸', 'Artistes uniques',       'Unique artists'),
  ('track_count',     '🎼', 'Titres uniques',         'Unique tracks'),
  ('album_count',     '💽', 'Albums uniques',         'Unique albums'),
  ('scrobbles_week',  '📊', 'Scrobbles semaine',      'Scrobbles week'),
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
  int _thisWeekCount = 0; // scrobbles réels cette semaine
  int _lastWeekCount = 0; // scrobbles réels la semaine passée

  bool    _loading = true;
  String? _error;
  Timer?  _npTimer;
  Timer?  _topTimer;

  // Header settings
  String _headerSource          = 'nowplaying';
  String _headerImageUrl        = '';
  double _headerBlur            = 0.0;
  String _headerAnimation       = 'fade';
  String _headerCustomUrl       = '';
  String _headerFallbackUrl     = '';
  bool   _headerFallbackEnabled = false;
  String _fallbackType          = 'none';
  String _fallbackPeriod        = 'overall';
  String _headerPeriod          = 'overall';
  bool   _headerMusicAnim       = false;

  // Section visibility
  bool _showNowPlay  = true;
  bool _showStats    = true;
  bool _showArtists  = true;
  bool _showAlbums   = true;  // new
  bool _showTracks   = true;
  bool _showRecent   = true;  // new

  // Friends
  bool              _showFriends    = true;
  List<_FriendData> _friends        = [];
  Set<String>       _favFriends     = {};
  Set<String>       _favProfiles    = {};
  bool              _friendsLoading = false;

  @override
  void initState() {
    super.initState();
    _initWithCache();
    _npTimer  = Timer.periodic(const Duration(seconds: 10), (_) => _refreshLive());
    _topTimer = Timer.periodic(const Duration(minutes: 10), (_) => _refreshTopLists());
  }

  @override
  void dispose() {
    _npTimer?.cancel();
    _topTimer?.cancel();
    super.dispose();
  }

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
      _showAlbums            = p.getBool('ls_show_albums')              ?? true;
      _showTracks            = p.getBool('ls_show_tracks')              ?? true;
      _showRecent            = p.getBool('ls_show_recent')              ?? true;
      _showFriends           = p.getBool('ls_show_friends')             ?? true;
      final rawCards = p.getStringList('ls_stat_cards');
      _statCards   = rawCards != null && rawCards.isNotEmpty
          ? rawCards : List.from(_kDefaultStatCards);
      _favFriends  = Set<String>.from(p.getStringList('ls_fav_friends')  ?? []);
      _favProfiles = Set<String>.from(p.getStringList('ls_fav_profiles') ?? []);
    });
  }

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
        // Always fetch week top lists for the highlights strip
        widget.service.getTopArtists(period: '7day', limit: 3),
        widget.service.getTopTracks (period: '7day', limit: 3),
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
        _topArtistsWeek = res.length > 9 ? res[9] as List<dynamic> : [];
        _topTracksWeek  = res.length > 10 ? res[10] as List<dynamic> : [];
        if (res.length > 6 && (res[6] as List).isNotEmpty) _topArtistsWeek = res[6] as List<dynamic>;
        if (res.length > 7 && (res[7] as List).isNotEmpty) _topAlbumsWeek  = res[7] as List<dynamic>;
        if (res.length > 8 && (res[8] as List).isNotEmpty) _topTracksWeek  = res[8] as List<dynamic>;
        _loading = false;
      });

      if (_nowPlaying != null) _extractColor(_nowPlaying!);
      _resolveHeaderImage();
      _saveToCache(res);
      if (_showFriends) _loadFriends();
      _fetchWeekComparison();
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
      }
    }
  }

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
        setState(() => _nowPlaying = np);
        if (np != null) {
          _extractColor(np);
          DataCache.set(DataCache.keyNowPlaying(), np);
        } else if (useNowPlayingColorNotifier.value) {
          accentNotifier.value = nowPlayingFallbackColorNotifier.value;
        }
        _resolveHeaderImage();
      } else if (np != null) {
        DataCache.set(DataCache.keyNowPlaying(), np);
      }
    } catch (_) {}
    if (_showFriends && mounted) _loadFriends(silent: true);
  }

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

      bool changed = false;
      final newArtists = results[0] as List<dynamic>;
      final newTracks  = results[1] as List<dynamic>;
      if (newArtists.isNotEmpty && _topArtists.isNotEmpty) {
        if ((newArtists[0] as Map)['name'] != (_topArtists[0] as Map)['name']) changed = true;
      } else if (newArtists.length != _topArtists.length) {
        changed = true;
      }
      if (!changed) {
        if (newTracks.isNotEmpty && _topTracks.isNotEmpty) {
          if ((newTracks[0] as Map)['name'] != (_topTracks[0] as Map)['name']) changed = true;
        } else if (newTracks.length != _topTracks.length) {
          changed = true;
        }
      }

      if (changed) {
        setState(() {
          _topArtists    = newArtists;
          _topTracks     = newTracks;
          if (results.length > 2) _topArtistsWeek = results[2] as List<dynamic>;
          if (results.length > 3) _topTracksWeek  = results[3] as List<dynamic>;
        });
      }
      DataCache.set(DataCache.keyTopArtists('overall'), results[0]);
      DataCache.set(DataCache.keyTopTracks('overall'),  results[1]);
      if (results.length > 2 && (results[2] as List).isNotEmpty)
        DataCache.set(DataCache.keyTopArtists('7day'), results[2]);
      if (results.length > 3 && (results[3] as List).isNotEmpty)
        DataCache.set(DataCache.keyTopTracks('7day'),  results[3]);
    } catch (_) {}
  }

  // Compare les scrobbles de cette semaine vs la semaine passée via l'API
  Future<void> _fetchWeekComparison() async {
    try {
      final now         = DateTime.now();
      final tsNow       = (now.millisecondsSinceEpoch / 1000).round();
      final tsWeekAgo   = (now.subtract(const Duration(days: 7)).millisecondsSinceEpoch / 1000).round();
      final ts2WeeksAgo = (now.subtract(const Duration(days: 14)).millisecondsSinceEpoch / 1000).round();

      final results = await Future.wait([
        widget.service.getRecentTracks(limit: 1, from: tsWeekAgo,   to: tsNow),
        widget.service.getRecentTracks(limit: 1, from: ts2WeeksAgo, to: tsWeekAgo),
      ]);

      final thisW = int.tryParse((results[0]['@attr']?['total'] ?? '0').toString()) ?? 0;
      final lastW = int.tryParse((results[1]['@attr']?['total'] ?? '0').toString()) ?? 0;
      if (mounted) setState(() { _thisWeekCount = thisW; _lastWeekCount = lastW; });
    } catch (_) {}
  }

  // Retourne "+8%" ou "-10%" pour comparer deux valeurs
  String _weekDeltaStr(int current, int previous) {
    if (previous == 0) return '';
    final delta = ((current - previous) / previous * 100).round();
    return delta >= 0 ? '+$delta%' : '$delta%';
  }

  Future<void> _loadFriends({bool silent = false}) async {    if (!mounted) return;
    if (!silent) setState(() => _friendsLoading = true);
    try {
      final raw = await widget.service.getFriends(limit: 50, withRecentTrack: false);
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

      // Include starred profiles from Search not already in the list
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

      // Sort: online+fav first, then online, then fav, then alphabetical
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

  Future<void> _resolveHeaderImage() async {
    String url = '';
    switch (_headerSource) {
      case 'custom':
        url = _headerCustomUrl;
      case 'nowplaying':
        if (_nowPlaying != null) {
          url = await ImageService.resolveTrack(
            (_nowPlaying!['name'] ?? '').toString(),
            (_nowPlaying!['artist']?['#text'] ?? '').toString(),
          );
        }
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
          );
        }
      default:
        url = '';
    }
    if (mounted) setState(() => _headerImageUrl = url);
  }

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

  Future<void> _extractColor(Map<String, dynamic> track) async {
    if (!useNowPlayingColorNotifier.value) return;
    final url = _extractImage(track['image']);
    if (url.isEmpty || url.contains('2a96cbd8b46e442fc41c2b86b821562f')) {
      if (mounted) accentNotifier.value = nowPlayingFallbackColorNotifier.value;
      return;
    }
    try {
      final pal = await PaletteGenerator.fromImageProvider(
        NetworkImage(url), size: const Size(200, 200), maximumColorCount: 24);
      final c = pal.vibrantColor?.color
             ?? pal.lightVibrantColor?.color
             ?? pal.darkVibrantColor?.color
             ?? pal.lightMutedColor?.color
             ?? pal.mutedColor?.color
             ?? pal.dominantColor?.color;
      if (!mounted) return;
      if (c != null) {
        accentNotifier.value = seedColorForScheme(c);
      } else {
        accentNotifier.value = nowPlayingFallbackColorNotifier.value;
      }
    } catch (_) {
      if (mounted) accentNotifier.value = nowPlayingFallbackColorNotifier.value;
    }
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
      // ── Nouvelles cartes ──────────────────────────────────────────────
      case 'artist_count':
        final n = int.tryParse((_userInfo?['artist_count'] ?? '0').toString()) ?? 0;
        return _DashStatCard(
          emoji: '🎸', rawInt: n > 0 ? n : null,
          value: n > 0 ? _fmtFull(n) : '—',
          label: localeNotifier.value == 'en' ? 'Unique artists' : 'Artistes uniques',
          sub: null,
        );
      case 'track_count':
        final n = int.tryParse((_userInfo?['track_count'] ?? '0').toString()) ?? 0;
        return _DashStatCard(
          emoji: '🎼', rawInt: n > 0 ? n : null,
          value: n > 0 ? _fmtFull(n) : '—',
          label: localeNotifier.value == 'en' ? 'Unique tracks' : 'Titres uniques',
          sub: null,
        );
      case 'album_count':
        final n = int.tryParse((_userInfo?['album_count'] ?? '0').toString()) ?? 0;
        return _DashStatCard(
          emoji: '💽', rawInt: n > 0 ? n : null,
          value: n > 0 ? _fmtFull(n) : '—',
          label: localeNotifier.value == 'en' ? 'Unique albums' : 'Albums uniques',
          sub: null,
        );
      case 'scrobbles_week':
        // Réel si chargé, sinon estimation lifetime × 7
        final val = _thisWeekCount > 0 ? _thisWeekCount : weekly;
        return _DashStatCard(
          emoji: '📊', rawInt: val,
          value: _thisWeekCount > 0 ? _fmtFull(_thisWeekCount) : '~${_fmt(weekly)}',
          label: localeNotifier.value == 'en' ? 'This week' : 'Cette semaine',
          sub: _thisWeekCount > 0 && _lastWeekCount > 0
              ? _weekDeltaStr(_thisWeekCount, _lastWeekCount)
              : null,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) return _DashboardSkeleton(scheme: scheme);
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

    final hasWeekData = _topArtistsWeek.isNotEmpty || _topTracksWeek.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(slivers: [

        // ── Profile app bar ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 230,
          pinned: true,
          stretch: true,
          actions: [
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
                // Background: ambient / blurred image / gradient
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

                // Bottom gradient for text readability
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

                // Profile info overlay
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Now playing ─────────────────────────────────────────────
              if (_showNowPlay && _nowPlaying != null) ...[
                _NowPlayingCard(track: _nowPlaying!),
                const SizedBox(height: 12),
              ],

              // ── This week highlights strip ───────────────────────────────
              if (hasWeekData) ...[
                _WeekHighlightStrip(
                  topArtist:     _topArtistsWeek.isNotEmpty ? _topArtistsWeek[0] as Map : null,
                  topTrack:      _topTracksWeek.isNotEmpty  ? _topTracksWeek[0]  as Map : null,
                  weeklyEst:     weekly,
                  thisWeekCount: _thisWeekCount,
                  lastWeekCount: _lastWeekCount,
                  service:       widget.service,
                ),
                const SizedBox(height: 20),
              ],

              // ── Stats ────────────────────────────────────────────────────
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

              // ── Recent plays ─────────────────────────────────────────────
              if (_showRecent && _recentTracks.isNotEmpty) ...[
                _SectionHeader(
                  title: localeNotifier.value == 'en' ? 'Recent plays' : 'Écoutes récentes',
                  icon: Icons.history_rounded,
                ),
                const SizedBox(height: 10),
                _RecentTracksList(
                  tracks:  _recentTracks.take(5).toList(),
                  service: widget.service,
                ),
                const SizedBox(height: 20),
              ],

              // ── Friends ──────────────────────────────────────────────────
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

              // ── Top artists carousel ─────────────────────────────────────
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

              // ── Top albums carousel (new) ────────────────────────────────
              if (_showAlbums && _topAlbums.isNotEmpty) ...[
                _SectionHeader(
                  title: localeNotifier.value == 'en' ? 'Top Albums' : 'Top Albums',
                  icon: Icons.album_rounded,
                ),
                const SizedBox(height: 10),
                _HorizontalCarousel(
                  items:   _topAlbums.take(10).toList(),
                  type:    'albums',
                  service: widget.service,
                ),
                const SizedBox(height: 20),
              ],

              // ── Top tracks carousel ──────────────────────────────────────
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
  final String         type;    // 'artists' | 'tracks' | 'albums'
  final LastFmService  service;

  const _HorizontalCarousel({
    required this.items,
    required this.type,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final cardW = (MediaQuery.of(context).size.width * 0.52).clamp(160.0, 220.0);
    final cardH = cardW * 1.10;

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


// ── Single carousel card ──────────────────────────────────────────────────────

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

              _CarouselImage(
                initialUrl: widget.initialUrl,
                resolver:   () => widget.imageFuture,
                width:      widget.width,
                height:     widget.height,
              ),

              // Gradient for text readability
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


// ── Friends section ───────────────────────────────────────────────────────────

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

              // Blurred album art background (online friends)
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

              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Avatar + online dot
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


// ── Friend card skeleton ──────────────────────────────────────────────────────

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
              const SizedBox(height: 12),
              _SkeletonCard(scheme: scheme, height: 64,
                  color: scheme.secondaryContainer.withValues(alpha: 0.4)),
              const SizedBox(height: 20),
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
                _bone(w: 110, h: 14, r: 7),
              ]),
              const SizedBox(height: 12),
              ...List.generate(3, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
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

class _RollingNumber extends StatefulWidget {
  final int        target;
  final TextStyle? style;
  final String     prefix;
  final String     suffix;
  final Duration   duration;
  final bool       fullFormat;

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

String _fmtFull(int n) {
  final s   = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
    buf.write(s[i]);
  }
  return buf.toString();
}


// ── Hero stat card — total scrobbles + sub-metrics ───────────────────────────
// Cleaner layout: big rolling number on the left, 3 mini metrics on the right.

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

    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Label row
          Row(children: [
            Icon(Icons.equalizer_rounded,
                size: 15, color: scheme.onPrimaryContainer.withValues(alpha: 0.6)),
            const SizedBox(width: 5),
            Text(
              L.dashScrobbles.toUpperCase(),
              style: text.labelSmall?.copyWith(
                color:         scheme.onPrimaryContainer.withValues(alpha: 0.6),
                fontWeight:    FontWeight.w700,
                letterSpacing: 1.2,
                fontSize:      10,
              ),
            ),
          ]),

          const SizedBox(height: 8),

          // Big rolling total
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

          const SizedBox(height: 16),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.1),
          ),

          const SizedBox(height: 14),

          // Sub-metrics row — no background container, just even columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniMetric(
                icon: Icons.bolt_rounded,
                label: L.dashScrobblesPerDay,
                color: scheme.onPrimaryContainer,
                rawInt: avg, prefix: '~',
              ),
              _VertDivider(color: scheme.onPrimaryContainer),
              _MiniMetric(
                icon: Icons.calendar_view_week_rounded,
                label: L.dashPerWeek,
                color: scheme.onPrimaryContainer,
                rawInt: weekly, prefix: '~',
              ),
              _VertDivider(color: scheme.onPrimaryContainer),
              _MiniMetric(
                icon: Icons.today_rounded,
                label: L.dashDaysActive,
                color: scheme.onPrimaryContainer,
                rawInt: days,
                suffix: localeNotifier.value == 'en' ? ' d' : ' j',
              ),
            ],
          ),

          // Member since — subtle line at the bottom
          if (regStr.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.calendar_month_outlined,
                  size: 12, color: scheme.onPrimaryContainer.withValues(alpha: 0.5)),
              const SizedBox(width: 5),
              Text(
                L.memberSince(regStr),
                style: text.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ]),
          ],

        ]),
      ),
    );
  }
}


// ── Thin vertical divider for metric rows ─────────────────────────────────────

class _VertDivider extends StatelessWidget {
  final Color color;
  const _VertDivider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: color.withValues(alpha: 0.15));
}


// ── Small metric item inside the hero card ────────────────────────────────────

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final int?     rawInt;
  final String   prefix;
  final String   suffix;
  final String?  staticValue;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.color,
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
      Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
      const SizedBox(height: 3),
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
      const SizedBox(height: 2),
      Text(label,
          style: text.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.6), fontSize: 9)),
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
// Larger, cleaner layout with album name if available.

class _NowPlayingCard extends StatelessWidget {
  final Map<String, dynamic> track;
  const _NowPlayingCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final title  = (track['name']             ?? '').toString();
    final artist = (track['artist']?['#text'] ?? '').toString();
    final album  = (track['album']?['#text']  ?? '').toString();
    final rawUrl = _extractImage(track['image']);

    return Container(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [

          // Artwork — slightly larger
          _SmartImage(
            size: 64,
            borderRadius: 12,
            initialUrl: rawUrl,
            resolver: () => ImageService.resolveTrack(title, artist,
                lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null),
          ),

          const SizedBox(width: 14),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Live badge
              Row(children: [
                _PulsingDot(color: scheme.secondary, size: 7),
                const SizedBox(width: 6),
                Text(
                  L.commonNowPlayingBadge,
                  style: text.labelSmall?.copyWith(
                    color:         scheme.secondary,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ]),

              const SizedBox(height: 5),

              // Track title
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSecondaryContainer,
                ),
              ),

              // Artist
              Text(
                artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSecondaryContainer.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Album (if present, shown small)
              if (album.isNotEmpty && album != title) ...[
                const SizedBox(height: 2),
                Text(
                  album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

            ],
          )),
        ]),
      ),
    );
  }
}


// ── This week highlights strip ────────────────────────────────────────────────
// Compact card: top artist this week | top track this week | estimated weekly plays

class _WeekHighlightStrip extends StatelessWidget {
  final Map?          topArtist;
  final Map?          topTrack;
  final int           weeklyEst;
  final int           thisWeekCount; // scrobbles réels cette semaine (0 = pas encore chargé)
  final int           lastWeekCount; // scrobbles réels la semaine passée
  final LastFmService service;

  const _WeekHighlightStrip({
    required this.topArtist,
    required this.topTrack,
    required this.weeklyEst,
    required this.service,
    this.thisWeekCount = 0,
    this.lastWeekCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final isEn   = localeNotifier.value == 'en';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header label
          Row(children: [
            Icon(Icons.trending_up_rounded,
                size: 13, color: scheme.primary),
            const SizedBox(width: 5),
            Text(
              (isEn ? 'THIS WEEK' : 'CETTE SEMAINE'),
              style: text.labelSmall?.copyWith(
                color:         scheme.primary,
                fontWeight:    FontWeight.w700,
                letterSpacing: 1.1,
                fontSize:      10,
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // Three tiles side by side
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Top artist
                Expanded(child: _WeekTile(
                  icon:  Icons.mic_rounded,
                  label: isEn ? 'Top artist' : 'Artiste top',
                  value: topArtist != null
                      ? (topArtist!['name'] ?? '—').toString()
                      : '—',
                  plays: topArtist != null
                      ? int.tryParse((topArtist!['playcount'] ?? '0').toString()) ?? 0
                      : null,
                )),

                Container(
                  width: 1, margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),

                // Top track
                Expanded(child: _WeekTile(
                  icon:  Icons.music_note_rounded,
                  label: isEn ? 'Top track' : 'Titre top',
                  value: topTrack != null
                      ? (topTrack!['name'] ?? '—').toString()
                      : '—',
                  plays: topTrack != null
                      ? int.tryParse((topTrack!['playcount'] ?? '0').toString()) ?? 0
                      : null,
                )),

                Container(
                  width: 1, margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),

                // Scrobbles réels cette semaine (ou estimation si pas encore chargé)
                Expanded(child: _WeekTile(
                  icon:    Icons.headphones_rounded,
                  label:   isEn ? 'This week' : 'Cette semaine',
                  value:   thisWeekCount > 0
                      ? _fmt(thisWeekCount)
                      : '~${_fmt(weeklyEst)}',
                  plays:   null,
                  percent: thisWeekCount > 0 && lastWeekCount > 0
                      ? (thisWeekCount - lastWeekCount) / lastWeekCount * 100
                      : null,
                )),

              ],
            ),
          ),
        ]),
      ),
    );
  }
}


// ── Single tile in the week strip ─────────────────────────────────────────────

class _WeekTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final int?     plays;
  final double?  percent; // % vs semaine précédente, null si non disponible

  const _WeekTile({
    required this.icon,
    required this.label,
    required this.value,
    this.plays,
    this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(icon, size: 12, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color:    scheme.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            height: 1.2,
          ),
        ),
        if (plays != null && plays! > 0) ...[
          const SizedBox(height: 2),
          Text(
            '${_fmt(plays!)} ${L.commonPlays}',
            style: text.labelSmall?.copyWith(
              color:    scheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
        // Pourcentage vs semaine passée avec icône tendance
        if (percent != null) ...[
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              percent! >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size:  10,
              color: percent! >= 0 ? Colors.green.shade400 : Colors.red.shade400,
            ),
            const SizedBox(width: 2),
            Text(
              '${percent! >= 0 ? '+' : ''}${percent!.round()}%',
              style: text.labelSmall?.copyWith(
                color:      percent! >= 0 ? Colors.green.shade400 : Colors.red.shade400,
                fontSize:   9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ],
      ],
    );
  }
}


// ── Recent plays compact list ─────────────────────────────────────────────────

class _RecentTracksList extends StatelessWidget {
  final List<dynamic>  tracks;
  final LastFmService  service;

  const _RecentTracksList({
    required this.tracks,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: tracks.asMap().entries.map((e) {
          return _RecentTrackRow(
            track:   e.value as Map<String, dynamic>,
            isLast:  e.key == tracks.length - 1,
            service: service,
          );
        }).toList(),
      ),
    );
  }
}


// ── Single recent track row ───────────────────────────────────────────────────

class _RecentTrackRow extends StatefulWidget {
  final Map<String, dynamic> track;
  final bool                 isLast;
  final LastFmService        service;

  const _RecentTrackRow({
    required this.track,
    required this.isLast,
    required this.service,
  });

  @override
  State<_RecentTrackRow> createState() => _RecentTrackRowState();
}

class _RecentTrackRowState extends State<_RecentTrackRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final text    = Theme.of(context).textTheme;
    final track   = widget.track;
    final title   = (track['name']             ?? '').toString();
    final artist  = (track['artist']?['#text'] ?? '').toString();
    final album   = (track['album']?['#text']  ?? '').toString();
    final rawUrl  = _extractImage(track['image']);
    final dateStr = _fmtTrackDateLocal(track);

    return GestureDetector(
      onTap: () {
        // Les tracks récents ont artist['#text'], la detail sheet attend artist['name']
        final normalized = Map<String, dynamic>.from(track);
        final ra = track['artist'];
        if (ra is Map && ra['name'] == null) {
          normalized['artist'] = {
            ...Map<String, dynamic>.from(ra as Map<String, dynamic>),
            'name': ra['#text'] ?? '',
          };
        }
        showDetailSheet(context, normalized, 'tracks', widget.service);
      },
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed
            ? scheme.onSurface.withValues(alpha: 0.05)
            : Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [

                // Artwork
                _SmartImage(
                  size: 44,
                  borderRadius: 8,
                  initialUrl: rawUrl,
                  resolver: () => ImageService.resolveTrack(title, artist,
                      lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null),
                ),

                const SizedBox(width: 12),

                // Track + artist
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant),
                    ),
                  ],
                )),

                const SizedBox(width: 8),

                // Time
                Text(
                  dateStr,
                  style: text.labelSmall?.copyWith(
                    color:    scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),

              ]),
            ),
            if (!widget.isLast)
              Divider(
                height: 1, thickness: 1, indent: 70, endIndent: 0,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        ),
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


// ── Sync progress chip ────────────────────────────────────────────────────────

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
          if (frac > 0)
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: frac,
                alignment: Alignment.centerLeft,
                child: Container(color: scheme.primary.withValues(alpha: 0.15)),
              ),
            ),
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


// ── Ambient header (Apple Music-style breathing animation) ────────────────────

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

    _scale = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

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
            : _GradientHeader(scheme: widget.scheme),
      ),
    );
  }
}