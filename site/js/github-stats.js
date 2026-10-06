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

  function tile(icon, raw, labelKey, n, href) {
    // the version tile is a link to its entry on the versions page
    const span = document.createElement(href ? 'a' : 'span');
    if (href) span.href = href;
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

  function build(stars, tag, downloads) {
    const defs = [];
    if (typeof stars === 'number') defs.push([starIcon, stars, 'ghFavorites']);
    if (tag) defs.push([tagIcon, tag, 'ghLatestVersion', 'releases.html#' + encodeURIComponent(tag)]);
    if (typeof downloads === 'number') defs.push([downloadIcon, downloads, 'ghDownloads']);

    if (!defs.length) {
      el.classList.add('is-empty'); // nothing to show: give the reserved space back
      return;
    }
    tiles = defs.map((d, i) => tile(d[0], d[1], d[2], i, d[3]));
    el.textContent = '';
    tiles.forEach((x) => el.appendChild(x.span));
    paint();
    el.removeAttribute('aria-hidden');
    el.classList.add('is-ready');
  }

  const getJson = (url) =>
    fetch(url).then((r) => (r.ok ? r.json() : null)).catch(() => null);

  Promise.all([
    getJson('https://api.github.com/repos/' + repo),
    getJson('https://api.github.com/repos/' + repo + '/releases/latest'),
    getJson('https://api.github.com/repos/' + repo + '/releases?per_page=100'),
  ]).then(([info, latest, releases]) => {
    const stars = info && typeof info.stargazers_count === 'number' ? info.stargazers_count : null;
    const tag = latest && latest.tag_name ? latest.tag_name : null;
    const downloads = Array.isArray(releases)
      ? releases.reduce((sum, rel) => sum + (rel.assets || []).reduce((s, a) => s + (a.download_count || 0), 0), 0)
      : null;
    build(stars, tag, downloads);
  });

  if (window.i18n) i18n.onChange(paint);
})();
