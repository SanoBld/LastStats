// Download modal: OS -> architecture -> format. It fetches the latest GitHub
// release and jumps straight to the exact file the visitor picked. Reads the
// repo from the trigger button's data-repo attribute so it stays reusable.
//
// The file names below MUST match what .github/workflows/build-*.yml produce
// (and what the release notes / the in-app updater look for).
(function () {
  const trigger = document.getElementById('download-trigger');
  if (!trigger) return;

  const repo = trigger.getAttribute('data-repo') || 'SanoBld/LastStats-App';
  const releasesUrl = `https://github.com/${repo}/releases`;

  // File formats: label is language-neutral, subKey is translated (i18n.js).
  const FORMATS = {
    exe:      { label: '.exe — Installer',                   subKey: 'dlFmtExe' },
    zip:      { label: '.zip — Portable',                    subKey: 'dlFmtZip' },
    dmg:      { label: '.dmg — Installer',                   subKey: 'dlFmtDmg' },
    deb:      { label: '.deb — Debian / Ubuntu / Mint',      subKey: 'dlFmtDeb' },
    rpm:      { label: '.rpm — Fedora / openSUSE / RHEL',    subKey: 'dlFmtRpm' },
    appimage: { label: '.AppImage — Any distro',             subKey: 'dlFmtAppImage' },
    script:   { label: 'install-linux.sh — One-line script', subKey: 'dlFmtScript' },
    apk:      { label: '.apk',                               subKey: null },
    ipa:      { label: '.ipa — Unsigned',                    subKey: 'dlFmtIpa' },
  };

  // A file = { fmt, name, fallbacks? }. "fallbacks" are older file names, used
  // only when the latest release predates the current naming.
  const f = (fmt, name, fallbacks) => ({ fmt, name, fallbacks: fallbacks || [] });

  // Linux packages: same set for x64 and arm64.
  const linuxFiles = (arch) => [
    f('deb', `LastStats-linux-${arch}.deb`),
    f('rpm', `LastStats-linux-${arch}.rpm`),
    f('appimage', `LastStats-linux-${arch}.AppImage`),
    f('zip', arch === 'x64' ? 'laststats-linux.zip' : 'laststats-linux-arm64.zip'),
    f('script', 'install-linux.sh'),
  ];

  const macFiles = (suffix) => [
    f('dmg', suffix ? `LastStats-macos-${suffix}.dmg` : 'LastStats-macos.dmg', ['LastStats-macos.dmg']),
    f('zip', suffix ? `laststats-macos-${suffix}.zip` : 'laststats-macos.zip', ['laststats-macos.zip']),
  ];

  const PLATFORMS = [
    {
      id: 'windows', label: 'Windows',
      icon: '<svg width="18" height="18" viewBox="0 0 512 512"><path fill="#2f78d4" d="M96 96H416V247H265V96H247V247H96v18H247V416h18V265H416V416H96"/></svg>',
      archs: [
        { id: 'x64', label: '64 bits (x64)', subKey: 'dlArchPc',
          files: [f('exe', 'LastStats-Setup-x64.exe'), f('zip', 'laststats-windows.zip')] },
        { id: 'arm64', label: 'ARM64', subKey: 'dlArchWinArm',
          files: [f('exe', 'LastStats-Setup-arm64.exe'), f('zip', 'laststats-windows-arm64.zip')] },
      ],
    },
    {
      id: 'linux', label: 'Linux',
      icon: '<svg width="18" height="18" viewBox="0 0 512 512" fill="#333"><g transform="matrix(2 0 0 2 256 256)"><path d="M-32-25c-3 7-24 29-22 51 8 92 36 30 78 53 0 0 75-42 15-110-17-24-2-43-13-59s-30-17-44-2 6 37-14 67"/><path d="M42 21s9-18-8-31c16 17 6 32 6 32h-3C36-13 27 6 14-56 29-73 0-88 0-60h-9c1-24-20-12-8 5-1 37-23 52-23 78-7-18 6-32 6-32s-18 15-7 37 31 17 17 27c22 15 56 5 55-27 1-8 22-5 24-3s-3-4-13-4m-56-78c-7-2-5-11-2-11s8 7 2 11m19 1c-5-7-1-14 4-13s5 13-4 13" fill="#eee"/><g fill="#fc2" stroke="#333" stroke-width="1"><path d="M-41 31l21 30c11 7 5 35-25 21-17-5-31-4-33-13s4-10 3-14c-4-22 14-11 19-22s5-16 15-2M71 45c-4-6 0-17-14-16-6 12-23 24-24 0-10 0-3 24-7 35-9 27 17 29 28 16l26-18c2-3 5-6-9-17m-92-92c-3-6 11-14 16-14s12 4 19 6 4 9 2 10S3-35-5-35s-10-8-16-12"/><path d="M-21-48c8 6 17 11 35-3"/></g><path d="M-10-54c-2 0 1-2 2-1m7 1c1-1-1-2-3-1"/></g></svg>',
      archs: [
        { id: 'x64', label: '64 bits (x64)', subKey: 'dlArchPc', files: linuxFiles('x64') },
        { id: 'arm64', label: 'ARM64', subKey: 'dlArchLinuxArm', files: linuxFiles('arm64') },
      ],
    },
    {
      id: 'android', label: 'Android',
      icon: '<svg width="18" height="18" viewBox="0 0 512 512"><path d="M433 320a184 184 0 011 8H74a181 181 0 011-10 180 180 0 0118-54 180 180 0 0113-21 182 182 0 0120-23 182 182 0 0132-26l-11-19-18-32a17 17 0 01-2-13 16 16 0 018-10 16 16 0 017-2 17 17 0 0116 8 10000 10000 0 008 13l11 18 11 19 1 2 6-2a180 180 0 0158-10h2c22 0 44 4 64 11l2 1 1-2 11-19 11-18 8-13a17 17 0 0110-8 17 17 0 016 0 17 17 0 017 2 16 16 0 016 6 17 17 0 012 14l-1 3a9000 9000 0 01-8 13l-11 18-11 19a181 181 0 0132 25 181 181 0 0120 23 182 182 0 0113 21 180 180 0 0118 54v2Z" fill="#34a853"/><path d="M350 276c7-5 8-16 2-25s-17-12-24-7-8 16-2 25 17 12 24 7m-163-7c6-9 5-20-2-25s-18-1-24 7c-6 9-5 20 2 25s18 1 24-7" fill="#202124"/></svg>',
      // APKs are built per-ABI (processor architecture) to keep file size
      // down, so the choice matters. "universal" bundles every ABI.
      archsNoteKey: 'dlAndroidNote',
      archs: [
        { id: 'arm64', label: 'ARM64 (arm64-v8a)', subKey: 'dlArchArm64',
          files: [f('apk', 'app-arm64-v8a-release.apk')] },
        { id: 'armv7', label: 'ARM32 (armeabi-v7a)', subKey: 'dlArchArmv7',
          files: [f('apk', 'app-armeabi-v7a-release.apk')] },
        { id: 'x86_64', label: 'x86_64', subKey: 'dlArchX86',
          files: [f('apk', 'app-x86_64-release.apk')] },
        { id: 'universal', label: 'Universelle / Universal', subKey: 'dlArchUniversal',
          files: [f('apk', 'app-universal-release.apk')] },
      ],
    },
    {
      id: 'macos', label: 'macOS',
      icon: '<svg width="18" height="18" viewBox="0 0 512 512" fill="currentColor"><path d="M183 245c33 0 53 24 53 64s-21 64-53 64-52-25-52-64 20-64 52-64ZM339 395c62 2 86-66 36-89-21-9-50-8-64-22-33-34 58-61 65-12h23c-4-76-151-54-113 20 6 11 20 20 39 24 121 25-2 102-25 30H276c2 30 27 47 63 49ZM271 190a18 18 0 0012-9v9h10V153c0-22-33-22-41-8a14 14 0 00-2 7h10c3-11 23-10 22 2v4l-14 1c-30 1-26 38 3 31ZM183 395c48 0 77-34 77-86s-30-85-77-85-76 32-76 85 29 86 76 86ZM160 190h10V157l2-5c5.085-8.23 17.553-6.36 20 3v35h11V157c0-16 22-16 22-1v34h11V153c0-21-28-22-35-7-4-14-26-13-31-1v-9H160Zm146-38c-12 41 41 53 47 20H343c-5 18-28 9-28-6 0-27 25-26 28-11h10c-4-26-40-24-47-3Zm-24 18c-5 30-52-4 0-4v4Z"/></svg>',
      archs: [
        { id: 'arm64', label: 'Apple Silicon (M1+)', subKey: 'dlArchAppleSilicon', files: macFiles('arm64') },
        { id: 'x64', label: 'Intel', subKey: 'dlArchIntel', files: macFiles('x64') },
        { id: 'universal', label: 'Universelle / Universal', subKey: 'dlArchMacUniversal', files: macFiles('') },
      ],
    },
    {
      id: 'ios', label: 'iOS',
      icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="7" y="2" width="10" height="20" rx="2.5"/><path d="M11 18h2"/></svg>',
      archs: null,
      noteKey: 'dlIosNote',            // shown once the download starts
      files: [f('ipa', 'LastStats-ios.ipa')],
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

  // exact (case-insensitive) file name lookup, trying the fallbacks in order
  function findAsset(assets, file) {
    for (const name of [file.name, ...file.fallbacks]) {
      const hit = assets.find((a) => a.name.toLowerCase() === name.toLowerCase());
      if (hit) return hit;
    }
    return null;
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
    // force a reflow so the CSS transition also runs on the very first open
    void modal.offsetWidth;
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

  // one button, with an optional small second line
  function optionButton(html, onClick) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'dl-option md-ripple';
    btn.innerHTML = html;
    btn.addEventListener('click', onClick);
    return btn;
  }

  function labelWithSub(label, sub) {
    return sub
      ? `<span class="dl-option-text"><strong>${label}</strong><small>${sub}</small></span>`
      : `<span>${label}</span>`;
  }

  // Step 1: operating system
  function renderPlatformStep() {
    const content = modal.querySelector('#dl-modal-content');
    content.innerHTML = `
      <h3 class="dl-modal-title" id="dl-modal-title">${t('dlTitle', 'Télécharger LastStats')}</h3>
      <p class="dl-modal-sub">${t('dlChooseOs', "Choisissez votre système d'exploitation.")}</p>
      <div class="dl-options" id="dl-platform-list"></div>`;
    const list = content.querySelector('#dl-platform-list');
    PLATFORMS.forEach((platform) => {
      list.appendChild(optionButton(`${platform.icon}<span>${platform.label}</span>`, () => {
        if (platform.archs) withTransition(() => renderArchStep(platform));
        else withTransition(() => chooseFile(platform, null));
      }));
    });
  }

  // Step 2: processor architecture
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
      const sub = arch.subKey ? t(arch.subKey, '') : '';
      list.appendChild(optionButton(labelWithSub(arch.label, sub),
        () => withTransition(() => chooseFile(platform, arch))));
    });
    content.querySelector('.dl-back').addEventListener('click', () => withTransition(renderPlatformStep));
  }

  // Only one file for this choice -> download it; several -> ask the format.
  function chooseFile(platform, arch) {
    const files = arch ? arch.files : platform.files;
    if (files.length === 1) resolveDownload(platform, files[0]);
    else renderFormatStep(platform, arch, files);
  }

  // Step 3: file format (installer, portable, .deb, .rpm, ...)
  function renderFormatStep(platform, arch, files) {
    const content = modal.querySelector('#dl-modal-content');
    const title = arch ? `${platform.label} — ${arch.label}` : platform.label;
    content.innerHTML = `
      <h3 class="dl-modal-title" id="dl-modal-title">${title}</h3>
      <p class="dl-modal-sub">${t('dlChooseFormat', 'Quel format ?')}</p>
      <div class="dl-options" id="dl-format-list"></div>
      <button type="button" class="dl-back">${t('dlBack', '← Retour')}</button>`;
    const list = content.querySelector('#dl-format-list');
    files.forEach((file) => {
      const fmt = FORMATS[file.fmt];
      const sub = fmt.subKey ? t(fmt.subKey, '') : '';
      list.appendChild(optionButton(labelWithSub(fmt.label, sub),
        () => withTransition(() => resolveDownload(platform, file))));
    });
    content.querySelector('.dl-back').addEventListener('click', () =>
      withTransition(() => (arch ? renderArchStep(platform) : renderPlatformStep())));
  }

  function renderStatus(message, isError) {
    const content = modal.querySelector('#dl-modal-content');
    content.innerHTML = `
      <h3 class="dl-modal-title" id="dl-modal-title">${t('dlDownloadTitle', 'Téléchargement')}</h3>
      <p class="dl-status${isError ? ' is-error' : ''}">${message}</p>
      <button type="button" class="dl-back">${t('dlBackRetry', '← Retour')}</button>`;
    content.querySelector('.dl-back').addEventListener('click', () => withTransition(renderPlatformStep));
  }

  function resolveDownload(platform, file) {
    renderStatus(t('dlSearching', 'Recherche de la dernière version…'), false);
    fetchLatestRelease()
      .then((release) => {
        const asset = findAsset(release.assets || [], file);

        if (!asset) {
          renderStatus(t('dlNoAsset', 'Aucun fichier correspondant trouvé pour cette plateforme. Ouverture de la page des releases…'), true);
          setTimeout(() => window.open(releasesUrl, '_blank', 'noopener'), 1200);
          return;
        }

        const summary = `${release.tag_name || ''} — ${asset.name}`.trim();
        const note = platform.noteKey ? t(platform.noteKey, '') : '';
        renderStatus(note ? `${summary}<br><small>${note}</small>` : summary);
        window.location.href = asset.browser_download_url;
        // keep the modal open when there is an instruction to read (iOS)
        if (!note) setTimeout(closeModal, 600);
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
