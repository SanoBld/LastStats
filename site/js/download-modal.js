// Two-step download modal (OS, then architecture) that fetches the latest
// GitHub release and jumps straight to the matching asset. Reads the repo
// from the trigger button's data-repo attribute so it stays reusable.
(function () {
  const trigger = document.getElementById('download-trigger');
  if (!trigger) return;

  const repo = trigger.getAttribute('data-repo') || 'SanoBld/LastStats-App';
  const releasesUrl = `https://github.com/${repo}/releases`;

  // OS list: id used for matching + asset name keywords for that platform
  const PLATFORMS = [
    {
      id: 'windows', label: 'Windows',
      keywords: ['windows', 'win64', 'win32', '.exe', '.msi'],
      icon: '<svg width="18" height="18" viewBox="0 0 512 512"><path fill="#2f78d4" d="M96 96H416V247H265V96H247V247H96v18H247V416h18V265H416V416H96"/></svg>',
      // desktop app: architecture actually matters
      archs: [
        { id: 'x64', label: '64 bits (x64)', keywords: ['x64', 'amd64', 'win64'] },
        { id: 'arm64', label: 'ARM64', keywords: ['arm64', 'aarch64'] },
      ],
    },
    {
      id: 'linux', label: 'Linux',
      keywords: ['linux', '.appimage', '.deb', '.tar.gz', '.tar.xz'],
      icon: '<svg width="18" height="18" viewBox="0 0 512 512" fill="#333"><g transform="matrix(2 0 0 2 256 256)"><path d="M-32-25c-3 7-24 29-22 51 8 92 36 30 78 53 0 0 75-42 15-110-17-24-2-43-13-59s-30-17-44-2 6 37-14 67"/><path d="M42 21s9-18-8-31c16 17 6 32 6 32h-3C36-13 27 6 14-56 29-73 0-88 0-60h-9c1-24-20-12-8 5-1 37-23 52-23 78-7-18 6-32 6-32s-18 15-7 37 31 17 17 27c22 15 56 5 55-27 1-8 22-5 24-3s-3-4-13-4m-56-78c-7-2-5-11-2-11s8 7 2 11m19 1c-5-7-1-14 4-13s5 13-4 13" fill="#eee"/><g fill="#fc2" stroke="#333" stroke-width="1"><path d="M-41 31l21 30c11 7 5 35-25 21-17-5-31-4-33-13s4-10 3-14c-4-22 14-11 19-22s5-16 15-2M71 45c-4-6 0-17-14-16-6 12-23 24-24 0-10 0-3 24-7 35-9 27 17 29 28 16l26-18c2-3 5-6-9-17m-92-92c-3-6 11-14 16-14s12 4 19 6 4 9 2 10S3-35-5-35s-10-8-16-12"/><path d="M-21-48c8 6 17 11 35-3"/></g><path d="M-10-54c-2 0 1-2 2-1m7 1c1-1-1-2-3-1"/></g></svg>',
      archs: [
        { id: 'x64', label: '64 bits (x64)', keywords: ['x64', 'amd64', 'x86_64'] },
        { id: 'arm64', label: 'ARM64', keywords: ['arm64', 'aarch64'] },
      ],
    },
    {
      id: 'android', label: 'Android',
      keywords: ['android', '.apk'],
      icon: '<svg width="18" height="18" viewBox="0 0 512 512"><path d="M433 320a184 184 0 011 8H74a181 181 0 011-10 180 180 0 0118-54 180 180 0 0113-21 182 182 0 0120-23 182 182 0 0132-26l-11-19-18-32a17 17 0 01-2-13 16 16 0 018-10 16 16 0 017-2 17 17 0 0116 8 10000 10000 0 008 13l11 18 11 19 1 2 6-2a180 180 0 0158-10h2c22 0 44 4 64 11l2 1 1-2 11-19 11-18 8-13a17 17 0 0110-8 17 17 0 016 0 17 17 0 017 2 16 16 0 016 6 17 17 0 012 14l-1 3a9000 9000 0 01-8 13l-11 18-11 19a181 181 0 0132 25 181 181 0 0120 23 182 182 0 0113 21 180 180 0 0118 54v2Z" fill="#34a853"/><path d="M350 276c7-5 8-16 2-25s-17-12-24-7-8 16-2 25 17 12 24 7m-163-7c6-9 5-20-2-25s-18-1-24 7c-6 9-5 20 2 25s18 1 24-7" fill="#202124"/></svg>',
      // Android APKs are built per-ABI (processor architecture) to keep file
      // size down, so the choice actually matters here too. "universal" is
      // the safe fallback that bundles every ABI in one bigger file.
      archsNoteKey: 'dlAndroidNote',
      archs: [
        { id: 'arm64', label: 'ARM64 (arm64-v8a)', subKey: 'dlArchArm64', keywords: ['arm64', 'aarch64', 'arm64-v8a'] },
        { id: 'armv7', label: 'ARM32 (armeabi-v7a)', subKey: 'dlArchArmv7', keywords: ['armeabi-v7a', 'armv7', 'arm32'] },
        { id: 'x86_64', label: 'x86_64', subKey: 'dlArchX86', keywords: ['x86_64', 'x64'] },
        { id: 'universal', label: 'Universelle / Universal', subKey: 'dlArchUniversal', keywords: ['universal'] },
      ],
    },
    {
      id: 'macos', label: 'macOS',
      keywords: ['macos', 'darwin', '.dmg', 'mac.zip'],
      icon: '<svg width="18" height="18" viewBox="0 0 512 512" fill="currentColor"><path d="M183 245c33 0 53 24 53 64s-21 64-53 64-52-25-52-64 20-64 52-64ZM339 395c62 2 86-66 36-89-21-9-50-8-64-22-33-34 58-61 65-12h23c-4-76-151-54-113 20 6 11 20 20 39 24 121 25-2 102-25 30H276c2 30 27 47 63 49ZM271 190a18 18 0 0012-9v9h10V153c0-22-33-22-41-8a14 14 0 00-2 7h10c3-11 23-10 22 2v4l-14 1c-30 1-26 38 3 31ZM183 395c48 0 77-34 77-86s-30-85-77-85-76 32-76 85 29 86 76 86ZM160 190h10V157l2-5c5.085-8.23 17.553-6.36 20 3v35h11V157c0-16 22-16 22-1v34h11V153c0-21-28-22-35-7-4-14-26-13-31-1v-9H160Zm146-38c-12 41 41 53 47 20H343c-5 18-28 9-28-6 0-27 25-26 28-11h10c-4-26-40-24-47-3Zm-24 18c-5 30-52-4 0-4v4Z"/></svg>',
      archs: null,
    },
  ];

  let modal = null;
  let latestRelease = null;
  let fetchPromise = null;

  function fetchLatestRelease() {
    if (fetchPromise) return fetchPromise;
    fetchPromise = fetch(`https://api.github.com/repos/${repo}/releases/latest`)
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error('no release'))))
      .then((data) => {
        latestRelease = data;
        return data;
      });
    return fetchPromise;
  }

  function t(key, fallback) {
    return (window.i18n && i18n.t(key)) || fallback;
  }

  // scores each asset against a set of keywords, returns the best match or null
  function findAsset(assets, keywords) {
    let best = null;
    let bestScore = 0;
    assets.forEach((asset) => {
      const name = asset.name.toLowerCase();
      const score = keywords.reduce((acc, kw) => (name.includes(kw) ? acc + 1 : acc), 0);
      if (score > bestScore) {
        bestScore = score;
        best = asset;
      }
    });
    return bestScore > 0 ? best : null;
  }

  function buildModal() {
    const box = document.createElement('div');
    box.className = 'dl-modal';
    box.id = 'dl-modal';
    box.setAttribute('aria-hidden', 'true');
    box.innerHTML = `
      <div class="dl-modal-box" role="dialog" aria-modal="true" aria-labelledby="dl-modal-title">
        <button type="button" class="dl-modal-close" id="dl-modal-close" aria-label="Fermer">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
        <div id="dl-modal-content"></div>
      </div>`;
    document.body.appendChild(box);
    box.querySelector('#dl-modal-close').addEventListener('click', closeModal);
    box.addEventListener('click', (e) => { if (e.target === box) closeModal(); });
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeModal(); });
    return box;
  }

  function openModal() {
    if (!modal) modal = buildModal();
    renderPlatformStep();
    modal.classList.add('is-open');
    modal.removeAttribute('aria-hidden');
    fetchLatestRelease().catch(() => {}); // warm the cache while the user picks
  }

  function closeModal() {
    if (!modal) return;
    modal.classList.remove('is-open');
    modal.setAttribute('aria-hidden', 'true');
  }

  function withTransition(renderFn) {
    const content = modal.querySelector('#dl-modal-content');
    content.classList.add('is-switching');
    setTimeout(() => {
      renderFn();
      modal.querySelector('#dl-modal-content').classList.remove('is-switching');
    }, 180);
  }

  function renderPlatformStep() {
    const content = modal.querySelector('#dl-modal-content');
    content.innerHTML = `
      <h3 class="dl-modal-title" id="dl-modal-title">${t('dlTitle', 'Télécharger LastStats')}</h3>
      <p class="dl-modal-sub">${t('dlChooseOs', "Choisissez votre système d'exploitation.")}</p>
      <div class="dl-options" id="dl-platform-list"></div>`;
    const list = content.querySelector('#dl-platform-list');
    PLATFORMS.forEach((platform) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'dl-option md-ripple';
      btn.innerHTML = `${platform.icon}<span>${platform.label}</span>`;
      btn.addEventListener('click', () => {
        if (platform.archs) {
          withTransition(() => renderArchStep(platform));
        } else {
          withTransition(() => resolveDownload(platform, null));
        }
      });
      list.appendChild(btn);
    });
  }

  function renderArchStep(platform) {
    const content = modal.querySelector('#dl-modal-content');
    const note = platform.archsNoteKey ? t(platform.archsNoteKey, '') : '';
    content.innerHTML = `
      <h3 class="dl-modal-title" id="dl-modal-title">${platform.label}</h3>
      <p class="dl-modal-sub">${t('dlChooseArch', 'Quel type de processeur ?')}${note ? ` ${note}` : ''}</p>
      <div class="dl-options" id="dl-arch-list"></div>
      <button type="button" class="dl-back">${t('dlBackOs', '← Changer de système')}</button>`;
    const list = content.querySelector('#dl-arch-list');
    platform.archs.forEach((arch) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'dl-option md-ripple';
      const sub = arch.subKey ? t(arch.subKey, '') : '';
      btn.innerHTML = sub
        ? `<span class="dl-option-text"><strong>${arch.label}</strong><small>${sub}</small></span>`
        : `<span>${arch.label}</span>`;
      btn.addEventListener('click', () => withTransition(() => resolveDownload(platform, arch)));
      list.appendChild(btn);
    });
    content.querySelector('.dl-back').addEventListener('click', () => withTransition(renderPlatformStep));
  }

  function renderStatus(message, isError) {
    const content = modal.querySelector('#dl-modal-content');
    content.innerHTML = `
      <h3 class="dl-modal-title" id="dl-modal-title">${t('dlDownloadTitle', 'Téléchargement')}</h3>
      <p class="dl-status${isError ? ' is-error' : ''}">${message}</p>
      <button type="button" class="dl-back">${t('dlBackRetry', '← Retour')}</button>`;
    content.querySelector('.dl-back').addEventListener('click', () => withTransition(renderPlatformStep));
  }

  function resolveDownload(platform, arch) {
    renderStatus(t('dlSearching', 'Recherche de la dernière version…'), false);
    fetchLatestRelease()
      .then((release) => {
        const assets = release.assets || [];
        // narrow to this OS first, then refine by architecture if relevant
        const osMatches = assets.filter((a) =>
          platform.keywords.some((kw) => a.name.toLowerCase().includes(kw))
        );
        const pool = osMatches.length ? osMatches : assets;
        const universal = findAsset(pool, ['universal']);
        const asset = arch ? findAsset(pool, arch.keywords) || universal || pool[0] : pool[0];

        if (!asset) {
          renderStatus(t('dlNoAsset', 'Aucun fichier correspondant trouvé pour cette plateforme. Ouverture de la page des releases…'), true);
          setTimeout(() => window.open(releasesUrl, '_blank', 'noopener'), 1200);
          return;
        }

        renderStatus(`${release.tag_name || ''} — ${asset.name}`.trim());
        window.location.href = asset.browser_download_url;
        setTimeout(closeModal, 600);
      })
      .catch(() => {
        renderStatus(t('dlFetchError', "Impossible de récupérer la dernière version. Ouverture de la page des releases…"), true);
        setTimeout(() => window.open(releasesUrl, '_blank', 'noopener'), 1200);
      });
  }

  trigger.addEventListener('click', openModal);

  // if the language changes while the modal is open, just refresh the
  // current step's text instead of tracking exactly which step we're on
  if (window.i18n) {
    i18n.onChange(() => {
      if (modal && modal.classList.contains('is-open')) renderPlatformStep();
    });
  }
})();
