// Pushes page: list of commits (grouped by day) with a ZIP download for each one.
// Data: data/commits.json (made by the deploy-site workflow, no rate limit).
// If it is missing, we ask the GitHub API once (first page only).
(function () {
  const tag = document.currentScript;
  const repo = (tag && tag.getAttribute('data-repo')) || 'SanoBld/LastStats-App';
  const STEP = 30;

  const listEl = document.getElementById('cm-list');
  const latestEl = document.getElementById('cm-latest');
  const statusEl = document.getElementById('cm-status');
  const moreEl = document.getElementById('cm-more');
  const searchEl = document.getElementById('cm-search');
  const filterBtns = document.querySelectorAll('#cm-filter .rel-filter-btn');

  searchEl.placeholder = (window.i18n && i18n.t('releases.search')) || 'Rechercher…';
  let commits = [];
  let filter = 'all';
  let query = '';
  let shown = STEP;

  // default texts, used when i18n/*.js is old or cached and has no "commits.*" key
  const DEF = {
    fr: { view: 'Voir', zip: 'ZIP', zip_title: 'Télécharger le code de ce push (ZIP)', copy: 'Copier le hash', copied: 'Copié', latest: 'Dernier push', empty: 'Aucun push trouvé.', error: 'Impossible de charger les pushs.', push_one: 'push', push_many: 'pushs' },
    en: { view: 'View', zip: 'ZIP', zip_title: 'Download the code of this push (ZIP)', copy: 'Copy hash', copied: 'Copied', latest: 'Latest push', empty: 'No push found.', error: 'Could not load pushes.', push_one: 'push', push_many: 'pushes' },
  };
  const t = (k) => {
    const v = window.i18n ? i18n.t(k) : k;
    if (v !== k) return v;
    const d = DEF[lang()] || DEF.fr;
    return d[k.replace('commits.', '')] || v;
  };
  const lang = () => (window.i18n ? i18n.lang : 'fr');
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const zipUrl = (sha) => `https://github.com/${repo}/archive/${sha}.zip`;

  const ICON_ZIP = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 10 5 5 5-5"/><path d="M12 15V3"/></svg>';

  function load() {
    return fetch('data/commits.json', { cache: 'no-cache' })
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null)
      .then((d) => {
        if (d && Array.isArray(d.commits) && d.commits.length) return d;
        return fetch(`https://api.github.com/repos/${repo}/commits?per_page=100`)
          .then((r) => { if (!r.ok) throw new Error('api ' + r.status); return r.json(); })
          .then((arr) => ({
            commits: arr.map((c) => ({
              sha: c.sha, message: c.commit.message, date: c.commit.author.date,
              author: (c.author && c.author.login) || c.commit.author.name,
              avatar: c.author && c.author.avatar_url, url: c.html_url, tags: [],
            })),
          }));
      });
  }

  const kind = (c) => (/^\s*feat/i.test(c.message) ? 'feat' : /^\s*fix/i.test(c.message) ? 'fix' : 'other');

  function visible() {
    const q = query.trim().toLowerCase();
    return commits.filter((c) => {
      if (filter === 'tag' && !(c.tags && c.tags.length)) return false;
      if ((filter === 'feat' || filter === 'fix') && kind(c) !== filter) return false;
      return !q || (c.message + ' ' + c.sha + ' ' + c.author + ' ' + (c.tags || []).join(' ')).toLowerCase().includes(q);
    });
  }

  function row(c, withDate) {
    const lines = (c.message || '').split('\n');
    const d = new Date(c.date);
    const time = withDate
      ? d.toLocaleString(lang(), { dateStyle: 'medium', timeStyle: 'short' })
      : d.toLocaleTimeString(lang(), { hour: '2-digit', minute: '2-digit' });
    const tags = (c.tags || []).map((n) => `<span class="rel-badge">${esc(n)}</span>`).join(' ');
    const el = document.createElement('div');
    el.className = 'cm-row';
    el.innerHTML = `
      <div class="cm-main">
        <p class="cm-msg">${esc(lines[0])} ${tags}</p>
        <p class="cm-meta">
          <button type="button" class="cm-sha md-ripple" title="${esc(t('commits.copy'))}">${esc(c.sha.slice(0, 7))}</button>
          <span>${c.avatar ? `<img class="cm-avatar" src="${esc(c.avatar)}&s=36" alt="" loading="lazy"> ` : ''}${esc(c.author)}</span>
          <span>${esc(time)}</span>
        </p>
      </div>
      <div class="cm-actions">
        <a class="cm-btn md-ripple" href="${esc(c.url)}" target="_blank" rel="noopener">${esc(t('commits.view'))}</a>
        <a class="cm-btn is-zip md-ripple" href="${zipUrl(c.sha)}" title="${esc(t('commits.zip_title'))}">${ICON_ZIP}<span>${esc(t('commits.zip'))}</span></a>
      </div>`;
    const sha = el.querySelector('.cm-sha');
    sha.addEventListener('click', () => {
      if (navigator.clipboard) navigator.clipboard.writeText(c.sha).catch(() => {});
      const old = sha.textContent;
      sha.textContent = t('commits.copied');
      setTimeout(() => { sha.textContent = old; }, 1200);
    });
    return el;
  }

  function renderLatest() {
    latestEl.innerHTML = '';
    if (!commits.length) return;
    const c = commits[0];
    const card = document.createElement('article');
    card.className = 'rel-card is-latest cm-latest';
    card.innerHTML = `<div class="rel-head"><span class="rel-badge">${esc(t('commits.latest'))}</span></div>`;
    card.appendChild(row(c, true));
    latestEl.appendChild(card);
  }

  function render() {
    const items = visible();
    listEl.innerHTML = '';
    statusEl.hidden = items.length > 0;
    if (!items.length) { statusEl.textContent = t('commits.empty'); statusEl.classList.remove('is-error'); }

    const slice = items.slice(0, shown);
    let day = '';
    let rows = null;
    let count = null;
    let n = 0;
    slice.forEach((c) => {
      const key = c.date.slice(0, 10);
      if (key !== day) {
        if (count) count.textContent = `${n} ${t(n > 1 ? 'commits.push_many' : 'commits.push_one')}`;
        day = key; n = 0;
        const card = document.createElement('article');
        card.className = 'rel-card';
        const title = new Date(c.date).toLocaleDateString(lang(), { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
        card.innerHTML = `<h2 class="cm-day-title">${esc(title)}</h2><p class="cm-day-count"></p><div class="cm-rows"></div>`;
        count = card.querySelector('.cm-day-count');
        rows = card.querySelector('.cm-rows');
        listEl.appendChild(card);
      }
      rows.appendChild(row(c, false));
      n++;
    });
    if (count) count.textContent = `${n} ${t(n > 1 ? 'commits.push_many' : 'commits.push_one')}`;
    moreEl.hidden = items.length <= shown;
  }

  filterBtns.forEach((b) => b.addEventListener('click', () => {
    filterBtns.forEach((x) => x.classList.toggle('is-active', x === b));
    filter = b.getAttribute('data-filter'); shown = STEP; render();
  }));
  searchEl.addEventListener('input', () => { query = searchEl.value; shown = STEP; render(); });
  moreEl.addEventListener('click', () => { shown += STEP; render(); });

  load().then((d) => {
    commits = d.commits;
    renderLatest();
    render();
  }).catch(() => {
    statusEl.textContent = t('commits.error');
    statusEl.classList.add('is-error');
  });

  if (window.i18n) i18n.onChange(() => { searchEl.placeholder = t('releases.search'); if (commits.length) { renderLatest(); render(); } });
})();
