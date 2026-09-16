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
      icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3 5.5 10.5 4.4v7.1H3zm0 13 7.5 1.1v-7.1H3zM11.4 4.3 21 3v8.4h-9.6zm0 8.6H21V21l-9.6-1.3z"/></svg>',
      // desktop app: architecture actually matters
      archs: [
        { id: 'x64', label: '64 bits (x64)', keywords: ['x64', 'amd64', 'win64'] },
        { id: 'arm64', label: 'ARM64', keywords: ['arm64', 'aarch64'] },
      ],
    },
    {
      id: 'linux', label: 'Linux',
      keywords: ['linux', '.appimage', '.deb', '.tar.gz', '.tar.xz'],
      icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2c-1.5 0-2.8 1.6-2.8 4 0 1.4.4 2.4.9 3.3-1.8.9-4.1 2.7-4.1 5.2 0 1.1.4 2 1 2.7-.3.4-.5.9-.5 1.4 0 1.3 1.4 2.4 3.5 2.4.7 0 1.4-.1 2-.4.6.3 1.3.4 2 .4 2.1 0 3.5-1.1 3.5-2.4 0-.5-.2-1-.5-1.4.6-.7 1-1.6 1-2.7 0-2.5-2.3-4.3-4.1-5.2.5-.9.9-1.9.9-3.3 0-2.4-1.3-4-2.8-4z"/></svg>',
      archs: [
        { id: 'x64', label: '64 bits (x64)', keywords: ['x64', 'amd64', 'x86_64'] },
        { id: 'arm64', label: 'ARM64', keywords: ['arm64', 'aarch64'] },
      ],
    },
    {
      id: 'android', label: 'Android',
      keywords: ['android', '.apk'],
      icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M17.6 9.5 19 7.2c.1-.2 0-.4-.2-.5s-.4 0-.5.2l-1.4 2.4c-1.2-.6-2.5-.9-3.9-.9s-2.7.3-3.9.9L7.7 6.9c-.1-.2-.3-.3-.5-.2s-.3.3-.2.5l1.4 2.3C5.9 10.9 4.5 13.2 4.5 16h15c0-2.8-1.4-5.1-1.9-6.5zM8.5 13.5c-.6 0-1-.4-1-1s.4-1 1-1 1 .4 1 1-.4 1-1 1zm7 0c-.6 0-1-.4-1-1s.4-1 1-1 1 .4 1 1-.4 1-1 1z"/></svg>',
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
      icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M16.5 1.5c.1 1.1-.3 2.2-1 3-.7.8-1.9 1.5-3 1.4-.1-1.1.4-2.2 1.1-3 .7-.8 1.9-1.4 2.9-1.4zm3.3 16.4c-.4 1-.7 1.5-1.2 2.3-.7 1.1-1.7 2.5-3 2.5-1.1 0-1.4-.7-2.9-.7s-1.9.7-2.9.7c-1.3 0-2.2-1.3-2.9-2.4-2-3-2.4-6.6-1-8.9.8-1.3 2.2-2.1 3.5-2.1 1.2 0 2 .7 3 .7.9 0 1.6-.7 3-.7 1.1 0 2.3.6 3.1 1.7-2.7 1.5-2.3 5.4.3 6.6z"/></svg>',
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
          renderArchStep(platform);
        } else {
          resolveDownload(platform, null);
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
      btn.addEventListener('click', () => resolveDownload(platform, arch));
      list.appendChild(btn);
    });
    content.querySelector('.dl-back').addEventListener('click', renderPlatformStep);
  }

  function renderStatus(message, isError) {
    const content = modal.querySelector('#dl-modal-content');
    content.innerHTML = `
      <h3 class="dl-modal-title" id="dl-modal-title">${t('dlDownloadTitle', 'Téléchargement')}</h3>
      <p class="dl-status${isError ? ' is-error' : ''}">${message}</p>
      <button type="button" class="dl-back">${t('dlBackRetry', '← Retour')}</button>`;
    content.querySelector('.dl-back').addEventListener('click', renderPlatformStep);
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
