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


## v4.1.0

**Welcome setup**
- The first-launch sync screen is gone: data and scrobbles now sync in the background while you set up the app, with a live percentage at the top left
- New setup pages: covers and images (shape, animated covers, motion covers, tab labels) and sync and battery (automatic sync, battery saver)
- Notification switches now ask for the system permission and schedule the tasks, like the Notifications settings

**Loading bars**
- New wavy progress bar (Material You) used wherever a loading has real progress: history sync chip on the dashboard (now shows loaded/total scrobbles), history card in charts, Sync settings and the Spotify / Last.fm login pages
- The round loader now morphs between several shapes (soft burst, cookie, pentagon, pill, sunny, oval) like the Material 3 Expressive loading indicator

**Spotify Canvas**
- New video cover source: Spotify Canvas (tracks and albums), with in-app Spotify login in Settings > Appearance > Video covers
- Video sources can now be chosen and sorted freely (Apple Music, Spotify, YouTube Music)
