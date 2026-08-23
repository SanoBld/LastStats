# Changelog

<!--
  HOW TO USE THIS FILE

  Before triggering a release (pushing a tag OR running the release
  workflow manually), add a new section at the TOP of this file.

  The heading must match the git tag EXACTLY:
    - stable release -> ## v2.8.0
    - beta release   -> ## v2.8.0-beta   (the "-beta" suffix must be included)

  Example:

      ## v2.8.0-beta
      - New weekly stats feature (testing)
      - Fixed an Android display bug

      ## v2.8.0
      - Weekly stats
      - Bug fixes

  The release.yml workflow reads this file, extracts only the text under
  the heading that matches the version being released, and inserts it
  into the GitHub release notes automatically.

  Commit (and push) this file BEFORE creating the tag or running the
  workflow manually — otherwise the workflow won't see the new entry yet
  and will show a fallback message instead.
-->


## v3.2.0

**Home Screen Widgets** (Android)
- New: 5 home screen widgets — total scrobbles, now playing, loved tracks, this week, and a full recap
- Now Playing widget shows the album art full-bleed, with track and artist over a dark gradient
- Widgets follow the app's theme (style, light/dark, and accent color), with a toggle to keep them pure white/black instead
- Size-responsive: the 3 stat widgets adapt their layout as you resize them, down to a compact number-only square
- Auto-refresh while the app is open (live for Now Playing, periodic for stats), plus a background task every ~30 min
- Fully translated into all 10 supported languages, including the widget picker names

**Settings**
- New search bar in Settings, filtering every category and jumping straight into common options (accent color, theme, language, and more), some editable inline
- New "Inspirations" section in About, crediting Metrolist and Better Nothing Music Visualizer
- Rebuilt settings tabs, including a redesigned FAQ page with more questions
- Eco mode for battery saving
- Reworked updates page, with a searchable, filterable version history
- Fixed accent colors: picking black or white no longer looks tinted blue
- New: separate accent color for light and dark theme, optionally switched by a fixed time of day instead of the active theme

**Levels & Achievements**
- New account level system, based on total scrobbles
- New achievements system, with card borders (bronze to iridescent) based on play count
- Two new achievement categories: friends added, and taste comparisons made
- All computed automatically from cached stats, no extra network calls

**3D Artwork Cards**
- Share artwork cards as an image
- QR code sharing and QR code scanning for profiles
- Achievement badges now show their name when shared, not just the tier

**Performance**
- General app optimization, faster and smoother overall