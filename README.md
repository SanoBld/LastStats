# 🎵 LastStats

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![PWA Ready](https://img.shields.io/badge/PWA-Ready-orange.svg)
![Vanilla JS](https://img.shields.io/badge/Framework-Zero-yellow.svg)

> **Your Last.fm music stats, reinvented.**
> A minimalist and powerful PWA (Progressive Web App) to explore, analyze, and share your listening history with a fluid and modern experience.

---

## 📌 Summary

1. [🌟 Overview](#-overview)
2. [⚡ Highlights](#-highlights)
3. [🚀 Quick Start](#-quick-start)
4. [🛠️ Tech Stack](#-tech-stack)
5. [🔒 Privacy & Security](#-privacy--security)
6. [📈 Key Features](#-key-features)
7. [🤝 Contribution](#-contribution)

---

## 🌟 Overview

**LastStats** transforms raw data from the [Last.fm](https://www.last.fm/) API into interactive dashboards and elegant visualizations. 

Built on a **"Zero Framework"** philosophy, the project leverages the native power of the modern Web (ES6+) to ensure maximum performance, a lightweight footprint, and total independence from heavy third-party libraries.

---

## ⚡ Highlights

* 🚀 **Maximum Performance**: Zero framework (Vanilla JS), near-instant loading times, and butter-smooth animations.
* 📱 **Full PWA Experience**: Installable on iOS/Android with offline support via Service Workers.
* 🎨 **Material You Design (M3)**: Adaptive interface with Light/Dark themes and dynamic color accents.
* 📊 **Pro Visualizations**: Advanced charts powered by Chart.js and D3.js (Sankey, Sunburst, Treemaps).
* 🌐 **Built-in i18n**: Native multi-language support with automatic browser language detection.

---

## 🚀 Quick Start

### Local Installation

This project requires no build step or compilation. A simple HTTP server is enough (required for Service Worker functionality).

```bash
# 1. Clone the repository
git clone [https://github.com/your-username/laststats.git](https://github.com/your-username/laststats.git)
cd laststats

# 2. Launch a local server
npx serve . 
# OR
python3 -m http.server 8080
```

## 🛠️ Tech Stack

The project is built on a **pure web** architecture, prioritizing native standards for longevity and performance.

* **Logic & UI**: Vanilla JavaScript (ES6+), Web Components, HTML5, CSS3 (Custom Properties).
* **Data Visualization**: [Chart.js](https://www.chartjs.org/) for trend graphs and [D3.js](https://d3js.org/) for complex data structures.
* **API**: [Last.fm API](https://www.last.fm/api) (REST).
* **PWA**: Service Workers (Workbox) for caching and offline support.
* **Icons**: [Google Material Symbols](https://fonts.google.com/icons).

---

## 🔒 Privacy & Security

Your privacy is at the core of LastStats. Unlike other analytics tools, no data passes through our servers.

* **Client-Side Only**: All calculations and data rendering happen locally in your browser.
* **No Database**: We do not store your credentials. Your API key (if provided) is stored only in your device's `localStorage`.
* **Open Source**: The code is transparent and can be audited by anyone at any time.

---

## 📈 Key Features

* **Dynamic Dashboard**: Visualize your top artists, albums, and tracks across various timeframes (7 days, 1 month, 3 months, overall).
* **Time-Machine Reports**: Explore your past listening habits with filters by year and month.
* **Data Export**: Generate elegant visuals ready to be shared on social media (Instagram, Twitter).
* **Sankey Charts**: Track the transition of your musical tastes between genres over time.
* **Live Scrobbling**: View your listening activity in real-time with smooth animations.

---

## 🤝 Contribution

Contributions are what make the open-source community an amazing place. Any help is greatly appreciated!

1.  **Fork** the project.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).
4.  **Push** to the branch (`git push origin feature/AmazingFeature`).
5.  Open a **Pull Request**.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
