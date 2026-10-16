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

**Legal notice, links and README**
- About: new "Legal" section with a link to the legal notice and privacy page, publisher and contact, a short data and privacy summary, and the non-affiliation notice for all third-party services
- About: Flutter and open-source package licenses are now available in the app
- About: "Powered by" now lists every service the app uses (ListenBrainz, LRCLIB, lyrics.ovh, Google Translate, Spotify, Apple Music, GitHub)
- New legal texts translated in all 10 languages
- Fixed the license link in About (it pointed to a missing page)
- All links now point to the main repository, SanoBld/LastStats, in the website and the deploy workflow
- Website: the "last updated" date on the legal page now updates by itself from the repository history
- Website and README: the web version is now described as a preview (it has bugs, missing images and broken features), no more "beta" label
- README rewritten with a more human tone, a clearer structure and a Legal section

