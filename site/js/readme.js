// Fetches README.md straight from the repo's default branch (via GitHub's raw
// content API) and renders it with marked.js, so this page always mirrors
// whatever is currently on GitHub — no manual sync needed after a push.
// Also wires up the screenshot lightbox, a clickable table of contents built
// from the README's own headings, and a reading-progress indicator.
(function () {
  const status = document.getElementById('readme-status');
  const body = document.getElementById('readme-body');
  const toc = document.getElementById('readme-toc');
  const tocList = document.getElementById('readme-toc-list');
  const progressBar = document.getElementById('readme-progress-bar');
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
    root.querySelectorAll('source[srcset]').forEach((source) => {
      const srcset = source.getAttribute('srcset');
      if (!/^https?:\/\//i.test(srcset)) source.srcset = rawBase + srcset.replace(/^\.?\//, '');
    });
    root.querySelectorAll('a[href]').forEach((a) => {
      const href = a.getAttribute('href');
      if (href.startsWith('#') || /^https?:\/\//i.test(href) || href.startsWith('mailto:')) return;
      a.href = blobBase + href.replace(/^\.?\//, '');
      a.target = '_blank';
      a.rel = 'noopener';
    });
  }

  // Screenshots get the click-to-zoom lightbox; small badges/logo don't.
  function wireLightbox(root) {
    root.querySelectorAll('img').forEach((img) => {
      if (img.src.includes('shields.io') || img.src.includes('app_logo')) return;
      if (img.closest('a')) return; // already a link (e.g. Discord badge) — don't double-bind
      const wrap = document.createElement('div');
      wrap.className = 'lightbox-trigger';
      img.parentNode.insertBefore(wrap, img);
      wrap.appendChild(img);
    });
    if (window.Lightbox) window.Lightbox.init(root);
  }

  // Builds the left "on this page" nav from h1/h2/h3, and a reading-progress
  // bar tied to how far the README has been scrolled through.
  function buildToc(root) {
    const headings = root.querySelectorAll('h1, h2, h3');
    if (!headings.length || !toc || !tocList) return;
    const used = new Set();
    headings.forEach((h) => {
      let slug = h.textContent.trim().toLowerCase()
        .replace(/[^\p{L}\p{N}\s-]/gu, '').trim().replace(/\s+/g, '-');
      if (!slug) slug = 'section';
      let unique = slug, i = 2;
      while (used.has(unique)) unique = `${slug}-${i++}`;
      used.add(unique);
      h.id = unique;

      const link = document.createElement('a');
      link.href = `#${unique}`;
      link.textContent = h.textContent.trim();
      link.className = `readme-toc-${h.tagName.toLowerCase()}`;
      link.addEventListener('click', (e) => {
        e.preventDefault();
        h.scrollIntoView({ behavior: 'smooth', block: 'start' });
        history.replaceState(null, '', `#${unique}`);
      });
      tocList.appendChild(link);
    });
    toc.removeAttribute('aria-hidden');

    function onScroll() {
      const rect = root.getBoundingClientRect();
      const total = rect.height - window.innerHeight;
      const scrolled = Math.min(Math.max(-rect.top, 0), Math.max(total, 1));
      const pct = total > 0 ? (scrolled / total) * 100 : 0;
      if (progressBar) progressBar.style.height = pct + '%';
    }
    document.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
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
            wireLightbox(body);
            buildToc(body);
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
