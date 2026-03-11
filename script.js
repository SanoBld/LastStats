'use strict';

/* ============================================================
   LASTSTATS — SCRIPT v4
   i18n fully linked to i18n.js · Session persistence ·
   Auto-login · Background history · Minimizable progress
   ============================================================ */

// ── Constants ──
const LASTFM_URL    = 'https://ws.audioscrobbler.com/2.0/';
const CACHE_TTL     = 30 * 60 * 1000;
const TOP_LIMIT     = 50;
const DISPLAY_LIMIT = 20;
const DEFAULT_IMG   = '2a96cbd8b46e442fc41c2b86b821562f';

const CHART_PALETTE = [
  '#6366f1','#8b5cf6','#a855f7','#d946ef','#ec4899',
  '#f43f5e','#f97316','#eab308','#22c55e','#06b6d4',
  '#3b82f6','#0ea5e9','#14b8a6','#84cc16','#78716c',
];

// Dynamic month/day helpers (lang-aware)
function MONTHS()       { return (window.I18N?.arr('months'))       || ['January','February','March','April','May','June','July','August','September','October','November','December']; }
function MONTHS_SHORT() { return (window.I18N?.arr('months_short')) || ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; }
function DAYS()         { return (window.I18N?.arr('days'))         || ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']; }

// Fallback t() if i18n.js not yet loaded
if (typeof window.t !== 'function') window.t = (k) => k;

// ── Global state ──
const APP = {
  apiKey:          '',
  username:        '',
  userInfo:        null,
  charts:          {},
  topArtistsData:  [],
  topAlbumsData:   [],
  topTracksData:   [],
  regYear:         new Date().getFullYear() - 5,
  currentTheme:    'dark',
  currentAccent:   'purple',
  fullHistory:     null,
  streakData:      null,
  language:        'fr',
  artistsLayout:   'grid',
  albumsLayout:    'grid',
  tracksLayout:    'list',
  artistsPage:     1,
  artistsPeriod:   'overall',
  artistsLoading:  false,
  artistsExhausted:false,
  artistsTotalPages:1,
  albumsPage:      1,
  albumsPeriod:    'overall',
  albumsLoading:   false,
  albumsExhausted: false,
  albumsTotalPages:1,
  tracksPage:      1,
  tracksPeriod:    'overall',
  tracksLoading:   false,
  tracksExhausted: false,
  tracksTotalPages:1,
};

/* ============================================================
   CACHE (localStorage)
   ============================================================ */
const Cache = {
  prefix: 'ls2_',

  _key(method, params) {
    return this.prefix + APP.username + '_' + method + '_' + JSON.stringify(params);
  },

  get(method, params = {}) {
    try {
      const raw = localStorage.getItem(this._key(method, params));
      if (!raw) return null;
      const { data, ts } = JSON.parse(raw);
      if (Date.now() - ts > CACHE_TTL) { localStorage.removeItem(this._key(method, params)); return null; }
      return data;
    } catch { return null; }
  },

  set(method, params = {}, data) {
    try {
      localStorage.setItem(this._key(method, params), JSON.stringify({ data, ts: Date.now() }));
    } catch {
      this._purge();
      try { localStorage.setItem(this._key(method, params), JSON.stringify({ data, ts: Date.now() })); } catch {}
    }
  },

  _purge() {
    const keys = Object.keys(localStorage).filter(k => k.startsWith(this.prefix));
    keys.sort().slice(0, Math.min(30, keys.length)).forEach(k => localStorage.removeItem(k));
  },

  clear() {
    Object.keys(localStorage).filter(k => k.startsWith(this.prefix)).forEach(k => localStorage.removeItem(k));
  },
};

/* ============================================================
   API
   ============================================================ */
const API = {
  async call(method, params = {}, skipCache = false) {
    if (!skipCache) {
      const cached = Cache.get(method, params);
      if (cached) return cached;
    }
    const data = await this._fetch(method, params);
    Cache.set(method, params, data);
    return data;
  },

  async _fetch(method, params = {}) {
    const url = new URL(LASTFM_URL);
    url.searchParams.set('method', method);
    url.searchParams.set('api_key', APP.apiKey);
    url.searchParams.set('user', APP.username);
    url.searchParams.set('format', 'json');
    Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, String(v)));

    const res = await fetch(url.toString());
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    if (data.error) throw new Error(data.message || `API error ${data.error}`);
    return data;
  },

  async getMonthScrobbles(year, month) {
    const from = Math.floor(new Date(year, month, 1).getTime() / 1000);
    const to   = Math.floor(new Date(year, month + 1, 0, 23, 59, 59).getTime() / 1000);
    try {
      const data = await this.call('user.getRecentTracks', { from, to, limit: 1 });
      return parseInt(data.recenttracks?.['@attr']?.total || 0);
    } catch { return 0; }
  },

  async fetchAllPages(onProgress, yearFrom = null, yearTo = null) {
    const allTracks = [];
    let page = 1, totalPages = 1;
    const baseParams = { limit: 200, extended: 0 };
    if (yearFrom) baseParams.from = yearFrom;
    if (yearTo)   baseParams.to   = yearTo;

    do {
      const params = { ...baseParams, page };
      let data = null;
      for (let attempt = 0; attempt < 3; attempt++) {
        try { data = await this._fetch('user.getRecentTracks', params); break; }
        catch (e) { if (attempt === 2) throw e; await sleep(1000 * (attempt + 1)); }
      }
      const attr = data.recenttracks?.['@attr'] || {};
      totalPages = parseInt(attr.totalPages || 1);
      const raw  = data.recenttracks?.track || [];
      const tracks = Array.isArray(raw) ? raw : [raw];
      for (const t of tracks) { if (!t['@attr']?.nowplaying) allTracks.push(t); }
      if (onProgress) onProgress(page, totalPages, allTracks.length);
      page++;
      if (page <= totalPages) await sleep(150);
    } while (page <= totalPages);

    return allTracks;
  },
};

/* ============================================================
   UTILITIES
   ============================================================ */
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function formatNum(n) {
  if (n === null || n === undefined || n === '') return '—';
  return Number(n).toLocaleString();
}

function formatDate(unixTs) {
  if (!unixTs) return '—';
  return new Date(unixTs * 1000).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' });
}

function timeAgo(unixTs) {
  if (!unixTs) return '';
  const diff = Date.now() - unixTs * 1000;
  const days = Math.floor(diff / 86400000);
  if (days === 0) {
    const h = Math.floor(diff / 3600000);
    if (h === 0) return t('time_few_min');
    return t('time_hours', h);
  }
  if (days === 1)  return t('time_yesterday');
  if (days < 30)  return t('time_days', days);
  if (days < 365) return t('time_months', Math.floor(days / 30));
  return t('time_years', Math.floor(days / 365));
}

function nameToGradient(name = '?') {
  let hash = 5381;
  for (let i = 0; i < name.length; i++) hash = ((hash << 5) + hash) ^ name.charCodeAt(i);
  const h1 = Math.abs(hash) % 360;
  const h2 = (h1 + 42) % 360;
  return `linear-gradient(135deg, hsl(${h1},62%,38%), hsl(${h2},70%,52%))`;
}

function isDefaultImg(url = '') {
  return !url || url.includes(DEFAULT_IMG) || url.length < 10;
}

function destroyChart(id) {
  if (APP.charts[id]) { APP.charts[id].destroy(); delete APP.charts[id]; }
}

function animateValue(el, from, to, duration = 800) {
  const start = performance.now();
  const update = (now) => {
    const p = Math.min((now - start) / duration, 1);
    const ease = 1 - Math.pow(1 - p, 3);
    el.textContent = formatNum(Math.round(from + (to - from) * ease));
    if (p < 1) requestAnimationFrame(update);
  };
  requestAnimationFrame(update);
}

function showToast(msg, type = 'success') {
  const toastEl = document.getElementById('toast');
  const ico     = document.getElementById('toast-icon');
  if (!toastEl) return;
  document.getElementById('toast-txt').textContent = msg;
  ico.className  = type === 'error' ? 'fas fa-times-circle' : 'fas fa-check-circle';
  ico.style.color= type === 'error' ? '#f87171' : '#22c55e';
  toastEl.classList.add('show');
  clearTimeout(toastEl._timer);
  toastEl._timer = setTimeout(() => toastEl.classList.remove('show'), 3200);
}

function showSetupError(msg) {
  const el = document.getElementById('setup-err');
  if (!el) return;
  document.getElementById('setup-err-txt').textContent = msg;
  el.classList.remove('hidden');
}

function escHtml(str = '') {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function errMsg(e) {
  return `<p style="color:var(--text-muted);grid-column:1/-1;padding:20px">
    <i class="fas fa-exclamation-triangle" style="color:#f97316"></i> ${escHtml(e.message)}
  </p>`;
}

function estimateListenTime(scrobbles) {
  const totalMin = Math.round(scrobbles * 3.5);
  const hours    = Math.floor(totalMin / 60);
  const minutes  = totalMin % 60;
  if (hours > 0) return `≈ ${formatNum(hours)}h ${minutes}min`;
  return `≈ ${minutes} min`;
}

/* ── Skeletons ── */
function skeletonMusicCards(n = 8) {
  return Array(n).fill(0).map((_, i) => `
    <div class="music-card sk" style="animation-delay:${i * 0.04}s">
      <div class="music-card-img" style="height:160px"><div class="sk-ln" style="width:100%;height:100%;border-radius:0"></div></div>
      <div class="music-card-body"><div class="sk-ln w80"></div><div class="sk-ln w60 mt8"></div></div>
    </div>`).join('');
}

function skeletonTrackItems(n = 10) {
  return Array(n).fill(0).map((_, i) => `
    <div class="track-item sk" style="animation-delay:${i * 0.03}s">
      <div class="sk-ln" style="width:24px;height:24px;border-radius:50%"></div>
      <div style="flex:1;display:flex;flex-direction:column;gap:6px">
        <div class="sk-ln w80"></div><div class="sk-ln w50"></div>
      </div>
    </div>`).join('');
}

/* ── Chart theme helpers ── */
function getThemeColors() {
  const isDark = APP.currentTheme === 'dark'
    || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches);
  return {
    grid:   isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.06)',
    text:   isDark ? '#64748b' : '#64748b',
    bg:     isDark ? '#131320' : '#ffffff',
    isDark,
  };
}

function baseChartOpts(extras = {}) {
  const c = getThemeColors();
  return {
    responsive: true, maintainAspectRatio: false,
    animation: { duration: 600, easing: 'easeOutQuart' },
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: c.isDark ? 'rgba(15,15,35,.95)' : 'rgba(255,255,255,.95)',
        titleColor: c.isDark ? '#e2e8f0' : '#0f172a',
        bodyColor:  c.isDark ? '#94a3b8' : '#475569',
        borderColor: 'rgba(99,102,241,.2)', borderWidth: 1,
        cornerRadius: 8, padding: 10,
      },
    },
    scales: {
      x: { grid: { color: c.grid }, ticks: { color: c.text, font: { size: 11 } } },
      y: { grid: { color: c.grid }, ticks: { color: c.text, font: { size: 11 } } },
    },
    ...extras,
  };
}

function updateAllChartThemes() {
  Object.values(APP.charts).forEach(chart => {
    if (!chart?.options) return;
    const c = getThemeColors();
    if (chart.options.scales) {
      Object.values(chart.options.scales).forEach(s => {
        if (s.grid)  s.grid.color  = c.grid;
        if (s.ticks) s.ticks.color = c.text;
      });
    }
    if (chart.options.plugins?.tooltip) {
      chart.options.plugins.tooltip.backgroundColor = c.isDark ? 'rgba(15,15,35,.95)' : 'rgba(255,255,255,.95)';
    }
    chart.update('none');
  });
}

/* ============================================================
   SESSION PERSISTENCE
   Always save/restore credentials to localStorage
   ============================================================ */
function saveSession() {
  if (APP.username) localStorage.setItem('ls_username', APP.username);
  if (APP.apiKey)   localStorage.setItem('ls_apikey',   APP.apiKey);
}

function clearSession() {
  localStorage.removeItem('ls_username');
  localStorage.removeItem('ls_apikey');
}

function loadSavedCredentials() {
  return {
    username: localStorage.getItem('ls_username') || '',
    apiKey:   localStorage.getItem('ls_apikey')   || '',
  };
}

/* ============================================================
   THEME
   ============================================================ */
function setTheme(theme) {
  APP.currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  localStorage.setItem('ls_theme', theme);
  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === theme));
  updateAllChartThemes();
  // Re-apply accent for light/dark variants
  const accent = APP.currentAccent || localStorage.getItem('ls_accent') || 'purple';
  if (accent && accent !== 'dynamic') setAccent(accent);
}

function applyTheme(theme) {
  APP.currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === theme));
}

function toggleApiKey() {
  const inp = document.getElementById('input-apikey');
  const ico = document.getElementById('eye-icon');
  if (!inp) return;
  inp.type   = inp.type === 'password' ? 'text' : 'password';
  ico.className = inp.type === 'password' ? 'fas fa-eye' : 'fas fa-eye-slash';
}

/* ============================================================
   INITIALISATION
   ============================================================ */
async function initApp(usernameOverride, apiKeyOverride) {
  // Support both manual form submission and auto-login
  const username = usernameOverride || (document.getElementById('input-username')?.value || '').trim();
  const apiKey   = apiKeyOverride   || (document.getElementById('input-apikey')?.value   || '').trim();

  if (document.getElementById('setup-err'))
    document.getElementById('setup-err').classList.add('hidden');

  if (!username) { showSetupError(t('setup_err_username')); return; }
  if (!apiKey || apiKey.length < 30) { showSetupError(t('setup_err_apikey')); return; }

  APP.apiKey   = apiKey;
  APP.username = username;

  const btn = document.getElementById('load-btn');
  if (btn) { btn.disabled = true; btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${t('setup_btn_loading')}`; }

  try {
    const info = await API.call('user.getInfo', {}, true);
    APP.userInfo = info.user;
    APP.regYear  = new Date(parseInt(info.user.registered?.unixtime || 0) * 1000).getFullYear() || new Date().getFullYear() - 5;

    // Always save session
    saveSession();

    const theme = localStorage.getItem('ls_theme') || 'dark';
    applyTheme(theme);

    // Hide setup, show app
    const setupScreen = document.getElementById('setup-screen');
    const appEl       = document.getElementById('app');
    if (setupScreen) setupScreen.classList.add('hidden');
    if (appEl)       appEl.classList.remove('hidden');

    setupProfileUI();
    await loadDashboard();

    // Restore last section
    const savedSection = localStorage.getItem('ls_section');
    if (savedSection && document.getElementById('s-' + savedSection)) {
      nav(savedSection);
    }

    // Parallel loading (non-blocking)
    Promise.all([
      loadTopArtists('overall'),
      loadTopAlbums('overall'),
      loadTopTracks('overall'),
    ]).then(() => loadMoodTags());

    setupChartsSection();
    setupWrappedSection();
    loadAdvancedStats();
    initPeriodSelectors();
    pollNowPlaying();
    loadVersus();

    // Restore persisted settings
    syncSettingsFields();
    restoreBadgesFromStorage();
    const savedAccent = localStorage.getItem('ls_accent') || 'purple';
    APP.currentAccent = savedAccent;
    if (savedAccent !== 'dynamic') setAccent(savedAccent);

    setArtistsLayout(APP.artistsLayout);
    setAlbumsLayout(APP.albumsLayout);
    setTracksLayout(APP.tracksLayout);

    const lang = localStorage.getItem('ls_lang') || 'fr';
    APP.language = lang;
    setLanguage(lang);

    // Background history auto-update
    _scheduleBackgroundHistoryFetch();

  } catch (err) {
    const msg = err.message.toLowerCase().includes('user not found') || err.message.includes('Invalid API')
      ? t('setup_err_invalid')
      : t('setup_err_generic', err.message);
    showSetupError(msg);
  } finally {
    if (btn) { btn.disabled = false; btn.innerHTML = `<i class="fas fa-chart-bar"></i> ${t('setup_btn_launch')}`; }
  }
}

/* ── Background history auto-fetch ── */
let _bgHistoryTimer = null;

function _scheduleBackgroundHistoryFetch() {
  clearTimeout(_bgHistoryTimer);
  // Auto-fetch after 3 seconds if no history loaded yet
  _bgHistoryTimer = setTimeout(async () => {
    if (!APP.fullHistory || !APP.fullHistory.length) {
      await fetchFullHistory(true); // true = background mode
    }
  }, 3000);
}

/* ============================================================
   DOMContentLoaded — auto-login + init
   ============================================================ */
window.addEventListener('DOMContentLoaded', () => {
  // Injecte les styles des boutons share (complète style.css sans le modifier)
  const shareStyle = document.createElement('style');
  shareStyle.textContent = `
    .track-play-btn.share,
    .mc-play-btn.share {
      background: var(--accent-lt) !important;
      color: var(--accent) !important;
      border: 1px solid var(--border-glow) !important;
    }
    .track-play-btn.share:hover,
    .mc-play-btn.share:hover {
      background: var(--accent) !important;
      color: var(--accent-on) !important;
      transform: scale(1.12);
    }
  `;
  document.head.appendChild(shareStyle);
  // Apply theme immediately
  const theme = localStorage.getItem('ls_theme') || 'dark';
  document.documentElement.dataset.theme = theme;
  APP.currentTheme = theme;

  // Restore language
  APP.language = localStorage.getItem('ls_lang') || (window.I18N?.getLang?.() || 'fr');

  // Restore layout preferences
  APP.artistsLayout = localStorage.getItem('ls_artists_layout') || 'grid';
  APP.albumsLayout  = localStorage.getItem('ls_albums_layout')  || 'grid';
  APP.tracksLayout  = localStorage.getItem('ls_tracks_layout')  || 'list';

  // Pre-fill form fields if saved
  const { username, apiKey } = loadSavedCredentials();
  if (document.getElementById('input-username')) document.getElementById('input-username').value = username;
  if (document.getElementById('input-apikey'))   document.getElementById('input-apikey').value   = apiKey;

  // Auto-login if credentials are saved
  if (username && apiKey) {
    // Small delay to let DOM settle
    setTimeout(() => {
      initApp(username, apiKey);
    }, 150);
  }

  // PWA install prompt
  let _deferredInstall = null;
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    _deferredInstall = e;
    const btn = document.getElementById('pwa-install-btn');
    if (btn) btn.classList.remove('hidden');
  });

  const installBtn = document.getElementById('pwa-install-btn');
  if (installBtn) {
    installBtn.addEventListener('click', async () => {
      if (!_deferredInstall) return;
      _deferredInstall.prompt();
      const { outcome } = await _deferredInstall.userChoice;
      if (outcome === 'accepted') showToast(t('toast_installed'));
      _deferredInstall = null;
    });
  }

  const swBtn = document.getElementById('sw-update-btn');
  if (swBtn) swBtn.addEventListener('click', forceSwUpdate);
});

/* ============================================================
   NAVIGATION
   ============================================================ */
const NAV_TITLE_KEYS = {
  dashboard:     'nav_dashboard',
  'top-artists': 'nav_top_artists',
  'top-albums':  'nav_top_albums',
  'top-tracks':  'nav_top_tracks',
  charts:        'nav_charts',
  vizplus:       'nav_vizplus',
  badges:        'nav_badges',
  obscurity:     'nav_obscurity',
  wrapped:       'nav_wrapped',
  advanced:      'nav_advanced',
  settings:      'nav_settings',
};

function nav(section) {
  const doNav = () => {
    document.querySelectorAll('.nav-lnk').forEach(el =>
      el.classList.toggle('active', el.dataset.s === section)
    );
    document.querySelectorAll('.app-sec').forEach(el => el.classList.remove('active'));
    document.getElementById('s-' + section)?.classList.add('active');

    const titleKey = NAV_TITLE_KEYS[section];
    document.getElementById('hd-title').textContent = titleKey ? t(titleKey) : section;

    localStorage.setItem('ls_section', section);
    if (window.innerWidth <= 1024) closeSb();

    // Lazy load section-specific features
    if (section === 'vizplus')   loadVizPlus();
    if (section === 'obscurity') loadObscurityScore();
  };

  if (document.startViewTransition) {
    document.startViewTransition(doNav);
  } else {
    doNav();
  }
}

function openSb()  {
  document.getElementById('sidebar')?.classList.add('open');
  document.getElementById('sidebar-ov')?.classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeSb() {
  document.getElementById('sidebar')?.classList.remove('open');
  document.getElementById('sidebar-ov')?.classList.remove('open');
  document.body.style.overflow = '';
}

/* ============================================================
   LANGUAGE
   ============================================================ */
function setLanguage(lang) {
  if (!window.I18N?.setLang) return;
  window.I18N.setLang(lang);
  APP.language = lang;

  document.querySelectorAll('.lang-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.lang === lang)
  );

  // Update nav labels
  document.querySelectorAll('.nav-lnk[data-s]').forEach(el => {
    const key  = NAV_TITLE_KEYS[el.dataset.s];
    const span = el.querySelector('span:not(.nav-bdg)');
    if (key && span) span.textContent = t(key);
  });

  // Update current title
  const activeSection = document.querySelector('.app-sec.active')?.id?.replace('s-', '');
  if (activeSection) {
    const key = NAV_TITLE_KEYS[activeSection];
    if (key) document.getElementById('hd-title').textContent = t(key);
  }

  showToast(t('toast_lang_changed'));
}

/* ============================================================
   PROFILE
   ============================================================ */
function setupProfileUI() {
  const u = APP.userInfo;
  if (!u) return;

  const nameEl    = document.getElementById('sb-name');
  const playsEl   = document.getElementById('sb-plays');
  const countryEl = document.getElementById('sb-country');
  if (nameEl)    nameEl.textContent    = u.name || APP.username;
  if (playsEl)   playsEl.textContent   = formatNum(u.playcount) + ' ' + t('scrobbles');
  if (countryEl && u.country) countryEl.textContent = u.country;

  const imgUrl = u.image?.find(i => i.size === 'medium')?.['#text'] || '';
  const sbAv   = document.getElementById('sb-av');
  const letter = (u.name || '?')[0].toUpperCase();

  if (sbAv) {
    if (imgUrl && !isDefaultImg(imgUrl)) {
      sbAv.innerHTML = `<img src="${imgUrl}" alt="Avatar"
        onerror="this.outerHTML='<div style=\\'width:100%;height:100%;background:${nameToGradient(u.name)};display:flex;align-items:center;justify-content:center;font-weight:700;color:white\\'>${letter}</div>'">`;
    } else {
      sbAv.innerHTML = `<div style="width:100%;height:100%;background:${nameToGradient(u.name)};display:flex;align-items:center;justify-content:center;font-weight:700;color:white;font-size:1.1rem">${letter}</div>`;
    }
  }

  const miniUser = document.getElementById('hd-mini-user');
  if (miniUser) miniUser.textContent = '@' + (u.name || APP.username);
}

/* ── Now Playing polling ── */
let _npTimer = null;
async function pollNowPlaying() {
  clearTimeout(_npTimer);
  try {
    const data   = await API._fetch('user.getRecentTracks', { limit: 1, extended: 1 });
    const tracks = data.recenttracks?.track;
    if (!tracks) return;
    const last = Array.isArray(tracks) ? tracks[0] : tracks;
    const wrap = document.getElementById('now-playing-wrap');

    if (last['@attr']?.nowplaying) {
      const trackName  = last.name || '—';
      const artistName = last.artist?.name || last.artist?.['#text'] || '—';
      document.getElementById('np-track').textContent  = trackName;
      document.getElementById('np-artist').textContent = artistName;

      const artEl = document.getElementById('np-art');
      const img   = last.image?.find(i => i.size === 'medium')?.['#text'];
      if (img && !isDefaultImg(img)) {
        artEl.innerHTML = `<img src="${img}" alt="" style="width:100%;height:100%;object-fit:cover">`;
        if (APP.currentAccent === 'dynamic') _applyColorThiefFromUrl(img);
      } else {
        artEl.innerHTML = '';
      }

      const q     = encodeURIComponent(`${trackName} ${artistName}`);
      const spBtn = document.getElementById('np-spotify-btn');
      const ytBtn = document.getElementById('np-youtube-btn');
      if (spBtn) spBtn.href = `spotify:search:${encodeURIComponent(trackName + ' ' + artistName)}`;
      if (ytBtn) ytBtn.href = `https://www.youtube.com/results?search_query=${q}`;

      wrap?.classList.remove('hidden');
      _npTimer = setTimeout(pollNowPlaying, 30000);
    } else {
      wrap?.classList.add('hidden');
      _npTimer = setTimeout(pollNowPlaying, 60000);
    }
  } catch {
    _npTimer = setTimeout(pollNowPlaying, 120000);
  }
}

/* ============================================================
   DASHBOARD
   ============================================================ */
async function loadDashboard() {
  const u = APP.userInfo;
  if (!u) return;

  const currentYear = new Date().getFullYear();
  const regTs       = parseInt(u.registered?.unixtime || 0);
  const daysSince   = regTs ? Math.floor((Date.now() - regTs * 1000) / 86400000) : 1;
  const totalPlay   = parseInt(u.playcount || 0);
  const avgPerDay   = daysSince > 0 ? (totalPlay / daysSince).toFixed(1) : 0;

  let uniqueArtists = '…', uniqueAlbums = '…', uniqueTracks = '…';
  try {
    const [a, b, c] = await Promise.all([
      API.call('user.getTopArtists', { period: 'overall', limit: 1 }),
      API.call('user.getTopAlbums',  { period: 'overall', limit: 1 }),
      API.call('user.getTopTracks',  { period: 'overall', limit: 1 }),
    ]);
    uniqueArtists = formatNum(a.topartists?.['@attr']?.total);
    uniqueAlbums  = formatNum(b.topalbums?.['@attr']?.total);
    uniqueTracks  = formatNum(c.toptracks?.['@attr']?.total);
  } catch {}

  let lastScrobble = '—';
  try {
    const recent = await API.call('user.getRecentTracks', { limit: 1 });
    const tracks  = recent.recenttracks?.track;
    if (tracks) {
      const last = Array.isArray(tracks) ? tracks[0] : tracks;
      lastScrobble = last['@attr']?.nowplaying
        ? t('stat_now_playing')
        : timeAgo(parseInt(last.date?.uts || 0));
    }
  } catch {}

  const listenMinutes = Math.round(totalPlay * 3.5);
  const listenHours   = Math.floor(listenMinutes / 60);
  const listenRem     = listenMinutes % 60;
  const listenTimeStr = listenHours > 0 ? `≈ ${formatNum(listenHours)}h ${listenRem}min` : `≈ ${listenRem} min`;

  const cards = [
    { icon: '🎵', value: totalPlay,          label: t('stat_total_scrobbles'), sub: t('stat_avg_day', avgPerDay),           color: '#6366f1' },
    { icon: '🎤', value: uniqueArtists,       label: t('stat_artists'),         sub: t('stat_since_start'),                  color: '#8b5cf6', noAnim: true },
    { icon: '💿', value: uniqueAlbums,        label: t('stat_albums'),          sub: t('stat_since_start'),                  color: '#a855f7', noAnim: true },
    { icon: '🎼', value: uniqueTracks,        label: t('stat_tracks'),          sub: t('stat_since_start'),                  color: '#ec4899', noAnim: true },
    { icon: '📅', value: formatDate(regTs),   label: t('stat_member_since'),    sub: t('stat_active_days', formatNum(daysSince)), color: '#f97316', noAnim: true },
    { icon: '⏱️', value: lastScrobble,        label: t('stat_last_scrobble'),   sub: u.url ? `last.fm/user/${u.name}` : '',  color: '#22c55e', noAnim: true },
  ];

  const ltCard = document.getElementById('stat-card-listen-time');
  if (ltCard) {
    const valEl = ltCard.querySelector('.stat-card-value');
    const subEl = ltCard.querySelector('.stat-card-sub');
    if (valEl) valEl.textContent = listenTimeStr;
    if (subEl) subEl.textContent = t('stat_listen_estimate', formatNum(totalPlay));
  }

  document.getElementById('stat-grid').innerHTML = cards.map((c, i) => `
    <div class="stat-card" style="--card-accent:${c.color};animation-delay:${i * 0.05}s">
      <div class="stat-card-icon">${c.icon}</div>
      <div class="stat-card-value" id="sv-${i}" style="color:${c.color}">${c.noAnim ? c.value : '0'}</div>
      <div class="stat-card-label">${c.label}</div>
      <div class="stat-card-sub">${c.sub}</div>
    </div>`).join('');

  const scrobbleEl = document.getElementById('sv-0');
  if (scrobbleEl) animateValue(scrobbleEl, 0, totalPlay, 1000);

  loadDashMonthlyChart(currentYear);
  loadDashArtistsChart();
}

async function loadDashMonthlyChart(year) {
  const yrEl = document.getElementById('dash-yr');
  if (yrEl) yrEl.textContent = year;

  const [first, second] = await Promise.all([
    Promise.all(Array(6).fill(0).map((_, i) => API.getMonthScrobbles(year, i))),
    Promise.all(Array(6).fill(0).map((_, i) => API.getMonthScrobbles(year, i + 6))),
  ]);
  const counts = [...first, ...second];

  destroyChart('dash-monthly');
  const c = getThemeColors();
  APP.charts['dash-monthly'] = new Chart(document.getElementById('dash-monthly'), {
    type: 'bar',
    data: {
      labels: MONTHS_SHORT(),
      datasets: [{
        data: counts,
        backgroundColor: counts.map((v, i) => `${CHART_PALETTE[i % CHART_PALETTE.length]}99`),
        borderColor:     counts.map((_, i) => CHART_PALETTE[i % CHART_PALETTE.length]),
        borderWidth: 1, borderRadius: 5,
      }],
    },
    options: {
      ...baseChartOpts(),
      plugins: {
        ...baseChartOpts().plugins,
        tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } },
      },
      scales: {
        x: { grid: { display: false }, ticks: { color: c.text, font: { size: 10 } } },
        y: { grid: { color: c.grid },  ticks: { color: c.text, font: { size: 10 } } },
      },
    },
  });
}

async function loadDashArtistsChart() {
  try {
    const data    = await API.call('user.getTopArtists', { period: 'overall', limit: 5 });
    const artists = data.topartists?.artist || [];
    if (!artists.length) return;

    destroyChart('dash-artists');
    const c = getThemeColors();
    APP.charts['dash-artists'] = new Chart(document.getElementById('dash-artists'), {
      type: 'doughnut',
      data: {
        labels: artists.map(a => a.name),
        datasets: [{
          data: artists.map(a => parseInt(a.playcount)),
          backgroundColor: CHART_PALETTE.slice(0, 5),
          borderWidth: 2,
          borderColor: c.isDark ? '#07071a' : '#f1f5f9',
          hoverOffset: 6,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { display: true, position: 'right', labels: { color: c.text, font: { size: 11 }, boxWidth: 12, padding: 8 } },
          tooltip: { callbacks: { label: ctx => ` ${ctx.label}: ${formatNum(ctx.raw)}` } },
        },
        cutout: '62%',
        animation: { duration: 700 },
      },
    });
  } catch (e) { console.warn('dash-artists chart:', e); }
}

/* ============================================================
   VERSUS
   ============================================================ */
async function loadVersus() {
  const vsBody = document.getElementById('vs-body');
  if (!vsBody) return;

  try {
    const now       = new Date();
    const currYear  = now.getFullYear();
    const currMonth = now.getMonth();
    const prevMonth = currMonth === 0 ? 11 : currMonth - 1;
    const prevYear  = currMonth === 0 ? currYear - 1 : currYear;

    const [currScrobbles, prevScrobbles] = await Promise.all([
      API.getMonthScrobbles(currYear, currMonth),
      API.getMonthScrobbles(prevYear, prevMonth),
    ]);

    const scrobbleDiff = currScrobbles - prevScrobbles;
    const scrobblePct  = prevScrobbles > 0 ? ((scrobbleDiff / prevScrobbles) * 100).toFixed(1) : null;

    let currArtists = null, prevArtists = null;
    try {
      const [ca, pa] = await Promise.all([
        API.call('user.getTopArtists', { period: '1month', limit: 1 }),
        API.call('user.getTopArtists', { period: '3month', limit: 1 }),
      ]);
      currArtists = parseInt(ca.topartists?.['@attr']?.total || 0);
      prevArtists = parseInt(pa.topartists?.['@attr']?.total || 0);
    } catch {}

    function arrowBadge(diff, pct) {
      if (pct === null || diff === 0) return `<span class="vs-arrow flat">${t('versus_stable')}</span>`;
      const cls  = diff > 0 ? 'up' : 'down';
      const icon = diff > 0 ? '▲' : '▼';
      const sign = diff > 0 ? '+' : '';
      return `<span class="vs-arrow ${cls}">${icon} ${sign}${pct}%</span>`;
    }

    const MONTHS_ARR = MONTHS();
    let html = `
      <div class="vs-metric">
        <span class="vs-label">🎵 ${t('scrobbles').charAt(0).toUpperCase() + t('scrobbles').slice(1)}</span>
        <div class="vs-values">
          <span class="vs-curr">${formatNum(currScrobbles)}</span>
          ${arrowBadge(scrobbleDiff, scrobblePct)}
        </div>
      </div>
      <div class="vs-prev-row">
        <span class="vs-prev-txt">${formatNum(prevScrobbles)} ${MONTHS_ARR[prevMonth] || ''}</span>
      </div>`;

    if (currArtists !== null) {
      const artDiff = currArtists - prevArtists;
      const artPct  = prevArtists > 0 ? ((artDiff / prevArtists) * 100).toFixed(1) : null;
      html += `
        <div class="vs-metric" style="margin-top:10px">
          <span class="vs-label">🎤 ${t('artists').charAt(0).toUpperCase() + t('artists').slice(1)}</span>
          <div class="vs-values">
            <span class="vs-curr">${formatNum(currArtists)}</span>
            ${arrowBadge(artDiff, artPct)}
          </div>
        </div>`;
    }

    html += `<div class="vs-months">${MONTHS_ARR[currMonth] || ''} <span>vs</span> ${MONTHS_ARR[prevMonth] || ''}</div>`;
    vsBody.innerHTML = html;

  } catch {
    if (vsBody) vsBody.innerHTML = `<p class="vs-na">${t('versus_unavailable')}</p>`;
  }
}

/* ============================================================
   MOOD TAGS
   ============================================================ */
async function loadMoodTags() {
  const tagsEl = document.getElementById('mood-tags');
  if (!tagsEl) return;

  try {
    if (!APP.topArtistsData.length) {
      const d = await API.call('user.getTopArtists', { period: 'overall', limit: 10 });
      APP.topArtistsData = d.topartists?.artist || [];
    }

    const top10 = APP.topArtistsData.slice(0, 10);
    const tagScores = new Map();

    const IGNORED = new Set(['seen live','favorites','favourite','love','awesome','beautiful','epic',
      'amazing','classic','favourite music','my favourite','under 2000 listeners',
      'all','featured','good','new','old','best','cool','hot','great','perfect']);

    const tagResults = await Promise.allSettled(
      top10.map(a => API.call('artist.getTopTags', { artist: a.name }))
    );

    tagResults.forEach((result, i) => {
      if (result.status !== 'fulfilled') return;
      const tags = result.value.toptags?.tag || [];
      const artistWeight = 10 - i;
      tags.slice(0, 8).forEach((tag, j) => {
        const name = tag.name?.toLowerCase().trim();
        if (!name || name.length < 2 || IGNORED.has(name)) return;
        const score = (parseInt(tag.count) || 50) * artistWeight * (8 - j);
        tagScores.set(name, (tagScores.get(name) || 0) + score);
      });
    });

    const top5 = [...tagScores.entries()].sort((a, b) => b[1] - a[1]).slice(0, 5);

    if (!top5.length) { tagsEl.innerHTML = `<p class="mood-na">${t('mood_none')}</p>`; return; }

    tagsEl.innerHTML = top5.map(([tag], i) => {
      const label = tag.charAt(0).toUpperCase() + tag.slice(1);
      return `<span class="mood-tag rank-${i + 1}">#${escHtml(label)}</span>`;
    }).join('');

  } catch (e) {
    console.warn('loadMoodTags:', e);
    if (tagsEl) tagsEl.innerHTML = `<p class="mood-na">${t('mood_error')}</p>`;
  }
}

/* ============================================================
   LISTENING STREAK
   ============================================================ */
function calcStreak(tracks) {
  const daySet = new Set();
  for (const t of tracks) {
    const ts = parseInt(t.date?.uts || 0);
    if (!ts) continue;
    const d = new Date(ts * 1000);
    daySet.add(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`);
  }

  const sorted = [...daySet].sort();
  if (!sorted.length) return { best: 0, current: 0 };

  let best = 1, streak = 1;
  for (let i = 1; i < sorted.length; i++) {
    const diff = Math.round((new Date(sorted[i]) - new Date(sorted[i - 1])) / 86400000);
    if (diff === 1) { streak++; if (streak > best) best = streak; }
    else streak = 1;
  }

  const todayMs  = new Date(); todayMs.setHours(0, 0, 0, 0);
  const todayStr = `${todayMs.getFullYear()}-${String(todayMs.getMonth() + 1).padStart(2, '0')}-${String(todayMs.getDate()).padStart(2, '0')}`;
  const yestMs   = new Date(todayMs - 86400000);
  const yestStr  = `${yestMs.getFullYear()}-${String(yestMs.getMonth() + 1).padStart(2, '0')}-${String(yestMs.getDate()).padStart(2, '0')}`;

  const rev = [...sorted].reverse();
  let current = 0;
  if (rev[0] === todayStr || rev[0] === yestStr) {
    current = 1;
    for (let i = 1; i < rev.length; i++) {
      const diff = Math.round((new Date(rev[i - 1]) - new Date(rev[i])) / 86400000);
      if (diff === 1) current++;
      else break;
    }
  }

  return { best, current };
}

function updateStreakUI(streakData) {
  const bestEl = document.getElementById('streak-best');
  const currEl = document.getElementById('streak-curr');
  const hintEl = document.getElementById('streak-hint');

  if (bestEl) bestEl.textContent = streakData.best;
  if (currEl) currEl.textContent = streakData.current;
  if (hintEl) {
    if (streakData.current > 0) {
      hintEl.textContent = streakData.current === streakData.best
        ? t('streak_on_record')
        : t('streak_ongoing', streakData.best);
    } else {
      hintEl.textContent = t('streak_calc', formatNum(APP.fullHistory?.length || 0));
    }
  }
}

/* ============================================================
   HEATMAP
   ============================================================ */
function renderHeatmap(hourCounts) {
  const el = document.getElementById('heatmap-grid');
  if (!el) return;

  document.getElementById('heatmap-empty')?.remove();
  const max   = Math.max(...hourCounts, 1);
  const total = hourCounts.reduce((a, b) => a + b, 0);

  const cells = hourCounts.map((count, h) => {
    const intensity = count / max;
    const r = Math.round(199 + (67  - 199) * intensity);
    const g = Math.round(210 + (56  - 210) * intensity);
    const b = Math.round(254 + (202 - 254) * intensity);
    const alpha = 0.15 + intensity * 0.85;
    const bg    = `rgba(${r},${g},${b},${alpha})`;
    const textC = intensity > 0.45 ? 'rgba(255,255,255,.95)' : 'rgba(200,195,240,.8)';
    const pct   = total > 0 ? ((count / total) * 100).toFixed(1) : 0;
    return `
      <div class="heatmap-cell" style="background:${bg};color:${textC}"
           title="${h}h–${h + 1}h : ${formatNum(count)} ${t('scrobbles')} (${pct}%)">
        <span class="hm-hour">${h}h</span>
        <span class="hm-val">${count > 9999 ? Math.round(count / 1000) + 'k' : count > 0 ? count : ''}</span>
      </div>`;
  }).join('');

  const scaleStops = [0.1, 0.3, 0.5, 0.7, 0.9].map(v => {
    const r = Math.round(199 + (67 - 199) * v);
    const g = Math.round(210 + (56 - 210) * v);
    const b = Math.round(254 + (202 - 254) * v);
    return `<div style="width:28px;height:10px;border-radius:3px;background:rgba(${r},${g},${b},${0.15 + v * 0.85})"></div>`;
  }).join('');

  el.innerHTML = `
    <div class="heatmap-cells">${cells}</div>
    <div class="heatmap-legend">
      <span>${t('heatmap_calm')}</span>
      <div class="heatmap-scale">${scaleStops}</div>
      <span>${t('heatmap_intense')}</span>
    </div>`;
}

/* ============================================================
   TOP ARTISTS
   ============================================================ */
APP.artistsLayout    = localStorage.getItem('ls_artists_layout') || 'grid';
APP.artistsPage      = 1;
APP.artistsPeriod    = 'overall';
APP.artistsLoading   = false;
APP.artistsExhausted = false;
APP.artistsTotalPages= 1;
let _artistsObserver = null;

function setArtistsLayout(layout) {
  APP.artistsLayout = layout;
  localStorage.setItem('ls_artists_layout', layout);
  const grid = document.getElementById('artists-grid');
  if (grid) {
    grid.className = grid.className.replace(/\blayout-\S+/g, '').trim();
    grid.classList.add('layout-' + layout);
  }
  document.querySelectorAll('#artists-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === layout)
  );
  if (APP.topArtistsData.length && grid) {
    grid.innerHTML = APP.topArtistsData
      .slice(0, APP.artistsPage * 50)
      .map((a, i) => _buildArtistCard(a, i + 1))
      .join('');
  }
}

function _buildArtistCard(a, rank) {
  const letter  = (a.name || '?')[0].toUpperCase();
  const bg      = nameToGradient(a.name);
  const spQ     = encodeURIComponent(a.name);
  const ytQ     = encodeURIComponent(a.name);
  const imgId   = `artist-img-r${rank}`;
  const safeUrl = (a.url || '#').replace(/'/g, '%27');
  const plays   = parseInt(a.playcount || 0);
  const delay   = Math.min(rank % 20, 10) * 0.04;

  const heroHtml = `
    <div class="artist-hero-card" style="animation-delay:${delay}s"
         onclick="openArtistModal('${escHtml(a.name).replace(/'/g, "\\'")}','${safeUrl}',${plays})">
      <div class="artist-hero-fallback" id="${imgId}-fallback" style="background:${bg}">${letter}</div>
      <img class="artist-hero-img" id="${imgId}" alt="${escHtml(a.name)}" style="display:none" loading="lazy">
      <div class="artist-hero-overlay"></div>
      <div class="artist-hero-rank">${rank}</div>
      <div class="artist-hero-body">
        <div class="artist-hero-name">${escHtml(a.name)}</div>
        <div class="artist-hero-plays">${formatNum(a.playcount)} ${t('plays')}</div>
      </div>
      <div class="artist-hero-actions">
        <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" title="Spotify"><i class="fab fa-spotify"></i></a>
        <a class="mc-play-btn yt" href="https://www.youtube.com/results?search_query=${ytQ}" target="_blank" rel="noopener" onclick="event.stopPropagation()" title="YouTube"><i class="fab fa-youtube"></i></a>
        <button class="mc-play-btn share" onclick="event.stopPropagation();shareArtist(${JSON.stringify(a.name)},${plays},'${safeUrl}')" title="Partager"><i class="fas fa-share-alt"></i></button>
      </div>
    </div>`;

  const listHtml = `
    <div class="music-card" style="animation-delay:${delay}s"
         onclick="openArtistModal('${escHtml(a.name).replace(/'/g, "\\'")}','${safeUrl}',${plays})">
      <div class="music-card-img" style="aspect-ratio:1">
        <div class="spotify-cover" id="${imgId}-cover" style="background:${bg}">
          <span class="sc-letter">${letter}</span>
          <span class="sc-name">${escHtml(a.name)}</span>
        </div>
        <div class="music-card-rank">${rank}</div>
        <div class="music-card-actions">
          <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" title="Spotify"><i class="fab fa-spotify"></i></a>
          <a class="mc-play-btn yt" href="https://www.youtube.com/results?search_query=${ytQ}" target="_blank" rel="noopener" onclick="event.stopPropagation()" title="YouTube"><i class="fab fa-youtube"></i></a>
          <button class="mc-play-btn share" onclick="event.stopPropagation();shareArtist(${JSON.stringify(a.name)},${plays},'${safeUrl}')" title="Partager"><i class="fas fa-share-alt"></i></button>
        </div>
      </div>
      <div class="music-card-body">
        <div class="music-card-name" title="${escHtml(a.name)}">${escHtml(a.name)}</div>
        <div class="music-card-plays">${formatNum(a.playcount)} ${t('plays')}</div>
      </div>
    </div>`;

  const layout   = APP.artistsLayout || 'grid';
  const html     = layout === 'grid' ? heroHtml : listHtml;
  const targetId = layout === 'grid' ? imgId : `${imgId}-cover`;

  setTimeout(() => {
    if (layout === 'grid') {
      getArtistImage(a.name).then(imgUrl => {
        if (!imgUrl) return;
        const imgEl      = document.getElementById(imgId);
        const fallbackEl = document.getElementById(`${imgId}-fallback`);
        if (imgEl) { imgEl.src = imgUrl; imgEl.style.display = 'block'; imgEl.onerror = () => { imgEl.style.display = 'none'; }; }
        if (fallbackEl) fallbackEl.style.display = 'none';
      });
    } else {
      injectArtistImage(a.name, targetId, bg, letter);
    }
  }, rank * 80);

  return html;
}

async function loadTopArtists(period) {
  APP.artistsPage      = 1;
  APP.artistsPeriod    = period;
  APP.artistsLoading   = false;
  APP.artistsExhausted = false;

  const grid     = document.getElementById('artists-grid');
  const loader   = document.getElementById('artists-page-loader');
  const sentinel = document.getElementById('artists-scroll-sentinel');

  grid.className = `music-grid layout-${APP.artistsLayout}`;
  grid.innerHTML = skeletonMusicCards(12);
  if (loader)   loader.classList.add('hidden');

  if (_artistsObserver) { _artistsObserver.disconnect(); _artistsObserver = null; }

  document.querySelectorAll('#artists-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === APP.artistsLayout)
  );

  try {
    const data    = await API.call('user.getTopArtists', { period, limit: 50, page: 1 });
    const artists = data.topartists?.artist || [];
    APP.topArtistsData    = artists;
    APP.artistsTotalPages = parseInt(data.topartists?.['@attr']?.totalPages || 1);
    grid.innerHTML        = artists.map((a, i) => _buildArtistCard(a, i + 1)).join('');

    if (APP.artistsTotalPages > 1 && sentinel) {
      _artistsObserver = new IntersectionObserver(
        entries => { if (entries[0].isIntersecting) _loadMoreArtists(); },
        { rootMargin: '200px' }
      );
      _artistsObserver.observe(sentinel);
    }
  } catch (e) { grid.innerHTML = errMsg(e); }
}

async function _loadMoreArtists() {
  if (APP.artistsLoading || APP.artistsExhausted) return;
  if (APP.artistsPage >= APP.artistsTotalPages) { APP.artistsExhausted = true; return; }

  APP.artistsLoading = true;
  APP.artistsPage++;

  const grid   = document.getElementById('artists-grid');
  const loader = document.getElementById('artists-page-loader');
  if (loader) loader.classList.remove('hidden');

  try {
    const data    = await API.call('user.getTopArtists', { period: APP.artistsPeriod, limit: 50, page: APP.artistsPage });
    const artists = data.topartists?.artist || [];
    if (!artists.length) { APP.artistsExhausted = true; return; }
    const startRank = (APP.artistsPage - 1) * 50 + 1;
    artists.forEach((a, i) => grid.insertAdjacentHTML('beforeend', _buildArtistCard(a, startRank + i)));
    APP.topArtistsData = [...APP.topArtistsData, ...artists];
  } catch (e) { console.warn('_loadMoreArtists:', e); }
  finally {
    APP.artistsLoading = false;
    if (loader) loader.classList.add('hidden');
  }
}

/* ============================================================
   TOP ALBUMS
   ============================================================ */
APP.albumsLayout    = localStorage.getItem('ls_albums_layout') || 'grid';
APP.albumsPage      = 1;
APP.albumsPeriod    = 'overall';
APP.albumsLoading   = false;
APP.albumsExhausted = false;
APP.albumsTotalPages= 1;
let _albumsObserver = null;

function setAlbumsLayout(layout) {
  APP.albumsLayout = layout;
  localStorage.setItem('ls_albums_layout', layout);
  const grid = document.getElementById('albums-grid');
  if (grid) {
    grid.className = grid.className.replace(/\blayout-\S+/g, '').trim();
    grid.classList.add('layout-' + layout);
  }
  document.querySelectorAll('#albums-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === layout)
  );
}

function _buildAlbumCard(a, rank) {
  const imgUrl   = a.image?.find(img => img.size === 'extralarge')?.['#text'] || '';
  const hasImg   = !isDefaultImg(imgUrl);
  const letter   = (a.name || '?')[0].toUpperCase();
  const bg       = nameToGradient((a.name || '') + (a.artist?.name || ''));
  const safeUrl  = (a.url || '#').replace(/'/g, '%27');
  const artistNm = a.artist?.name || '';
  return `
    <div class="music-card" style="animation-delay:${Math.min((rank - 1) % 20, 10) * 0.04}s" onclick="window.open('${safeUrl}','_blank')">
      <div class="music-card-img" style="height:160px">
        ${hasImg ? `<img src="${imgUrl}" alt="${escHtml(a.name)}" loading="lazy"
                       onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
        <div class="spotify-cover" style="background:${bg};display:${hasImg ? 'none' : 'flex'}">
          <span class="sc-letter">${letter}</span>
          <span class="sc-name">${escHtml(a.name)}</span>
        </div>
        <div class="music-card-rank">${rank}</div>
        <div class="music-card-actions">
          <button class="mc-play-btn share" onclick="event.stopPropagation();shareAlbum(${JSON.stringify(a.name)},${JSON.stringify(artistNm)},${a.playcount},'${safeUrl}')" title="Partager"><i class="fas fa-share-alt"></i></button>
        </div>
      </div>
      <div class="music-card-body">
        <div class="music-card-name" title="${escHtml(a.name)}">${escHtml(a.name)}</div>
        <div class="music-card-artist">${escHtml(artistNm)}</div>
        <div class="music-card-plays">${formatNum(a.playcount)} ${t('plays')}</div>
      </div>
    </div>`;
}

async function loadTopAlbums(period) {
  APP.albumsPage      = 1;
  APP.albumsPeriod    = period;
  APP.albumsLoading   = false;
  APP.albumsExhausted = false;

  const grid     = document.getElementById('albums-grid');
  const loader   = document.getElementById('albums-page-loader');
  const sentinel = document.getElementById('albums-scroll-sentinel');

  grid.className = `music-grid layout-${APP.albumsLayout}`;
  grid.innerHTML = skeletonMusicCards(12);
  if (loader) loader.classList.add('hidden');

  if (_albumsObserver) { _albumsObserver.disconnect(); _albumsObserver = null; }

  try {
    const data   = await API.call('user.getTopAlbums', { period, limit: 50, page: 1 });
    const albums = data.topalbums?.album || [];
    APP.topAlbumsData    = albums;
    APP.albumsTotalPages = parseInt(data.topalbums?.['@attr']?.totalPages || 1);
    grid.innerHTML       = albums.map((a, i) => _buildAlbumCard(a, i + 1)).join('');

    if (APP.albumsTotalPages > 1 && sentinel) {
      _albumsObserver = new IntersectionObserver(
        entries => { if (entries[0].isIntersecting) _loadMoreAlbums(); },
        { rootMargin: '200px' }
      );
      _albumsObserver.observe(sentinel);
    }
  } catch (e) { grid.innerHTML = errMsg(e); }
}

async function _loadMoreAlbums() {
  if (APP.albumsLoading || APP.albumsExhausted) return;
  if (APP.albumsPage >= APP.albumsTotalPages) { APP.albumsExhausted = true; return; }

  APP.albumsLoading = true;
  APP.albumsPage++;

  const grid   = document.getElementById('albums-grid');
  const loader = document.getElementById('albums-page-loader');
  if (loader) loader.classList.remove('hidden');

  try {
    const data   = await API.call('user.getTopAlbums', { period: APP.albumsPeriod, limit: 50, page: APP.albumsPage });
    const albums = data.topalbums?.album || [];
    if (!albums.length) { APP.albumsExhausted = true; return; }
    const startRank = (APP.albumsPage - 1) * 50 + 1;
    albums.forEach((a, i) => grid.insertAdjacentHTML('beforeend', _buildAlbumCard(a, startRank + i)));
    APP.topAlbumsData = [...APP.topAlbumsData, ...albums];
  } catch (e) { console.warn('_loadMoreAlbums:', e); }
  finally {
    APP.albumsLoading = false;
    if (loader) loader.classList.add('hidden');
  }
}

/* ============================================================
   TOP TRACKS
   ============================================================ */
APP.tracksLayout    = localStorage.getItem('ls_tracks_layout') || 'list';
APP.tracksPage      = 1;
APP.tracksPeriod    = 'overall';
APP.tracksLoading   = false;
APP.tracksExhausted = false;
APP.tracksTotalPages= 1;
let _tracksObserver = null;

function setTracksLayout(layout) {
  APP.tracksLayout = layout;
  localStorage.setItem('ls_tracks_layout', layout);
  const list = document.getElementById('tracks-list');
  if (list) list.className = `tracks-list layout-${layout}`;
  document.querySelectorAll('#tracks-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === layout)
  );
  if (APP.topTracksData.length && list) {
    const maxPlay = APP.topTracksData.length > 0 ? parseInt(APP.topTracksData[0].playcount) : 1;
    list.innerHTML = APP.topTracksData.slice(0, APP.tracksPage * 50).map((t, i) => _buildTrackItem(t, i + 1, maxPlay)).join('');
    _resolveTrackImages(APP.topTracksData.slice(0, APP.tracksPage * 50), 1);
  }
}

function _buildTrackItem(track, rank, maxPlay) {
  const pct         = ((parseInt(track.playcount) / Math.max(maxPlay, 1)) * 100).toFixed(1);
  const medal       = rank <= 3 ? ['🥇','🥈','🥉'][rank - 1] : rank;
  const spQ         = encodeURIComponent(`${track.name} ${track.artist?.name || ''}`);
  const ytQ         = encodeURIComponent(`${track.name} ${track.artist?.name || ''}`);
  const imgUrl      = track.image?.find(im => im.size === 'medium')?.['#text'] || track.image?.find(im => im.size === 'small')?.['#text'] || '';
  const hasCover    = !isDefaultImg(imgUrl);
  const coverBg     = nameToGradient(track.name + (track.artist?.name || ''));
  const coverLetter = (track.name || '?')[0].toUpperCase();
  const delay       = Math.min((rank - 1) % 20, 10) * 0.025;

  const coverElId = `track-cover-r${rank}`;

  return `
    <div class="track-item" style="animation-delay:${delay}s"
         onclick="window.open('${(track.url || '#').replace(/'/g, '%27')}','_blank')">
      <div class="track-cover" id="${coverElId}">
        ${hasCover ? `<img src="${imgUrl}" alt="${escHtml(track.name)}" loading="lazy"
               onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
        <div style="width:100%;height:100%;background:${coverBg};
                    display:${hasCover ? 'none' : 'flex'};align-items:center;
                    justify-content:center;font-size:1.2rem;font-weight:900;color:white">${coverLetter}</div>
      </div>
      <div class="track-rank">${medal}</div>
      <div class="track-info">
        <div class="track-name" title="${escHtml(track.name)}">
          <i class="fas fa-music" style="font-size:.65rem;opacity:.35;margin-right:5px"></i>${escHtml(track.name)}
        </div>
        <div class="track-artist">${escHtml(track.artist?.name || '')}</div>
      </div>
      <div class="track-bar-wrap">
        <div class="track-bar" style="width:${pct}%"></div>
      </div>
      <div class="track-plays">${formatNum(track.playcount)}</div>
      <div class="track-play-btns">
        <a class="track-play-btn sp" href="spotify:search:${spQ}" title="Spotify" onclick="event.stopPropagation()"><i class="fab fa-spotify"></i></a>
        <a class="track-play-btn yt" href="https://www.youtube.com/results?search_query=${ytQ}" target="_blank" rel="noopener" title="YouTube" onclick="event.stopPropagation()"><i class="fab fa-youtube"></i></a>
        <button class="track-play-btn share" title="Partager" onclick="event.stopPropagation();shareTrack(${JSON.stringify(track.name)},${JSON.stringify(track.artist?.name||'')},${track.playcount},'${(track.url||'').replace(/'/g,'%27')}')"><i class="fas fa-share-alt"></i></button>
      </div>
    </div>`;
}

/* ── Résolution d'image pour un track via API Last.fm ──
   Essaie dans l'ordre : image objet → album.getInfo → track.getInfo
   Injecte l'image dans le DOM une fois obtenue (lazy, non-bloquant)
*/
const _trackImgCache = new Map();

async function _resolveTrackImage(track, rank) {
  const coverEl = document.getElementById(`track-cover-r${rank}`);
  if (!coverEl) return;

  // 1. L'objet track a déjà une image non-default → rien à faire
  const existingImg = track.image?.find(im => im.size === 'medium')?.['#text'] ||
                      track.image?.find(im => im.size === 'small')?.['#text'] || '';
  if (!isDefaultImg(existingImg)) return; // image déjà rendue par _buildTrackItem

  // 2. Clé de cache
  const cacheKey = `${(track.artist?.name||'').toLowerCase()}::${(track.album?.['#text']||track.name||'').toLowerCase()}`;
  if (_trackImgCache.has(cacheKey)) {
    const cached = _trackImgCache.get(cacheKey);
    if (cached) _injectTrackCoverImg(coverEl, cached);
    return;
  }

  try {
    let imgUrl = null;

    // 3a. Essai via album.getInfo si on connaît l'album
    const albumTitle = track.album?.['#text'] || '';
    if (albumTitle) {
      try {
        const d = await API.call('album.getInfo', {
          artist: track.artist?.name || '',
          album:  albumTitle,
          autocorrect: 1,
        });
        imgUrl = d.album?.image?.find(i => i.size === 'extralarge')?.['#text'] ||
                 d.album?.image?.find(i => i.size === 'large')?.['#text'] || '';
        if (isDefaultImg(imgUrl)) imgUrl = null;
      } catch {}
    }

    // 3b. Fallback : track.getInfo
    if (!imgUrl) {
      try {
        const d = await API.call('track.getInfo', {
          artist: track.artist?.name || '',
          track:  track.name || '',
          autocorrect: 1,
        });
        imgUrl = d.track?.album?.image?.find(i => i.size === 'extralarge')?.['#text'] ||
                 d.track?.album?.image?.find(i => i.size === 'large')?.['#text'] ||
                 d.track?.album?.image?.find(i => i.size === 'medium')?.['#text'] || '';
        if (isDefaultImg(imgUrl)) imgUrl = null;
      } catch {}
    }

    _trackImgCache.set(cacheKey, imgUrl || null);
    if (imgUrl) _injectTrackCoverImg(coverEl, imgUrl);

  } catch { _trackImgCache.set(cacheKey, null); }
}

function _injectTrackCoverImg(coverEl, imgUrl) {
  if (!coverEl || !imgUrl) return;
  // Vérifie si un img est déjà présent
  if (coverEl.querySelector('img[src]')) return;
  const img = document.createElement('img');
  img.src     = imgUrl;
  img.alt     = '';
  img.loading = 'lazy';
  img.style.cssText = 'width:100%;height:100%;object-fit:cover;border-radius:inherit;position:absolute;inset:0';
  img.onerror = () => img.remove();
  img.onload  = () => {
    // Cache l'avatar gradient derrière
    const fallback = coverEl.querySelector('div');
    if (fallback) fallback.style.display = 'none';
  };
  coverEl.style.position = 'relative';
  coverEl.prepend(img);
}

/* Lance la résolution d'images pour un lot de tracks (throttlé, non-bloquant) */
function _resolveTrackImages(tracks, startRank = 1) {
  // On espace les appels pour ne pas spammer l'API
  tracks.forEach((track, i) => {
    if (isDefaultImg(
      track.image?.find(im => im.size === 'medium')?.['#text'] ||
      track.image?.find(im => im.size === 'small')?.['#text'] || ''
    )) {
      setTimeout(() => _resolveTrackImage(track, startRank + i), i * 120);
    }
  });
}

async function loadTopTracks(period) {
  APP.tracksPage      = 1;
  APP.tracksPeriod    = period;
  APP.tracksLoading   = false;
  APP.tracksExhausted = false;

  const list     = document.getElementById('tracks-list');
  const loader   = document.getElementById('tracks-page-loader');
  const sentinel = document.getElementById('tracks-scroll-sentinel');

  list.className = `tracks-list layout-${APP.tracksLayout}`;
  list.innerHTML = skeletonTrackItems(12);
  if (loader) loader.classList.add('hidden');

  if (_tracksObserver) { _tracksObserver.disconnect(); _tracksObserver = null; }

  document.querySelectorAll('#tracks-layout-toggle .layout-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.layout === APP.tracksLayout)
  );

  try {
    const data    = await API.call('user.getTopTracks', { period, limit: 50, page: 1 });
    const tracks  = data.toptracks?.track || [];
    APP.topTracksData    = tracks;
    APP.tracksTotalPages = parseInt(data.toptracks?.['@attr']?.totalPages || 1);
    const maxPlay        = tracks.length > 0 ? parseInt(tracks[0].playcount) : 1;
    list.innerHTML       = tracks.map((t, i) => _buildTrackItem(t, i + 1, maxPlay)).join('');

    // Résolution asynchrone des images manquantes (non-bloquant)
    _resolveTrackImages(tracks, 1);

    if (APP.tracksTotalPages > 1 && sentinel) {
      _tracksObserver = new IntersectionObserver(
        entries => { if (entries[0].isIntersecting) _loadMoreTracks(); },
        { rootMargin: '200px' }
      );
      _tracksObserver.observe(sentinel);
    }
  } catch (e) { list.innerHTML = `<p style="color:var(--text-muted);padding:20px">${escHtml(e.message)}</p>`; }
}

async function _loadMoreTracks() {
  if (APP.tracksLoading || APP.tracksExhausted) return;
  if (APP.tracksPage >= APP.tracksTotalPages) { APP.tracksExhausted = true; return; }

  APP.tracksLoading = true;
  APP.tracksPage++;

  const list   = document.getElementById('tracks-list');
  const loader = document.getElementById('tracks-page-loader');
  if (loader) loader.classList.remove('hidden');

  try {
    const data   = await API.call('user.getTopTracks', { period: APP.tracksPeriod, limit: 50, page: APP.tracksPage });
    const tracks = data.toptracks?.track || [];
    if (!tracks.length) { APP.tracksExhausted = true; return; }
    const maxPlay   = APP.topTracksData.length > 0 ? parseInt(APP.topTracksData[0].playcount) : 1;
    const startRank = (APP.tracksPage - 1) * 50 + 1;
    tracks.forEach((t, i) => list.insertAdjacentHTML('beforeend', _buildTrackItem(t, startRank + i, maxPlay)));
    // Résolution images manquantes pour la page chargée
    _resolveTrackImages(tracks, startRank);
    APP.topTracksData = [...APP.topTracksData, ...tracks];
  } catch (e) { console.warn('_loadMoreTracks:', e); }
  finally {
    APP.tracksLoading = false;
    if (loader) loader.classList.add('hidden');
  }
}

/* ── Period selectors ── */
function initPeriodSelectors() {
  [
    { id: 'prd-artists', fn: loadTopArtists },
    { id: 'prd-albums',  fn: loadTopAlbums },
    { id: 'prd-tracks',  fn: loadTopTracks },
  ].forEach(({ id, fn }) => {
    const container = document.getElementById(id);
    if (!container) return;
    container.querySelectorAll('.prd').forEach(btn => {
      btn.addEventListener('click', () => {
        container.querySelectorAll('.prd').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        fn(btn.dataset.p);
      });
    });
  });
}

/* ============================================================
   CHARTS SECTION
   ============================================================ */
function setupChartsSection() {
  const currentYear = new Date().getFullYear();
  const sel = document.getElementById('yr-sel');
  if (!sel) return;
  sel.innerHTML = '';
  for (let y = currentYear; y >= APP.regYear; y--) {
    sel.innerHTML += `<option value="${y}">${y}</option>`;
  }
  loadMonthlyChart(currentYear);
  loadCumulativeChart();
  loadPieCharts();
}

async function loadMonthlyChart(year) {
  year = parseInt(year);
  const prog = document.getElementById('monthly-prog');
  const fill = document.getElementById('monthly-fill');
  const txt  = document.getElementById('monthly-prog-txt');

  if (prog) prog.classList.remove('hidden');
  if (fill) fill.style.width = '0%';

  const counts = [];
  for (let m = 0; m < 12; m++) {
    const n = await API.getMonthScrobbles(year, m);
    counts.push(n);
    if (fill) fill.style.width = `${Math.round((m + 1) / 12 * 100)}%`;
    if (txt)  txt.textContent  = `${MONTHS_SHORT()[m]} ${year} — ${formatNum(n)} ${t('scrobbles')}`;
  }
  if (prog) prog.classList.add('hidden');

  destroyChart('chart-monthly');
  const c = getThemeColors();
  APP.charts['chart-monthly'] = new Chart(document.getElementById('chart-monthly'), {
    type: 'bar',
    data: {
      labels: MONTHS(),
      datasets: [{
        label: t('chart_monthly_label', year),
        data: counts,
        backgroundColor: CHART_PALETTE.map(p => p + 'bb'),
        borderColor: CHART_PALETTE,
        borderWidth: 1, borderRadius: 7,
      }],
    },
    options: {
      ...baseChartOpts(),
      plugins: {
        ...baseChartOpts().plugins,
        tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } },
      },
      scales: {
        x: { grid: { display: false }, ticks: { color: c.text } },
        y: { grid: { color: c.grid },  ticks: { color: c.text } },
      },
    },
  });
}

async function loadCumulativeChart() {
  const currentYear = new Date().getFullYear();
  const regYear     = APP.regYear;
  const labels = [], cumulative = [];
  let total = 0;

  for (let y = regYear; y <= currentYear; y++) {
    const mCounts = await Promise.all(Array(12).fill(0).map((_, m) => API.getMonthScrobbles(y, m)));
    mCounts.forEach((n, m) => {
      if (y < currentYear || m <= new Date().getMonth()) {
        total += n;
        labels.push(`${MONTHS_SHORT()[m]} ${y}`);
        cumulative.push(total);
      }
    });
  }

  destroyChart('chart-cumul');
  const c = getThemeColors();
  APP.charts['chart-cumul'] = new Chart(document.getElementById('chart-cumul'), {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: t('chart_cumul_label'),
        data: cumulative,
        borderColor: '#6366f1',
        backgroundColor: 'rgba(99,102,241,0.08)',
        fill: true, tension: 0.4,
        pointRadius: cumulative.length > 60 ? 0 : 3,
        pointHoverRadius: 5,
        borderWidth: 2,
      }],
    },
    options: {
      ...baseChartOpts(),
      animation: { duration: cumulative.length > 80 ? 0 : 600, easing: 'easeOutQuart' },
      plugins: {
        ...baseChartOpts().plugins,
        tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } },
      },
      scales: {
        x: { grid: { display: false }, ticks: { color: c.text, maxTicksLimit: 14 } },
        y: { grid: { color: c.grid },  ticks: { color: c.text } },
      },
    },
  });
}

async function loadPieCharts() {
  const c = getThemeColors();
  const pieOpts = {
    responsive: true, maintainAspectRatio: false,
    plugins: {
      legend: { position: 'right', labels: { color: c.text, boxWidth: 12, padding: 8, font: { size: 11 } } },
      tooltip: { callbacks: { label: ctx => ` ${ctx.label}: ${formatNum(ctx.raw)}` } },
    },
    cutout: '56%',
    animation: { duration: 700 },
  };

  try {
    if (!APP.topArtistsData.length) {
      const d = await API.call('user.getTopArtists', { period: 'overall', limit: 10 });
      APP.topArtistsData = d.topartists?.artist || [];
    }
    const top10a = APP.topArtistsData.slice(0, 10);
    destroyChart('chart-art-pie');
    APP.charts['chart-art-pie'] = new Chart(document.getElementById('chart-art-pie'), {
      type: 'doughnut',
      data: {
        labels: top10a.map(a => a.name),
        datasets: [{ data: top10a.map(a => parseInt(a.playcount)), backgroundColor: CHART_PALETTE, borderWidth: 2, borderColor: c.isDark ? '#07071a' : '#f1f5f9', hoverOffset: 8 }],
      },
      options: pieOpts,
    });
  } catch (e) { console.warn('pie-artists:', e); }

  try {
    if (!APP.topAlbumsData.length) {
      const d = await API.call('user.getTopAlbums', { period: 'overall', limit: 10 });
      APP.topAlbumsData = d.topalbums?.album || [];
    }
    const top10b = APP.topAlbumsData.slice(0, 10);
    destroyChart('chart-alb-pie');
    APP.charts['chart-alb-pie'] = new Chart(document.getElementById('chart-alb-pie'), {
      type: 'doughnut',
      data: {
        labels: top10b.map(a => a.name),
        datasets: [{ data: top10b.map(a => parseInt(a.playcount)), backgroundColor: CHART_PALETTE, borderWidth: 2, borderColor: c.isDark ? '#07071a' : '#f1f5f9', hoverOffset: 8 }],
      },
      options: pieOpts,
    });
  } catch (e) { console.warn('pie-albums:', e); }
}

/* ============================================================
   WRAPPED
   ============================================================ */
function setupWrappedSection() {
  const currentYear = new Date().getFullYear();
  const sel = document.getElementById('w-yr-sel');
  if (!sel) return;
  sel.innerHTML = '';
  for (let y = currentYear; y >= APP.regYear; y--) {
    sel.innerHTML += `<option value="${y}"${y === currentYear - 1 ? ' selected' : ''}>${y}</option>`;
  }
  loadWrapped(currentYear - 1);
}

async function loadWrapped(year) {
  year = parseInt(year);
  document.getElementById('w-loader')?.classList.remove('hidden');
  const wrappedCard = document.getElementById('wrapped-card');
  if (wrappedCard) wrappedCard.style.opacity = '.4';
  document.getElementById('w-yr-badge').textContent = year;
  document.getElementById('w-uname').textContent    = '@' + (APP.userInfo?.name || APP.username);

  const progFill = document.getElementById('w-prog-fill');
  const progN    = document.getElementById('w-prog-n');
  const monthCounts = [];

  for (let m = 0; m < 12; m++) {
    const n = await API.getMonthScrobbles(year, m);
    monthCounts.push(n);
    if (progFill) progFill.style.width = Math.round((m + 1) / 12 * 100) + '%';
    if (progN)    progN.textContent    = m + 1;
  }

  const totalYear = monthCounts.reduce((a, b) => a + b, 0);
  const maxMonth  = monthCounts.indexOf(Math.max(...monthCounts));

  document.getElementById('w-scrobbles').textContent = formatNum(totalYear);
  document.getElementById('w-top-m').textContent     = MONTHS()[maxMonth] || '';

  // Update listen time
  const ltEl = document.getElementById('w-listen-time');
  if (ltEl && totalYear > 0) ltEl.textContent = estimateListenTime(totalYear);

  try {
    const [artData, trkData, albData] = await Promise.all([
      API.call('user.getTopArtists', { period: '12month', limit: 50 }),
      API.call('user.getTopTracks',  { period: '12month', limit: 50 }),
      API.call('user.getTopAlbums',  { period: '12month', limit: 50 }),
    ]);
    const arts = artData.topartists?.artist || [];
    const trks = trkData.toptracks?.track   || [];
    const albs = albData.topalbums?.album   || [];

    document.getElementById('w-art-cnt').textContent = formatNum(artData.topartists?.['@attr']?.total || arts.length);

    if (arts[0]) _fillWrappedPod('art', arts[0].name, arts[0].playcount,
      arts[0].image?.find(i => i.size === 'extralarge')?.['#text'] || arts[0].image?.find(i => i.size === 'large')?.['#text']);
    if (trks[0]) _fillWrappedPod('trk', trks[0].name, trks[0].playcount, null, trks[0].name + (trks[0].artist?.name || ''));
    if (albs[0]) _fillWrappedPod('alb', albs[0].name, albs[0].playcount,
      albs[0].image?.find(i => i.size === 'extralarge')?.['#text'] || albs[0].image?.find(i => i.size === 'large')?.['#text']);
  } catch (e) { console.warn('wrapped tops:', e); }

  destroyChart('w-mini');
  APP.charts['w-mini'] = new Chart(document.getElementById('w-mini'), {
    type: 'bar',
    data: {
      labels: MONTHS_SHORT(),
      datasets: [{
        data: monthCounts,
        backgroundColor: 'rgba(255,255,255,0.25)',
        borderColor:     'rgba(255,255,255,0.5)',
        borderWidth: 1, borderRadius: 3,
      }],
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: { callbacks: { label: ctx => ` ${formatNum(ctx.raw)}` } } },
      scales: {
        x: { grid: { display: false }, ticks: { color: 'rgba(255,255,255,.55)', font: { size: 8 } } },
        y: { display: false },
      },
      animation: { duration: 500 },
    },
  });

  document.getElementById('w-loader')?.classList.add('hidden');
  if (wrappedCard) wrappedCard.style.opacity = '1';
}

function _fillWrappedPod(prefix, name, playcount, imgUrl, fallbackSeed) {
  const letter = (name || '?')[0].toUpperCase();
  const seed   = fallbackSeed || name;

  document.getElementById(`w-${prefix}-name`).textContent  = name;
  document.getElementById(`w-${prefix}-plays`).textContent = formatNum(playcount) + ' ' + t('plays');
  document.getElementById(`w-${prefix}-lt`).textContent    = letter;

  const imgEl = document.getElementById(`w-${prefix}-img`);
  imgEl.style.background = nameToGradient(seed);

  if (imgUrl && !isDefaultImg(imgUrl)) {
    imgEl.innerHTML = `<img src="${imgUrl}" alt="${escHtml(name)}" style="width:100%;height:100%;object-fit:cover;border-radius:50%"
      onerror="this.outerHTML='<span id=w-${prefix}-lt>${letter}</span>'">`;
  }
}

async function exportWrapped() {
  const card = document.getElementById('wrapped-card');
  try {
    showToast(t('wrapped_generating'));
    document.body.classList.add('export-mode');
    if (document.fonts?.ready) await document.fonts.ready;
    await sleep(80);
    const canvas = await html2canvas(card, { scale: 2, useCORS: true, allowTaint: true, backgroundColor: null, logging: false });
    document.body.classList.remove('export-mode');
    downloadCanvas(canvas, `laststats-wrapped-${document.getElementById('w-yr-sel').value}.png`);
    showToast(t('wrapped_exported'));
  } catch (e) {
    document.body.classList.remove('export-mode');
    showToast(t('wrapped_export_error', e.message), 'error');
  }
}

/* ============================================================
   STORY / EXPORT
   ============================================================ */
async function generateStory(type) {
  showToast(t('story_preparing'));
  try {
    const u       = APP.userInfo;
    const year    = document.getElementById('w-yr-sel')?.value || new Date().getFullYear() - 1;
    const artists = APP.topArtistsData.slice(0, 3);
    const tracks  = APP.topTracksData.slice(0, 3);

    if (!artists.length) { showToast(t('story_no_data'), 'error'); return; }

    const username = u?.name || APP.username;
    const art0     = artists[0];
    const trk0     = tracks[0];
    const alb0     = APP.topAlbumsData[0];
    const scrobbles = document.getElementById('w-scrobbles')?.textContent || '—';
    const artCnt    = document.getElementById('w-art-cnt')?.textContent   || '—';
    const topMonth  = document.getElementById('w-top-m')?.textContent     || '—';
    const artImgUrl = await getArtistImage(art0.name);

    if (type === 'mini') {
      document.getElementById('story-mini-year').textContent     = year;
      document.getElementById('story-mini-username').textContent  = '@' + username;
      document.getElementById('story-mini-scrobbles').textContent = scrobbles;
      document.getElementById('story-mini-artists').textContent   = artCnt;
      document.getElementById('story-mini-art-name').textContent  = art0.name;
      const artImgEl = document.getElementById('story-mini-art-img');
      document.getElementById('story-mini-art-lt').textContent    = art0.name[0].toUpperCase();
      artImgEl.style.background = nameToGradient(art0.name);
      if (artImgUrl) artImgEl.innerHTML = `<img src="${artImgUrl}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%">`;
      if (trk0) document.getElementById('story-mini-trk-name').textContent = trk0.name;
      await _captureStory('story-mini-card', 360, 640, `laststats-story-${year}.png`);
    } else {
      document.getElementById('story-full-year').textContent     = year;
      document.getElementById('story-full-username').textContent  = '@' + username;
      document.getElementById('story-full-scrobbles').textContent = scrobbles;
      document.getElementById('story-full-artists').textContent   = artCnt;
      document.getElementById('story-full-month').textContent     = topMonth;
      document.getElementById('story-full-art-name').textContent  = art0.name;
      document.getElementById('story-full-art-plays').textContent = formatNum(art0.playcount) + ' ' + t('plays');
      document.getElementById('story-full-art-lt').textContent    = art0.name[0].toUpperCase();
      const fullArtImg = document.getElementById('story-full-art-img');
      fullArtImg.style.background = nameToGradient(art0.name);
      if (artImgUrl) fullArtImg.innerHTML = `<img src="${artImgUrl}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%">`;
      if (trk0) {
        document.getElementById('story-full-trk-name').textContent  = trk0.name;
        document.getElementById('story-full-trk-plays').textContent = formatNum(trk0.playcount) + ' ' + t('plays');
        document.getElementById('story-full-trk-lt').textContent    = trk0.name[0].toUpperCase();
        document.getElementById('story-full-trk-img').style.background = nameToGradient(trk0.name);
      }
      if (alb0) {
        document.getElementById('story-full-alb-name').textContent  = alb0.name;
        document.getElementById('story-full-alb-plays').textContent = formatNum(alb0.playcount) + ' ' + t('plays');
        document.getElementById('story-full-alb-lt').textContent    = alb0.name[0].toUpperCase();
        const albImgEl  = document.getElementById('story-full-alb-img');
        albImgEl.style.background = nameToGradient(alb0.name);
        const albImgUrl = alb0.image?.find(i => i.size === 'medium')?.['#text'];
        if (albImgUrl && !isDefaultImg(albImgUrl)) albImgEl.innerHTML = `<img src="${albImgUrl}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%">`;
      }
      await _captureStory('story-full-card', 680, 860, `laststats-full-${year}.png`);
    }
    showToast(t('story_downloaded'));
  } catch (e) {
    document.body.classList.remove('export-mode');
    showToast(t('story_error', e.message), 'error');
    console.error('generateStory:', e);
  }
}

async function _captureStory(cardId, w, h, filename) {
  const card = document.getElementById(cardId);
  document.body.classList.add('export-mode');
  if (document.fonts?.ready) await document.fonts.ready;
  await sleep(120);
  const canvas = await html2canvas(card, {
    scale: 2, useCORS: true, allowTaint: true, backgroundColor: null,
    width: w, height: h, windowWidth: w, windowHeight: h, logging: false,
    onclone: (doc) => { doc.fonts?.ready; },
  });
  document.body.classList.remove('export-mode');
  downloadCanvas(canvas, filename);
}

function downloadCanvas(canvas, filename) {
  const link = document.createElement('a');
  link.download = filename;
  link.href = canvas.toDataURL('image/png');
  link.click();
}

/* ============================================================
   ADVANCED STATS
   ============================================================ */
async function loadAdvancedStats() {
  const u       = APP.userInfo;
  const regTs   = parseInt(u?.registered?.unixtime || 0);
  const daysSince = regTs ? Math.floor((Date.now() - regTs * 1000) / 86400000) : 1;
  const total   = parseInt(u?.playcount || 0);
  const avgDay  = daysSince > 0 ? (total / daysSince).toFixed(1) : 0;
  const avgWeek = (parseFloat(avgDay) * 7).toFixed(0);

  try {
    if (!APP.topArtistsData.length) {
      const d = await API.call('user.getTopArtists', { period: 'overall', limit: TOP_LIMIT });
      APP.topArtistsData = d.topartists?.artist || [];
    }

    const playcounts = APP.topArtistsData.map(a => parseInt(a.playcount));
    const eddington  = calcEddington(playcounts);
    const oneHits    = playcounts.filter(p => p === 1).length;
    const maxArtist  = APP.topArtistsData[0];
    const topPct     = total > 0 && maxArtist ? ((parseInt(maxArtist.playcount) / total) * 100).toFixed(1) : 0;

    const cards = [
      { icon: '⚡', value: avgDay,    label: t('adv_per_day'),      sub: t('adv_per_week', avgWeek),           color: '#6366f1' },
      { icon: '🔢', value: eddington, label: t('adv_eddington'),    sub: t('adv_eddington_sub', eddington),    color: '#8b5cf6' },
      { icon: '🌟', value: maxArtist ? maxArtist.name : '—', label: t('adv_top1_alltime'), sub: t('adv_top1_pct', topPct), color: '#a855f7', noAnim: true },
      { icon: '💀', value: oneHits,   label: t('adv_ohw'),          sub: t('adv_ohw_sub'),                     color: '#ec4899' },
      { icon: '📆', value: formatNum(daysSince), label: t('adv_days'), sub: t('adv_days_sub', formatDate(regTs)), color: '#f97316', noAnim: true },
      { icon: '🎯', value: formatNum(total),     label: t('adv_total'), sub: t('adv_total_sub'),                 color: '#22c55e', noAnim: true },
    ];

    document.getElementById('adv-grid').innerHTML = cards.map((c, i) => `
      <div class="adv-card" style="animation-delay:${i * 0.05}s">
        <div class="adv-card-icon">${c.icon}</div>
        <div class="adv-card-value" style="color:${c.color}">${c.value}</div>
        <div class="adv-card-label">${c.label}</div>
        <div class="adv-card-sub">${c.sub}</div>
      </div>`).join('');

  } catch (e) {
    document.getElementById('adv-grid').innerHTML = `<p style="color:var(--text-muted);grid-column:1/-1">${e.message}</p>`;
  }
}

function calcEddington(playcounts) {
  const sorted = [...playcounts].sort((a, b) => b - a);
  let e = 0;
  for (let i = 0; i < sorted.length; i++) {
    if (sorted[i] >= i + 1) e = i + 1;
    else break;
  }
  return e;
}

/* ============================================================
   FULL HISTORY FETCH — with minimizable overlay
   ============================================================ */
let _historyFetchMinimized = false;
let _bgFetchInProgress     = false;

/**
 * Fetches full scrobble history.
 * @param {boolean} backgroundMode — if true, runs silently, shows toast when done
 */
async function fetchFullHistory(backgroundMode = false) {
  if (_bgFetchInProgress) return;
  _bgFetchInProgress = true;

  const btn     = document.getElementById('fetch-history-btn');
  const overlay = document.getElementById('fetch-overlay');
  const fillEl  = document.getElementById('fetch-fill');
  const pctEl   = document.getElementById('fetch-pct');
  const tracksEl= document.getElementById('fetch-tracks');
  const subEl   = document.getElementById('fetch-sub');
  const msgEl   = document.getElementById('fetch-msg');
  const titleEl = document.getElementById('fetch-title');
  const minBtn  = document.getElementById('fetch-minimize-btn');

  if (btn) { btn.disabled = true; btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${t('fetch_btn_loading')}`; }

  if (!backgroundMode && overlay) {
    _historyFetchMinimized = false;
    overlay.classList.remove('hidden', 'fetch-overlay--minimized');
    document.body.classList.add('fetch-active');
    if (fillEl)   fillEl.style.width  = '0%';
    if (pctEl)    pctEl.textContent   = '0%';
    if (tracksEl) tracksEl.textContent = '0 ' + t('scrobbles');
    if (msgEl)    msgEl.textContent   = t('fetch_init');
    if (titleEl)  titleEl.textContent  = t('fetch_title');
  } else if (backgroundMode && overlay) {
    // Mode arrière-plan : pill réduite directement
    _historyFetchMinimized = true;
    overlay.classList.remove('hidden');
    overlay.classList.add('fetch-overlay--minimized');
    document.body.classList.add('fetch-active');
    const pillTxt = overlay.querySelector('.fetch-pill-text');
    const pillPct = overlay.querySelector('.fetch-pill-pct');
    if (pillTxt) pillTxt.textContent = t('fetch_loading');
    if (pillPct) pillPct.textContent = '0%';
    if (titleEl) titleEl.textContent  = t('fetch_title');
  }

  // Wire minimize button
  if (minBtn) {
    minBtn.onclick = () => minimizeHistoryFetch();
    minBtn.innerHTML = `<i class="fas fa-minus"></i>`;
    minBtn.title = t('fetch_minimize');
  }

  // Pill click → expand
  const pillEl = overlay?.querySelector('.fetch-pill');
  if (pillEl) pillEl.onclick = () => expandHistoryFetch();

  try {
    const tracks = await API.fetchAllPages((page, totalPages, loaded) => {
      const pct = Math.round(page / totalPages * 100);
      if (!_historyFetchMinimized) {
        if (fillEl)   fillEl.style.width   = pct + '%';
        if (pctEl)    pctEl.textContent    = pct + '%';
        if (tracksEl) tracksEl.textContent = formatNum(loaded) + ' ' + t('scrobbles');
        if (subEl)    subEl.textContent    = t('fetch_page', page, totalPages);
        if (msgEl)    msgEl.textContent    = t('fetch_loading');
      } else {
        // État réduit : met à jour la pill
        if (overlay) {
          const _pp = overlay.querySelector('.fetch-pill-pct');
          const _pt = overlay.querySelector('.fetch-pill-text');
          if (_pp) _pp.textContent = pct + '%';
          if (_pt) _pt.textContent = t('fetch_loading');
        }
        // Met aussi à jour la barre en fond pour quand on ré-expand
        if (fillEl)   fillEl.style.width   = pct + '%';
        if (pctEl)    pctEl.textContent    = pct + '%';
        if (tracksEl) tracksEl.textContent = formatNum(loaded) + ' ' + t('scrobbles');
        if (subEl)    subEl.textContent    = t('fetch_page', page, totalPages);
      }
    });

    APP.fullHistory = tracks;
    if (overlay) {
      overlay.classList.add('hidden');
      document.body.classList.remove('fetch-active');
    }

    processFullHistory(tracks);
    if (backgroundMode) {
      showToast(t('fetch_auto_done'));
    } else {
      showToast(t('fetch_success', formatNum(tracks.length)));
    }

    if (btn) { btn.disabled = false; btn.innerHTML = `<i class="fas fa-check"></i> ${t('fetch_btn_done')}`; }

  } catch (e) {
    if (overlay) {
      overlay.classList.add('hidden');
      document.body.classList.remove('fetch-active');
    }
    showToast(t('fetch_error', e.message), 'error');
    if (btn) { btn.disabled = false; btn.innerHTML = `<i class="fas fa-sync-alt"></i> ${t('fetch_btn_refresh')}`; }
  } finally {
    _bgFetchInProgress = false;
  }
}

function minimizeHistoryFetch() {
  const overlay = document.getElementById('fetch-overlay');
  if (!overlay) return;
  _historyFetchMinimized = true;
  overlay.classList.add('fetch-overlay--minimized');
  const minBtn = document.getElementById('fetch-minimize-btn');
  if (minBtn) { minBtn.innerHTML = '<i class="fas fa-expand-alt"></i>'; minBtn.title = t('fetch_expand'); minBtn.onclick = () => expandHistoryFetch(); }
  // Init pill text si vide
  const pillTxt = overlay.querySelector('.fetch-pill-text');
  if (pillTxt && !pillTxt.textContent.trim()) pillTxt.textContent = t('fetch_loading');
}

function expandHistoryFetch() {
  const overlay = document.getElementById('fetch-overlay');
  if (!overlay) return;
  _historyFetchMinimized = false;
  overlay.classList.remove('fetch-overlay--minimized');
  const minBtn = document.getElementById('fetch-minimize-btn');
  if (minBtn) { minBtn.innerHTML = '<i class="fas fa-minus"></i>'; minBtn.title = t('fetch_minimize'); minBtn.onclick = () => minimizeHistoryFetch(); }
}

function processFullHistory(tracks) {
  if (!tracks || !tracks.length) return;

  const hourCounts = Array(24).fill(0);
  const dayCounts  = Array(7).fill(0);
  const artistMap  = new Map();

  for (const t of tracks) {
    const ts = parseInt(t.date?.uts || 0);
    if (ts) {
      const d   = new Date(ts * 1000);
      hourCounts[d.getHours()]++;
      const dow = (d.getDay() + 6) % 7;
      dayCounts[dow]++;
    }
    const artist = t.artist?.['#text'] || t.artist?.name || '';
    if (artist) artistMap.set(artist, (artistMap.get(artist) || 0) + 1);
  }

  const oneHitWonders = [...artistMap.entries()].filter(([, n]) => n === 1).map(([name]) => name).slice(0, 20);
  const allPlays      = [...artistMap.values()];
  const eddington     = calcEddington(allPlays);
  const uniqueCount   = artistMap.size;

  const u         = APP.userInfo;
  const regTs     = parseInt(u?.registered?.unixtime || 0);
  const daysSince = regTs ? Math.floor((Date.now() - regTs * 1000) / 86400000) : 1;
  const avgDay    = (tracks.length / daysSince).toFixed(1);

  const sortedArtists = [...artistMap.entries()].sort((a, b) => b[1] - a[1]);
  const top1   = sortedArtists[0];
  const topPct = top1 ? ((top1[1] / tracks.length) * 100).toFixed(1) : 0;

  const streakData = calcStreak(tracks);
  APP.streakData   = streakData;
  updateStreakUI(streakData);

  document.getElementById('adv-grid').innerHTML = [
    { icon: '⚡', value: avgDay,    label: t('adv_per_day'),      sub: t('adv_real_avg', formatNum(tracks.length)), color: '#6366f1' },
    { icon: '🔢', value: eddington, label: t('adv_eddington'),    sub: t('adv_eddington_sub', eddington),            color: '#8b5cf6' },
    { icon: '🌟', value: top1?.[0] || '—', label: t('adv_top1_alltime'), sub: t('adv_top1_detail', formatNum(top1?.[1] || 0), topPct), color: '#a855f7', noAnim: true },
    { icon: '🔥', value: streakData.best, label: t('adv_streak_record'),  sub: t('adv_streak_current', streakData.current, streakData.current > 1 ? 's' : ''), color: '#f97316' },
    { icon: '🎤', value: formatNum(uniqueCount), label: t('adv_unique_artists'), sub: t('adv_unique_sub'), color: '#ec4899', noAnim: true },
    { icon: '🎵', value: formatNum(tracks.length), label: t('adv_analyzed'), sub: t('adv_analyzed_sub'), color: '#22c55e', noAnim: true },
  ].map((c, i) => `
    <div class="adv-card" style="animation-delay:${i * 0.05}s">
      <div class="adv-card-icon">${c.icon}</div>
      <div class="adv-card-value" style="color:${c.color}">${c.value}</div>
      <div class="adv-card-label">${c.label}</div>
      <div class="adv-card-sub">${c.sub}</div>
    </div>`).join('');

  document.getElementById('adv-charts')?.classList.remove('hidden');
  renderHourlyChart(hourCounts);
  renderWeekdayChart(dayCounts);
  renderOneHitWonders(oneHitWonders, artistMap);
  renderHeatmap(hourCounts);
}

function renderHourlyChart(hourCounts) {
  destroyChart('chart-hourly');
  const c      = getThemeColors();
  const labels = Array(24).fill(0).map((_, i) => `${i}h`);
  APP.charts['chart-hourly'] = new Chart(document.getElementById('chart-hourly'), {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        data: hourCounts,
        backgroundColor: hourCounts.map(v => `rgba(99,102,241,${0.2 + (v / Math.max(...hourCounts, 1)) * 0.7})`),
        borderColor:     hourCounts.map(v => `rgba(99,102,241,${0.4 + (v / Math.max(...hourCounts, 1)) * 0.6})`),
        borderWidth: 1, borderRadius: 4,
      }],
    },
    options: {
      ...baseChartOpts(),
      animation: { duration: 0 },
      plugins: { ...baseChartOpts().plugins, tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } } },
      scales: {
        x: { grid: { display: false }, ticks: { color: c.text, maxTicksLimit: 12, font: { size: 10 } } },
        y: { grid: { color: c.grid },  ticks: { color: c.text, font: { size: 10 } } },
      },
    },
  });
}

function renderWeekdayChart(dayCounts) {
  destroyChart('chart-weekday');
  const c = getThemeColors();
  APP.charts['chart-weekday'] = new Chart(document.getElementById('chart-weekday'), {
    type: 'bar',
    data: {
      labels: DAYS(),
      datasets: [{
        data: dayCounts,
        backgroundColor: CHART_PALETTE.slice(0, 7).map(p => p + 'cc'),
        borderColor:     CHART_PALETTE.slice(0, 7),
        borderWidth: 1, borderRadius: 5,
      }],
    },
    options: {
      ...baseChartOpts(),
      animation: { duration: 0 },
      plugins: { ...baseChartOpts().plugins, tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} ${t('scrobbles')}` } } },
      scales: {
        x: { grid: { display: false }, ticks: { color: c.text } },
        y: { grid: { color: c.grid },  ticks: { color: c.text } },
      },
    },
  });
}

function renderOneHitWonders(names, artistMap) {
  const el = document.getElementById('ohw-list');
  if (!el) return;

  // Inject explanation notice
  const ohwSection = el.closest?.('.adv-chart-card');
  if (ohwSection && !ohwSection.querySelector('.ohw-explain')) {
    const notice = document.createElement('p');
    notice.className  = 'ohw-explain';
    notice.style.cssText = 'color:var(--text-muted);font-size:.82rem;margin:8px 0 0;line-height:1.5';
    notice.innerHTML  = t('ohw_explain');
    el.insertAdjacentElement('beforebegin', notice);
  }

  if (!names.length) {
    el.innerHTML = `<p style="color:var(--text-muted);padding:12px">${t('ohw_none')}</p>`;
    return;
  }

  const raresAll = [...artistMap.entries()].filter(([, n]) => n <= 3).sort((a, b) => a[1] - b[1]).slice(0, 20);

  el.innerHTML = raresAll.map(([name, plays], i) => `
    <div class="ohw-item">
      <span class="ohw-num">${i + 1}</span>
      <span class="ohw-name" title="${escHtml(name)}">${escHtml(name)}</span>
      <span class="ohw-plays">${t('ohw_plays', plays, plays > 1 ? 's' : '')}</span>
    </div>`).join('');
}

/* ============================================================
   REFRESH & LOGOUT
   ============================================================ */
async function refreshData() {
  const icon = document.getElementById('refresh-icon');
  if (icon) icon.classList.add('fa-spin');
  Cache.clear();
  APP.fullHistory = null;
  APP.streakData  = null;

  try {
    await loadDashboard();
    loadVersus();
    loadMoodTags();
    const activeSection = document.querySelector('.app-sec.active')?.id?.replace('s-', '');
    if (activeSection === 'top-artists') await loadTopArtists('overall');
    if (activeSection === 'top-albums')  await loadTopAlbums('overall');
    if (activeSection === 'top-tracks')  await loadTopTracks('overall');
    if (activeSection === 'vizplus')     loadVizPlus();
    if (activeSection === 'obscurity')   loadObscurityScore();
    showToast(t('toast_data_updated'));
  } finally {
    if (icon) icon.classList.remove('fa-spin');
  }

  // Re-schedule background history refresh
  _scheduleBackgroundHistoryFetch();
}

function logout() {
  Cache.clear();
  clearSession();
  localStorage.removeItem('ls_section');
  APP.username    = '';
  APP.apiKey      = '';
  APP.userInfo    = null;
  APP.fullHistory = null;
  APP.streakData  = null;
  Object.values(APP.charts).forEach(c => c?.destroy());
  APP.charts = {};

  clearTimeout(_npTimer);
  clearTimeout(_bgHistoryTimer);

  document.getElementById('app')?.classList.add('hidden');
  document.getElementById('setup-screen')?.classList.remove('hidden');
  if (document.getElementById('input-username')) document.getElementById('input-username').value = '';
  if (document.getElementById('input-apikey'))   document.getElementById('input-apikey').value   = '';
}

/* ============================================================
   ARTIST IMAGE CACHE
   ============================================================ */
const _imgCache = new Map();

async function getArtistImage(artistName) {
  if (_imgCache.has(artistName)) return _imgCache.get(artistName);
  try {
    const data   = await API._fetch('artist.getTopAlbums', { artist: artistName, limit: 3, autocorrect: 1 });
    const albums = data.topalbums?.album || [];
    for (const alb of albums) {
      const img = alb.image?.find(i => i.size === 'extralarge')?.['#text'] || alb.image?.find(i => i.size === 'large')?.['#text'] || '';
      if (!isDefaultImg(img)) { _imgCache.set(artistName, img); return img; }
    }
  } catch {}
  _imgCache.set(artistName, null);
  return null;
}

async function injectArtistImage(artistName, containerId, fallbackBg, fallbackLetter) {
  const container = document.getElementById(containerId);
  if (!container) return;
  const img = await getArtistImage(artistName);
  if (img && container) {
    container.innerHTML = `
      <img src="${img}" alt="${escHtml(artistName)}" loading="lazy"
           style="width:100%;height:100%;object-fit:cover;border-radius:0"
           onerror="this.outerHTML='<div class=\\'spotify-cover\\' style=\\'background:${fallbackBg}\\'>
             <span class=\\'sc-letter\\'>${fallbackLetter}</span>
             <span class=\\'sc-name\\'>${escHtml(artistName)}</span></div>'">`;
  }
}

/* ============================================================
   ACCENT / COLOR THEME
   ============================================================ */
const _colorThief = typeof ColorThief !== 'undefined' ? new ColorThief() : null;

function setAccent(colorKey) {
  APP.currentAccent = colorKey;
  localStorage.setItem('ls_accent', colorKey);

  document.querySelectorAll('.acc-dot').forEach(b => b.classList.toggle('active', b.dataset.color === colorKey));

  if (colorKey === 'dynamic') {
    const npArtEl = document.querySelector('#np-art img');
    if (npArtEl?.complete && npArtEl.naturalWidth > 0) _applyColorThiefFromEl(npArtEl);
    return;
  }

  const PALETTES = {
    purple: { accent:'#d0bcff', container:'#4f378b', on:'#381e72', onCont:'#eaddff', glow:'rgba(208,188,255,0.18)', lt:'rgba(208,188,255,0.12)' },
    blue:   { accent:'#9ecaff', container:'#004a77', on:'#001d36', onCont:'#cde5ff', glow:'rgba(158,202,255,0.18)', lt:'rgba(158,202,255,0.12)' },
    green:  { accent:'#78dc77', container:'#1e5c1c', on:'#002105', onCont:'#94f990', glow:'rgba(120,220,119,0.18)', lt:'rgba(120,220,119,0.12)' },
    red:    { accent:'#ffb4ab', container:'#93000a', on:'#690005', onCont:'#ffdad6', glow:'rgba(255,180,171,0.18)', lt:'rgba(255,180,171,0.12)' },
    orange: { accent:'#ffb77c', container:'#6d3400', on:'#3d1d00', onCont:'#ffdcc0', glow:'rgba(255,183,124,0.18)', lt:'rgba(255,183,124,0.12)' },
  };
  const LIGHT = {
    purple: { accent:'#6750a4', container:'#eaddff', on:'#ffffff', onCont:'#21005d', glow:'rgba(103,80,164,0.3)', lt:'rgba(103,80,164,0.1)' },
    blue:   { accent:'#0061a4', container:'#cde5ff', on:'#ffffff', onCont:'#001d36', glow:'rgba(0,97,164,0.3)',   lt:'rgba(0,97,164,0.1)'   },
    green:  { accent:'#006e1c', container:'#94f990', on:'#ffffff', onCont:'#002105', glow:'rgba(0,110,28,0.3)',   lt:'rgba(0,110,28,0.1)'   },
    red:    { accent:'#ba1a1a', container:'#ffdad6', on:'#ffffff', onCont:'#410002', glow:'rgba(186,26,26,0.3)',   lt:'rgba(186,26,26,0.1)'  },
    orange: { accent:'#9c4e00', container:'#ffdcc0', on:'#ffffff', onCont:'#3d1d00', glow:'rgba(156,78,0,0.3)',   lt:'rgba(156,78,0,0.1)'   },
  };

  const isDark = APP.currentTheme === 'dark' || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches);
  const pal    = (isDark ? PALETTES : LIGHT)[colorKey] || PALETTES.purple;
  _applyCSSAccent(pal);
  updateAllChartThemes();
}

function _applyCSSAccent({ accent, container, on, onCont, glow, lt }) {
  const root = document.documentElement.style;
  root.setProperty('--accent',           accent);
  root.setProperty('--accent-container', container);
  root.setProperty('--accent-on',        on);
  root.setProperty('--accent-on-cont',   onCont);
  root.setProperty('--accent-glow',      glow);
  root.setProperty('--accent-lt',        lt);
}

function _applyColorThiefFromUrl(imgUrl) {
  if (!_colorThief) return;
  const img = new Image();
  img.crossOrigin = 'anonymous';
  img.onload = () => _applyColorThiefFromEl(img);
  img.onerror = () => {};
  img.src = imgUrl;
}

function _applyColorThiefFromEl(imgEl) {
  if (!_colorThief || !imgEl) return;
  try {
    const [r, g, b] = _colorThief.getColor(imgEl);
    const h  = _rgbToHsl(r, g, b)[0];
    _applyCSSAccent({
      accent:    `hsl(${h},65%,75%)`,
      container: `hsl(${h},45%,28%)`,
      on:        `hsl(${h},45%,14%)`,
      onCont:    `hsl(${h},65%,90%)`,
      glow:      `hsla(${h},65%,75%,0.18)`,
      lt:        `hsla(${h},65%,75%,0.12)`,
    });
  } catch (e) { console.warn('ColorThief:', e); }
}

function _rgbToHsl(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  let h, s; const l = (max + min) / 2;
  if (max === min) { h = s = 0; }
  else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
      case g: h = ((b - r) / d + 2) / 6; break;
      case b: h = ((r - g) / d + 4) / 6; break;
    }
  }
  return [Math.round(h * 360), Math.round(s * 100), Math.round(l * 100)];
}

/* ============================================================
   BADGE ENGINE
   ============================================================ */
const BadgeEngine = (() => {
  const TIERS = [
    { key: 'bronze',  label: 'Bronze',  icon: '🥉', xp: 10  },
    { key: 'argent',  label: 'Argent',  icon: '🥈', xp: 25  },
    { key: 'or',      label: 'Or',      icon: '🥇', xp: 50  },
    { key: 'diamant', label: 'Diamant', icon: '💎', xp: 100 },
    { key: 'elite',   label: 'Élite',   icon: '👑', xp: 200 },
  ];

  function thresholds(base, count = 5) {
    return Array(count).fill(0).map((_, i) => Math.round(base * Math.pow(2, i)));
  }

  const BADGE_DEFS = [
    { id: 'night_owl',    cat: 'noctambule',  icon: '🦉', get name() { return t('badge_night_owl_name'); },   get desc() { return t('badge_night_owl_desc'); },   thresholds: thresholds(50),   compute: (hist) => hist.filter(tr => { const h = new Date(parseInt(tr.date?.uts || 0) * 1000).getHours(); return h >= 0 && h < 5; }).length },
    { id: 'early_bird',   cat: 'noctambule',  icon: '🐦', get name() { return t('badge_early_bird_name'); },  get desc() { return t('badge_early_bird_desc'); },  thresholds: thresholds(30),   compute: (hist) => hist.filter(tr => { const h = new Date(parseInt(tr.date?.uts || 0) * 1000).getHours(); return h >= 5 && h < 8; }).length },
    { id: 'weekend_warrior', cat: 'noctambule', icon: '🎉', get name() { return t('badge_weekend_name'); },   get desc() { return t('badge_weekend_desc'); },     thresholds: thresholds(200),  compute: (hist) => hist.filter(tr => { const d = new Date(parseInt(tr.date?.uts || 0) * 1000).getDay(); return d === 0 || d === 6; }).length },
    { id: 'explorer',     cat: 'exploration', icon: '🧭', get name() { return t('badge_explorer_name'); },    get desc() { return t('badge_explorer_desc'); },    thresholds: thresholds(50),   compute: (hist) => { if (!hist.length) return 0; const u = new Set(hist.map(tr => (tr.artist?.['#text'] || tr.artist?.name || '').toLowerCase())).size; return Math.round((u / hist.length) * 1000); } },
    { id: 'discoverer',   cat: 'exploration', icon: '🔭', get name() { return t('badge_discoverer_name'); },  get desc() { return t('badge_discoverer_desc'); },  thresholds: thresholds(50),   compute: (hist) => new Set(hist.map(tr => (tr.artist?.['#text'] || tr.artist?.name || '').toLowerCase())).size },
    { id: 'hidden_gems',  cat: 'exploration', icon: '💎', get name() { return t('badge_hidden_gems_name'); }, get desc() { return t('badge_hidden_gems_desc'); }, thresholds: thresholds(10),   compute: (hist) => { const m = new Map(); hist.forEach(tr => { const a = (tr.artist?.['#text'] || tr.artist?.name || '').toLowerCase(); if (a) m.set(a, (m.get(a) || 0) + 1); }); return [...m.values()].filter(v => v <= 2).length; } },
    { id: 'loyal',        cat: 'fidelite',    icon: '💖', get name() { return t('badge_loyal_name'); },       get desc() { return t('badge_loyal_desc'); },       thresholds: thresholds(20),   compute: (hist) => { if (!hist.length) return 0; const wm = new Map(); for (const tr of hist) { const ts = parseInt(tr.date?.uts || 0); if (!ts) continue; const d = new Date(ts * 1000); const wk = `${d.getFullYear()}-W${Math.ceil((d.getDate() + 6 - (d.getDay() || 7)) / 7)}`; const art = (tr.artist?.['#text'] || tr.artist?.name || '').toLowerCase(); const k = `${wk}::${art}`; wm.set(k, (wm.get(k) || 0) + 1); } return Math.max(0, ...[...wm.values()]); } },
    { id: 'obsessed',     cat: 'fidelite',    icon: '🔁', get name() { return t('badge_obsessed_name'); },    get desc() { return t('badge_obsessed_desc'); },    thresholds: thresholds(10),   compute: (hist) => { const dm = new Map(); for (const tr of hist) { const ts = parseInt(tr.date?.uts || 0); if (!ts) continue; const d = new Date(ts * 1000); const k = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}::${(tr.artist?.['#text'] || '').toLowerCase()}`; dm.set(k, (dm.get(k) || 0) + 1); } return Math.max(0, ...[...dm.values()]); } },
    { id: 'collector',    cat: 'fidelite',    icon: '📀', get name() { return t('badge_collector_name'); },   get desc() { return t('badge_collector_desc'); },   thresholds: thresholds(20),   compute: (hist) => new Set(hist.map(tr => { const alb = tr.album?.['#text'] || ''; const art = tr.artist?.['#text'] || tr.artist?.name || ''; return alb ? `${art}::${alb}`.toLowerCase() : null; }).filter(Boolean)).size },
    { id: 'scrobbler',    cat: 'volume',      icon: '🎵', get name() { return t('badge_scrobbler_name'); },   get desc() { return t('badge_scrobbler_desc'); },   thresholds: thresholds(1000), compute: (hist) => hist.length },
    { id: 'binge',        cat: 'volume',      icon: '🎧', get name() { return t('badge_binge_name'); },       get desc() { return t('badge_binge_desc'); },       thresholds: thresholds(50),   compute: (hist) => { const dm = new Map(); for (const tr of hist) { const ts = parseInt(tr.date?.uts || 0); if (!ts) continue; const d = new Date(ts * 1000); const k = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`; dm.set(k, (dm.get(k) || 0) + 1); } return Math.max(0, ...[...dm.values()]); } },
    { id: 'marathon',     cat: 'volume',      icon: '🏃', get name() { return t('badge_marathon_name'); },    get desc() { return t('badge_marathon_desc'); },    thresholds: thresholds(7),    compute: () => APP.streakData?.best || 0 },
    { id: 'record_day',   cat: 'volume',      icon: '📈', get name() { return t('badge_record_day_name'); },  get desc() { return t('badge_record_day_desc'); },  thresholds: thresholds(5),    compute: (hist) => { const dm = new Map(); for (const tr of hist) { const ts = parseInt(tr.date?.uts || 0); if (!ts) continue; const d = new Date(ts * 1000); const k = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`; dm.set(k, (dm.get(k) || 0) + 1); } return [...dm.values()].filter(v => v >= 50).length; } },
    { id: 'listen_time',  cat: 'volume',      icon: '⏳', get name() { return t('badge_listen_time_name'); }, get desc() { return t('badge_listen_time_desc'); }, thresholds: thresholds(100),  compute: (hist) => Math.round(hist.length * 3.5 / 60) },
    { id: 'diversified',  cat: 'diversite',   icon: '🌈', get name() { return t('badge_diversified_name'); }, get desc() { return t('badge_diversified_desc'); }, thresholds: thresholds(5),    compute: () => document.querySelectorAll('.mood-tag').length },
    { id: 'genre_curious',cat: 'diversite',   icon: '🎭', get name() { return t('badge_genre_curious_name'); }, get desc() { return t('badge_genre_curious_desc'); }, thresholds: thresholds(6), compute: (hist) => new Set(hist.map(tr => { const ts = parseInt(tr.date?.uts || 0); if (!ts) return null; const d = new Date(ts * 1000); return `${d.getFullYear()}-${d.getMonth()}`; }).filter(Boolean)).size },
    { id: 'multilingual', cat: 'diversite',   icon: '🌍', get name() { return t('badge_multilingual_name'); }, get desc() { return t('badge_multilingual_desc'); }, thresholds: thresholds(5), compute: (hist) => { const nl = /[^\u0000-\u007F\u00C0-\u024F]/; return new Set(hist.filter(tr => { const a = tr.artist?.['#text'] || tr.artist?.name || ''; return nl.test(a); }).map(tr => (tr.artist?.['#text'] || tr.artist?.name || '').toLowerCase())).size; } },
  ];

  function computeBadge(def, history) {
    const value = def.compute(history);
    let tierIdx = -1;
    for (let i = def.thresholds.length - 1; i >= 0; i--) {
      if (value >= def.thresholds[i]) { tierIdx = i; break; }
    }
    return {
      ...def,
      value, tierIdx,
      tier:          tierIdx >= 0 ? TIERS[tierIdx] : null,
      unlocked:      tierIdx >= 0,
      nextThreshold: tierIdx < def.thresholds.length - 1 ? def.thresholds[tierIdx + 1] : null,
    };
  }

  function levelFromXP(xp) {
    const LEVEL_TITLES = t('level_titles')?.split?.(',') || ['Level 1','Level 2','Level 3','Level 4','Level 5','Level 6','Level 7','Level 8'];
    if (xp <= 0) return { level: 1, xpCurr: 0, xpNext: 100, pct: 0, title: LEVEL_TITLES[0] };
    const level     = Math.min(LEVEL_TITLES.length, Math.floor(Math.log2(xp / 50 + 1)) + 1);
    const xpForLvl  = Math.round(50 * (Math.pow(2, level - 1) - 1));
    const xpForNext = Math.round(50 * (Math.pow(2, level) - 1));
    const pct       = Math.min(100, Math.round(((xp - xpForLvl) / Math.max(1, xpForNext - xpForLvl)) * 100));
    return { level, xpCurr: xp, xpNext: xpForNext, pct, title: LEVEL_TITLES[level - 1] || LEVEL_TITLES.at(-1) };
  }

  function compute() {
    const history = APP.fullHistory;
    if (!history || !history.length) {
      document.getElementById('badges-empty')?.classList.remove('hidden');
      document.getElementById('badges-container')?.classList.add('hidden');
      showToast(t('toast_badges_need_hist'), 'error');
      return;
    }
    document.getElementById('badges-empty')?.classList.add('hidden');
    const loadBtn = document.getElementById('badges-load-btn');
    if (loadBtn) loadBtn.innerHTML = t('badge_calc');

    const results = [];
    let i = 0;
    function processNext() {
      if (i >= BADGE_DEFS.length) {
        _render(results);
        saveBadgesToStorage(results);
        showToast(t('toast_badges_saved'));
        if (loadBtn) loadBtn.innerHTML = t('badge_recalc');
        return;
      }
      results.push(computeBadge(BADGE_DEFS[i], history));
      i++;
      setTimeout(processNext, 0);
    }
    processNext();
  }

  function _badgeCard(b) {
    const tierClass = b.unlocked ? `tier-${b.tier.key}` : 'tier-bronze';
    const tierLabel = b.unlocked ? `${b.tier.icon} ${b.tier.label}` : t('badge_locked');
    const nextInfo  = b.nextThreshold !== null ? `${b.value} / ${b.nextThreshold}` : b.unlocked ? t('badge_max') : '';
    const delay     = b.unlocked ? `animation-delay:${(b.tierIdx || 0) * 0.08}s` : '';
    return `
      <div class="${b.unlocked ? 'badge-card unlocked' : 'badge-card locked'}" style="${delay}" onclick="showBadgeModal('${b.id}')">
        <div class="badge-card-icon">${b.icon}</div>
        <div class="badge-card-name">${escHtml(b.name)}</div>
        <div class="badge-card-tier ${tierClass}">${tierLabel}</div>
        ${nextInfo ? `<div class="badge-card-progress">${nextInfo}</div>` : ''}
      </div>`;
  }

  function _render(results) {
    document.getElementById('badges-container')?.classList.remove('hidden');
    const totalXP  = results.reduce((acc, b) => acc + (b.unlocked ? TIERS[b.tierIdx].xp : 0), 0);
    const unlocked = results.filter(b => b.unlocked).length;
    const lvlData  = levelFromXP(totalXP);

    const lvlEl = document.getElementById('bsc-level');   if (lvlEl) lvlEl.textContent = lvlData.level;
    const titleEl = document.getElementById('bsc-title'); if (titleEl) titleEl.textContent = lvlData.title;
    const xpFill  = document.getElementById('bsc-xp-fill'); if (xpFill) setTimeout(() => { xpFill.style.width = lvlData.pct + '%'; }, 200);
    const xpVal   = document.getElementById('bsc-xp-val'); if (xpVal) xpVal.textContent = `${totalXP} XP`;

    const unlockedEl = document.getElementById('bsc-unlocked'); if (unlockedEl) unlockedEl.textContent = t('badge_unlocked_count', unlocked);
    const totalEl    = document.getElementById('bsc-total');    if (totalEl) totalEl.textContent = t('badge_total', results.length);

    const navBadge = document.getElementById('badges-count-badge');
    if (navBadge) { if (unlocked > 0) { navBadge.textContent = unlocked; navBadge.style.display = ''; } else navBadge.style.display = 'none'; }

    ['noctambule','exploration','fidelite','volume','diversite'].forEach(cat => {
      const grid = document.getElementById(`badge-grid-${cat}`);
      if (!grid) return;
      grid.innerHTML = results.filter(b => b.cat === cat).map(b => _badgeCard(b)).join('');
    });

    window._badgeResults = results;
  }

  return { compute, BADGE_DEFS, TIERS };
})();

/* ── Badge modal ── */
function showBadgeModal(badgeId) {
  const results = window._badgeResults || [];
  const b = results.find(r => r.id === badgeId);
  if (!b) return;

  document.getElementById('bm-icon').textContent  = b.icon;
  document.getElementById('bm-title').textContent = b.name;
  document.getElementById('bm-desc').textContent  = b.desc;

  const tierEl = document.getElementById('bm-tier');
  if (b.unlocked) {
    tierEl.className   = `bm-tier badge-card-tier tier-${b.tier.key}`;
    tierEl.textContent = `${b.tier.icon} ${b.tier.label}`;
  } else {
    tierEl.className   = 'bm-tier';
    tierEl.textContent = t('badge_locked');
  }

  const nextT  = b.nextThreshold !== null ? b.nextThreshold : b.thresholds.at(-1);
  const pct    = nextT > 0 ? Math.min(100, Math.round((b.value / nextT) * 100)) : 100;
  const fillEl = document.getElementById('bm-progress-fill');
  if (fillEl) setTimeout(() => { fillEl.style.width = pct + '%'; }, 150);

  document.getElementById('bm-progress-cur').textContent  = `${b.value}`;
  document.getElementById('bm-progress-next').textContent = b.nextThreshold ? `${b.nextThreshold}` : t('badge_max');

  const tiersRow = document.getElementById('bm-tiers-row');
  if (tiersRow) {
    tiersRow.innerHTML = b.thresholds.map((thresh, i) => {
      const tier    = BadgeEngine.TIERS[i];
      const achieved= b.value >= thresh;
      const isCurr  = b.unlocked && b.tierIdx === i;
      const cls     = isCurr ? 'bm-tier-chip current' : achieved ? 'bm-tier-chip achieved' : 'bm-tier-chip';
      return `<span class="${cls}" title="${tier.label}: ${thresh}">${tier.icon} ${thresh}</span>`;
    }).join('');
  }

  // Wire share/export buttons
  const shareBtn  = document.getElementById('bm-share-btn');
  const exportBtn = document.getElementById('bm-export-btn');
  if (shareBtn)  shareBtn.onclick  = () => shareBadgeAsImage(badgeId);
  if (exportBtn) exportBtn.onclick = () => exportBadgeAsImage(badgeId);

  document.getElementById('badge-modal')?.classList.remove('hidden');
}

function closeBadgeModal(e) {
  if (e && e.target !== document.getElementById('badge-modal')) return;
  document.getElementById('badge-modal')?.classList.add('hidden');
}

/* Badge persistence */
const BADGES_STORAGE_KEY = 'ls_badges_';

function saveBadgesToStorage(results) {
  if (!APP.username) return;
  try {
    const compact = results.map(b => ({ id: b.id, value: b.value, tierIdx: b.tierIdx, unlocked: b.unlocked }));
    localStorage.setItem(BADGES_STORAGE_KEY + APP.username, JSON.stringify({ ts: Date.now(), badges: compact }));
  } catch (e) { console.warn('saveBadges:', e); }
}

function restoreBadgesFromStorage() {
  if (!APP.username) return;
  try {
    const raw = localStorage.getItem(BADGES_STORAGE_KEY + APP.username);
    if (!raw) return;
    const { badges, ts } = JSON.parse(raw);
    if (!Array.isArray(badges)) return;

    const unlocked = badges.filter(b => b.unlocked).length;

    // Mise à jour du badge de navigation
    const navBadge = document.getElementById('badges-count-badge');
    if (navBadge && unlocked > 0) {
      navBadge.textContent = String(unlocked);
      navBadge.style.display = '';
    }

    // Renseigner le score-card si les données sont récentes (< 7 jours)
    const ageMs = Date.now() - (ts || 0);
    if (ageMs < 7 * 24 * 3600 * 1000) {
      const bscUnlocked = document.getElementById('bsc-unlocked');
      const bscTotal    = document.getElementById('bsc-total');
      if (bscUnlocked) bscUnlocked.textContent = t('badge_unlocked_count', unlocked);
      if (bscTotal)    bscTotal.textContent    = t('badge_total', badges.length);

      // Afficher une notice indiquant que les badges viennent du cache
      const noDataEl = document.getElementById('badges-empty');
      if (noDataEl) {
        const notice = document.getElementById('badge-persist-notice');
        if (!notice) {
          const n = document.createElement('p');
          n.id = 'badge-persist-notice';
          n.className = 'badge-persist-notice';
          const ageDays = Math.round(ageMs / 86400000);
          n.textContent = t ? t('badge_restored', ageDays || 0) : `Succès restaurés (il y a ${ageDays} j.)`;
          noDataEl.parentElement?.insertBefore(n, noDataEl);
        }
      }
    }
  } catch {}
}

/* Badge share/export */
async function shareBadgeAsImage(badgeId) { await _captureBadgeAsImage(badgeId, 'share'); }
async function exportBadgeAsImage(badgeId) { await _captureBadgeAsImage(badgeId, 'download'); }

async function _captureBadgeAsImage(badgeId, mode) {
  const results = window._badgeResults || [];
  const b       = results.find(r => r.id === badgeId);
  if (!b) { showToast(t('toast_badge_not_found'), 'error'); return; }

  const cc = document.createElement('div');
  cc.id = 'badge-export-canvas';
  cc.style.cssText = 'position:fixed;left:-9999px;top:0;width:360px;height:360px;background:linear-gradient(135deg,#1a1033,#0f0a1e);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:32px;border-radius:24px;font-family:Inter,sans-serif;';
  const accentColor = b.tier?.key === 'elite' ? '#a78bfa' : b.tier?.key === 'diamant' ? '#60a5fa' : b.tier?.key === 'or' ? '#fbbf24' : b.tier?.key === 'argent' ? '#94a3b8' : '#cd7f32';
  const tierLabel   = b.unlocked && b.tier ? `${b.tier.icon} ${b.tier.label}` : t('badge_locked');
  cc.innerHTML = `
    <div style="font-size:72px;line-height:1">${b.icon}</div>
    <div style="color:#fff;font-size:22px;font-weight:700;text-align:center">${escHtml(b.name)}</div>
    <div style="background:${accentColor}22;color:${accentColor};font-size:14px;font-weight:600;padding:6px 16px;border-radius:99px;border:1px solid ${accentColor}55">${tierLabel}</div>
    <div style="color:rgba(255,255,255,.55);font-size:12px;text-align:center;max-width:240px">${escHtml(b.desc)}</div>
    <div style="color:rgba(255,255,255,.35);font-size:11px;margin-top:12px">LastStats · last.fm</div>`;
  document.body.appendChild(cc);

  try {
    if (document.fonts?.ready) await document.fonts.ready;
    await sleep(120);
    const canvas = await html2canvas(cc, { scale: 2, useCORS: true, allowTaint: true, backgroundColor: null, logging: false, width: 360, height: 360 });
    document.body.removeChild(cc);

    if (mode === 'share' && navigator.share && navigator.canShare) {
      canvas.toBlob(async (blob) => {
        if (!blob) { downloadCanvas(canvas, `badge-${b.id}.png`); return; }
        const file = new File([blob], `badge-${b.id}.png`, { type: 'image/png' });
        try { await navigator.share({ title: b.name, text: `${b.name} — LastStats`, files: [file] }); }
        catch { downloadCanvas(canvas, `badge-${b.id}.png`); }
      }, 'image/png');
    } else {
      downloadCanvas(canvas, `badge-${b.id}.png`);
      showToast(t('toast_badge_downloaded'));
    }
  } catch (e) {
    if (document.body.contains(cc)) document.body.removeChild(cc);
    showToast(t('toast_badge_error', e.message), 'error');
  }
}

/* ============================================================
   OBSCURITY SCORE
   ============================================================ */
async function loadObscurityScore() {
  const container = document.getElementById('obs-container');
  const loadingEl = document.getElementById('obs-loading');
  const scoreEl   = document.getElementById('obs-score');
  const labelEl   = document.getElementById('obs-label');
  const listEl    = document.getElementById('obs-artists-list');

  if (!container) return;
  if (loadingEl) loadingEl.classList.remove('hidden');

  try {
    let artists = APP.topArtistsData;
    if (!artists.length) {
      const d = await API.call('user.getTopArtists', { period: 'overall', limit: 30 });
      artists = d.topartists?.artist || [];
    }
    const top30 = artists.slice(0, 30);

    const infoResults = await Promise.allSettled(
      top30.map(a => API.call('artist.getInfo', { artist: a.name, autocorrect: 1 }))
    );

    let totalListeners = 0, count = 0;
    const scored = [];

    infoResults.forEach((res, i) => {
      if (res.status !== 'fulfilled') return;
      const listeners = parseInt(res.value.artist?.stats?.listeners || 0);
      const a = top30[i];
      totalListeners += listeners;
      count++;
      scored.push({ name: a.name, listeners, plays: parseInt(a.playcount || 0) });
    });

    if (!count) { if (loadingEl) loadingEl.classList.add('hidden'); return; }

    const avgListeners = totalListeners / count;
    // Obscurity score: 0 (mainstream) → 100 (hidden gems)
    const score = Math.max(0, Math.min(100, Math.round(100 - Math.log10(Math.max(1, avgListeners)) * 14)));

    const label = score >= 80 ? t('obs_hunter')
                : score >= 60 ? t('obs_gems')
                : score >= 40 ? t('obs_eclectique')
                : score >= 20 ? t('obs_mainstream')
                : t('obs_very_popular');

    if (scoreEl) scoreEl.textContent = score;
    if (labelEl) labelEl.textContent = label;

    // Split artists into popular vs gems
    const popular = scored.filter(a => a.listeners > 1_000_000);
    const gems    = scored.filter(a => a.listeners <= 500_000);

    if (listEl) {
      listEl.innerHTML = `
        <p class="obs-artists-desc">${t('obs_artists_desc', popular.length, gems.length)}</p>
        <div class="obs-artists-grid">
          ${scored.slice(0, 12).map(a => {
            const type = a.listeners > 1_000_000 ? t('obs_type_popular') : a.listeners > 300_000 ? t('obs_type_indie') : t('obs_type_gems');
            const cls  = a.listeners > 1_000_000 ? 'obs-tag-popular' : a.listeners > 300_000 ? 'obs-tag-indie' : 'obs-tag-gem';
            return `<div class="obs-artist-item">
              <span class="obs-artist-name">${escHtml(a.name)}</span>
              <span class="obs-tag ${cls}">${type}</span>
            </div>`;
          }).join('')}
        </div>`;
    }

    if (loadingEl) loadingEl.classList.add('hidden');
    if (container) container.classList.remove('hidden');

  } catch (e) {
    if (loadingEl) loadingEl.classList.add('hidden');
    showToast(t('obs_error', e.message), 'error');
  }
}

/* ============================================================
   VIZ PLUS
   ============================================================ */
async function loadVizPlus() {
  const statusEl  = document.getElementById('vizplus-status');
  const statusTxt = document.getElementById('vizplus-status-txt');
  const btn       = document.getElementById('vizplus-load-btn');

  if (statusEl) statusEl.classList.remove('hidden');
  if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'; }

  try {
    if (statusTxt) statusTxt.textContent = t('loading');
    await _buildRadarChart();
    await _buildTreemap();
    await _buildSankey();
    if (statusEl) statusEl.classList.add('hidden');
    showToast(t('toast_data_updated'));
  } catch (e) {
    console.error('loadVizPlus:', e);
    if (statusTxt) statusTxt.textContent = t('obs_error', e.message);
    setTimeout(() => statusEl?.classList.add('hidden'), 3000);
  } finally {
    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-magic"></i>'; }
  }
}

async function _buildRadarChart() {
  const phEl = document.getElementById('vizplus-radar-ph');
  const wrap = document.getElementById('vizplus-radar-wrap');

  const topArtists = APP.topArtistsData.length
    ? APP.topArtistsData.slice(0, 15)
    : (await API.call('user.getTopArtists', { period: 'overall', limit: 15 })).topartists?.artist || [];

  const TARGET_GENRES = ['rock','pop','electronic','hip-hop','metal','jazz','classical','indie','r&b','country'];
  const scores = {};
  TARGET_GENRES.forEach(g => { scores[g] = 0; });

  const tagResults = await Promise.allSettled(topArtists.map(a => API.call('artist.getTopTags', { artist: a.name })));
  const IGNORED    = new Set(['seen live','favorites','favourite','love','awesome','all','good','new','old']);

  tagResults.forEach((res, i) => {
    if (res.status !== 'fulfilled') return;
    const tags   = res.value.toptags?.tag || [];
    const weight = topArtists.length - i;
    tags.slice(0, 10).forEach(tag => {
      const name = (tag.name || '').toLowerCase().trim();
      for (const genre of TARGET_GENRES) {
        if (name.includes(genre) && !IGNORED.has(name)) scores[genre] += (parseInt(tag.count) || 30) * weight;
      }
    });
  });

  const labels = TARGET_GENRES.map(g => g.charAt(0).toUpperCase() + g.slice(1));
  const data   = TARGET_GENRES.map(g => scores[g]);

  if (data.every(v => v === 0)) {
    if (phEl) phEl.innerHTML = `<i class="fas fa-spider fa-2x"></i><p>${t('unavailable')}</p>`;
    return;
  }

  if (phEl) phEl.classList.add('hidden');
  if (wrap) wrap.classList.remove('hidden');

  destroyChart('chart-radar');
  const c = getThemeColors();
  APP.charts['chart-radar'] = new Chart(document.getElementById('chart-radar'), {
    type: 'radar',
    data: {
      labels,
      datasets: [{
        label: 'Genres',
        data,
        backgroundColor: 'rgba(99,102,241,0.15)',
        borderColor: '#6366f1',
        pointBackgroundColor: CHART_PALETTE,
        pointBorderColor: '#fff',
        pointBorderWidth: 2,
        pointRadius: 5,
        borderWidth: 2,
      }],
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      animation: { duration: 800 },
      plugins: { legend: { display: false }, tooltip: { callbacks: { label: ctx => ` ${ctx.raw}` } } },
      scales: { r: { grid: { color: c.grid }, ticks: { color: c.text, font: { size: 10 }, backdropColor: 'transparent' }, pointLabels: { color: c.text, font: { size: 12 } }, beginAtZero: true } },
    },
  });
}

async function _buildTreemap() {
  const phEl = document.getElementById('vizplus-treemap-ph');
  const wrap = document.getElementById('vizplus-treemap-wrap');

  let artists = APP.topArtistsData;
  if (artists.length < 20) {
    const d = await API.call('user.getTopArtists', { period: 'overall', limit: 100 });
    artists = d.topartists?.artist || [];
    APP.topArtistsData = artists;
  }
  const top100 = artists.slice(0, 100);
  if (!top100.length) return;

  if (phEl) phEl.classList.add('hidden');
  if (wrap) wrap.classList.remove('hidden');

  const treeData = top100.map((a, i) => ({ label: a.name, value: parseInt(a.playcount) || 1, color: CHART_PALETTE[i % CHART_PALETTE.length] + 'cc' }));
  destroyChart('chart-treemap');
  APP.charts['chart-treemap'] = new Chart(document.getElementById('chart-treemap'), {
    type: 'treemap',
    data: {
      datasets: [{
        label: 'Top 100',
        tree: treeData,
        key: 'value',
        labels: { display: true, formatter: (ctx) => { const d = ctx.dataset.data[ctx.dataIndex]; return d ? [d._data.label, formatNum(d._data.value)] : ''; } },
        backgroundColor: (ctx) => { const d = ctx.dataset.data[ctx.dataIndex]; return d?._data?.color || '#6366f1cc'; },
        borderWidth: 1, borderColor: 'rgba(0,0,0,0.25)', spacing: 2,
      }],
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      animation: { duration: 600 },
      plugins: {
        legend: { display: false },
        tooltip: { callbacks: { title: (items) => items[0]?.raw?._data?.label || '', label: (ctx) => ` ${formatNum(ctx.raw?._data?.value)} ${t('plays')}` } },
      },
    },
  });
}

async function _buildSankey() {
  const phEl = document.getElementById('vizplus-sankey-ph');
  const wrap = document.getElementById('vizplus-sankey-wrap');
  const svg  = document.getElementById('chart-sankey');

  if (!APP.fullHistory || APP.fullHistory.length < 50) {
    if (phEl) phEl.innerHTML = `<i class="fas fa-stream fa-2x"></i><p>${t('adv_analyzed_sub')}</p>`;
    return;
  }

  if (phEl) phEl.classList.add('hidden');
  if (wrap) wrap.classList.remove('hidden');

  const transitions = new Map();
  const top20Artists = new Set((APP.topArtistsData.slice(0, 20) || []).map(a => a.name.toLowerCase()));
  const history = [...APP.fullHistory].filter(t => parseInt(t.date?.uts || 0) > 0).sort((a, b) => parseInt(a.date?.uts) - parseInt(b.date?.uts));

  const SESSION_GAP = 30 * 60;
  let prevArtist = null, prevTs = 0;

  for (const track of history) {
    const ts     = parseInt(track.date?.uts || 0);
    const artist = (track.artist?.['#text'] || track.artist?.name || '').trim();
    if (!artist || !top20Artists.has(artist.toLowerCase())) { prevArtist = null; continue; }
    if (prevArtist && prevArtist !== artist && (ts - prevTs) < SESSION_GAP) {
      const key = `${prevArtist}→${artist}`;
      transitions.set(key, (transitions.get(key) || 0) + 1);
    }
    prevArtist = artist; prevTs = ts;
  }

  const topLinks  = [...transitions.entries()].sort((a, b) => b[1] - a[1]).slice(0, 30);
  if (!topLinks.length) {
    if (phEl) { phEl.classList.remove('hidden'); phEl.innerHTML = `<i class="fas fa-stream fa-2x"></i><p>${t('unavailable')}</p>`; }
    if (wrap) wrap.classList.add('hidden');
    return;
  }

  const nodeNames = [...new Set(topLinks.flatMap(([k]) => k.split('→')))];
  const nodeIdx   = Object.fromEntries(nodeNames.map((n, i) => [n, i]));
  const nodes     = nodeNames.map(n => ({ name: n }));
  const links     = topLinks.map(([k, v]) => {
    const [src, tgt] = k.split('→');
    if (nodeIdx[src] === undefined || nodeIdx[tgt] === undefined) return null;
    return { source: nodeIdx[src], target: nodeIdx[tgt], value: v };
  }).filter(Boolean);

  const container = svg.parentElement;
  const size      = Math.min(container.clientWidth || 500, 500);

  if (typeof d3 === 'undefined' || typeof d3.sankey === 'undefined') {
    if (phEl) { phEl.classList.remove('hidden'); phEl.innerHTML = `<i class="fas fa-stream fa-2x"></i><p>D3 Sankey unavailable</p>`; }
    return;
  }

  d3.select(svg).selectAll('*').remove();
  const margin = { top: 10, right: 10, bottom: 10, left: 10 };
  const width  = size - margin.left - margin.right;
  const height = Math.min(size, 400) - margin.top - margin.bottom;

  const g = d3.select(svg)
    .attr('width', size).attr('height', Math.min(size, 400))
    .append('g').attr('transform', `translate(${margin.left},${margin.top})`);

  const sankey = d3.sankey().nodeWidth(15).nodePadding(10).size([width, height]);
  const graph  = sankey({ nodes: nodes.map(d => Object.assign({}, d)), links: links.map(d => Object.assign({}, d)) });

  g.append('g').selectAll('path').data(graph.links).join('path')
    .attr('d', d3.sankeyLinkHorizontal())
    .attr('stroke', (d, i) => CHART_PALETTE[i % CHART_PALETTE.length])
    .attr('stroke-width', d => Math.max(1, d.width))
    .attr('fill', 'none').attr('opacity', 0.45);

  g.append('g').selectAll('rect').data(graph.nodes).join('rect')
    .attr('x', d => d.x0).attr('y', d => d.y0)
    .attr('height', d => d.y1 - d.y0).attr('width', d => d.x1 - d.x0)
    .attr('fill', (_, i) => CHART_PALETTE[i % CHART_PALETTE.length])
    .append('title').text(d => d.name);

  g.append('g').selectAll('text').data(graph.nodes).join('text')
    .attr('x', d => d.x0 < width / 2 ? d.x1 + 6 : d.x0 - 6)
    .attr('y', d => (d.y1 + d.y0) / 2).attr('dy', '0.35em')
    .attr('text-anchor', d => d.x0 < width / 2 ? 'start' : 'end')
    .attr('font-size', '11px').attr('fill', getThemeColors().text)
    .text(d => d.name.length > 18 ? d.name.slice(0, 16) + '…' : d.name);
}

async function _buildSunburst() {
  const phEl   = document.getElementById('vizplus-sunburst-ph');
  const wrapEl = document.getElementById('vizplus-sunburst-wrap');
  const svgEl  = document.getElementById('chart-sunburst');

  if (!svgEl) return;

  const artists = APP.topArtistsData.length
    ? APP.topArtistsData.slice(0, 20)
    : (await API.call('user.getTopArtists', { period: 'overall', limit: 20 })).topartists?.artist || [];

  const IGNORED  = new Set(['seen live','favorites','favourite','love','awesome','all','good','new','old','best','epic']);
  const genreMap = new Map();

  const tagResults = await Promise.allSettled(artists.map(a => API.call('artist.getTopTags', { artist: a.name })));
  tagResults.forEach((res, i) => {
    if (res.status !== 'fulfilled') return;
    const tags   = (res.value.toptags?.tag || []).slice(0, 4);
    const artist = artists[i];
    const plays  = parseInt(artist.playcount || 1);
    tags.forEach(tag => {
      const g = (tag.name || '').toLowerCase().trim();
      if (!g || g.length < 2 || IGNORED.has(g)) return;
      if (!genreMap.has(g)) genreMap.set(g, new Map());
      const aMap = genreMap.get(g);
      aMap.set(artist.name, (aMap.get(artist.name) || 0) + plays);
    });
  });

  const topGenres = [...genreMap.entries()]
    .map(([g, aMap]) => ({ g, total: [...aMap.values()].reduce((a, b) => a + b, 0) }))
    .sort((a, b) => b.total - a.total).slice(0, 8).map(({ g }) => g);

  if (!topGenres.length) {
    if (phEl) { phEl.classList.remove('hidden'); phEl.querySelector?.('p') && (phEl.querySelector('p').textContent = t('unavailable')); }
    return;
  }

  const rootData = {
    name: 'Genres',
    children: topGenres.map((genre, gi) => ({
      name: genre.charAt(0).toUpperCase() + genre.slice(1),
      color: CHART_PALETTE[gi % CHART_PALETTE.length],
      children: [...genreMap.get(genre).entries()].sort((a, b) => b[1] - a[1]).slice(0, 5).map(([artist, plays]) => ({ name: artist, value: plays })),
    })),
  };

  if (phEl)   phEl.classList.add('hidden');
  if (wrapEl) wrapEl.classList.remove('hidden');

  if (typeof d3 === 'undefined') return;

  const container = svgEl.parentElement;
  const size      = Math.min(container.clientWidth || 500, 500);
  const radius    = size / 2;

  d3.select(svgEl).selectAll('*').remove();
  const svg = d3.select(svgEl).attr('width', size).attr('height', size);
  const g   = svg.append('g').attr('transform', `translate(${radius},${radius})`);

  const hierarchy = d3.hierarchy(rootData).sum(d => d.value || 0);
  const partition = d3.partition().size([2 * Math.PI, radius]);
  const root      = partition(hierarchy);

  const arc = d3.arc()
    .startAngle(d => d.x0).endAngle(d => d.x1)
    .innerRadius(d => d.y0).outerRadius(d => d.y1 - 2);

  g.selectAll('path').data(root.descendants().filter(d => d.depth)).join('path')
    .attr('d', arc)
    .attr('fill', d => { let node = d; while (node.depth > 1) node = node.parent; return node.data.color || '#6366f1'; })
    .attr('opacity', d => 1 - d.depth * 0.15)
    .attr('stroke', '#1a1033').attr('stroke-width', 1)
    .append('title').text(d => `${d.data.name}: ${formatNum(d.value)}`);
}

/* ============================================================
   MUSICAL PROFILE
   ============================================================ */
async function loadMusicalProfile() {
  const phEl   = document.getElementById('profile-placeholder');
  const wrapEl = document.getElementById('profile-chart-wrap');
  const legEl  = document.getElementById('profile-tag-legend');
  const btnEl  = document.getElementById('profile-load-btn');

  if (btnEl) { btnEl.disabled = true; btnEl.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'; }
  if (phEl)  phEl.classList.add('hidden');

  const TOP_TAGS_COUNT = 5, MONTHS_BACK = 6;
  const IGNORED_TAGS = new Set(['seen live','favorites','favourite','love','awesome','beautiful','epic','amazing','classic','my favourite','all','good','new','old','best','cool','hot','great']);

  try {
    const now = new Date();
    const labels = [], tagData = {};

    for (let mBack = MONTHS_BACK - 1; mBack >= 0; mBack--) {
      const d      = new Date(now.getFullYear(), now.getMonth() - mBack, 1);
      labels.push(MONTHS_SHORT()[d.getMonth()] + ' ' + d.getFullYear().toString().slice(-2));

      const period    = mBack <= 1 ? '1month' : mBack <= 3 ? '3month' : '6month';
      let artists     = APP.topArtistsData;
      if (!artists.length) {
        const d2 = await API.call('user.getTopArtists', { period, limit: 10 });
        artists  = d2.topartists?.artist || [];
      }
      const top8      = artists.slice(0, 8);
      const tagResults= await Promise.allSettled(top8.map(a => API.call('artist.getTopTags', { artist: a.name })));
      const monthScores = new Map();

      tagResults.forEach((res, i) => {
        if (res.status !== 'fulfilled') return;
        const tags   = res.value.toptags?.tag || [];
        const weight = 8 - i;
        tags.slice(0, 6).forEach(tag => {
          const name = (tag.name || '').toLowerCase().trim();
          if (!name || name.length < 2 || IGNORED_TAGS.has(name)) return;
          monthScores.set(name, (monthScores.get(name) || 0) + (parseInt(tag.count) || 30) * weight);
        });
      });

      monthScores.forEach((score, tag) => {
        if (!tagData[tag]) tagData[tag] = Array(MONTHS_BACK).fill(0);
        tagData[tag][MONTHS_BACK - 1 - mBack] = score;
      });
      await sleep(80);
    }

    const tagTotals = Object.entries(tagData)
      .map(([tag, scores]) => ({ tag, total: scores.reduce((a, b) => a + b, 0) }))
      .sort((a, b) => b.total - a.total).slice(0, TOP_TAGS_COUNT);

    if (!tagTotals.length) {
      if (phEl) { phEl.classList.remove('hidden'); phEl.querySelector?.('p') && (phEl.querySelector('p').textContent = t('unavailable')); }
      return;
    }

    if (wrapEl) wrapEl.classList.remove('hidden');

    const c = getThemeColors();
    const datasets = tagTotals.map(({ tag }, idx) => ({
      label:           tag.charAt(0).toUpperCase() + tag.slice(1),
      data:            tagData[tag] || Array(MONTHS_BACK).fill(0),
      borderColor:     CHART_PALETTE[idx % CHART_PALETTE.length],
      backgroundColor: CHART_PALETTE[idx % CHART_PALETTE.length] + '18',
      fill: false, tension: 0.4, pointRadius: 4, pointHoverRadius: 6, borderWidth: 2,
    }));

    destroyChart('chart-profile-tags');
    APP.charts['chart-profile-tags'] = new Chart(document.getElementById('chart-profile-tags'), {
      type: 'line',
      data: { labels, datasets },
      options: {
        ...baseChartOpts(),
        animation: { duration: 700 },
        plugins: {
          legend: { display: false },
          tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${ctx.dataset.label} — ${formatNum(ctx.raw)}` } },
        },
        scales: {
          x: { grid: { display: false }, ticks: { color: c.text } },
          y: { grid: { color: c.grid },  ticks: { color: c.text } },
        },
      },
    });

    if (legEl) {
      legEl.innerHTML = tagTotals.map(({ tag }, idx) => `
        <div class="tag-legend-item">
          <span class="tag-legend-dot" style="background:${CHART_PALETTE[idx % CHART_PALETTE.length]}"></span>
          ${escHtml(tag.charAt(0).toUpperCase() + tag.slice(1))}
        </div>`).join('');
      legEl.classList.remove('hidden');
    }
  } catch (e) {
    console.warn('loadMusicalProfile:', e);
    if (phEl) { phEl.classList.remove('hidden'); phEl.querySelector?.('p') && (phEl.querySelector('p').textContent = t('obs_error', e.message)); }
  } finally {
    if (btnEl) { btnEl.disabled = false; btnEl.innerHTML = '<i class="fas fa-magic"></i>'; }
  }
}

/* ============================================================
   ARTIST MODAL
   ============================================================ */
async function openArtistModal(artistName, artistUrl, userPlays) {
  const modal = document.getElementById('artist-modal');
  if (!modal) return;

  document.getElementById('am-artist-name').textContent = artistName;
  document.getElementById('am-photo').src = '';
  document.getElementById('am-photo').classList.add('hidden');
  document.getElementById('am-photo-fallback').classList.remove('hidden');
  document.getElementById('am-photo-initials').textContent = artistName[0].toUpperCase();
  document.getElementById('am-photo-fallback').style.background = nameToGradient(artistName);

  document.getElementById('am-listeners').querySelector('span').textContent           = '…';
  document.getElementById('am-playcount-global').querySelector('span').textContent    = '…';
  document.getElementById('am-playcount-user').querySelector('span').textContent      = userPlays ? formatNum(userPlays) : '…';

  document.getElementById('am-tags').innerHTML = '';
  document.getElementById('am-bio').innerHTML  = '';
  document.getElementById('am-bio').classList.add('hidden');
  document.getElementById('am-bio-toggle').classList.add('hidden');
  document.getElementById('am-bio-loading').classList.remove('hidden');
  document.getElementById('am-top-tracks').innerHTML = '';
  document.getElementById('am-top-tracks').classList.add('hidden');
  document.getElementById('am-tracks-loading').classList.remove('hidden');
  document.getElementById('am-albums').innerHTML = '';
  document.getElementById('am-albums').classList.add('hidden');
  document.getElementById('am-albums-loading').classList.remove('hidden');

  const q = encodeURIComponent(artistName);
  document.getElementById('am-lastfm-link').href  = artistUrl || `https://www.last.fm/music/${q}`;
  document.getElementById('am-spotify-link').href = `spotify:search:${q}`;
  document.getElementById('am-youtube-link').href = `https://www.youtube.com/results?search_query=${q}`;

  modal.classList.remove('hidden');
  document.body.style.overflow = 'hidden';

  try {
    const [infoRes, tracksRes, albumsRes] = await Promise.allSettled([
      API.call('artist.getInfo',      { artist: artistName, autocorrect: 1 }),
      API.call('artist.getTopTracks', { artist: artistName, autocorrect: 1, limit: 5 }),
      API.call('artist.getTopAlbums', { artist: artistName, autocorrect: 1, limit: 6 }),
    ]);

    if (infoRes.status === 'fulfilled') {
      const info   = infoRes.value.artist;
      const artImg = await getArtistImage(artistName);
      if (artImg) {
        const photoEl = document.getElementById('am-photo');
        photoEl.src   = artImg;
        photoEl.onload = () => { photoEl.classList.remove('hidden'); document.getElementById('am-photo-fallback').classList.add('hidden'); };
        photoEl.onerror = () => {};
      }

      document.getElementById('am-listeners').querySelector('span').textContent        = formatNum(info.stats?.listeners);
      document.getElementById('am-playcount-global').querySelector('span').textContent = formatNum(info.stats?.playcount);

      const tags = (info.tags?.tag || []).slice(0, 6);
      document.getElementById('am-tags').innerHTML = tags.map(tag => `<span class="am-tag">${escHtml(tag.name)}</span>`).join('');

      const bioRaw = info.bio?.content || info.bio?.summary || '';
      const bio    = bioRaw.replace(/<a[^>]*>.*?<\/a>/gi, '').replace(/<[^>]+>/g, '').trim();
      document.getElementById('am-bio-loading').classList.add('hidden');

      if (bio) {
        const bioEl = document.getElementById('am-bio');
        bioEl.textContent = bio;
        bioEl.classList.add('am-bio--collapsed');
        bioEl.classList.remove('expanded', 'hidden');
        if (bio.length > 280) {
          const tog = document.getElementById('am-bio-toggle');
          if (tog) { tog.classList.remove('hidden', 'expanded'); tog.innerHTML = `${t('bio_read_more')} <i class="fas fa-chevron-down"></i>`; }
        }
      } else {
        const bioEl = document.getElementById('am-bio');
        bioEl.textContent = t('bio_none');
        bioEl.classList.remove('am-bio--collapsed', 'hidden');
      }
    } else {
      document.getElementById('am-bio-loading').classList.add('hidden');
      document.getElementById('am-bio').textContent = t('bio_unavailable');
      document.getElementById('am-bio').classList.remove('hidden');
    }

    document.getElementById('am-tracks-loading').classList.add('hidden');
    if (tracksRes.status === 'fulfilled') {
      const tracks = (tracksRes.value.toptracks?.track || []).slice(0, 5);
      const list   = document.getElementById('am-top-tracks');
      if (tracks.length) {
        list.innerHTML = tracks.map((tr, i) => `
          <li>
            <span class="am-track-rank">${i + 1}</span>
            <span class="am-track-name" title="${escHtml(tr.name)}">${escHtml(tr.name)}</span>
            <span class="am-track-plays">${formatNum(tr.playcount)}</span>
          </li>`).join('');
      } else {
        list.innerHTML = `<li style="color:var(--text-muted);font-size:.84rem;list-style:none;padding:8px 0">${t('tracks_none')}</li>`;
      }
      list.classList.remove('hidden');
    } else {
      document.getElementById('am-top-tracks').innerHTML = `<li style="color:var(--text-muted);font-size:.84rem;list-style:none">${t('tracks_unavailable')}</li>`;
      document.getElementById('am-top-tracks').classList.remove('hidden');
    }

    document.getElementById('am-albums-loading').classList.add('hidden');
    if (albumsRes.status === 'fulfilled') {
      const albums  = (albumsRes.value.topalbums?.album || []).slice(0, 6);
      const albumEl = document.getElementById('am-albums');
      albumEl.innerHTML = albums.map(alb => {
        const img    = alb.image?.find(i => i.size === 'medium')?.['#text'] || '';
        const hasImg = !isDefaultImg(img);
        const letter = (alb.name || '?')[0].toUpperCase();
        const bg     = nameToGradient(alb.name);
        return `
          <div class="am-album-card" onclick="window.open('${alb.url}','_blank')" title="${escHtml(alb.name)}">
            <div class="am-album-img">
              ${hasImg ? `<img src="${img}" alt="${escHtml(alb.name)}" loading="lazy">`
                       : `<div style="width:100%;height:100%;background:${bg};display:flex;align-items:center;justify-content:center;font-size:1.4rem;font-weight:900;color:white">${letter}</div>`}
            </div>
            <div class="am-album-name">${escHtml(alb.name)}</div>
          </div>`;
      }).join('');
      albumEl.classList.remove('hidden');
    }
  } catch (e) { console.warn('openArtistModal:', e); }
}

function closeArtistModal(e) {
  if (e && e.target !== document.getElementById('artist-modal')) return;
  document.getElementById('artist-modal')?.classList.add('hidden');
  document.body.style.overflow = '';
}

function toggleArtistBio() {
  const bioEl = document.getElementById('am-bio');
  const togEl = document.getElementById('am-bio-toggle');
  if (!bioEl || !togEl) return;
  const isExpanded = bioEl.classList.toggle('expanded');
  togEl.classList.toggle('expanded', isExpanded);
  togEl.innerHTML  = isExpanded
    ? `${t('bio_collapse')} <i class="fas fa-chevron-up"></i>`
    : `${t('bio_read_more')} <i class="fas fa-chevron-down"></i>`;
}

/* ============================================================
   SETTINGS
   ============================================================ */
function syncSettingsFields() {
  const uEl  = document.getElementById('settings-username');
  const kEl  = document.getElementById('settings-apikey');
  const remEl= document.getElementById('settings-remember');
  if (uEl)   uEl.value   = APP.username || '';
  if (kEl)   kEl.value   = APP.apiKey   || '';
  if (remEl) remEl.checked = !!(localStorage.getItem('ls_username'));

  document.querySelectorAll('.lang-btn').forEach(b => b.classList.toggle('active', b.dataset.lang === APP.language));
  document.querySelectorAll('.acc-dot').forEach(b => b.classList.toggle('active', b.dataset.color === (APP.currentAccent || 'purple')));
}

function toggleSettingsApiKey() {
  const inp = document.getElementById('settings-apikey');
  const ico = document.getElementById('settings-eye-icon');
  if (!inp) return;
  inp.type      = inp.type === 'password' ? 'text' : 'password';
  ico.className = inp.type === 'password' ? 'fas fa-eye' : 'fas fa-eye-slash';
}

function updateUsername() {
  const uEl = document.getElementById('settings-username');
  if (!uEl) return;
  const val = uEl.value.trim();
  if (!val) { showToast(t('settings_username_invalid'), 'error'); return; }
  APP.username = val;
  saveSession();
  const setupEl = document.getElementById('input-username');
  if (setupEl) setupEl.value = val;
  showToast(t('toast_username_ok'));
}

function updateApiKey() {
  const kEl = document.getElementById('settings-apikey');
  if (!kEl) return;
  const val = kEl.value.trim();
  if (!val || val.length < 30) { showToast(t('settings_apikey_invalid'), 'error'); return; }
  APP.apiKey = val;
  saveSession();
  const setupEl = document.getElementById('input-apikey');
  if (setupEl) setupEl.value = val;
  showToast(t('toast_apikey_ok'));
}

function clearAppCache() {
  Cache.clear();
  APP.fullHistory = null;
  APP.streakData  = null;
  showToast(t('toast_cache_cleared'));
}

/* ============================================================
   SHARE SYSTEM — Web Share API + clipboard fallback
   ============================================================ */

/**
 * Partage générique : essaie navigator.share, fallback clipboard.
 * @param {Object} payload — { title, text, url }
 */
async function _share(payload) {
  if (navigator.share) {
    try { await navigator.share(payload); return; } catch (e) {
      if (e.name === 'AbortError') return; // utilisateur a annulé
    }
  }
  // Fallback clipboard
  const str = `${payload.text}${payload.url ? '\n' + payload.url : ''}`;
  try {
    await navigator.clipboard.writeText(str);
    showToast(t('toast_link_copied'));
  } catch {
    prompt(t('toast_link_copied') + ':', str);
  }
}

/** Partage un titre individuel */
async function shareTrack(trackName, artistName, plays, url) {
  const lastfmUrl = url || `https://www.last.fm/music/${encodeURIComponent(artistName)}/_/${encodeURIComponent(trackName)}`;
  const text = `🎵 ${trackName} — ${artistName}\n` +
               `${formatNum(plays)} ${t('plays')} · LastStats / last.fm`;
  await _share({ title: `${trackName} — ${artistName}`, text, url: lastfmUrl });
}

/** Partage un artiste individuel */
async function shareArtist(artistName, plays, url) {
  const lastfmUrl = url || `https://www.last.fm/music/${encodeURIComponent(artistName)}`;
  const text = `🎤 ${artistName}\n` +
               `${formatNum(plays)} ${t('plays')} · LastStats / last.fm`;
  await _share({ title: artistName, text, url: lastfmUrl });
}

/** Partage un album individuel */
async function shareAlbum(albumName, artistName, plays, url) {
  const lastfmUrl = url || `https://www.last.fm/music/${encodeURIComponent(artistName)}/${encodeURIComponent(albumName)}`;
  const text = `💿 ${albumName} — ${artistName}\n` +
               `${formatNum(plays)} ${t('plays')} · LastStats / last.fm`;
  await _share({ title: `${albumName} — ${artistName}`, text, url: lastfmUrl });
}

/** Partage une stat du dashboard */
async function shareStat(icon, label, value) {
  const profileUrl = `https://www.last.fm/user/${encodeURIComponent(APP.username)}`;
  const text = `${icon} ${label} : ${value}\n@${APP.username} · LastStats`;
  await _share({ title: `LastStats — ${APP.username}`, text, url: profileUrl });
}

/** Partage le profil complet */
async function shareProfile() {
  const u       = APP.userInfo;
  const total   = formatNum(u?.playcount || 0);
  const url     = u?.url || `https://www.last.fm/user/${encodeURIComponent(APP.username)}`;
  const text    = `🎵 ${APP.username} — ${total} ${t('scrobbles')} sur Last.fm\nVia LastStats`;
  await _share({ title: `Profil LastStats — ${APP.username}`, text, url });
}

/* ============================================================
   NOW PLAYING — Share
   ============================================================ */
async function shareNowPlaying() {
  const track  = document.getElementById('np-track')?.textContent  || '?';
  const artist = document.getElementById('np-artist')?.textContent || '?';
  const url    = `https://www.last.fm/music/${encodeURIComponent(artist)}/_/${encodeURIComponent(track)}`;
  const text   = t('np_share_text', track, artist);

  if (navigator.share) {
    try { await navigator.share({ title: `${track} — ${artist}`, text, url }); return; }
    catch {}
  }
  try {
    await navigator.clipboard.writeText(`${text}\n${url}`);
    showToast(t('toast_link_copied'));
  } catch {
    prompt(t('toast_link_copied') + ':', url);
  }
}

/* ============================================================
   PERIOD COMPARISON
   ============================================================ */
const PERIOD_LABELS = {
  '7day':    'This week',    '1month': 'This month',   '3month': 'Last 3 months',
  '6month':  'Last 6 months','12month':'This year',    'overall':'All time',
};

function _prevPeriodKey(period) {
  return { '7day':'1month','1month':'3month','3month':'6month','6month':'12month','12month':'overall','overall':'overall' }[period] || 'overall';
}

async function loadPeriodComparison() {
  const selA  = document.getElementById('compare-period-a');
  const selB  = document.getElementById('compare-period-b');
  const resEl = document.getElementById('compare-results');
  const ldEl  = document.getElementById('compare-loading');
  const descEl= document.getElementById('compare-desc');

  if (!selA || !selB) return;

  const periodA = selA.value;
  const labelA  = PERIOD_LABELS[periodA]   || periodA;
  const labelB  = PERIOD_LABELS[_prevPeriodKey(periodA)] || _prevPeriodKey(periodA);

  if (descEl) descEl.innerHTML = `<strong>${labelA}</strong> <span class="compare-vs-icon">vs</span> <strong>${labelB}</strong>`;

  const tagA = document.getElementById('cmp-period-tag-a');
  const tagB = document.getElementById('cmp-period-tag-b');
  if (tagA) tagA.textContent = labelA;
  if (tagB) tagB.textContent = labelB;

  if (resEl) resEl.classList.add('hidden');
  if (ldEl)  ldEl.classList.remove('hidden');

  try {
    const prevPeriod = _prevPeriodKey(periodA);
    const [dataA, dataB, topArtistsB] = await Promise.all([
      API.call('user.getTopArtists', { period: periodA,  limit: 1 }),
      API.call('user.getTopArtists', { period: prevPeriod, limit: 1 }),
      API.call('user.getTopArtists', { period: prevPeriod, limit: 3 }),
    ]);

    const totalA = parseInt(dataA.topartists?.['@attr']?.total || 0);
    const totalB = parseInt(dataB.topartists?.['@attr']?.total || 0);
    const scDiff = totalA - totalB;
    const scPct  = totalB > 0 ? ((scDiff / totalB) * 100).toFixed(1) : null;
    const top1A  = dataA.topartists?.artist?.[0]?.name || '—';
    const top1B  = (topArtistsB.topartists?.artist || [])[0]?.name || '—';
    const listenA= estimateListenTime(totalA);
    const listenB= estimateListenTime(totalB);

    _setCompareMetric('cmp-scrobbles-a', formatNum(totalA));
    _setCompareMetric('cmp-scrobbles-b', formatNum(totalB));
    _setCompareDelta('cmp-scrobbles-delta', scDiff, scPct);
    _setCompareMetric('cmp-artists-a', top1A);
    _setCompareMetric('cmp-artists-b', top1B);

    const ltAEl = document.getElementById('cmp-listen-a');
    const ltBEl = document.getElementById('cmp-listen-b');
    if (ltAEl) ltAEl.textContent = listenA;
    if (ltBEl) ltBEl.textContent = listenB;

    if (resEl) resEl.classList.remove('hidden');
  } catch (e) {
    showToast(t('toast_compare_error', e.message), 'error');
  } finally {
    if (ldEl) ldEl.classList.add('hidden');
  }
}

function _setCompareMetric(id, value) { const el = document.getElementById(id); if (el) el.textContent = value; }

function _setCompareDelta(id, diff, pct) {
  const el = document.getElementById(id);
  if (!el) return;
  if (pct === null || diff === 0) { el.textContent = t('versus_stable'); el.className = 'cmp-delta cmp-flat'; }
  else {
    const sign = diff > 0 ? '+' : '';
    el.textContent = `${diff > 0 ? '▲' : '▼'} ${sign}${pct}%`;
    el.className   = `cmp-delta ${diff > 0 ? 'cmp-up' : 'cmp-down'}`;
  }
  el.classList.remove('hidden');
}

/* ============================================================
   OHW TOOLTIP
   ============================================================ */
function toggleOhwTooltip() {
  document.getElementById('ohw-tooltip')?.classList.toggle('ohw-tooltip--visible');
}
function closeOhwTooltip() {
  document.getElementById('ohw-tooltip')?.classList.remove('ohw-tooltip--visible');
}
document.addEventListener('click', (e) => {
  const tooltip = document.getElementById('ohw-tooltip');
  const btn     = document.querySelector('.info-tooltip-btn');
  if (!tooltip || !btn) return;
  if (!tooltip.contains(e.target) && !btn.contains(e.target)) tooltip.classList.remove('ohw-tooltip--visible');
});

/* ============================================================
   PWA FORCE UPDATE
   ============================================================ */
async function forceSwUpdate() {
  const btn = document.getElementById('sw-update-btn');
  if (btn) { btn.disabled = true; btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${t('toast_updating')}`; }
  try {
    if ('caches' in window) { const keys = await caches.keys(); await Promise.all(keys.map(k => caches.delete(k))); }
    if ('serviceWorker' in navigator) { const regs = await navigator.serviceWorker.getRegistrations(); await Promise.all(regs.map(r => r.unregister())); }
    Cache.clear();
    showToast(t('toast_updating'));
    await sleep(800);
    window.location.reload(true);
  } catch (e) {
    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-sync-alt"></i>'; }
    showToast(t('toast_update_error'), 'error');
  }
}

/* ============================================================
   EXPORT CSV / JSON
   ============================================================ */
function exportData(format) {
  const sources = [
    { type: t('csv_artist_type'), items: APP.topArtistsData, name: d => d.name, artist: () => '', plays: d => d.playcount, url: d => d.url },
    { type: t('csv_album_type'),  items: APP.topAlbumsData,  name: d => d.name, artist: d => d.artist?.name || '', plays: d => d.playcount, url: d => d.url },
    { type: t('csv_track_type'),  items: APP.topTracksData,  name: d => d.name, artist: d => d.artist?.name || '', plays: d => d.playcount, url: d => d.url },
  ];

  const allRows = sources.flatMap(s => s.items.map(d => ({
    [t('csv_type')]:   s.type,
    [t('csv_name')]:   s.name(d),
    [t('csv_artist')]: s.artist(d),
    [t('csv_plays')]:  s.plays(d),
    [t('csv_url')]:    s.url(d),
  })));

  if (format === 'json') {
    const blob = new Blob([JSON.stringify(allRows, null, 2)], { type: 'application/json' });
    const a    = document.createElement('a');
    a.href     = URL.createObjectURL(blob);
    a.download = `laststats-${APP.username}.json`;
    a.click();
    showToast(t('toast_export_json'));
  } else {
    const headers = Object.keys(allRows[0] || {});
    const csv     = [headers.join(','), ...allRows.map(r => headers.map(h => `"${String(r[h] || '').replace(/"/g, '""')}"`).join(','))].join('\n');
    const blob    = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const a       = document.createElement('a');
    a.href        = URL.createObjectURL(blob);
    a.download    = `laststats-${APP.username}.csv`;
    a.click();
    showToast(t('toast_export_csv'));
  }
}
