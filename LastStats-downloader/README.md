# LastStat Downloader

A small, static site to download your Last.fm listening data (history, top artists, top albums, top tracks) as CSV, Excel (.xlsx), JSON or PDF. No backend — everything runs in your browser, and your API key never leaves your device.

## Files
```
index.html        login page (username + API key)
download.html      download page (pick dataset + format)
css/style.css      shared styles
js/i18n.js          FR/EN translations
js/auth.js          credential storage (localStorage)
js/lastfm-api.js    Last.fm API calls + pagination
js/export.js        CSV / Excel / JSON file builders + PDF dispatch
js/pdf-export.js    PDF builders: "Simple" (plain table) and "Beautiful" (branded report with cover stats)
js/login.js         login page logic
js/app.js           download page logic
```

## Get a Last.fm API key
Create one for free at https://www.last.fm/api/account/create — you only need the "API key" field shown after creating an account.

## Deploy on GitHub Pages
1. Push these files to a GitHub repo (keep the folder structure as-is).
2. Repo → **Settings → Pages** → Source: `Deploy from a branch` → Branch: `main` / `(root)`.
3. Your site appears at `https://<user>.github.io/<repo>/` after a minute.

---

## (FR) LastStat Downloader

Site statique pour télécharger vos données Last.fm (historique, top artistes, top albums, top morceaux) en CSV, Excel (.xlsx), JSON ou PDF (version simple ou version "esthétique" avec page de garde et statistiques). Aucun serveur — tout se passe dans votre navigateur, votre clé API ne quitte jamais votre appareil.

### Obtenir une clé API Last.fm
Créez-en une gratuitement sur https://www.last.fm/api/account/create — seul le champ « API key » affiché après création du compte est nécessaire.

### Déployer sur GitHub Pages
1. Poussez ces fichiers dans un dépôt GitHub (gardez la structure des dossiers).
2. Dépôt → **Settings → Pages** → Source : `Deploy from a branch` → Branche : `main` / `(root)`.
3. Le site sera disponible sur `https://<user>.github.io/<repo>/` après une minute.
