// Achievements sheet: opens from the profile menu at home.
// Top: overall profile tier ring. Below: one card per category
// (Listening / Artists / Albums / Loyalty), each showing a textured tier
// swatch, a short description, and current progress. Tapping a card opens
// the full milestone list for that category.
part of 'home_screen.dart';

void showAchievementsSheet(BuildContext context, Map<String, dynamic>? userInfo) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    fullscreenDialog: true,
    pageBuilder: (_, _, _) => _AchievementsSheet(userInfo: userInfo),
    transitionsBuilder: (_, anim, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 380),
  ));
}

int _yearsSince(dynamic registered) {
  if (registered == null) return 0;
  final ts = registered is Map
      ? int.tryParse((registered['#text'] ?? registered['unixtime'] ?? '0').toString()) ?? 0
      : int.tryParse(registered.toString()) ?? 0;
  if (ts <= 0) return 0;
  final days = (DateTime.now().millisecondsSinceEpoch / 1000 - ts) / 86400;
  return (days / 365).floor();
}

class _AchievementsSheet extends StatelessWidget {
  final Map<String, dynamic>? userInfo;
  const _AchievementsSheet({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total   = int.tryParse((userInfo?['playcount']    ?? '0').toString()) ?? 0;
    final artists = int.tryParse((userInfo?['artist_count'] ?? '0').toString()) ?? 0;
    final albums  = int.tryParse((userInfo?['album_count']  ?? '0').toString()) ?? 0;

    final list = computeAchievements(
      totalScrobbles: total, artistCount: artists,
      albumCount: albums, yearsRegistered: _yearsSince(userInfo?['registered']),
    );
    final unlocked = list.where((a) => a.unlocked).length;
    final myTier   = profileTier(unlocked);

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
              _AchvTierBadge(tier: myTier, size: 92),
              const SizedBox(height: 10),
              Text(myTier == CardTier.none ? '—' : tierLabel(myTier),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
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
    AchvCategory.loyalty   => (L.achvCatLoyalty,   L.achvDescLoyalty,   Icons.cake_rounded),
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
    return Container(
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
    );
  }
}

// ── Shared tier visuals ─────────────────────────────────────────────────────

// Flat rectangular surface with the tier's metallic sheen, used as the
// header strip of category cards. Rounded corners only where placed.
class _AchvTierSurface extends StatelessWidget {
  final CardTier tier;
  final Widget? child;
  const _AchvTierSurface({required this.tier, this.child});

  @override
  Widget build(BuildContext context) {
    final grad = tierGradient(tier);
    return Container(
      decoration: BoxDecoration(
        color: grad == null ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
        gradient: grad == null ? null : LinearGradient(
          colors: grad, stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

// Circular tier badge with the same sheen, used for the profile summary
// and each milestone row.
class _AchvTierBadge extends StatelessWidget {
  final CardTier tier;
  final double size;
  final IconData? icon;
  final bool dim;
  const _AchvTierBadge({required this.tier, required this.size, this.icon, this.dim = false});

  @override
  Widget build(BuildContext context) {
    final grad = tierGradient(tier);
    return Opacity(
      opacity: dim ? 0.35 : 1.0,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: grad == null ? null : LinearGradient(
            colors: grad, stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          color: grad == null ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
          boxShadow: grad == null ? null : [
            BoxShadow(color: grad[1].withValues(alpha: 0.5), blurRadius: 10, spreadRadius: -2),
          ],
        ),
        child: icon == null ? null : Icon(icon, size: size * 0.42, color: Colors.black87),
      ),
    );
  }
}
