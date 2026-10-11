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

**Search tab and Charts tab redesign**
- Search: recent searches, "From your recent searches" carousel, live suggestions with a recommended result, category chips and a "Best results" card once you validate
- Search: Last.fm profiles are now plain rows (avatar, name, plays, star) like artists, and titles and albums are aligned to the left
- Search: the photo now follows the result (the old picture no longer stays when the suggestion changes)
- Charts: tab rebuilt around real charts: a smooth area chart (monthly or cumulative, touch to inspect), a 24-hour listening clock, a week bar chart, donut charts for artists and albums and a genre radar, all in the app theme; large collapsing app bar with pinned year chips
- All new texts are translated in all 10 languages

**Welcome setup**
- The first-launch sync screen is gone: data and scrobbles now sync in the background while you set up the app, with a live percentage at the top left
- New setup pages: covers and images (shape, animated covers, motion covers, tab labels) and sync and battery (automatic sync, battery saver)
- Notification switches now ask for the system permission and schedule the tasks, like the Notifications settings

**Material You details**
- Biography, lyrics, top tracks, top albums, tracklist, track info, stats and the Last.fm discussion now sit in accent cards with expressive shapes (leaf, arch, squircle)
- Play, favourite, period and filter buttons use the accent colour on a soft tonal background instead of white on a coloured one

**Biographies and history**
- Biographies fall back to Wikipedia (your language first, then English) when Last.fm has none, with the source shown
- History: every track sits in its own rounded accent card, hour headers and the stat pills use the dark accent

**Artists, text and fixes**
- Artist page: popular and recent tracks with covers, in the right order, swipe left / right to switch
- Settings > Appearance: text size slider (default a bit bigger) and font choice
- History list: fixed track cards drawing over the header

**Search and status bar**
- Search fully redone in Material You: pill search bar, category pills, results in rounded cards, sections ordered by best match instead of a fixed order
- Status bar icons now follow the app theme (no more white on white)
- Folder cards are more readable (stronger tint, solid badge and counter)

**Loading bars**
- New wavy progress bar (Material You) used wherever a loading has real progress: history sync chip on the dashboard (now shows loaded/total scrobbles; the wavy bar only appears for big syncs, 200+ scrobbles), Sync settings and the Spotify / Last.fm login pages
- The round loader now morphs between soft rounded shapes of the app (squircle, oval), like the Material 3 Expressive loading indicator
- Dashboard: when "motion covers" is on, the animated cover of the track now playing plays on the now-playing card and in the top header (profile / level area) (new switch in Settings > Dashboard > Header image to turn it on or off)

**Spotify Canvas**
- New video cover source: Spotify Canvas (tracks and albums), with in-app Spotify login in Settings > Appearance > Video covers
- Video sources can now be chosen and sorted freely (Apple Music, Spotify, YouTube Music)
