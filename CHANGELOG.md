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

**Settings and backups**
- Fixed: with "colour from the music", the colour chosen for when nothing plays is used again at app start and by the widgets (it fell back to the default accent)
- Backups now also include the update channel, the auto-update check, the scrobble sync options and the year recap share option; restoring a backup refreshes the widgets

**Widgets**
- New option "Widget background": Poster (theme shapes), Plain (black or white following light/dark) or None (transparent)
- Theme changes (colours, style, light/dark) now reach the widgets right away instead of after the next data refresh
- New calendar widget: one square per day, like GitHub, in the app colours; today's number refreshes on its own
- All logos removed from the widgets
- Widgets use the app font, ask Last.fm only for what they show and redraw less often to save battery
- The stats logo is now centred in widgets and notifications

**News and notifications**
- "Mark all as read" in the news page; unread items have a coloured frame and are marked read when opened
- "Mark all as read" on a notification now also clears the other LastStats notifications and the update notification
- Download / Share in the news sheet use the connected Material buttons; the update sheet buttons sit higher, away from the navigation bar

**App icon**
- Real adaptive icons for each icon variant (better on Nothing Phone launchers)

**Share images**
- Year recap: new layout using the full 9:16 height, bigger stat tiles, picture ending in the middle of the tiles
- Artist, album, track and friend posters are now 9:16 instead of square-ish
- Smaller gap between "LastStats" and the logo on every share image


**Updates**
- Download now fetches the update inside the app (animated wavy progress) and opens the installer directly, from the updates page, the version history, the news and the update notification (Android: you only confirm the install; Windows: silent installer, then the app restarts); clear messages if the install permission is missing or the download fails, in all 10 languages
- Version history: Download now saves the file straight into your Downloads folder from inside the app, with no browser
- Downloads can continue in the background: close the progress sheet and a notification with a progress bar follows the download (new "Download notifications" switch in the notification settings)
- The update buttons now say "Download" everywhere instead of "Open link"
- Fixed the notification bell: it now stays lit while an update is available and also shows for any new message, even when the stats could not be loaded

**Images and covers**
- Recommended: clear the image cache after updating (Settings > Cache) so every cover and photo is fetched again with the new matching rules
- Fixed missing covers for tracks and albums credited under another form of the artist name (for example "Maître Gims" and "GIMS"): the artist is accepted when it shares all its words with the credited one, while the title must still match exactly
- Fixed wrong album and track covers: titles must now match exactly (editions like "Deluxe" or "Remastered" are still accepted) and the artist is checked on every source; cached covers are refreshed once
- Fixed wrong artist photos: artist names are now matched exactly (no more "Drake" getting "Drake Bell"), the most popular artist with that exact name is picked, and previously cached artist photos are refreshed once
- Fixed wrong images for the recent tracks of an artist, which now match the exact artist

**Sharing and exports**
- Every share image now uses the same style: Material shapes, same stat tiles, rank badges and section labels, flat single-colour background and rounded corners
- The LastStats name and logo have the same font and size on every share image, sit in the bottom-right corner, are bigger, and no longer appear twice on chart exports
- Chart export: the image is built from the chart data instead of a screenshot, so no buttons, zoom controls or tap-only info appear on it
- Chart export: scrobble progression shows both "by month" and "cumulative" with the peak labelled; weekday, artist, album and genre charts show counts and percentages directly on the image
- Chart export: soft Material shapes behind the chart, no gradient and no dark box, a bigger cookie-shaped logo in the header, and every chart tile in the picker has the same size
- Recap and year recap shares: same flat background and rounded corners as the other share images
- Sharing a card (track, artist, album, friend): the cover sits in a Material shape that follows your image-shape setting, the bottom fades into the cover's main color, the text switches between black and white to stay readable, and it uses your chosen font with bigger info lines aligned on the same left edge
- Badge share: the icon sits in a cookie shape

**Year recap**
- A 30-second Deezer preview plays automatically on every slide with a fade-in and fade-out, matched to the slide (busiest day, listening period, consistency, discoveries, friends ranking, music twin, top 1 on the final slide)
- New player at the bottom with play/pause, the title being played and a wavy progress bar (pause applies to all slides)
- Audio previews no longer fall back to a homonym artist or album, and the preview no longer picks a song from the wrong artist
- New "Your streak song" and "Your single-day record" slides, with animated counters
- The #1 artist, track and album shapes turn while the music plays, and ranks 2-5 use a variety of shapes
- Tap a progress bar at the top to jump straight to that slide
- Shares: extra background shapes (especially on single-slide shares), the title a bit lower, only the scrobble count on the first slide, and your display name when you set one
- Customize the share image (color, light/dark theme, font) from the last slide, and customize options open in a scrollable panel with colors, color style, light/dark, image shapes and every font; your own style is restored when you leave

**Dashboard**
- Tapping your profile opens a centered bubble with your profile info and every shortcut (settings, notifications, recaps, achievements, profile scanner, refresh, reset cache, connections); the tiles have the same size and tapping your own profile opens it like a friend's one
- The settings button and its long-press menu are gone, and the notification bell only shows in the header when there is something new
- The greeting next to your profile changes with the time of day, the weekend, what you are listening to, your listening habits and your account anniversary; new messages when a friend catches up with you, at Christmas, New Year and Easter, and for each season (reversed for southern-hemisphere countries), translated in every language
- Now-playing card: the cover on the left fades into the card color with the title on the right, the animated cover follows the track when it changes, and the accent color follows the cover even when Last.fm has no picture
- You can pick a background image from your device (kept inside the app, 4 MB max) in addition to a link
- Tapping the level opens the levels page, the "this week" badge uses the softer accent, the duplicate scrobbles icon is gone, and country and member-since no longer show in the header (still in the profile bubble)

**Details and artist page**
- The "read more" button for bios and lyrics expands smoothly, morphs between its two states and keeps rounded corners while pressed
- Artist page: the top tracks ranking has a sliding tab selector, bars that fill in, and a cleaner switch between "popular" and "recent"
- Charts: tapping a legend row or bar gives a small vibration and a soft press animation

**Notifications**
- Notifications now show the LastStats logo (status-bar glyph and large icon) instead of a plain circle, and every message notification starts with its emoji (a default one per type when none is set)
- New "Mark as read" and "Mark all as read" buttons on notifications (also clears the download-complete one); "Download" button on the update notification
- When a download finishes while you are outside the app, the notification offers to install (button and tap); the downloaded installer is deleted automatically once the update is installed, and after saving a file to Downloads
- After a download from the version history, the sheet has a button that opens your Downloads folder, and the notification opens it too

**Interface and animations**
- Every tappable area (lists, cards, settings rows, chips, sheets, login page, profile bubble) has the same small press bounce and a pressed fill that follows its own rounded shape, also on tiles with their own background; round buttons such as the back arrow stay round
- The top bar no longer turns grey when scrolling and pressed buttons no longer show a round Android ripple
- The side rail on large screens slides smoothly when collapsed or expanded
- New central file lib/theme/m3_interaction.dart for press and top-bar style

**Widgets**
- Android widgets redesigned in Material You: system dynamic colors (wallpaper-based on Android 12+), system corner radius, follows the system light/dark mode, rounded square album art, themed LastStats glyph, picker descriptions in every language and a real preview
- Widgets refresh their data themselves from Last.fm (never stale), keep rounded corners when resized and use the app's exact color scheme; recap widget fixed
- Widgets use the same poster style as the share images (flat color, soft cookie shapes, stat tiles) and follow the app options: light/dark mode, accent color, dynamic color (Material You) and the "colored widgets" switch; fixed clipped numbers on the small widgets and the empty space in the recap widget
- Now-playing widget: new layout with the cover on the left, and the cover now loads even when Last.fm has none (same sources as the app)

**Battery and sync**
- Battery saver: the screen really drops to ~60 Hz (native refresh-rate control, works on adaptive 120 Hz phones) and goes back to the highest rate when turned off; the animated dashboard background is paused and the blurred image is cached
- Sync: "Sync now" shows the wavy progress bar, and friends sync includes all your Last.fm friends, not only favourites and scanned profiles

**Settings and cache**
- Android: choose the app icon in Settings > Appearance (Classic, Light, Nothing dark, Nothing light, Blue, Red); the change applies when you leave the app
- Settings that only exist on some platforms are now hidden elsewhere: battery saver and its quick toggle (phones/tablets only), notifications (not on web), the Android widgets option (Android with the Nothing style only)
- New "Tinted" color style where even backgrounds, borders and text carry a faint tint of your accent, and the descriptions of the other color styles are rewritten
- Cache: new size limit for stored API data, the redundant "animated covers in memory" block is removed, and clearing any cache asks for confirmation

**Maintenance**
- Every workflow job that pushes to gh-pages now shares one queue, which fixes the "fetch first" push error
- All new texts are translated in every language

