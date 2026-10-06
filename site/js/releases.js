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
  const railScroll = document.getElementById('rel-rail-scroll');
  const searchEl = document.getElementById('rel-search');
  const railEmpty = document.getElementById('rel-rail-empty');
  if (!list) return;

  let releases = [];
  let filter = 'all';
  let shown = PAGE;
  let visible = []; // releases matching the filter (rail shows all of them)
  let navItems = [];

  // beta = flagged pre-release on GitHub, or alpha/beta in the tag name
  const isBeta = (r) => !!r.prerelease || /alpha|beta/i.test(r.tag_name || '');

  // same id on the card, the rail link and the URL hash
  const idOf = (rel) => (rel.tag_name || String(rel.id)).replace(/[^\w.-]/g, '_');

  const t = (k) => (window.i18n ? i18n.t(k) : k);
  const lang = () => (window.i18n ? i18n.lang : 'fr');

  // escape text before putting it in innerHTML
  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // ---- small markdown renderer (GitHub release notes) ----
  // supports: headings, **bold**, *italic*, ~~strike~~, ==highlight==, `code`, code blocks,
  // links + bare urls, @user, #123, lists (nested, ordered, task), tables, quotes, rules.
  // Everything is escaped first, so notes can never inject HTML.
  function inline(src) {
    const codes = [];
    let t = src.replace(/`([^`]+)`/g, (_, c) => { codes.push(c); return '\u0000' + (codes.length - 1) + '\u0000'; });
    t = esc(t);
    t = t
      .replace(/\[([^\]]+)\]\((https?:[^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>')
      .replace(/(^|[\s(])(https?:\/\/[^\s<)]+)/g, '$1<a href="$2" target="_blank" rel="noopener">$2</a>')
      .replace(/(^|[\s(])@([A-Za-z0-9-]+)/g, '$1<a href="https://github.com/$2" target="_blank" rel="noopener">@$2</a>')
      .replace(new RegExp('(^|[\\s(])#(\\d+)\\b', 'g'), '$1<a href="https://github.com/' + repo + '/issues/$2" target="_blank" rel="noopener">#$2</a>')
      .replace(/\*\*(.+?)\*\*|__(.+?)__/g, (_, x, y) => '<strong>' + (x || y) + '</strong>')
      .replace(/(^|[^*\w])\*([^*\s][^*]*?)\*(?!\*)/g, '$1<em>$2</em>')
      .replace(/(^|[^_\w])_([^_\s][^_]*?)_(?![_\w])/g, '$1<em>$2</em>')
      .replace(/~~(.+?)~~/g, '<del>$1</del>')
      .replace(/==(.+?)==/g, '<mark>$1</mark>');
    return t.replace(/\u0000(\d+)\u0000/g, (_, i) => '<code>' + esc(codes[i]) + '</code>');
  }

  const TABLE_SEP = /^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$/;
  const LIST_ITEM = /^(\s*)([-*+]|\d+[.)])\s+(.*)$/;
  const cells = (line) => line.trim().replace(/^\||\|$/g, '').split(/(?<!\\)\|/).map((c) => c.trim().replace(/\\\|/g, '|'));

  function md(text) {
    const lines = text.replace(/\r/g, '').split('\n');
    const out = [];
    let i = 0;

    // a line that starts something other than a plain paragraph
    const isBlock = (k) => {
      const l = lines[k].trim();
      return /^(#{1,6}\s|```|>|[-*_]{3,}$)/.test(l) || LIST_ITEM.test(lines[k]) ||
        (l.includes('|') && k + 1 < lines.length && TABLE_SEP.test(lines[k + 1]));
    };

    while (i < lines.length) {
      const line = lines[i];
      const l = line.trim();
      if (!l) { i++; continue; }

      // fenced code block
      if (l.startsWith('```')) {
        const code = [];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) code.push(lines[i++]);
        i++;
        out.push('<pre><code>' + esc(code.join('\n')) + '</code></pre>');
        continue;
      }

      // table
      if (l.includes('|') && i + 1 < lines.length && TABLE_SEP.test(lines[i + 1])) {
        const head = cells(l);
        const align = cells(lines[i + 1]).map((c) => (/^:-+:$/.test(c) ? 'center' : /-:$/.test(c) ? 'right' : ''));
        const cell = (tag, c, n) => `<${tag}${align[n] ? ` style="text-align:${align[n]}"` : ''}>${inline(c)}</${tag}>`;
        let html = '<div class="rel-table-wrap"><table><thead><tr>' + head.map((c, n) => cell('th', c, n)).join('') + '</tr></thead><tbody>';
        i += 2;
        while (i < lines.length && lines[i].trim() && lines[i].includes('|')) {
          html += '<tr>' + cells(lines[i]).map((c, n) => cell('td', c, n)).join('') + '</tr>';
          i++;
        }
        out.push(html + '</tbody></table></div>');
        continue;
      }

      // heading
      const h = l.match(/^(#{1,6})\s+(.*)$/);
      if (h) { out.push(`<h4 class="rel-h rel-h${h[1].length}">${inline(h[2])}</h4>`); i++; continue; }

      // horizontal rule
      if (/^([-*_])\1{2,}$/.test(l)) { out.push('<hr>'); i++; continue; }

      // quote (content is rendered again, so it can hold lists, bold, ...)
      if (l.startsWith('>')) {
        const q = [];
        while (i < lines.length && lines[i].trim().startsWith('>')) q.push(lines[i++].trim().replace(/^>\s?/, ''));
        out.push('<blockquote>' + md(q.join('\n')) + '</blockquote>');
        continue;
      }

      // list (nested by indentation, ordered or not, with task items)
      if (LIST_ITEM.test(line)) {
        const stack = [];
        while (i < lines.length && LIST_ITEM.test(lines[i])) {
          const m = lines[i].match(LIST_ITEM);
          const indent = m[1].replace(/\t/g, '  ').length;
          const type = /\d/.test(m[2][0]) ? 'ol' : 'ul';
          while (stack.length && indent < stack[stack.length - 1].indent) out.push('</li></' + stack.pop().type + '>');
          const top = stack[stack.length - 1];
          if (!top || indent > top.indent) { out.push('<' + type + '>'); stack.push({ indent, type }); } else out.push('</li>');
          const task = m[3].match(/^\[([ xX])\]\s+(.*)$/);
          out.push(task
            ? `<li class="rel-task"><input type="checkbox" disabled${task[1] === ' ' ? '' : ' checked'}> ${inline(task[2])}`
            : '<li>' + inline(m[3]));
          i++;
        }
        while (stack.length) out.push('</li></' + stack.pop().type + '>');
        continue;
      }

      // paragraph: consecutive plain lines, single line breaks kept (like GitHub)
      const para = [];
      while (i < lines.length && lines[i].trim() && (para.length === 0 || !isBlock(i))) para.push(inline(lines[i++].trim()));
      out.push('<p>' + para.join('<br>') + '</p>');
    }
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
      (isBeta(rel) ? `<span class="rel-badge">${esc(t('releases.pre'))}</span>` : '');
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
    const items = releases.filter((r) => filter === 'all' || (filter === 'beta') === isBeta(r));
    const latestId = (releases.find((r) => !isBeta(r)) || {}).tag_name;
    statusEl.hidden = items.length > 0;
    if (!items.length) statusEl.textContent = t('releases.empty');
    visible = items;
    items.slice(0, shown).forEach((r) => list.appendChild(card(r, r.tag_name === latestId)));
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
      if (isBeta(r)) a.insertAdjacentHTML('beforeend', '<span class="rel-nav-pre">pre</span>');
      a.addEventListener('click', (e) => { e.preventDefault(); goTo(idOf(r), true); });
      railInner.appendChild(a);
      return a;
    });
    rail.hidden = !navItems.length;
    searchEl.placeholder = t('releases.search');
    applySearch();
  }

  // hide the bookmarks that do not match the search box
  function applySearch() {
    const q = searchEl.value.trim().toLowerCase();
    let count = 0;
    navItems.forEach((n) => {
      const hit = !q || n.textContent.toLowerCase().includes(q);
      n.hidden = !hit;
      if (hit) count++;
    });
    rail.classList.toggle('is-searching', !!q);
    railEmpty.hidden = !q || count > 0;
  }
  searchEl.addEventListener('input', applySearch);

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
      if (!cur.hidden) {
        const top = cur.offsetTop, h = cur.offsetHeight;
        if (top < railScroll.scrollTop) railScroll.scrollTop = top - 8;
        else if (top + h > railScroll.scrollTop + railScroll.clientHeight) railScroll.scrollTop = top + h - railScroll.clientHeight + 8;
      }
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

  // data comes from js/gh-data.js (static copy first, GitHub API only as a fallback)
  (window.ghData ? ghData.get() : Promise.reject(new Error('no loader')))
    .then((data) => {
      releases = data.releases.filter((r) => !r.draft);
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
