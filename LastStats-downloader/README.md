# LastStat Downloader

A small, static site to download your Last.fm listening data (history, top artists, top albums, top tracks) as CSV, Excel (.xlsx), JSON or PDF. No backend — everything runs in your browser, and your API key never leaves your device.

## Files
```
index.html        login page (username + API key)
download.html      download page (pick dataset + format)
css/style.css      shared styles
js/i18n.js          FR/EN translations + PDF column header translations
js/auth.js          credential storage (localStorage)
js/lastfm-api.js    Last.fm API calls + pagination
js/images.js         artist photo + album/track art lookups (with graceful fallback)
js/export.js        CSV / Excel / JSON file builders + PDF dispatch (track durations are formatted as m:ss)
js/pdf-export.js    PDF builders: "Simple" (plain table) and "Beautiful" (branded report with cover stats + photos)
js/login.js         login page logic
js/app.js           download page logic
```

## About the Beautiful PDF's photos
The Beautiful PDF shows real, thinly-framed pictures on its podium: artist photos via **Wikipedia** first (free, no key, reliable), falling back to **TheAudioDB** if Wikipedia has no image (public test key `123` works out of the box, rate-limited; paste your own Patreon key on the login page for a higher limit), and album/track artwork via the **iTunes Search API** (no key needed). If a picture can't be fetched for any reason, a colored monogram avatar is drawn instead — the PDF never breaks, it just looks slightly plainer for that item.

A **"Include photos"** checkbox appears on the download page once the "Beautiful" style is selected, to turn this lookup on or off entirely.

## Get a Last.fm API key
Create one for free at https://www.last.fm/api/account/create — you only need the "API key" field shown after creating an account.

## Deploy on GitHub Pages
1. Push these files to a GitHub repo (keep the folder structure as-is).
2. Repo → **Settings → Pages** → Source: `Deploy from a branch` → Branch: `main` / `(root)`.
3. Your site appears at `https://<user>.github.io/<repo>/` after a minute.

---

## (FR) LastStat Downloader

Site statique pour télécharger vos données Last.fm (historique, top artistes, top albums, top morceaux) en CSV, Excel (.xlsx), JSON ou PDF (version simple ou version "esthétique" avec page de garde, statistiques et photos). Aucun serveur — tout se passe dans votre navigateur, votre clé API ne quitte jamais votre appareil.

### Photos dans le PDF esthétique
Le podium du PDF esthétique affiche de vraies photos, encadrées d'un petit contour : les artistes via **Wikipédia** en priorité (gratuit, sans clé, fiable), avec repli sur **TheAudioDB** si Wikipédia n'a pas d'image (clé publique de test `123` fonctionnelle d'office, avec limite de débit — collez votre propre clé Patreon sur la page de connexion pour une limite plus élevée). Les pochettes d'albums/morceaux passent par l'**API iTunes Search** (gratuite, sans clé). Si une photo ne peut pas être récupérée, un avatar coloré avec une initiale est dessiné à la place — le PDF ne casse jamais, il est juste un peu plus sobre pour cet élément.

Une case à cocher **« Inclure les photos »** apparaît sur la page de téléchargement quand le style « Esthétique » est choisi, pour activer/désactiver complètement ces recherches d'images.

### Obtenir une clé API Last.fm
Créez-en une gratuitement sur https://www.last.fm/api/account/create — seul le champ « API key » affiché après création du compte est nécessaire.

### Déployer sur GitHub Pages
1. Poussez ces fichiers dans un dépôt GitHub (gardez la structure des dossiers).
2. Dépôt → **Settings → Pages** → Source : `Deploy from a branch` → Branche : `main` / `(root)`.
3. Le site sera disponible sur `https://<user>.github.io/<repo>/` après une minute.
