// Random Material 3 palette on every page load.
// Same structure as the app (tonal roles, same lightness/saturation steps as
// css/style.css, which is built from a teal-blue seed) but the hue changes at
// each refresh. To keep a fixed color family, e.g. blues only:
//   const hue = 190 + Math.random() * 60;
(function () {
  const KEY = 'accent-hue';          // saved on this browser (localStorage)
  const SKEY = 'accent-hue-session'; // chosen but not saved: kept for this tab only
  const rnd = () => Math.floor(Math.random() * 360);
  const read = (st, k) => { try { const v = parseInt(st.getItem(k), 10); return v >= 0 && v <= 360 ? v : null; } catch (e) { return null; } };
  const savedHue = read(localStorage, KEY);
  let hue = savedHue !== null ? savedHue : (read(sessionStorage, SKEY) !== null ? read(sessionStorage, SKEY) : rnd());
  const c = (h, s, l) => `hsl(${Math.round(h)}, ${s}%, ${l}%)`;
  const st = document.createElement('style');
  document.head.appendChild(st);

  function apply(hue) {
  const h2 = (hue + 60) % 360; // tertiary hue, like the app (shifted hue)

  const light = {
    'primary': c(hue, 60, 30), 'on-primary': '#FFFFFF',
    'primary-container': c(hue, 100, 87), 'on-primary-container': c(hue, 100, 10),
    'secondary': c(hue, 18, 35), 'on-secondary': '#FFFFFF',
    'secondary-container': c(hue, 35, 87), 'on-secondary-container': c(hue, 45, 10),
    'tertiary': c(h2, 18, 42), 'on-tertiary': '#FFFFFF',
    'tertiary-container': c(h2, 100, 93), 'on-tertiary-container': c(h2, 40, 16),
    'background': c(hue, 30, 97), 'on-background': c(hue, 12, 10),
    'on-surface': c(hue, 12, 10), 'on-surface-variant': c(hue, 10, 27),
    'outline-variant': c(hue, 12, 78),
    'surface-container-low': c(hue, 25, 95), 'surface-container': c(hue, 22, 93),
    'surface-container-high': c(hue, 20, 91), 'surface-container-highest': c(hue, 15, 89),
  };
  const dark = {
    'primary': c(hue, 70, 75), 'on-primary': c(hue, 100, 15),
    'primary-container': c(hue, 100, 19), 'on-primary-container': c(hue, 100, 87),
    'secondary': c(hue, 25, 76), 'on-secondary': c(hue, 30, 18),
    'secondary-container': c(hue, 22, 25), 'on-secondary-container': c(hue, 35, 87),
    'tertiary': c(h2, 50, 82), 'on-tertiary': c(h2, 30, 22),
    'tertiary-container': c(h2, 20, 30), 'on-tertiary-container': c(h2, 100, 93),
    'background': c(hue, 22, 7), 'on-background': c(hue, 10, 88),
    'on-surface': c(hue, 10, 88), 'on-surface-variant': c(hue, 10, 77),
    'outline-variant': c(hue, 10, 27),
    'surface-container-low': c(hue, 15, 10), 'surface-container': c(hue, 15, 12),
    'surface-container-high': c(hue, 12, 15), 'surface-container-highest': c(hue, 10, 19),
  };
  const block = (o) => Object.keys(o).map((k) => `--md-${k}:${o[k]}`).join(';');

  // higher specificity than style.css, whatever the load order
  st.textContent = `html:root{${block(light)}}html[data-theme="dark"]{${block(dark)}}`;
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', light.primary);
  }
  apply(hue);

  // ---------- color picker (built once the nav exists) ----------
  const T = {};
  const t = (k, fb) => (window.i18n && window.i18n.t(k) !== k ? window.i18n.t(k) : fb);

  function build() {
    const toggles = document.querySelector('.nav-toggles');
    if (!toggles) return;
    // help button moves to the right cluster, first position
    const help = document.querySelector('.nav > .nav-logo');
    if (help) toggles.insertBefore(help, toggles.firstChild);

    const wrap = document.createElement('div');
    wrap.className = 'color-wrap';
    wrap.innerHTML =
      '<button type="button" class="theme-toggle color-toggle md-ripple" aria-haspopup="dialog" aria-expanded="false">' +
        '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a9 9 0 1 0 0 18c1.1 0 1.8-.8 1.8-1.7 0-.5-.2-.9-.5-1.2-.3-.3-.5-.7-.5-1.2 0-.9.8-1.7 1.7-1.7H16a5 5 0 0 0 5-5c0-3.9-4-7.2-9-7.2z"/><circle cx="7.5" cy="11" r="1" fill="currentColor"/><circle cx="10.5" cy="7" r="1" fill="currentColor"/><circle cx="15" cy="7.5" r="1" fill="currentColor"/></svg>' +
      '</button>' +
      '<div class="color-menu" role="dialog">' +
        '<input class="color-range" type="range" min="0" max="360" step="1">' +
        '<div class="color-swatches"></div>' +
        '<label class="color-save"><input type="checkbox"><span class="color-save-label"></span></label>' +
        '<button type="button" class="color-random md-ripple"></button>' +
      '</div>';
    toggles.insertBefore(wrap, toggles.querySelector('.lang-wrap, .lang-toggle'));

    const btn = wrap.querySelector('.color-toggle');
    const range = wrap.querySelector('.color-range');
    const sw = wrap.querySelector('.color-swatches');
    const chk = wrap.querySelector('input[type=checkbox]');
    const rand = wrap.querySelector('.color-random');
    range.value = hue;
    chk.checked = read(localStorage, KEY) !== null;

    [0, 28, 52, 140, 175, 197, 230, 265, 320].forEach((h) => {
      const b = document.createElement('button');
      b.type = 'button'; b.className = 'color-sw'; b.dataset.h = h;
      b.style.background = c(h, 60, 45);
      b.addEventListener('click', () => set(h));
      sw.appendChild(b);
    });

    function marks() {
      sw.querySelectorAll('.color-sw').forEach((b) => b.classList.toggle('is-active', +b.dataset.h === hue));
      range.style.setProperty('--thumb', c(hue, 60, 45));
    }
    function persist() {
      try {
        if (chk.checked) { localStorage.setItem(KEY, hue); }
        else { localStorage.removeItem(KEY); }
        sessionStorage.setItem(SKEY, hue);
      } catch (e) {}
    }
    function set(h) { hue = +h; range.value = hue; apply(hue); persist(); marks(); }
    function labels() {
      btn.setAttribute('aria-label', t('color.pick', 'Color')); btn.title = t('color.pick', 'Color');
      wrap.querySelector('.color-save-label').textContent = t('color.save', 'Remember on this browser');
      rand.textContent = t('color.random', 'Random');
    }

    range.addEventListener('input', () => set(range.value));
    chk.addEventListener('change', persist);
    rand.addEventListener('click', () => { try { sessionStorage.removeItem(SKEY); } catch (e) {} set(rnd()); });
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const open = !wrap.classList.contains('is-open');
      document.querySelectorAll('.lang-wrap.is-open').forEach((w) => w.classList.remove('is-open'));
      wrap.classList.toggle('is-open', open);
      btn.setAttribute('aria-expanded', open);
    });
    document.addEventListener('click', (e) => {
      if (!wrap.contains(e.target)) { wrap.classList.remove('is-open'); btn.setAttribute('aria-expanded', 'false'); }
    });
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') wrap.classList.remove('is-open'); });
    labels(); marks();
    if (window.i18n && window.i18n.onChange) window.i18n.onChange(labels);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', build); else build();
})();
