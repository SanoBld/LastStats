// Fetches README.md straight from the repo's default branch (via GitHub's raw
// content API) and renders it with marked.js, so this page always mirrors
// whatever is currently on GitHub — no manual sync needed after a push.
(function () {
  const status = document.getElementById('readme-status');
  const body = document.getElementById('readme-body');
  const scriptTag = document.currentScript;
  if (!status || !body || !scriptTag) return;

  const repo = scriptTag.getAttribute('data-repo');
  if (!repo) return;

  function t(key, fallback) {
    return (window.i18n && i18n.t(key)) || fallback;
  }

  // Rewrites every relative img/a src|href in the rendered README so they
  // resolve against the repo's raw content / blob view instead of 404ing
  // against this site's own origin.
  function fixRelativeLinks(root, rawBase, blobBase) {
    root.querySelectorAll('img[src]').forEach((img) => {
      const src = img.getAttribute('src');
      if (!/^https?:\/\//i.test(src)) img.src = rawBase + src.replace(/^\.?\//, '');
    });
    root.querySelectorAll('a[href]').forEach((a) => {
      const href = a.getAttribute('href');
      if (href.startsWith('#') || /^https?:\/\//i.test(href) || href.startsWith('mailto:')) return;
      a.href = blobBase + href.replace(/^\.?\//, '');
      a.target = '_blank';
      a.rel = 'noopener';
    });
  }

  fetch(`https://api.github.com/repos/${repo}`)
    .then((r) => (r.ok ? r.json() : { default_branch: 'main' }))
    .then((repoInfo) => {
      const branch = (repoInfo && repoInfo.default_branch) || 'main';
      const rawBase = `https://raw.githubusercontent.com/${repo}/${branch}/`;
      const blobBase = `https://github.com/${repo}/blob/${branch}/`;

      return fetch(`https://api.github.com/repos/${repo}/readme`, {
        headers: { Accept: 'application/vnd.github.raw+json' },
      })
        .then((r) => {
          if (!r.ok) throw new Error('readme fetch failed');
          return r.text();
        })
        .then((markdown) => {
          if (window.marked) {
            body.innerHTML = marked.parse(markdown);
            fixRelativeLinks(body, rawBase, blobBase);
          } else {
            // marked failed to load (e.g. offline) — fall back to raw text
            const pre = document.createElement('pre');
            pre.textContent = markdown;
            body.appendChild(pre);
          }
          status.style.display = 'none';
          body.removeAttribute('aria-hidden');
        });
    })
    .catch(() => {
      status.textContent = t('readmeError', 'Impossible de charger le README pour le moment.');
      status.classList.add('is-error');
    });
})();
