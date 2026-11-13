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
- Loading screens on charts and tabs now show the same soft placeholder shapes with the loader on top

**Interface**
- Removed: the Nothing OS style (app, onboarding and settings); the app now always uses Material You
- Fixed: the music calendar now uses the full width of the screen
- Profile share image: "LastStats" is now at the bottom left and the source (Last.fm) sits just above the QR code

