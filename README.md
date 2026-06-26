# 🎵 LastStats

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![PWA Ready](https://img.shields.io/badge/PWA-Ready-orange.svg)
![Vanilla JS](https://img.shields.io/badge/Framework-Zero-yellow.svg)

> **Your Last.fm music stats, reinvented.**
> A minimalist and powerful PWA to explore, analyze, and share your listening history with a fluid and modern experience.

---

## 📌 Summary

1. [🌟 Overview](#-overview)
2. [⚡ Highlights](#-highlights)
3. [🚀 Quick Start](#-quick-start)
4. [🛠️ Tech Stack](#-tech-stack)
5. [🔒 Privacy & Security](#-privacy--security)
6. [📈 Key Features](#-key-features)
7. [🗺️ Roadmap](#-roadmap)
8. [🤝 Contribution](#-contribution)

---

## 🌟 Overview

**LastStats** transforms raw data from the [Last.fm](https://www.last.fm/) API into interactive dashboards and elegant visualizations.

Built on a **"Zero Framework"** philosophy, the project leverages the native power of the modern Web (ES6+) to ensure maximum performance, a lightweight footprint, and total independence from heavy third-party libraries.

---

## ⚡ Highlights

* 🚀 **Maximum Performance**: Zero framework (Vanilla JS), near-instant loading times, and butter-smooth animations.
* 📱 **Full PWA Experience**: Installable on iOS/Android with offline support via Service Workers.
* 🎨 **Material You Design (M3)**: Adaptive interface with Light/Dark themes and dynamic color accents.
* 📊 ** Visualizations**: Advanced charts powered by Chart.js and D3.js (Radar, Sunburst, Treemaps).
* 🌐 **Built-in i18n**: Native multi-language support (12 languages) with automatic browser language detection.

---

## 🚀 Quick Start

This project requires no build step or compilation. A simple HTTP server is enough (required for Service Worker functionality).

```bash
# 1. Clone the repository
git clone https://github.com/sanobld/LastStats.git
cd laststats

# 2. Launch a local server
npx serve .
# OR
python3 -m http.server 8080
```

Then open `http://localhost:8080` and enter your [Last.fm API key](https://www.last.fm/api/account/create).

---

## 🛠️ Tech Stack

The project is built on a **pure web** architecture, prioritizing native standards for longevity and performance.

* **Logic & UI**: Vanilla JavaScript (ES6+), HTML5, CSS3 (Custom Properties)
* **Data Visualization**: [Chart.js](https://www.chartjs.org/) · [D3.js](https://d3js.org/)
* **API**: [Last.fm API](https://www.last.fm/api) (REST)
* **PWA**: Service Workers with versioned cache and bounded image storage
* **Icons**: [Google Material Symbols](https://fonts.google.com/icons) · [Font Awesome](https://fontawesome.com/)

---

## 🔒 Privacy & Security

Your privacy is at the core of LastStats. No data passes through our servers.

* **Client-Side Only**: All calculations and rendering happen locally in your browser.
* **No Database**: Credentials are stored only in your device's `localStorage` and never transmitted to a third party.
* **Open Source**: The code is fully transparent and auditable.

---

## 📈 Key Features

* **Dynamic Dashboard**: Top artists, albums and tracks across multiple timeframes (7 days → all-time).
* **Listening Calendar**: GitHub-style heatmap of your annual scrobble activity.
* **Advanced Visualizations**: Genre Radar, Sunburst hierarchy, Sankey flow charts.
* **Obscurity Score**: How underground is your taste? Rated 0–100.
* **Badge System**: 20+ achievements with 5 tiers (Bronze → Elite) and XP levels.
* **History Browser**: Day-by-day scrobble timeline with stats and hour distribution.
* **Compare Mode**: Musical compatibility score with any Last.fm user.
* **Wrapped**: Annual recap with story-style export cards.
* **Live Scrobbling**: Now-playing widget that refreshes every 2 seconds while music is playing.
* **Export**: CSV/JSON data export and shareable image cards.

---

## 🗺️ Roadmap

Items in active development or planned for future releases.

**v2.x — In Progress**
- [ ] Offline-first full history: background sync when back online
- [ ] Listening streaks extended stats (longest streak calendar highlight)
- [ ] PWA share-target support (share from Spotify/Apple Music to LastStats)

**v3.0 — Planned**
- [ ] Multi-account support (switch between profiles without re-login)
- [ ] Artist deep-dive page with discography timeline
- [ ] Scrobble heatmap by hour × day-of-week (2D grid)
- [ ] Customizable dashboard widget layout (drag & drop)
- [ ] Collaborative Wrapped — compare two full Wrapped summaries side by side
- [ ] Listening goals & streaks (set daily/weekly scrobble targets)

**Nice-to-have**
- [ ] Dark OLED theme variant
- [ ] Push notifications for milestone badges
- [ ] Offline badge computation after initial history load

---

## 🤝 Contribution

1. **Fork** the project.
2. Create your feature branch: `git checkout -b feature/AmazingFeature`
3. **Commit** your changes: `git commit -m 'Add some AmazingFeature'`
4. **Push** to the branch: `git push origin feature/AmazingFeature`
5. Open a **Pull Request**.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.