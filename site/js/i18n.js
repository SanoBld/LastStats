// i18n helper. Dictionaries live in /i18n/<lang>.js (window.I18N.<lang>), one file per language.
// - static text: data-i18n="key" (textContent) or data-i18n-html="key" (trusted HTML, for links)
// - aria labels: data-i18n-aria="key"
// - scripts: i18n.t('key'), re-render with i18n.onChange(fn)
// Language: saved choice, else the browser language (automatic), else English.
// All fixed texts are translated locally (one file per language); missing keys fall back to
// English, then French. Only changing content (release notes, commit messages) is
// machine-translated through Google Translate (see translate / watchNotes below).
(function () {
  const DICT = window.I18N || {};
  const ORDER = ['fr', 'en', 'de', 'es', 'it', 'pt', 'ru', 'ja', 'zh', 'ar'];
  const LANGS = Object.keys(DICT).sort((a, b) => {
    const ia = ORDER.indexOf(a), ib = ORDER.indexOf(b);
    return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib) || a.localeCompare(b);
  });
  const CHAIN = ['en', 'fr'];
  const RTL = ['ar', 'he', 'fa', 'ur'];

  function lookup(lang, key) {
    const d = DICT[lang];
    if (d && d[key] !== undefined) return d[key];
    for (const f of CHAIN) if (DICT[f] && DICT[f][key] !== undefined) return DICT[f][key];
    return null;
  }

  function detect() {
    try {
      const saved = localStorage.getItem('lang');
      if (saved && DICT[saved]) return saved;
    } catch (e) {}
    const prefs = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || ''];
    for (const p of prefs) {
      const code = String(p).slice(0, 2).toLowerCase();
      if (DICT[code]) return code;
    }
    return DICT.en ? 'en' : LANGS[0];
  }

  let lang = detect();
  const listeners = [];

  // ---- machine translation (free Google endpoint, no key), cached ----
  const cache = new Map();
  try { Object.entries(JSON.parse(sessionStorage.getItem('trcache') || '{}')).forEach(([k, v]) => cache.set(k, v)); } catch (e) {}
  function saveCache() {
    try { sessionStorage.setItem('trcache', JSON.stringify(Object.fromEntries([...cache].slice(-400)))); } catch (e) {}
  }
  function translate(text, to) {
    const key = to + '|' + text;
    if (cache.has(key)) return Promise.resolve(cache.get(key));
    const url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&dt=t&tl=' +
      encodeURIComponent(to === 'zh' ? 'zh-CN' : to) + '&q=' + encodeURIComponent(text);
    return fetch(url)
      .then((r) => { if (!r.ok) throw new Error('tr ' + r.status); return r.json(); })
      .then((j) => {
        const out = (j[0] || []).map((s) => s[0]).join('');
        cache.set(key, out || text);
        saveCache();
        return out || text;
      })
      .catch(() => text);
  }


  // ---- dynamic content (release notes): translated on demand, on by default ----
  const dyn = { on: true };
  try { dyn.on = localStorage.getItem('cmTr') !== '0'; } catch (e) {}
  const orig = new WeakMap();
  const roots = new Set();
  function textNodes(root) {
    const out = [];
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: (n) => (/\p{L}{2,}/u.test(n.nodeValue) && !n.parentElement.closest('code,pre') ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT),
    });
    while (w.nextNode()) out.push(w.currentNode);
    return out;
  }
  function restore(root) {
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    while (w.nextNode()) if (orig.has(w.currentNode)) w.currentNode.nodeValue = orig.get(w.currentNode);
  }
  function trRoot(root) {
    if (!dyn.on) return;
    const to = lang;
    const queue = textNodes(root);
    queue.forEach((n) => { if (!orig.has(n)) orig.set(n, n.nodeValue); });
    const work = () => {
      const n = queue.shift();
      if (!n) return;
      const src = orig.get(n);
      const lead = src.match(/^\s*/)[0], tail = src.match(/\s*$/)[0];
      translate(src.trim(), to).then((out) => {
        if (dyn.on && lang === to && n.isConnected) n.nodeValue = lead + out + tail;
        work();
      });
    };
    for (let i = 0; i < 4; i++) work();
  }
  const seenIO = 'IntersectionObserver' in window
    ? new IntersectionObserver((es) => es.forEach((e) => {
        if (e.isIntersecting) { seenIO.unobserve(e.target); e.target.__seen = true; trRoot(e.target); }
      }), { rootMargin: '300px' })
    : null;
  function watchNotes(root) {
    roots.add(root);
    if (seenIO) seenIO.observe(root); else { root.__seen = true; trRoot(root); }
  }
  function refreshRoots() {
    roots.forEach((r) => {
      if (!r.isConnected) { roots.delete(r); return; }
      restore(r);
      if (r.__seen) trRoot(r);
    });
  }

  // ---- language menu (Android-style dropdown) ----
  function buildMenu(btn) {
    if (btn.parentElement && btn.parentElement.classList.contains('lang-wrap')) return;
    const wrap = document.createElement('div');
    wrap.className = 'lang-wrap';
    btn.parentNode.insertBefore(wrap, btn);
    wrap.appendChild(btn);
    const menu = document.createElement('div');
    menu.className = 'lang-menu';
    menu.setAttribute('role', 'menu');
    wrap.appendChild(menu);
    btn.setAttribute('aria-haspopup', 'menu');
    btn.setAttribute('aria-expanded', 'false');
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const open = !wrap.classList.contains('is-open');
      closeMenus();
      if (open) { wrap.classList.add('is-open'); btn.setAttribute('aria-expanded', 'true'); }
    });
  }
  function closeMenus() {
    document.querySelectorAll('.lang-wrap.is-open').forEach((w) => {
      w.classList.remove('is-open');
      const b = w.querySelector('.lang-toggle');
      if (b) b.setAttribute('aria-expanded', 'false');
    });
  }
  function fillMenus() {
    let saved = null;
    try { saved = localStorage.getItem('lang'); } catch (e) {}
    document.querySelectorAll('.lang-menu').forEach((menu) => {
      menu.innerHTML = '';
      const item = (code, label, tag, active) => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'lang-item md-ripple' + (active ? ' is-active' : '');
        b.setAttribute('role', 'menuitemradio');
        b.setAttribute('aria-checked', active ? 'true' : 'false');
        b.innerHTML = '<span class="lang-item-name"></span><span class="lang-item-tag"></span>';
        b.firstChild.textContent = label;
        b.lastChild.textContent = tag;
        b.addEventListener('click', () => { closeMenus(); code ? window.i18n.setLang(code) : window.i18n.auto(); });
        menu.appendChild(b);
      };
      item(null, (lookup(lang, 'langAuto') || 'Auto'), 'AUTO', !saved);
      LANGS.forEach((l) => {
        const m = DICT[l]._meta || { short: l.toUpperCase(), name: l };
        item(l, m.name, m.short, !!saved && l === lang);
      });
    });
  }

  function applyStatic() {
    document.documentElement.lang = lang;
    document.documentElement.dir = RTL.includes(lang) ? 'rtl' : 'ltr';

    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const v = lookup(lang, el.getAttribute('data-i18n'));
      if (v === null) return;
      el.textContent = v;
    });
    document.querySelectorAll('[data-i18n-html]').forEach((el) => {
      const v = lookup(lang, el.getAttribute('data-i18n-html'));
      if (v !== null) el.innerHTML = v;
    });
    document.querySelectorAll('[data-i18n-aria]').forEach((el) => {
      const v = lookup(lang, el.getAttribute('data-i18n-aria'));
      if (v !== null) el.setAttribute('aria-label', v);
    });

    const meta = (DICT[lang] && DICT[lang]._meta) || { short: lang.toUpperCase(), name: lang };
    document.querySelectorAll('.lang-toggle').forEach((btn) => {
      btn.textContent = meta.short;
      btn.setAttribute('aria-label', meta.name);
    });
    fillMenus();
    refreshRoots();
    listeners.forEach((fn) => fn(lang));
  }

  window.i18n = {
    get lang() { return lang; },
    get langs() { return LANGS.slice(); },
    t(key) { const v = lookup(lang, key); return v !== null ? v : key; },
    translate,
    watchNotes,
    get dynTr() { return dyn.on; },
    setDynTr(on) {
      dyn.on = !!on;
      try { localStorage.setItem('cmTr', on ? '1' : '0'); } catch (e) {}
      refreshRoots();
    },
    setLang(l) {
      if (!DICT[l]) return;
      lang = l;
      try { localStorage.setItem('lang', l); } catch (e) {}
      applyStatic();
    },
    auto() {
      try { localStorage.removeItem('lang'); } catch (e) {}
      lang = detect();
      applyStatic();
    },
    onChange(fn) { listeners.push(fn); },
  };

  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.lang-toggle').forEach(buildMenu);
    applyStatic();
    document.addEventListener('click', closeMenus);
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeMenus(); });
  });
})();
