// theme with 3 modes: light / dark / auto (auto = follow system, live)
// click cycles light -> dark -> auto -> light. mode is persisted; only
// 'auto' keeps listening to the OS setting afterwards.
(function () {
  const STORAGE_KEY = 'theme-mode'; // 'light' | 'dark' | 'auto'
  const root = document.documentElement;
  const btn = document.getElementById('theme-toggle');
  const media = window.matchMedia('(prefers-color-scheme: dark)');

  const LABELS = {
    fr: { light: 'Thème clair (cliquer pour sombre)', dark: 'Thème sombre (cliquer pour auto)', auto: 'Thème auto (cliquer pour clair)' },
    en: { light: 'Light theme (click for dark)', dark: 'Dark theme (click for auto)', auto: 'Auto theme (click for light)' },
  };

  function resolvedFromMode(mode) {
    return mode === 'auto' ? (media.matches ? 'dark' : 'light') : mode;
  }

  function apply(mode) {
    root.setAttribute('data-theme', resolvedFromMode(mode));
    root.setAttribute('data-theme-mode', mode);
    if (btn) {
      const lang = (window.i18n && window.i18n.lang) || 'fr';
      const label = LABELS[lang][mode];
      btn.setAttribute('aria-label', label);
      btn.setAttribute('title', label);
    }
  }

  function getMode() {
    const saved = localStorage.getItem(STORAGE_KEY);
    return saved === 'light' || saved === 'dark' || saved === 'auto' ? saved : 'auto';
  }

  function setMode(mode) {
    localStorage.setItem(STORAGE_KEY, mode);
    apply(mode);
  }

  // OS changes only matter while we're in auto mode
  media.addEventListener('change', () => {
    if (getMode() === 'auto') apply('auto');
  });

  if (window.i18n) window.i18n.onChange(() => apply(getMode()));

  if (btn) {
    btn.addEventListener('click', () => {
      const next = { light: 'dark', dark: 'auto', auto: 'light' }[getMode()];
      setMode(next);
    });
  }

  apply(getMode());
})();
