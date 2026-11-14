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


## v4.4.0

**Animations**
- New: "Motion blur" option in Appearance, saved and restored with your themes
- Better animations: pull-to-refresh now uses the app loader (it turns as you pull and fades in / out), one loader style everywhere (pages and charts), and one progress bar style with smooth value changes
- Loading screens: every tab (charts, ranking, history, search, favorites, track details) now shows soft placeholder shapes laid out like its own content, with the same pulse and loader as the dashboard

**Interface**
- Removed: the Nothing OS style (app, onboarding and settings); the app now always uses Material You
- Music calendar: always fills the full width and shows the latest weeks that fit your screen; in Charts it now opens on today instead of the start of the year
- Charts calendar redesigned in the GitHub contribution style (months on top, Mon/Wed/Fri, rounded cells, Less/More legend, year selector), opening on today
- The home calendar and the shared calendar image now use the same GitHub-style design; removed the Beta badge from the chart export sheet
- Performance: lighter calendar rendering, badge shimmer paused while the app is in the background
- Home calendar now loads enough weeks to fill the card with real data
- Friend profile: simple loader with a smooth transition instead of the grey placeholder
- Updated the first-launch introduction: new animation blur option, texts that match the current settings, no more mention of the removed style
- Profile share image: "LastStats" is now at the bottom left and the source (Last.fm) sits just above the QR code

