# 🎵 LastStat Downloader

Export, explore, and re-import your Last.fm listening history — entirely in your browser, no backend, ready to deploy on GitHub Pages.

**[English](#english)** · **[Français](#français)**

---

## English

### What it does
A small static web app built around your Last.fm data:

1. **Sign in** with your Last.fm username + a free API key (stays in your browser only).
2. **Export** your full scrobble history, top artists, top albums, or top tracks as **CSV, Excel, JSON, or PDF**.
3. **Re-import** any of those exports on the **Recap** page to get a visual summary — no need to re-fetch from Last.fm.

### Features
- 🔐 Login screen — username + API key, stored in `localStorage` only, never sent anywhere but Last.fm's own API.
- 📦 Four export formats: CSV, Excel (`.xlsx`), JSON, and PDF.
- 🎨 Two PDF styles:
  - **Simple** — a plain, fast table.
  - **Beautiful** — a branded report with cover stats, a podium with real photos (thinly framed, with a graceful monogram fallback), and a themed table.
- 🖼️ Photo lookups for the Beautiful PDF: Wikipedia first for artists, falling back to TheAudioDB; iTunes Search for album/track artwork. An "Include photos" toggle turns this off entirely if you'd rather skip it.
- 🔃 Ascending / descending sort toggle, applied before export.
- 📊 **Recap page** — drag & drop a previously exported file and get: Top 10, busiest day, averages, date range, plus monthly and day-of-week breakdown charts.
- 🌐 Bilingual UI (French / English), including translated PDF column headers.
- 📱 Responsive layout — tested down to small phone widths.
- 🚫 No backend, no analytics, no third-party storage — everything happens client-side.

### Project structure
| Path | What it's for |
|---|---|
| `index.html` | Login page (username + API key) |
| `download.html` | Export page — pick a dataset, a format, and download |
| `recap.html` | Import page — re-upload an export and see a summary |
| `css/style.css` | All styling (Material 3–inspired theme) |
| `js/i18n.js` | FR/EN UI strings + PDF column header translations |
| `js/auth.js` | Credential storage (`localStorage`) |
| `js/lastfm-api.js` | Last.fm API calls + pagination |
| `js/images.js` | Artist/album/track photo lookups, with graceful fallback |
| `js/export.js` | CSV / Excel / JSON builders + PDF dispatch |
| `js/pdf-export.js` | PDF rendering — Simple & Beautiful styles |
| `js/login.js` | Login page logic |
| `js/app.js` | Export page logic |
| `js/recap.js` | Recap page logic — file parsing + summary rendering |
| `assets/` | Drop your own `icon.png` here (see `assets/README.md`) |

### Getting started

**1. Get a free Last.fm API key**
Create one at [last.fm/api/account/create](https://www.last.fm/api/account/create) — you only need the "API key" field shown after.

**2. Add your icon (optional)**
See [`assets/README.md`](assets/README.md). Drop a square PNG in as `assets/icon.png` — it's already wired up as the favicon on all three pages.

**3. Deploy to GitHub Pages**
1. Push this repo to GitHub (keep the folder structure as-is).
2. Go to **Settings → Pages** → Source: `Deploy from a branch` → Branch: `main` / `(root)`.
3. Your site is live at `https://<your-username>.github.io/<repo>/` within a minute or two.

### How your data is handled
- Your Last.fm username, API key, and an optional images-API key live only in your browser's `localStorage` — nothing is sent to any server you don't already trust.
- Network calls go to: the Last.fm API (your data), and — only for the Beautiful PDF, only if "Include photos" is on — Wikipedia, TheAudioDB, and the iTunes Search API (public artwork lookups, no personal data sent).
- Exported files are generated and downloaded entirely client-side.

### Tech notes
- PDF generation: [jsPDF](https://github.com/parallax/jsPDF) + [jspdf-autotable](https://github.com/simonbengtsson/jsPDF-AutoTable) (loaded via CDN).
- Excel export/import: [SheetJS](https://sheetjs.com/) (loaded via CDN).
- No build step, no package manager, no framework — plain HTML/CSS/JS.

### License
No license specified yet. Add a `LICENSE` file if you plan on sharing this repo publicly.

---

## Français

### Ce que ça fait
Une petite application web statique autour de vos données Last.fm :

1. **Connexion** avec votre pseudo Last.fm + une clé API gratuite (reste uniquement dans votre navigateur).
2. **Export** de votre historique complet, top artistes, top albums ou top morceaux en **CSV, Excel, JSON ou PDF**.
3. **Réimport** de n'importe lequel de ces fichiers sur la page **Récap** pour obtenir un résumé visuel — sans avoir besoin de réinterroger Last.fm.

### Fonctionnalités
- 🔐 Écran de connexion — pseudo + clé API, stockés uniquement dans le `localStorage`, jamais envoyés ailleurs qu'à l'API de Last.fm elle-même.
- 📦 Quatre formats d'export : CSV, Excel (`.xlsx`), JSON et PDF.
- 🎨 Deux styles de PDF :
  - **Simple** — un tableau classique, rapide.
  - **Esthétique** — un rapport personnalisé avec statistiques de couverture, un podium avec de vraies photos (finement encadrées, avec repli en monogramme si besoin), et un tableau aux couleurs du thème.
- 🖼️ Recherche de photos pour le PDF esthétique : Wikipédia en priorité pour les artistes, repli sur TheAudioDB ; iTunes Search pour les pochettes d'albums/morceaux. Une case « Inclure les photos » permet de désactiver complètement cette recherche.
- 🔃 Bouton d'ordre croissant / décroissant, appliqué avant l'export.
- 📊 **Page Récap** — glissez-déposez un fichier déjà exporté et obtenez : Top 10, jour le plus actif, moyennes, période couverte, ainsi que des graphiques de répartition par mois et par jour de la semaine.
- 🌐 Interface bilingue (français / anglais), y compris les en-têtes de colonnes du PDF traduits.
- 📱 Mise en page responsive — testée jusqu'aux petits écrans de téléphone.
- 🚫 Aucun serveur, aucune analytique, aucun stockage tiers — tout se passe côté client.

### Structure du projet
| Fichier | À quoi il sert |
|---|---|
| `index.html` | Page de connexion (pseudo + clé API) |
| `download.html` | Page d'export — choix des données, du format, et téléchargement |
| `recap.html` | Page d'import — réimporter un export et voir un résumé |
| `css/style.css` | Tous les styles (thème inspiré de Material 3) |
| `js/i18n.js` | Textes FR/EN de l'interface + traduction des en-têtes du PDF |
| `js/auth.js` | Stockage des identifiants (`localStorage`) |
| `js/lastfm-api.js` | Appels à l'API Last.fm + pagination |
| `js/images.js` | Recherche de photos artistes/albums/morceaux, avec repli |
| `js/export.js` | Générateurs CSV / Excel / JSON + redirection vers le PDF |
| `js/pdf-export.js` | Génération du PDF — styles Simple et Esthétique |
| `js/login.js` | Logique de la page de connexion |
| `js/app.js` | Logique de la page d'export |
| `js/recap.js` | Logique de la page Récap — lecture du fichier + rendu du résumé |
| `assets/` | Déposez votre `icon.png` ici (voir `assets/README.md`) |

### Démarrage

**1. Obtenir une clé API Last.fm gratuite**
Créez-en une sur [last.fm/api/account/create](https://www.last.fm/api/account/create) — seul le champ « API key » affiché après création du compte est nécessaire.

**2. Ajouter votre icône (optionnel)**
Voir [`assets/README.md`](assets/README.md). Déposez un PNG carré en tant que `assets/icon.png` — c'est déjà branché comme favicon sur les trois pages.

**3. Déployer sur GitHub Pages**
1. Poussez ce dépôt sur GitHub (gardez la structure des dossiers).
2. Allez dans **Settings → Pages** → Source : `Deploy from a branch` → Branche : `main` / `(root)`.
3. Le site est en ligne sur `https://<votre-pseudo>.github.io/<repo>/` en une minute ou deux.

### Comment vos données sont traitées
- Votre pseudo Last.fm, votre clé API et une éventuelle clé d'API images vivent uniquement dans le `localStorage` de votre navigateur — rien n'est envoyé à un serveur autre que ceux indiqués ci-dessous.
- Les appels réseau vont vers : l'API Last.fm (vos données), et — uniquement pour le PDF esthétique, uniquement si « Inclure les photos » est activé — Wikipédia, TheAudioDB et l'API iTunes Search (recherches publiques d'images, aucune donnée personnelle envoyée).
- Les fichiers exportés sont générés et téléchargés entièrement côté client.

### Notes techniques
- Génération du PDF : [jsPDF](https://github.com/parallax/jsPDF) + [jspdf-autotable](https://github.com/simonbengtsson/jsPDF-AutoTable) (chargés via CDN).
- Export/import Excel : [SheetJS](https://sheetjs.com/) (chargé via CDN).
- Pas d'étape de build, pas de gestionnaire de paquets, pas de framework — du HTML/CSS/JS pur.

### Licence
Aucune licence définie pour l'instant. Ajoutez un fichier `LICENSE` si vous comptez partager ce dépôt publiquement.
