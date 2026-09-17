// Pulls live stats from the GitHub API (stars + latest release tag) and
// drops them into the #gh-stats strip. Reads the repo from this script's
// own data-repo attribute so it stays reusable across project pages.
(function () {
  const el = document.getElementById('gh-stats');
  const scriptTag = document.currentScript;
  if (!el || !scriptTag) return;

  const repo = scriptTag.getAttribute('data-repo');
  if (!repo) return;

  const starIcon = '<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 .25a.75.75 0 0 1 .673.418l1.882 3.815 4.21.612a.75.75 0 0 1 .416 1.279l-3.046 2.97.719 4.192a.75.75 0 0 1-1.088.791L8 12.347l-3.766 1.98a.75.75 0 0 1-1.088-.79l.72-4.194L.818 6.374a.75.75 0 0 1 .416-1.28l4.21-.611L7.327.668A.75.75 0 0 1 8 .25Z"/></svg>';
  const tagIcon = '<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M1 7.775V2.75C1 1.784 1.784 1 2.75 1h5.025c.464 0 .91.184 1.238.513l6.25 6.25a1.75 1.75 0 0 1 0 2.474l-5.026 5.026a1.75 1.75 0 0 1-2.474 0l-6.25-6.25A1.75 1.75 0 0 1 1 7.775Zm5-3.025a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3Z"/></svg>';
  const downloadIcon = '<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M7.25 1a.75.75 0 0 1 .75.75v6.19l1.97-1.97a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L3.47 7.03a.75.75 0 1 1 1.06-1.06l1.97 1.97V1.75A.75.75 0 0 1 7.25 1ZM1.75 12a.75.75 0 0 0-.75.75v1.5A1.75 1.75 0 0 0 2.75 16h9a1.75 1.75 0 0 0 1.75-1.75v-1.5a.75.75 0 0 0-1.5 0v1.5a.25.25 0 0 1-.25.25h-9a.25.25 0 0 1-.25-.25v-1.5a.75.75 0 0 0-.75-.75Z"/></svg>';

  // cache the raw numbers so a language switch can re-render without refetching
  let stars = null;
  let latestTag = null;
  let totalDownloads = null;

  function t(key, fallback) {
    return (window.i18n && i18n.t(key)) || fallback;
  }

  function render() {
    el.innerHTML = '';
    if (typeof stars === 'number') {
      const span = document.createElement('span');
      span.className = 'gh-stat';
      span.innerHTML = starIcon + `${stars} ${t('ghFavorites', 'favoris')}`;
      el.appendChild(span);
    }
    if (latestTag) {
      const span = document.createElement('span');
      span.className = 'gh-stat';
      span.innerHTML = tagIcon + `${t('ghLatestVersion', 'Dernière version')} ${latestTag}`;
      el.appendChild(span);
    }
    if (typeof totalDownloads === 'number') {
      const span = document.createElement('span');
      span.className = 'gh-stat';
      span.innerHTML = downloadIcon + `${totalDownloads} ${t('ghDownloads', 'téléchargements')}`;
      el.appendChild(span);
    }
    if (stars !== null || latestTag !== null || totalDownloads !== null) el.removeAttribute('aria-hidden');
  }

  // stars come from the main repo endpoint
  fetch(`https://api.github.com/repos/${repo}`)
    .then((r) => (r.ok ? r.json() : null))
    .then((data) => {
      if (data && typeof data.stargazers_count === 'number') {
        stars = data.stargazers_count;
        render();
      }
    })
    .catch(() => {});

  // latest release tag, separate call since it 404s if there's no release yet
  fetch(`https://api.github.com/repos/${repo}/releases/latest`)
    .then((r) => (r.ok ? r.json() : null))
    .then((data) => {
      if (data && data.tag_name) {
        latestTag = data.tag_name;
        render();
      }
    })
    .catch(() => {});

  // total downloads across every release's assets, same source as the README badge
  fetch(`https://api.github.com/repos/${repo}/releases?per_page=100`)
    .then((r) => (r.ok ? r.json() : null))
    .then((releases) => {
      if (!Array.isArray(releases)) return;
      totalDownloads = releases.reduce(
        (sum, rel) => sum + (rel.assets || []).reduce((s, a) => s + (a.download_count || 0), 0),
        0
      );
      render();
    })
    .catch(() => {});

  if (window.i18n) i18n.onChange(render);
})();
