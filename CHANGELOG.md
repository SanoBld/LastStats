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


## v4.5.0

### Highlights
- ListenBrainz support: log in with your user token and use the whole app without Last.fm
- Year recap redesigned: full-screen covers, animated covers, most played track on each chart, new sharing options
- News button on the login screen, new Last.fm and ListenBrainz help pages and FAQs

### Major: ListenBrainz
- New: choose between Last.fm and ListenBrainz on the login screen, with help links. Last.fm is marked as a paid API (an API key requires Last.fm Pro from December 1); ListenBrainz is free and only needs your user token
- New login: ListenBrainz in 3 steps (open your token page, paste, connect), a copied token is detected and offered automatically, clear error messages, optional display name. Last.fm login now only asks for your own API key. Smooth transition between the service choice and the forms
- ListenBrainz mode: everything is read from ListenBrainz and Last.fm is never contacted, whatever the key (profile, tops, recent listens, loved tracks, friends, charts). Search, tags and artwork come from MusicBrainz and Cover Art Archive. Anything ListenBrainz cannot provide is hidden. Last.fm mode is unchanged
- Existing users stay logged in on Last.fm and go straight to the dashboard; only logged-out users see the login screen
- Switching service (login screen or Settings > Account) with local scrobbles: transfer them to ListenBrainz, merge both histories (Last.fm wins on conflicts) or start fresh. Nothing is deleted unless you choose to start fresh
- Scrobbles are stored on the device like with Last.fm (same yearly files, incremental sync, duplicates removed). A failed sync no longer leaves a gap, and years are found again after a crash
- History, music calendar, recap and notification stats work with ListenBrainz; listener and play counts on artist / album / track pages come from ListenBrainz popularity data
- Unique tracks, artists and albums counters now work in ListenBrainz mode (taken from the all-time statistics; the profile makes 3 more requests)
- Your own account no longer appears in your followed users list (duplicates and empty names are removed too)
- Settings adapt to the service: ListenBrainz card and token section, profile link to listenbrainz.org, no API key info or extra accounts in ListenBrainz mode
- Backup: export / import keep the service and the token; restoring a ListenBrainz backup reconnects to it
- ListenBrainz requests are retried on temporary network errors ("Connection terminated during handshake")
- Public (built-in) API keys are turned off, because Last.fm requires a paid subscription for API keys from December 1. Your own key is always the one used (the code is kept and can be switched back on); the built-in key and Last.fm website login choices are removed
- Official ListenBrainz and MusicBrainz icons in About, in the API image sources and in the detail page links; texts, dialogs and links follow the service in all 10 languages

### Major: Year recap
- The #1 artist, #1 track, #1 album, streak track and record-day track now use their cover as a full-screen background, with the name big in the middle (for example "Your #1 hit"). The background also covers the status bar, the top bar and the buttons
- Animated covers (videos) play on these slides when enabled in Settings > Appearance. They follow the per-type switches and the eco mode. During sharing, a still image is used
- New button next to the share icon, available on every slide: switch the cover between full screen, top banner and no image. Your choice is saved, applies to the shared image, and is remembered separately for the #1 slides and for the other slides
- Each chart (best month, listening hours, top artist share, discoveries) now shows the most played track of its context
- Last slide: choose the image of the summary card (top 1 cover, profile picture or none). The choice is saved and used for the shared image
- Sharing: the cover of the slide replaces the profile picture at the top of the shared image (full poster for the #1 slides). The cover is downloaded before the capture so the image is never empty
- Covers are never stretched or squashed anymore: they fill the area and are cropped. This also fixes distorted covers elsewhere in the app when the area is not square

### Login screen and onboarding
- New "News" button (before logging in) to check for outages, maintenance and announcements. If you are offline, an error message with a "Retry" button is shown
- The News and Language buttons now match the style of the app (same shape, height and press effect). Tooltips use the app style too
- Buttons that name the service (first setup, Settings > Startup, Settings > Connection, friends icon) show "ListenBrainz" or "Last.fm" depending on the service you use
- Last.fm Pro date written in full ("from December 1, 2026") on the login screen and in Settings > Connections
- Removed outdated texts that still mentioned the built-in key and the Last.fm website login

### News & announcements
- Texts now support **bold**, __underline__, ==highlight==, ~~strikethrough~~, *italic*, `code`, titles, bullet and numbered lists, quotes, links, tables and line breaks (type \n in the workflow field), in the app and on the website. The workflow field describes the whole syntax, so you can hand it to an AI
- Fixed accents and emojis being garbled in news; previews in the list and in notifications show clean text instead of raw ** and |; the website translation keeps spacing and formatting
- New workflow to delete a news item (list, last, by id or by position)
- News and releases (stable and beta) are also posted on Discord by the same workflow script, with the full changelog, bold text, lists and tables

### Help and FAQ
- New Last.fm FAQ and ListenBrainz FAQ (5 questions each: API key, Last.fm Pro, user token, statistics, history import) in the app and on the help page of the website
- New "ListenBrainz" help section on the website (tutorial, how it works, account and token, scrobbling, switching service, troubleshooting), built like the Last.fm one
- The general FAQ (app and website) now covers both services: scrobbles, data storage, favorites, backup and switching account or service. Outdated "3 accounts" and "built-in key" mentions removed

### Offline and images
- Images: artwork and avatars shown in lists now use the on-device image cache, so they no longer reload at every launch. The cache is read at startup, so cached images show in the first frame
- Network errors: the last good ListenBrainz answer is kept on the device and shown when the network fails (DNS / timeout). Rankings fall back to the scrobbles stored on the device. The page keeps its data instead of an error screen
- New error icon (top-left on the dashboard, top-right on other tabs, in the header): tap it to see the error details. It disappears when the connection is back
- Loading: once your scrobbles have been synced, the dashboard and rankings show your saved data at once (no skeleton) and refresh in the background. A small spinner shows in the error icon spot while it loads; if it fails the error icon shows instead, and if it works the screen only changes when the data really changed
- Same instant loading for History (the day is read from your device) and Charts (top artists / albums from your device), with the background refresh spinner and error icon
- The loading spinner next to the error icon now uses the app's own loader
- Long press / right click: the folder cards, the heart buttons (favorites and detail page) and the rankings rows (right click on PC) now open the same bubble menu as the History tracks
- Favorites page: your saved list shows at once and refreshes behind (spinner / error icon in the top bar)
- Tab titles (Rankings, Charts, History) now use the accent color, like the dashboard

### Dashboard & errors
- When Last.fm or ListenBrainz answers with a web page (maintenance, server error) instead of data, a short translated message is shown instead of a technical error
- If loading fails, the dashboard shows the saved data first with a small "saved data shown" note; the error screen only appears when nothing is saved
- Dashboard header "Music animation" rebuilt as a real living background (three drifting layers, soft colour wash, gentle breathing); pauses when the video cover plays and in eco mode; renamed "Animated music background"
- "Now playing" card: smooth appear / disappear (slides in with fade and blur, the page below moves gradually); a track change only cross-fades
- Dashboard settings: "Backup period" renamed to a clearer label (period of the top pick shown when nothing is playing)

### Animations & design (Metrolist-inspired)
- New: "Motion blur" option in Appearance, saved with your themes
- Pull-to-refresh uses the app loader; one loader and one progress bar style everywhere; every tab shows placeholder shapes laid out like its own content
- Options bubble: long-press (right-click on PC) a track in History, Rankings, Favorites or folders. Open on Last.fm, Spotify, YouTube Music, Apple Music or Deezer, copy the title or "artist - title", add to a folder
- Favorites: sort is a single chip opening the bubble; new multi-select (long-press > Select) to remove several tracks at once
- Equalizer bars on the "Now playing" badge, confetti at the end of the year recap, smooth fade when artwork or the accent colour changes, long titles scroll by themselves
- Brand logos: real logos in the website download window and in Settings > About (Apple, Deezer, Spotify, GitHub, YouTube Music, Windows, Linux, Android, Telegram, Instagram, YouTube, Buy Me a Coffee)
- PC: lists can be dragged with the mouse, start-up screen appears instantly, lower image cache memory; Android 14+: predictive back gesture; lighter calendar rendering, badge shimmer paused in the background

### Interface
- Removed: the Nothing OS style; the app now always uses Material You
- Charts calendar redesigned in the GitHub contribution style (months on top, Mon/Wed/Fri, rounded cells, Less/More legend, year selector), opening on today; the home calendar and shared calendar image use the same design and always fill the full width with real data
- Link versions / split collaborations: smarter title cleaning (bracketed titles stay whole, several version tags removed together), options apply to search results, duplicate artists in search shown once; titles made only of symbols ("???") are no longer merged and words like "Lost" or "Ghost" after a dash are not version tags
- Music compatibility: close button, safe-area sheet, long-press a shared item for the options bubble; it can now be shared as a 9:16 image (score, shared counts, breakdown bars, top shared artists and tracks)
- Year recap: lighter, funnier wording in all 10 languages, French-style " :" spacing fixed in other languages; image with the logo lower for more room
- Profile share image: "LastStats" bottom left, the source (Last.fm) just above the QR code
- Friend profile: simple loader with a smooth transition instead of the grey placeholder
- Closing the keyboard also removes the cursor from the text field
- Updated the first-launch introduction (animation blur option, texts matching the current settings)

### Settings
- Account: the "My accounts (1/3)" counter and the "Active" label are hidden when there is only one account
- Appearance: the video cover options now unroll under their switch. The two "Interactions" sections no longer share a title (the first is now "Covers and achievements")
- Removed the BETA badge on the artwork color theme
- API: sort your favourite image sources (Apple Music, YouTube Music, Deezer, TheAudioDB, MusicBrainz, Wikipedia, Last.fm) by dragging and turn each on or off; Apple Music first by default; video sources sorted the same way. Last.fm is hidden in ListenBrainz mode, where ListenBrainz shows your token and its 1 request / second limit
- API: short explanation at the bottom of "Requests today", "Errors" and "Limited"; source logos on the API cards; the cover source now says "Apple Music" instead of "iTunes"
- Options bubble replaces the choice sheets in Settings (video quality, modes...); it scrolls when long. Font pickers keep their preview sheet
- Settings > About reorganised: duplicates removed, support right after app info, owner and licence in the header; sections with only a few rows are shown directly
- Default text size is now 100 % (was 110 %)

### Website
- ListenBrainz is mentioned next to Last.fm (compatibility chip and history text); unused PNG images removed
- Formal address in all French texts

### License
- LastStats is now released under the GNU GPL v3 (was MIT), copyright Sano Bld. New LICENSE and NOTICE.md; README, website legal page, About page, RPM package and the 10 translations updated. Versions released before this stay under MIT

### Texts and translations
- Error messages and the "saved data shown" notice are now full sentences in the 10 languages
- Website tab titles use "|" as separator
- Performance: ListenBrainz requests no longer read the offline copy unless the network fails

### Fixes
- Spotify login: the login page now uses an up-to-date browser identity and allows cookies, storage and pop-ups, so the "Log in" button works again; app links (spotify://) are ignored
- Android notification: "Mark all as read" works when the app is closed
- Rankings: removed the duplicated year / month buttons, the date chip opens the picker again
- Formal address (vous) everywhere in French, including the update dialog, notifications and icon note

