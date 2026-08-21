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
- Auto-refresh while the app is open, plus a background task every ~30 min