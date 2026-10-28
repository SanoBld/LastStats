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


## v4.3.0

- Year recap: a 30-second Deezer preview now plays automatically on every slide, with a fade-in and fade-out
- Year recap: new player at the bottom with play/pause, the title being played and a wavy progress bar (pause applies to all slides)
- Year recap: the music matches each slide (busiest day, listening period, consistency, discoveries, friends ranking, music twin, top 1 on the final slide)
- Year recap: new "Your streak song" and "Your single-day record" slides, with animated counters
- Year recap: the #1 artist, track and album shapes now turn while the music plays (the picture stays still), and ranks 2-5 use a variety of shapes
- Year recap: customize the share image (color, light/dark theme, font) from the last slide, your own style is restored when you leave
- Year recap: shared single slides show the title a bit lower, and the first slide only keeps the scrobble count
- Dashboard: tapping your profile now opens a centered bubble with your profile info and every shortcut (settings, notifications, recaps, achievements, profile scanner, refresh, reset cache)
- Dashboard: the settings button and its long-press menu are gone, the notification bell only shows in the header when you have unread news
- Year recap: the shared image uses your display name when you set one
- Top bar no longer turns grey when scrolling, and pressed buttons fill their own shape instead of showing a round Android ripple
- New central file lib/theme/m3_interaction.dart for press and top-bar style
- Interface: every tappable area in the app (lists, cards, settings rows, chips, sheets) now uses the same pressed fill, which follows its own rounded shape
- Interface: round buttons such as the back arrow stay round when pressed, and filter pills get the same pressed fill
- Dashboard: the profile bubble tiles are all the same size, tapping the profile card goes straight to the account page, and a new Connections shortcut was added
- Fixed the preview picking a song from the wrong artist
- New texts translated in all languages