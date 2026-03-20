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
