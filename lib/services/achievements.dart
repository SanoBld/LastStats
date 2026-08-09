// Achievements system: card border tiers + unlockable milestones.
// All computed from data already cached locally (user.getInfo stats),
// no extra network calls.
import 'package:flutter/material.dart';

// 9 ranks, low to high. Last one is the "ultimate" tier: reached once and
// stays maxed out beyond its threshold (no cap on how high you can go).
enum CardTier { none, bronze, silver, gold, platinum, emerald, sapphire, diamond, chrome, iridescent }

const _tierGradients = <CardTier, List<Color>>{
  CardTier.bronze:     [Color(0xFFCD7F32), Color(0xFF8C5A2B)],
  CardTier.silver:     [Color(0xFFE8E8E8), Color(0xFF9B9B9B)],
  CardTier.gold:       [Color(0xFFFFD76A), Color(0xFFB8860B)],
  CardTier.platinum:   [Color(0xFFEAF4FF), Color(0xFFB8C4CE)],
  CardTier.emerald:    [Color(0xFF6EE7B7), Color(0xFF047857)],
  CardTier.sapphire:   [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
  CardTier.diamond:    [Color(0xFFB3F5FF), Color(0xFF3FA9C9)],
  CardTier.chrome:     [Color(0xFFF5F5F5), Color(0xFF6E7A85), Color(0xFFF5F5F5)],
  CardTier.iridescent: [Color(0xFFFF9AF4), Color(0xFF9AD8FF), Color(0xFFFFE29A), Color(0xFFFF9AF4)],
};

List<Color>? tierGradient(CardTier t) => t == CardTier.none ? null : _tierGradients[t];

String tierLabel(CardTier t) => switch (t) {
  CardTier.bronze     => 'Bronze',
  CardTier.silver     => 'Argent',
  CardTier.gold       => 'Or',
  CardTier.platinum   => 'Platine',
  CardTier.emerald    => 'Émeraude',
  CardTier.sapphire   => 'Saphir',
  CardTier.diamond    => 'Diamant',
  CardTier.chrome     => 'Chromé',
  CardTier.iridescent => 'Iridescent',
  CardTier.none       => '',
};

// Play-count thresholds for the card border on a track/album/artist.
const kPlayTierThresholds = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000];
const _playTierOrder = [
  CardTier.bronze, CardTier.silver, CardTier.gold, CardTier.platinum,
  CardTier.emerald, CardTier.sapphire, CardTier.diamond, CardTier.chrome, CardTier.iridescent,
];

CardTier tierForPlays(int n) {
  var best = CardTier.none;
  for (var i = 0; i < kPlayTierThresholds.length; i++) {
    if (n >= kPlayTierThresholds[i]) best = _playTierOrder[i];
  }
  return best;
}

// Overall profile tier = how many achievements are unlocked, mapped onto
// the same 9-rank scale.
const _profileTierThresholds = [2, 4, 6, 8, 10, 12, 13, 15, 17];
CardTier profileTier(int unlockedCount) {
  var best = CardTier.none;
  for (var i = 0; i < _profileTierThresholds.length; i++) {
    if (unlockedCount >= _profileTierThresholds[i]) best = _playTierOrder[i];
  }
  return best;
}

enum AchvCategory { listening, artists, albums, loyalty }

class AchievementDef {
  final String id;
  final AchvCategory category;
  final int threshold;   // scrobbles, distinct count, or years
  final CardTier tier;
  final IconData icon;
  const AchievementDef(this.id, this.category, this.threshold, this.tier, this.icon);
}

const kAchievements = <AchievementDef>[
  // Écoute — total scrobbles
  AchievementDef('l100',   AchvCategory.listening, 100,   CardTier.bronze,     Icons.headphones_rounded),
  AchievementDef('l1000',  AchvCategory.listening, 1000,  CardTier.silver,     Icons.headphones_rounded),
  AchievementDef('l5000',  AchvCategory.listening, 5000,  CardTier.gold,       Icons.headphones_rounded),
  AchievementDef('l10000', AchvCategory.listening, 10000, CardTier.platinum,   Icons.headphones_rounded),
  AchievementDef('l25000', AchvCategory.listening, 25000, CardTier.sapphire,   Icons.headphones_rounded),
  AchievementDef('l50000', AchvCategory.listening, 50000, CardTier.iridescent, Icons.headphones_rounded),
  // Artistes — distinct artists
  AchievementDef('a50',    AchvCategory.artists, 50,  CardTier.bronze,  Icons.mic_external_on_rounded),
  AchievementDef('a150',   AchvCategory.artists, 150, CardTier.gold,    Icons.mic_external_on_rounded),
  AchievementDef('a300',   AchvCategory.artists, 300, CardTier.emerald, Icons.mic_external_on_rounded),
  AchievementDef('a500',   AchvCategory.artists, 500, CardTier.diamond, Icons.mic_external_on_rounded),
  // Albums — distinct albums
  AchievementDef('ab50',   AchvCategory.albums, 50,  CardTier.bronze,   Icons.album_rounded),
  AchievementDef('ab150',  AchvCategory.albums, 150, CardTier.gold,     Icons.album_rounded),
  AchievementDef('ab300',  AchvCategory.albums, 300, CardTier.sapphire, Icons.album_rounded),
  // Fidélité — years since registration
  AchievementDef('y1',  AchvCategory.loyalty, 1,  CardTier.bronze,     Icons.cake_rounded),
  AchievementDef('y3',  AchvCategory.loyalty, 3,  CardTier.silver,     Icons.cake_rounded),
  AchievementDef('y5',  AchvCategory.loyalty, 5,  CardTier.emerald,    Icons.cake_rounded),
  AchievementDef('y10', AchvCategory.loyalty, 10, CardTier.iridescent, Icons.cake_rounded),
];

class AchievementProgress {
  final AchievementDef def;
  final int  current;
  final bool unlocked;
  const AchievementProgress(this.def, this.current, this.unlocked);
}

// [current] must already be resolved per category by the caller
// (totalScrobbles, artistCount, albumCount, yearsRegistered).
List<AchievementProgress> computeAchievements({
  required int totalScrobbles,
  required int artistCount,
  required int albumCount,
  required int yearsRegistered,
}) {
  int currentFor(AchvCategory c) => switch (c) {
    AchvCategory.listening => totalScrobbles,
    AchvCategory.artists   => artistCount,
    AchvCategory.albums    => albumCount,
    AchvCategory.loyalty   => yearsRegistered,
  };
  return kAchievements.map((d) {
    final cur = currentFor(d.category);
    return AchievementProgress(d, cur, cur >= d.threshold);
  }).toList();
}
