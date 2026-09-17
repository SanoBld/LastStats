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

  fetch(`https://api.github.com/repos/${repo}/readme`, {
    headers: { Accept: 'application/vnd.github.raw+json' },
  })
    .then((r) => {
      if (!r.ok) throw new Error('readme fetch failed');
      return r.text();
    })
    .then((markdown) => {
      if (window.marked) {
        body.innerHTML = marked.parse(markdown);
      } else {
        // marked failed to load (e.g. offline) — fall back to raw text
        const pre = document.createElement('pre');
        pre.textContent = markdown;
        body.appendChild(pre);
      }
      status.style.display = 'none';
      body.removeAttribute('aria-hidden');
    })
    .catch(() => {
      status.textContent = t('readmeError', 'Impossible de charger le README pour le moment.');
      status.classList.add('is-error');
    });
})();
