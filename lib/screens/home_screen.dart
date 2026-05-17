import 'dart:async';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../services/lastfm_service.dart';
import '../services/image_service.dart';
import '../services/update_service.dart';
import 'setup_screen.dart';

// ─── Constantes ──────────────────────────────────────────────────────────────
const _kPeriods = [
  ('7day',    'Semaine'),
  ('1month',  'Mois'),
  ('3month',  '3 mois'),
  ('6month',  '6 mois'),
  ('12month', 'Année'),
  ('overall', 'Tout'),
];

const _kMonths = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];

// Source de l'image d'en-tête : 'none' | 'top_artist' | 'top_album' | 'top_track' | 'nowplaying'
const _kHeaderSources = [
  ('nowplaying',  'Musique en cours',  Icons.play_circle_rounded),
  ('top_track',   'Titre #1',          Icons.music_note_rounded),
  ('top_album',   'Album #1',          Icons.album_rounded),
  ('top_artist',  'Artiste #1',        Icons.mic_rounded),
  ('none',        'Couleur du thème',  Icons.palette_rounded),
];


// Presets d'accent : (Color, key, label)
const _kAccentOptions = [
  (Color(0xFF7C3AED), 'purple', 'Violet'),
  (Color(0xFF1D4ED8), 'blue',   'Bleu'),
  (Color(0xFF059669), 'green',  'Vert'),
  (Color(0xFFDC2626), 'red',    'Rouge'),
  (Color(0xFFD97706), 'orange', 'Orange'),
  (Color(0xFFDB2777), 'pink',   'Rose'),
  (Color(0xFF0F766E), 'teal',   'Sarcelle'),
];

// ─── Helper global : bordure subtile pour toutes les cards ─────────────────
// Résout le problème Material You où les cards sont invisibles sans contour.
BorderSide _cardBorder(ColorScheme s, {double alpha = 0.45}) =>
    BorderSide(color: s.outlineVariant.withValues(alpha: alpha), width: 1);

// ═══════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final String username;
  final String apiKey;
  final int    startupTab;
  const HomeScreen({
    super.key,
    required this.username,
    required this.apiKey,
    this.startupTab = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _idx;
  late final LastFmService _service;

  @override
  void initState() {
    super.initState();
    _idx     = widget.startupTab.clamp(0, 4);
    _service = LastFmService(apiKey: widget.apiKey, username: widget.username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: [
        _DashboardPage(service: _service, username: widget.username),
        _RankingsPage(service: _service),
        _ChartsPage(service: _service),
        _HistoryPage(service: _service),
        _SettingsPage(username: widget.username),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon:         Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Classements',
          ),
          NavigationDestination(
            icon:         Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph_rounded),
            label: 'Graphiques',
          ),
          NavigationDestination(
            icon:         Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
          NavigationDestination(
            icon:         Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════
class _DashboardPage extends StatefulWidget {
  final LastFmService service;
  final String username;
  const _DashboardPage({required this.service, required this.username});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  Map<String, dynamic>? _userInfo;
  List<dynamic> _topArtists   = [];
  List<dynamic> _topAlbums    = [];
  List<dynamic> _topTracks    = [];
  List<dynamic> _recentTracks = [];
  Map<String, dynamic>? _nowPlaying;

  bool _loading = true;
  String? _error;
  Timer? _npTimer;

  String _headerSource = 'nowplaying'; // nouvelle pref
  String _headerImageUrl = '';         // URL résolue pour le header
  bool   _showNowPlay = true;
  bool   _showStats   = true;
  bool   _showArtists = true;
  bool   _showTracks  = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) => _load());
    _npTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshNP());
  }

  @override
  void dispose() { _npTimer?.cancel(); super.dispose(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _headerSource = p.getString('ls_header_source') ?? 'nowplaying';
      _showNowPlay  = p.getBool('ls_show_nowplay')    ?? true;
      _showStats    = p.getBool('ls_show_stats')      ?? true;
      _showArtists  = p.getBool('ls_show_artists')    ?? true;
      _showTracks   = p.getBool('ls_show_tracks')     ?? true;
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        widget.service.getUserInfo(),
        widget.service.getTopArtists(period: 'overall', limit: 50),
        widget.service.getTopAlbums (period: 'overall', limit: 50),
        widget.service.getTopTracks (period: 'overall', limit: 50),
        widget.service.getRecentTracks(limit: 10),
        widget.service.getNowPlaying(),
      ]);
      final recentRaw = (res[4] as Map<String, dynamic>)['track'];
      final allRecent = recentRaw is List ? recentRaw
          : (recentRaw != null ? [recentRaw] : <dynamic>[]);
      Map<String, dynamic>? np;
      final recentF = <dynamic>[];
      for (final t in allRecent) {
        if ((t as Map?)?['@attr']?['nowplaying'] == 'true') np = t as Map<String, dynamic>;
        else recentF.add(t);
      }
      setState(() {
        _userInfo     = res[0] as Map<String, dynamic>?;
        _topArtists   = res[1] as List<dynamic>;
        _topAlbums    = res[2] as List<dynamic>;
        _topTracks    = res[3] as List<dynamic>;
        _recentTracks = recentF;
        _nowPlaying   = np ?? res[5] as Map<String, dynamic>?;
        _loading      = false;
      });
      if (_nowPlaying != null) _extractColor(_nowPlaying!);
      _resolveHeaderImage();
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _refreshNP() async {
    try {
      final np = await widget.service.getNowPlaying();
      if (mounted) {
        setState(() => _nowPlaying = np);
        if (np != null) _extractColor(np);
        _resolveHeaderImage();
      }
    } catch (_) {}
  }

  Future<void> _resolveHeaderImage() async {
    String url = '';
    switch (_headerSource) {
      case 'nowplaying':
        if (_nowPlaying != null) {
          final raw = _extractImage(_nowPlaying!['image']);
          url = await ImageService.resolveTrack(
            (_nowPlaying!['name'] ?? '').toString(),
            (_nowPlaying!['artist']?['#text'] ?? '').toString(),
            lastfmUrl: raw,
          );
        }
      case 'top_track':
        if (_topTracks.isNotEmpty) {
          final t = _topTracks[0] as Map;
          url = await ImageService.resolveTrack(
            (t['name'] ?? '').toString(),
            (t['artist']?['name'] ?? '').toString(),
            lastfmUrl: _extractImage(t['image']),
          );
        }
      case 'top_album':
        if (_topAlbums.isNotEmpty) {
          final a = _topAlbums[0] as Map;
          url = await ImageService.resolveAlbum(
            (a['name'] ?? '').toString(),
            (a['artist']?['name'] ?? '').toString(),
            lastfmUrl: _extractImage(a['image']),
          );
        }
      case 'top_artist':
        if (_topArtists.isNotEmpty) {
          final a = _topArtists[0] as Map;
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

  // ── Calculs stats ──────────────────────────────────────────────────────
  int    _total()    => int.tryParse((_userInfo?['playcount'] ?? '0').toString()) ?? 0;
  int    _days()     {
    final raw = _userInfo?['registered'];
    if (raw == null) return 0;
    int ts = 0;
    if (raw is Map) ts = int.tryParse((raw['#text'] ?? raw['unixtime'] ?? '0').toString()) ?? 0;
    else ts = int.tryParse(raw.toString()) ?? 0;
    if (ts <= 0) return 0;
    return ((DateTime.now().millisecondsSinceEpoch / 1000 - ts) / 86400).floor();
  }
  double _avg()      { final d = _days(); return d > 0 ? _total() / d : 0; }
  int    _weekly()   => (_avg() * 7).round();
  String _regDate()  {
    final raw = _userInfo?['registered'];
    if (raw == null) return '';
    int ts = 0;
    if (raw is Map) ts = int.tryParse((raw['#text'] ?? raw['unixtime'] ?? '0').toString()) ?? 0;
    else ts = int.tryParse(raw.toString()) ?? 0;
    if (ts <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.day} ${_kMonths[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error   != null) return _ErrorView(message: _error!, onRetry: _load);

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

        // ── AppBar profil — couverture plein-écran ────────
        SliverAppBar(
          expandedHeight: 230,
          pinned: true,
          stretch: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: 'Actualiser',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                // ── Image de fond (pochette ou dégradé) ──
                if (_headerImageUrl.isNotEmpty)
                  Image.network(
                    _headerImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _GradientHeader(scheme: scheme),
                  )
                else
                  _GradientHeader(scheme: scheme),

                // ── Overlay foncé en bas pour lisibilité ──
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Contenu profil ────────────────────────
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
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  shadows: [Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                  )],
                                )),
                              if (realName.isNotEmpty)
                                Text(realName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    shadows: const [Shadow(
                                      color: Colors.black45, blurRadius: 4)],
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
                                      shadows: const [Shadow(
                                        color: Colors.black45, blurRadius: 4)],
                                    )),
                                  const SizedBox(width: 8),
                                ],
                                if (regStr.isNotEmpty) ...[
                                  Icon(Icons.calendar_today_outlined,
                                      size: 11,
                                      color: Colors.white.withValues(alpha: 0.75)),
                                  const SizedBox(width: 2),
                                  Text('Depuis $regStr',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 12,
                                      shadows: const [Shadow(
                                        color: Colors.black45, blurRadius: 4)],
                                    )),
                                ],
                              ]),
                            ],
                          )),
                        ]),
                        const SizedBox(height: 10),
                        // Pill scrobbles
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${_fmtFull(total)} scrobbles',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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

              // ── Now Playing ──────────────────────────────
              if (_showNowPlay && _nowPlaying != null) ...[
                _NowPlayingCard(track: _nowPlaying!),
                const SizedBox(height: 14),
              ],

              // ── Bloc statistiques ─────────────────────────
              if (_showStats) ...[
                _SectionHeader(title: 'Statistiques', icon: Icons.bar_chart_rounded),
                const SizedBox(height: 10),

                // HERO : scrobbles totaux — pleine largeur
                _HeroStatCard(
                  total: total,
                  avg: avg.round(),
                  days: days,
                  weekly: weekly,
                  regStr: regStr,
                ),

                const SizedBox(height: 10),

                // GRILLE 2×3 : stats secondaires
                _StatGrid(children: [
                  _DashStatCard(
                    emoji: '🎤',
                    value: topArtist != null ? (topArtist['name'] ?? '—').toString() : '—',
                    label: 'Artiste #1',
                    sub:   topArtist != null
                        ? '${_fmt(int.tryParse((topArtist['playcount'] ?? '0').toString()) ?? 0)} écoutes'
                        : null,
                  ),
                  _DashStatCard(
                    emoji: '💿',
                    value: topAlbum != null ? (topAlbum['name'] ?? '—').toString() : '—',
                    label: 'Album #1',
                    sub:   topAlbum != null
                        ? (topAlbum['artist']?['name'] ?? '').toString()
                        : null,
                  ),
                  _DashStatCard(
                    emoji: '🎵',
                    value: topTrack != null ? (topTrack['name'] ?? '—').toString() : '—',
                    label: 'Titre #1',
                    sub:   topTrack != null
                        ? '${_fmt(int.tryParse((topTrack['playcount'] ?? '0').toString()) ?? 0)} écoutes'
                        : null,
                  ),
                  _DashStatCard(
                    emoji: '⏱️',
                    value: lastTrack != null ? (lastTrack['name'] ?? '—').toString() : '—',
                    label: 'Dernière écoute',
                    sub:   lastTrack != null ? _fmtDate(lastTrack['date']?['#text'] ?? '') : null,
                  ),
                ]),

                const SizedBox(height: 20),
              ],

              // ── Top Artistes (mini) ───────────────────────
              if (_showArtists && _topArtists.isNotEmpty) ...[
                _SectionHeader(title: 'Top Artistes', icon: Icons.mic_rounded),
                const SizedBox(height: 8),
                ..._topArtists.take(5).toList().asMap().entries.map((e) => _ItemTile(
                  name:     (e.value['name'] ?? '').toString(),
                  sub:      '${_fmt(int.tryParse((e.value['playcount'] ?? '0').toString()) ?? 0)} écoutes',
                  imageUrl: _extractImage(e.value['image']),
                  imageFuture: ImageService.resolveArtist((e.value['name'] ?? '').toString(),
                      lastfmUrl: _extractImage(e.value['image'])),
                  rank: '${e.key + 1}',
                )),
                const SizedBox(height: 20),
              ],

              // ── Top Titres (mini) ─────────────────────────
              if (_showTracks && _topTracks.isNotEmpty) ...[
                _SectionHeader(title: 'Top Titres', icon: Icons.music_note_rounded),
                const SizedBox(height: 8),
                ..._topTracks.take(5).toList().asMap().entries.map((e) {
                  final tName  = (e.value['name'] ?? '').toString();
                  final artist = (e.value['artist']?['name'] ?? '').toString();
                  return _ItemTile(
                    name:     tName,
                    sub:      artist,
                    imageUrl: _extractImage(e.value['image']),
                    imageFuture: ImageService.resolveTrack(tName, artist,
                        lastfmUrl: _extractImage(e.value['image'])),
                    rank:  '${e.key + 1}',
                    plays: _fmt(int.tryParse((e.value['playcount'] ?? '0').toString()) ?? 0),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Dégradé de fallback pour le header ──────────────────────────────────────
class _GradientHeader extends StatelessWidget {
  final ColorScheme scheme;
  const _GradientHeader({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.secondary,
            scheme.tertiary,
          ],
        ),
      ),
    );
  }
}

// ─── Nombre complet avec séparateur millier ───────────────────────────────────
String _fmtFull(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ─── Hero stat card (pleine largeur) ─────────────────────────────────────────

class _HeroStatCard extends StatelessWidget {
  final int total, avg, days, weekly;
  final String regStr;
  const _HeroStatCard({required this.total, required this.avg, required this.days,
      required this.weekly, required this.regStr});

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
          // Ligne principale
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('🎯', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Text(_fmt(total),
                style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onPrimaryContainer,
                    height: 1)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('scrobbles',
                  style: text.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 14),
          // Sous-métriques
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniMetric('⚡', '~${_fmt(avg)}', 'par jour', scheme.onPrimaryContainer),
                _vDivider(scheme.onPrimaryContainer),
                _MiniMetric('📅', '~${_fmt(weekly)}', 'par semaine', scheme.onPrimaryContainer),
                _vDivider(scheme.onPrimaryContainer),
                _MiniMetric('🗓️', '$days j', 'd\'activité', scheme.onPrimaryContainer),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _vDivider(Color c) => Container(
      width: 1, height: 32,
      color: c.withValues(alpha: 0.15));
}

class _MiniMetric extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _MiniMetric(this.emoji, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 2),
      Text(value, style: text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800, color: color)),
      Text(label, style: text.labelSmall?.copyWith(
          color: color.withValues(alpha: 0.65))),
    ]);
  }
}

// ─── Grille 2 colonnes ────────────────────────────────────────────────────────
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

// ─── Stat card secondaire ─────────────────────────────────────────────────────
class _DashStatCard extends StatelessWidget {
  final String emoji, value, label;
  final String? sub;
  const _DashStatCard({required this.emoji, required this.value,
      required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _cardBorder(scheme),           // ← contour toujours visible
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800, color: scheme.onSurface)),
          Text(label, style: text.bodySmall?.copyWith(
              color: scheme.primary, fontWeight: FontWeight.w600)),
          if (sub != null)
            Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOW PLAYING CARD
// ═══════════════════════════════════════════════════════════════════════════
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
          _SmartImage(size: 52, borderRadius: 10, initialUrl: rawUrl,
              resolver: () => ImageService.resolveTrack(title, artist,
                  lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 7, height: 7,
                  decoration: BoxDecoration(color: scheme.secondary, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('EN COURS', style: text.labelSmall?.copyWith(
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

// ═══════════════════════════════════════════════════════════════════════════
// CLASSEMENTS — podium + liste
// ═══════════════════════════════════════════════════════════════════════════
class _RankingsPage extends StatefulWidget {
  final LastFmService service;
  const _RankingsPage({required this.service});

  @override
  State<_RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<_RankingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _period = 'overall';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('Classements', style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              children: _kPeriods.map((p) {
                final sel = p.$1 == _period;
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(label: Text(p.$2), selected: sel,
                      onSelected: (_) { if (!sel) setState(() => _period = p.$1); }));
              }).toList(),
            ),
          ),
          TabBar(controller: _tabs, tabs: const [
            Tab(text: 'Artistes'), Tab(text: 'Albums'), Tab(text: 'Titres'),
          ]),
          Expanded(child: TabBarView(controller: _tabs, children: [
            _TopListBody(service: widget.service, type: 'artists', period: _period),
            _TopListBody(service: widget.service, type: 'albums',  period: _period),
            _TopListBody(service: widget.service, type: 'tracks',  period: _period),
          ])),
        ]),
      ),
    );
  }
}

class _TopListBody extends StatefulWidget {
  final LastFmService service;
  final String type, period;
  const _TopListBody({required this.service, required this.type, required this.period});

  @override
  State<_TopListBody> createState() => _TopListBodyState();
}

class _TopListBodyState extends State<_TopListBody>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _items = [];
  bool _loading = true, _loadingMore = false, _exhausted = false;
  String? _error;
  int _page = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(reset: true); }

  @override
  void didUpdateWidget(_TopListBody old) {
    super.didUpdateWidget(old);
    if (old.period != widget.period || old.type != widget.type) _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _exhausted = false; _items = []; });
    } else {
      if (_loadingMore || _exhausted) return;
      setState(() => _loadingMore = true);
    }
    try {
      List<dynamic> fresh;
      switch (widget.type) {
        case 'artists':
          fresh = await widget.service.getTopArtists(period: widget.period, limit: 50, page: _page); break;
        case 'albums':
          fresh = await widget.service.getTopAlbums(period: widget.period,  limit: 50, page: _page); break;
        default:
          fresh = await widget.service.getTopTracks(period: widget.period,  limit: 50, page: _page);
      }
      if (mounted) setState(() {
        _items.addAll(fresh); _exhausted = fresh.length < 50;
        _loading = false; _loadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false; _loadingMore = false;
      });
    }
  }

  void _showDetail(BuildContext ctx, Map<String, dynamic> item) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ItemDetailSheet(item: item, type: widget.type, service: widget.service));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    if (_loading)    return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: () => _load(reset: true));
    if (_items.isEmpty) return Center(child: Text('Aucun résultat',
        style: TextStyle(color: scheme.onSurfaceVariant)));

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!_exhausted && !_loadingMore && n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          _page++; _load();
        }
        return false;
      },
      child: CustomScrollView(slivers: [
        if (_items.length >= 3)
          SliverToBoxAdapter(child: _PodiumWidget(
              items: _items.take(3).toList(), type: widget.type,
              onTap: (item) => _showDetail(context, item as Map<String, dynamic>))),

        SliverList(delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final off = _items.length >= 3 ? 3 : 0;
            final idx = i + off;
            if (idx >= _items.length) {
              return _loadingMore ? const Padding(padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator())) : const SizedBox.shrink();
            }
            final item   = _items[idx] as Map<String, dynamic>;
            final name   = (item['name'] ?? '').toString();
            final plays  = _fmt(int.tryParse((item['playcount'] ?? '0').toString()) ?? 0);
            final artist = (item['artist']?['name'] ?? '').toString();
            final raw    = _extractImage(item['image']);
            Future<String> imgF;
            switch (widget.type) {
              case 'artists': imgF = ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              case 'albums':  imgF = ImageService.resolveAlbum(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              default:        imgF = ImageService.resolveTrack(name, artist, lastfmUrl: raw.isNotEmpty ? raw : null);
            }
            return InkWell(
              onTap: () => _showDetail(ctx, item),
              borderRadius: BorderRadius.circular(8),
              child: _ItemTile(
                name: name, imageUrl: raw, imageFuture: imgF, rank: '${idx + 1}',
                sub:   widget.type != 'artists' ? '$artist · $plays écoutes' : '$plays écoutes',
                plays: widget.type != 'artists' ? plays : null,
              ),
            );
          },
          childCount: (_items.length >= 3 ? _items.length - 3 : _items.length) + 1,
        )),
      ]),
    );
  }
}

// ─── Podium ──────────────────────────────────────────────────────────────────
class _PodiumWidget extends StatelessWidget {
  final List<dynamic> items;
  final String type;
  final void Function(dynamic) onTap;
  const _PodiumWidget({required this.items, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    const order   = [1, 0, 2];
    const heights = [100.0, 130.0, 80.0];
    const medals  = ['🥈', '🥇', '🥉'];
    const imgSz   = [54.0, 68.0, 46.0];

    final podiumColors = [
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.primaryContainer,   scheme.onPrimaryContainer),
      (scheme.tertiaryContainer,  scheme.onTertiaryContainer),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(title: 'Podium', icon: Icons.emoji_events_rounded),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (col) {
            final di   = order[col];
            final item = items[di] as Map<String, dynamic>;
            final name = (item['name'] ?? '').toString();
            final art  = type != 'artists' ? (item['artist']?['name'] ?? '').toString() : '';
            final plays = _fmt(int.tryParse((item['playcount'] ?? '0').toString()) ?? 0);
            final raw  = _extractImage(item['image']);
            Future<String> imgF;
            switch (type) {
              case 'artists': imgF = ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              case 'albums':  imgF = ImageService.resolveAlbum(name, art, lastfmUrl: raw.isNotEmpty ? raw : null); break;
              default:        imgF = ImageService.resolveTrack(name, art, lastfmUrl: raw.isNotEmpty ? raw : null);
            }
            final (podC, podOn) = podiumColors[di];

            return Expanded(child: GestureDetector(
              onTap: () => onTap(item),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(imgSz[col] / 4),
                  child: _SmartImage(size: imgSz[col], borderRadius: imgSz[col] / 4,
                      initialUrl: raw, resolver: () => imgF),
                ),
                const SizedBox(height: 5),
                Text(medals[col], style: TextStyle(fontSize: di == 0 ? 22 : 18)),
                const SizedBox(height: 3),
                // Socle
                Container(
                  width: double.infinity,
                  height: heights[col],
                  decoration: BoxDecoration(
                    color: podC,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(
                      top:   BorderSide(color: podOn.withValues(alpha: 0.15), width: 1),
                      left:  BorderSide(color: podOn.withValues(alpha: 0.15), width: 1),
                      right: BorderSide(color: podOn.withValues(alpha: 0.15), width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.all(7),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: podOn.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('#${di + 1}', style: text.labelSmall?.copyWith(
                          color: podOn, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 3),
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                            color: podOn, fontWeight: FontWeight.w700, fontSize: di == 0 ? 11 : 10)),
                    if (heights[col] >= 100) ...[
                      const SizedBox(height: 2),
                      Text(plays, style: text.bodySmall
                          ?.copyWith(color: podOn.withValues(alpha: 0.65), fontSize: 9)),
                    ],
                  ]),
                ),
              ]),
            ));
          }),
        ),
        const SizedBox(height: 12),
        Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
          child: Text('Suite du classement',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _PeriodStats { final int rank, playcount; const _PeriodStats({required this.rank, required this.playcount}); }

class _ItemDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String type;
  final LastFmService service;
  const _ItemDetailSheet({required this.item, required this.type, required this.service});

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  String _period = 'overall';
  final Map<String, _PeriodStats?> _cache = {};
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadPeriod('overall'); }

  Future<void> _loadPeriod(String period) async {
    if (_cache.containsKey(period)) { setState(() => _period = period); return; }
    setState(() { _period = period; _loading = true; });
    final name = (widget.item['name'] ?? '').toString();
    final art  = widget.type != 'artists' ? (widget.item['artist']?['name'] ?? '').toString() : '';
    try {
      List<dynamic> items;
      if (widget.type == 'artists')     items = await widget.service.getTopArtists(period: period, limit: 200);
      else if (widget.type == 'albums') items = await widget.service.getTopAlbums(period: period,  limit: 200);
      else                              items = await widget.service.getTopTracks(period: period,   limit: 200);
      int rank = -1, plays = 0;
      for (var i = 0; i < items.length; i++) {
        final n = (items[i]['name'] ?? '').toString();
        final a = widget.type != 'artists' ? (items[i]['artist']?['name'] ?? '').toString() : '';
        if (n == name && (widget.type == 'artists' || a == art)) {
          rank = i + 1; plays = int.tryParse((items[i]['playcount'] ?? '0').toString()) ?? 0; break;
        }
      }
      setState(() { _cache[period] = _PeriodStats(rank: rank, playcount: plays); _loading = false; });
    } catch (_) {
      setState(() { _cache[period] = _PeriodStats(rank: -1, playcount: 0); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final name   = (widget.item['name'] ?? '').toString();
    final art    = widget.type != 'artists' ? (widget.item['artist']?['name'] ?? '').toString() : '';
    final raw    = _extractImage(widget.item['image']);
    final stats  = _cache[_period];
    final plabel = _kPeriods.firstWhere((p) => p.$1 == _period, orElse: () => (_period, _period)).$2;

    Future<String> imgF;
    switch (widget.type) {
      case 'artists': imgF = ImageService.resolveArtist(name, lastfmUrl: raw.isNotEmpty ? raw : null); break;
      case 'albums':  imgF = ImageService.resolveAlbum(name, art, lastfmUrl: raw.isNotEmpty ? raw : null); break;
      default:        imgF = ImageService.resolveTrack(name, art, lastfmUrl: raw.isNotEmpty ? raw : null);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.55, minChildSize: 0.35, maxChildSize: 0.85, expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top:  BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            left: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            right: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
        child: Column(children: [
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(children: [
              _SmartImage(size: 68, borderRadius: 12, initialUrl: raw, resolver: () => imgF),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                if (art.isNotEmpty) Text(art, style: text.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(switch (widget.type) {'artists'=>'Artiste','albums'=>'Album',_=>'Titre'},
                      style: text.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
                ),
              ])),
            ])),
          const Divider(height: 20),
          SizedBox(height: 44, child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            children: _kPeriods.map((p) => Padding(padding: const EdgeInsets.only(right: 8),
              child: FilterChip(label: Text(p.$2), selected: p.$1 == _period,
                  showCheckmark: false, onSelected: (_) => _loadPeriod(p.$1)))).toList(),
          )),
          const SizedBox(height: 12),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: stats == null ? const SizedBox.shrink()
                      : Column(children: [
                          if (stats.rank > 0 && stats.rank <= 200)
                            _SheetStatCard(
                              icon: Icons.leaderboard_rounded, value: '#${stats.rank}',
                              label: 'Classement · $plabel',
                              color: scheme.primaryContainer, onColor: scheme.onPrimaryContainer),
                          const SizedBox(height: 12),
                          _SheetStatCard(
                            icon: Icons.headphones_rounded, value: _fmt(stats.playcount),
                            label: 'Écoutes · $plabel',
                            color: scheme.secondaryContainer, onColor: scheme.onSecondaryContainer),
                          if (stats.rank == -1 || stats.rank > 200)
                            Padding(padding: const EdgeInsets.only(top: 16),
                              child: Text('Non classé dans le top 200 pour cette période.',
                                  textAlign: TextAlign.center,
                                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
                        ]))),
        ]),
      ),
    );
  }
}

class _SheetStatCard extends StatelessWidget {
  final IconData icon; final String value, label; final Color color, onColor;
  const _SheetStatCard({required this.icon, required this.value, required this.label,
      required this.color, required this.onColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0, color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: _cardBorder(scheme)),
      child: Padding(padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, color: onColor, size: 32),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: onColor)),
            Text(label, style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: onColor.withValues(alpha: 0.8))),
          ]),
        ])),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRAPHIQUES
// ═══════════════════════════════════════════════════════════════════════════
class _ChartsPage extends StatefulWidget {
  final LastFmService service; const _ChartsPage({required this.service});

  @override
  State<_ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<_ChartsPage> with AutomaticKeepAliveClientMixin {
  Map<String, int>? _monthly;
  List<dynamic> _topArtists = [];
  bool _loading = true; String? _error;
  bool _gemsLoading = false; List<_GemEntry> _gems = [];

  @override bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        widget.service.getMonthlyScrobbles(months: 12),
        widget.service.getTopArtists(period: 'overall', limit: 10),
      ]);
      setState(() {
        _monthly    = res[0] as Map<String, int>;
        _topArtists = res[1] as List<dynamic>;
        _loading    = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _computeGems() async {
    if (_topArtists.isEmpty) return;
    setState(() { _gemsLoading = true; _gems = []; });
    final artists  = _topArtists.take(15).toList();
    final listeners = await Future.wait(
        artists.map((a) => widget.service.getArtistListeners((a['name'] ?? '').toString())));
    final entries = <_GemEntry>[];
    for (var i = 0; i < artists.length; i++) {
      entries.add(_GemEntry(name: (artists[i]['name'] ?? '').toString(),
          plays: int.tryParse((artists[i]['playcount'] ?? '0').toString()) ?? 0,
          listeners: listeners[i] ?? 0));
    }
    entries.sort((a, b) => a.listeners.compareTo(b.listeners));
    setState(() { _gems = entries; _gemsLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    if (_loading)    return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);

    final monthly = _monthly!;
    final maxVal  = monthly.values.fold(0, (a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Graphiques', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        _SectionHeader(title: 'Scrobbles — 12 mois', icon: Icons.calendar_month_rounded),
        const SizedBox(height: 12),
        Card(
          elevation: 0, color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: _cardBorder(scheme)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: SizedBox(height: 160, child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthly.entries.map((e) {
                final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (ratio > 0) Text(_fmt(e.value), style: text.labelSmall
                        ?.copyWith(fontSize: 8, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Flexible(fit: FlexFit.loose,
                      child: FractionallySizedBox(heightFactor: ratio.clamp(0.02, 1.0),
                        child: Container(decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.45 + ratio * 0.55),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))))),
                    const SizedBox(height: 4),
                    Text(e.key.substring(5), style: text.labelSmall?.copyWith(fontSize: 9)),
                  ]),
                ));
              }).toList(),
            )),
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Top artistes — distribution', icon: Icons.mic_rounded),
        const SizedBox(height: 12),
        if (_topArtists.isNotEmpty) () {
          final mx = _topArtists.map((a) => int.tryParse((a['playcount'] ?? '0').toString()) ?? 0).fold(0, (a,b) => a>b?a:b);
          return Card(
            elevation: 0, color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: _cardBorder(scheme)),
            child: Padding(padding: const EdgeInsets.all(16),
              child: Column(children: _topArtists.asMap().entries.map((e) {
                final plays = int.tryParse((e.value['playcount'] ?? '0').toString()) ?? 0;
                final ratio = mx > 0 ? plays / mx : 0.0;
                return Padding(padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SizedBox(width: 24, child: Text('${e.key + 1}',
                        textAlign: TextAlign.center, style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: Text((e.value['name'] ?? '').toString(),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Expanded(flex: 5, child: ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: ratio, minHeight: 8,
                          backgroundColor: scheme.primary.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(scheme.primary)))),
                    const SizedBox(width: 8),
                    Text(_fmt(plays), style: text.bodySmall?.copyWith(
                        color: scheme.primary, fontWeight: FontWeight.w600)),
                  ]));
              }).toList()),
            ),
          );
        }(),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Mainstream vs Pépites', icon: Icons.diamond_outlined),
        const SizedBox(height: 8),
        Text('Popularité mondiale de tes artistes favoris.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (_gems.isEmpty && !_gemsLoading)
          FilledButton.icon(onPressed: _computeGems,
              icon: const Icon(Icons.calculate_rounded), label: const Text('Calculer'))
        else if (_gemsLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else ...[
          ..._gems.map((gem) {
            final isGem = gem.listeners < 500000;
            return Card(
              elevation: 0, color: scheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: _cardBorder(scheme)),
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Text(isGem ? '💎' : '🎤', style: const TextStyle(fontSize: 24)),
                title: Text(gem.name, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('${_fmt(gem.listeners)} auditeurs mondiaux',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                trailing: Text(isGem ? 'Pépite' : 'Mainstream',
                    style: text.labelSmall?.copyWith(
                        color: isGem ? scheme.tertiary : scheme.primary, fontWeight: FontWeight.w700)),
              ),
            );
          }),
          Center(child: TextButton(onPressed: _computeGems, child: const Text('Recalculer'))),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _GemEntry { final String name; final int plays, listeners;
  const _GemEntry({required this.name, required this.plays, required this.listeners}); }

// ═══════════════════════════════════════════════════════════════════════════
// HISTORIQUE
// ═══════════════════════════════════════════════════════════════════════════
class _HistoryPage extends StatefulWidget {
  final LastFmService service; const _HistoryPage({required this.service});

  @override
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage> with AutomaticKeepAliveClientMixin {
  List<dynamic> _tracks = [];
  bool _loading = true, _loadingMore = false, _exhausted = false;
  String? _error;
  int _page = 1;
  Map<String, dynamic>? _nowPlaying;
  String _preset = 'all';
  DateTimeRange? _customRange;

  @override bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(reset: true); }

  (int?, int?) _range() {
    final now = DateTime.now();
    switch (_preset) {
      case 'today': final s = DateTime(now.year, now.month, now.day);
        return (s.millisecondsSinceEpoch ~/ 1000, now.millisecondsSinceEpoch ~/ 1000);
      case '7d':  return (now.subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000, now.millisecondsSinceEpoch ~/ 1000);
      case '30d': return (now.subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000, now.millisecondsSinceEpoch ~/ 1000);
      case 'month': final s = DateTime(now.year, now.month, 1);
        return (s.millisecondsSinceEpoch ~/ 1000, now.millisecondsSinceEpoch ~/ 1000);
      case 'custom': if (_customRange != null) return (
        _customRange!.start.millisecondsSinceEpoch ~/ 1000,
        _customRange!.end.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000);
        return (null, null);
      default: return (null, null);
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _exhausted = false; _tracks = []; });
    } else {
      if (_loadingMore || _exhausted) return;
      setState(() => _loadingMore = true);
    }
    try {
      final (from, to) = _range();
      final data  = await widget.service.getRecentTracks(limit: 50, page: _page, from: from, to: to);
      final raw   = data['track'];
      final fresh = raw is List ? raw : (raw != null ? [raw] : <dynamic>[]);
      final totalP = int.tryParse((data['@attr'] as Map?)?['totalPages']?.toString() ?? '1') ?? 1;
      Map<String, dynamic>? np;
      final list = <dynamic>[];
      for (final t in fresh) {
        if ((t as Map?)?['@attr']?['nowplaying'] == 'true') np = t as Map<String, dynamic>;
        else list.add(t);
      }
      setState(() {
        if (reset) _tracks = list; else _tracks.addAll(list);
        _nowPlaying = reset ? np : (_nowPlaying ?? np);
        _exhausted  = _page >= totalP;
        _loading    = false; _loadingMore = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context, firstDate: DateTime(now.year - 5), lastDate: now,
      initialDateRange: _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'Sélectionner une plage', cancelText: 'Annuler', confirmText: 'Valider',
    );
    if (r != null) { setState(() { _customRange = r; _preset = 'custom'; }); _load(reset: true); }
  }

  String get _customLabel {
    if (_customRange == null) return 'Personnalisé';
    return '${_customRange!.start.day}/${_customRange!.start.month} → ${_customRange!.end.day}/${_customRange!.end.month}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(children: [
              Expanded(child: Text('Historique', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
              if (_preset != 'all') IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  onPressed: () { setState(() => _preset = 'all'); _load(reset: true); }),
              IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => _load(reset: true)),
            ]),
          ),
          SizedBox(height: 44, child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            children: [
              for (final (k, l) in const [('all', 'Tout'), ('today', "Auj."), ('7d', '7 j'), ('30d', '30 j'), ('month', 'Ce mois')])
                Padding(padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(label: Text(l), selected: _preset == k, showCheckmark: false,
                      onSelected: (_) { if (_preset != k) { setState(() => _preset = k); _load(reset: true); } })),
              Padding(padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_preset == 'custom' ? _customLabel : 'Personnalisé'),
                  selected: _preset == 'custom', showCheckmark: false,
                  avatar: Icon(Icons.date_range_rounded, size: 16,
                      color: _preset == 'custom' ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
                  onSelected: (_) => _pickCustom())),
            ],
          )),
          const Divider(height: 12),
          if (_loading)    const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null) Expanded(child: _ErrorView(message: _error!, onRetry: () => _load(reset: true)))
          else Expanded(child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (!_exhausted && !_loadingMore && n.metrics.pixels >= n.metrics.maxScrollExtent - 300) { _page++; _load(); }
                return false;
              },
              child: _tracks.isEmpty
                  ? Center(child: Text('Aucune écoute.', style: TextStyle(color: scheme.onSurfaceVariant)))
                  : ListView.builder(
                      itemCount: (_nowPlaying != null ? 1 : 0) + _tracks.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_nowPlaying != null && i == 0) return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: _NowPlayingCard(track: _nowPlaying!));
                        final idx = _nowPlaying != null ? i - 1 : i;
                        if (idx == _tracks.length) return const Padding(
                            padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        final t   = _tracks[idx] as Map;
                        final tit = (t['name']             ?? '').toString();
                        final art = (t['artist']?['#text'] ?? '').toString();
                        final alb = (t['album']?['#text']  ?? '').toString();
                        final raw = _extractImage(t['image']);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: _SmartImage(size: 44, borderRadius: 6, initialUrl: raw,
                              resolver: () => ImageService.resolveTrack(tit, art, lastfmUrl: raw.isNotEmpty ? raw : null)),
                          title: Text(tit, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(alb.isNotEmpty ? '$art · $alb' : art,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          trailing: Text(_fmtDate(t['date']?['#text'] ?? ''),
                              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                        );
                      },
                    ),
            ),
          )),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARAMÈTRES
// ═══════════════════════════════════════════════════════════════════════════
const _kStartupLabels = [
  (Icons.dashboard_rounded,    'Dashboard'),
  (Icons.emoji_events_rounded, 'Classements'),
  (Icons.auto_graph_rounded,   'Graphiques'),
  (Icons.history_rounded,      'Historique'),
];

class _SettingsPage extends StatefulWidget {
  final String username; const _SettingsPage({required this.username});

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  String _theme = 'system', _accent = 'purple';
  bool   _useDynamicColor = false, _useNowPlayingColor = false;
  int    _startupTab = 0;
  String _headerSource = 'nowplaying';
  bool   _showNowPlay = true, _showStats = true, _showArtists = true, _showTracks = true;
  bool   _autoUpdate = true;
  UpdateInfo? _updateInfo; bool _checkingUpdate = false; String? _updateError;

  bool get _isCustomAccent =>
      _accent.startsWith('#') ||
      !_kAccentOptions.any((o) => o.$2 == _accent);

  @override
  void initState() { super.initState(); _loadPrefs().then((_) => _maybeCheckUpdate()); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _theme             = p.getString('ls_theme')               ?? 'system';
      _accent            = p.getString('ls_accent')              ?? 'purple';
      _useDynamicColor   = p.getBool('ls_use_dynamic_color')     ?? false;
      _useNowPlayingColor = p.getBool('ls_use_nowplaying_color') ?? false;
      _startupTab         = p.getInt('ls_startup_tab')            ?? 0;
      _headerSource       = p.getString('ls_header_source')       ?? 'nowplaying';
      _showNowPlay        = p.getBool('ls_show_nowplay')          ?? true;
      _showStats         = p.getBool('ls_show_stats')            ?? true;
      _showArtists       = p.getBool('ls_show_artists')          ?? true;
      _showTracks        = p.getBool('ls_show_tracks')           ?? true;
      _autoUpdate        = p.getBool('ls_auto_update_check')     ?? true;
    });
  }

  Future<void> _maybeCheckUpdate() async {
    if (!_autoUpdate) return;
    final p = await SharedPreferences.getInstance();
    if (DateTime.now().millisecondsSinceEpoch - (p.getInt('ls_last_update_check') ?? 0) <
        const Duration(days: 1).inMilliseconds) return;
    await _checkUpdate(auto: true);
  }

  Future<void> _checkUpdate({bool auto = false}) async {
    if (!mounted) return;
    setState(() { _checkingUpdate = true; _updateError = null; });
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      final p = await SharedPreferences.getInstance();
      await p.setInt('ls_last_update_check', DateTime.now().millisecondsSinceEpoch);
      setState(() { _updateInfo = info; _checkingUpdate = false; });
    } catch (_) {
      if (mounted) setState(() { _updateError = 'Vérification impossible.'; _checkingUpdate = false; });
    }
  }

  Future<void> _set<T>(String key, T v) async {
    final p = await SharedPreferences.getInstance();
    if (v is bool)   await p.setBool(key, v);
    if (v is String) await p.setString(key, v);
    if (v is int)    await p.setInt(key, v);
  }

  Future<void> _setTheme(String v) async {
    await _set('ls_theme', v); setState(() => _theme = v);
    themeModeNotifier.value = themeFromString(v);
  }

  Future<void> _setAccentPreset(String key, Color color) async {
    await _set('ls_accent', key); setState(() => _accent = key);
    if (!_useDynamicColor && !_useNowPlayingColor) accentNotifier.value = color;
  }

  Future<void> _pickCustomColor() async {
    if (_useDynamicColor || _useNowPlayingColor) return;
    final current = accentNotifier.value;
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(initialColor: current),
    );
    if (result != null && mounted) {
      final hex = colorToHex(result);
      await _set('ls_accent', hex);
      setState(() => _accent = hex);
      accentNotifier.value = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final currentAccent = accentNotifier.value;

    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Paramètres', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        // Bannière mise à jour
        if (_updateInfo != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4))),
            child: Row(children: [
              Icon(Icons.system_update_rounded, color: scheme.onTertiaryContainer, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mise à jour — v${_updateInfo!.version}',
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700,
                        color: scheme.onTertiaryContainer)),
                if (_updateInfo!.notes.isNotEmpty)
                  Text(_updateInfo!.notes.length > 100
                      ? '${_updateInfo!.notes.substring(0, 100)}…' : _updateInfo!.notes,
                      style: text.bodySmall?.copyWith(color: scheme.onTertiaryContainer.withValues(alpha: 0.8))),
              ])),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  final url = Uri.parse(_updateInfo!.hasApk ? _updateInfo!.apkUrl! : _updateInfo!.releaseUrl);
                  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                style: FilledButton.styleFrom(
                    backgroundColor: scheme.tertiary, foregroundColor: scheme.onTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: text.labelMedium),
                child: Text(_updateInfo!.hasApk ? 'Télécharger' : 'Voir'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // ── APPARENCE ──
        _SettingsSection(label: 'Apparence', children: [

          // Thème
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.contrast_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Thème', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto_rounded), label: Text('Auto')),
                  ButtonSegment(value: 'light',  icon: Icon(Icons.light_mode_rounded),       label: Text('Clair')),
                  ButtonSegment(value: 'dark',   icon: Icon(Icons.dark_mode_rounded),        label: Text('Sombre')),
                ],
                selected: {_theme},
                onSelectionChanged: (s) => _setTheme(s.first),
                style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          )),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Couleur d'accent
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.palette_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text("Couleur d'accent", style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (_useDynamicColor || _useNowPlayingColor) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outlineVariant)),
                    child: Text('Auto', style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant))),
                ],
              ]),
              const SizedBox(height: 12),
              Opacity(
                opacity: (_useDynamicColor || _useNowPlayingColor) ? 0.35 : 1.0,
                child: Wrap(spacing: 10, runSpacing: 10, children: [
                  // Presets nommés
                  ..._kAccentOptions.map((opt) {
                    final (color, key, label) = opt;
                    final sel = _accent == key;
                    return GestureDetector(
                      onTap: (_useDynamicColor || _useNowPlayingColor) ? null : () => _setAccentPreset(key, color),
                      child: Tooltip(message: label, child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: sel ? Border.all(color: scheme.onSurface, width: 3)
                              : Border.all(color: scheme.outlineVariant, width: 1.5),
                          boxShadow: sel ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)] : [],
                        ),
                        child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                      )),
                    );
                  }),
                  // Bouton couleur personnalisée (roue de couleur)
                  GestureDetector(
                    onTap: (_useDynamicColor || _useNowPlayingColor) ? null : _pickCustomColor,
                    child: Tooltip(
                      message: 'Personnalisé',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isCustomAccent
                              ? null
                              : const SweepGradient(colors: [
                                  Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                                  Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
                                ]),
                          color: _isCustomAccent ? currentAccent : null,
                          border: _isCustomAccent
                              ? Border.all(color: scheme.onSurface, width: 3)
                              : Border.all(color: scheme.outlineVariant, width: 1.5),
                          boxShadow: _isCustomAccent
                              ? [BoxShadow(color: currentAccent.withValues(alpha: 0.5), blurRadius: 8)] : [],
                        ),
                        child: _isCustomAccent
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ]),
              ),
              // Affiche la couleur custom sélectionnée
              if (_isCustomAccent && !_useDynamicColor && !_useNowPlayingColor) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Container(width: 18, height: 18,
                    decoration: BoxDecoration(color: currentAccent, shape: BoxShape.circle,
                        border: Border.all(color: scheme.outlineVariant))),
                  const SizedBox(width: 8),
                  Text(colorToHex(currentAccent),
                      style: text.bodySmall?.copyWith(
                          fontFamily: 'monospace', color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _pickCustomColor,
                      child: const Text('Modifier')),
                ]),
              ],
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // ── COULEUR DYNAMIQUE ──
        _SettingsSection(label: 'Couleur dynamique', children: [
          SwitchListTile(
            secondary: Icon(Icons.colorize_rounded, color: scheme.primary),
            title: const Text('Material You'),
            subtitle: const Text('Utilise la couleur du thème Android'),
            value: _useDynamicColor,
            onChanged: (v) async {
              await _set('ls_use_dynamic_color', v);
              setState(() { _useDynamicColor = v; if (v) _useNowPlayingColor = false; });
              useDynamicColorNotifier.value    = v;
              useNowPlayingColorNotifier.value = false;
              if (!v) accentNotifier.value = accentFromString(_accent);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.album_rounded,
                color: _useDynamicColor ? scheme.onSurfaceVariant : scheme.primary),
            title: const Text('Couleur depuis la musique'),
            subtitle: Text(_useDynamicColor
                ? 'Désactiver Material You d\'abord'
                : 'Extrait la couleur de la pochette en cours'),
            value: _useNowPlayingColor,
            onChanged: _useDynamicColor ? null : (v) async {
              await _set('ls_use_nowplaying_color', v);
              setState(() => _useNowPlayingColor = v);
              useNowPlayingColorNotifier.value = v;
              if (!v) accentNotifier.value = accentFromString(_accent);
            },
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text('La couleur dominante de la pochette en cours remplace l\'accent.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        ]),

        const SizedBox(height: 16),

        // ── PAGE DE DÉMARRAGE ──
        _SettingsSection(label: 'Page de démarrage', children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.rocket_launch_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text("Onglet à l'ouverture", style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: _kStartupLabels.asMap().entries.map((e) => FilterChip(
                  avatar: Icon(e.value.$1, size: 16), label: Text(e.value.$2),
                  selected: _startupTab == e.key, showCheckmark: false,
                  onSelected: (_) async { await _set('ls_startup_tab', e.key); setState(() => _startupTab = e.key); },
                )).toList()),
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // ── DASHBOARD ──
        _SettingsSection(label: 'Dashboard', children: [

          // Image d'en-tête
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.wallpaper_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text("Image d'en-tête", style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text('La pochette choisie s\'affiche en fond de l\'accueil.',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: _kHeaderSources.map((opt) {
                  final (key, label, icon) = opt;
                  final sel = _headerSource == key;
                  return FilterChip(
                    avatar: Icon(icon, size: 16),
                    label: Text(label),
                    selected: sel,
                    showCheckmark: false,
                    onSelected: (_) async {
                      final p = await SharedPreferences.getInstance();
                      await p.setString('ls_header_source', key);
                      setState(() => _headerSource = key);
                    },
                  );
                }).toList()),
              const SizedBox(height: 10),
            ],
          )),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Sections visibles
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Sections visibles', style: text.bodySmall
                ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700))),
          SwitchListTile(secondary: const Icon(Icons.play_circle_outline_rounded),
            title: const Text('En cours de lecture'), value: _showNowPlay,
            onChanged: (v) async { await _set('ls_show_nowplay', v); setState(() => _showNowPlay = v); }),
          SwitchListTile(secondary: const Icon(Icons.bar_chart_rounded),
            title: const Text('Statistiques'), value: _showStats,
            onChanged: (v) async { await _set('ls_show_stats', v); setState(() => _showStats = v); }),
          SwitchListTile(secondary: const Icon(Icons.mic_rounded),
            title: const Text('Top Artistes'), value: _showArtists,
            onChanged: (v) async { await _set('ls_show_artists', v); setState(() => _showArtists = v); }),
          SwitchListTile(secondary: const Icon(Icons.music_note_rounded),
            title: const Text('Top Titres'), value: _showTracks,
            onChanged: (v) async { await _set('ls_show_tracks', v); setState(() => _showTracks = v); }),
        ]),


        const SizedBox(height: 16),

        // ── COMPTE ──
        _SettingsSection(label: 'Compte', children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Text(widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                  style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700))),
            title: Text(widget.username, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Profil Last.fm connecté')),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: scheme.error),
            title: Text('Se déconnecter', style: TextStyle(color: scheme.error)),
            onTap: () async {
              final ok = await showDialog<bool>(context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text('Tes identifiants seront supprimés.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter')),
                  ],
                ));
              if (ok == true && mounted) {
                final p = await SharedPreferences.getInstance();
                await p.remove('ls_username'); await p.remove('ls_apikey');
                if (mounted) Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SetupScreen()), (_) => false);
              }
            }),
        ]),

        const SizedBox(height: 16),

        // ── MISES À JOUR ──
        _SettingsSection(label: 'Mises à jour', children: [
          SwitchListTile(secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Vérification automatique'),
            subtitle: const Text('1 fois par jour'), value: _autoUpdate,
            onChanged: (v) async { await _set('ls_auto_update_check', v); setState(() => _autoUpdate = v); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: _checkingUpdate ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.system_update_outlined),
            title: const Text('Vérifier maintenant'),
            subtitle: _updateError != null ? Text(_updateError!, style: TextStyle(color: scheme.error))
                : (_updateInfo == null ? const Text('À jour') : Text('v${_updateInfo!.version} disponible')),
            onTap: _checkingUpdate ? null : () => _checkUpdate()),
        ]),

        const SizedBox(height: 16),

        // ── À PROPOS ──
        _SettingsSection(label: 'À propos', children: [
          ListTile(leading: const Icon(Icons.info_outline_rounded), title: const Text('Version'),
            trailing: Text(UpdateService.currentVersion,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(leading: const Icon(Icons.web_rounded), title: const Text('Version web'),
            subtitle: const Text('sanobld.github.io/LastStats'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () async {
              final u = Uri.parse('https://sanobld.github.io/LastStats');
              if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
            }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(leading: const Icon(Icons.code_rounded), title: const Text('Code source'),
            subtitle: const Text('github.com/sanobld/LastStats'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () async {
              final u = Uri.parse('https://github.com/sanobld/LastStats');
              if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
            }),
        ]),

        const SizedBox(height: 24),
        Center(child: Text('LastStats Mobile v${UpdateService.currentVersion}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PICKER DIALOG — sélecteur HSL complet
// ═══════════════════════════════════════════════════════════════════════════
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSLColor _hsl;
  late TextEditingController _hexCtrl;
  bool _hexError = false;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(widget.initialColor)
        .withSaturation(_clamp01(HSLColor.fromColor(widget.initialColor).saturation, 0.4, 1.0))
        .withLightness(_clamp01(HSLColor.fromColor(widget.initialColor).lightness, 0.3, 0.7));
    _hexCtrl = TextEditingController(text: colorToHex(_hsl.toColor()));
  }

  @override
  void dispose() { _hexCtrl.dispose(); super.dispose(); }

  double _clamp01(double v, double min, double max) => v.clamp(min, max);
  Color  get _color => _hsl.toColor();

  void _syncHex() {
    _hexCtrl.text = colorToHex(_color);
    _hexCtrl.selection = TextSelection.collapsed(offset: _hexCtrl.text.length);
    _hexError = false;
  }

  void _onHexInput(String raw) {
    final hex = raw.trim().replaceAll('#', '');
    if (hex.length != 6) { setState(() => _hexError = true); return; }
    try {
      final c = Color(0xFF000000 | int.parse(hex, radix: 16));
      final hsl = HSLColor.fromColor(c);
      setState(() {
        _hsl = hsl
            .withSaturation(_clamp01(hsl.saturation, 0.0, 1.0))
            .withLightness(_clamp01(hsl.lightness, 0.0, 1.0));
        _hexError = false;
      });
    } catch (_) { setState(() => _hexError = true); }
  }

  // ── Hue slider custom ────────────────────────────────────────────────────
  Widget _buildHueSlider(BuildContext ctx) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        onTapDown:  (d) => setState(() { _hsl = _hsl.withHue((d.localPosition.dx / w).clamp(0, 1) * 360); _syncHex(); }),
        onPanUpdate:(d) => setState(() { _hsl = _hsl.withHue((d.localPosition.dx / w).clamp(0, 1) * 360); _syncHex(); }),
        child: SizedBox(height: 36, child: Stack(alignment: Alignment.centerLeft, children: [
          // Gradient arc-en-ciel
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: Container(height: 24, decoration: const BoxDecoration(gradient: LinearGradient(colors: [
              Color(0xFFFF0000), Color(0xFFFF8000), Color(0xFFFFFF00),
              Color(0xFF00FF00), Color(0xFF00FFFF), Color(0xFF0000FF),
              Color(0xFFFF00FF), Color(0xFFFF0000),
            ])))),
          // Curseur
          Positioned(
            left: ((_hsl.hue / 360) * w - 12).clamp(0, w - 24),
            child: Container(width: 24, height: 36,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [_hsl.withLightness(0.5).withSaturation(1.0).toColor(),
                              _hsl.withLightness(0.5).withSaturation(1.0).toColor()]))),
          ),
        ])),
      );
    });
  }

  Widget _buildSliderRow(String label, double value, double min, double max,
      List<Color> gradientColors, void Function(double) onChanged) {
    return LayoutBuilder(builder: (_, c) => GestureDetector(
      onTapDown:  (d) => setState(() { onChanged(((d.localPosition.dx / c.maxWidth) * (max - min) + min).clamp(min, max)); _syncHex(); }),
      onPanUpdate:(d) => setState(() { onChanged(((d.localPosition.dx / c.maxWidth) * (max - min) + min).clamp(min, max)); _syncHex(); }),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        SizedBox(height: 28, child: Stack(alignment: Alignment.centerLeft, children: [
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: Container(height: 20, decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors)))),
          Positioned(
            left: (((value - min) / (max - min)) * c.maxWidth - 10).clamp(0, c.maxWidth - 20),
            child: Container(width: 20, height: 28,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.black26, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)]))),
        ])),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final pure   = _hsl.withSaturation(1.0).withLightness(0.5).toColor();

    // Presets rapides
    const quickPresets = [
      Color(0xFF7C3AED), Color(0xFF1D4ED8), Color(0xFF059669),
      Color(0xFFDC2626), Color(0xFFD97706), Color(0xFFDB2777),
      Color(0xFF0F766E), Color(0xFFEA580C), Color(0xFF7C3AED),
      Color(0xFF0284C7), Color(0xFF16A34A), Color(0xFF9333EA),
    ];

    return AlertDialog(
      title: const Text('Couleur personnalisée'),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aperçu
            Row(children: [
              Expanded(child: Container(height: 52,
                decoration: BoxDecoration(color: _color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant)))),
              const SizedBox(width: 10),
              // Input hex
              Expanded(child: TextField(
                controller: _hexCtrl,
                onChanged: _onHexInput,
                decoration: InputDecoration(
                  labelText: 'HEX',
                  prefixText: '',
                  errorText: _hexError ? 'Format invalide' : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                style: text.bodyMedium?.copyWith(fontFamily: 'monospace'),
              )),
            ]),
            const SizedBox(height: 16),

            // Teinte
            Text('Teinte', style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildHueSlider(context),
            const SizedBox(height: 14),

            // Saturation
            _buildSliderRow('Saturation',
              _hsl.saturation, 0.0, 1.0,
              [Colors.grey.shade400, pure],
              (v) => _hsl = _hsl.withSaturation(v)),
            const SizedBox(height: 14),

            // Luminosité
            _buildSliderRow('Luminosité',
              _hsl.lightness, 0.15, 0.85,
              [Colors.black, _hsl.withSaturation(1.0).withLightness(0.5).toColor(), Colors.white],
              (v) => _hsl = _hsl.withLightness(v)),
            const SizedBox(height: 16),

            // Presets rapides
            Text('Couleurs rapides', style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: quickPresets.toSet().toList().take(10).map((c) => GestureDetector(
                onTap: () => setState(() {
                  _hsl = HSLColor.fromColor(c);
                  _syncHex();
                }),
                child: Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                      border: Border.all(color: scheme.outlineVariant, width: 1))),
              )).toList()),
            const SizedBox(height: 16),
          ],
        )),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════════════════════════════════════

class _SettingsSection extends StatelessWidget {
  final String label; final List<Widget> children;
  const _SettingsSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(label.toUpperCase(), style: text.labelSmall?.copyWith(
            color: scheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
      Card(
        elevation: 0, color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: _cardBorder(scheme),           // ← contour Material You
        ),
        child: Column(children: children)),
    ]);
  }
}

class _SmartImage extends StatelessWidget {
  final String? initialUrl;
  final Future<String> Function() resolver;
  final double size, borderRadius;
  const _SmartImage({required this.resolver, required this.size,
      required this.borderRadius, this.initialUrl});

  static const _ph = '2a96cbd8b46e442fc41c2b86b821562f';
  bool get _needsResolve =>
      initialUrl == null || initialUrl!.isEmpty || initialUrl!.contains(_ph);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_needsResolve) return _img(initialUrl!, scheme);
    return FutureBuilder<String>(future: resolver(), builder: (_, snap) {
      if (snap.connectionState != ConnectionState.done) return _loading(scheme);
      final url = snap.data ?? '';
      return url.isEmpty ? _fallback(scheme) : _img(url, scheme);
    });
  }

  Widget _img(String url, ColorScheme s) => ClipRRect(borderRadius: BorderRadius.circular(borderRadius),
    child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(s)));

  Widget _loading(ColorScheme s) => ClipRRect(borderRadius: BorderRadius.circular(borderRadius),
    child: Container(width: size, height: size, color: s.surfaceContainerHighest,
      child: Center(child: SizedBox(width: size * 0.4, height: size * 0.4,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: s.primary.withValues(alpha: 0.5))))));

  Widget _fallback(ColorScheme s) => ClipRRect(borderRadius: BorderRadius.circular(borderRadius),
    child: Container(width: size, height: size, color: s.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded, color: s.onSurfaceVariant, size: size * 0.5)));
}

class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, color: scheme.primary, size: 20), const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    ]);
  }
}

class _ItemTile extends StatelessWidget {
  final String name, sub, imageUrl, rank;
  final Future<String>? imageFuture;
  final String? plays;
  const _ItemTile({required this.name, required this.sub, required this.imageUrl,
      required this.rank, this.imageFuture, this.plays});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(children: [
        SizedBox(width: 28, child: Text(rank, textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        _SmartImage(size: 48, borderRadius: 8, initialUrl: imageUrl,
            resolver: imageFuture != null ? () => imageFuture! : () => Future.value('')),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ])),
        if (plays != null) Padding(padding: const EdgeInsets.only(left: 8),
          child: Text(plays!, style: text.bodySmall
              ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600))),
      ]));
  }
}

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer')),
      ])));
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _extractImage(dynamic images) {
  if (images == null) return '';
  final list = images is List ? images : [];
  if (list.isEmpty) return '';
  try {
    final large = list.lastWhere(
        (i) => i is Map && i['size'] == 'extralarge', orElse: () => list.last);
    return (large is Map ? large['#text'] ?? '' : '').toString();
  } catch (_) { return ''; }
}

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

String _fmtDate(String raw) {
  if (raw.isEmpty) return '';
  try {
    final parts = raw.split(', ');
    return parts.length == 2 ? '${parts[0]} · ${parts[1]}' : raw;
  } catch (_) { return raw; }
}