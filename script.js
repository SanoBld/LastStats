'use strict';

/* ============================================================
   LASTSTATS — SCRIPT v3
   Modules : Cache · API · UI · Charts · Streak · Versus ·
             Mood Tags · Heatmap · Story · Stats avancées · PWA
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
  fullHistory:   null,
  streakData:    null,   // { best, current }
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
    let page = 1;
    let totalPages = 1;

    const baseParams = { limit: 200, extended: 0 };
    if (yearFrom) baseParams.from = yearFrom;
    if (yearTo)   baseParams.to   = yearTo;

    do {
      const params = { ...baseParams, page };
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

      for (const t of tracks) {
        if (!t['@attr']?.nowplaying) allTracks.push(t);
      }

      if (onProgress) onProgress(page, totalPages, allTracks.length);
      page++;
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

    // ── PWA : Restaurer la dernière section visitée ──
    const savedSection = localStorage.getItem('ls_section');
    if (savedSection && document.getElementById('s-' + savedSection)) {
      nav(savedSection);
    }

    // Chargement parallèle (non bloquant)
    Promise.all([
      loadTopArtists('overall'),
      loadTopAlbums('overall'),
      loadTopTracks('overall'),
    ]).then(() => {
      // Mood tags dès que topArtistsData est prêt
      loadMoodTags();
    });

    setupChartsSection();
    setupWrappedSection();
    loadAdvancedStats();
    initPeriodSelectors();
    pollNowPlaying();

    // Versus chargé en parallèle (non bloquant)
    loadVersus();

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
   NAVIGATION  +  PWA section save
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
    vizplus:       'Visualisations Avancées',
    badges:        'Succès',
    obscurity:     'Mainstream vs Obscur',
    wrapped:       'Wrapped',
    advanced:      'Stats Avancées',
  };
  document.getElementById('hd-title').textContent = titles[section] || section;

  // ── PWA : Sauvegarder la section courante ──
  localStorage.setItem('ls_section', section);

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

    if (last['@attr']?.nowplaying) {
      const trackName  = last.name || '—';
      const artistName = last.artist?.name || last.artist?.['#text'] || '—';
      document.getElementById('np-track').textContent  = trackName;
      document.getElementById('np-artist').textContent = artistName;

      const artEl  = document.getElementById('np-art');
      const artImg = document.getElementById('np-art-img');
      const img    = last.image?.find(i => i.size === 'medium')?.['#text'];

      if (img && !isDefaultImg(img)) {
        artEl.innerHTML = `<img src="${img}" alt="" style="width:100%;height:100%;object-fit:cover">`;
        // ColorThief dynamic accent
        if (APP.currentAccent === 'dynamic') {
          _applyColorThiefFromUrl(img);
        }
      } else {
        artEl.innerHTML = '';
      }

      // Boutons lecture
      const q = encodeURIComponent(`${trackName} ${artistName}`);
      const spBtn = document.getElementById('np-spotify-btn');
      const ytBtn = document.getElementById('np-youtube-btn');
      if (spBtn) spBtn.href = `spotify:search:${encodeURIComponent(trackName + ' ' + artistName)}`;
      if (ytBtn) ytBtn.href = `https://www.youtube.com/results?search_query=${q}`;

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
   ██  VERSUS — Comparaison de périodes  ██
   Compare mois actuel vs mois précédent (Scrobbles)
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
    const scrobblePct  = prevScrobbles > 0
      ? ((scrobbleDiff / prevScrobbles) * 100).toFixed(1)
      : null;

    // Artistes uniques ce mois (via top artists 1month)
    let currArtists = null, prevArtists = null;
    try {
      const [ca, pa] = await Promise.all([
        API.call('user.getTopArtists', { period: '1month', limit: 1 }),
        API.call('user.getTopArtists', { period: '3month', limit: 1 }), // proxy pour "mois passé"
      ]);
      currArtists = parseInt(ca.topartists?.['@attr']?.total || 0);
      prevArtists = parseInt(pa.topartists?.['@attr']?.total || 0);
    } catch { /* optionnel */ }

    function arrowBadge(diff, pct) {
      if (pct === null || diff === 0) return `<span class="vs-arrow flat">→ stable</span>`;
      const cls  = diff > 0 ? 'up' : 'down';
      const icon = diff > 0 ? '▲' : '▼';
      const sign = diff > 0 ? '+' : '';
      return `<span class="vs-arrow ${cls}">${icon} ${sign}${pct}%</span>`;
    }

    let html = `
      <div class="vs-metric">
        <span class="vs-label">🎵 Scrobbles</span>
        <div class="vs-values">
          <span class="vs-curr">${formatNum(currScrobbles)}</span>
          ${arrowBadge(scrobbleDiff, scrobblePct)}
        </div>
      </div>
      <div class="vs-prev-row">
        <span class="vs-prev-txt">${formatNum(prevScrobbles)} en ${MONTHS_FR[prevMonth]}</span>
      </div>`;

    if (currArtists !== null) {
      const artDiff = currArtists - prevArtists;
      const artPct  = prevArtists > 0 ? ((artDiff / prevArtists) * 100).toFixed(1) : null;
      html += `
        <div class="vs-metric" style="margin-top:10px">
          <span class="vs-label">🎤 Artistes</span>
          <div class="vs-values">
            <span class="vs-curr">${formatNum(currArtists)}</span>
            ${arrowBadge(artDiff, artPct)}
          </div>
        </div>`;
    }

    html += `<div class="vs-months">${MONTHS_FR[currMonth]} <span>vs</span> ${MONTHS_FR[prevMonth]}</div>`;
    vsBody.innerHTML = html;

  } catch (e) {
    if (vsBody) vsBody.innerHTML = `<p class="vs-na">Données indisponibles</p>`;
  }
}

/* ============================================================
   ██  MOOD — Nuage de Tags musicaux  ██
   Récupère les tags des 10 meilleurs artistes via artist.getTopTags
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

    // Fetch tags pour chaque artiste (en parallèle)
    const tagResults = await Promise.allSettled(
      top10.map(a => API.call('artist.getTopTags', { artist: a.name }))
    );

    // Mots à ignorer (non-genres)
    const IGNORED = new Set([
      'seen live','favorites','favourite','love','awesome','beautiful','epic',
      'amazing','classic','favourite music','my favourite','under 2000 listeners',
      'all','featured','good','new','old','best','cool','hot','great','perfect',
    ]);

    tagResults.forEach((result, i) => {
      if (result.status !== 'fulfilled') return;
      const tags = result.value.toptags?.tag || [];
      const artistWeight = 10 - i; // Plus de poids aux artistes en tête
      tags.slice(0, 8).forEach((tag, j) => {
        const name = tag.name?.toLowerCase().trim();
        if (!name || name.length < 2 || IGNORED.has(name)) return;
        // Score = count API × poids artiste × (moins de poids pour tags loin dans la liste)
        const score = (parseInt(tag.count) || 50) * artistWeight * (8 - j);
        tagScores.set(name, (tagScores.get(name) || 0) + score);
      });
    });

    const top5 = [...tagScores.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5);

    if (!top5.length) {
      tagsEl.innerHTML = '<p class="mood-na">Aucun genre trouvé</p>';
      return;
    }

    tagsEl.innerHTML = top5.map(([tag], i) => {
      const label = tag.charAt(0).toUpperCase() + tag.slice(1);
      return `<span class="mood-tag rank-${i + 1}">#${escHtml(label)}</span>`;
    }).join('');

  } catch (e) {
    console.warn('loadMoodTags:', e);
    if (tagsEl) tagsEl.innerHTML = '<p class="mood-na">Genres indisponibles</p>';
  }
}

/* ============================================================
   ██  LISTENING STREAK  ██
   Calcule le record ET la streak actuelle depuis l'historique
   ============================================================ */
function calcStreak(tracks) {
  // Collecte les jours uniques (YYYY-MM-DD) triés
  const daySet = new Set();
  for (const t of tracks) {
    const ts = parseInt(t.date?.uts || 0);
    if (!ts) continue;
    const d = new Date(ts * 1000);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    daySet.add(key);
  }

  const sorted = [...daySet].sort(); // chronologique
  if (!sorted.length) return { best: 0, current: 0 };

  // Calcul du record (parcours séquentiel)
  let best = 1, streak = 1;
  for (let i = 1; i < sorted.length; i++) {
    const prev = new Date(sorted[i - 1]);
    const curr = new Date(sorted[i]);
    const diffDays = Math.round((curr - prev) / 86400000);
    if (diffDays === 1) {
      streak++;
      if (streak > best) best = streak;
    } else {
      streak = 1;
    }
  }

  // Calcul de la streak actuelle (depuis aujourd'hui ou hier en remontant)
  const todayMs  = new Date();
  todayMs.setHours(0, 0, 0, 0);
  const todayStr = `${todayMs.getFullYear()}-${String(todayMs.getMonth() + 1).padStart(2, '0')}-${String(todayMs.getDate()).padStart(2, '0')}`;
  const yestMs   = new Date(todayMs - 86400000);
  const yestStr  = `${yestMs.getFullYear()}-${String(yestMs.getMonth() + 1).padStart(2, '0')}-${String(yestMs.getDate()).padStart(2, '0')}`;

  // Parcours à rebours depuis le jour le plus récent
  const rev = [...sorted].reverse();
  let current = 0;
  if (rev[0] === todayStr || rev[0] === yestStr) {
    current = 1;
    for (let i = 1; i < rev.length; i++) {
      const a = new Date(rev[i - 1]);
      const b = new Date(rev[i]);
      const diff = Math.round((a - b) / 86400000);
      if (diff === 1) {
        current++;
      } else {
        break;
      }
    }
  }

  return { best, current };
}

function updateStreakUI(streakData) {
  const bestEl  = document.getElementById('streak-best');
  const currEl  = document.getElementById('streak-curr');
  const hintEl  = document.getElementById('streak-hint');

  if (bestEl) bestEl.textContent = streakData.best;
  if (currEl) currEl.textContent = streakData.current;
  if (hintEl) {
    if (streakData.current > 0) {
      hintEl.textContent = streakData.current === streakData.best
        ? '🔥 Vous êtes sur votre record !'
        : `🔥 Streak en cours — record : ${streakData.best} jours`;
    } else {
      hintEl.textContent = `Record calculé sur ${formatNum(APP.fullHistory?.length || 0)} scrobbles`;
    }
  }
}

/* ============================================================
   ██  HEATMAP HORAIRE (CSS Grid — anti-lag)  ██
   Grille 24 cellules, intensité par couleur indigo
   ============================================================ */
function renderHeatmap(hourCounts) {
  const el = document.getElementById('heatmap-grid');
  if (!el) return;

  // Vider l'état "vide"
  const emptyState = document.getElementById('heatmap-empty');
  if (emptyState) emptyState.remove();

  const max = Math.max(...hourCounts, 1);
  const total = hourCounts.reduce((a, b) => a + b, 0);

  const cells = hourCounts.map((count, h) => {
    const intensity = count / max; // 0–1
    // Dégradé : indigo pâle (#c7d2fe = 199,210,254) → indigo vif (#4338ca = 67,56,202)
    const r = Math.round(199 + (67  - 199) * intensity);
    const g = Math.round(210 + (56  - 210) * intensity);
    const b = Math.round(254 + (202 - 254) * intensity);
    const alpha = 0.15 + intensity * 0.85;
    const bg    = `rgba(${r},${g},${b},${alpha})`;
    const textC = intensity > 0.45 ? 'rgba(255,255,255,.95)' : 'rgba(200,195,240,.8)';
    const pct   = total > 0 ? ((count / total) * 100).toFixed(1) : 0;

    return `
      <div class="heatmap-cell" style="background:${bg};color:${textC}"
           title="${h}h–${h + 1}h : ${formatNum(count)} scrobbles (${pct}%)">
        <span class="hm-hour">${h}h</span>
        <span class="hm-val">${count > 9999 ? Math.round(count / 1000) + 'k' : count > 0 ? count : ''}</span>
      </div>`;
  }).join('');

  // Légende de l'échelle de couleur
  const scaleStops = [0.1, 0.3, 0.5, 0.7, 0.9].map(v => {
    const r = Math.round(199 + (67 - 199) * v);
    const g = Math.round(210 + (56 - 210) * v);
    const b = Math.round(254 + (202 - 254) * v);
    return `<div style="width:28px;height:10px;border-radius:3px;background:rgba(${r},${g},${b},${0.15 + v * 0.85})"></div>`;
  }).join('');

  el.innerHTML = `
    <div class="heatmap-cells">${cells}</div>
    <div class="heatmap-legend">
      <span>Calme</span>
      <div class="heatmap-scale">${scaleStops}</div>
      <span>Intense</span>
    </div>`;
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
      // Last.fm ne fournit plus les images : on utilise getTopAlbums comme source
      const letter = (a.name || '?')[0].toUpperCase();
      const bg     = nameToGradient(a.name);
      const safeUrl = a.url || '#';
      const spQ  = encodeURIComponent(a.name);
      const ytQ  = encodeURIComponent(a.name);
      const imgId = `artist-img-${i}`;
      // On rend d'abord le fallback, puis on injecte l'image async
      const html = `
        <div class="music-card" style="animation-delay:${i * 0.04}s" onclick="window.open('${safeUrl}','_blank')">
          <div class="music-card-img" style="height:160px">
            <div id="${imgId}" class="spotify-cover" style="background:${bg}">
              <span class="sc-letter">${letter}</span>
              <span class="sc-name">${escHtml(a.name)}</span>
            </div>
            <div class="music-card-rank">${i + 1}</div>
            <div class="music-card-actions">
              <a class="mc-play-btn sp" href="spotify:search:${spQ}" onclick="event.stopPropagation()" title="Spotify"><i class="fab fa-spotify"></i></a>
              <a class="mc-play-btn yt" href="https://www.youtube.com/results?search_query=${ytQ}" target="_blank" rel="noopener" onclick="event.stopPropagation()" title="YouTube"><i class="fab fa-youtube"></i></a>
            </div>
          </div>
          <div class="music-card-body">
            <div class="music-card-name" title="${escHtml(a.name)}">${escHtml(a.name)}</div>
            <div class="music-card-plays">${formatNum(a.playcount)} écoutes</div>
          </div>
        </div>`;
      // Injection image différée (non bloquant)
      setTimeout(() => injectArtistImage(a.name, imgId, bg, letter), i * 120);
      return html;
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
      const spQ   = encodeURIComponent(`${t.name} ${t.artist?.name || ''}`);
      const ytQ   = encodeURIComponent(`${t.name} ${t.artist?.name || ''}`);
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
          <div class="track-play-btns">
            <a class="track-play-btn sp" href="spotify:search:${spQ}" title="Ouvrir dans Spotify" onclick="event.stopPropagation()"><i class="fab fa-spotify"></i></a>
            <a class="track-play-btn yt" href="https://www.youtube.com/results?search_query=${ytQ}" target="_blank" rel="noopener" title="Rechercher sur YouTube" onclick="event.stopPropagation()"><i class="fab fa-youtube"></i></a>
          </div>
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
    downloadCanvas(canvas, `laststats-wrapped-${document.getElementById('w-yr-sel').value}.png`);
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
   ██  GÉNÉRATION DE STORY / CARTE D'IDENTITÉ  ██
   generateStory('mini')  → Format 9:16 • Top 3 artistes/titres
   generateStory('full')  → Grande carte • Toutes les stats
   ============================================================ */
async function generateStory(type) {
  showToast('Préparation de la carte…');

  try {
    const u       = APP.userInfo;
    const year    = document.getElementById('w-yr-sel')?.value || new Date().getFullYear() - 1;
    const artists = APP.topArtistsData.slice(0, type === 'mini' ? 3 : 10);
    const tracks  = APP.topTracksData.slice(0, type === 'mini' ? 3 : 5);

    if (!artists.length) {
      showToast('Chargez d\'abord les données (Top Artistes)', 'error');
      return;
    }

    if (type === 'mini') {
      // ── MINI STORY 9:16 (360×640) ──
      const card = document.getElementById('story-mini-card');

      card.innerHTML = `
        <div class="story-header">
          <span class="story-brand">LastStats</span>
          <span class="story-year">${year}</span>
        </div>
        <div class="story-body">
          <p class="story-user">@${escHtml(u?.name || APP.username)}</p>

          <p class="story-section-title">🎤 Top Artistes</p>
          <div class="story-list">
            ${artists.map((a, i) => `
              <div class="story-item">
                <span class="story-item-rank">#${i + 1}</span>
                <span class="story-item-name">${escHtml(a.name)}</span>
                <span class="story-item-plays">${formatNum(a.playcount)}</span>
              </div>`).join('')}
          </div>

          ${tracks.length ? `
          <p class="story-section-title" style="margin-top:18px">🎵 Top Titres</p>
          <div class="story-list">
            ${tracks.map((t, i) => `
              <div class="story-item">
                <span class="story-item-rank">#${i + 1}</span>
                <span class="story-item-name">${escHtml(t.name)}</span>
                <span class="story-item-plays">${formatNum(t.playcount)}</span>
              </div>`).join('')}
          </div>` : ''}
        </div>
        <div class="story-footer">
          <span>last.fm/user/${escHtml(u?.name || APP.username)}</span>
          <span>LastStats</span>
        </div>`;

      await _captureStory('story-mini-card', 360, 640, `laststats-story-${year}.png`);

    } else {
      // ── FULL CARD (680×860) ──
      const u2       = APP.userInfo;
      const total    = parseInt(u2?.playcount || 0);
      const regTs    = parseInt(u2?.registered?.unixtime || 0);
      const eddington = APP.topArtistsData.length
        ? calcEddington(APP.topArtistsData.map(a => parseInt(a.playcount)))
        : '—';

      const streakBest    = APP.streakData?.best    ?? '—';
      const streakCurrent = APP.streakData?.current ?? '—';

      // Mood tags si disponibles
      const moodEl = document.getElementById('mood-tags');
      const moodHTML = moodEl?.innerHTML || '';

      const card = document.getElementById('story-full-card');
      card.innerHTML = `
        <div class="story-header">
          <div>
            <span class="story-brand">LastStats — Carte Complète</span>
            <div class="story-user" style="margin-top:6px">@${escHtml(u2?.name || APP.username)}</div>
          </div>
          <span class="story-year">${year}</span>
        </div>

        <div class="story-stats-row">
          <div class="story-stat"><strong>${formatNum(total)}</strong><span>Scrobbles totaux</span></div>
          <div class="story-stat"><strong>${streakBest}</strong><span>🔥 Streak record</span></div>
          <div class="story-stat"><strong>${eddington}</strong><span>Eddington</span></div>
          <div class="story-stat"><strong>${formatDate(regTs).replace(/ /g, '\u00A0')}</strong><span>Membre depuis</span></div>
        </div>

        ${moodHTML ? `
        <div class="story-mood">
          <p class="story-section-title">🎭 Mood Musical</p>
          <div class="story-mood-tags">${moodHTML}</div>
        </div>` : ''}

        <p class="story-section-title">🎤 Top ${artists.length} Artistes</p>
        <div class="story-list story-list-grid">
          ${artists.map((a, i) => `
            <div class="story-item">
              <span class="story-item-rank">#${i + 1}</span>
              <span class="story-item-name">${escHtml(a.name)}</span>
              <span class="story-item-plays">${formatNum(a.playcount)}</span>
            </div>`).join('')}
        </div>

        ${tracks.length ? `
        <p class="story-section-title" style="margin-top:16px">🎵 Top Titres</p>
        <div class="story-list story-list-grid">
          ${tracks.map((t, i) => `
            <div class="story-item">
              <span class="story-item-rank">#${i + 1}</span>
              <span class="story-item-name">${escHtml(t.name)}</span>
              <span class="story-item-plays">${formatNum(t.playcount)}</span>
            </div>`).join('')}
        </div>` : ''}

        <div class="story-footer" style="margin-top:auto">
          <span>Généré avec LastStats · ${new Date().toLocaleDateString('fr-FR')}</span>
          <span>last.fm/user/${escHtml(u2?.name || APP.username)}</span>
        </div>`;

      await _captureStory('story-full-card', 680, 860, `laststats-full-${year}.png`);
    }

    showToast('Carte téléchargée !');

  } catch (e) {
    document.body.classList.remove('export-mode');
    showToast('Erreur génération : ' + e.message, 'error');
    console.error('generateStory:', e);
  }
}

async function _captureStory(cardId, w, h, filename) {
  const card = document.getElementById(cardId);
  document.body.classList.add('export-mode');
  await sleep(60); // Laisser le DOM se peindre
  const canvas = await html2canvas(card, {
    scale: 2,
    useCORS: true,
    allowTaint: true,
    backgroundColor: null,
    width: w,
    height: h,
    windowWidth: w,
    windowHeight: h,
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
        <div class="adv-card-value" style="color:${c.color}">${c.value}</div>
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

  const oneHitWonders = [...artistMap.entries()]
    .filter(([, n]) => n === 1)
    .map(([name]) => name)
    .slice(0, 20);

  const allPlays    = [...artistMap.values()];
  const eddington   = calcEddington(allPlays);
  const uniqueCount = artistMap.size;

  const u         = APP.userInfo;
  const regTs     = parseInt(u?.registered?.unixtime || 0);
  const daysSince = regTs ? Math.floor((Date.now() - regTs * 1000) / 86400000) : 1;
  const avgDay    = (tracks.length / daysSince).toFixed(1);

  const sortedArtists = [...artistMap.entries()].sort((a, b) => b[1] - a[1]);
  const top1 = sortedArtists[0];
  const topPct = top1 ? ((top1[1] / tracks.length) * 100).toFixed(1) : 0;

  // ── Calcul et affichage du Streak ──
  const streakData  = calcStreak(tracks);
  APP.streakData    = streakData;
  updateStreakUI(streakData);

  // ── Mise à jour grille stats avancées ──
  document.getElementById('adv-grid').innerHTML = [
    { icon: '⚡', value: avgDay,    label: 'Scrobbles / jour', sub: `Calculé sur ${formatNum(tracks.length)} scrobbles réels`, color: '#6366f1' },
    { icon: '🔢', value: eddington, label: 'Nombre d\'Eddington', sub: `${eddington} artistes écoutés ≥ ${eddington}×`, color: '#8b5cf6' },
    { icon: '🌟', value: top1?.[0] || '—', label: 'Artiste n°1 (all time)', sub: `${formatNum(top1?.[1] || 0)} écoutes · ${topPct}% du total`, color: '#a855f7', noAnim: true },
    { icon: '🔥', value: streakData.best, label: 'Streak Record', sub: `Actuel : ${streakData.current} jour${streakData.current > 1 ? 's' : ''}`, color: '#f97316' },
    { icon: '🎤', value: formatNum(uniqueCount), label: 'Artistes uniques', sub: 'Sur l\'historique complet', color: '#ec4899', noAnim: true },
    { icon: '🎵', value: formatNum(tracks.length), label: 'Scrobbles analysés', sub: 'Chargés depuis l\'API', color: '#22c55e', noAnim: true },
  ].map((c, i) => `
    <div class="adv-card" style="animation-delay:${i * 0.05}s">
      <div class="adv-card-icon">${c.icon}</div>
      <div class="adv-card-value" style="color:${c.color}">${c.value}</div>
      <div class="adv-card-label">${c.label}</div>
      <div class="adv-card-sub">${c.sub}</div>
    </div>`).join('');

  // ── Graphiques avancés ──
  document.getElementById('adv-charts').classList.remove('hidden');
  renderHourlyChart(hourCounts);
  renderWeekdayChart(dayCounts);
  renderOneHitWonders(oneHitWonders, artistMap);

  // ── Heatmap dans la section Graphiques ──
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
        backgroundColor: hourCounts.map((v, i) => {
          const intensity = v / Math.max(...hourCounts, 1);
          return `rgba(99,102,241,${0.2 + intensity * 0.7})`;
        }),
        borderColor: hourCounts.map((v, i) => {
          const intensity = v / Math.max(...hourCounts, 1);
          return `rgba(99,102,241,${0.4 + intensity * 0.6})`;
        }),
        borderWidth: 1, borderRadius: 4,
      }],
    },
    options: {
      ...baseChartOpts(),
      animation: { duration: 0 },
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
      animation: { duration: 0 },
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
  APP.streakData  = null;

  try {
    await loadDashboard();
    loadVersus();
    loadMoodTags();
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
  localStorage.removeItem('ls_section');
  APP.username    = '';
  APP.apiKey      = '';
  APP.userInfo    = null;
  APP.fullHistory = null;
  APP.streakData  = null;
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

/* ============================================================
   ██  ARTIST IMAGE (via artist.getTopAlbums)  ██
   Last.fm ne fournit plus les images d'artistes directement.
   On récupère la pochette du 1er album comme substitut.
   ============================================================ */
const _imgCache = new Map();

async function getArtistImage(artistName) {
  if (_imgCache.has(artistName)) return _imgCache.get(artistName);
  try {
    const data = await API._fetch('artist.getTopAlbums', { artist: artistName, limit: 3, autocorrect: 1 });
    const albums = data.topalbums?.album || [];
    for (const alb of albums) {
      const img = alb.image?.find(i => i.size === 'extralarge')?.['#text']
               || alb.image?.find(i => i.size === 'large')?.['#text']
               || '';
      if (!isDefaultImg(img)) {
        _imgCache.set(artistName, img);
        return img;
      }
    }
  } catch { /* silencieux */ }
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
   ██  ACCENT DYNAMIQUE — ColorThief  ██
   ============================================================ */
const _colorThief = typeof ColorThief !== 'undefined' ? new ColorThief() : null;

function setAccent(colorKey) {
  APP.currentAccent = colorKey;
  localStorage.setItem('ls_accent', colorKey);

  // Mettre à jour les boutons
  document.querySelectorAll('.acc-dot').forEach(b =>
    b.classList.toggle('active', b.dataset.color === colorKey)
  );

  if (colorKey === 'dynamic') {
    // On extrait la couleur de la pochette du titre en cours si disponible
    const npArtEl = document.querySelector('#np-art img');
    if (npArtEl?.complete && npArtEl.naturalWidth > 0) {
      _applyColorThiefFromEl(npArtEl);
    }
    return;
  }

  // Palettes Material You prédéfinies (dark)
  const PALETTES = {
    purple: { accent:'#d0bcff', container:'#4f378b', on:'#381e72', onCont:'#eaddff', glow:'rgba(208,188,255,0.18)', lt:'rgba(208,188,255,0.12)' },
    blue:   { accent:'#9ecaff', container:'#004a77', on:'#001d36', onCont:'#cde5ff', glow:'rgba(158,202,255,0.18)', lt:'rgba(158,202,255,0.12)' },
    green:  { accent:'#78dc77', container:'#1e5c1c', on:'#002105', onCont:'#94f990', glow:'rgba(120,220,119,0.18)', lt:'rgba(120,220,119,0.12)' },
    red:    { accent:'#ffb4ab', container:'#93000a', on:'#690005', onCont:'#ffdad6', glow:'rgba(255,180,171,0.18)', lt:'rgba(255,180,171,0.12)' },
    orange: { accent:'#ffb77c', container:'#6d3400', on:'#3d1d00', onCont:'#ffdcc0', glow:'rgba(255,183,124,0.18)', lt:'rgba(255,183,124,0.12)' },
  };

  // Variantes light
  const LIGHT = {
    purple: { accent:'#6750a4', container:'#eaddff', on:'#ffffff', onCont:'#21005d', glow:'rgba(103,80,164,0.3)', lt:'rgba(103,80,164,0.1)' },
    blue:   { accent:'#0061a4', container:'#cde5ff', on:'#ffffff', onCont:'#001d36', glow:'rgba(0,97,164,0.3)',   lt:'rgba(0,97,164,0.1)'   },
    green:  { accent:'#006e1c', container:'#94f990', on:'#ffffff', onCont:'#002105', glow:'rgba(0,110,28,0.3)',   lt:'rgba(0,110,28,0.1)'   },
    red:    { accent:'#ba1a1a', container:'#ffdad6', on:'#ffffff', onCont:'#410002', glow:'rgba(186,26,26,0.3)',   lt:'rgba(186,26,26,0.1)'  },
    orange: { accent:'#9c4e00', container:'#ffdcc0', on:'#ffffff', onCont:'#3d1d00', glow:'rgba(156,78,0,0.3)',   lt:'rgba(156,78,0,0.1)'   },
  };

  const isDark = APP.currentTheme === 'dark'
    || (APP.currentTheme === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches);

  const pal = (isDark ? PALETTES : LIGHT)[colorKey] || PALETTES.purple;
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
  img.onerror = () => {}; // silencieux
  img.src = imgUrl;
}

function _applyColorThiefFromEl(imgEl) {
  if (!_colorThief || !imgEl) return;
  try {
    const [r, g, b] = _colorThief.getColor(imgEl);
    // Convertir RGB → palette M3 simplifiée
    const h = _rgbToHsl(r, g, b)[0];
    const accent    = `hsl(${h},65%,75%)`;
    const container = `hsl(${h},45%,28%)`;
    const on        = `hsl(${h},45%,14%)`;
    const onCont    = `hsl(${h},65%,90%)`;
    const glow      = `hsla(${h},65%,75%,0.18)`;
    const lt        = `hsla(${h},65%,75%,0.12)`;
    _applyCSSAccent({ accent, container, on, onCont, glow, lt });
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
   ██  BADGE ENGINE  ██
   Système de gamification infinie — paliers exponentiels
   ============================================================ */
const BadgeEngine = (() => {

  // ── Définition des paliers (Bronze → Elite) ──
  const TIERS = [
    { key: 'bronze',  label: 'Bronze',  icon: '🥉', xp: 10  },
    { key: 'argent',  label: 'Argent',  icon: '🥈', xp: 25  },
    { key: 'or',      label: 'Or',      icon: '🥇', xp: 50  },
    { key: 'diamant', label: 'Diamant', icon: '💎', xp: 100 },
    { key: 'elite',   label: 'Élite',   icon: '👑', xp: 200 },
  ];

  // Formule exponentielle : chaque palier supérieur nécessite ~2× plus
  // threshold(tier, level) = base * 2^(level-1)
  function thresholds(base, count = 5) {
    return Array(count).fill(0).map((_, i) => Math.round(base * Math.pow(2, i)));
  }

  // ── Définitions des badges ──
  const BADGE_DEFS = [
    // --- NOCTAMBULE ---
    {
      id: 'night_owl', cat: 'noctambule', icon: '🦉', name: 'Oiseau de Nuit',
      desc: 'Nombre d\'écoutes entre 00h et 05h du matin',
      thresholds: thresholds(50),
      compute: (hist) => hist.filter(t => {
        const h = new Date(parseInt(t.date?.uts || 0) * 1000).getHours();
        return h >= 0 && h < 5;
      }).length,
    },
    // --- EXPLORATEUR ---
    {
      id: 'explorer', cat: 'exploration', icon: '🧭', name: 'Explorateur',
      desc: 'Ratio artistes uniques / écoutes totales × 1000',
      thresholds: thresholds(50),
      compute: (hist) => {
        if (!hist.length) return 0;
        const unique = new Set(hist.map(t => (t.artist?.['#text'] || t.artist?.name || '').toLowerCase())).size;
        return Math.round((unique / hist.length) * 1000);
      },
    },
    {
      id: 'discoverer', cat: 'exploration', icon: '🔭', name: 'Découvreur',
      desc: 'Nombre d\'artistes distincts écoutés',
      thresholds: thresholds(50),
      compute: (hist) => new Set(hist.map(t => (t.artist?.['#text'] || t.artist?.name || '').toLowerCase())).size,
    },
    // --- FIDÉLITÉ ---
    {
      id: 'loyal', cat: 'fidelite', icon: '💖', name: 'Fidélité',
      desc: 'Max d\'écoutes d\'un même artiste sur 7 jours consécutifs',
      thresholds: thresholds(20),
      compute: (hist) => {
        if (!hist.length) return 0;
        // Grouper par semaine ISO × artiste
        const weekMap = new Map();
        for (const t of hist) {
          const ts = parseInt(t.date?.uts || 0);
          if (!ts) continue;
          const d   = new Date(ts * 1000);
          const week = `${d.getFullYear()}-W${Math.ceil((d.getDate() + 6 - (d.getDay() || 7)) / 7)}`;
          const art  = (t.artist?.['#text'] || t.artist?.name || '').toLowerCase();
          const k    = `${week}::${art}`;
          weekMap.set(k, (weekMap.get(k) || 0) + 1);
        }
        return Math.max(0, ...[...weekMap.values()]);
      },
    },
    {
      id: 'obsessed', cat: 'fidelite', icon: '🔁', name: 'Obsessionnel',
      desc: 'Max d\'écoutes d\'un même artiste en une seule journée',
      thresholds: thresholds(10),
      compute: (hist) => {
        const dayMap = new Map();
        for (const t of hist) {
          const ts  = parseInt(t.date?.uts || 0);
          if (!ts) continue;
          const d   = new Date(ts * 1000);
          const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}::${(t.artist?.['#text'] || '').toLowerCase()}`;
          dayMap.set(key, (dayMap.get(key) || 0) + 1);
        }
        return Math.max(0, ...[...dayMap.values()]);
      },
    },
    // --- VOLUME ---
    {
      id: 'scrobbler', cat: 'volume', icon: '🎵', name: 'Scrobbler',
      desc: 'Nombre total de scrobbles',
      thresholds: thresholds(1000),
      compute: (hist) => hist.length,
    },
    {
      id: 'binge', cat: 'volume', icon: '🎧', name: 'Binge Listener',
      desc: 'Max de scrobbles en une seule journée',
      thresholds: thresholds(50),
      compute: (hist) => {
        const dayMap = new Map();
        for (const t of hist) {
          const ts = parseInt(t.date?.uts || 0);
          if (!ts) continue;
          const d  = new Date(ts * 1000);
          const k  = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
          dayMap.set(k, (dayMap.get(k) || 0) + 1);
        }
        return Math.max(0, ...[...dayMap.values()]);
      },
    },
    // --- DIVERSITÉ ---
    {
      id: 'diversified', cat: 'diversite', icon: '🌈', name: 'Éclectique',
      desc: 'Nombre de genres distincts écoutés (via mood tags en cache)',
      thresholds: thresholds(5),
      compute: () => {
        // Approximation : genres identifiés dans le mood tags cache
        const moods = document.querySelectorAll('.mood-tag');
        return moods.length;
      },
    },
    {
      id: 'marathon', cat: 'volume', icon: '🏃', name: 'Marathonien',
      desc: 'Streak record (jours consécutifs d\'écoute)',
      thresholds: thresholds(7),
      compute: () => APP.streakData?.best || 0,
    },
  ];

  // ── Calcul d'un badge ──
  function computeBadge(def, history) {
    const value = def.compute(history);
    let tierIdx = -1;
    for (let i = def.thresholds.length - 1; i >= 0; i--) {
      if (value >= def.thresholds[i]) { tierIdx = i; break; }
    }
    const nextThreshold = tierIdx < def.thresholds.length - 1
      ? def.thresholds[tierIdx + 1]
      : null;
    return {
      ...def,
      value,
      tierIdx,
      tier: tierIdx >= 0 ? TIERS[tierIdx] : null,
      unlocked: tierIdx >= 0,
      nextThreshold,
    };
  }

  // ── Titre de niveau global ──
  const LEVEL_TITLES = [
    'Audiophile débutant','Mélomane','Scrobbleur',
    'Curateur musical','Expert','Virtuose','Légende','Demi-dieu de la musique',
  ];

  function levelFromXP(xp) {
    // niveau = floor(log2(xp/100 + 1)) + 1, plafonné
    if (xp <= 0) return { level: 1, xpCurr: 0, xpNext: 100, pct: 0 };
    const level    = Math.min(LEVEL_TITLES.length, Math.floor(Math.log2(xp / 50 + 1)) + 1);
    const xpForLvl = Math.round(50 * (Math.pow(2, level - 1) - 1));
    const xpForNext= Math.round(50 * (Math.pow(2, level) - 1));
    const pct      = Math.min(100, Math.round(((xp - xpForLvl) / (xpForNext - xpForLvl)) * 100));
    return { level, xpCurr: xp, xpNext: xpForNext, pct, title: LEVEL_TITLES[level - 1] || LEVEL_TITLES.at(-1) };
  }

  // ── Entrée publique : compute() ──
  function compute() {
    const history = APP.fullHistory;

    if (!history || !history.length) {
      document.getElementById('badges-empty')?.classList.remove('hidden');
      document.getElementById('badges-container')?.classList.add('hidden');
      showToast('Chargez l\'historique complet pour calculer les succès', 'error');
      return;
    }

    document.getElementById('badges-empty')?.classList.add('hidden');
    document.getElementById('badges-load-btn').innerHTML = '<i class="fas fa-spinner fa-spin"></i> Calcul…';

    // Calcul fragmenté pour ne pas bloquer l'UI
    const results = [];
    let i = 0;

    function processNext() {
      if (i >= BADGE_DEFS.length) {
        _render(results);
        document.getElementById('badges-load-btn').innerHTML = '<i class="fas fa-sync-alt"></i> Recalculer';
        return;
      }
      results.push(computeBadge(BADGE_DEFS[i], history));
      i++;
      setTimeout(processNext, 0); // non-bloquant
    }
    processNext();
  }

  // ── Rendu ──
  function _render(results) {
    document.getElementById('badges-container')?.classList.remove('hidden');

    // Score global
    const totalXP = results.reduce((acc, b) => acc + (b.unlocked ? TIERS[b.tierIdx].xp : 0), 0);
    const unlocked = results.filter(b => b.unlocked).length;
    const lvlData  = levelFromXP(totalXP);

    const lvlEl = document.getElementById('bsc-level');
    if (lvlEl) lvlEl.textContent = lvlData.level;
    const titleEl = document.getElementById('bsc-title');
    if (titleEl) titleEl.textContent = lvlData.title;
    const xpFill = document.getElementById('bsc-xp-fill');
    if (xpFill) setTimeout(() => { xpFill.style.width = lvlData.pct + '%'; }, 200);
    const xpVal = document.getElementById('bsc-xp-val');
    if (xpVal) xpVal.textContent = `${totalXP} XP (niv. suivant: ${lvlData.xpNext})`;

    const unlockedEl = document.getElementById('bsc-unlocked');
    if (unlockedEl) unlockedEl.textContent = `${unlocked} succès débloqués`;
    const totalEl = document.getElementById('bsc-total');
    if (totalEl) totalEl.textContent = `sur ${results.length}`;

    // Badge count dans la nav
    const navBadge = document.getElementById('badges-count-badge');
    if (navBadge) {
      if (unlocked > 0) { navBadge.textContent = unlocked; navBadge.style.display = ''; }
      else navBadge.style.display = 'none';
    }

    // Rendu par catégorie
    const cats = ['noctambule','exploration','fidelite','volume','diversite'];
    cats.forEach(cat => {
      const grid = document.getElementById(`badge-grid-${cat}`);
      if (!grid) return;
      const catBadges = results.filter(b => b.cat === cat);
      grid.innerHTML = catBadges.map(b => _badgeCard(b)).join('');
    });

    // Stocker pour le modal
    window._badgeResults = results;
  }

  function _badgeCard(b) {
    const tierClass  = b.unlocked ? `tier-${b.tier.key}` : 'tier-bronze';
    const tierLabel  = b.unlocked ? `${b.tier.icon} ${b.tier.label}` : '🔒 Verrouillé';
    const nextInfo   = b.nextThreshold !== null
      ? `${b.value} / ${b.nextThreshold}`
      : b.unlocked ? 'Max atteint !' : '';
    const cardClass  = b.unlocked ? 'badge-card unlocked' : 'badge-card locked';

    // Animation décalée par tier
    const delay      = b.unlocked ? `animation-delay:${(b.tierIdx || 0) * 0.08}s` : '';
    return `
      <div class="${cardClass}" style="${delay}" onclick="showBadgeModal('${b.id}')">
        <div class="badge-card-icon">${b.icon}</div>
        <div class="badge-card-name">${escHtml(b.name)}</div>
        <div class="badge-card-tier ${tierClass}">${tierLabel}</div>
        ${nextInfo ? `<div class="badge-card-progress">${nextInfo}</div>` : ''}
      </div>`;
  }

  return { compute, BADGE_DEFS, TIERS };
})();

/* ── Modale badge ── */
function showBadgeModal(badgeId) {
  const results = window._badgeResults || [];
  const b = results.find(r => r.id === badgeId);
  if (!b) return;

  document.getElementById('bm-icon').textContent   = b.icon;
  document.getElementById('bm-title').textContent  = b.name;
  document.getElementById('bm-desc').textContent   = b.desc;

  const tierEl = document.getElementById('bm-tier');
  if (b.unlocked) {
    tierEl.className = `bm-tier badge-card-tier tier-${b.tier.key}`;
    tierEl.textContent = `${b.tier.icon} ${b.tier.label}`;
  } else {
    tierEl.className = 'bm-tier';
    tierEl.textContent = '🔒 Pas encore débloqué';
  }

  const nextT   = b.nextThreshold !== null ? b.nextThreshold : b.thresholds.at(-1);
  const pct     = nextT > 0 ? Math.min(100, Math.round((b.value / nextT) * 100)) : 100;
  const fillEl  = document.getElementById('bm-progress-fill');
  if (fillEl) setTimeout(() => { fillEl.style.width = pct + '%'; }, 150);

  document.getElementById('bm-progress-cur').textContent  = `Valeur : ${b.value}`;
  document.getElementById('bm-progress-next').textContent = b.nextThreshold
    ? `Prochain palier : ${b.nextThreshold}` : 'Palier max atteint !';

  // Paliers visuels
  const tiersRow = document.getElementById('bm-tiers-row');
  if (tiersRow) {
    tiersRow.innerHTML = b.thresholds.map((thresh, i) => {
      const tier    = BadgeEngine.TIERS[i];
      const achieved = b.value >= thresh;
      const isCurr   = b.unlocked && b.tierIdx === i;
      const cls      = isCurr ? 'bm-tier-chip current' : achieved ? 'bm-tier-chip achieved' : 'bm-tier-chip';
      return `<span class="${cls}" title="${tier.label}: ${thresh}">${tier.icon} ${thresh}</span>`;
    }).join('');
  }

  document.getElementById('badge-modal').classList.remove('hidden');
}

function closeBadgeModal(e) {
  if (e && e.target !== document.getElementById('badge-modal')) return;
  document.getElementById('badge-modal').classList.add('hidden');
}

/* ============================================================
   ██  VISUALISATIONS AVANCÉES  ██
   1. Radar Chart (genres via mood tags)
   2. Treemap Top 100 artistes
   3. Sankey flux d'écoute
   ============================================================ */
async function loadVizPlus() {
  const statusEl  = document.getElementById('vizplus-status');
  const statusTxt = document.getElementById('vizplus-status-txt');
  const btn       = document.getElementById('vizplus-load-btn');

  if (statusEl) statusEl.classList.remove('hidden');
  if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Génération…'; }

  try {
    // ── 1. RADAR ──
    if (statusTxt) statusTxt.textContent = 'Analyse des genres musicaux…';
    await _buildRadarChart();

    // ── 2. TREEMAP ──
    if (statusTxt) statusTxt.textContent = 'Construction du Treemap Top 100…';
    await _buildTreemap();

    // ── 3. SANKEY ──
    if (statusTxt) statusTxt.textContent = 'Calcul des flux d\'écoute…';
    await _buildSankey();

    if (statusEl) statusEl.classList.add('hidden');
    showToast('Visualisations générées !');
  } catch (e) {
    console.error('loadVizPlus:', e);
    if (statusTxt) statusTxt.textContent = 'Erreur : ' + e.message;
    setTimeout(() => statusEl?.classList.add('hidden'), 3000);
  } finally {
    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-magic"></i> Générer'; }
  }
}

// ─── RADAR : Genres / Mood Tags ───────────────────────────────
async function _buildRadarChart() {
  const phEl  = document.getElementById('vizplus-radar-ph');
  const wrap  = document.getElementById('vizplus-radar-wrap');

  // Réutiliser les mood tags déjà calculés OU les refetcher
  const topArtists = APP.topArtistsData.length
    ? APP.topArtistsData.slice(0, 15)
    : (await API.call('user.getTopArtists', { period: 'overall', limit: 15 })).topartists?.artist || [];

  // Genres cibles pour le radar
  const TARGET_GENRES = ['rock','pop','electronic','hip-hop','metal','jazz','classical','indie','r&b','country'];
  const scores = {};
  TARGET_GENRES.forEach(g => { scores[g] = 0; });

  const tagResults = await Promise.allSettled(
    topArtists.map(a => API.call('artist.getTopTags', { artist: a.name }))
  );

  const IGNORED = new Set(['seen live','favorites','favourite','love','awesome','all','good','new','old']);

  tagResults.forEach((res, i) => {
    if (res.status !== 'fulfilled') return;
    const tags   = res.value.toptags?.tag || [];
    const weight = topArtists.length - i;
    tags.slice(0, 10).forEach(tag => {
      const name = (tag.name || '').toLowerCase().trim();
      for (const genre of TARGET_GENRES) {
        if (name.includes(genre) && !IGNORED.has(name)) {
          scores[genre] += (parseInt(tag.count) || 30) * weight;
        }
      }
    });
  });

  const labels = TARGET_GENRES.map(g => g.charAt(0).toUpperCase() + g.slice(1));
  const data   = TARGET_GENRES.map(g => scores[g]);

  if (data.every(v => v === 0)) {
    if (phEl) phEl.innerHTML = '<i class="fas fa-spider fa-2x"></i><p>Pas assez de tags pour ce graphique</p>';
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
        label: 'Présence des genres',
        data,
        backgroundColor: 'rgba(99,102,241,0.15)',
        borderColor:     '#6366f1',
        pointBackgroundColor: CHART_PALETTE,
        pointBorderColor:     '#fff',
        pointBorderWidth: 2,
        pointRadius: 5,
        borderWidth: 2,
      }],
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      animation: { duration: 800 },
      plugins: {
        legend: { display: false },
        tooltip: { callbacks: { label: ctx => ` Score genre : ${ctx.raw}` } },
      },
      scales: {
        r: {
          grid:       { color: c.grid },
          ticks:      { color: c.text, font: { size: 10 }, backdropColor: 'transparent' },
          pointLabels:{ color: c.text, font: { size: 12 } },
          beginAtZero: true,
        },
      },
    },
  });
}

// ─── TREEMAP : Top 100 artistes ───────────────────────────────
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

  const treeData = top100.map((a, i) => ({
    label: a.name,
    value: parseInt(a.playcount) || 1,
    color: CHART_PALETTE[i % CHART_PALETTE.length] + 'cc',
  }));

  destroyChart('chart-treemap');
  APP.charts['chart-treemap'] = new Chart(document.getElementById('chart-treemap'), {
    type: 'treemap',
    data: {
      datasets: [{
        label: 'Top 100 Artistes',
        tree: treeData,
        key: 'value',
        labels: { display: true, formatter: (ctx) => {
          const d = ctx.dataset.data[ctx.dataIndex];
          return d ? [d._data.label, formatNum(d._data.value)] : '';
        }},
        backgroundColor: (ctx) => {
          const d = ctx.dataset.data[ctx.dataIndex];
          return d?._data?.color || '#6366f1cc';
        },
        borderWidth: 1,
        borderColor: 'rgba(0,0,0,0.25)',
        spacing: 2,
      }],
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      animation: { duration: 600 },
      plugins: {
        legend: { display: false },
        tooltip: { callbacks: {
          title: (items) => items[0]?.raw?._data?.label || '',
          label: (ctx)  => ` ${formatNum(ctx.raw?._data?.value)} écoutes`,
        }},
      },
    },
  });
}

// ─── SANKEY : Flux d'écoute entre artistes ────────────────────
async function _buildSankey() {
  const phEl = document.getElementById('vizplus-sankey-ph');
  const wrap = document.getElementById('vizplus-sankey-wrap');
  const svg  = document.getElementById('chart-sankey');

  // Nécessite l'historique complet
  if (!APP.fullHistory || APP.fullHistory.length < 50) {
    if (phEl) phEl.innerHTML = `<i class="fas fa-stream fa-2x"></i>
      <p>Chargez d'abord l'historique complet (section Stats Avancées)</p>
      <button class="btn-fetch-sm" onclick="nav('advanced');setTimeout(()=>fetchFullHistory(),300)">
        <i class="fas fa-database"></i> Charger
      </button>`;
    return;
  }

  if (phEl) phEl.classList.add('hidden');
  if (wrap) wrap.classList.remove('hidden');

  // Construire les transitions artiste → artiste
  const transitions = new Map();
  const top20Artists = new Set(
    (APP.topArtistsData.slice(0, 20) || []).map(a => a.name.toLowerCase())
  );

  const history = [...APP.fullHistory]
    .filter(t => parseInt(t.date?.uts || 0) > 0)
    .sort((a, b) => parseInt(a.date?.uts) - parseInt(b.date?.uts));

  // Sessions : pause > 30 min = nouvelle session
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
    prevArtist = artist;
    prevTs     = ts;
  }

  // Top 30 transitions
  const topLinks = [...transitions.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 30);

  if (!topLinks.length) {
    if (phEl) { phEl.classList.remove('hidden'); phEl.innerHTML = '<i class="fas fa-stream fa-2x"></i><p>Pas assez de transitions entre artistes</p>'; }
    if (wrap) wrap.classList.add('hidden');
    return;
  }

  // Construire nœuds et liens pour d3-sankey
  const nodeNames = [...new Set(topLinks.flatMap(([k]) => k.split('→')))];
  const nodeIdx   = Object.fromEntries(nodeNames.map((n, i) => [n, i]));

  const nodes = nodeNames.map(n => ({ name: n }));
  const links = topLinks
    .map(([k, v]) => {
      const [src, tgt] = k.split('→');
      if (nodeIdx[src] === undefined || nodeIdx[tgt] === undefined) return null;
      return { source: nodeIdx[src], target: nodeIdx[tgt], value: v };
    })
    .filter(Boolean);

  // Rendu D3 Sankey
  const container = svg.parentElement;
  const W = container.clientWidth || 700;
  const H = 440;

  svg.setAttribute('viewBox', `0 0 ${W} ${H}`);
  svg.setAttribute('width', W);

  // Vider le SVG
  while (svg.firstChild) svg.removeChild(svg.firstChild);

  const sankey = d3.sankey()
    .nodeWidth(18)
    .nodePadding(12)
    .extent([[12, 12], [W - 12, H - 12]]);

  const graph = sankey({ nodes: nodes.map(d => ({ ...d })), links: links.map(d => ({ ...d })) });

  const isDark = APP.currentTheme !== 'light';
  const svgEl  = d3.select(svg);

  // Liens
  svgEl.append('g')
    .attr('fill', 'none')
    .selectAll('path')
    .data(graph.links)
    .join('path')
    .attr('d', d3.sankeyLinkHorizontal())
    .attr('stroke', (d, i) => CHART_PALETTE[i % CHART_PALETTE.length])
    .attr('stroke-width', d => Math.max(1, d.width))
    .attr('stroke-opacity', .35)
    .append('title').text(d => `${d.source.name} → ${d.target.name}: ${d.value}`);

  // Nœuds
  const g = svgEl.append('g').selectAll('g').data(graph.nodes).join('g');
  g.append('rect')
    .attr('x', d => d.x0).attr('y', d => d.y0)
    .attr('width', d => d.x1 - d.x0).attr('height', d => d.y1 - d.y0)
    .attr('fill', (_, i) => CHART_PALETTE[i % CHART_PALETTE.length])
    .attr('rx', 3);

  // Labels
  g.append('text')
    .attr('x', d => d.x0 < W / 2 ? d.x1 + 6 : d.x0 - 6)
    .attr('y', d => (d.y1 + d.y0) / 2)
    .attr('dy', '.35em')
    .attr('text-anchor', d => d.x0 < W / 2 ? 'start' : 'end')
    .style('fill', isDark ? '#cac4d0' : '#1c1b1f')
    .style('font-size', '11px')
    .style('font-family', 'Inter, sans-serif')
    .text(d => d.name.length > 16 ? d.name.slice(0, 16) + '…' : d.name);
}

/* ============================================================
   ██  ANALYSE MAINSTREAM VS OBSCUR  ██
   Score d'originalité basé sur artist.stats.listeners
   ============================================================ */
let _obscurityData = [];

async function loadObscurityScore() {
  const btn     = document.getElementById('obscurity-load-btn');
  const emptyEl = document.getElementById('obscurity-empty');
  const listEl  = document.getElementById('obscurity-list');

  if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Analyse…'; }
  if (emptyEl) emptyEl.innerHTML = `<div class="spinner-sm"></div><p style="margin-top:10px">Analyse des artistes en cours…</p>`;

  try {
    let artists = APP.topArtistsData;
    if (!artists.length) {
      const d = await API.call('user.getTopArtists', { period: 'overall', limit: 50 });
      artists = d.topartists?.artist || [];
      APP.topArtistsData = artists;
    }

    const top30 = artists.slice(0, 30);
    const results = [];

    // Récupération des listeners par batch de 5
    for (let i = 0; i < top30.length; i += 5) {
      const batch = top30.slice(i, i + 5);
      const infos = await Promise.allSettled(
        batch.map(a => API.call('artist.getInfo', { artist: a.name, autocorrect: 1 }))
      );

      infos.forEach((res, j) => {
        const artist    = batch[j];
        const listeners = parseInt(res.value?.artist?.stats?.listeners || 0);
        const plays     = parseInt(artist.playcount || 0);

        if (!listeners) return;
        // Score d'obscurité : rapport entre l'engagement de l'utilisateur et la popularité globale
        // Normalisé : 1 000 000 listeners = très mainstream
        // Si tu écoutes beaucoup un artiste avec peu de listeners = score élevé
        const popularityRatio = Math.min(1, listeners / 2_000_000);
        const obscurityRaw    = (1 - popularityRatio) * Math.log10(plays + 1) / Math.log10(10000 + 1) * 100;
        const obscurityScore  = Math.min(100, Math.round(obscurityRaw));

        const type = listeners > 2_000_000 ? 'mainstream'
                   : listeners < 100_000   ? 'obscur'
                   : 'culte';

        results.push({ name: artist.name, plays, listeners, obscurityScore, type, url: artist.url || '#' });
      });
      await sleep(100);
    }

    _obscurityData = results;
    _renderObscurityScore(results);

    if (emptyEl) emptyEl.classList.add('hidden');
    if (listEl)  listEl.classList.remove('hidden');

  } catch (e) {
    if (emptyEl) emptyEl.innerHTML = `<i class="fas fa-exclamation-triangle fa-3x"></i><p>Erreur : ${escHtml(e.message)}</p>`;
    console.error('obscurity:', e);
  } finally {
    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-search"></i> Recalculer'; }
  }
}

function _renderObscurityScore(data) {
  if (!data.length) return;

  // Score moyen global pondéré par les écoutes
  const totalPlays  = data.reduce((s, d) => s + d.plays, 0);
  const globalScore = Math.round(
    data.reduce((s, d) => s + d.obscurityScore * (d.plays / totalPlays), 0)
  );

  // Jauge SVG
  const arc   = document.getElementById('oh-gauge-arc');
  const scoreValEl = document.getElementById('oh-score-val');
  const labelEl    = document.getElementById('oh-label');
  const descEl     = document.getElementById('oh-desc');
  const fillEl     = document.getElementById('oh-sp-fill');

  if (arc) {
    const totalLen = 251.2;
    const dash     = totalLen * (1 - globalScore / 100);
    setTimeout(() => { arc.style.strokeDashoffset = dash; }, 200);
    const color = globalScore < 30 ? '#f97316' : globalScore < 60 ? '#6366f1' : '#06b6d4';
    arc.style.stroke = color;
  }
  if (scoreValEl) scoreValEl.textContent = globalScore;

  if (labelEl) {
    labelEl.textContent = globalScore < 25 ? '🎤 Pur mainstream'
                        : globalScore < 45 ? '🎵 Grand public'
                        : globalScore < 65 ? '🎸 Auditeur éclairé'
                        : globalScore < 80 ? '💎 Goûts obscurs'
                        : '🌑 Ultra-underground';
  }

  if (descEl) {
    const mainCount = data.filter(d => d.type === 'mainstream').length;
    const obscCount = data.filter(d => d.type === 'obscur').length;
    descEl.textContent = `${mainCount} artiste(s) mainstream · ${obscCount} artiste(s) obscur(s) dans votre top 30.`;
  }

  if (fillEl) {
    setTimeout(() => { fillEl.style.left = globalScore + '%'; }, 400);
  }

  _renderObscurityItems(data, 'ratio');
}

function sortObscurity(sortKey) {
  document.querySelectorAll('.obs-filter').forEach(b =>
    b.classList.toggle('active', b.dataset.sort === sortKey)
  );
  _renderObscurityItems(_obscurityData, sortKey);
}

function _renderObscurityItems(data, sortKey = 'ratio') {
  const container = document.getElementById('obscurity-items');
  if (!container) return;

  const sorted = [...data].sort((a, b) =>
    sortKey === 'plays' ? b.plays - a.plays : b.obscurityScore - a.obscurityScore
  );

  const maxScore = Math.max(...sorted.map(d => d.obscurityScore), 1);

  container.innerHTML = sorted.map((d, i) => {
    const typeClass = `obs-type-${d.type}`;
    const typeLabel = d.type === 'mainstream' ? '🎤 Mainstream'
                    : d.type === 'obscur'     ? '💎 Obscur'
                    : '🎸 Culte';
    const pct       = Math.round((d.obscurityScore / maxScore) * 100);
    const bg        = nameToGradient(d.name);
    const letter    = d.name[0].toUpperCase();

    return `
      <div class="obscurity-item" style="animation-delay:${i * 0.03}s" onclick="window.open('${d.url}','_blank')">
        <div class="obs-rank">${i + 1}</div>
        <div class="obs-art-img" id="obs-img-${i}">
          <div class="obs-art-letter" style="background:${bg}">${letter}</div>
        </div>
        <div class="obs-info">
          <div class="obs-name">${escHtml(d.name)}</div>
          <div class="obs-plays">${formatNum(d.plays)} écoutes · ${formatNum(d.listeners)} auditeurs</div>
        </div>
        <div class="obs-bar-wrap">
          <div class="obs-bar" style="width:${pct}%"></div>
        </div>
        <span class="obs-type-badge ${typeClass}">${typeLabel}</span>
        <div class="obs-score-wrap">
          <div class="obs-score">${d.obscurityScore}</div>
          <div class="obs-score-lbl">/100</div>
        </div>
      </div>`;
  }).join('');

  // Charger les images artistes en différé
  sorted.forEach((d, i) => {
    setTimeout(() => {
      const bg     = nameToGradient(d.name);
      const letter = d.name[0].toUpperCase();
      injectArtistImage(d.name, `obs-img-${i}`, bg, letter);
    }, i * 100 + 500);
  });
}

/* ============================================================
   ██  EXPORT DONNÉES (JSON & CSV)  ██
   ============================================================ */
function exportStats(format) {
  const payload = {
    username:    APP.username,
    exportDate:  new Date().toISOString(),
    userInfo: {
      playcount: APP.userInfo?.playcount,
      country:   APP.userInfo?.country,
      registered: APP.userInfo?.registered?.unixtime,
    },
    topArtists: APP.topArtistsData.slice(0, 50).map(a => ({
      name:      a.name,
      playcount: parseInt(a.playcount),
      url:       a.url,
    })),
    topAlbums: APP.topAlbumsData.slice(0, 50).map(a => ({
      name:      a.name,
      artist:    a.artist?.name,
      playcount: parseInt(a.playcount),
    })),
    topTracks: APP.topTracksData.slice(0, 50).map(t => ({
      name:      t.name,
      artist:    t.artist?.name,
      playcount: parseInt(t.playcount),
      url:       t.url,
    })),
    streakData: APP.streakData,
    obscurityScore: _obscurityData.slice(0, 30).map(d => ({
      name:          d.name,
      plays:         d.plays,
      listeners:     d.listeners,
      obscurityScore: d.obscurityScore,
      type:          d.type,
    })),
  };

  if (format === 'json') {
    _downloadText(JSON.stringify(payload, null, 2), `laststats-${APP.username}-${Date.now()}.json`, 'application/json');
    showToast('Export JSON téléchargé !');
    return;
  }

  if (format === 'csv') {
    const rows = ['Type,Nom,Artiste,Écoutes,URL'];
    payload.topArtists.forEach(a => rows.push(`Artiste,"${a.name.replace(/"/g,'""')}",,${a.playcount},${a.url || ''}`));
    payload.topAlbums.forEach(a  => rows.push(`Album,"${a.name.replace(/"/g,'""')}","${(a.artist||'').replace(/"/g,'""')}",${a.playcount},`));
    payload.topTracks.forEach(t  => rows.push(`Titre,"${t.name.replace(/"/g,'""')}","${(t.artist||'').replace(/"/g,'""')}",${t.playcount},${t.url || ''}`));
    _downloadText(rows.join('\n'), `laststats-${APP.username}-${Date.now()}.csv`, 'text/csv');
    showToast('Export CSV téléchargé !');
  }
}

function _downloadText(content, filename, type) {
  const blob = new Blob([content], { type });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url; a.download = filename; a.click();
  setTimeout(() => URL.revokeObjectURL(url), 3000);
}

/* ============================================================
   ██  INIT  : Restauration accent + nouvelles fonctions  ██
   ============================================================ */
// Étendre initApp pour restaurer l'accent enregistré
const _origInitApp = initApp;
window.initApp = async function() {
  await _origInitApp();
  // Restaurer accent
  const savedAccent = localStorage.getItem('ls_accent') || 'purple';
  APP.currentAccent = savedAccent;
  setAccent(savedAccent);
};

// Étendre refreshData pour recalculer les nouvelles sections si elles sont actives
const _origRefreshData = refreshData;
window.refreshData = async function() {
  await _origRefreshData();
  const active = document.querySelector('.app-sec.active')?.id?.replace('s-', '');
  if (active === 'vizplus')   loadVizPlus();
  if (active === 'obscurity') loadObscurityScore();
};

