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

**Settings: redesigned in Material 3 Expressive**
- Every settings page now shares one design: cookie-shaped icon badges, grouped tiles (big outer corners, small inner corners), spring press animation, a check icon inside switches, clearer section titles and an 8dp spacing scale
- Same controls everywhere: switch rows, "choice" rows, action rows, sliders, text/URL rows and time rows. The current value is always visible on the right (no more mixed chips, segmented buttons and cards)
- New choice sheet: shows all options at once with shape-morphing cards, and scrolls only when the list is too long for the screen
- Applied to Dashboard, Appearance, Startup, Notifications, Backup, Sync, Cache, Battery saver and PC mode. Older rows on the other pages are restyled automatically
- Updates, About, Account, FAQ, Language and Version history now share the same style: softer rounded cards, cookie-shaped logo and icons, rounder update banner
- Destructive actions (log out, clear cache…) now use a red container with a matching icon instead of a red icon on a blue badge
- All new texts are translated in the 10 app languages, reworded to sound natural
- Notification bars ("Backup saved", "Export failed"…) now float with the app accent color, rounded corners and a smooth slide-in/out animation
- Side-by-side buttons (update download/details, crash log share/clear) form a connected group of rounded squares that turn into a pill when pressed
- FAQ questions and the open-source libraries list are now Material 3 accordions: card that morphs when opened, spring chevron, smooth height animation
- Pop-up and drop-down menus use the same rounded tonal surface
- Backups already include every Dashboard setting (sections order, stat cards, Discover filters, order, own-row filters, smart order, infinite scroll, header options); restore reloads them as before

**Dashboard settings**
- Settings > Dashboard rebuilt: header image, animation and blur, visible sections, Discover, chart and stat cards, each with the same row types
- New "Choose and sort" sheet for Discover filters and stat cards: tick what you want and use the Sort button to drag them in your order (the chosen order is now used on the dashboard)
- Discover filters can be shown on their own row, outside their tab ("Show on its own row" icon in the sheet)
- Discover filters stay on one scrolling line

**Discover: smart order**
- New option "Most relevant filter first": filters are sorted by usefulness for the moment (time of day, weekend, start of the month), your habits (filters you pick and cards you open, recent ones count more), and rotation so the same filter is not always first
- "On this day" jumps to the front once a day when you really listened to music on this date in past years, and is hidden when there is nothing to show
- Filters that come back empty go to the end

**Fixes**
- Fixed Dart analyzer errors on the dashboard (weekly count type), the deprecated `onReorder` in the reorder sheet and missing braces in the taste engine

**Dashboard: reorderable and more customizable**
- New "Reorder sections" button in Settings > Dashboard: drag Stats, Discover, Recent plays, Friends and the Chart/calendar block into any order you like
- New "Infinite scroll" option in Settings > Dashboard: the Discover section loops endlessly instead of stopping at the last card
- New Discover source "On this day": tracks you played on this same day/month in previous years, pulled from your locally cached listening history (works offline once your history is loaded)

**Fixes**
- Fixed a white square that stayed visible on a chip (e.g. tapping "This month" in Discover) until scrolling — chips no longer keep a stuck highlight after a tap

**Material 3 Expressive**
- New wavy loading indicator (rotating bumpy shape) replaces the old spinners on full pages, chart sections and dialogs
- Loading screens are centered and visible everywhere, skeleton blocks have more contrast in dark theme
- Motion physics: spring-like curves (spatial and effects, fast / default / slow) for buttons, switches, chips and new components
- Favorites and favorite folders redesigned: grouped buttons, grouped list rows, pill search, cookie badges, cards that change shape when pressed
- "Add to folder" sheet redesigned with drag handle, tinted rows and animated check

**Buttons and details**
- Heart button: round when not loved, grows into the bumpy cookie shape with the vivid accent color when loved
- Play button: round pill when stopped, turns into a rounded square with the vivid accent color while playing
- History date buttons redesigned as connected Material You buttons that change shape when pressed
- News colors now follow the app accent colors
- New shared-axis animation when opening the level history, with grouped rows and cookie level badges

**Discover: personal first**
- The Discover section is now split in two: "Pour toi" (your top artist and your country) always comes first, "Tendances Last.fm" (worldwide top tracks / top artists) comes below
- Fixed a plain grey loading box on Discover: it now shows the usual small animated wavy loader, correctly sized

**Discover and image shapes**
- New dashboard section "Discover" between the stats and the recent plays: swipeable music ideas (community picks, trending artists, similar to your top artist, your country) with Material You shaped images
- Show or hide it, and pick its sources, in Settings > Dashboard
- New setting Settings > Appearance > Image shapes: mix of Material You shapes, square, circle, or one single shape for all images

**Images, loading and pages**
- Images use Material You shapes (cookie, circle, clover, arch, leaf, oval…) in lists, popular albums, history and recaps, each item keeps its own shape
- Posters, images and the biography show the wavy loading indicator while loading, all small spinners in the app now use it too
- Translate button redesigned in Material You, it changes color and shape when the bio is translated
- Recaps: tonal buttons, animated story bar, animated filters and shaped images
- Page transitions no longer show the home screen behind while animating (fixes the achievements category animation)

**Options and settings**
- All chips and segmented buttons now animate: the selected one becomes a pill, the others stay soft squares
- Rankings: new date button opens a Material You sheet to pick year and month
- Settings redesigned: grouped rows with big outer and small inner corners, cookie profile avatar and category badges, press-morph cards

**Large screens**
- Side rail with rounded indicator, content in a rounded centered panel (tablet style)
- Profile search grid and folder grid adapt to the screen width

