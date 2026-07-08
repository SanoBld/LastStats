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


## v2.9.6-beta
- Background scrobble sync with adjustable frequency and a progress notification
- Customizable sync notifications, now also available on Windows
- New custom title bar on Windows and Linux
- Music platform selection (Last.fm, Spotify, YT Music) with official logos, used to filter links shown on track/artist/album pages
- Updated onboarding favorites step, with Last.fm friend suggestions and profile search
- Added translations for Spanish, Chinese, and Portuguese
- General interface improvements across settings
- Login screen redesign
- New comparison system
- Chart sharing (beta)
- New themes and customization options
- Various fixes and stability improvements