// Achievements sheet: opens from the profile menu at home.
// Shows the overall profile tier (based on unlocked count) and every
// milestone grouped by category, with locked/unlocked state.
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

class _AchievementsSheet extends StatelessWidget {
  final Map<String, dynamic>? userInfo;
  const _AchievementsSheet({required this.userInfo});

  int _years() {
    final raw = userInfo?['registered'];
    if (raw == null) return 0;
    final ts = raw is Map
        ? int.tryParse((raw['#text'] ?? raw['unixtime'] ?? '0').toString()) ?? 0
        : int.tryParse(raw.toString()) ?? 0;
    if (ts <= 0) return 0;
    final days = (DateTime.now().millisecondsSinceEpoch / 1000 - ts) / 86400;
    return (days / 365).floor();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total   = int.tryParse((userInfo?['playcount']    ?? '0').toString()) ?? 0;
    final artists = int.tryParse((userInfo?['artist_count'] ?? '0').toString()) ?? 0;
    final albums  = int.tryParse((userInfo?['album_count']  ?? '0').toString()) ?? 0;

    final list = computeAchievements(
      totalScrobbles: total, artistCount: artists,
      albumCount: albums, yearsRegistered: _years(),
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
              _TierRing(tier: myTier, size: 84),
              const SizedBox(height: 10),
              Text(myTier == CardTier.none ? '—' : tierLabel(myTier),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(L.achvUnlocked(unlocked, list.length),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 24),
          for (final cat in AchvCategory.values)
            if (byCategory[cat] != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(_categoryLabel(cat),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              ...byCategory[cat]!.map((a) => _AchvTile(a: a)),
            ],
        ],
      ),
    );
  }

  String _categoryLabel(AchvCategory c) => switch (c) {
    AchvCategory.listening => L.achvCatListening,
    AchvCategory.artists   => L.achvCatArtists,
    AchvCategory.albums    => L.achvCatAlbums,
    AchvCategory.loyalty   => L.achvCatLoyalty,
  };
}

class _AchvTile extends StatelessWidget {
  final AchievementProgress a;
  const _AchvTile({required this.a});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = (a.current / a.def.threshold).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        _TierRing(tier: a.def.tier, size: 44, icon: a.def.icon, dim: !a.unlocked),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${tierLabel(a.def.tier)} · ${a.def.threshold}',
                  style: TextStyle(fontWeight: FontWeight.w600,
                      color: a.unlocked ? null : scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio, minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: a.unlocked ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(a.unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 18, color: a.unlocked ? Colors.green : scheme.onSurfaceVariant),
      ]),
    );
  }
}

// Small circular badge showing a tier's gradient, used for both the
// profile summary and each milestone row.
class _TierRing extends StatelessWidget {
  final CardTier tier;
  final double size;
  final IconData? icon;
  final bool dim;
  const _TierRing({required this.tier, required this.size, this.icon, this.dim = false});

  @override
  Widget build(BuildContext context) {
    final grad = tierGradient(tier);
    return Opacity(
      opacity: dim ? 0.35 : 1.0,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: grad == null
              ? null
              : LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: grad == null ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
        ),
        child: icon == null ? null : Icon(icon, size: size * 0.45, color: Colors.black87),
      ),
    );
  }
}
