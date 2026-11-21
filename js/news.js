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
  // ---- mini markdown (same syntax as the app) --------------------------------------------
  // **bold**  *italic*  __underline__  ~~strike~~  ==highlight==  `code`  # titles  - lists
  // | tables |  ![alt](https://image)  and links. In the workflow field a line break is written \n
  const inline = (raw) => {
    const keep = [];
    const stash = (h) => '\u0000' + (keep.push(h) - 1) + '\u0000';
    let t = esc(raw);
    t = t.replace(/`([^`]+)`/g, (m, a) => stash('<code>' + a + '</code>'));
    t = t.replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g,
      (m, a, u) => stash('<a href="' + u + '" target="_blank" rel="noopener">' + a + '</a>'));
    t = t.replace(/(https?:\/\/[^\s<]+?)([)\].,;!?]*)(?=\s|$|\u0000)/g,
      (m, u, tail) => stash('<a href="' + u + '" target="_blank" rel="noopener">' + u + '</a>') + tail);
    t = t.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
         .replace(/__(.+?)__/g, '<u>$1</u>')
         .replace(/~~(.+?)~~/g, '<s>$1</s>')
         .replace(/==(.+?)==/g, '<mark>$1</mark>')
         .replace(/(?<!\*)\*(?!\*)(.+?)\*(?!\*)/g, '<em>$1</em>')
         .replace(/(^|[\s(])_(.+?)_(?=[\s).,;!?]|$)/g, '$1<em>$2</em>');
    return t.replace(/\u0000(\d+)\u0000/g, (m, i) => keep[+i]);
  };
  const isRow = (l) => l.trim() !== '' && l.includes('|');
  const isSep = (l) => /^\s*\|?[\s:\-|]+\|?\s*$/.test(l) && l.includes('-');
  const cells = (l) => { l = l.trim(); if (l[0] === '|') l = l.slice(1); if (l.endsWith('|')) l = l.slice(0, -1); return l.split('|').map((c) => c.trim()); };
  function md(src) {
    // a one-line field can't hold a real line break: "\n" typed as two characters is one
    let text = String(src || '');
    if (!text.includes('\n')) text = text.replace(/\\n/g, '\n');
    const lines = text.replace(/\r\n?/g, '\n').split('\n');
    const out = [];
    let para = [], list = [], quote = [], listTag = 'ul';
    const flush = () => {
      if (para.length) { out.push('<p>' + para.join('<br>') + '</p>'); para = []; }
      if (list.length) { out.push('<' + listTag + '>' + list.join('') + '</' + listTag + '>'); list = []; }
      if (quote.length) { out.push('<blockquote>' + quote.join('<br>') + '</blockquote>'); quote = []; }
    };
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trimEnd(), tr = line.trim();
      if (!tr) { flush(); continue; }
      let m;
      if ((m = /^!\[([^\]]*)\]\((https?:\/\/\S+)\)$/.exec(tr))) { flush(); out.push('<img class="nw-img" loading="lazy" alt="' + esc(m[1]) + '" src="' + esc(m[2]) + '">'); continue; }
      if (i + 1 < lines.length && isRow(line) && isSep(lines[i + 1])) {
        flush();
        const head = cells(line); let j = i + 2; const rows = [];
        while (j < lines.length && isRow(lines[j])) { rows.push(cells(lines[j])); j++; }
        out.push('<div class="nw-table"><table><thead><tr>' + head.map((h) => '<th>' + inline(h) + '</th>').join('') + '</tr></thead><tbody>' +
          rows.map((r) => '<tr>' + head.map((_, k) => '<td>' + inline(r[k] || '') + '</td>').join('') + '</tr>').join('') + '</tbody></table></div>');
        i = j - 1; continue;
      }
      if ((m = /^(#{1,3})\s+(.*)/.exec(tr))) { flush(); out.push('<h3 class="nw-h nw-h' + m[1].length + '">' + inline(m[2]) + '</h3>'); continue; }
      if ((m = /^>\s?(.*)/.exec(tr))) { if (para.length || list.length) flush(); quote.push(inline(m[1])); continue; }
      if ((m = /^[-*]\s+(.*)/.exec(tr))) { if (para.length || quote.length || listTag !== 'ul') flush(); listTag = 'ul'; list.push('<li>' + inline(m[1]) + '</li>'); continue; }
      if ((m = /^\d+[.)]\s+(.*)/.exec(tr))) { if (para.length || quote.length || listTag !== 'ol') flush(); listTag = 'ol'; list.push('<li>' + inline(m[1]) + '</li>'); continue; }
      if (list.length || quote.length) flush();
      para.push(inline(tr));
    }
    flush();
    return out.join('');
  }

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
  // body: render the markdown first, then translate only the text nodes (links and code stay as they are)
  function translateBody(el, orig, to) {
    const tk = (el._tk = (el._tk || 0) + 1);
    el.innerHTML = md(orig);
    if (!trOn || !window.i18n) return;
    const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, {
      acceptNode: (n) => (n.nodeValue.trim() && !n.parentNode.closest('a,code') ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT),
    });
    const nodes = []; while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.forEach((n) => {
      n._lead = (/^\s*/.exec(n.nodeValue) || [''])[0]; n._trail = (/\s*$/.exec(n.nodeValue) || [''])[0];
      i18n.translate(n.nodeValue, to).then((out) => { if (trOn && lang() === to && el._tk === tk && out) n.nodeValue = (n._lead || '') + out.trim() + (n._trail || ''); }).catch(() => {});
    });
  }
  function applyTr() {
    const to = lang();
    document.querySelectorAll('#nw-list .nw-txt').forEach((el) => {
      const orig = el.getAttribute('data-orig');
      if (el.hasAttribute('data-md')) { translateBody(el, orig, to); return; }
      if (!trOn || !window.i18n) { el.textContent = orig; return; }
      i18n.translate(orig, to).then((out) => { if (trOn && lang() === to) el.textContent = out; }).catch(() => {});
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
        ${n.body ? `<div class="nw-body nw-txt" data-orig="${esc(n.body)}" data-md="1">${md(n.body)}</div>` : ''}`;
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
