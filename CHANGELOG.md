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
- Loading screens: every tab (charts, ranking, history, search, favorites, track details) now shows soft placeholder shapes laid out like its own content, with the same pulse and loader as the dashboard

**Interface**
- Removed: the Nothing OS style (app, onboarding and settings); the app now always uses Material You
- Music calendar: always fills the full width and shows the latest weeks that fit your screen; in Charts it now opens on today instead of the start of the year
- Charts calendar redesigned in the GitHub contribution style (months on top, Mon/Wed/Fri, rounded cells, Less/More legend, year selector), opening on today
- The home calendar and the shared calendar image now use the same GitHub-style design; removed the Beta badge from the chart export sheet
- Link versions / split collaborations: smarter title cleaning (a title starting with a bracket stays whole, several version tags are removed together) and the options now apply to search results; duplicate artists in search (GIMS, Gims...) are shown once
- Link versions: fixed titles/artists made only of symbols ("???", "!!!") being merged together, and words like "Lost" or "Ghost" after a dash no longer count as a version tag
- Year recap: lighter, funnier wording in all 10 languages; fixed the French-style " :" spacing showing in other languages
- Closing the keyboard now also removes the cursor from the text field, so it no longer pops back up on other tabs
- PC: a start-up screen appears instantly while data loads (the window no longer looks frozen at launch); lower image cache memory
- Performance: lighter calendar rendering, badge shimmer paused while the app is in the background
- Home calendar now loads enough weeks to fill the card with real data
- Friend profile: simple loader with a smooth transition instead of the grey placeholder
- Updated the first-launch introduction: new animation blur option, texts that match the current settings, no more mention of the removed style
- Profile share image: "LastStats" is now at the bottom left and the source (Last.fm) sits just above the QR code

**Metrolist-inspired (design ideas)**
- New: options bubble. Long-press (or right-click on PC) a track in History, Rankings, Favorites or folders: it opens a bubble next to it, growing from the pressed spot, with connected rounded blocks. Open on Last.fm, Spotify, YouTube Music, Apple Music or Deezer (with their logos), copy the title, copy "artist - title", add to a folder
- Favorites: sort is now a single chip that opens the bubble; new multi-select (long-press > Select, tick several tracks, remove them all at once)
- Brand logos: real Apple logo for iOS in the website download window, real logos (Apple, Deezer, Spotify, GitHub, YouTube Music) in Settings > About; added Windows, Linux, Android, Telegram, Instagram, YouTube and Buy Me a Coffee logos
- Animations: equalizer bars on the "Now playing" badge, confetti at the end of the year recap, smooth fade when artwork appears or changes, slower fade when the accent colour changes, long titles scroll by themselves in track lists
- New: "Density" option in Appearance (Compact, Comfortable, Airy), saved and translated in the 10 languages
- PC: lists can be dragged with the mouse; Android 14+: predictive back gesture enabled

- Options bubble now replaces the choice sheets in Settings (video quality, modes, etc.); it scrolls when the list is long. Font pickers keep their preview sheet
- Removed: the interface density option (Compact / Comfortable / Airy)
- "Now playing" card: smooth appear / disappear (slides in with fade and blur, the page below moves gradually instead of jumping); a track change only cross-fades

**Interface**
- Music compatibility: close button, safe-area sheet (no longer under the status bar), long-press a shared item for the options bubble
- Descriptions in announcements and notification details now support **bold**, __underline__, ==highlight==, ~~strikethrough~~, *italic*, `code` and links
- Settings > About reorganised: duplicates removed (version, GitHub link, Metrolist, Flutter, ThemeData), support right after app info, owner and licence in the header

- Music compatibility can now be shared as an image (9:16, 1080x1920 like the other shares): score, shared counts, breakdown bars, top shared artists and tracks
- Year recap image: the LastStats logo sits lower, leaving more room for the lists
- Dashboard settings: "Backup period" renamed to a clearer label (period of the top pick shown when nothing is playing), in all 10 languages
- Settings > About: sections with only a few rows are shown directly, no "show more"

- Dashboard header "Music animation" rebuilt as a real living background (three drifting layers, single blur, soft colour wash, gentle breathing); no longer a copy of the Apple Music effect. It pauses when the video cover plays on top and in eco mode, and is renamed "Animated music background"

**Fixes**
- Android notification: the "Mark all as read" button now works when the app is closed (background plugins registered, in-app news marked read on return)
- Rankings: removed the duplicated year / month buttons, the date chip opens the picker again

**License**
- LastStats is now released under the GNU GPL v3 (was MIT), copyright Sano Bld. New LICENSE and NOTICE.md; README, website legal page, About page, RPM package and the 10 translations updated. Versions released before this stay under MIT

**ListenBrainz**
- New: choose between Last.fm and ListenBrainz on the login screen, with help links (Last.fm Pro, create an account for each service). Last.fm is marked as a paid API (API key requires Last.fm Pro from December 1); ListenBrainz is free and only needs your user token
- ListenBrainz mode: the app reads everything from ListenBrainz and never contacts Last.fm (profile, tops, recent listens, loved tracks, friends, charts). Search, tags and artwork come from MusicBrainz and Cover Art Archive. Anything ListenBrainz cannot provide is hidden. Last.fm mode is unchanged
- Existing users stay logged in on Last.fm and go straight to the dashboard after the update; only logged-out users see the login screen
- Switching service (login screen or Settings > Account) with local scrobbles in the app: transfer them to ListenBrainz, merge both histories (Last.fm wins on conflicts) or start fresh. Nothing is deleted unless you choose to start fresh
- Settings adapt to the service: ListenBrainz card and token section in Connections / Account, profile link to listenbrainz.org, no API key info or extra accounts in ListenBrainz mode
- Login screen: smooth transition between the service choice and the forms, formal address in all texts, 10 languages
- Fixed: ListenBrainz requests are retried on temporary network errors ("Connection terminated during handshake")
- ListenBrainz storage: scrobbles are stored on the device like with Last.fm (same yearly files, same incremental sync, timestamp-based loading, duplicates removed). A failed sync no longer leaves a gap in the history, and years are found again after a crash
- ListenBrainz: history, music calendar and recap work again (listens of a period are downloaded once and shared by all pages); notification stats use ListenBrainz too
- ListenBrainz: listener and play counts on artist / album / track pages come from ListenBrainz popularity data; texts, dialogs and links follow the service in all 10 languages; the official ListenBrainz icon is used everywhere
- New login screen: ListenBrainz in 3 steps (open your token page, paste, connect), a copied token is detected and offered automatically, clear error messages for each failure, optional display name. Last.fm login now only asks for your own API key
- Backup: export / import now keep the service and the ListenBrainz token; restoring a ListenBrainz backup connects to ListenBrainz and reopens the app on that account
- Last.fm is never contacted in ListenBrainz mode, whatever the key
- Public (built-in) API keys are turned off, because Last.fm requires a paid subscription for API keys from December 1. Your own key is always the one used; the code is kept and can be switched back on. The built-in key and Last.fm website login choices are removed
- Default text size is now 100 % (was 110 %)

**Settings > API**
- New: sort your favourite image sources (Apple Music, YouTube Music, Deezer, TheAudioDB, MusicBrainz, Wikipedia, Last.fm) by dragging, and turn each one on or off. Apple Music is now first by default (artists keep YouTube Music lower). Video sources are sorted the same way on the same page
- Last.fm source is hidden in ListenBrainz mode; ListenBrainz appears with your token and its 1 request / second limit
- The image source shown for a cover now says "Apple Music" instead of "iTunes"

