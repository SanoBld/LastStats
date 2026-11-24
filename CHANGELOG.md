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


## v4.6.0

### Highlights
- Much smoother app: heavy calculations no longer freeze the interface
- Opening a year recap or the charts page on a big history is now fluid

### Performance
- Year recap: the whole calculation now runs in the background instead of on the interface thread, with the same results as before
- Year recap: merged and split artists and titles are computed once per song instead of once per scrobble, and dates are built only once
- Charts: top artists and albums and the listening habits (hours and weekdays) over all years are calculated in the background
- Charts: the "All time" monthly and calendar data are kept in memory and rebuilt only when your history changes, instead of at every redraw
- Profile pictures are decoded at a smaller size, which saves memory and smooths scrolling
