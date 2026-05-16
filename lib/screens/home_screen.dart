import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lastfm_service.dart';
import 'setup_screen.dart';

// ─── Image par défaut Last.fm ──────────────────────────
const _kDefaultImg =
    'https://lastfm.freetls.fastly.net/i/u/300x300/2a96cbd8b46e442fc41c2b86b821562f.png';

// ─── Périodes disponibles ──────────────────────────────
const _kPeriods = [
  ('7day',    'Semaine'),
  ('1month',  'Mois'),
  ('3month',  '3 mois'),
  ('6month',  '6 mois'),
  ('12month', 'Année'),
  ('overall', 'Tout'),
];

class HomeScreen extends StatefulWidget {
  final String username;
  final String apiKey;

  const HomeScreen({
    super.key,
    required this.username,
    required this.apiKey,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final LastFmService _service;

  @override
  void initState() {
    super.initState();
    _service = LastFmService(apiKey: widget.apiKey, username: widget.username);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(service: _service, username: widget.username),
      _TopListPage(service: _service, type: 'artists'),
      _TopListPage(service: _service, type: 'albums'),
      _TopListPage(service: _service, type: 'tracks'),
      _SettingsPage(username: widget.username),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Artistes',
          ),
          NavigationDestination(
            icon: Icon(Icons.album_outlined),
            selectedIcon: Icon(Icons.album_rounded),
            label: 'Albums',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note_rounded),
            label: 'Titres',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════
class _DashboardPage extends StatefulWidget {
  final LastFmService service;
  final String username;
  const _DashboardPage({required this.service, required this.username});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  Map<String, dynamic>? _userInfo;
  List<dynamic> _topArtists = [];
  List<dynamic> _topAlbums  = [];
  List<dynamic> _topTracks  = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.service.getUserInfo(),
        widget.service.getTopArtists(period: 'overall', limit: 5),
        widget.service.getTopAlbums(period: 'overall',  limit: 5),
        widget.service.getTopTracks(period: 'overall',  limit: 5),
      ]);
      setState(() {
        _userInfo   = results[0] as Map<String, dynamic>?;
        _topArtists = results[1] as List<dynamic>;
        _topAlbums  = results[2] as List<dynamic>;
        _topTracks  = results[3] as List<dynamic>;
        _loading    = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);

    final info       = _userInfo!;
    final name       = (info['name']      ?? widget.username).toString();
    final realName   = (info['realname']  ?? '').toString();
    final country    = (info['country']   ?? '').toString();
    final scrobbles  = (info['playcount'] ?? '0').toString();
    final regRaw     = info['registered'];
    final registered = regRaw is Map
        ? (regRaw['#text'] ?? '').toString()
        : regRaw?.toString() ?? '';
    final avatarUrl  = _extractImage(info['image']);

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // ── AppBar avec profil ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primaryContainer,
                      scheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: scheme.primary.withValues(alpha: 0.2),
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl.isEmpty
                              ? Icon(Icons.person_rounded, size: 40,
                                  color: scheme.onPrimaryContainer)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text('@$name',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Stat scrobbles ──
                _StatCard(
                  icon: Icons.headphones_rounded,
                  value: _formatNumber(int.tryParse(scrobbles) ?? 0),
                  label: 'Scrobbles au total',
                  sub: registered.isNotEmpty ? 'Membre depuis $registered' : null,
                ),
                const SizedBox(height: 20),

                // ── Top Artistes ──
                _SectionHeader(title: 'Top Artistes', icon: Icons.mic_rounded),
                const SizedBox(height: 8),
                ..._topArtists.map((a) => _ItemTile(
                  name:   (a['name'] ?? '').toString(),
                  sub:    '${_formatNumber(int.tryParse((a['playcount'] ?? '0').toString()) ?? 0)} écoutes',
                  imageUrl: _extractImage(a['image']),
                  rank:   (_topArtists.indexOf(a) + 1).toString(),
                )),
                const SizedBox(height: 20),

                // ── Top Albums ──
                _SectionHeader(title: 'Top Albums', icon: Icons.album_rounded),
                const SizedBox(height: 8),
                ..._topAlbums.map((a) => _ItemTile(
                  name:   (a['name'] ?? '').toString(),
                  sub:    (a['artist']?['name'] ?? '').toString(),
                  imageUrl: _extractImage(a['image']),
                  rank:   (_topAlbums.indexOf(a) + 1).toString(),
                  plays:  _formatNumber(int.tryParse((a['playcount'] ?? '0').toString()) ?? 0),
                )),
                const SizedBox(height: 20),

                // ── Top Titres ──
                _SectionHeader(title: 'Top Titres', icon: Icons.music_note_rounded),
                const SizedBox(height: 8),
                ..._topTracks.map((t) => _ItemTile(
                  name:   (t['name'] ?? '').toString(),
                  sub:    (t['artist']?['name'] ?? '').toString(),
                  imageUrl: _extractImage(t['image']),
                  rank:   (_topTracks.indexOf(t) + 1).toString(),
                  plays:  _formatNumber(int.tryParse((t['playcount'] ?? '0').toString()) ?? 0),
                )),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PAGE TOP LISTE (artistes / albums / titres)
// ═══════════════════════════════════════════════════════
class _TopListPage extends StatefulWidget {
  final LastFmService service;
  final String type; // 'artists' | 'albums' | 'tracks'

  const _TopListPage({required this.service, required this.type});

  @override
  State<_TopListPage> createState() => _TopListPageState();
}

class _TopListPageState extends State<_TopListPage> {
  String _period = 'overall';
  List<dynamic> _items    = [];
  bool _loading   = true;
  bool _loadingMore = false;
  bool _exhausted = false;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _exhausted = false; _items = []; });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      List<dynamic> fresh;
      if (widget.type == 'artists') {
        fresh = await widget.service.getTopArtists(period: _period, limit: 50, page: _page);
      } else if (widget.type == 'albums') {
        fresh = await widget.service.getTopAlbums(period: _period, limit: 50, page: _page);
      } else {
        fresh = await widget.service.getTopTracks(period: _period, limit: 50, page: _page);
      }

      setState(() {
        _items.addAll(fresh);
        _exhausted = fresh.length < 50;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  String get _title {
    switch (widget.type) {
      case 'artists': return 'Artistes';
      case 'albums':  return 'Albums';
      default:        return 'Titres';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case 'artists': return Icons.mic_rounded;
      case 'albums':  return Icons.album_rounded;
      default:        return Icons.music_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Titre ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Icon(_icon, color: scheme.primary),
                  const SizedBox(width: 10),
                  Text(_title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            // ── Sélecteur de période ──
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: _kPeriods.map((p) {
                  final selected = p.$1 == _period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p.$2),
                      selected: selected,
                      onSelected: (_) {
                        if (!selected) {
                          _period = p.$1;
                          _load(reset: true);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1),

            // ── Liste ──
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: () => _load(reset: true))
                      : _items.isEmpty
                          ? Center(child: Text('Aucun résultat', style: TextStyle(color: scheme.onSurfaceVariant)))
                          : NotificationListener<ScrollNotification>(
                              onNotification: (n) {
                                if (!_exhausted && !_loadingMore &&
                                    n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                                  _page++;
                                  _load();
                                }
                                return false;
                              },
                              child: ListView.builder(
                                itemCount: _items.length + (_loadingMore ? 1 : 0),
                                itemBuilder: (ctx, i) {
                                  if (i == _items.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  final item = _items[i];
                                  final name  = (item['name'] ?? '').toString();
                                  final plays = _formatNumber(
                                      int.tryParse((item['playcount'] ?? '0').toString()) ?? 0);
                                  final sub   = widget.type != 'artists'
                                      ? (item['artist']?['name'] ?? '').toString()
                                      : plays + ' écoutes';
                                  final imgUrl = _extractImage(item['image']);

                                  return _ItemTile(
                                    name:     name,
                                    sub:      sub,
                                    imageUrl: imgUrl,
                                    rank:     (i + 1).toString(),
                                    plays:    widget.type != 'artists' ? plays : null,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PARAMÈTRES
// ═══════════════════════════════════════════════════════
class _SettingsPage extends StatelessWidget {
  final String username;
  const _SettingsPage({required this.username});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Paramètres',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: const Text('Profil connecté'),
                  subtitle: Text('@$username'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: scheme.error),
                  title: Text('Se déconnecter',
                      style: TextStyle(color: scheme.error)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Se déconnecter ?'),
                        content: const Text(
                            'Tes identifiants seront supprimés de l\'appareil.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Déconnecter'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('ls_username');
                      await prefs.remove('ls_apikey');
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SetupScreen()),
                          (_) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('LastStats Mobile v1.0.0',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════════════════

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
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: scheme.onPrimaryContainer, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer)),
                Text(label,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
                if (sub != null)
                  Text(sub!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.65))),
              ],
            ),
          ],
        ),
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
    return Row(
      children: [
        Icon(icon, color: scheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String name;
  final String sub;
  final String imageUrl;
  final String rank;
  final String? plays;
  const _ItemTile({
    required this.name,
    required this.sub,
    required this.imageUrl,
    required this.rank,
    this.plays,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    final url = imageUrl.isNotEmpty && !imageUrl.contains('2a96cbd8b46e442fc41c2b86b821562f')
        ? imageUrl
        : _kDefaultImg;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Numéro de rang
          SizedBox(
            width: 28,
            child: Text(rank,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: scheme.surfaceContainerHighest,
                child: Icon(Icons.music_note_rounded,
                    color: scheme.onSurfaceVariant, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nom + sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          // Nombre d'écoutes (si fourni)
          if (plays != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(plays!,
                style: text.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600)),
            ),
        ],
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────

String _extractImage(dynamic images) {
  if (images == null) return '';
  final list = images is List ? images : [];
  if (list.isEmpty) return '';
  try {
    final large = list.lastWhere(
      (i) => i is Map && i['size'] == 'extralarge',
      orElse: () => list.last,
    );
    return (large is Map ? large['#text'] ?? '' : '').toString();
  } catch (_) {
    return '';
  }
}

String _formatNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}
