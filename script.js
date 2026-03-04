'use strict';

/* ============================================================
   LASTSTATS — SCRIPT v2
   Modules : Cache · API (paginé) · UI · Charts · Stats avancées
   ============================================================ */

// ── Constantes ──
const LASTFM_URL    = 'https://ws.audioscrobbler.com/2.0/';
const CACHE_TTL     = 30 * 60 * 1000;   // 30 min
const TOP_LIMIT     = 50;
const DISPLAY_LIMIT = 20;
const DEFAULT_IMG   = '2a96cbd8b46e442fc41c2b86b821562f';

const MONTHS_FR    = ['Janvier','Février','Mars','Avril','Mai','Juin',
                      'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
const MONTHS_SHORT = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
const DAYS_FR      = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];

const CHART_PALETTE = [
  '#6366f1','#8b5cf6','#a855f7','#d946ef','#ec4899',
  '#f43f5e','#f97316','#eab308','#22c55e','#06b6d4',
  '#3b82f6','#0ea5e9','#14b8a6','#84cc16','#78716c',
];

// ── État global ──
const APP = {
  apiKey:        '',
  username:      '',
  userInfo:      null,
  charts:        {},
  topArtistsData:[],
  topAlbumsData: [],
  topTracksData: [],
  regYear:       new Date().getFullYear() - 5,
  currentTheme:  'dark',
  fullHistory:   null,  // tracks paginées (si chargées)
};

/* ============================================================
   MODULE CACHE (localStorage)
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
      if (Date.now() - ts > CACHE_TTL) {
        localStorage.removeItem(this._key(method, params));
        return null;
      }
      return data;
    } catch { return null; }
  },

  set(method, params = {}, data) {
    try {
      localStorage.setItem(
        this._key(method, params),
        JSON.stringify({ data, ts: Date.now() })
      );
    } catch {
      this._purge();
      try {
        localStorage.setItem(
          this._key(method, params),
          JSON.stringify({ data, ts: Date.now() })
        );
      } catch { /* silencieux */ }
    }
  },

  _purge() {
    const keys = Object.keys(localStorage).filter(k => k.startsWith(this.prefix));
    // Supprimer les plus anciennes (30 entrées)
    keys.sort().slice(0, Math.min(30, keys.length)).forEach(k => localStorage.removeItem(k));
  },

  clear() {
    Object.keys(localStorage)
      .filter(k => k.startsWith(this.prefix))
      .forEach(k => localStorage.removeItem(k));
  },
};

/* ============================================================
   MODULE API LAST.FM
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
    if (data.error) throw new Error(data.message || `Erreur API ${data.error}`);
    return data;
  },

  // Scrobbles pour un mois donné (limit=1 → on récupère juste le total)
  async getMonthScrobbles(year, month) {
    const from = Math.floor(new Date(year, month, 1).getTime() / 1000);
    const to   = Math.floor(new Date(year, month + 1, 0, 23, 59, 59).getTime() / 1000);
    try {
      const data = await this.call('user.getRecentTracks', { from, to, limit: 1 });
      return parseInt(data.recenttracks?.['@attr']?.total || 0);
    } catch { return 0; }
  },

  /* ----------------------------------------------------------
     PAGINATION : Récupère TOUTES les pages de recentTracks
     onProgress(page, totalPages, scrobblesLoaded) → callback UI
     yearFrom/yearTo → filtrer par plage temporelle (UNIX ts)
  ---------------------------------------------------------- */
  async fetchAllPages(onProgress, yearFrom = null, yearTo = null) {
    const allTracks = [];
    let page = 1;
    let totalPages = 1;

    const baseParams = { limit: 200, extended: 0 };
    if (yearFrom) baseParams.from = yearFrom;
    if (yearTo)   baseParams.to   = yearTo;

    do {
      const params = { ...baseParams, page };

      // Tentatives : retry x2 en cas d'erreur réseau
      let data = null;
      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          data = await this._fetch('user.getRecentTracks', params);
          break;
        } catch (e) {
          if (attempt === 2) throw e;
          await sleep(1000 * (attempt + 1));
        }
      }

      const attr = data.recenttracks?.['@attr'] || {};
      totalPages = parseInt(attr.totalPages || 1);

      const raw = data.recenttracks?.track || [];
      const tracks = Array.isArray(raw) ? raw : [raw];

      // Filtrer le "now playing"
      for (const t of tracks) {
        if (!t['@attr']?.nowplaying) allTracks.push(t);
      }

      if (onProgress) onProgress(page, totalPages, allTracks.length);
      page++;

      // Petite pause entre les requêtes (anti-rate-limit)
      if (page <= totalPages) await sleep(150);

    } while (page <= totalPages);

    return allTracks;
  },
};

/* ============================================================
   UTILITAIRES
   ============================================================ */
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function formatNum(n) {
  if (n === null || n === undefined || n === '') return '—';
  return Number(n).toLocaleString('fr-FR');
}

function formatDate(unixTs) {
  if (!unixTs) return '—';
  return new Date(unixTs * 1000).toLocaleDateString('fr-FR', {
    year: 'numeric', month: 'long', day: 'numeric'
  });
}

function timeAgo(unixTs) {
  if (!unixTs) return '';
  const diff = Date.now() - unixTs * 1000;
  const days = Math.floor(diff / 86400000);
  if (days === 0) {
    const h = Math.floor(diff / 3600000);
    if (h === 0) return 'il y a quelques minutes';
    return `il y a ${h}h`;
  }
  if (days === 1) return 'hier';
  if (days < 30)  return `il y a ${days} jours`;
  if (days < 365) return `il y a ${Math.floor(days / 30)} mois`;
  return `il y a ${Math.floor(days / 365)} ans`;
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
  const t   = document.getElementById('toast');
  const ico = document.getElementById('toast-icon');
  document.getElementById('toast-txt').textContent = msg;
  ico.className = type === 'error' ? 'fas fa-times-circle' : 'fas fa-check-circle';
  ico.style.color = type === 'error' ? '#f87171' : '#22c55e';
  t.classList.add('show');
  clearTimeout(t._timer);
  t._timer = setTimeout(() => t.classList.remove('show'), 3200);
}

function showSetupError(msg) {
  const el = document.getElementById('setup-err');
  document.getElementById('setup-err-txt').textContent = msg;
  el.classList.remove('hidden');
}

/* ── Skeletons ── */
function skeletonMusicCards(n = 8) {
  return Array(n).fill(0).map((_, i) => `
    <div class="music-card sk" style="animation-delay:${i * 0.04}s">
      <div class="music-card-img" style="height:160px">
        <div class="sk-ln" style="width:100%;height:100%;border-radius:0"></div>
      </div>
      <div class="music-card-body">
        <div class="sk-ln w80"></div>
        <div class="sk-ln w60 mt8"></div>
      </div>
    </div>`).join('');
}

function skeletonTrackItems(n = 10) {
  return Array(n).fill(0).map((_, i) => `
    <div class="track-item sk" style="animation-delay:${i * 0.03}s">
      <div class="sk-ln" style="width:24px;height:24px;border-radius:50%"></div>
      <div style="flex:1;display:flex;flex-direction:column;gap:6px">
        <div class="sk-ln w80"></div>
        <div class="sk-ln w50"></div>
      </div>
    </div>`).join('');
}

/* ── Graphiques : options communes ── */
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
   INITIALISATION
   ============================================================ */
async function initApp() {
  const username = document.getElementById('input-username').value.trim();
  const apiKey   = document.getElementById('input-apikey').value.trim();
  const remember = document.getElementById('remember-me').checked;

  document.getElementById('setup-err').classList.add('hidden');

  if (!username) return showSetupError('Veuillez entrer votre nom d\'utilisateur Last.fm.');
  if (!apiKey || apiKey.length < 30) return showSetupError('La clé API doit faire 32 caractères hexadécimaux.');

  APP.apiKey   = apiKey;
  APP.username = username;

  const btn = document.getElementById('load-btn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Connexion…';

  try {
    const info = await API.call('user.getInfo', {}, true);
    APP.userInfo = info.user;
    APP.regYear  = new Date(parseInt(info.user.registered?.unixtime || 0) * 1000).getFullYear() || new Date().getFullYear() - 5;

    if (remember) {
      localStorage.setItem('ls_username', username);
      localStorage.setItem('ls_apikey',   apiKey);
    } else {
      localStorage.removeItem('ls_username');
      localStorage.removeItem('ls_apikey');
    }

    const theme = localStorage.getItem('ls_theme') || 'dark';
    applyTheme(theme);

    document.getElementById('setup-screen').classList.add('hidden');
    document.getElementById('app').classList.remove('hidden');

    setupProfileUI();
    await loadDashboard();

    // Chargement parallèle (non bloquant)
    Promise.all([
      loadTopArtists('overall'),
      loadTopAlbums('overall'),
      loadTopTracks('overall'),
    ]);

    setupChartsSection();
    setupWrappedSection();
    loadAdvancedStats();
    initPeriodSelectors();
    pollNowPlaying();

  } catch (err) {
    const msg = err.message.toLowerCase().includes('user not found') || err.message.includes('Invalid API')
      ? 'Utilisateur introuvable ou clé API invalide.'
      : `Erreur : ${err.message}`;
    showSetupError(msg);
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-chart-bar"></i> Lancer l\'analyse';
  }
}

// Restauration automatique depuis localStorage
window.addEventListener('DOMContentLoaded', () => {
  const u = localStorage.getItem('ls_username');
  const k = localStorage.getItem('ls_apikey');
  if (u) document.getElementById('input-username').value = u;
  if (k) document.getElementById('input-apikey').value   = k;

  const theme = localStorage.getItem('ls_theme') || 'dark';
  document.documentElement.dataset.theme = theme;
});

/* ============================================================
   NAVIGATION
   ============================================================ */
function nav(section) {
  document.querySelectorAll('.nav-lnk').forEach(el =>
    el.classList.toggle('active', el.dataset.s === section)
  );
  document.querySelectorAll('.app-sec').forEach(el => el.classList.remove('active'));
  document.getElementById('s-' + section)?.classList.add('active');

  const titles = {
    dashboard:     'Dashboard',
    'top-artists': 'Top Artistes',
    'top-albums':  'Top Albums',
    'top-tracks':  'Top Titres',
    charts:        'Graphiques',
    wrapped:       'Wrapped',
    advanced:      'Stats Avancées',
  };
  document.getElementById('hd-title').textContent = titles[section] || section;

  if (window.innerWidth <= 1024) closeSb();
}

function openSb()  { document.getElementById('sidebar').classList.add('open'); document.getElementById('sidebar-ov').classList.add('open'); document.body.style.overflow = 'hidden'; }
function closeSb() { document.getElementById('sidebar').classList.remove('open'); document.getElementById('sidebar-ov').classList.remove('open'); document.body.style.overflow = ''; }

/* ============================================================
   THÈME
   ============================================================ */
function setTheme(theme) {
  APP.currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  localStorage.setItem('ls_theme', theme);
  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === theme));
  updateAllChartThemes();
}

function applyTheme(theme) {
  APP.currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  document.querySelectorAll('.th-btn').forEach(b => b.classList.toggle('active', b.dataset.t === theme));
}

function toggleApiKey() {
  const inp = document.getElementById('input-apikey');
  const ico = document.getElementById('eye-icon');
  inp.type = inp.type === 'password' ? 'text' : 'password';
  ico.className = inp.type === 'password' ? 'fas fa-eye' : 'fas fa-eye-slash';
}

/* ============================================================
   PROFIL
   ============================================================ */
function setupProfileUI() {
  const u = APP.userInfo;
  if (!u) return;

  document.getElementById('sb-name').textContent  = u.name || APP.username;
  document.getElementById('sb-plays').textContent = formatNum(u.playcount) + ' scrobbles';
  if (u.country) document.getElementById('sb-country').textContent = u.country;

  const imgUrl = u.image?.find(i => i.size === 'medium')?.['#text'] || '';
  const sbAv   = document.getElementById('sb-av');
  const letter = (u.name || '?')[0].toUpperCase();

  if (imgUrl && !isDefaultImg(imgUrl)) {
    sbAv.innerHTML = `<img src="${imgUrl}" alt="Avatar"
      onerror="this.outerHTML='<div style=\\'width:100%;height:100%;background:${nameToGradient(u.name)};display:flex;align-items:center;justify-content:center;font-weight:700;color:white\\'>${letter}</div>'">`
  } else {
    sbAv.innerHTML = `<div style="width:100%;height:100%;background:${nameToGradient(u.name)};display:flex;align-items:center;justify-content:center;font-weight:700;color:white;font-size:1.1rem">${letter}</div>`;
  }

  document.getElementById('hd-mini-user').textContent = '@' + (u.name || APP.username);
}

/* ── Now Playing polling ── */
let _npTimer = null;
async function pollNowPlaying() {
  clearTimeout(_npTimer);
  try {
    const data = await API._fetch('user.getRecentTracks', { limit: 1, extended: 1 });
    const tracks = data.recenttracks?.track;
    if (!tracks) return;
    const last = Array.isArray(tracks) ? tracks[0] : tracks;

    const wrap = document.getElementById('now-playing-wrap');
    const bar  = document.getElementById('now-playing-bar');

    if (last['@attr']?.nowplaying) {
      document.getElementById('np-track').textContent  = last.name || '—';
      document.getElementById('np-artist').textContent = last.artist?.name || last.artist?.['#text'] || '—';

      const artEl = document.getElementById('np-art');
      const img   = last.image?.find(i => i.size === 'medium')?.['#text'];
      artEl.innerHTML = img && !isDefaultImg(img)
        ? `<img src="${img}" alt="" style="width:100%;height:100%;object-fit:cover">`
        : '';

      wrap.classList.remove('hidden');
      _npTimer = setTimeout(pollNowPlaying, 30000);
    } else {
      wrap.classList.add('hidden');
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
  } catch { /* non bloquant */ }

  let lastScrobble = '—';
  try {
    const recent = await API.call('user.getRecentTracks', { limit: 1 });
    const tracks  = recent.recenttracks?.track;
    if (tracks) {
      const last = Array.isArray(tracks) ? tracks[0] : tracks;
      if (!last['@attr']?.nowplaying) {
        lastScrobble = timeAgo(parseInt(last.date?.uts || 0));
      } else {
        lastScrobble = '🎵 En ce moment';
      }
    }
  } catch { /* non bloquant */ }

  const cards = [
    { icon: '🎵', value: totalPlay, label: 'Total scrobbles', sub: `~${avgPerDay} / jour en moyenne`, color: '#6366f1' },
    { icon: '🎤', value: uniqueArtists, label: 'Artistes écoutés', sub: 'depuis le début', color: '#8b5cf6', noAnim: true },
    { icon: '💿', value: uniqueAlbums, label: 'Albums explorés', sub: 'depuis le début', color: '#a855f7', noAnim: true },
    { icon: '🎼', value: uniqueTracks, label: 'Titres différents', sub: 'depuis le début', color: '#ec4899', noAnim: true },
    { icon: '📅', value: formatDate(regTs), label: 'Membre depuis', sub: `${formatNum(daysSince)} jours d'activité`, color: '#f97316', noAnim: true },
    { icon: '⏱️', value: lastScrobble, label: 'Dernier scrobble', sub: u.url ? `last.fm/user/${u.name}` : '', color: '#22c55e', noAnim: true },
  ];

  document.getElementById('stat-grid').innerHTML = cards.map((c, i) => `
    <div class="stat-card" style="--card-accent:${c.color};animation-delay:${i * 0.05}s">
      <div class="stat-card-icon">${c.icon}</div>
      <div class="stat-card-value" id="sv-${i}" style="color:${c.color}">${c.noAnim ? c.value : '0'}</div>
      <div class="stat-card-label">${c.label}</div>
      <div class="stat-card-sub">${c.sub}</div>
    </div>`).join('');

  // Animation du compteur sur le total scrobbles
  const scrobbleEl = document.getElementById('sv-0');
  if (scrobbleEl) animateValue(scrobbleEl, 0, totalPlay, 1000);

  loadDashMonthlyChart(currentYear);
  loadDashArtistsChart();
}

async function loadDashMonthlyChart(year) {
  document.getElementById('dash-yr').textContent = year;
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
      labels: MONTHS_SHORT,
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
        tooltip: {
          ...baseChartOpts().plugins.tooltip,
          callbacks: { label: ctx => ` ${formatNum(ctx.raw)} scrobbles` },
        },
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
          legend: {
            display: true, position: 'right',
            labels: { color: c.text, font: { size: 11 }, boxWidth: 12, padding: 8 },
          },
          tooltip: { callbacks: { label: ctx => ` ${ctx.label}: ${formatNum(ctx.raw)}` } },
        },
        cutout: '62%',
        animation: { duration: 700 },
      },
    });
  } catch (e) { console.warn('dash-artists chart:', e); }
}

/* ============================================================
   TOP ARTISTES
   ============================================================ */
async function loadTopArtists(period) {
  const grid = document.getElementById('artists-grid');
  grid.innerHTML = skeletonMusicCards(12);
  try {
    const data    = await API.call('user.getTopArtists', { period, limit: TOP_LIMIT });
    const artists = (data.topartists?.artist || []).slice(0, DISPLAY_LIMIT);
    APP.topArtistsData = data.topartists?.artist || [];

    grid.innerHTML = artists.map((a, i) => {
      const imgUrl = a.image?.find(img => img.size === 'extralarge')?.['#text'] || '';
      const hasImg = !isDefaultImg(imgUrl);
      const letter = (a.name || '?')[0].toUpperCase();
      const bg     = nameToGradient(a.name);
      return `
        <div class="music-card" style="animation-delay:${i * 0.04}s" onclick="window.open('${a.url}','_blank')">
          <div class="music-card-img" style="height:160px">
            ${hasImg ? `<img src="${imgUrl}" alt="${escHtml(a.name)}" loading="lazy"
                         onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
            <div class="spotify-cover" style="background:${bg};display:${hasImg ? 'none' : 'flex'}">
              <span class="sc-letter">${letter}</span>
              <span class="sc-name">${escHtml(a.name)}</span>
            </div>
            <div class="music-card-rank">${i + 1}</div>
          </div>
          <div class="music-card-body">
            <div class="music-card-name" title="${escHtml(a.name)}">${escHtml(a.name)}</div>
            <div class="music-card-plays">${formatNum(a.playcount)} écoutes</div>
          </div>
        </div>`;
    }).join('');
  } catch (e) {
    grid.innerHTML = errMsg(e);
  }
}

/* ============================================================
   TOP ALBUMS
   ============================================================ */
async function loadTopAlbums(period) {
  const grid = document.getElementById('albums-grid');
  grid.innerHTML = skeletonMusicCards(12);
  try {
    const data   = await API.call('user.getTopAlbums', { period, limit: TOP_LIMIT });
    const albums = (data.topalbums?.album || []).slice(0, DISPLAY_LIMIT);
    APP.topAlbumsData = data.topalbums?.album || [];

    grid.innerHTML = albums.map((a, i) => {
      const imgUrl = a.image?.find(img => img.size === 'extralarge')?.['#text'] || '';
      const hasImg = !isDefaultImg(imgUrl);
      const letter = (a.name || '?')[0].toUpperCase();
      const bg     = nameToGradient((a.name || '') + (a.artist?.name || ''));
      return `
        <div class="music-card" style="animation-delay:${i * 0.04}s" onclick="window.open('${a.url}','_blank')">
          <div class="music-card-img" style="height:160px">
            ${hasImg ? `<img src="${imgUrl}" alt="${escHtml(a.name)}" loading="lazy"
                         onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
            <div class="spotify-cover" style="background:${bg};display:${hasImg ? 'none' : 'flex'}">
              <span class="sc-letter">${letter}</span>
              <span class="sc-name">${escHtml(a.name)}</span>
            </div>
            <div class="music-card-rank">${i + 1}</div>
          </div>
          <div class="music-card-body">
            <div class="music-card-name" title="${escHtml(a.name)}">${escHtml(a.name)}</div>
            <div class="music-card-artist">${escHtml(a.artist?.name || '')}</div>
            <div class="music-card-plays">${formatNum(a.playcount)} écoutes</div>
          </div>
        </div>`;
    }).join('');
  } catch (e) {
    grid.innerHTML = errMsg(e);
  }
}

/* ============================================================
   TOP TITRES
   ============================================================ */
async function loadTopTracks(period) {
  const list = document.getElementById('tracks-list');
  list.innerHTML = skeletonTrackItems(12);
  try {
    const data   = await API.call('user.getTopTracks', { period, limit: TOP_LIMIT });
    const tracks = (data.toptracks?.track || []).slice(0, DISPLAY_LIMIT);
    APP.topTracksData = data.toptracks?.track || [];
    const maxPlay = tracks.length > 0 ? parseInt(tracks[0].playcount) : 1;

    list.innerHTML = tracks.map((t, i) => {
      const pct = ((parseInt(t.playcount) / maxPlay) * 100).toFixed(1);
      const medal = i < 3 ? ['🥇','🥈','🥉'][i] : i + 1;
      return `
        <div class="track-item" style="animation-delay:${i * 0.025}s" onclick="window.open('${t.url}','_blank')">
          <div class="track-rank">${medal}</div>
          <div class="track-info">
            <div class="track-name" title="${escHtml(t.name)}">${escHtml(t.name)}</div>
            <div class="track-artist">${escHtml(t.artist?.name || '')}</div>
          </div>
          <div class="track-bar-wrap">
            <div class="track-bar" style="width:${pct}%"></div>
          </div>
          <div class="track-plays">${formatNum(t.playcount)}</div>
        </div>`;
    }).join('');
  } catch (e) {
    list.innerHTML = `<p style="color:var(--text-muted);padding:20px">${e.message}</p>`;
  }
}

/* ── Sélecteurs de période ── */
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
   SECTION GRAPHIQUES
   ============================================================ */
function setupChartsSection() {
  const currentYear = new Date().getFullYear();
  const sel = document.getElementById('yr-sel');
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

  prog.classList.remove('hidden');
  fill.style.width = '0%';

  const counts = [];
  for (let m = 0; m < 12; m++) {
    const n = await API.getMonthScrobbles(year, m);
    counts.push(n);
    fill.style.width = `${Math.round((m + 1) / 12 * 100)}%`;
    txt.textContent  = `${MONTHS_SHORT[m]} ${year} — ${formatNum(n)} scrobbles`;
  }
  prog.classList.add('hidden');

  destroyChart('chart-monthly');
  const c = getThemeColors();
  APP.charts['chart-monthly'] = new Chart(document.getElementById('chart-monthly'), {
    type: 'bar',
    data: {
      labels: MONTHS_FR,
      datasets: [{
        label: `Scrobbles ${year}`,
        data: counts,
        backgroundColor: CHART_PALETTE.map(p => p + 'bb'),
        borderColor:     CHART_PALETTE,
        borderWidth: 1, borderRadius: 7,
      }],
    },
    options: {
      ...baseChartOpts(),
      plugins: {
        ...baseChartOpts().plugins,
        tooltip: {
          ...baseChartOpts().plugins.tooltip,
          callbacks: { label: ctx => ` ${formatNum(ctx.raw)} scrobbles` },
        },
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
    const mCounts = await Promise.all(
      Array(12).fill(0).map((_, m) => API.getMonthScrobbles(y, m))
    );
    mCounts.forEach((n, m) => {
      if (y < currentYear || m <= new Date().getMonth()) {
        total += n;
        labels.push(`${MONTHS_SHORT[m]} ${y}`);
        cumulative.push(total);
      }
    });
  }

  destroyChart('chart-cumul');
  const c = getThemeColors();
  // Désactiver les animations sur les gros volumes (anti-lag CPU)
  const animDuration = cumulative.length > 80 ? 0 : 600;
  APP.charts['chart-cumul'] = new Chart(document.getElementById('chart-cumul'), {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: 'Scrobbles cumulés',
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
      animation: { duration: animDuration, easing: 'easeOutQuart' },
      plugins: {
        ...baseChartOpts().plugins,
        tooltip: {
          ...baseChartOpts().plugins.tooltip,
          callbacks: { label: ctx => ` ${formatNum(ctx.raw)} scrobbles au total` },
        },
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
  sel.innerHTML = '';
  for (let y = currentYear; y >= APP.regYear; y--) {
    sel.innerHTML += `<option value="${y}"${y === currentYear - 1 ? ' selected' : ''}>${y}</option>`;
  }
  loadWrapped(currentYear - 1);
}

async function loadWrapped(year) {
  year = parseInt(year);
  document.getElementById('w-loader').classList.remove('hidden');
  document.getElementById('wrapped-card').style.opacity = '.4';
  document.getElementById('w-yr-badge').textContent = year;
  document.getElementById('w-uname').textContent    = '@' + (APP.userInfo?.name || APP.username);

  const progFill = document.getElementById('w-prog-fill');
  const progN    = document.getElementById('w-prog-n');
  const monthCounts = [];

  for (let m = 0; m < 12; m++) {
    const n = await API.getMonthScrobbles(year, m);
    monthCounts.push(n);
    progFill.style.width = Math.round((m + 1) / 12 * 100) + '%';
    progN.textContent    = m + 1;
  }

  const totalYear = monthCounts.reduce((a, b) => a + b, 0);
  const maxMonth  = monthCounts.indexOf(Math.max(...monthCounts));

  document.getElementById('w-scrobbles').textContent = formatNum(totalYear);
  document.getElementById('w-top-m').textContent     = MONTHS_FR[maxMonth];

  // Tops artistes/tracks/albums (12month comme proxy)
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
      arts[0].image?.find(i => i.size === 'extralarge')?.['#text'] ||
      arts[0].image?.find(i => i.size === 'large')?.['#text']);
    if (trks[0]) _fillWrappedPod('trk', trks[0].name, trks[0].playcount, null, trks[0].name + (trks[0].artist?.name || ''));
    if (albs[0]) _fillWrappedPod('alb', albs[0].name, albs[0].playcount,
      albs[0].image?.find(i => i.size === 'extralarge')?.['#text'] ||
      albs[0].image?.find(i => i.size === 'large')?.['#text']);

  } catch (e) { console.warn('wrapped tops:', e); }

  // Mini chart
  destroyChart('w-mini');
  APP.charts['w-mini'] = new Chart(document.getElementById('w-mini'), {
    type: 'bar',
    data: {
      labels: MONTHS_SHORT,
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

  document.getElementById('w-loader').classList.add('hidden');
  document.getElementById('wrapped-card').style.opacity = '1';
}

function _fillWrappedPod(prefix, name, playcount, imgUrl, fallbackSeed) {
  const letter = (name || '?')[0].toUpperCase();
  const seed   = fallbackSeed || name;

  document.getElementById(`w-${prefix}-name`).textContent  = name;
  document.getElementById(`w-${prefix}-plays`).textContent = formatNum(playcount) + ' écoutes';
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
    showToast('Génération de l\'image…');
    document.body.classList.add('export-mode');
    const canvas = await html2canvas(card, { scale: 2, useCORS: true, allowTaint: true, backgroundColor: null });
    document.body.classList.remove('export-mode');
    const link = document.createElement('a');
    link.download = `laststats-wrapped-${document.getElementById('w-yr-sel').value}.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
    showToast('Image téléchargée !');
  } catch (e) {
    document.body.classList.remove('export-mode');
    showToast('Erreur export : ' + e.message, 'error');
  }
}

function copyLink() {
  const url = APP.userInfo?.url || `https://www.last.fm/user/${APP.username}`;
  navigator.clipboard.writeText(url)
    .then(() => showToast('Lien copié dans le presse-papiers !'))
    .catch(() => prompt('Copiez ce lien :', url));
}

/* ============================================================
   STATS AVANCÉES (basiques — sans historique complet)
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
    const topPct     = total > 0 && maxArtist
      ? ((parseInt(maxArtist.playcount) / total) * 100).toFixed(1) : 0;

    const cards = [
      { icon: '⚡', value: avgDay, label: 'Scrobbles / jour', sub: `~${avgWeek} par semaine`, color: '#6366f1' },
      { icon: '🔢', value: eddington, label: 'Nombre d\'Eddington', sub: `${eddington} artistes écoutés ≥ ${eddington}×`, color: '#8b5cf6' },
      { icon: '🌟', value: APP.topArtistsData.length > 0 ? APP.topArtistsData[0].name : '—', label: 'Artiste n°1 (all time)', sub: `${topPct}% de vos écoutes`, color: '#a855f7', noAnim: true },
      { icon: '💀', value: oneHits, label: 'One-Hit Wonders visibles', sub: 'Artistes écoutés 1 seule fois (top 50)', color: '#ec4899' },
      { icon: '📆', value: formatNum(daysSince), label: 'Jours d\'activité', sub: `Inscrit le ${formatDate(regTs)}`, color: '#f97316', noAnim: true },
      { icon: '🎯', value: formatNum(total), label: 'Scrobbles total', sub: 'Historique complet', color: '#22c55e', noAnim: true },
    ];

    document.getElementById('adv-grid').innerHTML = cards.map((c, i) => `
      <div class="adv-card" style="animation-delay:${i * 0.05}s">
        <div class="adv-card-icon">${c.icon}</div>
        <div class="adv-card-value" style="color:${c.color}">${c.noAnim ? c.value : c.value}</div>
        <div class="adv-card-label">${c.label}</div>
        <div class="adv-card-sub">${c.sub}</div>
      </div>`).join('');

  } catch (e) {
    document.getElementById('adv-grid').innerHTML =
      `<p style="color:var(--text-muted);grid-column:1/-1">${e.message}</p>`;
  }
}

/* ── Nombre d'Eddington ── */
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
   CHARGEMENT HISTORIQUE COMPLET (pagination user.getRecentTracks)
   ============================================================ */
async function fetchFullHistory() {
  const btn = document.getElementById('fetch-history-btn');
  if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Chargement…'; }

  // Overlay de progression
  const overlay  = document.getElementById('fetch-overlay');
  const fillEl   = document.getElementById('fetch-fill');
  const pctEl    = document.getElementById('fetch-pct');
  const tracksEl = document.getElementById('fetch-tracks');
  const subEl    = document.getElementById('fetch-sub');
  const msgEl    = document.getElementById('fetch-msg');

  overlay.classList.remove('hidden');
  fillEl.style.width = '0%';
  pctEl.textContent  = '0%';
  tracksEl.textContent = '0 scrobbles';
  msgEl.textContent  = 'Connexion à l\'API…';

  try {
    const tracks = await API.fetchAllPages((page, totalPages, loaded) => {
      const pct = Math.round(page / totalPages * 100);
      fillEl.style.width    = pct + '%';
      pctEl.textContent     = pct + '%';
      tracksEl.textContent  = formatNum(loaded) + ' scrobbles chargés';
      subEl.textContent     = `Page ${page} / ${totalPages}`;
      msgEl.textContent     = 'Récupération des données…';
    });

    APP.fullHistory = tracks;
    overlay.classList.add('hidden');

    // Traitement
    processFullHistory(tracks);
    showToast(`${formatNum(tracks.length)} scrobbles chargés avec succès !`);

  } catch (e) {
    overlay.classList.add('hidden');
    showToast('Erreur lors du chargement : ' + e.message, 'error');
  } finally {
    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-check"></i> Historique chargé'; }
  }
}

function processFullHistory(tracks) {
  if (!tracks || !tracks.length) return;

  // ── Compte par heure ──
  const hourCounts = Array(24).fill(0);
  // ── Compte par jour de semaine (0=Lun … 6=Dim) ──
  const dayCounts  = Array(7).fill(0);
  // ── Artistes uniques ──
  const artistMap  = new Map();

  for (const t of tracks) {
    const ts = parseInt(t.date?.uts || 0);
    if (ts) {
      const d  = new Date(ts * 1000);
      hourCounts[d.getHours()]++;
      // JS getDay() : 0=Dim, 1=Lun…
      const dow = (d.getDay() + 6) % 7; // recaler sur Lun=0
      dayCounts[dow]++;
    }
    const artist = t.artist?.['#text'] || t.artist?.name || '';
    if (artist) artistMap.set(artist, (artistMap.get(artist) || 0) + 1);
  }

  // One-hit wonders (artistes avec exactement 1 écoute)
  const oneHitWonders = [...artistMap.entries()]
    .filter(([, n]) => n === 1)
    .map(([name]) => name)
    .slice(0, 20);

  // Eddington depuis les données réelles
  const allPlays    = [...artistMap.values()];
  const eddington   = calcEddington(allPlays);
  const uniqueCount = artistMap.size;

  // Mise à jour de la grille adv-stats
  const u         = APP.userInfo;
  const regTs     = parseInt(u?.registered?.unixtime || 0);
  const daysSince = regTs ? Math.floor((Date.now() - regTs * 1000) / 86400000) : 1;
  const avgDay    = (tracks.length / daysSince).toFixed(1);

  const sortedArtists = [...artistMap.entries()].sort((a, b) => b[1] - a[1]);
  const top1 = sortedArtists[0];
  const topPct = top1 ? ((top1[1] / tracks.length) * 100).toFixed(1) : 0;

  document.getElementById('adv-grid').innerHTML = [
    { icon: '⚡', value: avgDay,    label: 'Scrobbles / jour', sub: `Calculé sur ${formatNum(tracks.length)} scrobbles réels`, color: '#6366f1' },
    { icon: '🔢', value: eddington, label: 'Nombre d\'Eddington', sub: `${eddington} artistes écoutés ≥ ${eddington}×`, color: '#8b5cf6' },
    { icon: '🌟', value: top1?.[0] || '—', label: 'Artiste n°1 (all time)', sub: `${formatNum(top1?.[1] || 0)} écoutes · ${topPct}% du total`, color: '#a855f7', noAnim: true },
    { icon: '💀', value: oneHitWonders.length, label: 'One-Hit Wonders', sub: `${formatNum(oneHitWonders.length)} artistes écoutés 1 seule fois`, color: '#ec4899' },
    { icon: '🎤', value: formatNum(uniqueCount), label: 'Artistes uniques', sub: 'Sur l\'historique complet', color: '#f97316', noAnim: true },
    { icon: '🎵', value: formatNum(tracks.length), label: 'Scrobbles analysés', sub: `Chargés depuis l'API`, color: '#22c55e', noAnim: true },
  ].map((c, i) => `
    <div class="adv-card" style="animation-delay:${i * 0.05}s">
      <div class="adv-card-icon">${c.icon}</div>
      <div class="adv-card-value" style="color:${c.color}">${c.value}</div>
      <div class="adv-card-label">${c.label}</div>
      <div class="adv-card-sub">${c.sub}</div>
    </div>`).join('');

  // Afficher les graphiques avancés
  document.getElementById('adv-charts').classList.remove('hidden');
  renderHourlyChart(hourCounts);
  renderWeekdayChart(dayCounts);
  renderOneHitWonders(oneHitWonders, artistMap);
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
        backgroundColor: hourCounts.map((_, i) => `${CHART_PALETTE[Math.floor(i / 4) % CHART_PALETTE.length]}bb`),
        borderColor:     hourCounts.map((_, i) => CHART_PALETTE[Math.floor(i / 4) % CHART_PALETTE.length]),
        borderWidth: 1, borderRadius: 4,
      }],
    },
    options: {
      ...baseChartOpts(),
      animation: { duration: 0 },  // Désactivé : données volumineuses de l'historique complet
      plugins: {
        ...baseChartOpts().plugins,
        tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} scrobbles` } },
      },
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
      labels: DAYS_FR,
      datasets: [{
        data: dayCounts,
        backgroundColor: CHART_PALETTE.slice(0, 7).map(p => p + 'cc'),
        borderColor:     CHART_PALETTE.slice(0, 7),
        borderWidth: 1, borderRadius: 5,
      }],
    },
    options: {
      ...baseChartOpts(),
      animation: { duration: 0 },  // Désactivé : données volumineuses de l'historique complet
      plugins: {
        ...baseChartOpts().plugins,
        tooltip: { ...baseChartOpts().plugins.tooltip, callbacks: { label: ctx => ` ${formatNum(ctx.raw)} scrobbles` } },
      },
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

  if (!names.length) {
    el.innerHTML = '<p style="color:var(--text-muted);padding:12px">Aucun one-hit wonder trouvé dans votre historique.</p>';
    return;
  }

  // Afficher aussi les artistes avec très peu d'écoutes (1-3)
  const raresAll = [...artistMap.entries()]
    .filter(([, n]) => n <= 3)
    .sort((a, b) => a[1] - b[1])
    .slice(0, 20);

  el.innerHTML = raresAll.map(([name, plays], i) => `
    <div class="ohw-item">
      <span class="ohw-num">${i + 1}</span>
      <span class="ohw-name" title="${escHtml(name)}">${escHtml(name)}</span>
      <span class="ohw-plays">${plays} écoute${plays > 1 ? 's' : ''}</span>
    </div>`).join('');
}

/* ============================================================
   REFRESH & LOGOUT
   ============================================================ */
async function refreshData() {
  const icon = document.getElementById('refresh-icon');
  icon.classList.add('fa-spin');
  Cache.clear();
  APP.fullHistory = null;

  try {
    await loadDashboard();
    const activeSection = document.querySelector('.app-sec.active')?.id?.replace('s-', '');
    if (activeSection === 'top-artists') await loadTopArtists('overall');
    if (activeSection === 'top-albums')  await loadTopAlbums('overall');
    if (activeSection === 'top-tracks')  await loadTopTracks('overall');
    showToast('Données actualisées !');
  } finally {
    icon.classList.remove('fa-spin');
  }
}

function logout() {
  Cache.clear();
  localStorage.removeItem('ls_username');
  localStorage.removeItem('ls_apikey');
  APP.username  = '';
  APP.apiKey    = '';
  APP.userInfo  = null;
  APP.fullHistory = null;
  Object.values(APP.charts).forEach(c => c?.destroy());
  APP.charts = {};

  clearTimeout(_npTimer);
  document.getElementById('app').classList.add('hidden');
  document.getElementById('setup-screen').classList.remove('hidden');
  document.getElementById('input-username').value = '';
  document.getElementById('input-apikey').value   = '';
}

/* ============================================================
   HELPERS
   ============================================================ */
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
