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


## v3.1.0

**Levels & Achievements**
- New account level system, based on total scrobbles
- New achievements system, with card borders (bronze to iridescent) based on play count
- All computed automatically from cached stats, no extra network calls

**3D Artwork Cards**
- Share artwork cards as an image
- QR code sharing and QR code scanning for profiles

**Settings**
- Rebuilt settings tabs, including a redesigned FAQ page with more questions
- Eco mode for battery saving
- Reworked updates page, with a searchable, filterable version history

**Performance**
- General app optimization, faster and smoother overall