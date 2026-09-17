// Tiny i18n helper, no framework needed:
// - static text: put both versions on the element as data-fr="..." data-en="..."
//   and this script swaps textContent depending on the active language.
// - dynamic strings built from JS (music widget, github stats, download
//   modal...) call i18n.t('key') and re-render when i18n.onChange fires.
(function () {
  // dictionary for strings that get built dynamically in other scripts
  const STRINGS = {
    fr: {
      nowPlaying: 'Écoute en cours',
      ghFavorites: 'favoris',
      ghDownloads: 'téléchargements',
      ghLatestVersion: 'Dernière version',
      lightboxZoomIn: 'Clique pour zoomer',
      lightboxZoomOut: 'Clique pour dézoomer',
      dlTitle: 'Télécharger LastStats',
      dlChooseOs: "Choisissez votre système d'exploitation.",
      dlChooseArch: 'Quel type de processeur ?',
      dlAndroidNote: 'Les APK Android sont compilés par architecture pour rester légers. En cas de doute, choisissez « Universelle », elle fonctionne sur tous les appareils.',
      dlArchArm64: 'La grande majorité des téléphones récents (2018+)',
      dlArchArmv7: 'Anciens téléphones 32 bits',
      dlArchX86: 'Émulateurs et quelques tablettes/Chromebooks',
      dlArchUniversal: 'Toutes architectures, fichier plus lourd',
      dlBackOs: '← Changer de système',
      dlBackRetry: '← Retour',
      dlSearching: 'Recherche de la dernière version…',
      dlDownloadTitle: 'Téléchargement',
      dlNoAsset: 'Aucun fichier correspondant trouvé pour cette plateforme. Ouverture de la page des releases…',
      dlFetchError: 'Impossible de récupérer la dernière version. Ouverture de la page des releases…',
    },
    en: {
      nowPlaying: 'Now playing',
      ghFavorites: 'stars',
      ghDownloads: 'downloads',
      ghLatestVersion: 'Latest version',
      lightboxZoomIn: 'Click to zoom in',
      lightboxZoomOut: 'Click to zoom out',
      dlTitle: 'Download LastStats',
      dlChooseOs: 'Choose your operating system.',
      dlChooseArch: 'Which processor type?',
      dlAndroidNote: "Android APKs are built per architecture to keep the file size down. If unsure, pick \"Universal\", it works on every device.",
      dlArchArm64: 'The vast majority of recent phones (2018+)',
      dlArchArmv7: 'Older 32-bit phones',
      dlArchX86: 'Emulators and some tablets/Chromebooks',
      dlArchUniversal: 'All architectures, bigger file',
      dlBackOs: '← Change system',
      dlBackRetry: '← Back',
      dlSearching: 'Looking up the latest version…',
      dlDownloadTitle: 'Download',
      dlNoAsset: 'No matching file found for this platform. Opening the releases page…',
      dlFetchError: 'Could not fetch the latest version. Opening the releases page…',
    },
  };

  function detect() {
    const saved = localStorage.getItem('lang');
    if (saved === 'fr' || saved === 'en') return saved;
    return navigator.language && navigator.language.toLowerCase().startsWith('fr') ? 'fr' : 'en';
  }

  let lang = detect();
  const listeners = [];

  function applyStatic() {
    document.documentElement.lang = lang;

    document.querySelectorAll('[data-fr]').forEach((el) => {
      const fr = el.getAttribute('data-fr');
      const en = el.getAttribute('data-en');
      el.textContent = lang === 'fr' ? fr : (en !== null ? en : fr);
    });

    // aria-label / title variants for non-text elements (icon buttons, etc.)
    document.querySelectorAll('[data-fr-aria]').forEach((el) => {
      const fr = el.getAttribute('data-fr-aria');
      const en = el.getAttribute('data-en-aria');
      el.setAttribute('aria-label', lang === 'fr' ? fr : (en || fr));
    });

    document.querySelectorAll('.lang-toggle').forEach((btn) => {
      btn.textContent = lang === 'fr' ? 'EN' : 'FR';
      btn.setAttribute('aria-label', lang === 'fr' ? 'Switch to English' : 'Passer en français');
    });

    listeners.forEach((fn) => fn(lang));
  }

  window.i18n = {
    // legacy shape kept so any older code reading i18n.fr[key] still works
    fr: STRINGS.fr,
    en: STRINGS.en,
    get lang() {
      return lang;
    },
    t(key) {
      return (STRINGS[lang] && STRINGS[lang][key]) || key;
    },
    setLang(l) {
      if (l !== 'fr' && l !== 'en') return;
      lang = l;
      localStorage.setItem('lang', l);
      applyStatic();
    },
    toggle() {
      window.i18n.setLang(lang === 'fr' ? 'en' : 'fr');
    },
    onChange(fn) {
      listeners.push(fn);
    },
  };

  document.addEventListener('DOMContentLoaded', () => {
    applyStatic();
    document.querySelectorAll('.lang-toggle').forEach((btn) => {
      btn.addEventListener('click', () => window.i18n.toggle());
    });
  });
})();
