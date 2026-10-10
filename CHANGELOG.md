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


## v4.0.0

**Overall design overhaul and Material 3 Expressive**
- New wavy loading indicator (rotating bumpy shape) replaces the old spinners on full pages, chart sections and dialogs
- Motion physics: spring-like curves (spatial and effects, fast / default / slow) for buttons, switches, chips and new components
- All chips and segmented buttons now animate: the selected one becomes a pill, the others stay soft squares
- Heart button: round when not loved, grows into the bumpy cookie shape with the vivid accent color when loved
- Play button: round pill when stopped, turns into a rounded square with the vivid accent color while playing
- Side-by-side buttons (update download/details, crash log share/clear) form a connected group of rounded squares that turn into a pill when pressed
- Pop-up and drop-down menus use the same rounded tonal surface
- Images, loading and pages: Images use Material You shapes (cookie, circle, clover, arch, leaf, oval…) in lists, popular albums, history and recaps, each item keeps its own shape
- Posters, images and the biography show the wavy loading indicator while loading, all small spinners in the app now use it too
- Loading screens are centered and visible everywhere, skeleton blocks have more contrast in dark theme
- Large screens: Side rail with rounded indicator, content in a rounded centered panel (tablet style)
- Profile search grid and folder grid adapt to the screen width

**Settings**
- **General redesign (Material 3 Expressive):**
  - Every settings page now shares one design: cookie-shaped icon badges, grouped tiles (big outer corners, small inner corners), spring press animation, a check icon inside switches, clearer section titles and an 8dp spacing scale
  - Same controls everywhere: switch rows, "choice" rows, action rows, sliders, text/URL rows and time rows. The current value is always visible on the right (no more mixed chips, segmented buttons and cards)
  - New choice sheet: shows all options at once with shape-morphing cards, and scrolls only when the list is too long for the screen
  - Applied to Dashboard, Appearance, Startup, Notifications, Backup, Sync, Cache, Battery saver and PC mode. Older rows on the other pages are restyled automatically
  - Updates, About, Account, FAQ, Language and Version history now share the same style: softer rounded cards, cookie-shaped logo and icons, rounder update banner
  - Destructive actions (log out, clear cache…) now use a red container with a matching icon instead of a red icon on a blue badge
  - FAQ questions and the open-source libraries list are now Material 3 accordions: card that morphs when opened, spring chevron, smooth height animation
  - Notification bars ("Backup saved", "Export failed"…) now float with the app accent color, rounded corners and a smooth slide-in/out animation
- **Library options:**
  - New option "Link versions of the same track": remasters, singles, (feat. ...) and deluxe editions count as one track or album with plays added together; remixes, live and instrumental versions stay separate
  - New option "Split collaborations": "Gims & Damso" counts for both artists instead of being a third artist; bands such as "Simon & Garfunkel" stay whole
  - Both library options apply to top lists, rankings, charts and item stats, and appear in Settings and in the welcome flow
  - Library options now apply everywhere: top lists, rankings, charts, recap, history counters, taste comparison (both sides use the same keys) and friends' libraries; friends' cached libraries are rebuilt when the options change
- **Appearance settings:**
  - New setting Settings > Appearance > Image shapes: mix of Material You shapes, square, circle, or one single shape for all images
  - The Nothing OS style stays hidden for now: Settings > Appearance shows a greyed-out Nothing OS card marked "Being improved", with a message explaining it when tapped
- **Account (API key):**
  - New "Change API key" in Settings > Account: replace your key with another one, or switch to the app's built-in key
  - If you picked the built-in key when you signed in, a new "Use my own API key" button lets you add your own key later
  - The new key is checked with Last.fm before it is saved (the built-in backup key is paused during the check, so a wrong key can't pass unnoticed)
  - The favorites connection is removed when the key changes, because it depends on the old key; you can reconnect it with your secret key, and the dashboard restarts with the new key
  - With the built-in key, a short note explains why favorites need your own API key and secret key

**Dashboard and Discover**
- **Dashboard customization and reordering:**
  - Settings > Dashboard rebuilt: header image, animation and blur, visible sections, Discover, chart and stat cards, each with the same row types
  - New "Reorder sections" button in Settings > Dashboard: drag Stats, Discover, Recent plays, Friends and the Chart/calendar block into any order you like
  - New "Choose and sort" sheet for Discover filters and stat cards: tick what you want and use the Sort button to drag them in your order (the chosen order is now used on the dashboard)
- **Discover:**
  - New dashboard section "Discover" between the stats and the recent plays: swipeable music ideas (community picks, trending artists, similar to your top artist, your country) with Material You shaped images
  - Show or hide it, and pick its sources, in Settings > Dashboard
  - The Discover section is now split in two: "Pour toi" (your top artist and your country) always comes first, "Tendances Last.fm" (worldwide top tracks / top artists) comes below
  - Discover filters can be shown on their own row, outside their tab ("Show on its own row" icon in the sheet)
  - Discover filters stay on one scrolling line
  - New "Infinite scroll" option in Settings > Dashboard: the Discover section loops endlessly instead of stopping at the last card
  - Discover source "On this day": tracks you played on this same day/month in previous years, pulled from your locally cached listening history (works offline once your history is loaded)
  - New option "Most relevant filter first": filters are sorted by usefulness for the moment (time of day, weekend, start of the month), your habits (filters you pick and cards you open, recent ones count more), and rotation so the same filter is not always first
  - "On this day" jumps to the front once a day when you really listened to music on this date in past years, and is hidden when there is nothing to show
  - Filters that come back empty go to the end

**Media display, posters and Apple Music**
- Album, artist and track posters: redesigned titles
- New poster shapes
- New video mode for Apple Music posters: an animated video preview instead of a static cover
- Apple Music video: much better matching, tries every release of a track (single, album, deluxe), smarter title/artist matching and a more robust token lookup
- YouTube fallback for track video posters: when Apple Music has no motion artwork, a short loop of the official YouTube video is used (silent, one moment of the clip); new video cover settings: source (Auto/Apple Music/YouTube), quality (auto to 1080p) and which types (tracks/albums/artists) get a video
- Translate button redesigned in Material You, it changes color and shape when the bio is translated
- New: choose the order, Apple Music then YouTube (default) or YouTube then Apple Music, or a single source
- New: modes (Recommended = default, Data saver, Max quality; Custom shows when settings match none)
- Appearance tab harmonised: same section titles and spacing everywhere, sections grouped (Style, Theme, Colors, Covers & detail pages, Interface); video settings use the same chips as the music-platform picker

**Large screens (PC) and web version**
- PC side bar rebuilt: full-width pills with icon and label inside the highlight, 52 dp tall, centred in the bar; collapsed mode shows tooltips
- "For you" / Discover on PC: 172 dp cards in a horizontal strip with mouse drag, left / right arrows and hover effect (phones unchanged)
- Friends row on the dashboard: arrows and mouse drag on PC
- Friend profile, title, album and artist pages: centred column (max 980 dp), banner capped at 320 dp, albums on a single row of ~150 dp covers on PC
- Charts, Search, Rankings, History and Favorites tabs: centred content column on PC (phones unchanged)
- French, Spanish, German, Italian, Chinese, Portuguese and Russian texts now use the formal "you" (vous / usted / Sie / Lei / 您)

**Friends and social features**
- Friends: cards are now one consistent rounded square shape (removed the mixed square/circle/oval variants)
- Friends: online status fills the whole card with your accent color instead of a hardcoded green overlay
- Friend profile poster: online status is shown only by the ring around the avatar (star-shaped for favourites, circle otherwise); the separate dot and "Now listening" pill are gone
- Friend profile poster: Apple Music motion artwork (animated video) for the currently playing track, with a photo/video switch glued next to the back and favourite buttons, following the existing motion artwork setting
- Favorites and favorite folders redesigned: grouped buttons, grouped list rows, pill search, cookie badges, cards that change shape when pressed
- "Add to folder" sheet redesigned with drag handle, tinted rows and animated check

**Charts, rankings, history and recaps**
- Charts tab restyled to match the other tabs: flat tonal cards with large rounded corners, tonal stat chips and streak tiles, primary-container loading banner, tonal export button
- Rankings podium redesigned to match the recap podium: shaped covers with rank badge, text under the cover, tonal bars
- Rankings: new date button opens a Material You sheet to pick year and month
- History date buttons redesigned as connected Material You buttons that change shape when pressed
- Recaps: tonal buttons, animated story bar, animated filters and shaped images

**Achievements, news and level system**
- Achievements redesigned to match the rest of the app: Material 3 Expressive header, level card, grouped category list and milestone lists with big outer and small inner corners, primary and container colors only
- Level history page uses the same header
- New shared-axis animation when opening the level history, with grouped rows and cookie level badges
- Tier styles (bronze, silver, gold, platinum, emerald, sapphire, diamond, chrome, iridescent) redesigned in Material You: soft tonal colors instead of metallic sheens, cookie-shaped badges, theme-colored back of the 3D badge card
- News list: same grouped tiles as settings, cookie-shaped icon badges, consistent spacing
- News colors now follow the app accent colors

**Loading screen, startup and onboarding**
- Loading screen redesigned: rotating cookie badge, progress card with percentage, grouped step tiles
- Welcome flow redesigned in Material You: animated header, tonal option tiles, new "Your library" step, and dashboard options now match the real dashboard settings (removed outdated top artists / albums / tracks switches)

**Installers and deployment (Linux and macOS)**
- New Linux ARM64 build (Raspberry Pi, ARM laptops and servers), built natively
- Linux installers: `.deb` (Debian, Ubuntu, Mint), `.rpm` (Fedora, openSUSE, RHEL) and a portable `.AppImage`, for x64 and ARM64; app menu entry, icon and clean uninstall included
- New `install-linux.sh` one-liner: detects your distro and CPU and installs the right package
- macOS: new `.dmg` installer (drag the app to Applications), universal build for Intel and Apple Silicon
- In-app updater: Linux ARM64 now downloads the ARM64 build
- Release workflow: all installers are built and published automatically with the rest of the release

**Cache management, backups and performance**
- Cache tab: each storage line now stays on one line (size, limit and percentage used), with the bar underneath
- Cache settings redesigned in Material You, with a new Apple Music animated covers entry showing video memory in use, active players and cached links, plus a one-tap release
- Animated covers pause while the app is in the background and release their player immediately if closed while loading; in-memory caches are now bounded
- Restoring a backup that contains scrobbles no longer re-downloads years from A to Z: cached years are trusted and only scrobbles newer than the last cached one are fetched
- Backup: separate switches for dashboard, notifications, library options and favourite profiles; runtime-only markers are no longer exported; image shape, achievements and eco mode are applied immediately on restore
- Backup: the export switches you choose are remembered for next time instead of resetting to defaults
- Backups already include every Dashboard setting (sections order, stat cards, Discover filters, order, own-row filters, smart order, infinite scroll, header options); restore reloads them as before
- Offline images cache simplified (no more RAM cache, less memory used); Android app data backup disabled in the manifest; Russian and Chinese strings added for notifications

**Website, API tab and web version**
- New "Pushes" page on the website (footer link): every push grouped by day with the commit, author, version tag when there is one, search and filters (features / fixes / versions), a link to GitHub and a ZIP download of the code at each push; the list is refreshed at every push to main
- Web version of the app is online: https://sanobld.github.io/LastStats/app/ (Beta, opened from the "Web version" button on the site)
- New "API" tab in Settings: shows today's requests per service, a request limiter option to avoid rate-limit errors, a reset button, and a note that some services are unofficial
- Last.fm rate-limit errors are now retried automatically; the client-side limiter is off by default
- Website: Versions page rebuilt with a table of contents rail, search, Stable / Beta filters, files grouped by platform and infinite scroll; new FAQ entry about missing images
- Website: "Web version" (Beta) button with a warning window, Umami analytics on the web app, fixed the Download button press animation (first open and hover / pressed shape)
- Website and README: all screenshots replaced with 13 new ones (weekly recap, friend profile, music compatibility, light artist page and more), with new texts translated in the 10 website languages, and the zoom on the screenshots removed
- Website: new showcase blocks for the animated artist page and track page videos (play only while visible, controls shown if animations are reduced); the videos, like the screenshots, can be opened full screen from the page and from the gallery
- Website: gallery is now an endless carousel (loops with no first or last image) and includes the two animated page videos, playing when centered; navigation dots stay on one line
- README: new screenshot layout and two animated GIFs (artist page and track page)

**About page and project info**
- About: new README page (opened from About) showing the project README, latest release version, total downloads, stars, license, latest commits and latest workflow runs, loaded from GitHub with an offline fallback to the bundled README
- About: long lists (favourites, sources, keyboard shortcuts, powered by) are folded behind a single row

**Translations**
- All app texts now live in the `l10n` folder, one file per language (`strings_xx.dart`); the two unused files `ui_strings.dart` and `screen_strings.dart` are removed
- Texts that were hard-coded or only translated in 5 languages (dashboard stat cards and sections, image shapes, accent color names, friend status, image sources, tooltips, file picker titles) are now translated in all 10 languages
- Notifications (channels, milestones, daily and weekly recaps, updates, sync) are now translated in all 10 languages, and the background worker uses the language saved in the app
- Formal "you" (vous / usted / Sie / Lei / 您) in French, Spanish, German, Italian, Chinese, Portuguese and Russian; Russian and Chinese notification texts added
- All new features and texts are available in all 10 app languages, reworded to sound natural
- New API key texts (change key, use my own key, errors, favorites warning) and a new FAQ question "Can I change my API key after signing in?" in all 10 languages, each in its own `strings_xx.dart`
- FAQ answers that were too short or outdated (iOS, favorites, backup, accounts, notifications) rewritten as complete explanatory sentences; the accounts answer now explains the 3-account support and the cache reset when switching
- FAQ: removed the "Is an iOS version planned?" question (an iOS build now exists) and reordered the questions by theme (basics, account and API key, data, features, project)
- "Built-in key as backup" description rewritten as a full sentence; new "Being improved" label and message for the Nothing OS style card in all 10 languages
- Code cleanup: removed unused translation helpers (`pickLang`), variables, functions and imports

**Bug fixes**
- Fixed a wrong translation in the profile tab: the active days label read "d'activité" / "of activity" (and similar in Spanish, Italian, Portuguese); it now reads "jours actifs" / "active days"
- Fixed mixed-language color names in Settings, the informal "Ou choisis" in image shapes, and "Tout temps" (now "Depuis toujours")
- Fix: tracks, albums and artists opened from a friend's profile now load their video and your stats, and stack on top of the profile instead of replacing it
- Fixed a white square that stayed visible on a chip (e.g. tapping "This month" in Discover) until scrolling — chips no longer keep a stuck highlight after a tap
- Fixed a plain grey loading box on Discover: it now shows the usual small animated wavy loader, correctly sized
- Page transitions no longer show the home screen behind while animating (fixes the achievements category animation)
- Dashboard: the now-playing cover no longer uses a circle shape, since a rotating circle shows no animation
- Fixed: YouTube videos did not start. Since 2026 YouTube refuses most separate video streams without a "PO token" (HTTP 403); only the 360p MP4 (itag 18) still plays. The app now uses the Android VR client, always keeps the 360p stream as a fallback, tests links deep inside the file, sends the User-Agent each link needs, and switches to the 360p stream if the chosen quality is refused
- The photo / video button only disappears when nothing plays at all
- YouTube links expire: they are looked up again after 90 minutes. On iOS / macOS only H.264 is used
- Apple Music: the chosen quality variant is checked before use, otherwise the adaptive video is kept
- Fixed Dart analyzer errors on the dashboard (weekly count type), the deprecated `onReorder` in the reorder sheet and missing braces in the taste engine

**Spotify Canvas**
- New video cover source: Spotify Canvas (tracks and albums), with in-app Spotify login in Settings > Appearance > Video covers
- Video sources can now be chosen and sorted freely (Apple Music, Spotify, YouTube Music)
