'use strict';
// Translation strings. Keep keys identical between fr and en.
const I18N = {
  fr: {
    app_name: 'LastStat Downloader',
    login_title: 'Connexion',
    login_sub: 'Entrez votre pseudo Last.fm et votre clé API pour continuer.',
    label_username: 'Pseudo Last.fm',
    label_apikey: 'Clé API Last.fm',
    placeholder_username: 'ex : musiclover42',
    placeholder_apikey: 'Votre clé API (32 caractères)',
    help_apikey: 'Pas de clé ? Créez-en une gratuitement sur last.fm/api',
    label_imageskey: 'Clé API images (optionnel)',
    placeholder_imageskey: 'Laissez vide pour utiliser la clé publique',
    help_imageskey: 'Améliore la fiabilité des photos d\u2019artistes dans le PDF esthétique — theaudiodb.com',
    btn_connect: 'Se connecter',
    btn_connecting: 'Connexion…',
    err_required: 'Pseudo et clé API requis (32 caractères min).',
    err_invalid: 'Pseudo ou clé API invalide.',

    nav_logout: 'Déconnexion',
    hello: 'Connecté en tant que',
    section_data: 'Données à télécharger',
    section_format: 'Format de fichier',
    fmt_csv: 'CSV',
    fmt_xlsx: 'Excel',
    fmt_json: 'JSON',
    fmt_pdf: 'PDF',
    section_pdf_style: 'Style du PDF',
    pdf_style_simple: 'Simple',
    pdf_style_pretty: 'Esthétique',
    pdf_include_images: 'Inclure les photos (artistes/albums)',
    pdf_total_plays: 'Écoutes totales',
    pdf_unique_artists: 'Artistes uniques',
    pdf_date_range: 'Période',
    pdf_plays: 'écoutes',
    pdf_items: 'éléments',
    card_history: 'Historique complet',
    card_history_desc: 'Tous vos morceaux écoutés (scrobbles)',
    card_artists: 'Top artistes',
    card_artists_desc: 'Classement complet de vos artistes',
    card_albums: 'Top albums',
    card_albums_desc: 'Classement complet de vos albums',
    card_tracks: 'Top morceaux',
    card_tracks_desc: 'Classement complet de vos morceaux',
    btn_download: 'Télécharger',
    btn_download_all: 'Tout télécharger',
    progress_title: 'Téléchargement…',
    toast_done: 'Téléchargement terminé',
    toast_error: 'Erreur pendant le téléchargement',
    footer_note: 'Vos données restent sur votre appareil — rien n\u2019est envoyé à un serveur tiers.',
  },
  en: {
    app_name: 'LastStat Downloader',
    login_title: 'Sign in',
    login_sub: 'Enter your Last.fm username and API key to continue.',
    label_username: 'Last.fm username',
    label_apikey: 'Last.fm API key',
    placeholder_username: 'e.g. musiclover42',
    placeholder_apikey: 'Your API key (32 characters)',
    help_apikey: 'No key? Get one for free at last.fm/api',
    label_imageskey: 'Images API key (optional)',
    placeholder_imageskey: 'Leave empty to use the public key',
    help_imageskey: 'Improves reliability of artist photos in the Beautiful PDF — theaudiodb.com',
    btn_connect: 'Sign in',
    btn_connecting: 'Signing in…',
    err_required: 'Username and API key are required (min 32 chars).',
    err_invalid: 'Invalid username or API key.',

    nav_logout: 'Sign out',
    hello: 'Signed in as',
    section_data: 'Data to download',
    section_format: 'File format',
    fmt_csv: 'CSV',
    fmt_xlsx: 'Excel',
    fmt_json: 'JSON',
    fmt_pdf: 'PDF',
    section_pdf_style: 'PDF style',
    pdf_style_simple: 'Simple',
    pdf_style_pretty: 'Beautiful',
    pdf_include_images: 'Include photos (artists/albums)',
    pdf_total_plays: 'Total plays',
    pdf_unique_artists: 'Unique artists',
    pdf_date_range: 'Date range',
    pdf_plays: 'plays',
    pdf_items: 'items',
    card_history: 'Full history',
    card_history_desc: 'Every track you have scrobbled',
    card_artists: 'Top artists',
    card_artists_desc: 'Your full artist ranking',
    card_albums: 'Top albums',
    card_albums_desc: 'Your full album ranking',
    card_tracks: 'Top tracks',
    card_tracks_desc: 'Your full track ranking',
    btn_download: 'Download',
    btn_download_all: 'Download all',
    progress_title: 'Downloading…',
    toast_done: 'Download complete',
    toast_error: 'Download failed',
    footer_note: 'Your data stays on your device — nothing is sent to a third-party server.',
  },
};

// Active language, saved across visits
let LANG = localStorage.getItem('lsd_lang');
if (!LANG) LANG = (navigator.language || '').startsWith('fr') ? 'fr' : 'en';
if (!I18N[LANG]) LANG = 'en';

function t(key) { return I18N[LANG][key] || key; }

// Push translations into the DOM ([data-i18n] = text, [data-i18n-ph] = placeholder)
function applyI18n() {
  document.documentElement.lang = LANG;
  document.querySelectorAll('[data-i18n]').forEach(el => { el.textContent = t(el.dataset.i18n); });
  document.querySelectorAll('[data-i18n-ph]').forEach(el => { el.placeholder = t(el.dataset.i18nPh); });
  document.querySelectorAll('.lang-btn').forEach(b => { b.classList.toggle('is-active', b.dataset.lang === LANG); });
}

function setLang(lang) {
  LANG = lang;
  localStorage.setItem('lsd_lang', lang);
  applyI18n();
}

document.addEventListener('DOMContentLoaded', applyI18n);
