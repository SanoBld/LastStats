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


## v3.6.0

**Material 3 Expressive**
- New wavy loading indicator (rotating bumpy shape) replaces the old spinners on full pages, chart sections and dialogs
- Loading screens are centered and visible everywhere, skeleton blocks have more contrast in dark theme
- Motion physics: spring-like curves (spatial and effects, fast / default / slow) for buttons, switches, chips and new components
- Favorites and favorite folders redesigned: grouped buttons, grouped list rows, pill search, cookie badges, cards that change shape when pressed
- "Add to folder" sheet redesigned with drag handle, tinted rows and animated check

**Options and settings**
- All chips and segmented buttons now animate: the selected one becomes a pill, the others stay soft squares
- Rankings: new date button opens a Material You sheet to pick year and month
- Settings redesigned: grouped rows with big outer and small inner corners, cookie profile avatar and category badges, press-morph cards

**Large screens**
- Side rail with rounded indicator, content in a rounded centered panel (tablet style)
- Profile search grid and folder grid adapt to the screen width

