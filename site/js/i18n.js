// i18n helper. Dictionaries live in /i18n/<lang>.js (window.I18N.<lang>).
// - static text: data-i18n="key" (textContent) or data-i18n-html="key" (trusted HTML, for links)
// - aria labels: data-i18n-aria="key"
// - scripts: i18n.t('key'), re-render with i18n.onChange(fn)
(function () {
  const DICT = window.I18N || {};
  const LANGS = Object.keys(DICT).sort((a, b) => (a === 'fr' ? -1 : b === 'fr' ? 1 : a.localeCompare(b)));
  const FALLBACK = 'fr';

  function lookup(lang, key) {
    const d = DICT[lang];
    if (d && d[key] !== undefined) return d[key];
    const f = DICT[FALLBACK];
    return f && f[key] !== undefined ? f[key] : null;
  }

  function detect() {
    const saved = localStorage.getItem('lang');
    if (saved && DICT[saved]) return saved;
    const nav = (navigator.language || '').slice(0, 2).toLowerCase();
    return DICT[nav] ? nav : 'en' in DICT ? 'en' : FALLBACK;
  }

  let lang = detect();
  const listeners = [];

  function nextLang() {
    return LANGS[(LANGS.indexOf(lang) + 1) % LANGS.length];
  }

  function applyStatic() {
    document.documentElement.lang = lang;

    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const v = lookup(lang, el.getAttribute('data-i18n'));
      if (v !== null) el.textContent = v;
    });
    document.querySelectorAll('[data-i18n-html]').forEach((el) => {
      const v = lookup(lang, el.getAttribute('data-i18n-html'));
      if (v !== null) el.innerHTML = v;
    });
    document.querySelectorAll('[data-i18n-aria]').forEach((el) => {
      const v = lookup(lang, el.getAttribute('data-i18n-aria'));
      if (v !== null) el.setAttribute('aria-label', v);
    });

    const next = nextLang();
    const meta = (DICT[next] && DICT[next]._meta) || { short: next.toUpperCase(), name: next };
    document.querySelectorAll('.lang-toggle').forEach((btn) => {
      btn.textContent = meta.short;
      btn.setAttribute('aria-label', meta.name);
    });

    listeners.forEach((fn) => fn(lang));
  }

  window.i18n = {
    get lang() {
      return lang;
    },
    get langs() {
      return LANGS.slice();
    },
    t(key) {
      const v = lookup(lang, key);
      return v !== null ? v : key;
    },
    setLang(l) {
      if (!DICT[l]) return;
      lang = l;
      localStorage.setItem('lang', l);
      applyStatic();
    },
    toggle() {
      window.i18n.setLang(nextLang());
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
