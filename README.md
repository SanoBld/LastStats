# LastStats

> **Vos statistiques musicales Last.fm, réinventées.**  
> Une PWA minimaliste et puissante pour explorer, analyser et partager votre historique d'écoute.

---

## Table des matières

1. [Description](#description)
2. [Démo](#démo)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Technologies](#technologies)
6. [Fonctionnalités](#fonctionnalités)
7. [Architecture](#architecture)
8. [Contribuer](#contribuer)
9. [Licence](#licence)

---

## Description

LastStats est une application web progressive (PWA) qui se connecte à l'API publique de [Last.fm](https://www.last.fm/) pour transformer votre historique d'écoute en tableaux de bord interactifs, graphiques avancés et cartes exportables pour les réseaux sociaux.

Conçu avec le principe **zero framework** — JavaScript pur ES6+, CSS personnalisé et APIs natives du navigateur — LastStats est rapide, léger et entièrement hors-ligne après le premier chargement.

---

## Démo

Pour lancer l'application localement :

```bash
# 1. Cloner le dépôt
git clone https://github.com/votre-utilisateur/laststats.git
cd laststats

# 2. Serveur local (requis pour le Service Worker)
npx serve .
# ou
python3 -m http.server 8080
```

Puis ouvrir `http://localhost:8080` dans votre navigateur.

> ⚠️ Un **serveur HTTP** est obligatoire pour que le Service Worker et la PWA fonctionnent correctement. L'ouverture directe en `file://` n'est pas supportée.

---

## Installation

### Prérequis

- Navigateur moderne (Chrome 111+, Firefox 115+, Safari 16.4+)
- Compte [Last.fm](https://www.last.fm/) actif
- Clé API Last.fm gratuite (voir ci-dessous)

### Obtenir une clé API Last.fm

1. Aller sur [last.fm/api/account/create](https://www.last.fm/api/account/create)
2. Remplir le formulaire (nom de l'application : `LastStats`, URL : `localhost`)
3. Copier la clé API générée (32 caractères hexadécimaux)

### Déploiement sur GitHub Pages

```bash
# Pousser le dossier sur la branche main
git push origin main

# Activer GitHub Pages dans Settings > Pages > Source: main /root
```

L'application sera disponible sur `https://votre-utilisateur.github.io/laststats/`.

---

## Configuration

Au premier lancement, renseignez :

| Champ | Description |
|-------|-------------|
| **Nom d'utilisateur** | Votre identifiant Last.fm |
| **Clé API** | Clé obtenue sur last.fm/api (32 caractères) |
| **Se souvenir de moi** | Persiste les identifiants dans `localStorage` |

Ces paramètres sont également modifiables à tout moment dans la section **Paramètres** de l'application.

---

## Technologies

| Technologie | Version | Usage |
|-------------|---------|-------|
| **Vanilla JS** | ES6+ | Logique applicative, modules, async/await |
| **CSS Variables** | — | Design System Material You v3 |
| **Chart.js** | 4.x | Graphiques bar, line, doughnut, radar, treemap |
| **D3.js** | 7.x | Sankey, Sunburst, visualisations avancées |
| **html2canvas** | 1.x | Export des cartes Wrapped en PNG |
| **ColorThief** | 2.x | Extraction de couleur dynamique depuis les pochettes |
| **Last.fm API** | 2.0 | Source de données (REST JSON, sans OAuth) |
| **Service Worker** | — | Mise en cache, mode hors-ligne |
| **Web App Manifest** | — | Installation PWA, icônes, thème |
| **View Transitions API** | — | Animations fluides entre sections |
| **IntersectionObserver** | — | Infinite scroll Top Artistes / Albums |
| **Web Share API** | — | Partage natif Now Playing |

---

## Fonctionnalités

### 🎵 Dashboard

- **Statistiques globales** : scrobbles totaux, artistes, albums, titres distincts, date d'inscription, dernier scrobble
- **Activité mensuelle** : graphique en barres par mois pour l'année sélectionnée
- **Top 5 Artistes** : donut chart avec légende interactive
- **Comparaison de périodes** : compare deux périodes au choix (7 jours, 1 mois, 3 mois…) avec indicateurs +/− en pourcentage
- **Widget Now Playing** : titre en cours avec pulsation verte, boutons Spotify/YouTube, bouton **Partager** (Web Share API ou copie presse-papiers)

### 🏆 Classements

- **Top Artistes** : grille infinie avec images récupérées via `artist.getTopAlbums`, clic pour ouvrir la **Modale Artiste**
- **Top Albums** : grille infinie avec pochettes
- **Top Titres** : liste avec **3 modes d'affichage** (liste / grille avec pochettes / compact), icône note sur chaque titre
- **Infinite Scroll** : pagination automatique via `IntersectionObserver`, chargement à la volée sans bouton

### 🎤 Modale Artiste

Au clic sur une carte artiste :
- Photo bien cadrée (`object-fit: cover`, `object-position: center top`)
- Biographie via `artist.getInfo` avec troncature + bouton « Lire la suite »
- Statistiques : auditeurs globaux, écoutes globales, écoutes utilisateur
- Tags de genre
- Top 5 titres **de l'artiste** (via `artist.getTopTracks`)
- Albums populaires en grille
- Liens vers Last.fm, Spotify, YouTube

### 📈 Graphiques

- **Activité mensuelle** par année avec sélecteur
- **Évolution cumulative** depuis l'inscription
- **Répartition** artistes et albums (donut)
- **Heatmap horaire** (24 colonnes, intensité par couleur)
- **Graphiques horaire et par jour de la semaine** (après chargement de l'historique)

### 🔮 Visualisations Avancées

- **Radar** : présence des genres musicaux (10 catégories)
- **Sunburst D3** : hiérarchie cliquable Genres → Artistes, breadcrumb de navigation
- **Treemap** : top 100 artistes proportionnel aux écoutes
- **Sankey** : flux de transitions entre artistes en session

### 🎼 Profil Musical

- Renommage de « Analyse de la Lourdeur » en **Profil Musical**
- Graphique linéaire montrant l'évolution des **5 tags dominants** sur les 6 derniers mois

### 📅 Wrapped

- Sélecteur d'année (depuis l'inscription)
- Podium Artiste / Titre / Album de l'année
- Stats annuelles : scrobbles, artistes, mois record
- Export **Story Mini 9:16** (360×640 px) pour Instagram/TikTok
- Export **Carte Complète** (680×860 px) avec podium et mini-chart
- Structure HTML flux (corrige les bugs de placement html2canvas)

### 🏅 Succès (Badges)

- 9 badges dans 5 catégories : Noctambule, Exploration, Fidélité, Volume, Diversité
- Paliers Bronze → Argent → Or → Diamant → Élite (seuils exponentiels)
- Système XP et niveau (1–8) avec titre
- **Persistance** dans `localStorage` par nom d'utilisateur
- Restauration automatique du compteur dans la nav au démarrage

### 🌑 Mainstream vs Obscur

- Score d'obscurité (0–100) pour vos top 30 artistes
- Jauge SVG animée
- Classement par score ou écoutes
- Badges : Mainstream / Culte / Obscur

### ⚙️ Paramètres

- Modification du nom d'utilisateur et de la clé API sans reconnexion
- Sélecteur de thème : Clair / Auto / Sombre
- Sélecteur d'accent : Violet / Bleu / Vert / Rouge / Orange / Dynamique (ColorThief)
- **Sélecteur de langue** : 🇫🇷 Français / 🇬🇧 English (i18n prêt)
- Export des données : JSON et CSV
- Vider le cache
- Bouton d'installation PWA

### 📊 Stats Avancées

- Nombre d'Eddington
- Streak record et streak actuelle (jours consécutifs)
- One-Hit Wonders (artistes écoutés 1 à 3 fois)
- Chargement de l'historique complet avec barre de progression

---

## Architecture

```
laststats/
├── index.html          # Structure HTML unique (SPA)
├── style.css           # Design System Material You v3 + addons v5
├── script.js           # Logique applicative complète (vanilla JS)
├── sw.js               # Service Worker v5 (cache-first / network-first)
├── manifest.json       # PWA manifest (icônes, thème, shortcuts)
├── icons/              # Icônes PWA (32, 152, 180, 192, 512 px)
└── README.md           # Ce fichier
```

### Modules JS (dans `script.js`)

| Module | Rôle |
|--------|------|
| `Cache` | Lecture/écriture localStorage avec TTL (30 min) |
| `API` | Appels Last.fm avec retry et cache intégré |
| `BadgeEngine` | Calcul et rendu des succès, persistance |
| `LANGUAGES` | Objet i18n FR/EN, fonction `t(key)` |
| Infinite Scroll | `IntersectionObserver` sur sentinelles |
| View Transitions | `document.startViewTransition()` avec fallback |

---

## Contribuer

Les contributions sont bienvenues.

```bash
# Fork + clone
git checkout -b feature/ma-fonctionnalite

# Tester localement
npx serve .

# Pull Request
git push origin feature/ma-fonctionnalite
```

**Règles** :
- Vanilla JS uniquement (pas de framework)
- Respecter les variables CSS existantes (`--accent`, `--bg-card`, etc.)
- Commenter les fonctions avec JSDoc minimal
- Tester sur Chrome, Firefox et Safari mobile

---

## Licence

MIT — Libre d'utilisation, de modification et de distribution.

---

<p align="center">
  Fait avec ♥ et beaucoup de scrobbles.<br>
  <a href="https://www.last.fm/">Last.fm API</a> · 
  <a href="https://www.chartjs.org/">Chart.js</a> · 
  <a href="https://d3js.org/">D3.js</a>
</p>
