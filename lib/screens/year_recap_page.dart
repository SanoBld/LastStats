part of 'home_screen.dart';

// Average track length used for the "hours of music" estimate (Last.fm does
// not give durations in scrobble history), clearly labelled as an estimate.
const double _kYrAvgTrackMinutes = 3.5;

// Accent-tinted soft text colour (instead of a neutral grey), works in light and dark
Color _yrSoft(ColorScheme s) => Color.lerp(s.onPrimaryContainer, s.primary, 0.55)!;

// True while a slide is rendered for sharing: animations jump to their final state
// TEST ONLY: set to true to also open the current (unfinished) year.
const bool _kYearRecapAllowCurrent = false;
bool _yrInstant = false;

class _YrRanked {
  final String name;
  final String artist; // empty for artists
  final int count;
  const _YrRanked(this.name, this.artist, this.count);
}

class _YrData {
  int total = 0;
  int activeDays = 0;
  int daysInRange = 0;
  int longestStreak = 0;
  String? busiestDay; // YYYY-MM-DD
  int busiestDayCount = 0;
  List<int> monthly = List.filled(12, 0);
  List<int> hourly = List.filled(24, 0);
  List<int> weekday = List.filled(7, 0); // Mon..Sun
  List<_YrRanked> artists = [];
  List<_YrRanked> tracks = [];
  List<_YrRanked> albums = [];
  int uniqueArtists = 0;
  int uniqueTracks = 0;
  int? newArtists; // null = unknown (older years not cached)
  List<String> topArtistNames = []; // top 50, lower-case, for taste matching
  List<_YrRanked> artistsWide = []; // top 20, for the share donut
  Map<String, int> calendar = {}; // YYYY-MM-DD -> scrobbles
  Map<String, int> cumulative = {}; // YYYY-MM -> running total
  Map<int, int> hourlyMap = {};
  Map<int, int> weekdayMap = {}; // 1 (Mon) .. 7 (Sun)
  List<_YrRanked> tracksAll = [];
  _YrRanked? busiestTrack, peakTrack, streakTrack, randomTrack, dayRecord;
  String dayRecordDate = '';
}

// What to play on a slide (type: tracks / artists / albums).
class _PvReq {
  final String type, name, artist;
  const _PvReq(this.type, this.name, this.artist);
  _PvReq.of(String type, _YrRanked r) : this(type, r.name, r.artist);
}

class _PvRes {
  final String url, title;
  const _PvRes(this.url, this.title);
}

class _YrFriend {
  final String name;
  final int total;
  final String image;
  const _YrFriend(this.name, this.total, [this.image = '']);
}

class _YrFriends {
  final List<_YrFriend> board; // friends with scrobbles this year
  final String? twin;           // friend with the most artists in common
  final List<String> shared;    // shared artists (display names, my rank order)
  final int sharedCount;
  final Map<String, String> images; // friend name -> avatar url
  final String myImage;
  const _YrFriends(this.board, this.twin, this.shared, this.sharedCount, this.images, this.myImage);
}

class YearRecapPage extends StatefulWidget {
  final LastFmService service;
  final String username;
  const YearRecapPage({super.key, required this.service, required this.username});

  @override
  State<YearRecapPage> createState() => _YearRecapPageState();
}

class _YearRecapPageState extends State<YearRecapPage> {
  // Only finished years are available (the current year is not over yet).
  late int _year = _kYearRecapAllowCurrent ? DateTime.now().year : DateTime.now().year - 1;
  _YrData? _data;
  bool _loading = true;
  bool _error = false;
  double _progress = 0;
  int _slide = 0;
  final PageController _pages = PageController();
  final GlobalKey _shareKey = GlobalKey();
  // Hidden 9:16 frame used for single-slide sharing
  final GlobalKey _frameKey = GlobalKey();
  final ValueNotifier<int?> _frameIdx = ValueNotifier(null);
  bool _sharing = false;
  // Profile picture url used as the share card background ('' = none)
  final ValueNotifier<Uint8List?> _photo = ValueNotifier(null);
  bool _photoDark = false; // true = dark picture, so the header text is white
  final ValueNotifier<bool> _profileOn = ValueNotifier(true);
  final ValueNotifier<bool> _sharingN = ValueNotifier(false);
  _YrFriends? _friendsData;
  int _token = 0;

  // ── Deezer preview (auto-play on top slides, with fade-in) ──
  final AudioPlayer _audio = AudioPlayer();
  final Map<String, _PvRes?> _previewCache = {};
  Timer? _fadeTimer;
  int _playToken = 0;

  List<_PvReq?> _pvList = const [];
  _YrRanked? _twinTrack;
  final ValueNotifier<bool> _playing = ValueNotifier(false);
  final ValueNotifier<String> _nowTitle = ValueNotifier('');
  bool _userPaused = false;

  // Temporary look for the share image: restored when the recap is closed
  Map<String, Object?>? _styleBackup;
  void _backupStyle() {
    _styleBackup ??= {
      'accent': accentNotifier.value, 'dyn': useDynamicColorNotifier.value, 'np': useNowPlayingColorNotifier.value,
      'art': artworkColorThemeNotifier.value, 'dn': useDayNightAccentNotifier.value,
      'mode': themeModeNotifier.value, 'font': appFontNotifier.value,
      'harm': colorHarmonyNotifier.value, 'shape': imageShapeNotifier.value,
    };
  }

  void _restoreStyle() {
    final b = _styleBackup;
    if (b == null) return;
    _styleBackup = null;
    accentNotifier.value = b['accent'] as Color;
    useDynamicColorNotifier.value = b['dyn'] as bool;
    useNowPlayingColorNotifier.value = b['np'] as bool;
    artworkColorThemeNotifier.value = b['art'] as bool;
    useDayNightAccentNotifier.value = b['dn'] as bool;
    themeModeNotifier.value = b['mode'] as ThemeMode;
    appFontNotifier.value = b['font'] as String;
    colorHarmonyNotifier.value = b['harm'] as String;
    imageShapeNotifier.value = b['shape'] as String;
  }

  void _openStyle() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      barrierColor: Colors.black26,
      builder: (ctx) {
        final sc = Theme.of(ctx).colorScheme;
        const colors = [0xFF7C3AED, 0xFF6366F1, 0xFF1D4ED8, 0xFF0EA5E9, 0xFF14B8A6, 0xFF16A34A, 0xFFEAB308, 0xFFF97316, 0xFFE11D48, 0xFFEC4899];
        const fonts = [
          ('', 'Auto'), ('Inter', 'Inter'), ('SpaceGrotesk', 'Space Grotesk'), ('GoogleSansFlex', 'Google Sans Flex'),
          ('OpenSans', 'Open Sans'), ('Roboto', 'Roboto'), ('RobotoSlab', 'Roboto Slab'), ('DancingScript', 'Dancing Script'),
          ('Spirax', 'Spirax'), ('Mynerve', 'Mynerve'), ('SingleDay', 'Single Day'), ('BetaniaPatmosGDL', 'Betania Patmos GDL'),
          ('Ndot57', 'Nothing Ndot 57'), ('Ndot55', 'Nothing Ndot 55'), ('Ndot77', 'Nothing Ndot 77'), ('NType82', 'Nothing NType 82'),
        ];
        const harmonies = ['mono', 'tinted', 'classic', 'vivid', 'soft'];
        Widget title(String t) => Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 10),
              child: Text(t, style: TextStyle(color: sc.onSurface, fontSize: 14, fontWeight: FontWeight.w800)),
            );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              Text(tx('yr_style'), style: TextStyle(color: sc.onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ValueListenableBuilder<Color>(
                valueListenable: accentNotifier,
                builder: (_, cur, _) => Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final c in colors)
                    GestureDetector(
                      onTap: () {
                        _backupStyle();
                        useDynamicColorNotifier.value = false;
                        useNowPlayingColorNotifier.value = false;
                        artworkColorThemeNotifier.value = false;
                        useDayNightAccentNotifier.value = false;
                        accentNotifier.value = Color(c);
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Color(c), shape: BoxShape.circle,
                          border: Border.all(color: cur.toARGB32() == c ? sc.onSurface : Colors.transparent, width: 3),
                        ),
                      ),
                    ),
                ]),
              ),
              title(tx('ap_harmony_title')),
              ValueListenableBuilder<String>(
                valueListenable: colorHarmonyNotifier,
                builder: (_, h, _) => Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final k in harmonies)
                    ChoiceChip(
                      label: Text(tx('ap_harmony_$k')),
                      selected: h == k,
                      onSelected: (_) { _backupStyle(); colorHarmonyNotifier.value = k; },
                    ),
                ]),
              ),
              const SizedBox(height: 18),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (_, m, _) => SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded)),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded)),
                  ],
                  selected: {m == ThemeMode.light ? ThemeMode.light : ThemeMode.dark},
                  onSelectionChanged: (v) { _backupStyle(); themeModeNotifier.value = v.first; },
                ),
              ),
              title(tx('shape_title')),
              ValueListenableBuilder<String>(
                valueListenable: imageShapeNotifier,
                builder: (_, mode, _) => Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  for (final m in ['mix', for (var i = 0; i < kM3ImageShapeCount; i++) 'shape:$i'])
                    GestureDetector(
                      onTap: () { _backupStyle(); imageShapeNotifier.value = m; },
                      child: Container(
                        width: 44, height: 44,
                        alignment: Alignment.center,
                        decoration: ShapeDecoration(
                          color: mode == m ? sc.primary : sc.secondaryContainer,
                          shape: m == 'mix' ? const CircleBorder() : m3ImageShape(int.parse(m.substring(6)), 44),
                        ),
                        child: m == 'mix'
                            ? Icon(Icons.auto_awesome_rounded, size: 20, color: mode == m ? sc.onPrimary : sc.onSecondaryContainer)
                            : null,
                      ),
                    ),
                ]),
              ),
              title(tx('txt_font')),
              ValueListenableBuilder<String>(
                valueListenable: appFontNotifier,
                builder: (_, f, _) => Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final ft in fonts)
                    ChoiceChip(
                      label: Text(ft.$1.isEmpty ? tx('txt_font_def') : ft.$2, style: ft.$1.isEmpty ? null : TextStyle(fontFamily: ft.$1)),
                      selected: f == ft.$1,
                      onSelected: (_) { _backupStyle(); appFontNotifier.value = ft.$1; },
                    ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
  StreamSubscription? _stateSub, _posSub, _durSub;
  Duration _dur = Duration.zero;
  final ValueNotifier<double> _prog = ValueNotifier(0);

  Future<void> _loadTwinTrack(String user) async {
    try {
      final l = await widget.service.getTopTracks(user: user, period: '12month', limit: 1);
      if (l.isEmpty || !mounted) return;
      final t = l.first as Map;
      final a = t['artist'];
      final an = a is Map ? (a['name'] ?? a['#text'] ?? '') : '$a';
      setState(() => _twinTrack = _YrRanked('${t['name']}', '$an', 1));
    } catch (_) {}
  }

  bool _same(String a, String b) => a.toLowerCase().trim() == b.toLowerCase().trim();

  Future<_PvRes?> _deezerPreview(_PvReq q) async {
    final key = '${q.type}|${q.artist}|${q.name}';
    if (_previewCache.containsKey(key)) return _previewCache[key];
    _PvRes? res;
    try {
      Future<Map<String, dynamic>?> get(Uri u) async {
        final r = await ApiHttp.get(u).timeout(const Duration(seconds: 6));
        return r.statusCode == 200 ? jsonDecode(r.body) as Map<String, dynamic> : null;
      }
      List<Map<String, dynamic>> list(Map<String, dynamic>? j) =>
          (j?['data'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      _PvRes? pick(List<Map<String, dynamic>> l, {String? artist}) {
        Map<String, dynamic>? best;
        for (final t in l) {
          if (((t['preview'] as String?) ?? '').isEmpty) continue;
          final an = '${(t['artist'] as Map?)?['name'] ?? ''}';
          if (artist == null || artist.isEmpty || _same(an, artist) || an.toLowerCase().contains(artist.toLowerCase()) || (an.isNotEmpty && artist.toLowerCase().contains(an.toLowerCase()))) { best = t; break; }
        }
        if (best == null) return null;
        return _PvRes(best['preview'] as String, '${best['title']} — ${(best['artist'] as Map?)?['name'] ?? ''}');
      }
      if (q.type == 'tracks') {
        res = pick(list(await get(Uri.https('api.deezer.com', '/search', {'q': 'artist:"${q.artist}" track:"${q.name}"', 'limit': '5'}))), artist: q.artist);
        if (res == null) {
          final l2 = list(await get(Uri.https('api.deezer.com', '/search', {'q': '${q.artist} ${q.name}', 'limit': '8'})));
          res = pick(l2, artist: q.artist) ?? pick(l2);
        }
      } else if (q.type == 'artists') {
        final arts = list(await get(Uri.https('api.deezer.com', '/search/artist', {'q': q.name, 'limit': '5'})));
        Map<String, dynamic>? a;
        for (final x in arts) { if (_same('${x['name']}', q.name)) { a = x; break; } }
        a ??= arts.firstOrNull;
        if (a != null) res = pick(list(await get(Uri.https('api.deezer.com', '/artist/${a['id']}/top', {'limit': '10'}))));
      } else {
        final als = list(await get(Uri.https('api.deezer.com', '/search/album', {'q': '${q.artist} ${q.name}', 'limit': '3'})));
        Map<String, dynamic>? a;
        for (final x in als) { if (_same('${(x['artist'] as Map?)?['name']}', q.artist)) { a = x; break; } }
        a ??= als.firstOrNull;
        if (a != null) {
          final tr = list(await get(Uri.https('api.deezer.com', '/album/${a['id']}/tracks', {'limit': '10'})));
          // album track endpoint has no artist field: fall back to the album artist
          for (final t in tr) {
            final u = (t['preview'] as String?) ?? '';
            if (u.isNotEmpty) { res = _PvRes(u, '${t['title']} — ${q.artist}'); break; }
          }
        }
      }
    } catch (_) {}
    _previewCache[key] = res;
    return res;
  }

  Future<void> _stopPreview() async {
    _playToken++;
    _fadeTimer?.cancel();
    _nowTitle.value = '';
    _prog.value = 0;
    try { await _audio.stop(); } catch (_) {}
  }

  Future<void> _playForSlide(int i) async {
    await _stopPreview();
    final q = i >= 0 && i < _pvList.length ? _pvList[i] : null;
    if (q == null) return;
    final tok = _playToken;
    final r = await _deezerPreview(q);
    if (r == null || !mounted || tok != _playToken) return;
    _nowTitle.value = r.title;
    if (_userPaused) { _pendingUrl = r.url; return; }
    await _startUrl(r.url, tok);
  }

  String? _pendingUrl;

  Future<void> _startUrl(String url, int tok) async {
    try {
      await _audio.setReleaseMode(ReleaseMode.stop);
      await _audio.setVolume(0);
      await _audio.play(UrlSource(url));
    } catch (_) { return; }
    if (tok != _playToken) return;
    var step = 0;
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      step++;
      final v = (step / 15).clamp(0.0, 1.0);
      _audio.setVolume(v);
      if (v >= 1.0) t.cancel();
    });
  }

  Future<void> _togglePlay() async {
    if (_playing.value) {
      _userPaused = true;
      _fadeTimer?.cancel();
      await _audio.pause();
    } else {
      _userPaused = false;
      if (_pendingUrl != null) {
        final u = _pendingUrl!; _pendingUrl = null;
        await _startUrl(u, _playToken);
      } else {
        await _audio.resume();
        _audio.setVolume(1);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _durSub = _audio.onDurationChanged.listen((x) => _dur = x);
    _posSub = _audio.onPositionChanged.listen((pos) {
      final t = _dur.inMilliseconds;
      if (t <= 0) return;
      _prog.value = (pos.inMilliseconds / t).clamp(0.0, 1.0);
      final rem = t - pos.inMilliseconds;
      if (rem <= 2500) _audio.setVolume((rem / 2500).clamp(0.0, 1.0)); // fade-out
    });
    _stateSub = _audio.onPlayerStateChanged.listen((st) { if (mounted) _playing.value = st == PlayerState.playing; });
    _load();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await SharedPreferences.getInstance();
      _profileOn.value = p.getBool('ls_year_share_profile') ?? true;
      final me = await widget.service.getUserInfo();
      final imgs = me?['image'];
      var url = '';
      if (imgs is List && imgs.isNotEmpty) {
        final e = imgs.lastWhere((i) => i is Map && i['size'] == 'extralarge', orElse: () => imgs.last);
        url = (e is Map ? e['#text'] ?? '' : '').toString();
      }
      // Empty or default Last.fm picture: keep the theme gradient
      if (url.isEmpty || url.contains('2a96cbd8b46e442fc41c2b86b821562f')) return;
      // Average brightness of the picture decides white or black header text
      Uint8List? bytes;
      try {
        final r = await OfflineImageCache.responseFor(url).timeout(const Duration(seconds: 8));
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
          bytes = r.bodyBytes;
          final codec = await ui.instantiateImageCodec(r.bodyBytes, targetWidth: 32, targetHeight: 32);
          final frame = await codec.getNextFrame();
          final raw = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
          frame.image.dispose();
          if (raw != null) {
            final px = raw.buffer.asUint8List();
            var sum = 0.0, n = 0;
            for (var i = 0; i + 3 < px.length; i += 4) {
              if (px[i + 3] < 200) continue;
              sum += 0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2];
              n++;
            }
            if (n > 0) _photoDark = sum / n < 140;
          }
        }
      } catch (_) {}
      if (mounted && bytes != null) _photo.value = bytes;
    } catch (_) {}
  }

  @override
  void dispose() {
    _sharingN.dispose();
    _photo.dispose();
    _frameIdx.dispose();
    _profileOn.dispose();
    scheduleMicrotask(_restoreStyle);
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _prog.dispose();
    _playing.dispose();
    _nowTitle.dispose();
    _fadeTimer?.cancel();
    _audio.stop();
    _audio.dispose();
    _pages.dispose();
    super.dispose();
  }

  List<int> get _years {
    final now = DateTime.now().year;
    final last = _kYearRecapAllowCurrent ? now : now - 1;
    final first = AllScrobblesService.getRegistrationYear().clamp(2002, now).toInt();
    return [for (var y = last; y >= first; y--) y];
  }

  final GlobalKey _yearKey = GlobalKey();

  // Year picker: a small card anchored under the year chip, made of the
  // app's own M3Chip pills (same look as every other chip selector).
  Future<void> _pickYear(ColorScheme scheme) async {
    final box = _yearKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screen = MediaQuery.sizeOf(context);
    final base = Theme.of(context);
    final y = await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '$_year',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (c, a, a2, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          alignment: Alignment.topRight,
          scale: Tween<double>(begin: 0.85, end: 1).animate(
              CurvedAnimation(parent: a, curve: M3Motion.emphasizedDecelerate)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, a1, a2) => Theme(
        data: base.copyWith(colorScheme: scheme),
        child: Stack(children: [
          Positioned(
            top: pos.dy + size.height + 6,
            right: (screen.width - (pos.dx + size.width)).clamp(8.0, screen.width),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screen.width < 340 ? screen.width - 16 : 320,
                maxHeight: screen.height - (pos.dy + size.height) - 24,
              ),
              child: Material(
                color: scheme.surfaceContainerHigh,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final yr in _years)
                        M3Chip(
                          selected: yr == _year,
                          label: Text('$yr'),
                          onSelected: (_) => Navigator.pop(ctx, yr),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
    if (y != null && y != _year) {
      _year = y;
      _load();
    }
  }

  Future<void> _load() async {
    final token = ++_token;
    setState(() {
      _friendsData = null;
      _twinTrack = null;
      _loading = true;
      _error = false;
      _progress = 0;
      _data = null;
      _slide = 0;
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
    try {
      final records = await AllScrobblesService.loadYear(
        _year,
        widget.service,
        onProgress: (loaded, total) {
          if (mounted && total > 0) setState(() => _progress = loaded / total);
        },
      );
      if (!mounted) return;
      final data = _compute(records, _year);
      setState(() {
        _data = data;
        _loading = false;
      });
      if (data.total > 0) _loadFriends(_year, data, token);
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && token == _token) _playForSlide(_slide); });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  // ── Aggregation ──────────────────────────────────────────────────────────
  _YrData _compute(List<ScrobbleRecord> records, int year) {
    final d = _YrData();
    d.total = records.length;
    if (records.isEmpty) return d;

    final known = LibraryMerge.knownSync(widget.service.username);
    final artistCount = <String, int>{};
    final trackCount = <String, int>{};
    final trackRep = <String, ScrobbleRecord>{};
    final albumCount = <String, int>{};
    final albumRep = <String, ScrobbleRecord>{};
    final dayCount = <String, int>{};

    for (final r in records) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.ts * 1000);
      d.monthly[dt.month - 1]++;
      d.hourly[dt.hour]++;
      d.weekday[dt.weekday - 1]++;
      final dayKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      dayCount[dayKey] = (dayCount[dayKey] ?? 0) + 1;

      if (r.artist.isEmpty) continue;
      final parts = LibraryMerge.splitOn
          ? LibraryMerge.artistParts(r.artist, known, ambiguous: true)
          : [r.artist];
      for (final a in parts) {
        artistCount[a] = (artistCount[a] ?? 0) + 1;
      }
      final tKey = LibraryMerge.mergeOn
          ? LibraryMerge.trackKey(r.track, r.artist, known)
          : '${r.artist} — ${r.track}';
      trackCount[tKey] = (trackCount[tKey] ?? 0) + 1;
      trackRep.putIfAbsent(tKey, () => r);
      if (r.album.isNotEmpty) {
        final aKey = '${r.artist} — ${r.album}';
        albumCount[aKey] = (albumCount[aKey] ?? 0) + 1;
        albumRep.putIfAbsent(aKey, () => r);
      }
    }

    List<T> top<T>(Map<String, int> m, T Function(String, int) build) {
      final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return e.take(5).map((x) => build(x.key, x.value)).toList();
    }

    d.artists = top(artistCount, (k, c) => _YrRanked(k, '', c));
    d.artistsWide = (artistCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(20).map((e) => _YrRanked(e.key, '', e.value)).toList();
    d.calendar = dayCount;
    d.cumulative = AllScrobblesService.computeYearCumulative(records, year);
    d.hourlyMap = {for (var h = 0; h < 24; h++) h: d.hourly[h]};
    d.weekdayMap = {for (var w = 0; w < 7; w++) w + 1: d.weekday[w]};
    d.tracks = top(trackCount, (k, c) => _YrRanked(trackRep[k]!.track, trackRep[k]!.artist, c));
    d.tracksAll = (trackCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(300).map((e) => _YrRanked(trackRep[e.key]!.track, trackRep[e.key]!.artist, e.value)).toList();
    d.albums = top(albumCount, (k, c) => _YrRanked(albumRep[k]!.album, albumRep[k]!.artist, c));
    final ranked = artistCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    d.topArtistNames = ranked.take(50).map((e) => e.key).toList();
    d.uniqueArtists = artistCount.length;
    d.uniqueTracks = trackCount.length;

    // Active days, busiest day, longest streak (consecutive calendar days).
    d.activeDays = dayCount.length;
    final days = dayCount.keys.toList()..sort();
    var streak = 0, best = 0;
    DateTime? prev;
    for (final k in days) {
      final p = k.split('-');
      final day = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      streak = (prev != null && day.difference(prev).inHours <= 36) ? streak + 1 : 1;
      if (streak > best) best = streak;
      prev = day;
      final c = dayCount[k]!;
      if (c > d.busiestDayCount) {
        d.busiestDayCount = c;
        d.busiestDay = k;
      }
    }
    d.longestStreak = best;
    final now = DateTime.now();
    final end = year == now.year ? now : DateTime(year, 12, 31);
    d.daysInRange = end.difference(DateTime(year, 1, 1)).inDays + 1;

    // Tracks tied to specific slides (busiest day, main listening period, longest streak, random)
    String bucketOf(int h) => (h < 5 || h >= 22) ? 'night' : h < 12 ? 'morning' : h < 18 ? 'day' : 'evening';
    final bk = <String, int>{};
    for (var h = 0; h < 24; h++) { bk[bucketOf(h)] = (bk[bucketOf(h)] ?? 0) + d.hourly[h]; }
    final persona = bk.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    final streakDays = <String>{};
    {
      var st = 0; DateTime? pv;
      for (var i = 0; i < days.length; i++) {
        final q = days[i].split('-');
        final dd = DateTime(int.parse(q[0]), int.parse(q[1]), int.parse(q[2]));
        st = (pv != null && dd.difference(pv).inHours <= 36) ? st + 1 : 1;
        pv = dd;
        if (st == best && streakDays.isEmpty) streakDays.addAll(days.sublist(i - best + 1, i + 1));
      }
    }
    String dk(DateTime t) => '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    _YrRanked? topOf(bool Function(DateTime) test) {
      final c = <String, int>{};
      final rp = <String, ScrobbleRecord>{};
      for (final r in records) {
        if (r.artist.isEmpty || r.track.isEmpty) continue;
        if (!test(DateTime.fromMillisecondsSinceEpoch(r.ts * 1000))) continue;
        final k = '${r.artist} — ${r.track}';
        c[k] = (c[k] ?? 0) + 1;
        rp.putIfAbsent(k, () => r);
      }
      if (c.isEmpty) return null;
      final b = c.entries.reduce((a, x) => x.value > a.value ? x : a);
      return _YrRanked(rp[b.key]!.track, rp[b.key]!.artist, b.value);
    }
    d.busiestTrack = topOf((t) => dk(t) == d.busiestDay);
    d.peakTrack = topOf((t) => bucketOf(t.hour) == persona);
    d.streakTrack = topOf((t) => streakDays.contains(dk(t)));
    {
      final c = <String, int>{};
      final rp = <String, ScrobbleRecord>{};
      for (final r in records) {
        if (r.artist.isEmpty || r.track.isEmpty) continue;
        final k = '${dk(DateTime.fromMillisecondsSinceEpoch(r.ts * 1000))}|${r.artist} — ${r.track}';
        c[k] = (c[k] ?? 0) + 1;
        rp.putIfAbsent(k, () => r);
      }
      if (c.isNotEmpty) {
        final b = c.entries.reduce((a, x) => x.value > a.value ? x : a);
        d.dayRecord = _YrRanked(rp[b.key]!.track, rp[b.key]!.artist, b.value);
        final q = b.key.split('|').first.split('-');
        d.dayRecordDate = '${q[2]}/${q[1]}/${q[0]}';
      }
    }
    final withTrack = records.where((r) => r.artist.isNotEmpty && r.track.isNotEmpty).toList();
    if (withTrack.isNotEmpty) {
      final r = withTrack[math.Random(year).nextInt(withTrack.length)];
      d.randomTrack = _YrRanked(r.track, r.artist, 1);
    }

    // Discoveries: artists never scrobbled in any earlier year. Only computed
    // when every earlier year since registration is in the local cache.
    final reg = AllScrobblesService.getRegistrationYear();
    var allPrior = true;
    final before = <String>{};
    for (var y = reg; y < year; y++) {
      final rs = AllScrobblesService.isYearCached(y) ? AllScrobblesService.getRecordsForYear(y) : null;
      if (rs == null) {
        allPrior = false;
        break;
      }
      for (final r in rs) {
        before.add(r.artist);
      }
    }
    if (allPrior && year > reg) {
      d.newArtists = artistCount.keys.where((a) => !before.contains(a)).length;
    }
    return d;
  }

  // ── Friends ──────────────────────────────────────────────────────────────
  // Yearly totals: one cheap call per friend (limit 1 -> only the total).
  // Taste twin: overlap between your top artists of the year and the friend
  // libraries already synced by FriendsLibraryService (no extra requests).
  Future<void> _loadFriends(int year, _YrData d, int token) async {
    try {
      final raw = await widget.service.getFriends(limit: 30, withRecentTrack: false);
      String bestImg(dynamic imgs) {
        if (imgs is! List || imgs.isEmpty) return '';
        final e = imgs.lastWhere((i) => i is Map && i['size'] == 'extralarge', orElse: () => imgs.last);
        return (e is Map ? e['#text'] ?? '' : '').toString();
      }

      final images = <String, String>{};
      final names = <String>[];
      for (final f in raw) {
        if (f is Map && (f['name'] ?? '').toString().isNotEmpty) {
          final n = f['name'].toString();
          names.add(n);
          images[n] = bestImg(f['image']);
        }
      }
      if (names.length > 20) names.removeRange(20, names.length);
      var myImage = '';
      try {
        final me = await widget.service.getUserInfo();
        myImage = bestImg(me?['image']);
      } catch (_) {}
      if (names.isEmpty) return;
      final now = DateTime.now();
      final from = DateTime(year, 1, 1).millisecondsSinceEpoch ~/ 1000;
      final to = (year == now.year ? now.add(const Duration(minutes: 1)) : DateTime(year + 1, 1, 1))
              .millisecondsSinceEpoch ~/ 1000;

      final board = <_YrFriend>[];
      for (var i = 0; i < names.length; i += 5) {
        final batch = names.skip(i).take(5);
        final res = await Future.wait(batch.map((n) async {
          try {
            final r = await widget.service.getRecentTracks(user: n, from: from, to: to, limit: 1);
            final t = int.tryParse((r['@attr']?['total'] ?? '0').toString()) ?? 0;
            return _YrFriend(n, t, images[n] ?? '');
          } catch (_) {
            return _YrFriend(n, 0); // private profile / error: skipped below
          }
        }));
        board.addAll(res.where((r) => r.total > 0));
        if (!mounted || token != _token) return;
      }

      String? twin;
      var shared = <String>[];
      var best = 0;
      final mine = d.topArtistNames;
      for (final n in names) {
        final lib = FriendsLibraryService.get(n);
        if (lib == null) continue;
        final theirs = lib.artists.take(150).map((a) => (a['name'] ?? '').toString().toLowerCase()).toSet();
        final common = mine.where((a) => theirs.contains(a.toLowerCase())).toList();
        if (common.length > best) {
          best = common.length;
          twin = n;
          shared = common;
        }
      }
      if (!mounted || token != _token) return;
      setState(() => _friendsData = _YrFriends(board, twin, shared.take(6).toList(), best, images, myImage));
      if (twin != null) _loadTwinTrack(twin);
    } catch (_) {
      // Friends are a bonus: no friends / network error -> no friend slides.
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('\u202f');
      b.write(s[i]);
    }
    return b.toString();
  }

  List<String> get _months => tx('yr_months').split(',');

  List<String> get _monthsFull => tx('yr_months_full').split(',');
  List<String> get _monthsGen => tx('yr_months_gen').split(',');
  List<String> get _weekdaysFull => tx('yr_weekdays_full').split(',');

  // "13 octobre" / "October 13" / "10月13日" depending on the language.
  String _dayLabel(String key) {
    final p = key.split('-');
    final m = int.parse(p[1]);
    final names = _monthsGen;
    return tx('yr_day_fmt', {
      'd': '${int.parse(p[2])}',
      'm': m - 1 < names.length ? names[m - 1] : p[1],
    });
  }

  Future<void> _share() async {
    if (_sharing) return;
    // Only the button listens to this: rebuilding the page here would reset
    // the card's image loaders to their placeholder right before the capture.
    _sharing = true;
    _sharingN.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      await WidgetsBinding.instance.endOfFrame;
      final rb = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (rb == null) throw StateError('no boundary');
      final img = await rb.toImage(pixelRatio: 3.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bytes == null) throw StateError('no bytes');
      await AppShare.shareBytes('laststats_year_${widget.username}_$_year.png', bytes.buffer.asUint8List());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tx('yr_share_err'))));
      }
    } finally {
      _sharing = false;
      if (mounted) _sharingN.value = false;
    }
  }

  // Share the slide currently shown, inside the same themed 9:16 card as the final recap.
  // The slide is rebuilt off-screen at a fixed phone size with all animations finished.
  Future<void> _shareSlide() async {
    if (_sharing || _data == null) return;
    _sharing = true;
    _sharingN.value = true;
    try {
      _yrInstant = true;
      _frameIdx.value = _slide;
      // Let the frame (and the pictures) build and load before the capture
      await Future.delayed(const Duration(milliseconds: 1800));
      await WidgetsBinding.instance.endOfFrame;
      final fb = _frameKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (fb == null) throw StateError('no frame');
      final img = await fb.toImage(pixelRatio: 3.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bytes == null) throw StateError('no bytes');
      await AppShare.shareBytes('laststats_year_${widget.username}_${_year}_${_slide + 1}.png', bytes.buffer.asUint8List());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tx('yr_share_err'))));
      }
    } finally {
      _frameIdx.value = null;
      _yrInstant = false;
      _sharing = false;
      if (mounted) _sharingN.value = false;
    }
  }

  void _next() {
    if (_data == null) return;
    if (_slide < _slideCount - 1) {
      _pages.nextPage(duration: M3Motion.spatialFastDuration, curve: M3Motion.spatialFast);
    }
  }

  void _prev() {
    if (_slide > 0) {
      _pages.previousPage(duration: M3Motion.spatialFastDuration, curve: M3Motion.spatialFast);
    }
  }

  int get _slideCount => _buildSlides(Theme.of(context).colorScheme).length;

  // Same prev/next button as the week/month recap
  Widget _navBtn(ColorScheme scheme, IconData icon, bool enabled, VoidCallback onTap) {
    return M3TonalButton(
      width: 72,
      height: 52,
      padding: EdgeInsets.zero,
      color: scheme.primaryContainer,
      radius: BorderRadius.circular(26),
      onTap: enabled ? onTap : null,
      child: Icon(icon, color: scheme.onPrimaryContainer, size: 28),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = _data;
    final ready = d != null && d.total > 0;
    final slides = ready ? _buildSlides(scheme) : const <Widget>[];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(clipBehavior: Clip.none, children: [Positioned.fill(child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primaryContainer.withValues(alpha: 0.6), scheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            if (ready)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: List.generate(slides.length, (i) {
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () { if (_pages.hasClients && i != _slide) _pages.jumpToPage(i); },
                        child: AnimatedContainer(
                          duration: M3Motion.spatialFastDuration,
                          curve: M3Motion.spatialFast,
                          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _slide ? scheme.primary : scheme.primary.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tx('yr_title'), style: AppText.title.copyWith(color: scheme.onSurface)),
                ),
                M3Chip(
                  key: _yearKey,
                  selected: false,
                  avatar: const Icon(Icons.expand_more_rounded),
                  label: Text('$_year', style: const TextStyle(fontWeight: FontWeight.w800)),
                  onSelected: (_) => _pickYear(scheme),
                ),
                const SizedBox(width: 8),
              ]),
            ),
            Expanded(child: _content(scheme, slides)),
            if (ready)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(children: [
                  _navBtn(scheme, Icons.chevron_left_rounded, _slide > 0, _prev),
                  Expanded(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${_slide + 1} / ${slides.length}',
                          style: TextStyle(color: _yrSoft(scheme), fontSize: 13, fontWeight: FontWeight.w800)),
                      // Share this slide alone (the last slide has its own share button)
                      if (_slide < slides.length - 1) ...[
                        const SizedBox(width: 10),
                        ValueListenableBuilder<bool>(
                          valueListenable: _sharingN,
                          builder: (_, busy, _) => IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            tooltip: L.commonShare,
                            onPressed: busy ? null : _shareSlide,
                            icon: busy ? SizedBox(width: 18, height: 18, child: M3Spinner(color: scheme.primary)) : const Icon(Icons.ios_share_rounded, size: 20),
                          ),
                        ),
                      ],
                    ]),
                  ),
                  _navBtn(scheme, Icons.chevron_right_rounded, _slide < slides.length - 1, _next),
                ]),
              ),
          ]),
        ),
      )),
        // Hidden (off-screen) 9:16 frame, only built while a single slide is being shared
        Positioned(
          left: -5000,
          top: 0,
          width: 360,
          height: 640,
          child: ValueListenableBuilder<int?>(
            valueListenable: _frameIdx,
            builder: (_, idx, _) => (idx == null || d == null)
                ? const SizedBox.shrink()
                : ValueListenableBuilder<Uint8List?>(
                    valueListenable: _photo,
                    builder: (_, photo, _) => ValueListenableBuilder<bool>(
                      valueListenable: _profileOn,
                      builder: (_, on, _) => RepaintBoundary(
                        key: _frameKey,
                        child: _YrShareCard(
                          scheme: scheme,
                          year: _year,
                          username: widget.username,
                          data: d,
                          hours: (d.total * _kYrAvgTrackMinutes / 60).round(),
                          fmt: _fmt,
                          photo: on ? photo : null,
                          photoDark: _photoDark,
                          slide: () {
                            final all = _buildSlides(scheme, frame: true);
                            return idx < all.length ? all[idx] : const SizedBox();
                          }(),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _content(ColorScheme scheme, List<Widget> slides) {
    if (_loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 160, child: M3WavyProgress(value: _progress.clamp(0.0, 1.0).toDouble())),
          const SizedBox(height: 16),
          Text(tx('yr_loading'), style: TextStyle(color: _yrSoft(scheme))),
        ]),
      );
    }
    if (_error || _data == null || _data!.total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(_error ? Icons.cloud_off_rounded : Icons.music_off_rounded, size: 48, color: _yrSoft(scheme)),
            const SizedBox(height: 12),
            Text(
              _error ? tx('yr_error') : tx('yr_empty', {'year': '$_year'}),
              textAlign: TextAlign.center,
              style: TextStyle(color: _yrSoft(scheme), fontSize: 15),
            ),
            if (_error) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: _load, child: Text(tx('yr_retry'))),
            ],
          ]),
        ),
      );
    }
    return Stack(children: [
      PageView(
        controller: _pages,
        onPageChanged: (i) { setState(() => _slide = i); _playForSlide(i); },
        children: slides,
      ),
      // Tap zones (left third = back, right two thirds = next), like a story.
      // Not on the last slide: they would swallow taps on the share button.
      if (_slide < _slideCount - 1)
      Positioned.fill(
        child: Row(children: [
          Expanded(
            flex: 1,
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _prev),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _next),
          ),
        ]),
      ),
      if (!_sharing)
        Positioned(
          left: 16, right: 16, bottom: 14,
          child: ValueListenableBuilder<String>(
            valueListenable: _nowTitle,
            builder: (_, title, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(a), child: c),
              ),
              child: title.isEmpty
                  ? const SizedBox.shrink(key: ValueKey('off'))
                  : ValueListenableBuilder<bool>(
                      key: ValueKey(_slide >= _slideCount - 1),
                      valueListenable: _playing,
                      builder: (_, on, _) => _slide >= _slideCount - 1
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: Material(
                                color: scheme.primaryContainer.withValues(alpha: 0.92),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  onPressed: _togglePlay,
                                  icon: Icon(on ? Icons.pause_rounded : Icons.play_arrow_rounded, color: scheme.primary),
                                ),
                              ),
                            )
                          : Material(
                              color: scheme.primaryContainer.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(28),
                              child: Row(children: [
                                IconButton(
                                  onPressed: _togglePlay,
                                  icon: Icon(on ? Icons.pause_rounded : Icons.play_arrow_rounded, color: scheme.primary),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 13, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      ValueListenableBuilder<double>(
                                        valueListenable: _prog,
                                        builder: (_, v, _) => M3WavyProgress(
                                          value: v, height: 10, stroke: 3,
                                          color: scheme.primary,
                                          trackColor: scheme.primary.withValues(alpha: 0.18),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ]),
                            ),
                    ),
            ),
          ),
        ),
    ]);
  }

  // ── Slides ───────────────────────────────────────────────────────────────
  List<Widget> _buildSlides(ColorScheme s, {bool frame = false}) {
    final d = _data;
    if (d == null || d.total == 0) return const [];
    final hours = (d.total * _kYrAvgTrackMinutes / 60).round();
    final out = <Widget>[];
    final pv = <_PvReq?>[];
    _PvReq? cur;
    void add(Widget w) { out.add(w); pv.add(cur); cur = null; }
    final used = <String>{};
    String kk(_YrRanked r) => '${r.artist}|${r.name}'.toLowerCase();
    final reserved = <String>{
      if (d.tracks.isNotEmpty) kk(d.tracks.first),
      if (d.streakTrack != null) kk(d.streakTrack!),
      if (d.dayRecord != null) kk(d.dayRecord!),
    };
    _PvReq? uniqT(_YrRanked? r) {
      if (r != null && !used.contains(kk(r)) && !reserved.contains(kk(r))) { used.add(kk(r)); return _PvReq.of('tracks', r); }
      for (final c in d.tracksAll) {
        if (!used.contains(kk(c)) && !reserved.contains(kk(c))) { used.add(kk(c)); return _PvReq.of('tracks', c); }
      }
      return r == null ? null : _PvReq.of('tracks', r);
    }
    final mq = MediaQuery.of(context);
    final cardW = (frame ? 316.0 : math.min(mq.size.width - 56, 320.0)).clamp(180.0, 320.0).toDouble();

    // 1. Intro
    if (d.tracksAll.length > 5) cur = uniqT(d.tracksAll[2 + math.Random(_year + 1).nextInt(math.min(20, d.tracksAll.length - 2))]);
    add(_YrSlide(
      scheme: s,
      children: [
        if (_yrInstant)
          const SizedBox(height: 0)
        else ...[
          Text(tx('yr_intro_h', {'year': '$_year'}),
              textAlign: TextAlign.center,
              style: TextStyle(color: s.onPrimaryContainer, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 28),
        ],
        _YrCountUp(value: d.total, fmt: _fmt, delayMs: 350, durationMs: 1600,
            style: TextStyle(color: s.primary, fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 6),
        _YrReveal(delayMs: 500, child: Text(tx('yr_scrobbles'), style: TextStyle(color: _yrSoft(s), fontSize: 16, fontWeight: FontWeight.w700))),
        if (!_yrInstant) ...[
          const SizedBox(height: 20),
          Builder(builder: (_) {
            final raw = tx('yr_hours', {'h': _fmt(hours)});
            final m = RegExp(r'\s*[\(（]([^\)）]*)[\)）]').firstMatch(raw);
            final main = m == null ? raw : raw.replaceFirst(m.group(0)!, '');
            return _YrReveal(delayMs: 1900, child: Column(children: [
              Text(main, textAlign: TextAlign.center, style: TextStyle(color: _yrSoft(s), fontSize: 14)),
              if (m != null)
                Text(m.group(1)!, textAlign: TextAlign.center, style: TextStyle(color: _yrSoft(s).withValues(alpha: 0.6), fontSize: 10, fontStyle: FontStyle.italic)),
            ]));
          }),
        ],
      ],
    ));

    // 2-4. Top artist / track / album: #1 big in the middle, then the rest
    if (d.artists.isNotEmpty) { cur = _PvReq.of('artists', d.artists.first); add(_topSlide(s, d.artists, 'artists', tx('yr_top_artist'))); }
    if (d.tracks.isNotEmpty) { cur = _PvReq.of('tracks', d.tracks.first); add(_topSlide(s, d.tracks, 'tracks', tx('yr_top_track'))); }
    if (d.albums.isNotEmpty) { cur = _PvReq.of('albums', d.albums.first); add(_topSlide(s, d.albums, 'albums', tx('yr_top_album'))); }

    // 5. Month by month
    cur = uniqT(d.busiestTrack);
    final maxM = d.monthly.fold<int>(0, (m, v) => v > m ? v : m);
    final bestMonth = d.monthly.indexOf(maxM);
    add(_YrSlide(
      scheme: s,
      children: [
        _label(s, tx('yr_months_h')),
        const SizedBox(height: 22),
        SizedBox(
          height: 170,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (i) {
              final f = maxM == 0 ? 0.0 : d.monthly[i] / maxM;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: f),
                          duration: _yrInstant ? Duration.zero : Duration(milliseconds: 500 + i * 80),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => FractionallySizedBox(
                            heightFactor: v.clamp(0.02, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == bestMonth ? s.primary : s.primary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(i < _months.length ? _months[i].characters.first : '',
                        style: TextStyle(color: _yrSoft(s), fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 22),
        Text(tx('yr_best_month', {'m': bestMonth < _monthsFull.length ? _monthsFull[bestMonth] : '', 'n': _fmt(maxM)}),
            textAlign: TextAlign.center, style: TextStyle(color: s.onPrimaryContainer, fontSize: 16, fontWeight: FontWeight.w800)),
        if (d.busiestDay != null) ...[
          const SizedBox(height: 8),
          Text(tx('yr_best_day', {'d': _dayLabel(d.busiestDay!), 'n': _fmt(d.busiestDayCount)}),
              textAlign: TextAlign.center, style: TextStyle(color: _yrSoft(s), fontSize: 14)),
        ],
      ],
    ));

    // 6. When you listen
    cur = uniqT(d.peakTrack);
    final buckets = <String, int>{
      'night': [for (var h = 0; h < 24; h++) if (h < 5 || h >= 22) d.hourly[h]].fold(0, (a, b) => a + b),
      'morning': [for (var h = 5; h < 12; h++) d.hourly[h]].fold(0, (a, b) => a + b),
      'day': [for (var h = 12; h < 18; h++) d.hourly[h]].fold(0, (a, b) => a + b),
      'evening': [for (var h = 18; h < 22; h++) d.hourly[h]].fold(0, (a, b) => a + b),
    };
    final persona = buckets.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    final maxH = d.hourly.fold<int>(0, (m, v) => v > m ? v : m);
    final peakHour = d.hourly.indexOf(maxH);
    final maxW = d.weekday.fold<int>(0, (m, v) => v > m ? v : m);
    final favDay = d.weekday.indexOf(maxW);
    final wd = _weekdaysFull;
    add(_YrSlide(
      scheme: s,
      children: [
        _label(s, tx('yr_when_h')),
        const SizedBox(height: 14),
        Text(tx('yr_p_$persona'),
            textAlign: TextAlign.center,
            style: TextStyle(color: s.primary, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 22),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (h) {
              final f = maxH == 0 ? 0.0 : d.hourly[h] / maxH;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FractionallySizedBox(
                    heightFactor: f.clamp(0.03, 1.0),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: h == peakHour ? s.primary : s.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final t in const ['0h', '6h', '12h', '18h', '23h'])
              Text(t, style: TextStyle(color: _yrSoft(s), fontSize: 10)),
          ]),
        ),
        const SizedBox(height: 22),
        Text(tx('yr_peak', {'h': '$peakHour', 'd': favDay < wd.length ? wd[favDay] : ''}),
            textAlign: TextAlign.center, style: TextStyle(color: s.onPrimaryContainer, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    ));

    // 7. Consistency
    cur = uniqT(d.tracksAll.length > 8 ? d.tracksAll[4 + math.Random(_year + 7).nextInt(math.min(25, d.tracksAll.length - 4))] : null);
    add(_YrSlide(
      scheme: s,
      children: [
        _label(s, tx('yr_streak_h')),
        const SizedBox(height: 22),
        _YrCountUp(value: d.longestStreak, fmt: _fmt, delayMs: 300, durationMs: 1400,
            style: TextStyle(color: s.primary, fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 6),
        Text(tx('yr_streak', {'n': '${d.longestStreak}'}),
            textAlign: TextAlign.center, style: TextStyle(color: s.onPrimaryContainer, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Text(tx('yr_active', {'n': '${d.activeDays}', 't': '${d.daysInRange}'}),
            textAlign: TextAlign.center, style: TextStyle(color: _yrSoft(s), fontSize: 14)),
      ],
    ));

    // 7a. Streak song + biggest single-day song
    if (d.streakTrack != null && d.longestStreak > 1) {
      cur = _PvReq.of('tracks', d.streakTrack!);
      add(_trackSlide(s, tx('yr_flame_h'), d.streakTrack!, 6, d.streakTrack!.count, tx('yr_flame_s', {'n': '${d.longestStreak}'})));
    }
    if (d.dayRecord != null && d.dayRecord!.count >= 2) {
      cur = _PvReq.of('tracks', d.dayRecord!);
      add(_trackSlide(s, tx('yr_day_h'), d.dayRecord!, 7, d.dayRecord!.count, tx('yr_day_s', {'d': d.dayRecordDate})));
    }

    // 7b. Where the plays go (Charts tab donut)
    if (d.artistsWide.length > 1) {
      cur = _PvReq.of('artists', d.artistsWide.firstWhere((a) => d.artists.isEmpty || a.name != d.artists.first.name, orElse: () => d.artistsWide.first));
      add(_YrSlide(
        scheme: s,
        children: [
          _label(s, tx('yr_share_h')),
          const SizedBox(height: 16),
          _ShareDonut(
            textColor: s.onPrimaryContainer,
            items: d.artistsWide,
            getLabel: (e) => (e as _YrRanked).name,
            getPlays: (e) => (e as _YrRanked).count,
          ),
        ],
      ));
    }

    // 8. Discoveries
    cur = uniqT(d.randomTrack);
    add(_YrSlide(
      scheme: s,
      children: [
        _label(s, tx('yr_disc_h')),
        const SizedBox(height: 22),
        if (d.newArtists != null) ...[
          _YrCountUp(value: d.newArtists!, fmt: _fmt, delayMs: 300, durationMs: 1400,
              style: TextStyle(color: s.primary, fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 6),
          Text(tx('yr_new'), textAlign: TextAlign.center, style: TextStyle(color: s.onPrimaryContainer, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
        ],
        Text(tx('yr_unique', {'a': _fmt(d.uniqueArtists), 't': _fmt(d.uniqueTracks)}),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: d.newArtists != null ? _yrSoft(s) : s.onPrimaryContainer,
                fontSize: d.newArtists != null ? 14 : 20,
                fontWeight: d.newArtists != null ? FontWeight.w600 : FontWeight.w800)),
      ],
    ));

    // 9. Friends: yearly leaderboard
    final fr = _friendsData;
    String? rankLine;
    if (fr != null && fr.board.isNotEmpty) {
      final rows = [...fr.board, _YrFriend('', d.total, fr.myImage)]..sort((a, b) => b.total.compareTo(a.total));
      final myRank = rows.indexWhere((r) => r.name.isEmpty) + 1;
      rankLine = tx('yr_rank', {'r': '$myRank', 'n': '${rows.length}'});
      final shown = rows.take(6).toList();
      if (!shown.any((r) => r.name.isEmpty)) shown[shown.length - 1] = rows[myRank - 1];
      final maxT = rows.first.total;
      if (d.tracksAll.isNotEmpty) cur = uniqT(d.tracksAll[(myRank - 1).clamp(0, d.tracksAll.length - 1)]);
      add(_YrSlide(
        scheme: s,
        children: [
          _label(s, tx('yr_friends_h')),
          const SizedBox(height: 10),
          _YrReveal(delayMs: 250, pop: true, child: Text(rankLine,
              textAlign: TextAlign.center,
              style: TextStyle(color: s.primary, fontSize: 28, fontWeight: FontWeight.w900))),
          const SizedBox(height: 20),
          for (var i = 0; i < shown.length; i++)
            _YrReveal(
              delayMs: 700 + i * 180,
              child: _friendBar(s, shown[i], maxT, 900 + i * 180, rows.indexOf(shown[i]) + 1),
            ),
        ],
      ));
    }

    // 10. Friends: music twin
    if (fr != null && fr.twin != null) {
      cur = uniqT(_twinTrack);
      add(_YrSlide(
        scheme: s,
        children: [
          _label(s, tx('yr_twin_h')),
          const SizedBox(height: 20),
          _YrReveal(
            delayMs: 300,
            pop: true,
            child: _YrAvatar(url: fr.images[fr.twin!] ?? '', label: fr.twin!, size: 104),
          ),
          const SizedBox(height: 14),
          _YrReveal(delayMs: 800, child: Text(fr.twin!,
              textAlign: TextAlign.center,
              style: TextStyle(color: s.onPrimaryContainer, fontSize: 22, fontWeight: FontWeight.w900))),
          const SizedBox(height: 6),
          _YrReveal(delayMs: 1100, child: Text(tx('yr_twin_s', {'n': '${fr.sharedCount}'}),
              textAlign: TextAlign.center, style: TextStyle(color: _yrSoft(s), fontSize: 14))),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < fr.shared.length; i++)
                _YrReveal(
                  delayMs: 1400 + i * 160,
                  child: Chip(
                    label: Text(fr.shared[i], style: TextStyle(fontWeight: FontWeight.w700, color: s.onPrimaryContainer)),
                    backgroundColor: s.primaryContainer,
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
        ],
      ));
    }

    // 11. Summary + share
    if (d.tracks.isNotEmpty) cur = _PvReq.of('tracks', d.tracks.first);
    add(_YrSlide(
      scheme: s,
      children: [
        SizedBox(
          width: cardW,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            child: ValueListenableBuilder<Uint8List?>(
              valueListenable: _photo,
              builder: (_, photo, _) => ValueListenableBuilder<bool>(
                valueListenable: _profileOn,
                builder: (_, on, _) => RepaintBoundary(
                  key: _shareKey,
                  child: _YrShareCard(scheme: s, year: _year, username: widget.username, data: d, hours: hours, fmt: _fmt, rankLine: rankLine, photo: on ? photo : null, photoDark: _photoDark),
                ),
              ),
            ),
          ),
        ),
        // Option: use the profile picture colours for the share image
        ValueListenableBuilder<Uint8List?>(
          valueListenable: _photo,
          builder: (_, photo, _) => photo == null
              ? const SizedBox(height: 14)
              : ValueListenableBuilder<bool>(
                  valueListenable: _profileOn,
                  builder: (_, on, _) => SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(tx('yr_share_profile'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    value: on,
                    onChanged: (v) async {
                      _profileOn.value = v;
                      final p = await SharedPreferences.getInstance();
                      await p.setBool('ls_year_share_profile', v);
                    },
                  ),
                ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ValueListenableBuilder<bool>(
            valueListenable: _sharingN,
            builder: (_, busy, _) => FilledButton.icon(
              onPressed: busy ? null : _share,
              icon: busy
                  ? SizedBox(width: 18, height: 18, child: M3Spinner(color: s.onPrimary))
                  : const Icon(Icons.ios_share_rounded),
              label: Text(L.commonShare),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(onPressed: _openStyle, tooltip: tx('yr_style'), icon: const Icon(Icons.palette_rounded)),
        ]),
      ],
    ));
    if (!frame) _pvList = pv;
    return out;
  }

  // Big #1 (artwork, name, plays counting up) followed by ranks 2..5.
  // Shapes for ranks 2+: never the hero's shape (nor its look-alike)
  int _listShape(String type, int i) {
    final hero = _heroShape(type);
    final pool = [for (var k = 0; k < 8; k++) if (k != hero && !((hero == 0 || hero == 4) && (k == 0 || k == 4))) k];
    return pool[(i - 1 + (type == 'artists' ? 0 : type == 'tracks' ? 2 : 4)) % pool.length];
  }

  Widget _trackSlide(ColorScheme s, String label, _YrRanked r, int shape, int bigN, String sub) => _YrSlide(
        scheme: s,
        compact: true,
        children: [
          _label(s, label),
          const SizedBox(height: 18),
          _YrImg(name: r.name, artist: r.artist, type: 'tracks', size: 170, shapeIndex: shape, spin: _playing),
          const SizedBox(height: 16),
          Text(r.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: s.onPrimaryContainer, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(r.artist, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _yrSoft(s), fontSize: 15)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            _YrCountUp(value: bigN, fmt: _fmt, delayMs: 300, durationMs: 1400,
                style: TextStyle(color: s.primary, fontSize: 44, fontWeight: FontWeight.w900, height: 1)),
            Text('×', style: TextStyle(color: s.primary, fontSize: 44, fontWeight: FontWeight.w900, height: 1)),
          ]),
          const SizedBox(height: 6),
          _YrReveal(delayMs: 900, child: Text(sub, textAlign: TextAlign.center, style: TextStyle(color: _yrSoft(s), fontSize: 14))),
        ],
      );

  // #1 never uses the circle: clover / burst / cookie
  int _heroShape(String type) => type == 'artists' ? 2 : (type == 'tracks' ? 4 : 0);

  Widget _topSlide(ColorScheme s, List<_YrRanked> items, String type, String label) {
    final first = items.first;
    return _YrSlide(
      scheme: s,
      compact: true,
      children: [
        if (_yrInstant)
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Text('${label.toUpperCase()} :',
                  textAlign: TextAlign.left,
                  style: TextStyle(color: s.primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0, height: 1.25)),
            ),
            const SizedBox(width: 12),
            _YrImg(name: first.name, artist: first.artist, type: type, size: 120, shapeIndex: _heroShape(type)),
          ])
        else ...[
          _label(s, label),
          const SizedBox(height: 18),
          _YrReveal(
            delayMs: 300,
            pop: true,
            child: _YrImg(name: first.name, artist: first.artist, type: type, size: 190, shapeIndex: _heroShape(type), spin: _playing),
          ),
        ],
        SizedBox(height: _yrInstant ? 14 : 18),
        _YrReveal(
          delayMs: 900,
          child: Text(first.name,
              textAlign: TextAlign.center,
              maxLines: _yrInstant ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: s.onPrimaryContainer, fontSize: _yrInstant ? 26 : 22, fontWeight: FontWeight.w900)),
        ),
        if (first.artist.isNotEmpty)
          _YrReveal(
            delayMs: 1000,
            child: Text(first.artist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _yrSoft(s), fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 4),
        _YrCountUp(
            value: first.count,
            fmt: (n) => tx('yr_plays', {'n': _fmt(n)}),
            delayMs: 1200,
            durationMs: 1000,
            style: TextStyle(color: s.primary, fontSize: 16, fontWeight: FontWeight.w800)),
        SizedBox(height: _yrInstant ? 14 : 22),
        _rankList(s, items.skip(1).toList(), type, startAt: 2, baseDelay: 1800),
      ],
    );
  }

  Widget _label(ColorScheme s, String t) => Text(t.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(color: _yrSoft(s), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4));

  Widget _friendBar(ColorScheme s, _YrFriend r, int maxT, int delayMs, int rank) {
    final me = r.name.isEmpty;
    final f = maxT == 0 ? 0.0 : r.total / maxT;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 26, child: Text('$rank', style: TextStyle(color: me ? s.primary : _yrSoft(s), fontSize: 15, fontWeight: FontWeight.w900))),
          _YrAvatar(url: r.image, label: me ? tx('yr_you') : r.name, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(me ? tx('yr_you') : r.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: s.onPrimaryContainer, fontSize: 14, fontWeight: me ? FontWeight.w900 : FontWeight.w700)),
          ),
          _YrCountUp(value: r.total, fmt: _fmt, delayMs: delayMs, durationMs: 1100,
              style: TextStyle(color: me ? s.primary : _yrSoft(s), fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 68),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: f),
            duration: _yrInstant ? Duration.zero : Duration(milliseconds: 900 + (delayMs ~/ 4)),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v.clamp(0.02, 1.0),
                minHeight: 10,
                backgroundColor: s.primary.withValues(alpha: 0.12),
                color: me ? s.primary : s.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // Rows are revealed from the last to the first, so #1 lands last.
  Widget _rankList(ColorScheme s, List<_YrRanked> items, String type, {int startAt = 1, int baseDelay = 300}) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _YrReveal(
            delayMs: baseDelay + (items.length - 1 - i) * 240,
            pop: i == 0 && startAt == 1,
            child: Padding(
            padding: EdgeInsets.symmetric(vertical: _yrInstant ? 3 : 5),
            child: Row(children: [
              SizedBox(
                width: 28,
                child: Text('${startAt + i}',
                    style: TextStyle(color: i == 0 && startAt == 1 ? s.primary : _yrSoft(s), fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              _YrImg(name: items[i].name, artist: items[i].artist, type: type, size: 46, shapeIndex: _listShape(type, i)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(items[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.itemTitle.copyWith(color: s.onPrimaryContainer)),
                  if (items[i].artist.isNotEmpty)
                    Text(items[i].artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(color: _yrSoft(s))),
                ]),
              ),
              const SizedBox(width: 8),
              Text(tx('yr_plays', {'n': _fmt(items[i].count)}), style: AppText.badge.copyWith(color: s.primary)),
            ]),
          ),
          ),
      ],
    );
  }
}

// Round profile picture (same ImageService loader as the rest of the app),
// with a coloured initial while loading / when the user has no picture.
class _YrAvatar extends StatelessWidget {
  final String url, label;
  final double size;
  const _YrAvatar({required this.url, required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: s.primaryContainer,
      child: Text(label.isEmpty ? '?' : label.characters.first.toUpperCase(),
          style: TextStyle(color: s.onPrimaryContainer, fontSize: size * 0.42, fontWeight: FontWeight.w900)),
    );
    // Shape follows the app setting (cookie, circle, square, mix)
    return M3ShapedBox(
      size: size,
      seed: label,
      child: url.isEmpty
          ? fallback
          : ImageService.widgetImage(url: url, width: size, height: size, fit: BoxFit.cover, errorWidget: fallback),
    );
  }
}

// Fade + slide + scale-in after a delay. [pop] adds an overshoot (the reveal
// of a #1). Replays each time its slide is built, i.e. each time it is shown.
class _YrReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final bool pop;
  const _YrReveal({required this.child, this.delayMs = 0, this.pop = false});

  @override
  State<_YrReveal> createState() => _YrRevealState();
}

class _YrRevealState extends State<_YrReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: widget.pop ? 750 : 520));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (_yrInstant) {
      _c.value = 1;
      return;
    }
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    final scale = Tween<double>(begin: widget.pop ? 0.5 : 0.94, end: 1)
        .animate(CurvedAnimation(parent: _c, curve: widget.pop ? Curves.easeOutBack : Curves.easeOutCubic));
    final slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: ScaleTransition(scale: scale, child: widget.child)),
    );
  }
}

// Number that counts up from 0 after a delay.
class _YrCountUp extends StatefulWidget {
  final int value;
  final String Function(int) fmt;
  final TextStyle style;
  final int delayMs;
  final int durationMs;
  const _YrCountUp({required this.value, required this.fmt, required this.style, this.delayMs = 0, this.durationMs = 1200});

  @override
  State<_YrCountUp> createState() => _YrCountUpState();
}

class _YrCountUpState extends State<_YrCountUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: widget.durationMs));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (_yrInstant) {
      _c.value = 1;
      return;
    }
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Text(widget.fmt((widget.value * v).round()), textAlign: TextAlign.center, style: widget.style);
      },
    );
  }
}

// One story slide: centred column that fades/slides in when first shown.
class _YrSlide extends StatelessWidget {
  final ColorScheme scheme;
  final List<Widget> children;
  final bool compact;
  const _YrSlide({required this.scheme, required this.children, this.compact = false});

  @override
  Widget build(BuildContext context) {
    // Share frame: natural height (the card scales it), small side margins
    if (_yrInstant) {
      return Padding(
        padding: EdgeInsets.fromLTRB(8, compact ? 36 : 66, 8, 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _yrInstant ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 40),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
          ),
        ),
      ),
    );
  }
}

// Artwork resolved through the same ImageService chain as the rest of the app.
class _YrImg extends StatefulWidget {
  final String name, artist, type; // type: artists | tracks | albums
  final double size;
  final bool round;
  final int? shapeIndex;
  final ValueNotifier<bool>? spin;
  const _YrImg({required this.name, required this.artist, required this.type, required this.size, this.round = false, this.shapeIndex, this.spin});

  @override
  State<_YrImg> createState() => _YrImgState();
}

class _YrImgState extends State<_YrImg> {
  late final Future<String> _future = switch (widget.type) {
    'artists' => ImageService.resolveArtist(widget.name),
    'albums' => ImageService.resolveAlbum(widget.name, widget.artist),
    _ => ImageService.resolveTrack(widget.name, widget.artist),
  };

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final fallback = Container(
      width: widget.size,
      height: widget.size,
      color: s.primaryContainer,
      child: Icon(
        widget.type == 'artists' ? Icons.person_rounded : (widget.type == 'albums' ? Icons.album_rounded : Icons.music_note_rounded),
        color: _yrSoft(s),
        size: widget.size * 0.5,
      ),
    );
    if (widget.shapeIndex != null) {
      // Static image, only the shape turns (image oversized so no corner shows)
      final big = widget.size * 1.45;
      return _YrSpinClip(
        size: widget.size,
        shapeIndex: widget.shapeIndex!,
        spin: widget.spin,
        child: FutureBuilder<String>(
          future: _future,
          builder: (_, snap) {
            final url = snap.data ?? '';
            if (url.isEmpty) {
              return SizedBox(width: big, height: big, child: ColoredBox(color: s.primaryContainer, child: Icon(
                widget.type == 'artists' ? Icons.person_rounded : (widget.type == 'albums' ? Icons.album_rounded : Icons.music_note_rounded),
                color: _yrSoft(s), size: widget.size * 0.5)));
            }
            return ImageService.widgetImage(url: url, width: big, height: big, fit: BoxFit.cover, errorWidget: fallback);
          },
        ),
      );
    }
    // Shape follows the app setting, same seed rule as the recap tabs
    return M3ShapedBox(
      size: widget.size,
      seed: widget.name,
      child: FutureBuilder<String>(
        future: _future,
        builder: (_, snap) {
          final url = snap.data ?? '';
          if (url.isEmpty) return fallback;
          return ImageService.widgetImage(url: url, width: widget.size, height: widget.size, fit: BoxFit.cover, errorWidget: fallback);
        },
      ),
    );
  }
}

// Fixed-size portrait card, exported as a PNG by the share button.
class _YrShareCard extends StatelessWidget {
  final ColorScheme scheme;
  final int year;
  final String username;
  final _YrData data;
  final int hours;
  final String Function(int) fmt;
  final String? rankLine; // friends ranking, when known
  final bool photoDark; // dark picture -> white header text
  final Widget? slide; // single-slide share: this slide is shown instead of the lists
  final Uint8List? photo; // profile picture bytes shown as background (null = theme gradient)
  const _YrShareCard({required this.scheme, required this.year, required this.username, required this.data, required this.hours, required this.fmt, this.rankLine, this.photo, this.photoDark = false, this.slide});

  Widget _stat(String label, String value) => Expanded(child: ShareTile(label: label, value: value));

  Widget _list(String title, List<_YrRanked> items, String type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ShareLabel(title),
      const SizedBox(height: 6),
      for (var i = 0; i < items.length && i < 3; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            ShareRank(n: i + 1, size: 22),
            const SizedBox(width: 8),
            _YrImg(name: items[i].name, artist: items[i].artist, type: type, size: 36, round: type == 'artists'),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(items[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurface, fontSize: 13, fontWeight: FontWeight.w800)),
                // Artist (tracks/albums) + play count
                Text(
                  [if (items[i].artist.isNotEmpty) items[i].artist, tx('yr_plays', {'n': fmt(items[i].count)})].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _yrSoft(scheme), fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        // Profile picture as background, fading into the card colour
        if (photo != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 170, // top quarter of the card
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xE6000000), Color(0x00000000)],
              ).createShader(r),
              // Full square picture, cropped to the top band (never stretched)
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 360,
                  maxWidth: 360,
                  minHeight: 360,
                  maxHeight: 360,
                  alignment: Alignment.center,
                  child: Image.memory(photo!, width: 360, height: 360, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => const SizedBox()),
                ),
              ),
            ),
          ),
        if (photo != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 170,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x73000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        if (photo == null) ...[
          Positioned(top: -60, right: -60, child: ShareBlob(size: 200, color: scheme.primary.withValues(alpha: 0.10))),
          Positioned(bottom: 90, left: -80, child: ShareBlob(size: 170, lobes: 12, color: scheme.tertiary.withValues(alpha: 0.08))),
        ],
        Container(
        width: 360,
        height: 640, // 9:16 (story format), exported at 3x = 1080x1920
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
        decoration: photo != null
            ? null
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primaryContainer, scheme.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.45],
                ),
              ),
        // FittedBox shrinks the content if it is ever taller than the card
        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.topCenter, child: SizedBox(width: 332, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (slide != null) const SizedBox(height: 28),
          Text(displayNameNotifier.value.trim().isNotEmpty ? displayNameNotifier.value.trim() : username, style: TextStyle(color: photo == null ? _yrSoft(scheme) : (photoDark ? Colors.white : const Color(0xFF111111)), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(tx('yr_intro_h', {'year': '$year'}), style: TextStyle(color: photo == null ? scheme.onSurface : (photoDark ? Colors.white : const Color(0xFF111111)), fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 10),
          if (slide != null)
            SizedBox(
              height: 452,
              width: 332,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: (slide is _YrSlide && (slide as _YrSlide).compact) ? Alignment.topCenter : Alignment.center,
                child: SizedBox(width: 332, child: slide),
              ),
            )
          else ...[
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _stat(tx('yr_scrobbles'), fmt(data.total)),
            const SizedBox(width: 8),
            _stat(tx('yr_card_hours').replaceAll(RegExp(r'\s*[\(（][^\)）]*[\)）]'), ''), fmt(hours)),
            const SizedBox(width: 8),
            _stat(tx('yr_card_streak'), '${data.longestStreak}'),
          ])),
          const SizedBox(height: 10),
          _list(tx('yr_top_artists'), data.artists, 'artists'),
          const SizedBox(height: 10),
          _list(tx('yr_top_tracks'), data.tracks, 'tracks'),
          const SizedBox(height: 10),
          _list(tx('yr_top_albums'), data.albums, 'albums'),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.bottomRight,
            child: ShareMark(color: _yrSoft(scheme).withValues(alpha: 0.7)),
          ),
        ]))),
      ),
      ]),
    );
  }
}


// Clips a static child with a shape that rotates while [spin] is true.
class _YrSpinClip extends StatefulWidget {
  final double size;
  final int shapeIndex;
  final ValueNotifier<bool>? spin;
  final Widget child;
  const _YrSpinClip({required this.size, required this.shapeIndex, required this.child, this.spin});

  @override
  State<_YrSpinClip> createState() => _YrSpinClipState();
}

class _YrSpinClipState extends State<_YrSpinClip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 10));

  void _sync() {
    if (widget.spin?.value == true) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.spin?.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    widget.spin?.removeListener(_sync);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = widget.size;
    // When it turns, the shape is drawn smaller so it never leaves its box (no overlap with the text)
    final inner = widget.spin != null ? sz * 0.74 : sz;
    return SizedBox(
      width: sz, height: sz,
      child: Center(
        child: ClipPath(
          clipper: _YrRotClipper(m3ImageShape(widget.shapeIndex, inner), _c),
          child: SizedBox(
            width: inner, height: inner,
            child: OverflowBox(minWidth: 0, minHeight: 0, maxWidth: sz * 1.45, maxHeight: sz * 1.45, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _YrRotClipper extends CustomClipper<Path> {
  final ShapeBorder shape;
  final Animation<double> anim;
  _YrRotClipper(this.shape, this.anim) : super(reclip: anim);

  @override
  Path getClip(Size size) {
    final path = shape.getOuterPath(Offset.zero & size);
    final c = size.center(Offset.zero);
    final m = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..rotateZ(anim.value * 2 * math.pi)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
    return path.transform(m.storage);
  }

  @override
  bool shouldReclip(covariant _YrRotClipper old) => old.shape != shape;
}
