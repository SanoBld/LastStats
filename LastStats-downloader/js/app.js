'use strict';
// Require login
if (!Auth.isLoggedIn) location.href = 'index.html';

// One entry per downloadable dataset
const TYPES = {
  history: { method: 'user.getRecentTracks', dataKey: 'recenttracks', itemKey: 'track', limit: 200, params: { extended: 0 }, build: Rows.history, labelKey: 'card_history' },
  artists:  { method: 'user.getTopArtists',  dataKey: 'topartists',  itemKey: 'artist', limit: 1000, params: { period: 'overall' }, build: Rows.artists, labelKey: 'card_artists' },
  albums:   { method: 'user.getTopAlbums',   dataKey: 'topalbums',   itemKey: 'album',  limit: 1000, params: { period: 'overall' }, build: Rows.albums,  labelKey: 'card_albums' },
  tracks:   { method: 'user.getTopTracks',   dataKey: 'toptracks',   itemKey: 'track',  limit: 1000, params: { period: 'overall' }, build: Rows.tracks,  labelKey: 'card_tracks' },
};

let currentFormat = 'csv';
let currentPdfStyle = 'simple';
let includeImages = true;
let currentSortOrder = 'desc';
let exportRunning = false;

function updatePdfSubRows() {
  const isPdf = currentFormat === 'pdf';
  document.getElementById('pdf-style-row').classList.toggle('hidden', !isPdf);
  document.getElementById('pdf-images-row').classList.toggle('hidden', !(isPdf && currentPdfStyle === 'pretty'));
}

function initDownloadPage() {
  document.getElementById('hello-username').textContent = Auth.username;

  const avatarEl = document.getElementById('user-avatar');
  if (Auth.avatarUrl) {
    avatarEl.innerHTML = `<img src="${Auth.avatarUrl}" alt="">`;
  } else {
    avatarEl.textContent = (Auth.username[0] || '?').toUpperCase();
  }

  document.getElementById('btn-logout').addEventListener('click', () => {
    Auth.clear();
    location.href = 'index.html';
  });

  // Format switch (csv / xlsx / json / pdf)
  document.querySelectorAll('.format-btn').forEach(b => {
    b.addEventListener('click', () => {
      currentFormat = b.dataset.format;
      document.querySelectorAll('.format-btn').forEach(x => x.classList.toggle('is-active', x === b));
      updatePdfSubRows();
    });
  });

  // PDF style switch (simple / pretty) — only relevant when format is pdf
  document.querySelectorAll('.pdfstyle-btn').forEach(b => {
    b.addEventListener('click', () => {
      currentPdfStyle = b.dataset.pdfstyle;
      document.querySelectorAll('.pdfstyle-btn').forEach(x => x.classList.toggle('is-active', x === b));
      updatePdfSubRows();
    });
  });

  document.getElementById('chk-include-images').addEventListener('change', (e) => {
    includeImages = e.target.checked;
  });

  // Sort order: descending (default, matches Last.fm's own order) or ascending (reversed)
  document.querySelectorAll('.sort-btn').forEach(b => {
    b.addEventListener('click', () => {
      currentSortOrder = b.dataset.sort;
      document.querySelectorAll('.sort-btn').forEach(x => x.classList.toggle('is-active', x === b));
    });
  });

  // One download button per dataset card
  document.querySelectorAll('[data-type]').forEach(btn => {
    btn.addEventListener('click', () => runExport(btn.dataset.type));
  });

  document.getElementById('btn-download-all').addEventListener('click', runExportAll);
}

async function runExport(type) {
  if (exportRunning) return;
  exportRunning = true;
  const cfg = TYPES[type];
  showProgress(t(cfg.labelKey));
  try {
    const items = await LastFM.fetchAll(cfg.method, cfg.dataKey, cfg.itemKey, { ...cfg.params, limit: cfg.limit }, updateProgress);
    const rows  = cfg.build(items);
    if (currentSortOrder === 'asc') {
      rows.reverse();
      if (type === 'history') rows.forEach((r, i) => { r['#'] = i + 1; }); // keep the row counter sequential
    }
    await downloadRows(rows, `laststat-${Auth.username}-${type}`, currentFormat, { title: t(cfg.labelKey), type, pdfStyle: currentPdfStyle, includeImages });
    showToast(t('toast_done'));
  } catch {
    showToast(t('toast_error'), true);
  } finally {
    exportRunning = false;
    hideProgress();
  }
}

async function runExportAll() {
  if (exportRunning) return;
  for (const type of Object.keys(TYPES)) {
    await runExport(type);
    await new Promise(r => setTimeout(r, 300));
  }
}

/* ── Progress overlay ── */
function showProgress(label) {
  document.getElementById('overlay-title').textContent = t('progress_title');
  document.getElementById('overlay-sub').textContent = label;
  document.getElementById('bar-fill').style.width = '0%';
  document.getElementById('overlay-pct').textContent = '0%';
  document.getElementById('progress-overlay').classList.remove('hidden');
}
function updateProgress(page, pages, count) {
  const pct = Math.round((page / pages) * 100);
  document.getElementById('bar-fill').style.width = pct + '%';
  document.getElementById('overlay-pct').textContent = `${pct}% — ${count}`;
}
function hideProgress() {
  document.getElementById('progress-overlay').classList.add('hidden');
}

/* ── Toast ── */
function showToast(msg, isError) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.toggle('is-error', !!isError);
  el.classList.add('show');
  setTimeout(() => el.classList.remove('show'), 2500);
}

document.addEventListener('DOMContentLoaded', initDownloadPage);
