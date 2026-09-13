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


## v3.5.0

**Dashboard**
- New dashboard chart: a listening calendar (last 60 days) or monthly bars — replaces the old top artists/albums/tracks block, pick which one in Dashboard settings
- New: set a custom display name (in the intro flow or Settings > Account) — shown big on the dashboard, with your actual Last.fm account name underneath
- Faster dashboard chart loading: proper pagination (was silently missing scrobbles on busy periods) and background caching instead of refetching every time

**Rankings**
- Fixed: podium photos sometimes stayed stuck on the previous top 3 after changing the year/month filter
- Year selector now stretches at the edges (Android style) instead of the iOS rubber-band bounce, same for the Charts tab

**News**
- New search bar in the news/what's-new page, filters by title and body as you type

**Sharing**
- Fixed sharing (artwork, charts, achievement badges, crash logs, recap cards) on Windows, macOS and Linux — desktop now saves the file and reveals it in the file explorer/Finder instead of relying on the native share charm, which silently failed for unpackaged desktop builds

**Performance (Windows)**
- Notification system setup no longer blocks the app's first frame on Windows — the window now appears noticeably faster on startup
- A few redundant startup steps now run in parallel instead of one after another