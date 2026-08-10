// Achievements system: card border tiers + unlockable milestones.
// All computed from data already cached locally (user.getInfo stats),
// no extra network calls.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// Single shared clock driving the "moving sheen" on tier badges/surfaces.
// One timer for the whole app instead of one AnimationController per badge
// — cheap, and every badge/surface just reads the current phase.
class TierShimmer {
  TierShimmer._();
  static final ValueNotifier<double> phase = ValueNotifier(0.0);
  static Timer? _timer;

  static void ensureRunning() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 60), (_) {
      phase.value = (phase.value + 0.012) % 1.0;
    });
  }
}

// Infinite account level, based on total scrobbles. Each level needs more
// than the last (quadratic curve), so it keeps getting harder forever —
// no cap, no "final" level.
int accountLevel(int totalScrobbles) {
  if (totalScrobbles <= 0) return 1;
  return math.sqrt(totalScrobbles / 25).floor() + 1;
}

// Total scrobbles required to REACH [level].
int levelThreshold(int level) {
  final l = level - 1;
  return 25 * l * l;
}

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
    Color(0xFF6B6B70), Color(0xFFC8C8CC), Color(0xFFFFFFFF),
    Color(0xFFA8A8AD), Color(0xFF56565A),
  ],
  CardTier.gold: [
    Color(0xFF8C6A0A), Color(0xFFFFD76A), Color(0xFFFFF3C4),
    Color(0xFFD9A62B), Color(0xFF7A5A08),
  ],
  CardTier.platinum: [
    Color(0xFFB9AC9A), Color(0xFFF3E9DA), Color(0xFFFFFDF8),
    Color(0xFFDCCBB0), Color(0xFF9C8C74),
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
    Color(0xFF15171A), Color(0xFFFFFFFF), Color(0xFF1D2124),
    Color(0xFFFFFFFF), Color(0xFF15171A),
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

// Next threshold above [n], or null once the top tier is reached.
int? nextPlayThreshold(int n) {
  for (final t in kPlayTierThresholds) {
    if (n < t) return t;
  }
  return null;
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

enum AchvCategory { listening, artists, albums, tracks, loyalty, pace }

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
  AchievementDef('l1', AchvCategory.listening, 100,    CardTier.bronze,     Icons.headphones_rounded),
  AchievementDef('l2', AchvCategory.listening, 500,    CardTier.silver,     Icons.headphones_rounded),
  AchievementDef('l3', AchvCategory.listening, 1000,   CardTier.gold,       Icons.headphones_rounded),
  AchievementDef('l4', AchvCategory.listening, 2500,   CardTier.platinum,   Icons.headphones_rounded),
  AchievementDef('l5', AchvCategory.listening, 5000,   CardTier.emerald,    Icons.headphones_rounded),
  AchievementDef('l6', AchvCategory.listening, 10000,  CardTier.sapphire,   Icons.headphones_rounded),
  AchievementDef('l7', AchvCategory.listening, 25000,  CardTier.diamond,    Icons.headphones_rounded),
  AchievementDef('l8', AchvCategory.listening, 50000,  CardTier.chrome,     Icons.headphones_rounded),
  AchievementDef('l9', AchvCategory.listening, 500000, CardTier.iridescent, Icons.headphones_rounded),
  // Artistes — distinct artists
  AchievementDef('a1', AchvCategory.artists, 25,  CardTier.bronze,     Icons.mic_external_on_rounded),
  AchievementDef('a2', AchvCategory.artists, 50,  CardTier.silver,     Icons.mic_external_on_rounded),
  AchievementDef('a3', AchvCategory.artists, 100, CardTier.gold,       Icons.mic_external_on_rounded),
  AchievementDef('a4', AchvCategory.artists, 150, CardTier.platinum,   Icons.mic_external_on_rounded),
  AchievementDef('a5', AchvCategory.artists, 250, CardTier.emerald,    Icons.mic_external_on_rounded),
  AchievementDef('a6', AchvCategory.artists, 300, CardTier.sapphire,   Icons.mic_external_on_rounded),
  AchievementDef('a7', AchvCategory.artists, 400, CardTier.diamond,    Icons.mic_external_on_rounded),
  AchievementDef('a8', AchvCategory.artists, 500, CardTier.chrome,     Icons.mic_external_on_rounded),
  AchievementDef('a9', AchvCategory.artists, 3000, CardTier.iridescent, Icons.mic_external_on_rounded),
  // Albums — distinct albums
  AchievementDef('ab1', AchvCategory.albums, 25,  CardTier.bronze,     Icons.album_rounded),
  AchievementDef('ab2', AchvCategory.albums, 50,  CardTier.silver,     Icons.album_rounded),
  AchievementDef('ab3', AchvCategory.albums, 100, CardTier.gold,       Icons.album_rounded),
  AchievementDef('ab4', AchvCategory.albums, 150, CardTier.platinum,   Icons.album_rounded),
  AchievementDef('ab5', AchvCategory.albums, 200, CardTier.emerald,    Icons.album_rounded),
  AchievementDef('ab6', AchvCategory.albums, 300, CardTier.sapphire,   Icons.album_rounded),
  AchievementDef('ab7', AchvCategory.albums, 400, CardTier.diamond,    Icons.album_rounded),
  AchievementDef('ab8', AchvCategory.albums, 500, CardTier.chrome,     Icons.album_rounded),
  AchievementDef('ab9', AchvCategory.albums, 3000, CardTier.iridescent, Icons.album_rounded),
  // Titres — distinct tracks
  AchievementDef('t1', AchvCategory.tracks, 50,   CardTier.bronze,     Icons.music_note_rounded),
  AchievementDef('t2', AchvCategory.tracks, 100,  CardTier.silver,     Icons.music_note_rounded),
  AchievementDef('t3', AchvCategory.tracks, 200,  CardTier.gold,       Icons.music_note_rounded),
  AchievementDef('t4', AchvCategory.tracks, 300,  CardTier.platinum,   Icons.music_note_rounded),
  AchievementDef('t5', AchvCategory.tracks, 500,  CardTier.emerald,    Icons.music_note_rounded),
  AchievementDef('t6', AchvCategory.tracks, 600,  CardTier.sapphire,   Icons.music_note_rounded),
  AchievementDef('t7', AchvCategory.tracks, 800,  CardTier.diamond,    Icons.music_note_rounded),
  AchievementDef('t8', AchvCategory.tracks, 1000, CardTier.chrome,     Icons.music_note_rounded),
  AchievementDef('t9', AchvCategory.tracks, 6000, CardTier.iridescent, Icons.music_note_rounded),
  // Fidélité — years since registration
  AchievementDef('y1', AchvCategory.loyalty, 1,  CardTier.bronze,     Icons.cake_rounded),
  AchievementDef('y2', AchvCategory.loyalty, 2,  CardTier.silver,     Icons.cake_rounded),
  AchievementDef('y3', AchvCategory.loyalty, 3,  CardTier.gold,       Icons.cake_rounded),
  AchievementDef('y4', AchvCategory.loyalty, 4,  CardTier.platinum,   Icons.cake_rounded),
  AchievementDef('y5', AchvCategory.loyalty, 5,  CardTier.emerald,    Icons.cake_rounded),
  AchievementDef('y6', AchvCategory.loyalty, 6,  CardTier.sapphire,   Icons.cake_rounded),
  AchievementDef('y7', AchvCategory.loyalty, 7,  CardTier.diamond,    Icons.cake_rounded),
  AchievementDef('y8', AchvCategory.loyalty, 8,  CardTier.chrome,     Icons.cake_rounded),
  AchievementDef('y9', AchvCategory.loyalty, 15, CardTier.iridescent, Icons.cake_rounded),
  // Rythme — average scrobbles per week
  AchievementDef('p1', AchvCategory.pace, 10,  CardTier.bronze,     Icons.speed_rounded),
  AchievementDef('p2', AchvCategory.pace, 20,  CardTier.silver,     Icons.speed_rounded),
  AchievementDef('p3', AchvCategory.pace, 35,  CardTier.gold,       Icons.speed_rounded),
  AchievementDef('p4', AchvCategory.pace, 50,  CardTier.platinum,   Icons.speed_rounded),
  AchievementDef('p5', AchvCategory.pace, 75,  CardTier.emerald,    Icons.speed_rounded),
  AchievementDef('p6', AchvCategory.pace, 100, CardTier.sapphire,   Icons.speed_rounded),
  AchievementDef('p7', AchvCategory.pace, 150, CardTier.diamond,    Icons.speed_rounded),
  AchievementDef('p8', AchvCategory.pace, 200, CardTier.chrome,     Icons.speed_rounded),
  AchievementDef('p9', AchvCategory.pace, 750, CardTier.iridescent, Icons.speed_rounded),
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
  required int trackCount,
  required int yearsRegistered,
  required int weeklyAvg,
}) {
  int currentFor(AchvCategory c) => switch (c) {
    AchvCategory.listening => totalScrobbles,
    AchvCategory.artists   => artistCount,
    AchvCategory.albums    => albumCount,
    AchvCategory.tracks    => trackCount,
    AchvCategory.loyalty   => yearsRegistered,
    AchvCategory.pace      => weeklyAvg,
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
