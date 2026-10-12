// Pulls live stats from the GitHub API (stars + latest release tag + downloads)
// and drops them into the #gh-stats strip. Reads the repo from this script's
// own data-repo attribute so it stays reusable across project pages.
// The strip is built once, after every request settled, so tiles never pop in
// one by one and push the page around.
(function () {
  const el = document.getElementById('gh-stats');
  const scriptTag = document.currentScript;
  if (!el || !scriptTag) return;

  const repo = scriptTag.getAttribute('data-repo');
  if (!repo) return;

  const starIcon = '<svg width="20" height="20" viewBox="0 0 16 16" fill="currentColor"><path d="M8 .25a.75.75 0 0 1 .673.418l1.882 3.815 4.21.612a.75.75 0 0 1 .416 1.279l-3.046 2.97.719 4.192a.75.75 0 0 1-1.088.791L8 12.347l-3.766 1.98a.75.75 0 0 1-1.088-.79l.72-4.194L.818 6.374a.75.75 0 0 1 .416-1.28l4.21-.611L7.327.668A.75.75 0 0 1 8 .25Z"/></svg>';
  const tagIcon = '<svg width="20" height="20" viewBox="0 0 16 16" fill="currentColor"><path d="M1 7.775V2.75C1 1.784 1.784 1 2.75 1h5.025c.464 0 .91.184 1.238.513l6.25 6.25a1.75 1.75 0 0 1 0 2.474l-5.026 5.026a1.75 1.75 0 0 1-2.474 0l-6.25-6.25A1.75 1.75 0 0 1 1 7.775Zm5-3.025a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3Z"/></svg>';
  const downloadIcon = '<svg width="20" height="20" viewBox="0 0 16 16" fill="currentColor"><path d="M7.25 1a.75.75 0 0 1 .75.75v6.19l1.97-1.97a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L3.47 7.03a.75.75 0 1 1 1.06-1.06l1.97 1.97V1.75A.75.75 0 0 1 7.25 1ZM1.75 12a.75.75 0 0 0-.75.75v1.5A1.75 1.75 0 0 0 2.75 16h9a1.75 1.75 0 0 0 1.75-1.75v-1.5a.75.75 0 0 0-1.5 0v1.5a.25.25 0 0 1-.25.25h-9a.25.25 0 0 1-.25-.25v-1.5a.75.75 0 0 0-.75-.75Z"/></svg>';

  const t = (key) => (window.i18n ? i18n.t(key) : key);
  const lang = () => (window.i18n ? i18n.lang : 'fr');

  // each tile keeps its own value + label refs so a language switch only updates text
  let tiles = [];

  const repoUrl = 'https://github.com/' + repo;
  const CACHE = 'ghstats-last:' + repo;

  function tile(icon, raw, labelKey, n, href, external) {
    // every tile is a link: stars -> GitHub, version -> versions page, downloads -> releases
    const span = document.createElement('a');
    span.href = href;
    if (external) { span.target = '_blank'; span.rel = 'noopener'; }
    span.className = 'gh-stat';
    span.style.setProperty('--n', n);
    span.innerHTML = icon + '<span class="gh-stat-value"></span><span class="gh-stat-label"></span>';
    return { span, raw, labelKey, value: span.children[1], label: span.children[2] };
  }

  function paint() {
    tiles.forEach((x) => {
      x.value.textContent = typeof x.raw === 'number' ? x.raw.toLocaleString(lang()) : x.raw;
      x.label.textContent = t(x.labelKey);
    });
  }

  // Tiles are built right away (last known values from localStorage, or a dash)
  // so everything is visible when the page opens; real data just updates the text.
  let last = {};
  try { last = JSON.parse(localStorage.getItem(CACHE)) || {}; } catch (e) { last = {}; }
  const dash = '\u2014';
  tiles = [
    tile(starIcon, typeof last.stars === 'number' ? last.stars : dash, 'ghFavorites', 0, repoUrl, true),
    tile(tagIcon, last.tag || dash, 'ghLatestVersion', 1, last.tag ? 'releases.html#' + encodeURIComponent(last.tag) : 'releases.html', false),
    tile(downloadIcon, typeof last.downloads === 'number' ? last.downloads : dash, 'ghDownloads', 2, repoUrl + '/releases', true),
  ];
  el.textContent = '';
  tiles.forEach((x) => el.appendChild(x.span));
  paint();
  el.removeAttribute('aria-hidden');
  el.classList.add('is-ready');

  function update(stars, tag, downloads) {
    if (typeof stars === 'number') tiles[0].raw = stars;
    if (tag) { tiles[1].raw = tag; tiles[1].span.href = 'releases.html#' + encodeURIComponent(tag); }
    if (typeof downloads === 'number') tiles[2].raw = downloads;
    paint();
    try { localStorage.setItem(CACHE, JSON.stringify({ stars: tiles[0].raw, tag: tiles[1].raw === dash ? null : tiles[1].raw, downloads: tiles[2].raw })); } catch (e) { /* ignore */ }
  }

  // data comes from js/gh-data.js (static copy first, API only as fallback)
  const ready = window.ghData ? ghData.get() : Promise.reject(new Error('no loader'));
  ready.then((d) => {
    const stable = d.releases.find((r) => !r.prerelease && !r.draft);
    const tag = stable ? stable.tag_name : null;
    const downloads = d.releases.reduce((sum, rel) => sum + (rel.assets || []).reduce((n, a) => n + (a.download_count || 0), 0), 0);
    update(typeof d.stars === 'number' ? d.stars : null, tag, downloads);
  }).catch(() => {});

  if (window.i18n) i18n.onChange(paint);
})();
