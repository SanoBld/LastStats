# LastStats

<p align="center">
  <img src="https://img.shields.io/github/v/release/SanoBld/LastStats-App?style=flat-square&color=7C3AED&label=Version" alt="Latest Release">
  <img src="https://img.shields.io/github/actions/workflow/status/SanoBld/LastStats-App/build-all.yml?branch=main&style=flat-square&label=Builds" alt="Build Status">
  <img src="https://img.shields.io/github/license/SanoBld/LastStats-App?style=flat-square&color=555555" alt="License">
</p>

A modern, multiplatform app built with Flutter and Material You to track and explore your listening habits in real time, using the Last.fm API.

Join the community on Discord: https://discord.gg/JjqmkQgZBs

---

## Features

**Design and theming**
- Clean, minimalist interface that works on phones, tablets, and desktop
- Full support for system light and dark mode, plus a pure black OLED theme
- Custom accent colors, either from presets or your own hex code
- Dynamic color that can match your device's system palette
- A Nothing OS inspired theme, with a classic red style or a mixed red and yellow style
- Optional Now Playing color mode, where the app's accent shifts to match the artwork of the track you are listening to
- Adaptive navigation: a side rail on wide screens, a bottom bar on smaller ones, and a manual switch if you prefer

**Favorites**
- Like tracks, artists, and albums directly from the app
- A dedicated Favorites page with filters and cover art
- A small heart badge next to loved tracks in your recent listens, history, and search results
- A favorites count shown on your dashboard

**Data and sync**
- Direct connection to the Last.fm API for real, live scrobbles, top artists, albums, and tracks
- Flexible time ranges: 7 days, 1 month, 3 months, 6 months, 12 months, or all time
- Background sync that keeps your stats up to date automatically
- Local cache to reduce loading times and API calls
- No fake or simulated data, everything comes from your real listening history

**Notifications**
- Get notified when new app updates or news posts are published
- A small badge on the news bell so you never miss an update
- Notifications can be turned on or off at any time

**Languages**
- Available in French, English, Spanish, Chinese, Portuguese, German, Italian, Japanese, Russian, and Arabic
- The app follows your system language automatically, or you can pick one yourself

**Other**
- Haptic feedback on key actions
- Optional labels under the navigation bar icons
- Built in update checker that lets you know when a new version is ready to download

---

## Downloads

You can find every release, for every platform, on the releases page:

https://github.com/SanoBld/LastStats-App/releases

Prebuilt files are also generated automatically after each update, through GitHub Actions:

https://github.com/SanoBld/LastStats-App/actions

Builds coming straight from Actions contain the latest code and may include bugs that have not been fixed yet. If you want a stable experience, use the releases page instead.

---

## Built with

- Flutter and Dart
- Material Design 3 (Material You)
- Last.fm REST API, with iTunes Search, Deezer, and Cover Art Archive as backup sources for missing artwork

---

## License

This project is open source. You are free to use it, modify it, or contribute to it.