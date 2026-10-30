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

- Updates: Download now fetches the update inside the app (animated wavy progress) and opens the installer directly, from the updates page, the version history, the news and the update notification (Android: you only confirm the install; Windows: silent installer, then the app restarts); clear messages if the install permission is missing or the download fails, in all 10 languages
- Fixed wrong images: recent tracks of an artist now match the exact artist, and year recap audio previews no longer fall back to a homonym artist or album
- Chart export: the share image is now built from the chart data instead of a screenshot of the screen, so no buttons, zoom controls or tap-only info appear on it
- Chart export: scrobble progression shows both "by month" and "cumulative" with the peak labelled; weekday, artist, album and genre charts now show counts and percentages directly on the image
- Chart export: flat single-colour background with soft Material shapes, no gradient and no dark box behind the chart, rounded corners like the artist and album posters
- Recap and year recap shares: same flat background and rounded corners as the other share images
- Year recap shares: extra background shapes, especially on single-slide shares where there was a lot of empty space
- Sharing: the LastStats name and logo now have the same font and size on every share image
- Fixed wrong album and track covers: titles must now match exactly (editions like "Deluxe" or "Remastered" are still accepted) and the artist is checked on every source; cached covers are refreshed once
- Fixed wrong artist photos: artist names are now matched exactly (no more "Drake" getting "Drake Bell"), the most popular artist with that exact name is picked, and previously cached artist photos are refreshed once

- Sharing: every share image now uses the same style (Material shapes, same stat tiles, same rank badges, same section labels, logo and name in the bottom-right corner)
- Chart export: the card header has a bigger logo in a cookie shape and soft corner shapes behind the chart
- Sharing a card (track, artist, album, friend): the cover now sits in a Material shape that follows your image-shape setting
- Badge share: the icon sits in a cookie shape
- Charts: tapping a legend row or bar gives a small vibration and a soft press animation
- Sharing: the LastStats logo now sits in a corner on every shared card, it is bigger, and it no longer appears twice on chart exports (the footer just says when it was generated)
- Chart export: every chart tile in the picker has the same size
- Sharing a card: uses your chosen font, bigger info lines (like your scrobbles), and every line starts at the same left edge
- Sharing a card (friend, track, artist, album): the bottom now fades into the cover's main color, the text switches between black and white to stay readable, and the logo is bigger
- Dashboard greeting: seasons are reversed for devices set to a southern-hemisphere country
- Details: the "read more" button keeps rounded corners while pressed
- Artist page: the top tracks ranking has a sliding tab selector, bars that fill in, and a cleaner switch between "popular" and "recent"
- Dashboard background: you can now pick an image from your device (kept inside the app, 4 MB max) in addition to a link
- Dashboard greeting: new messages when a friend catches up with your scrobbles, at Christmas, New Year and Easter, and for each season
- Dashboard: the accent color now follows the cover of the playing track even when Last.fm has no picture for it (tracks with an animated cover)
- Dashboard: the greeting next to your profile changes with the time of day, the weekend, what you are listening to, your listening habits and your account anniversary (translated in every language)
- Dashboard: the now-playing card shows the cover on the left, fading into the card color, with the title on the right (no more spinning shape)
- Dashboard: removed the duplicate icon on the scrobbles card
- Details: the "read more" button now morphs smoothly between its two states
- Year recap: tap a progress bar at the top to jump straight to that slide
- Details: the "read more" button for bios and lyrics now expands smoothly
- Dashboard: the now-playing shape is bigger, the country and member-since no longer show in the header (still in the profile bubble), and the duplicate scrobbles icon is gone
- Dashboard: the animated cover now follows the track when it changes
- Workflows: every job that pushes to gh-pages now shares one queue, which fixes the "fetch first" push error
- Dashboard: the now-playing cover now sits in a spinning shape (star by default) that follows your image-shape setting, like the year recap
- Dashboard: the "this week" badge uses the softer accent, like the other badges
- Year recap: the customize options now open in a scrollable panel with colors, color style, light/dark, image shapes and every font
- Cache: new size limit for stored API data, the redundant "animated covers in memory" block is removed, and clearing any cache now asks for confirmation
- Settings: new "Tinted" color style where even backgrounds, borders and text carry a faint tint of your accent (no neutral gray), and the descriptions of the other color styles are rewritten
- All new texts are translated in every language
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
- Interface: every tappable area now has the same small press bounce as buttons and cards (login page, profile bubble, sheets, lists)
- Interface: the pressed fill is now visible on tiles that have their own background (profile bubble shortcuts, chart picker)
- Interface: the side rail on large screens now slides smoothly when collapsed or expanded, instead of popping
- Battery saver: the screen now really drops to ~60 Hz (native refresh-rate control, works on adaptive 120 Hz phones) and goes back to the highest rate when it is turned off
- Battery saver: the animated background of the dashboard is paused, and the blurred image is cached instead of redrawn every frame
- Sync: "Sync now" shows the wavy progress bar like the year recap player
- Sync: friends sync now includes all your Last.fm friends, not only favourites and scanned profiles, with a wavy progress bar
- Dashboard: tapping your own profile in the profile bubble opens your profile like a friend's one (the side arrow still opens the account settings)
- Dashboard: tapping the level now opens the levels page instead of the history
- Interface: every tappable area in the app (lists, cards, settings rows, chips, sheets) now uses the same pressed fill, which follows its own rounded shape
- Interface: round buttons such as the back arrow stay round when pressed
- Dashboard: the profile bubble tiles are all the same size, tapping the profile card goes straight to the account page, and a new Connections shortcut was added
- Fixed the preview picking a song from the wrong artist
- New texts translated in all languages