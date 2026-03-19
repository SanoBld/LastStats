# 🎵 LastStats

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![PWA Ready](https://img.shields.io/badge/PWA-Ready-orange.svg)

> **Your Last.fm music stats, reinvented.**
> A minimalist and powerful PWA (Progressive Web App) to explore, analyze, and share your listening history with a fluid and modern experience.

---

## 📌 Summary

1. [Overview](#-overview)
2. [Highlights](#-highlights)
3. [Quick Start](#-quick-start)
4. [Key Features](#-key-features)
5. [Tech Stack](#-tech-stack)
6. [Architecture](#-architecture)
7. [Contribution](#-contribution)

---

## 🌟 Overview

**LastStats** transforms raw data from the [Last.fm](https://www.last.fm/) API into interactive dashboards and elegant visualizations. Built on a **"Zero Framework"** philosophy, it leverages the native power of the modern Web to ensure maximum performance and lightweight footprint.

---

## ⚡ Highlights

* 🚀 **Maximum Performance**: Zero framework (Vanilla JS ES6+), near-instant loading times.
* 📱 **PWA Experience**: Installable on iOS/Android, works offline via Service Workers.
* 🎨 **Material You Design (M3)**: Adaptive interface with Light/Dark themes and dynamic color accents.
* 📊 **Pro Visualizations**: Advanced charts powered by Chart.js and D3.js (Sankey, Sunburst, Treemaps).
* 🔒 **Privacy First**: Your API keys and data are stored locally (`localStorage`). No data ever leaves your browser.

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