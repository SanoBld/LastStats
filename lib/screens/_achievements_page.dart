// Achievements sheet: opens from the profile menu at home.
// Top: overall profile tier ring. Below: one card per category
// (Listening / Artists / Albums / Loyalty), each showing a textured tier
// swatch, a short description, and current progress. Tapping a card opens
// the full milestone list for that category.
part of 'home_screen.dart';

void showAchievementsSheet(BuildContext context, Map<String, dynamic>? userInfo, {bool isSelf = false}) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    fullscreenDialog: true,
    pageBuilder: (_, _, _) => _AchievementsSheet(userInfo: userInfo, isSelf: isSelf),
    transitionsBuilder: (_, anim, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 380),
  ));
}

int _yearsSince(dynamic registered) => (_daysSince(registered) / 365).floor();

int _daysSince(dynamic registered) {
  if (registered == null) return 0;
  final ts = registered is Map
      ? int.tryParse((registered['#text'] ?? registered['unixtime'] ?? '0').toString()) ?? 0
      : int.tryParse(registered.toString()) ?? 0;
  if (ts <= 0) return 0;
  return ((DateTime.now().millisecondsSinceEpoch / 1000 - ts) / 86400).floor();
}

class _AchievementsSheet extends StatelessWidget {
  final Map<String, dynamic>? userInfo;
  final bool isSelf;
  const _AchievementsSheet({required this.userInfo, this.isSelf = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total   = int.tryParse((userInfo?['playcount']    ?? '0').toString()) ?? 0;
    final artists = int.tryParse((userInfo?['artist_count'] ?? '0').toString()) ?? 0;
    final albums  = int.tryParse((userInfo?['album_count']  ?? '0').toString()) ?? 0;
    final tracks  = int.tryParse((userInfo?['track_count']  ?? '0').toString()) ?? 0;
    final days    = _daysSince(userInfo?['registered']);
    final weekly  = days > 0 ? ((total / days) * 7).round() : 0;

    final list = computeAchievements(
      totalScrobbles: total, artistCount: artists,
      albumCount: albums, trackCount: tracks,
      yearsRegistered: _yearsSince(userInfo?['registered']), weeklyAvg: weekly,
    );
    final unlocked = list.where((a) => a.unlocked).length;
    final myTier   = profileTier(unlocked);
    final avatarUrl = _extractImage(userInfo?['image']);
    final level     = accountLevel(total);
    final lvlFrom   = levelThreshold(level);
    final lvlTo     = levelThreshold(level + 1);
    final lvlRatio  = lvlTo > lvlFrom ? (total - lvlFrom) / (lvlTo - lvlFrom) : 0.0;

    final byCategory = <AchvCategory, List<AchievementProgress>>{};
    for (final a in list) {
      byCategory.putIfAbsent(a.def.category, () => []).add(a);
    }

    return Scaffold(
      appBar: AppBar(title: Text(L.achvTitle), scrolledUnderElevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Center(
            child: Column(children: [
              _AchvTierBadge(tier: myTier, size: 92, avatarUrl: avatarUrl),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: isSelf ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _LevelHistoryPage())) : null,
                child: Column(children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_ct('Niveau $level', 'Level $level'),
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    if (isSelf) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 20, color: scheme.onSurfaceVariant),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: lvlRatio.clamp(0.0, 1.0), minHeight: 5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$total / $lvlTo', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 4),
              Text(L.achvUnlocked(unlocked, list.length),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: AchvCategory.values.map((cat) {
              final items = byCategory[cat]!;
              return _AchvCategoryCard(category: cat, items: items);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Category card (grid tile) ───────────────────────────────────────────────

class _AchvCategoryCard extends StatelessWidget {
  final AchvCategory category;
  final List<AchievementProgress> items;
  const _AchvCategoryCard({required this.category, required this.items});

  (String, String, IconData) _meta() => switch (category) {
    AchvCategory.listening => (L.achvCatListening, L.achvDescListening, Icons.headphones_rounded),
    AchvCategory.artists   => (L.achvCatArtists,   L.achvDescArtists,   Icons.mic_external_on_rounded),
    AchvCategory.albums    => (L.achvCatAlbums,    L.achvDescAlbums,    Icons.album_rounded),
    AchvCategory.tracks    => (L.achvCatTracks,    L.achvDescTracks,    Icons.music_note_rounded),
    AchvCategory.loyalty   => (L.achvCatLoyalty,   L.achvDescLoyalty,   Icons.cake_rounded),
    AchvCategory.pace      => (L.achvCatPace,      L.achvDescPace,      Icons.speed_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final (title, desc, icon) = _meta();
    final summary = summarizeCategory(items);
    final scheme  = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _AchvCategoryDetailPage(
          category: category, items: items, title: title, description: desc, icon: icon,
        ),
      )),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: scheme.surfaceContainerHigh,
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Textured tier swatch at top — noticeable sheen, no 3D.
            SizedBox(
              height: 64,
              width: double.infinity,
              child: _AchvTierSurface(tier: summary.tier, child: Center(
                child: Icon(icon, size: 26,
                    color: summary.tier == CardTier.none ? scheme.onSurfaceVariant : Colors.black87),
              )),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, height: 1.25)),
                      ],
                    ),
                    Text(
                      summary.next == null
                          ? '${summary.current} · ${tierLabel(summary.tier)}'
                          : '${summary.current} / ${summary.next!.def.threshold}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category detail page (full milestone list) ─────────────────────────────

class _AchvCategoryDetailPage extends StatelessWidget {
  final AchvCategory category;
  final List<AchievementProgress> items;
  final String title, description;
  final IconData icon;
  const _AchvCategoryDetailPage({
    required this.category, required this.items,
    required this.title, required this.description, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title), scrolledUnderElevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(description, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 18),
          ...items.map((a) => _AchvMilestoneTile(a: a, icon: icon)),
        ],
      ),
    );
  }
}

class _AchvMilestoneTile extends StatelessWidget {
  final AchievementProgress a;
  final IconData icon;
  const _AchvMilestoneTile({required this.a, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio  = (a.current / a.def.threshold).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => _openAchvCard(context, a, icon),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHigh,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AchvTierBadge(tier: a.def.tier, size: 46, icon: icon, dim: !a.unlocked),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(tierLabel(a.def.tier),
                      style: TextStyle(fontWeight: FontWeight.w700,
                          color: a.unlocked ? null : scheme.onSurfaceVariant)),
                  const SizedBox(width: 6),
                  Icon(a.unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                      size: 15, color: a.unlocked ? Colors.green : scheme.onSurfaceVariant),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio, minHeight: 5,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: a.unlocked ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${a.current} / ${a.def.threshold}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── 3D badge card viewer ────────────────────────────────────────────────────

void _openAchvCard(BuildContext context, AchievementProgress a, IconData icon) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black87,
    barrierDismissible: true,
    pageBuilder: (_, _, _) => _AchvCardViewer(a: a, icon: icon),
    transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 220),
  ));
}

// Same Tilt3DCard used for artwork, adapted for a badge: front is the
// textured tier surface + icon, back shows the level details.
class _AchvCardViewer extends StatelessWidget {
  final AchievementProgress a;
  final IconData icon;
  const _AchvCardViewer({required this.a, required this.icon});

  @override
  Widget build(BuildContext context) {
    final size  = MediaQuery.of(context).size;
    final cardW = math.min(size.width * 0.72, 300.0);
    final cardH = cardW * 1.35;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Tilt3DCard(
                width: cardW, height: cardH,
                tier: a.unlocked ? a.def.tier : CardTier.none,
                front: _AchvTierSurface(
                  tier: a.def.tier,
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 60, color: Colors.black87),
                      const SizedBox(height: 14),
                      Text(tierLabel(a.def.tier), style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
                    ]),
                  ),
                ),
                back: Container(
                  color: const Color(0xFF171717),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tierLabel(a.def.tier), style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text('${a.current} / ${a.def.threshold}',
                          style: const TextStyle(color: Colors.white70, fontSize: 15)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Icon(a.unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                            size: 16, color: a.unlocked ? Colors.green : Colors.white38),
                        const SizedBox(width: 6),
                        Text(a.unlocked ? 'Débloqué' : 'Verrouillé',
                            style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topPad + 8, right: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Level history (own account only — needs full scrobble timestamps) ──────

// Walks the full local scrobble history once and records the moment the
// cumulative count first crossed each level's threshold.
List<(int level, int ts)> _computeLevelHistory() {
  final years = AllScrobblesService.getCachedYears()..sort();
  final allTs = <int>[];
  for (final y in years) {
    allTs.addAll(AllScrobblesService.getTimestampsForYear(y) ?? []);
  }
  allTs.sort();

  final history = <(int, int)>[];
  var lastLevel = 0;
  for (var i = 0; i < allTs.length; i++) {
    final lvl = accountLevel(i + 1);
    if (lvl > lastLevel) {
      history.add((lvl, allTs[i]));
      lastLevel = lvl;
    }
  }
  return history.reversed.toList(); // most recent first
}

class _LevelHistoryPage extends StatelessWidget {
  const _LevelHistoryPage();

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final history = _computeLevelHistory();

    return Scaffold(
      appBar: AppBar(
        title: Text(_ct('Historique des niveaux', 'Level history')),
        scrolledUnderElevation: 0,
      ),
      body: history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _ct('Pas encore assez de données — synchronise ton historique complet dans les réglages.',
                      'Not enough data yet — sync your full history in Settings.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final (level, ts) = history[i];
                final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                final dateStr = '${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/${date.year}';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Text('$level', style: TextStyle(
                        color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  title: Text(_ct('Niveau $level', 'Level $level')),
                  trailing: Text(dateStr, style: TextStyle(color: scheme.onSurfaceVariant)),
                );
              },
            ),
    );
  }
}

// Flat rectangular surface with the tier's metallic sheen, used as the
// header strip of category cards. The sheen slowly sweeps across it
// (shared clock — see TierShimmer) so tiers read as distinct, alive
// materials instead of a flat color block.
class _AchvTierSurface extends StatefulWidget {
  final CardTier tier;
  final Widget? child;
  const _AchvTierSurface({required this.tier, this.child});

  @override
  State<_AchvTierSurface> createState() => _AchvTierSurfaceState();
}

class _AchvTierSurfaceState extends State<_AchvTierSurface> {
  @override
  void initState() {
    super.initState();
    TierShimmer.ensureRunning();
  }

  @override
  Widget build(BuildContext context) {
    final grad = tierGradient(widget.tier);
    if (grad == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: widget.child,
      );
    }
    return ValueListenableBuilder<double>(
      valueListenable: TierShimmer.phase,
      builder: (context, phase, child) {
        final s = math.sin(phase * 2 * math.pi) * 0.5;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: grad, stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              begin: Alignment(-1 + s, -1), end: Alignment(1 + s, 1),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// Circular tier badge with the same moving sheen. Can show either an icon
// (achievement badges) or a profile photo clipped inside the ring (used
// for the account summary at the top of the sheet).
class _AchvTierBadge extends StatefulWidget {
  final CardTier tier;
  final double size;
  final IconData? icon;
  final String? avatarUrl;
  final bool dim;
  const _AchvTierBadge({
    required this.tier, required this.size,
    this.icon, this.avatarUrl, this.dim = false,
  });

  @override
  State<_AchvTierBadge> createState() => _AchvTierBadgeState();
}

class _AchvTierBadgeState extends State<_AchvTierBadge> {
  @override
  void initState() {
    super.initState();
    TierShimmer.ensureRunning();
  }

  @override
  Widget build(BuildContext context) {
    final grad = tierGradient(widget.tier);
    final hasAvatar = (widget.avatarUrl ?? '').isNotEmpty;

    Widget content(double phase) {
      final s = math.sin(phase * 2 * math.pi) * 0.5;
      return Container(
        width: widget.size, height: widget.size,
        padding: hasAvatar ? const EdgeInsets.all(3) : EdgeInsets.zero,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: grad == null ? null : LinearGradient(
            colors: grad, stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            begin: Alignment(-1 + s, -1), end: Alignment(1 + s, 1),
          ),
          color: grad == null ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
          boxShadow: grad == null ? null : [
            BoxShadow(color: grad[1].withValues(alpha: 0.5), blurRadius: 10, spreadRadius: -2),
          ],
        ),
        child: hasAvatar
            ? ClipOval(
                child: Image.network(widget.avatarUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.person_rounded, color: Colors.black87)),
              )
            : (widget.icon == null ? null
                : Icon(widget.icon, size: widget.size * 0.42, color: Colors.black87)),
      );
    }

    return Opacity(
      opacity: widget.dim ? 0.35 : 1.0,
      child: grad == null
          ? content(0)
          : ValueListenableBuilder<double>(
              valueListenable: TierShimmer.phase,
              builder: (context, phase, _) => content(phase),
            ),
    );
  }
}
