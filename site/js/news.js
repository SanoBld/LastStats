// News page: shows news.json (same file the app reads, made by the publish-news workflow).
(function () {
  const STEP = 20;
  const listEl = document.getElementById('nw-list');
  const statusEl = document.getElementById('nw-status');
  const moreEl = document.getElementById('nw-more');
  const searchEl = document.getElementById('nw-search');
  const filterBtns = document.querySelectorAll('#nw-filter .rel-filter-btn');

  const lang = () => (window.i18n ? i18n.lang : 'fr');
  // default texts, used if a language file has no "news.*" key
  const DEF = {
    fr: { empty: 'Aucune actualité trouvée.', error: 'Impossible de charger les actualités.', feature: 'Nouveauté', fix: 'Correctif', update: 'Mise à jour', alert: 'Alerte', info: 'Info' },
    en: { empty: 'No news found.', error: 'Could not load the news.', feature: 'Feature', fix: 'Fix', update: 'Update', alert: 'Alert', info: 'Info' },
  };
  const t = (k) => {
    const v = window.i18n ? i18n.t(k) : k;
    if (v !== k) return v;
    return (DEF[lang()] || DEF.fr)[k.replace('news.', '')] || v;
  };
  const ICON = { feature: '✨', fix: '🔧', update: '⬆️', alert: '⚠️', info: 'ℹ️' };
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  // make links in the body clickable (after escaping)
  const linkify = (s) => esc(s).replace(/(https?:\/\/[^\s<]+)/g, '<a href="$1" target="_blank" rel="noopener">$1</a>');

  // translation button: on by default, into the site language (same as the pushes page)
  let trOn = true;
  try { trOn = localStorage.getItem('cmTr') !== '0'; } catch (e) {}
  const trBtn = document.createElement('button');
  trBtn.type = 'button';
  trBtn.className = 'rel-filter-btn cm-tr-btn md-ripple';
  searchEl.parentNode.insertBefore(trBtn, searchEl);
  function paintTrBtn() {
    trBtn.classList.toggle('is-active', trOn);
    trBtn.setAttribute('aria-pressed', trOn ? 'true' : 'false');
    const lbl = (window.i18n && i18n.t(trOn ? 'commits.show_original' : 'commits.translate')) || '';
    trBtn.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12.87 15.07l-2.54-2.51.03-.03c1.74-1.94 2.98-4.17 3.71-6.53H17V4h-7V2H8v2H1v1.99h11.17C11.5 7.92 10.44 9.75 9 11.35 8.07 10.32 7.3 9.19 6.69 8h-2c.73 1.63 1.73 3.17 2.98 4.56l-5.09 5.02L4 19l5-5 3.11 3.11.76-2.04zM18.5 10h-2L12 22h2l1.12-3h4.75L21 22h2l-4.5-12zm-2.62 7l1.62-4.33L19.12 17h-3.24z"/></svg>';
    trBtn.title = lbl;
    trBtn.setAttribute('aria-label', lbl);
  }
  function applyTr() {
    const to = lang();
    document.querySelectorAll('#nw-list .nw-txt').forEach((el) => {
      const orig = el.getAttribute('data-orig');
      const link = el.hasAttribute('data-link');
      const show = (txt) => { if (link) el.innerHTML = linkify(txt); else el.textContent = txt; };
      if (!trOn || !window.i18n) { show(orig); return; }
      // translate only the text between links, so the links stay exact and clickable
      const parts = orig.split(/(https?:\/\/[^\s<]+)/);
      Promise.all(parts.map((p, i) => (i % 2 || !p.trim() ? p : i18n.translate(p, to).catch(() => p))))
        .then((out) => { if (trOn && lang() === to) show(out.join('')); });
    });
  }
  trBtn.addEventListener('click', () => {
    trOn = !trOn;
    try { localStorage.setItem('cmTr', trOn ? '1' : '0'); } catch (e) {}
    if (window.i18n && i18n.setDynTr) i18n.setDynTr(trOn);
    paintTrBtn(); applyTr();
  });
  paintTrBtn();

  let items = [], filter = 'all', query = '', shown = STEP;

  // the id is "news_<unix seconds>", so we can rebuild the full date (the date field has no year)
  function fullDate(n) {
    const m = /^news_(\d+)$/.exec(n.id || '');
    if (m) return new Date(+m[1] * 1000).toLocaleDateString(lang(), { year: 'numeric', month: 'long', day: 'numeric' });
    return n.date || '';
  }

  function visible() {
    const q = query.trim().toLowerCase();
    return items.filter((n) => {
      if (filter !== 'all' && n.type !== filter) return false;
      return !q || ((n.title || '') + ' ' + (n.body || '')).toLowerCase().includes(q);
    });
  }

  function render() {
    const list = visible();
    listEl.innerHTML = '';
    statusEl.hidden = list.length > 0;
    if (!list.length) { statusEl.textContent = t('news.empty'); statusEl.classList.remove('is-error'); }
    const wrap = document.createElement('div');
    wrap.className = 'cm-rows';
    list.slice(0, shown).forEach((n) => {
      const type = ICON[n.type] ? n.type : 'info';
      const row = document.createElement('article');
      row.className = 'cm-row nw-row' + (type === 'alert' ? ' is-alert' : '');
      row.innerHTML = `
        <div class="nw-head">
          <span class="nw-emoji" aria-hidden="true">${esc(n.emoji || ICON[type])}</span>
          <h2 class="nw-title nw-txt" data-orig="${esc(n.title)}">${esc(n.title)}</h2>
          <span class="rel-badge">${esc(t('news.' + type))}</span>
        </div>
        <p class="nw-date">${esc(fullDate(n))}</p>
        ${n.body ? `<p class="nw-body nw-txt" data-orig="${esc(n.body)}" data-link="1">${linkify(n.body)}</p>` : ''}`;
      wrap.appendChild(row);
    });
    listEl.appendChild(wrap);
    applyTr();
    moreEl.hidden = list.length <= shown;
  }

  filterBtns.forEach((b) => b.addEventListener('click', () => {
    filterBtns.forEach((x) => x.classList.toggle('is-active', x === b));
    filter = b.getAttribute('data-filter'); shown = STEP; render();
  }));
  searchEl.addEventListener('input', () => { query = searchEl.value; shown = STEP; render(); });
  moreEl.addEventListener('click', () => { shown += STEP; render(); });
  searchEl.placeholder = t('releases.search');

  // sources in order: copy made by the workflow, root file, live site; last good answer is kept in this browser
  const SRC = ['data/news.json', 'news.json', 'https://sanobld.github.io/LastStats/news.json'];
  const CKEY = 'news:items';
  const getJson = (u) => fetch(u, { cache: 'no-cache' }).then((r) => { if (!r.ok) throw new Error(r.status); return r.json(); });
  function load(i) {
    if (i >= SRC.length) {
      try { const c = JSON.parse(localStorage.getItem(CKEY)); if (c && Array.isArray(c.items)) return Promise.resolve(c); } catch (e) {}
      return Promise.reject(new Error('no news'));
    }
    return getJson(SRC[i]).then((d) => { if (!d || !Array.isArray(d.items)) throw new Error('bad'); return d; }).catch(() => load(i + 1));
  }
  statusEl.textContent = t('news.loading');
  load(0)
    .then((d) => { items = d.items; try { localStorage.setItem(CKEY, JSON.stringify({ items })); } catch (e) {} render(); })
    .catch(() => { statusEl.textContent = t('news.error'); statusEl.classList.add('is-error'); });

  if (window.i18n) i18n.onChange(() => { paintTrBtn(); searchEl.placeholder = t('releases.search'); if (items.length) render(); });
})();
