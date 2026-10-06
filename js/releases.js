// Versions page: lists every GitHub release with notes + files to download.
// Repo comes from this script tag's data-repo attribute.
(function () {
  const tag = document.currentScript;
  const repo = (tag && tag.getAttribute('data-repo')) || 'SanoBld/LastStats-App';
  const PAGE = 8; // cards shown at once

  const list = document.getElementById('rel-list');
  const statusEl = document.getElementById('rel-status');
  const moreBtn = document.getElementById('rel-more');
  const filterBtns = document.querySelectorAll('.rel-filter-btn');
  const rail = document.getElementById('rel-rail');
  const railInner = document.getElementById('rel-rail-inner');
  const railFill = document.getElementById('rel-rail-fill');
  if (!list) return;

  let releases = [];
  let filter = 'all';
  let shown = PAGE;
  let visible = []; // releases matching the filter (rail shows all of them)
  let navItems = [];

  // same id on the card, the rail link and the URL hash
  const idOf = (rel) => (rel.tag_name || String(rel.id)).replace(/[^\w.-]/g, '_');

  const t = (k) => (window.i18n ? i18n.t(k) : k);
  const lang = () => (window.i18n ? i18n.lang : 'fr');

  // escape text before putting it in innerHTML
  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // inline markdown: **bold**, `code`, [text](url), bare urls
  function inline(s) {
    return esc(s)
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
      .replace(/\[([^\]]+)\]\((https?:[^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
  }

  // tiny markdown renderer: headings, lists, paragraphs
  function md(text) {
    const out = [];
    let inList = false;
    text.replace(/\r/g, '').split('\n').forEach((raw) => {
      const line = raw.trim();
      const li = line.match(/^[-*]\s+(.*)/);
      if (li) {
        if (!inList) { out.push('<ul>'); inList = true; }
        out.push('<li>' + inline(li[1]) + '</li>');
        return;
      }
      if (inList) { out.push('</ul>'); inList = false; }
      if (!line) return;
      const h = line.match(/^#{1,6}\s+(.*)/);
      out.push(h ? '<h4>' + inline(h[1]) + '</h4>' : '<p>' + inline(line) + '</p>');
    });
    if (inList) out.push('</ul>');
    return out.join('');
  }

  function size(bytes) {
    if (bytes > 1048576) return (bytes / 1048576).toFixed(1) + ' MB';
    return Math.max(1, Math.round(bytes / 1024)) + ' KB';
  }

  function card(rel, isLatest) {
    const el = document.createElement('article');
    el.className = 'rel-card' + (isLatest ? ' is-latest' : '');
    el.id = idOf(rel);
    const date = rel.published_at
      ? new Date(rel.published_at).toLocaleDateString(lang(), { year: 'numeric', month: 'long', day: 'numeric' }) : '';
    const badges = (isLatest ? `<span class="rel-badge">${esc(t('releases.latest'))}</span>` : '') +
      (rel.prerelease ? `<span class="rel-badge">${esc(t('releases.pre'))}</span>` : '');
    const body = (rel.body || '').trim();
    const assets = (rel.assets || []).filter((a) => !/\.(sha256|sig|blockmap)$/i.test(a.name));

    el.innerHTML = `
      <div class="rel-head"><h2 class="rel-tag">${esc(rel.tag_name || rel.name)}</h2>${badges}</div>
      <p class="rel-date">${esc(date)}</p>
      <h3 class="rel-files-title">${esc(t('releases.notes'))}</h3>
      <div class="rel-notes">${body ? md(body) : '<p>' + esc(t('releases.no_notes')) + '</p>'}</div>
      <h3 class="rel-files-title">${esc(t('releases.files'))}</h3>
      <div class="rel-assets"></div>`;

    // long notes start collapsed
    const notes = el.querySelector('.rel-notes');
    if (body.length > 400) {
      notes.classList.add('is-collapsed');
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'rel-toggle md-ripple';
      btn.textContent = t('releases.show_more');
      btn.addEventListener('click', () => {
        const collapsed = notes.classList.toggle('is-collapsed');
        btn.textContent = collapsed ? t('releases.show_more') : '−';
      });
      notes.after(btn);
    }

    const box = el.querySelector('.rel-assets');
    if (!assets.length) box.innerHTML = '<p>' + esc(t('releases.no_files')) + '</p>';
    assets.forEach((a) => {
      const link = document.createElement('a');
      link.className = 'rel-asset md-ripple';
      link.href = a.browser_download_url;
      link.innerHTML = `<span class="rel-asset-name">${esc(a.name)}</span>
        <span class="rel-asset-meta">${size(a.size)} · ${a.download_count.toLocaleString(lang())}</span>`;
      link.title = `${a.download_count} ${t('releases.downloads')}`;
      box.appendChild(link);
    });
    return el;
  }

  function render() {
    list.innerHTML = '';
    const items = releases.filter((r) => filter === 'all' || !r.prerelease);
    const latestId = (releases.find((r) => !r.prerelease) || {}).id;
    visible = items;
    items.slice(0, shown).forEach((r) => list.appendChild(card(r, r.id === latestId)));
    moreBtn.hidden = items.length <= shown;
    buildRail();
    updateRail();
  }

  // left rail: one bookmark per version (all of them, even not rendered yet)
  function buildRail() {
    railInner.querySelectorAll('.rel-nav-item').forEach((n) => n.remove());
    navItems = visible.map((r) => {
      const a = document.createElement('a');
      a.className = 'rel-nav-item';
      a.href = '#' + idOf(r);
      a.textContent = r.tag_name || r.name;
      if (r.prerelease) a.insertAdjacentHTML('beforeend', '<span class="rel-nav-pre">pre</span>');
      a.addEventListener('click', (e) => { e.preventDefault(); goTo(idOf(r), true); });
      railInner.appendChild(a);
      return a;
    });
    rail.hidden = !navItems.length;
  }

  // jump to a version; renders more cards first if it is further down the list
  function goTo(id, pushHash) {
    const idx = visible.findIndex((r) => idOf(r) === id);
    if (idx < 0) return;
    if (idx >= shown) { shown = idx + 1; render(); }
    const el = document.getElementById(id);
    if (!el) return;
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    el.classList.remove('is-target');
    void el.offsetWidth;
    el.classList.add('is-target');
    if (pushHash) history.replaceState(null, '', '#' + id);
  }

  // scroll spy: last card above 35% of the viewport is the active one
  function updateRail() {
    if (!navItems.length) return;
    const cards = Array.from(list.querySelectorAll('.rel-card'));
    let active = 0;
    cards.forEach((c, i) => { if (c.getBoundingClientRect().top < window.innerHeight * 0.35) active = i; });
    navItems.forEach((n, i) => {
      n.classList.toggle('is-active', i === active);
      n.classList.toggle('is-passed', i <= active);
    });
    const cur = navItems[active];
    if (cur) {
      railFill.style.height = (cur.offsetTop + cur.offsetHeight / 2) + 'px';
      // keep the active bookmark visible inside the rail without moving the page
      const top = cur.offsetTop, h = cur.offsetHeight;
      if (top < rail.scrollTop) rail.scrollTop = top - 8;
      else if (top + h > rail.scrollTop + rail.clientHeight) rail.scrollTop = top + h - rail.clientHeight + 8;
    }
  }
  let ticking = false;
  window.addEventListener('scroll', () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => { updateRail(); ticking = false; });
  }, { passive: true });

  filterBtns.forEach((b) => b.addEventListener('click', () => {
    filter = b.getAttribute('data-filter');
    shown = PAGE;
    filterBtns.forEach((x) => x.classList.toggle('is-active', x === b));
    render();
  }));
  moreBtn.addEventListener('click', () => { shown += PAGE; render(); });

  fetch(`https://api.github.com/repos/${repo}/releases?per_page=50`)
    .then((r) => (r.ok ? r.json() : Promise.reject(new Error('api'))))
    .then((data) => {
      releases = data.filter((r) => !r.draft);
      statusEl.hidden = true;
      render();
      // coming from the index version tile: /releases.html#v3.5.0
      const hash = decodeURIComponent(location.hash.slice(1)).replace(/[^\w.-]/g, '_');
      if (hash) setTimeout(() => goTo(hash, false), 100);
    })
    .catch(() => {
      statusEl.textContent = t('releases.error');
      statusEl.setAttribute('data-i18n', 'releases.error');
      statusEl.classList.add('is-error');
    });

  // refresh texts + dates when the language changes
  if (window.i18n) i18n.onChange(() => { if (releases.length) render(); });
})();
