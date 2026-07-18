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


## v2.9.9-beta
- New Favorites system: like tracks/artists/albums, dedicated page with filters, cover art and removable items, clickable count in stats bar
- Discreet loved badge in recent listens (toggleable in settings)
- Windows installer (.exe) for x64 and ARM64, with shortcuts and clean uninstall/update
- Fixed app name showing as "laststats_mobile" in window title and Task Manager
- Redesigned Charts tab with modern, consistent styling
- Harmonized headers across Rankings, Charts, History, and Search
- Rankings now uses the same year filter chips as Charts
- Fixed broken scroll pagination on Artists tab
- Cleaned up redundant/illogical filter options
- FAQ rewritten (formal tone) with new questions, fully translated
- Fixed duplicate music platform setting
- Fixed version display to reflect actual build status
- Background scrobble sync with adjustable frequency and a progress notification
- Customizable sync notifications, now also available on Windows
- New custom title bar on Windows and Linux
- Music platform selection (Last.fm, Spotify, YT Music) with official logos, used to filter links shown on track/artist/album pages
- Updated onboarding favorites step, with Last.fm friend suggestions and profile search
- Added translations for German, Italian, Japanese, Russian, Arabic, Spanish, Chinese, and Portuguese
- General interface improvements across settings
- Login screen redesign
- New comparison system
- Chart sharing (beta)
- New themes and customization options
- Various fixes and stability improvements

**Important:** before updating, make sure to save your two API keys (Last.fm and secret key). After updating, it is recommended to reset the app so both keys are properly reconfigured.