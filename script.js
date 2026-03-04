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
