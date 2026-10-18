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


## v4.2.0

**News translation and website fixes**
- News: items are now translated automatically into the app language, with a compact translate button in the top bar to switch back to the original text
- News: long-press the translate button to pick another target language (same list as the biography translation)
- Spotify Canvas: the app now repairs itself when Spotify changes its private query (it reads the new hash from the web player's scripts, at most once every 6 hours, and retries); the "Test Spotify" button also tries this repair
- Spotify: when you are not logged in, nothing runs in the background for it (no lookups, no token refresh, no repair)
- Video covers: new switch "Also on the dashboard" (off by default) to allow YouTube for the animated cover behind your profile on the dashboard; it works even when YouTube is not one of your sources, translated in all 10 languages
- New: **Year in review** (profile menu > "Year in review"): a story-style recap of your year with total scrobbles and estimated hours, top artist, top tracks and albums, month by month chart, when you listen (night owl, early bird...), longest streak, discoveries, and a final summary card you can share as an image. Pick any year since you joined. Numbers count up and tops are revealed one by one, with two friends slides with profile pictures (yearly scrobbles ranking among your friends, and your "music twin" based on shared top artists), and a top artists donut reused from the Charts tab. Navigation arrows at the bottom, cookie shapes for artists and profile pictures, full sentences and full month/day names in every language, and a shared image that now includes every cover and the whole summary. Built from your local scrobble history, available in all 10 languages
- Year in review: only finished years can be opened (the current year unlocks on January 1st); every past year since you joined stays available
- Year in review: shared images redesigned so every slide looks alike: same title position and font sizes, accent theme colours instead of black text, content centered under the header photo, top artist/track/album with the title on the left and the cover on the right, a darker header photo so the white title stays readable, and a richer first slide with the estimation note made discreet
- Year in review: the loading screen now uses the app's wavy progress bar
- New: **year-in-review notification** on January 1st (once a year, in your local time, if at least one notification type is enabled), translated in all 10 languages
- New: a 👀 button next to the bell on the dashboard that opens the year in review, shown only from January 1st to January 15th
- Notifications: enabling the milestone interval no longer sends a notification right away (the first check only records your current scrobble count)
- Calendar pickers (history day and news date range) are now translated into the app language
- Year in review: the year picker is now a bottom sheet of pill chips, like the period chips
- 🏎️ 🐉 🤖
- Website: the table of contents dots of the help and legal pages are now all aligned on the same line
- Website: reworded the awkward "fiche artiste / fiche titre" wording to "page artiste / page titre" in French, and the matching Spanish, Italian and Portuguese texts
- Website: fixed the mixed "tu/vous" in two French titles on the home page

**Legal notice, links and README**
- About: new "Legal" section with a link to the legal notice and privacy page, publisher and contact, a short data and privacy summary, and the non-affiliation notice for all third-party services
- About: Flutter and open-source package licenses are now available in the app
- About: "Powered by" now lists every service the app uses (ListenBrainz, LRCLIB, lyrics.ovh, Google Translate, Spotify, Apple Music, GitHub)
- New legal texts translated in all 10 languages
- Fixed the license link in About (it pointed to a missing page)
- All links now point to the main repository, SanoBld/LastStats, in the website and the deploy workflow
- Website: the "last updated" date on the legal page now updates by itself from the repository history
- Website and README: the web version is now described as a preview (it has bugs, missing images and broken features), no more "beta" label
- Website: the legal notice is now complete and translated in all 10 languages (lyrics, Apple Music and YouTube Music posters, Google Translate for biographies, optional Spotify Canvas login, no ads or trackers in the app, AI use)
- Legal notice reviewed and rewritten in a friendlier, more natural tone with full sentences (no more outdated law article, clearer data and rights sections), translated in all 10 languages
- README badges no longer depend on the GitHub API (they now read data generated by the site deploy)
- README rewritten with a more human tone, a clearer structure and a Legal section

**Build and release (CI)**
- The build workflows keep the same inputs, file names and artifact names (the in-app updater and the release page are not affected), but each platform now builds with the language that fits it best: Android with Gradle (Kotlin DSL), iOS and macOS with Fastlane (Ruby), Windows with PowerShell, Linux with Bash, and the web app with Dart
- The workflow files are now short: all the build logic lives in scripts next to each platform (`android/ci.gradle.kts`, `ios/fastlane`, `macos/fastlane`, `windows/ci/build.ps1`, `linux/packaging/ci-build.sh`, `tool/ci/build_web.dart`)
- iOS and macOS builds now install CocoaPods in the same Ruby as Fastlane, so Flutter can find it on the runner

**Spotify Canvas**
- Fixed: when Spotify failed for a real reason (login token not ready, network error, Spotify refusing a request), the app remembered "no video" for the whole session, so no Canvas was ever shown again until restart. A failed lookup is now tried again later; a track that simply has no Canvas is still remembered as before
- After a failed Spotify token refresh, the app waits 2 minutes before opening the hidden web player again, so covers do not each open one
- Removed the leftover code of the old "Test Spotify" button and its texts in the 10 languages
