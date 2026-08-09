// Achievements system: card border tiers + unlockable milestones.
// All computed from data already cached locally (user.getInfo stats),
// no extra network calls.
import 'package:flutter/material.dart';

// 9 ranks, low to high. Last one is the "ultimate" tier: reached once and
// stays maxed out beyond its threshold (no cap on how high you can go).
enum CardTier { none, bronze, silver, gold, platinum, emerald, sapphire, diamond, chrome, iridescent }

// Rich multi-stop gradients: base tone → bright sheen → base → deeper
// shadow tone. Gives a noticeable metallic/gem texture without any 3D
// trick — just careful color stops. Used for both the card border and
// the achievement badges so the look stays consistent everywhere.
const _tierGradients = <CardTier, List<Color>>{
  CardTier.bronze: [
    Color(0xFF6B4321), Color(0xFFCD7F32), Color(0xFFF0B27A),
    Color(0xFFCD7F32), Color(0xFF5A3818),
  ],
  CardTier.silver: [
    Color(0xFF8A8A8A), Color(0xFFDCDCDC), Color(0xFFFFFFFF),
    Color(0xFFC3C3C3), Color(0xFF7A7A7A),
  ],
  CardTier.gold: [
    Color(0xFF8C6A0A), Color(0xFFFFD76A), Color(0xFFFFF3C4),
    Color(0xFFD9A62B), Color(0xFF7A5A08),
  ],
  CardTier.platinum: [
    Color(0xFF9FB2BE), Color(0xFFEAF4FF), Color(0xFFFFFFFF),
    Color(0xFFCBD8E0), Color(0xFF8697A2),
  ],
  CardTier.emerald: [
    Color(0xFF045C42), Color(0xFF34D399), Color(0xFFB8FCE0),
    Color(0xFF10B981), Color(0xFF03422F),
  ],
  CardTier.sapphire: [
    Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFFBFDBFE),
    Color(0xFF2563EB), Color(0xFF1E2E6B),
  ],
  CardTier.diamond: [
    Color(0xFF2A8DA6), Color(0xFF9FF3FF), Color(0xFFFFFFFF),
    Color(0xFF6FE0F5), Color(0xFF1F6D80),
  ],
  CardTier.chrome: [
    Color(0xFF5E6A73), Color(0xFFE8E8E8), Color(0xFFFFFFFF),
    Color(0xFF9AA5AC), Color(0xFF3F474D),
  ],
  CardTier.iridescent: [
    Color(0xFFFF9AF4), Color(0xFF9AD8FF), Color(0xFFC8FFEC),
    Color(0xFFFFE29A), Color(0xFFFF9AF4),
  ],
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

// Mid-tone from each tier's gradient — used as a soft tinted background
// (e.g. category cards) instead of the full bright gradient.
Color? tierSoftColor(CardTier t) {
  final g = tierGradient(t);
  return g == null ? null : g[0];
}

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

// Summary for a category card: raw value, highest tier reached, and the
// next locked milestone (null once everything in the category is unlocked).
class CategorySummary {
  final int current;
  final CardTier tier;
  final AchievementProgress? next;
  const CategorySummary(this.current, this.tier, this.next);
}

CategorySummary summarizeCategory(List<AchievementProgress> items) {
  final current = items.isEmpty ? 0 : items.first.current;
  var tier = CardTier.none;
  AchievementProgress? next;
  for (final a in items) {
    if (a.unlocked) tier = a.def.tier;
    else { next ??= a; }
  }
  return CategorySummary(current, tier, next);
}
