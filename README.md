# LastStats 🎵

A modern, multiplatform application built with **Flutter** and **Material You (M3)** to visualize, track, and analyze your listening statistics in real-time using the **Last.fm** API.

---

## ✨ Features

* **Minimalist & Modern Design:** Clean interface inspired by technical aesthetics, optimized for quick and efficient data reading.
* **Material You Integration:** Dynamic theme that automatically adapts to your system colors (Dynamic Color) with full native dark mode support.
* **Real Data:** Direct and seamless connection with the Last.fm API to fetch your actual scrobbles, top artists, albums, and tracks.
* **Zero Simulated Data:** The application only processes live, functional API data streams.
* **Multiplatform:** A single codebase to build versions for Android, Windows, macOS, Linux, and Web.

---

## 🚀 Downloads & Automated Builds (CI/CD)

This project uses automated pipelines powered by **GitHub Actions**. Every time the code is updated, the executables are built independently.

You can download the latest builds directly from the **Actions** tab of this repository:
* 🤖 **Android:** `laststats-android-apk`
* 🪟 **Windows:** `laststats-windows-app`
* 🌐 **Web:** `laststats-web-app`
* 🍏 **macOS:** `laststats-macos-app`
* 🐧 **Linux:** `laststats-linux-app`

---

## 📦 Technologies Used

* **Framework:** Flutter (Dart)
* **Design System:** Material Design 3 (Material You)
* **Key Packages:** `dynamic_color` for dynamic palette extraction and system adaptation, `url_launcher` for external links.
* **API:** Last.fm REST API
* **Automation:** GitHub Actions (Isolated workflow files for each platform)

---

## 📝 License

This project is open-source. Feel free to use, modify, or contribute to it.