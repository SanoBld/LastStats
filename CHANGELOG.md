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
- New: set a custom display name (in the intro flow or Settings > Account) — shown big on the dashboard; if set, that's all that's shown (no more Last.fm account name underneath)
- Faster dashboard chart loading: proper pagination (was silently missing scrobbles on busy periods) and background caching instead of refetching every time

**Rankings**
- Fixed: podium photos sometimes stayed stuck on the previous top 3 after changing the year/month filter
- Year selector now stretches at the edges (Android style) instead of the iOS rubber-band bounce, same for the Charts tab

**News**
- New search bar in the news/what's-new page, filters by title and body as you type
- Search bar visual style is now the same everywhere it appears: News, the Search tab, and Settings search

**Sharing**
- Fixed sharing (artwork, charts, achievement badges, crash logs, recap cards) on Windows, macOS and Linux: desktop no longer touches the native share charm at all (it was still being used as a silent fallback, which is what caused the "we couldn't show all the possible shares" error some of you saw) — it now always saves the file and reveals it in the file explorer/Finder instead

**Performance (Windows)**
- Notification system setup no longer blocks the app's first frame on Windows — the window now appears noticeably faster on startup
- A few redundant startup steps now run in parallel instead of one after another

**Transparency**
- About page now lists every open-source Flutter package used to build the app, each linking to its pub.dev page
- Added a proper open-source license (MIT) — use, modify, duplicate or redistribute freely, just credit the author — with a link to the full license text
- Translations page now notes that ALL translations, including French, were generated with AI assistance and may contain inaccuracies
- About page now also notes that AI was used to help develop a good part of the app's code
- README rewritten to match the current app (dashboard chart picker, custom nickname, working desktop sharing, license, AI note) and now includes real per-platform installation steps

**Code cleanup**
- Removed dead code left over from the old dashboard carousels
- Cleaned up a handful of unused imports and analyzer warnings