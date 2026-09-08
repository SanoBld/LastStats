// lib/theme/story_style.dart
//
// Shared design tokens extracted from the "story" recap screen
// (recap_story_page.dart), so the rest of the app can reuse the exact
// same typography scale, radii, and animation timings/curves.
import 'package:flutter/material.dart';

class AppText {
  // Big numbers (e.g. recap scrobble count)
  static const TextStyle hero = TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: 1);
  // Page/section title (story header, section headers)
  static const TextStyle title = TextStyle(fontSize: 20, fontWeight: FontWeight.w800);
  // Card title / item name
  static const TextStyle itemTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w800);
  // Body text
  static const TextStyle body = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
  // Badge / tag / chip text
  static const TextStyle badge = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
  // Secondary label (counts, dates, subtitles)
  static const TextStyle label = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
  // Smallest caption
  static const TextStyle caption = TextStyle(fontSize: 10, fontWeight: FontWeight.w600);
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 20;
  static BorderRadius smR = BorderRadius.circular(sm);
  static BorderRadius mdR = BorderRadius.circular(md);
  static BorderRadius lgR = BorderRadius.circular(lg);
  static BorderRadius xlR = BorderRadius.circular(xl);
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 350);
  static const Curve curve = Curves.easeOut;
  static const Curve curveEmphasized = Curves.easeOutCubic;
}

// Header gradient used behind the story pages; reusable for any "hero"
// header (e.g. dashboard top, detail sheet header) so the whole app shares
// the same accent wash.
LinearGradient storyHeaderGradient(ColorScheme scheme) => LinearGradient(
      colors: [scheme.primaryContainer.withValues(alpha: 0.55), scheme.surface],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0, 0.32],
    );
