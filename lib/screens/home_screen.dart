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
const _kDefaultImg =
    'https://lastfm.freetls.fastly.net/i/u/300x300/2a96cbd8b46e442fc41c2b86b821562f.png';

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

// ─── Cartes du dashboard ─────────────────────────────────────────────────────
// (id, label, icône)  — ordre = ordre par défaut
const _kDashCards = [
  ('nowplaying',      'En cours de lecture',    Icons.play_circle_outline_rounded),
  ('total_scrobbles', 'Total scrobbles',         Icons.headphones_rounded),
  ('avg_day',         'Moyenne / jour',          Icons.bolt_rounded),
  ('weekly_est',      'Semaine (estimé)',        Icons.calendar_today_rounded),
  ('avg_week',        'Moyenne / semaine',       Icons.date_range_rounded),
  ('account_age',     'Âge du compte',           Icons.schedule_rounded),
  ('loved_count',     'Titres aimés',            Icons.favorite_rounded),
  ('top_artist',      'Artiste #1',              Icons.mic_rounded),
  ('top_album',       'Album #1',                Icons.album_rounded),
  ('top_track',       'Titre #1',                Icons.music_note_rounded),
  ('last_played',     'Dernière écoute',         Icons.history_rounded),
  ('artists_list',    'Top Artistes (liste)',    Icons.people_rounded),
  ('tracks_list',     'Top Titres (liste)',      Icons.queue_music_rounded),
];

List<String> _defaultCardOrder() => _kDashCards.map((c) => c.$1).toList();


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
    final pages = [
      _DashboardPage(service: _service, username: widget.username),
      _RankingsPage(service: _service),
      _ChartsPage(service: _service),
      _HistoryPage(service: _service),
      _SettingsPage(username: widget.username),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          // Classements → trophée (distinct du graphique)
          NavigationDestination(
            icon:         Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Classements',
          ),
          // Graphiques → courbe analytique (distinct du classement)
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
// DASHBOARD — stat cards + now playing + recents
// ═══════════════════════════════════════════════════════════════════════════
class _DashboardPage extends StatefulWidget {
  final LastFmService service;
  final String username;
  const _DashboardPage({required this.service, required this.username});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  // ── Données API ────────────────────────────────────────
  Map<String, dynamic>? _userInfo;
  List<dynamic> _topArtists = [];
  List<dynamic> _topAlbums  = [];
  List<dynamic> _topTracks  = [];
  List<dynamic> _recentTracks = [];
  Map<String, dynamic>? _nowPlaying;

  bool _loading = true;
  String? _error;
  Timer? _npTimer;

  // ── Prefs ──────────────────────────────────────────────
  List<String> _cardOrder  = _defaultCardOrder();
  Set<String>  _hiddenCards = {};
  int          _lovedCount  = 0;
  int          _npRefreshSec = 30;  // piloté par les paramètres

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) => _load());
    _scheduleNpTimer();
  }

  void _scheduleNpTimer() {
    _npTimer?.cancel();
    if (_npRefreshSec > 0) {
      _npTimer = Timer.periodic(
          Duration(seconds: _npRefreshSec), (_) => _refreshNowPlaying());
    }
  }

  @override
  void dispose() {
    _npTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final orderStr  = prefs.getString('ls_card_order')  ?? '';
    final hiddenStr = prefs.getString('ls_card_hidden') ?? '';
    final npSec     = prefs.getInt('ls_np_refresh_sec') ?? 30;
    setState(() {
      _npRefreshSec = npSec;
      _hiddenCards  = hiddenStr.isEmpty ? {} : hiddenStr.split(',').toSet();
      if (orderStr.isNotEmpty) {
        final saved   = orderStr.split(',');
        // Ajouter les nouvelles cartes non encore sauvegardées
        final missing = _defaultCardOrder().where((id) => !saved.contains(id));
        _cardOrder    = [...saved, ...missing];
      }
    });
    _scheduleNpTimer();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.service.getUserInfo(),
        widget.service.getTopArtists(period: 'overall', limit: 50),
        widget.service.getTopAlbums (period: 'overall', limit: 50),
        widget.service.getTopTracks (period: 'overall', limit: 50),
        widget.service.getRecentTracks(limit: 10),
        widget.service.getNowPlaying(),
        widget.service.getLovedTracks(limit: 1),
      ]);

      final recentData = results[4] as Map<String, dynamic>;
      final rawTracks  = recentData['track'];
      final allRecent  = rawTracks is List ? rawTracks
          : (rawTracks != null ? [rawTracks] : <dynamic>[]);

      Map<String, dynamic>? np;
      final recentFiltered = <dynamic>[];
      for (final t in allRecent) {
        if ((t as Map?)?['@attr']?['nowplaying'] == 'true') {
          np = t as Map<String, dynamic>;
        } else {
          recentFiltered.add(t);
        }
      }

      // Loved count depuis userInfo
      final userInfoMap = results[0] as Map<String, dynamic>?;
      final lovedRaw    = userInfoMap?['playlists'];   // fallback
      // On essaie de récupérer le vrai total depuis getLovedTracks attr
      int lovedCount = 0;
      try {
        final lovedSvc = results[6] as List<dynamic>;
        // lovedTracks ne retourne pas d'attr total facilement via la liste
        // on lit depuis userInfo['playlists'] sinon on garde 0
        lovedCount = int.tryParse(
            userInfoMap?['loved_count']?.toString() ?? '') ?? 0;
        if (lovedCount == 0) lovedCount = lovedSvc.isNotEmpty ? -1 : 0;
      } catch (_) {}

      setState(() {
        _userInfo     = userInfoMap;
        _topArtists   = results[1] as List<dynamic>;
        _topAlbums    = results[2] as List<dynamic>;
        _topTracks    = results[3] as List<dynamic>;
        _recentTracks = recentFiltered;
        _nowPlaying   = np ?? results[5] as Map<String, dynamic>?;
        _lovedCount   = lovedCount;
        _loading      = false;
      });

      if (_nowPlaying != null) _extractColorFromNowPlaying(_nowPlaying!);
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }


  Future<void> _refreshNowPlaying() async {
    try {
      final np = await widget.service.getNowPlaying();
      if (mounted) {
        setState(() => _nowPlaying = np);
        if (np != null) _extractColorFromNowPlaying(np);
      }
    } catch (_) {}
  }

  Future<void> _extractColorFromNowPlaying(Map<String, dynamic> track) async {
    if (!useNowPlayingColorNotifier.value) return;
    final url = _extractImage(track['image']);
    if (url.isEmpty || url.contains('2a96cbd8b46e442fc41c2b86b821562f')) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(url),
        size: const Size(200, 200),
        maximumColorCount: 16,
      );
      final color = palette.vibrantColor?.color ?? palette.dominantColor?.color;
      if (color != null && mounted) accentNotifier.value = color;
    } catch (_) {}
  }

  // ── Stats calculées ───────────────────────────────────
  int _totalScrobbles()  => int.tryParse((_userInfo?['playcount'] ?? '0').toString()) ?? 0;
  int _accountDays()     {
    final raw = _userInfo?['registered'];
    if (raw == null) return 0;
    int ts = 0;
    if (raw is Map) ts = int.tryParse((raw['#text'] ?? raw['unixtime'] ?? '0').toString()) ?? 0;
    else ts = int.tryParse(raw.toString()) ?? 0;
    if (ts <= 0) return 0;
    return ((DateTime.now().millisecondsSinceEpoch / 1000 - ts) / 86400).floor();
  }
  double _avgPerDay()    { final d = _accountDays(); return d > 0 ? _totalScrobbles() / d : 0; }
  int    _weeklyEst()    => (_avgPerDay() * 7).round();
  String _registeredStr() {
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
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);

    final info     = _userInfo!;
    final name     = (info['name']     ?? widget.username).toString();
    final realName = (info['realname'] ?? '').toString();
    final country  = (info['country']  ?? '').toString();
    final avatarUrl = _extractImage(info['image']);

    final total   = _totalScrobbles();
    final days    = _accountDays();
    final avg     = _avgPerDay();
    final weekly  = _weeklyEst();
    final regStr  = _registeredStr();

    final topArtist = _topArtists.isNotEmpty ? _topArtists[0] : null;
    final topAlbum  = _topAlbums.isNotEmpty  ? _topAlbums[0]  : null;
    final topTrack  = _topTracks.isNotEmpty  ? _topTracks[0]  : null;

    final lastTrack = _recentTracks.isNotEmpty ? _recentTracks[0] as Map : null;
    final lastDate  = lastTrack?['date']?['#text'] ?? '';

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [

          // ── AppBar profil ──────────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Rafraîchir',
                onPressed: _load,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [scheme.primaryContainer, scheme.surface],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 80, 0),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: scheme.primary.withValues(alpha: 0.2),
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Icon(Icons.person_rounded, size: 36,
                                color: scheme.onPrimaryContainer)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          if (realName.isNotEmpty)
                            Text(realName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                          if (country.isNotEmpty && country != 'None')
                            Text(country,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                          if (regStr.isNotEmpty)
                            Text('Depuis $regStr',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      )),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildCards(scheme, name, total, days, avg, weekly,
                    regStr, topArtist, topAlbum, topTrack, lastTrack, lastDate),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCards(
    ColorScheme scheme,
    String name, int total, int days, double avg, int weekly,
    String regStr, dynamic topArtist, dynamic topAlbum, dynamic topTrack,
    Map? lastTrack, String lastDate,
  ) {
    final widgets = <Widget>[];

    for (final id in _cardOrder) {
      if (_hiddenCards.contains(id)) continue;

      switch (id) {
        case 'nowplaying':
          if (_nowPlaying != null) {
            widgets.add(_NowPlayingCard(track: _nowPlaying!));
            widgets.add(const SizedBox(height: 14));
          }

        case 'total_scrobbles':
          widgets.add(_DashStatCard(
            emoji: '🎯',
            value: _formatFull(total),
            label: 'Scrobbles au total',
            sub: regStr.isNotEmpty ? 'Depuis $regStr' : null,
            color: scheme.primaryContainer,
            onColor: scheme.onPrimaryContainer,
          ));
          widgets.add(const SizedBox(height: 10));

        case 'avg_day':
          widgets.add(_DashStatCard(
            emoji: '⚡',
            value: _formatFull(avg.round()),
            label: 'Moyenne par jour',
            sub: days > 0 ? '$days jours d\'activité' : null,
            color: scheme.secondaryContainer,
            onColor: scheme.onSecondaryContainer,
          ));
          widgets.add(const SizedBox(height: 10));

        case 'weekly_est':
          widgets.add(_DashStatCard(
            emoji: '📅',
            value: '~${_formatFull(weekly)}',
            label: 'Cette semaine (estimé)',
            sub: 'Basé sur ta moyenne quotidienne',
            color: scheme.tertiaryContainer,
            onColor: scheme.onTertiaryContainer,
          ));
          widgets.add(const SizedBox(height: 10));

        case 'avg_week':
          widgets.add(_DashStatCard(
            emoji: '📊',
            value: _formatFull((_avgPerDay() * 7).round()),
            label: 'Moyenne par semaine',
            sub: days > 0 ? 'Sur $days jours d\'historique' : null,
            color: scheme.surfaceContainerHighest,
            onColor: scheme.onSurface,
          ));
          widgets.add(const SizedBox(height: 10));

        case 'account_age':
          widgets.add(_DashStatCard(
            emoji: '🗓️',
            value: '${_formatFull(days)} jours',
            label: 'Âge du compte',
            sub: regStr.isNotEmpty ? regStr : null,
            color: scheme.surfaceContainerHighest,
            onColor: scheme.onSurface,
          ));
          widgets.add(const SizedBox(height: 10));

        case 'loved_count':
          if (_lovedCount > 0) {
            widgets.add(_DashStatCard(
              emoji: '❤️',
              value: _lovedCount > 0 ? _formatFull(_lovedCount) : '—',
              label: 'Titres aimés (loved)',
              sub: null,
              color: const Color(0xFFFFEBEE),
              onColor: const Color(0xFFB71C1C),
            ));
            widgets.add(const SizedBox(height: 10));
          }

        case 'top_artist':
          if (topArtist != null) {
            widgets.add(_DashStatCard(
              emoji: '🎤',
              value: (topArtist['name'] ?? '—').toString(),
              label: 'Artiste #1 — Tout le temps',
              sub: '${_formatFull(int.tryParse((topArtist['playcount'] ?? '0').toString()) ?? 0)} écoutes',
              color: scheme.primaryContainer,
              onColor: scheme.onPrimaryContainer,
              compact: true,
            ));
            widgets.add(const SizedBox(height: 10));
          }

        case 'top_album':
          if (topAlbum != null) {
            widgets.add(_DashStatCard(
              emoji: '💿',
              value: (topAlbum['name'] ?? '—').toString(),
              label: 'Album #1 — Tout le temps',
              sub: (topAlbum['artist']?['name'] ?? '').toString(),
              color: scheme.secondaryContainer,
              onColor: scheme.onSecondaryContainer,
              compact: true,
            ));
            widgets.add(const SizedBox(height: 10));
          }

        case 'top_track':
          if (topTrack != null) {
            widgets.add(_DashStatCard(
              emoji: '🎵',
              value: (topTrack['name'] ?? '—').toString(),
              label: 'Titre #1 — Tout le temps',
              sub: '${_formatFull(int.tryParse((topTrack['playcount'] ?? '0').toString()) ?? 0)} écoutes',
              color: scheme.tertiaryContainer,
              onColor: scheme.onTertiaryContainer,
              compact: true,
            ));
            widgets.add(const SizedBox(height: 10));
          }

        case 'last_played':
          if (lastTrack != null) {
            widgets.add(_DashStatCard(
              emoji: '⏱️',
              value: (lastTrack['name'] ?? '—').toString(),
              label: 'Dernière écoute',
              sub: lastDate.isNotEmpty ? _formatDate(lastDate) : null,
              color: scheme.surfaceContainerHighest,
              onColor: scheme.onSurface,
              compact: true,
            ));
            widgets.add(const SizedBox(height: 10));
          }

        case 'artists_list':
          if (_topArtists.isNotEmpty) {
            widgets.add(_SectionHeader(
                title: 'Top Artistes', icon: Icons.mic_rounded));
            widgets.add(const SizedBox(height: 8));
            for (var i = 0; i < _topArtists.take(5).length; i++) {
              final a = _topArtists[i];
              widgets.add(_ItemTile(
                name:     (a['name'] ?? '').toString(),
                sub:      '${_formatFull(int.tryParse((a['playcount'] ?? '0').toString()) ?? 0)} écoutes',
                imageUrl: _extractImage(a['image']),
                imageFuture: ImageService.resolveArtist(
                    (a['name'] ?? '').toString(),
                    lastfmUrl: _extractImage(a['image'])),
                rank: '${i + 1}',
              ));
            }
            widgets.add(const SizedBox(height: 20));
          }

        case 'tracks_list':
          if (_topTracks.isNotEmpty) {
            widgets.add(_SectionHeader(
                title: 'Top Titres', icon: Icons.music_note_rounded));
            widgets.add(const SizedBox(height: 8));
            for (var i = 0; i < _topTracks.take(5).length; i++) {
              final t      = _topTracks[i];
              final tn     = (t['name'] ?? '').toString();
              final artist = (t['artist']?['name'] ?? '').toString();
              widgets.add(_ItemTile(
                name:     tn,
                sub:      artist,
                imageUrl: _extractImage(t['image']),
                imageFuture: ImageService.resolveTrack(tn, artist,
                    lastfmUrl: _extractImage(t['image'])),
                rank:  '${i + 1}',
                plays: _formatFull(int.tryParse((t['playcount'] ?? '0').toString()) ?? 0),
              ));
            }
            widgets.add(const SizedBox(height: 20));
          }
      }
    }
    return widgets;
  }
} // end _DashboardPageState


// ─── Stat card du dashboard ───────────────────────────────────────────────────
class _DashStatCard extends StatelessWidget {
  final String  emoji;
  final String  value;
  final String  label;
  final String? sub;
  final Color   color;
  final Color   onColor;
  final bool    compact;

  const _DashStatCard({
    required this.emoji,
    required this.value,
    required this.label,
    this.sub,
    required this.color,
    required this.onColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: compact
                  ? text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: onColor)
                  : text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: onColor),
            ),
            Text(label,
                style: text.bodySmall?.copyWith(
                    color: onColor.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600)),
            if (sub != null)
              Text(sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                      color: onColor.withValues(alpha: 0.55))),
          ],
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          _SmartImage(
            size: 56, borderRadius: 10, initialUrl: rawUrl,
            resolver: () => ImageService.resolveTrack(title, artist,
                lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: scheme.secondary,
                        shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('EN COURS',
                    style: text.labelSmall?.copyWith(
                        color: scheme.secondary, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ]),
              const SizedBox(height: 2),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer.withValues(alpha: 0.75))),
            ],
          )),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLASSEMENTS — podium + liste infinie
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
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Classements',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),

            // ── Pillules de période ──
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                children: _kPeriods.map((p) {
                  final sel = p.$1 == _period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p.$2),
                      selected: sel,
                      onSelected: (_) {
                        if (!sel) setState(() => _period = p.$1);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Artistes'),
                Tab(text: 'Albums'),
                Tab(text: 'Titres'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _TopListBody(service: widget.service, type: 'artists', period: _period),
                  _TopListBody(service: widget.service, type: 'albums',  period: _period),
                  _TopListBody(service: widget.service, type: 'tracks',  period: _period),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Corps de la liste avec podium ───────────────────────────────────────────
class _TopListBody extends StatefulWidget {
  final LastFmService service;
  final String type;
  final String period;
  const _TopListBody({required this.service, required this.type, required this.period});

  @override
  State<_TopListBody> createState() => _TopListBodyState();
}

class _TopListBodyState extends State<_TopListBody>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _items     = [];
  bool _loading            = true;
  bool _loadingMore        = false;
  bool _exhausted          = false;
  String? _error;
  int _page                = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

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
          fresh = await widget.service.getTopArtists(period: widget.period, limit: 50, page: _page);
          break;
        case 'albums':
          fresh = await widget.service.getTopAlbums(period: widget.period,  limit: 50, page: _page);
          break;
        default:
          fresh = await widget.service.getTopTracks(period: widget.period,  limit: 50, page: _page);
      }
      if (mounted) setState(() {
        _items.addAll(fresh);
        _exhausted   = fresh.length < 50;
        _loading     = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error       = e.toString().replaceFirst('Exception: ', '');
        _loading     = false;
        _loadingMore = false;
      });
    }
  }

  void _showDetail(BuildContext ctx, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(
          item: item, type: widget.type, service: widget.service),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: () => _load(reset: true));
    if (_items.isEmpty) {
      return Center(child: Text('Aucun résultat',
          style: TextStyle(color: scheme.onSurfaceVariant)));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!_exhausted && !_loadingMore &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          _page++;
          _load();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          // ── Podium top 3 ──
          if (_items.length >= 3)
            SliverToBoxAdapter(
              child: _PodiumWidget(
                items: _items.take(3).toList(),
                type:  widget.type,
                onTap: (item) => _showDetail(context, item as Map<String, dynamic>),
              ),
            ),

          // ── Liste à partir du #4 ──
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final offset = _items.length >= 3 ? 3 : 0;
                final idx    = i + offset;

                if (idx >= _items.length) {
                  return _loadingMore
                      ? const Padding(padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()))
                      : const SizedBox.shrink();
                }

                final item   = _items[idx] as Map<String, dynamic>;
                final name   = (item['name'] ?? '').toString();
                final plays  = _formatNumber(int.tryParse((item['playcount'] ?? '0').toString()) ?? 0);
                final artist = (item['artist']?['name'] ?? '').toString();
                final rawUrl = _extractImage(item['image']);

                Future<String> imgFuture;
                switch (widget.type) {
                  case 'artists':
                    imgFuture = ImageService.resolveArtist(name, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
                    break;
                  case 'albums':
                    imgFuture = ImageService.resolveAlbum(name, artist, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
                    break;
                  default:
                    imgFuture = ImageService.resolveTrack(name, artist, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
                }

                return InkWell(
                  onTap: () => _showDetail(ctx, item),
                  borderRadius: BorderRadius.circular(8),
                  child: _ItemTile(
                    name:        name,
                    sub:         widget.type != 'artists' ? '$artist · $plays écoutes' : '$plays écoutes',
                    imageUrl:    rawUrl,
                    imageFuture: imgFuture,
                    rank:        '${idx + 1}',
                    plays:       widget.type != 'artists' ? plays : null,
                  ),
                );
              },
              childCount: (_items.length >= 3 ? _items.length - 3 : _items.length) + 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Podium visuel ─────────────────────────────────────────────────────────────
class _PodiumWidget extends StatelessWidget {
  final List<dynamic> items;   // exactly 3 items: [0]=#1 [1]=#2 [2]=#3
  final String type;
  final void Function(dynamic item) onTap;

  const _PodiumWidget({required this.items, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    // Ordre d'affichage visuel : #2 (gauche), #1 (centre), #3 (droite)
    const order    = [1, 0, 2];
    const heights  = [100.0, 130.0, 80.0]; // hauteur de la base du podium
    const medals   = ['🥈', '🥇', '🥉'];
    const imgSizes = [56.0, 72.0, 48.0];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Podium', icon: Icons.emoji_events_rounded),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (col) {
              final dataIdx = order[col];
              final item    = items[dataIdx] as Map<String, dynamic>;
              final name    = (item['name'] ?? '').toString();
              final artist  = type != 'artists'
                  ? (item['artist']?['name'] ?? '').toString() : '';
              final plays   = _formatNumber(int.tryParse(
                  (item['playcount'] ?? '0').toString()) ?? 0);
              final rawUrl  = _extractImage(item['image']);

              Future<String> imgFuture;
              switch (type) {
                case 'artists':
                  imgFuture = ImageService.resolveArtist(name, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
                  break;
                case 'albums':
                  imgFuture = ImageService.resolveAlbum(name, artist, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
                  break;
                default:
                  imgFuture = ImageService.resolveTrack(name, artist, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
              }

              final podiumColor = dataIdx == 0
                  ? scheme.primaryContainer
                  : dataIdx == 1
                      ? scheme.secondaryContainer
                      : scheme.tertiaryContainer;
              final podiumOnColor = dataIdx == 0
                  ? scheme.onPrimaryContainer
                  : dataIdx == 1
                      ? scheme.onSecondaryContainer
                      : scheme.onTertiaryContainer;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(item),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(imgSizes[col] / 4),
                        child: _SmartImage(
                          size: imgSizes[col],
                          borderRadius: imgSizes[col] / 4,
                          initialUrl: rawUrl,
                          resolver: () => imgFuture,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Médaille
                      Text(medals[col],
                          style: TextStyle(fontSize: imgSizes[col] == 72.0 ? 22 : 18)),

                      const SizedBox(height: 4),

                      // Base du podium
                      Container(
                        width: double.infinity,
                        height: heights[col],
                        decoration: BoxDecoration(
                          color: podiumColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Rang
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: podiumOnColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('#${dataIdx + 1}',
                                  style: text.labelSmall?.copyWith(
                                      color: podiumOnColor,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(height: 4),
                            // Nom
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(
                                  color: podiumOnColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: dataIdx == 0 ? 11 : 10),
                            ),
                            if (heights[col] >= 100) ...[
                              const SizedBox(height: 2),
                              Text(plays,
                                  style: text.bodySmall?.copyWith(
                                      color: podiumOnColor.withValues(alpha: 0.7),
                                      fontSize: 9)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
            child: Text('Suite du classement',
                style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _PeriodStats {
  final int rank;
  final int playcount;
  const _PeriodStats({required this.rank, required this.playcount});
}

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
  void initState() {
    super.initState();
    _loadPeriod('overall');
  }

  Future<void> _loadPeriod(String period) async {
    if (_cache.containsKey(period)) {
      setState(() => _period = period);
      return;
    }
    setState(() { _period = period; _loading = true; });

    final name       = (widget.item['name'] ?? '').toString();
    final artistName = widget.type != 'artists'
        ? (widget.item['artist']?['name'] ?? '').toString() : '';

    try {
      List<dynamic> items;
      if (widget.type == 'artists') {
        items = await widget.service.getTopArtists(period: period, limit: 200);
      } else if (widget.type == 'albums') {
        items = await widget.service.getTopAlbums(period: period, limit: 200);
      } else {
        items = await widget.service.getTopTracks(period: period, limit: 200);
      }

      int rank = -1, playcount = 0;
      for (var i = 0; i < items.length; i++) {
        final n = (items[i]['name'] ?? '').toString();
        final a = widget.type != 'artists'
            ? (items[i]['artist']?['name'] ?? '').toString() : '';
        if (n == name && (widget.type == 'artists' || a == artistName)) {
          rank     = i + 1;
          playcount = int.tryParse((items[i]['playcount'] ?? '0').toString()) ?? 0;
          break;
        }
      }
      setState(() { _cache[period] = _PeriodStats(rank: rank, playcount: playcount); _loading = false; });
    } catch (_) {
      setState(() { _cache[period] = _PeriodStats(rank: -1, playcount: 0); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme     = Theme.of(context).colorScheme;
    final text       = Theme.of(context).textTheme;
    final name       = (widget.item['name'] ?? '').toString();
    final artistName = widget.type != 'artists'
        ? (widget.item['artist']?['name'] ?? '').toString() : '';
    final rawUrl     = _extractImage(widget.item['image']);
    final stats      = _cache[_period];
    final periodLabel = _kPeriods.firstWhere(
        (p) => p.$1 == _period, orElse: () => (_period, _period)).$2;

    Future<String> imgFuture;
    switch (widget.type) {
      case 'artists':
        imgFuture = ImageService.resolveArtist(name, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
        break;
      case 'albums':
        imgFuture = ImageService.resolveAlbum(name, artistName, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
        break;
      default:
        imgFuture = ImageService.resolveTrack(name, artistName, lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.55, minChildSize: 0.35, maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2))),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(children: [
              _SmartImage(size: 72, borderRadius: 12, initialUrl: rawUrl,
                  resolver: () => imgFuture),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  if (artistName.isNotEmpty)
                    Text(artistName, style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(switch (widget.type) {
                      'artists' => 'Artiste', 'albums' => 'Album', _ => 'Titre' },
                      style: text.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700)),
                  ),
                ],
              )),
            ]),
          ),

          const Divider(height: 24),

          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              children: _kPeriods.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(p.$2),
                  selected: p.$1 == _period,
                  showCheckmark: false,
                  onSelected: (_) => _loadPeriod(p.$1),
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: stats == null ? const SizedBox.shrink()
                      : Column(children: [
                          if (stats.rank > 0 && stats.rank <= 200)
                            _DetailStatCard(
                              icon: Icons.leaderboard_rounded,
                              value: '#${stats.rank}',
                              label: 'Classement · $periodLabel',
                              color: scheme.primaryContainer,
                              onColor: scheme.onPrimaryContainer,
                            ),
                          const SizedBox(height: 12),
                          _DetailStatCard(
                            icon: Icons.headphones_rounded,
                            value: _formatNumber(stats.playcount),
                            label: 'Écoutes · $periodLabel',
                            color: scheme.secondaryContainer,
                            onColor: scheme.onSecondaryContainer,
                          ),
                          if (stats.rank == -1 || stats.rank > 200)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text('Non classé dans le top 200 pour cette période.',
                                  textAlign: TextAlign.center,
                                  style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                            ),
                        ]),
                )),
        ]),
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color onColor;
  const _DetailStatCard({required this.icon, required this.value,
      required this.label, required this.color, required this.onColor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 0, color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, color: onColor, size: 32),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800, color: onColor)),
            Text(label, style: text.bodySmall
                ?.copyWith(color: onColor.withValues(alpha: 0.8))),
          ]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRAPHIQUES
// ═══════════════════════════════════════════════════════════════════════════
class _ChartsPage extends StatefulWidget {
  final LastFmService service;
  const _ChartsPage({required this.service});

  @override
  State<_ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<_ChartsPage>
    with AutomaticKeepAliveClientMixin {
  Map<String, int>? _monthly;
  List<dynamic>     _topArtists = [];
  bool _loading   = true;
  String? _error;
  bool _gemsLoading = false;
  List<_GemEntry> _gems = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
    final futures  = artists.map(
        (a) => widget.service.getArtistListeners((a['name'] ?? '').toString()));
    final listeners = await Future.wait(futures);
    final entries = <_GemEntry>[];
    for (var i = 0; i < artists.length; i++) {
      entries.add(_GemEntry(
        name:      (artists[i]['name'] ?? '').toString(),
        plays:     int.tryParse((artists[i]['playcount'] ?? '0').toString()) ?? 0,
        listeners: listeners[i] ?? 0,
      ));
    }
    entries.sort((a, b) => a.listeners.compareTo(b.listeners));
    setState(() { _gems = entries; _gemsLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);

    final monthly = _monthly!;
    final maxVal  = monthly.values.fold(0, (a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Graphiques',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          _SectionHeader(title: 'Scrobbles — 12 derniers mois',
              icon: Icons.calendar_month_rounded),
          const SizedBox(height: 16),
          Card(
            elevation: 0, color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthly.entries.map((e) {
                    final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                    final month = e.key.substring(5);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (ratio > 0)
                              Text(_formatNumber(e.value),
                                  style: text.labelSmall?.copyWith(
                                      fontSize: 8, color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Flexible(
                              fit: FlexFit.loose,
                              child: FractionallySizedBox(
                                heightFactor: ratio.clamp(0.02, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(alpha: 0.5 + ratio * 0.5),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(month, style: text.labelSmall?.copyWith(fontSize: 9)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: 'Top artistes — distribution', icon: Icons.mic_rounded),
          const SizedBox(height: 12),
          if (_topArtists.isNotEmpty) ...[
            () {
              final maxPlays = _topArtists
                  .map((a) => int.tryParse((a['playcount'] ?? '0').toString()) ?? 0)
                  .fold(0, (a, b) => a > b ? a : b);
              return Card(
                elevation: 0, color: scheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _topArtists.asMap().entries.map((e) {
                      final plays = int.tryParse((e.value['playcount'] ?? '0').toString()) ?? 0;
                      final ratio = maxPlays > 0 ? plays / maxPlays : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          SizedBox(width: 24, child: Text('${e.key + 1}',
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700))),
                          const SizedBox(width: 8),
                          Expanded(flex: 3, child: Text(
                              (e.value['name'] ?? '').toString(),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                          const SizedBox(width: 8),
                          Expanded(flex: 5, child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio, minHeight: 8,
                                backgroundColor: scheme.primary.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                              ))),
                          const SizedBox(width: 8),
                          Text(_formatNumber(plays),
                              style: text.bodySmall?.copyWith(
                                  color: scheme.primary, fontWeight: FontWeight.w600)),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              );
            }(),
          ],

          const SizedBox(height: 24),

          _SectionHeader(title: 'Mainstream vs Pépites', icon: Icons.diamond_outlined),
          const SizedBox(height: 8),
          Text('Compare tes artistes favoris à leur popularité mondiale.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),

          if (_gems.isEmpty && !_gemsLoading)
            FilledButton.icon(
              onPressed: _computeGems,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Calculer mon score'),
            )
          else if (_gemsLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16),
                child: CircularProgressIndicator()))
          else ...[
            ..._gems.asMap().entries.map((e) {
              final gem   = e.value;
              final isGem = gem.listeners < 500000;
              return Card(
                elevation: 0, color: scheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: Text(isGem ? '💎' : '🎤',
                      style: const TextStyle(fontSize: 24)),
                  title: Text(gem.name,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('${_formatNumber(gem.listeners)} auditeurs mondiaux',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  trailing: Text(isGem ? 'Pépite' : 'Mainstream',
                      style: text.labelSmall?.copyWith(
                          color: isGem ? scheme.tertiary : scheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
              );
            }),
            Center(child: TextButton(
                onPressed: _computeGems, child: const Text('Recalculer'))),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GemEntry {
  final String name;
  final int plays;
  final int listeners;
  const _GemEntry({required this.name, required this.plays, required this.listeners});
}

// ═══════════════════════════════════════════════════════════════════════════
// HISTORIQUE
// ═══════════════════════════════════════════════════════════════════════════
class _HistoryPage extends StatefulWidget {
  final LastFmService service;
  const _HistoryPage({required this.service});

  @override
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _tracks = [];
  bool _loading         = true;
  bool _loadingMore     = false;
  bool _exhausted       = false;
  String? _error;
  int _page             = 1;
  Map<String, dynamic>? _nowPlaying;

  String         _preset      = 'all';
  DateTimeRange? _customRange;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  (int?, int?) _getRange() {
    final now = DateTime.now();
    switch (_preset) {
      case 'today':
        final s = DateTime(now.year, now.month, now.day);
        return (s.millisecondsSinceEpoch ~/ 1000, now.millisecondsSinceEpoch ~/ 1000);
      case '7d':
        return (now.subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
                now.millisecondsSinceEpoch ~/ 1000);
      case '30d':
        return (now.subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
                now.millisecondsSinceEpoch ~/ 1000);
      case 'month':
        final s = DateTime(now.year, now.month, 1);
        return (s.millisecondsSinceEpoch ~/ 1000, now.millisecondsSinceEpoch ~/ 1000);
      case 'custom':
        if (_customRange != null) {
          return (
            _customRange!.start.millisecondsSinceEpoch ~/ 1000,
            _customRange!.end.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
          );
        }
        return (null, null);
      default:
        return (null, null);
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
      final (from, to) = _getRange();
      final data  = await widget.service.getRecentTracks(limit: 50, page: _page, from: from, to: to);
      final raw   = data['track'];
      final fresh = raw is List ? raw : (raw != null ? [raw] : <dynamic>[]);
      final attr  = data['@attr'] as Map?;
      final totalP = int.tryParse(attr?['totalPages']?.toString() ?? '1') ?? 1;

      Map<String, dynamic>? np;
      final list = <dynamic>[];
      for (final t in fresh) {
        if ((t as Map?)?['@attr']?['nowplaying'] == 'true') {
          np = t as Map<String, dynamic>;
        } else {
          list.add(t);
        }
      }
      setState(() {
        if (reset) _tracks = list; else _tracks.addAll(list);
        _nowPlaying  = reset ? np : (_nowPlaying ?? np);
        _exhausted   = _page >= totalP;
        _loading     = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate:  now,
      initialDateRange: _customRange ?? DateTimeRange(
          start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'Sélectionner une plage',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (range != null) {
      setState(() { _customRange = range; _preset = 'custom'; });
      _load(reset: true);
    }
  }

  void _selectPreset(String preset) {
    if (preset == 'custom') { _pickCustomRange(); return; }
    if (_preset == preset) return;
    setState(() => _preset = preset);
    _load(reset: true);
  }

  String get _customLabel {
    if (_customRange == null) return 'Personnalisé';
    final s = _customRange!.start;
    final e = _customRange!.end;
    return '${s.day}/${s.month} → ${e.day}/${e.month}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(children: [
                Expanded(child: Text('Historique',
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                if (_preset != 'all')
                  IconButton(icon: const Icon(Icons.filter_alt_off_rounded),
                      tooltip: 'Réinitialiser', onPressed: () => _selectPreset('all')),
                IconButton(icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => _load(reset: true)),
              ]),
            ),

            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                children: [
                  for (final (k, l) in const [
                    ('all',   'Tout'),
                    ('today', "Aujourd'hui"),
                    ('7d',    '7 jours'),
                    ('30d',   '30 jours'),
                    ('month', 'Ce mois'),
                  ])
                    Padding(padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(label: Text(l), selected: _preset == k,
                            onSelected: (_) => _selectPreset(k), showCheckmark: false)),
                  Padding(padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_preset == 'custom' ? _customLabel : 'Personnalisé'),
                      selected: _preset == 'custom',
                      avatar: Icon(Icons.date_range_rounded, size: 16,
                          color: _preset == 'custom'
                              ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
                      onSelected: (_) => _pickCustomRange(),
                      showCheckmark: false,
                    )),
                ],
              ),
            ),

            const Divider(height: 12),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: _ErrorView(message: _error!, onRetry: () => _load(reset: true)))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _load(reset: true),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (!_exhausted && !_loadingMore &&
                          n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                        _page++;
                        _load();
                      }
                      return false;
                    },
                    child: _tracks.isEmpty
                        ? Center(child: Text('Aucune écoute sur cette période.',
                            style: TextStyle(color: scheme.onSurfaceVariant)))
                        : ListView.builder(
                            itemCount: (_nowPlaying != null ? 1 : 0)
                                + _tracks.length
                                + (_loadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (_nowPlaying != null && i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                  child: _NowPlayingCard(track: _nowPlaying!),
                                );
                              }
                              final idx = _nowPlaying != null ? i - 1 : i;
                              if (idx == _tracks.length) {
                                return const Padding(padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()));
                              }
                              final t      = _tracks[idx] as Map;
                              final title  = (t['name']             ?? '').toString();
                              final artist = (t['artist']?['#text'] ?? '').toString();
                              final album  = (t['album']?['#text']  ?? '').toString();
                              final rawUrl = _extractImage(t['image']);
                              final dateRaw = t['date']?['#text'] ?? '';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 2),
                                leading: _SmartImage(
                                  size: 46, borderRadius: 6, initialUrl: rawUrl,
                                  resolver: () => ImageService.resolveTrack(title, artist,
                                      lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null),
                                ),
                                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                subtitle: Text(album.isNotEmpty ? '$artist · $album' : artist,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                                trailing: Text(_formatDate(dateRaw),
                                    style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                              );
                            },
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARAMÈTRES
// ═══════════════════════════════════════════════════════════════════════════

const _kAccentOptions = [
  (Color(0xFF7C3AED), 'purple', 'Violet'),
  (Color(0xFF1D4ED8), 'blue',   'Bleu'),
  (Color(0xFF059669), 'green',  'Vert'),
  (Color(0xFFDC2626), 'red',    'Rouge'),
  (Color(0xFFD97706), 'orange', 'Orange'),
  (Color(0xFFDB2777), 'pink',   'Rose'),
];

const _kStartupLabels = [
  (Icons.dashboard_rounded,    'Dashboard'),
  (Icons.emoji_events_rounded, 'Classements'),
  (Icons.auto_graph_rounded,   'Graphiques'),
  (Icons.history_rounded,      'Historique'),
];

class _SettingsPage extends StatefulWidget {
  final String username;
  const _SettingsPage({required this.username});

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  String       _theme              = 'system';
  String       _accent             = 'purple';
  bool         _useDynamicColor    = false;
  bool         _useNowPlayingColor = false;
  int          _startupTab         = 0;
  bool         _autoUpdate         = true;
  int          _npRefreshSec       = 30;
  int          _cacheAutoExpiry    = 0;
  List<String> _cardOrder          = _defaultCardOrder();
  Set<String>  _hiddenCards        = {};
  UpdateInfo?  _updateInfo;
  bool         _checkingUpdate     = false;
  String?      _updateError;

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) => _maybeCheckUpdate());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _theme              = prefs.getString('ls_theme')               ?? 'system';
      _accent             = prefs.getString('ls_accent')              ?? 'purple';
      _useDynamicColor    = prefs.getBool('ls_use_dynamic_color')     ?? false;
      _useNowPlayingColor = prefs.getBool('ls_use_nowplaying_color')  ?? false;
      _startupTab         = prefs.getInt('ls_startup_tab')            ?? 0;
      _autoUpdate         = prefs.getBool('ls_auto_update_check')     ?? true;
      _npRefreshSec       = prefs.getInt('ls_np_refresh_sec')         ?? 30;
      _cacheAutoExpiry    = prefs.getInt('ls_cache_auto_expiry')      ?? 0;
      final orderStr  = prefs.getString('ls_card_order')  ?? '';
      final hiddenStr = prefs.getString('ls_card_hidden') ?? '';
      _hiddenCards = hiddenStr.isEmpty ? {} : hiddenStr.split(',').toSet();
      if (orderStr.isNotEmpty) {
        final saved   = orderStr.split(',');
        final missing = _defaultCardOrder().where((id) => !saved.contains(id));
        _cardOrder    = [...saved, ...missing];
      } else {
        _cardOrder = _defaultCardOrder();
      }
    });
  }


  Future<void> _maybeCheckUpdate() async {
    if (!_autoUpdate) return;
    final prefs     = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('ls_last_update_check') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - lastCheck <
        const Duration(days: 1).inMilliseconds) return;
    await _checkUpdate(auto: true);
  }

  Future<void> _checkUpdate({bool auto = false}) async {
    if (!mounted) return;
    setState(() { _checkingUpdate = true; _updateError = null; });
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ls_last_update_check', DateTime.now().millisecondsSinceEpoch);
      setState(() { _updateInfo = info; _checkingUpdate = false; });
    } catch (_) {
      if (mounted) setState(() { _updateError = 'Vérification impossible.'; _checkingUpdate = false; });
    }
  }

  Future<void> _setPref<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool)   await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is int)    await prefs.setInt(key, value);
  }

  Future<void> _setTheme(String v) async {
    await _setPref('ls_theme', v);
    setState(() => _theme = v);
    themeModeNotifier.value = themeFromString(v);
  }

  Future<void> _setAccent(String key, Color color) async {
    await _setPref('ls_accent', key);
    setState(() => _accent = key);
    if (!_useDynamicColor && !_useNowPlayingColor) accentNotifier.value = color;
  }

  void _openCardEditor() {
    // Copie locale pour l'édition
    var order  = List<String>.from(_cardOrder);
    var hidden = Set<String>.from(_hiddenCards);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            builder: (_, ctrl) => Column(children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(children: [
                  Expanded(child: Text('Cartes du Dashboard',
                      style: Theme.of(ctx).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('ls_card_order',  order.join(','));
                      await prefs.setString('ls_card_hidden', hidden.join(','));
                      if (!mounted) return;
                      setState(() { _cardOrder = order; _hiddenCards = hidden; });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Enregistrer'),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Appuyez sur ☰ pour réordonner, sur la case pour afficher/masquer.',
                    style: Theme.of(ctx).textTheme.bodySmall
                        ?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView(
                  scrollController: ctrl,
                  onReorder: (old, nw) {
                    setLocal(() {
                      if (nw > old) nw--;
                      final item = order.removeAt(old);
                      order.insert(nw, item);
                    });
                  },
                  children: order.map((id) {
                    final meta = _kDashCards.firstWhere(
                        (c) => c.$1 == id,
                        orElse: () => (id, id, Icons.widgets_rounded));
                    final isHidden = hidden.contains(id);
                    return ListTile(
                      key: ValueKey(id),
                      leading: Icon(meta.$3,
                          color: isHidden
                              ? Theme.of(ctx).colorScheme.onSurfaceVariant
                              : Theme.of(ctx).colorScheme.primary),
                      title: Text(meta.$2,
                          style: TextStyle(
                              color: isHidden
                                  ? Theme.of(ctx).colorScheme.onSurfaceVariant
                                  : null)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Checkbox(
                          value: !isHidden,
                          onChanged: (v) => setLocal(() {
                            if (v == true) hidden.remove(id);
                            else hidden.add(id);
                          }),
                        ),
                        const SizedBox(width: 4),
                        ReorderableDragStartListener(
                          index: order.indexOf(id),
                          child: const Icon(Icons.drag_handle_rounded),
                        ),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ]),
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Paramètres', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          if (_updateInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(Icons.system_update_rounded, color: scheme.onTertiaryContainer, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mise à jour — v${_updateInfo!.version}',
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700,
                          color: scheme.onTertiaryContainer)),
                  if (_updateInfo!.notes.isNotEmpty)
                    Text(_updateInfo!.notes.length > 120
                        ? '${_updateInfo!.notes.substring(0, 120)}…' : _updateInfo!.notes,
                        style: text.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer.withValues(alpha: 0.8))),
                ])),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final url = Uri.parse(_updateInfo!.hasApk
                        ? _updateInfo!.apkUrl! : _updateInfo!.releaseUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
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

          // APPARENCE
          _SettingsSection(label: 'Apparence', children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              ]),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.palette_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text("Couleur d'accent", style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (_useDynamicColor || _useNowPlayingColor) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Auto', style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                  ],
                ]),
                const SizedBox(height: 12),
                Opacity(
                  opacity: (_useDynamicColor || _useNowPlayingColor) ? 0.35 : 1.0,
                  child: Wrap(spacing: 10, runSpacing: 10,
                    children: _kAccentOptions.map((opt) {
                      final (color, key, label) = opt;
                      final sel = _accent == key;
                      return GestureDetector(
                        onTap: (_useDynamicColor || _useNowPlayingColor) ? null : () => _setAccent(key, color),
                        child: Tooltip(message: label,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle,
                              border: sel
                                  ? Border.all(color: scheme.onSurface, width: 3)
                                  : Border.all(color: Colors.transparent, width: 3),
                              boxShadow: sel
                                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                                  : [],
                            ),
                            child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
            ),
          ]),

          const SizedBox(height: 16),

          // COULEUR DYNAMIQUE
          _SettingsSection(label: 'Couleur dynamique', children: [
            SwitchListTile(
              secondary: Icon(Icons.colorize_rounded, color: scheme.primary),
              title: const Text('Material You'),
              subtitle: const Text('Utilise la couleur du thème Android'),
              value: _useDynamicColor,
              onChanged: (v) async {
                await _setPref('ls_use_dynamic_color', v);
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
                await _setPref('ls_use_nowplaying_color', v);
                setState(() => _useNowPlayingColor = v);
                useNowPlayingColorNotifier.value = v;
                if (!v) accentNotifier.value = accentFromString(_accent);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('Quand une musique est en lecture, sa couleur dominante remplace la couleur d\'accent.',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ]),

          const SizedBox(height: 16),

          // PAGE DE DÉMARRAGE
          _SettingsSection(label: 'Page de démarrage', children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.rocket_launch_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text("Onglet à l'ouverture",
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _kStartupLabels.asMap().entries.map((e) => FilterChip(
                    avatar: Icon(e.value.$1, size: 16),
                    label: Text(e.value.$2),
                    selected: _startupTab == e.key,
                    onSelected: (_) async {
                      await _setPref('ls_startup_tab', e.key);
                      setState(() => _startupTab = e.key);
                    },
                    showCheckmark: false,
                  )).toList(),
                ),
              ]),
            ),
          ]),

          const SizedBox(height: 16),

          // DASHBOARD
          _SettingsSection(label: 'Dashboard', children: [
            ListTile(
              leading: Icon(Icons.view_list_rounded, color: scheme.primary, size: 22),
              title: const Text('Personnaliser les cartes'),
              subtitle: const Text('Ordre, visibilité de chaque section'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openCardEditor(),
            ),
          ]),


          const SizedBox(height: 16),

          // TECHNIQUE
          _SettingsSection(label: 'Technique', children: [

            // Intervalle Now Playing
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.timer_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Rafraîchissement "En cours"',
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8,
                  children: const [
                    (0,  'Désactivé'),
                    (15, '15 s'),
                    (30, '30 s'),
                    (60, '1 min'),
                    (120,'2 min'),
                  ].map((opt) {
                    final (secs, label) = opt;
                    return FilterChip(
                      label: Text(label),
                      selected: _npRefreshSec == secs,
                      showCheckmark: false,
                      onSelected: (_) async {
                        await _setPref('ls_np_refresh_sec', secs);
                        setState(() => _npRefreshSec = secs);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ]),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Cache images
            ListTile(
              leading: Icon(Icons.image_outlined, color: scheme.primary),
              title: const Text('Cache images'),
              subtitle: Text('${ImageService.cacheSize} entrées en mémoire'),
              trailing: TextButton(
                onPressed: () {
                  ImageService.clearCache();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache images vidé.')));
                },
                child: const Text('Vider'),
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Vider cache auto
            ListTile(
              leading: Icon(Icons.auto_delete_outlined, color: scheme.primary),
              title: const Text('Vider le cache automatiquement'),
              subtitle: Text(_cacheAutoExpiry == 0
                  ? 'Jamais'
                  : _cacheAutoExpiry == 1
                      ? 'Au démarrage'
                      : 'Toutes les $_cacheAutoExpiry heures'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Vider le cache auto'),
                  children: const [
                    (0,   'Jamais'),
                    (1,   'Au démarrage'),
                    (6,   'Toutes les 6 h'),
                    (24,  'Toutes les 24 h'),
                    (168, 'Toutes les 7 j'),
                  ].map((opt) {
                    final (h, label) = opt;
                    return SimpleDialogOption(
                      onPressed: () async {
                        await _setPref('ls_cache_auto_expiry', h);
                        setState(() => _cacheAutoExpiry = h);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(label,
                          style: TextStyle(
                              fontWeight: _cacheAutoExpiry == h
                                  ? FontWeight.w700 : FontWeight.normal)),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Exporter préférences
            ListTile(
              leading: Icon(Icons.download_rounded, color: scheme.primary),
              title: const Text('Exporter mes préférences'),
              subtitle: const Text('Résumé JSON de tous tes réglages'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final keys  = prefs.getKeys()
                    .where((k) => k.startsWith('ls_'))
                    .toList()..sort();
                final json  = '{\n${keys.map((k) {
                  final v = prefs.get(k);
                  return '  "$k": ${v is String ? '"$v"' : v}';
                }).join(',\n')}\n}';
                if (!context.mounted) return;
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Préférences LastStats'),
                    content: SingleChildScrollView(
                      child: SelectableText(json,
                          style: Theme.of(ctx).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'))),
                    actions: [TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer'))],
                  ),
                );
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Réinitialiser
            ListTile(
              leading: Icon(Icons.delete_sweep_rounded, color: scheme.error),
              title: Text('Réinitialiser les préférences',
                  style: TextStyle(color: scheme.error)),
              subtitle: const Text('Remet tous les réglages par défaut'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Réinitialiser ?'),
                    content: const Text(
                        'Tous tes réglages seront remis à zéro. '
                        'Ton compte ne sera pas déconnecté.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler')),
                      FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Réinitialiser')),
                    ],
                  ),
                );
                if (ok == true) {
                  final prefs = await SharedPreferences.getInstance();
                  for (final k in prefs.getKeys()
                      .where((k) => k.startsWith('ls_') &&
                          k != 'ls_username' && k != 'ls_apikey')
                      .toList()) {
                    await prefs.remove(k);
                  }
                  ImageService.clearCache();
                  themeModeNotifier.value          = ThemeMode.system;
                  accentNotifier.value             = const Color(0xFF7C3AED);
                  useDynamicColorNotifier.value    = false;
                  useNowPlayingColorNotifier.value = false;
                  if (!mounted) return;
                  setState(() {
                    _theme               = 'system';
                    _accent              = 'purple';
                    _useDynamicColor     = false;
                    _useNowPlayingColor  = false;
                    _npRefreshSec        = 30;
                    _cacheAutoExpiry     = 0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Préférences réinitialisées.')));
                }
              },
            ),
          ]),

          const SizedBox(height: 16),

          // COMPTE
          _SettingsSection(label: 'Compte', children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text(widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                    style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
              ),
              title: Text(widget.username, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Profil Last.fm connecté'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: scheme.error),
              title: Text('Se déconnecter', style: TextStyle(color: scheme.error)),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Se déconnecter ?'),
                    content: const Text('Tes identifiants seront supprimés de l\'appareil.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter')),
                    ],
                  ),
                );
                if (ok == true && mounted) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('ls_username');
                  await prefs.remove('ls_apikey');
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SetupScreen()), (_) => false);
                }
              },
            ),
          ]),

          const SizedBox(height: 16),

          // MISES À JOUR
          _SettingsSection(label: 'Mises à jour', children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Vérification automatique'),
              subtitle: const Text('1 fois par jour'),
              value: _autoUpdate,
              onChanged: (v) async { await _setPref('ls_auto_update_check', v); setState(() => _autoUpdate = v); },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: _checkingUpdate
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.system_update_outlined),
              title: const Text('Vérifier maintenant'),
              subtitle: _updateError != null
                  ? Text(_updateError!, style: TextStyle(color: scheme.error))
                  : (_updateInfo == null ? const Text('À jour')
                      : Text('v${_updateInfo!.version} disponible')),
              onTap: _checkingUpdate ? null : () => _checkUpdate(),
            ),
          ]),

          const SizedBox(height: 16),

          // À PROPOS
          _SettingsSection(label: 'À propos', children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Version'),
              trailing: Text(UpdateService.currentVersion,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.web_rounded),
              title: const Text('Version web complète'),
              subtitle: const Text('sanobld.github.io/LastStats'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () async {
                final uri = Uri.parse('https://sanobld.github.io/LastStats');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('Code source'),
              subtitle: const Text('github.com/sanobld/LastStats'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () async {
                final uri = Uri.parse('https://github.com/sanobld/LastStats');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          ]),

          const SizedBox(height: 24),
          Center(child: Text('LastStats Mobile v${UpdateService.currentVersion}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════════════════════════════════════

class _SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _SettingsSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(label.toUpperCase(),
            style: text.labelSmall?.copyWith(
                color: scheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ),
      Card(
        elevation: 0, color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      ),
    ]);
  }
}

class _SmartImage extends StatelessWidget {
  final String? initialUrl;
  final Future<String> Function() resolver;
  final double size;
  final double borderRadius;

  const _SmartImage({required this.resolver, required this.size,
      required this.borderRadius, this.initialUrl});

  static const _ph = '2a96cbd8b46e442fc41c2b86b821562f';
  bool get _needsResolve =>
      initialUrl == null || initialUrl!.isEmpty || initialUrl!.contains(_ph);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_needsResolve) return _buildImage(initialUrl!, scheme);
    return FutureBuilder<String>(
      future: resolver(),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) return _loadingBox(scheme);
        final url = snap.data ?? '';
        return url.isEmpty ? _fallbackBox(scheme) : _buildImage(url, scheme);
      },
    );
  }

  Widget _buildImage(String url, ColorScheme scheme) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackBox(scheme)),
  );

  Widget _loadingBox(ColorScheme scheme) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Container(width: size, height: size, color: scheme.surfaceContainerHighest,
      child: Center(child: SizedBox(width: size * 0.4, height: size * 0.4,
          child: CircularProgressIndicator(strokeWidth: 1.5,
              color: scheme.primary.withValues(alpha: 0.5))))),
  );

  Widget _fallbackBox(ColorScheme scheme) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Container(width: size, height: size, color: scheme.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded,
          color: scheme.onSurfaceVariant, size: size * 0.5)),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? sub;
  const _StatCard({required this.icon, required this.value, required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Card(
      elevation: 0, color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(20),
        child: Row(children: [
          Icon(icon, color: scheme.onPrimaryContainer, size: 36),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
            Text(label, style: text.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
            if (sub != null)
              Text(sub!, style: text.bodySmall?.copyWith(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.65))),
          ]),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, color: scheme.primary, size: 20),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700)),
    ]);
  }
}

class _ItemTile extends StatelessWidget {
  final String  name;
  final String  sub;
  final String  imageUrl;
  final Future<String>? imageFuture;
  final String  rank;
  final String? plays;

  const _ItemTile({required this.name, required this.sub, required this.imageUrl,
      required this.rank, this.imageFuture, this.plays});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(children: [
        SizedBox(width: 28, child: Text(rank, textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
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
        if (plays != null)
          Padding(padding: const EdgeInsets.only(left: 8),
            child: Text(plays!, style: text.bodySmall?.copyWith(
                color: scheme.primary, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
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
      ]),
    ));
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

String _formatNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

/// Nombre complet avec séparateur millier (espace insécable).
String _formatFull(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F'); // espace fine
    buf.write(s[i]);
  }
  return buf.toString();
}


String _formatDate(String raw) {
  if (raw.isEmpty) return '';
  try {
    final parts = raw.split(', ');
    if (parts.length == 2) return '${parts[0]} · ${parts[1]}';
  } catch (_) {}
  return raw;
}