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

