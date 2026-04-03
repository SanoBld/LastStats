'use strict';

/* ═══════════════════════════════════════════════════════════════
   friends.js — LastStats Friends & Profile Search  v2
   Features: Color Sync · Home Tab · Group Stats · Media Preview
             Web Push · Musical Coincidence · Top5 Modal
═══════════════════════════════════════════════════════════════ */

const LASTFM_URL    = 'https://ws.audioscrobbler.com/2.0/';
const DEFAULT_IMG   = '2a96cbd8b46e442fc41c2b86b821562f';
const LIVE_POLL_MS  = 30_000;
const MAX_FRIENDS   = 200;
const RECENT_MAX    = 12;
const LS_FAV_KEY    = 'ls_friends_favorites';
const LS_RECENT_KEY = 'ls_friends_recent';
const LS_APIKEY     = 'ls_apikey';
const LS_USERNAME   = 'ls_username';
const LS_THEME      = 'ls_theme';
const LS_ACCENT     = 'ls_accent';
const LS_COLOR_SYNC = 'ls_color_sync';
const LS_PUSH         = 'ls_push_enabled';
const LS_TRACK_SEEN_KEY = 'ls_track_seen';
const LS_FLASHBACK_KEY  = 'ls_flashback_cache';
const LS_TRACK_PLAYS_CACHE = 'ls_track_plays_cache';  // track.getInfo userplaycount cache
const LS_DAILY_SCROBBLES   = 'ls_daily_scrobbles';    // daily scrobble counts per friend
const LS_DISCOVERY_CACHE   = 'ls_discovery_cache';    // artist.getInfo userplaycount for discovery wall
const LS_GROUP_WEEKLY_KEY  = 'ls_group_weekly_top';   // cached group weekly top artists

/* ─── Helpers ─── */
const $  = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => [...ctx.querySelectorAll(sel)];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function fmt(n) {
  if (n == null || isNaN(+n)) return '—';
  n = +n;
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M';
  if (n >= 1_000)     return (n / 1_000).toFixed(1).replace('.0','') + 'k';
  return n.toString();
}
function timeAgo(unixTs) {
  const s = Math.floor(Date.now() / 1000) - unixTs;
  if (s < 60)    return 'il y a quelques secondes';
  if (s < 3600)  return `il y a ${Math.floor(s/60)} min`;
  if (s < 86400) return `il y a ${Math.floor(s/3600)} h`;
  return `il y a ${Math.floor(s/86400)} j`;
}
function escHtml(str) {
  const d = document.createElement('div');
  d.textContent = str || '';
  return d.innerHTML;
}
function imgUrl(images) {
  if (!images) return '';
  const arr  = Array.isArray(images) ? images : [];
  const pref = ['extralarge','large','medium','small'];
  for (const size of pref) {
    const img = arr.find(i => i.size === size);
    if (img?.['#text'] && !img['#text'].includes(DEFAULT_IMG)) return img['#text'];
  }
  return '';
}

/**
 * Convertit un timestamp Unix (ex: 1617208730) en date lisible.
 * L'API Last.fm renvoie registered['#text'] sous forme d'entier Unix.
 */
function formatRegDate(rawTs) {
  if (!rawTs) return '—';
  const n = parseInt(rawTs, 10);
  if (!n || isNaN(n)) return '—';
  // Valeur > 1e9 → c'est bien un timestamp Unix en secondes
  const d = new Date(n > 1e9 ? n * 1000 : n);
  if (isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('fr-FR', { month: 'short', year: 'numeric' });
}

/* ─── Favorites ─── */
const Favs = {
  _data: null,
  load() {
    if (this._data) return this._data;
    try {
      const raw = localStorage.getItem(LS_FAV_KEY);
      const parsed = raw ? JSON.parse(raw) : {};
      // Validation : doit être un objet plat, sinon réinitialisation
      this._data = (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) ? parsed : {};
    } catch {
      this._data = {};
    }
    return this._data;
  },
  save() { try { localStorage.setItem(LS_FAV_KEY, JSON.stringify(this._data)); } catch {} },
  has(username)  { return !!this.load()[username.toLowerCase()]; },
  add(info) {
    this.load();
    this._data[info.name.toLowerCase()] = { ...info, savedAt: Date.now() };
    this.save();
  },
  remove(username) {
    this.load();
    delete this._data[username.toLowerCase()];
    this.save();
  },
  toggle(info) {
    if (this.has(info.name)) { this.remove(info.name); return false; }
    else { this.add(info); return true; }
  },
  all()   { return Object.values(this.load()).sort((a,b) => b.savedAt - a.savedAt); },
  count() { return Object.keys(this.load()).length; },
};

/* ─── Recent searches ─── */
const Recent = {
  load() {
    try { return JSON.parse(localStorage.getItem(LS_RECENT_KEY) || '[]'); } catch { return []; }
  },
  add(username) {
    const arr = this.load().filter(r => r.username.toLowerCase() !== username.toLowerCase());
    arr.unshift({ username, ts: Date.now() });
    try { localStorage.setItem(LS_RECENT_KEY, JSON.stringify(arr.slice(0, RECENT_MAX))); } catch {}
  },
  remove(username) {
    const arr = this.load().filter(r => r.username.toLowerCase() !== username.toLowerCase());
    try { localStorage.setItem(LS_RECENT_KEY, JSON.stringify(arr)); } catch {}
  },
  clear() { try { localStorage.removeItem(LS_RECENT_KEY); } catch {} },
};
/* ─── Track Seen Tracker (for context badges) ─── */
const TrackSeen = {
  _data: null,
  load() {
    if (this._data) return this._data;
    try { this._data = JSON.parse(localStorage.getItem(LS_TRACK_SEEN_KEY) || '{}'); }
    catch { this._data = {}; }
    return this._data;
  },
  save() { try { localStorage.setItem(LS_TRACK_SEEN_KEY, JSON.stringify(this._data)); } catch {} },
  mark(userKey, trackKey) {
    const d = this.load();
    if (!d[userKey]) d[userKey] = {};
    d[userKey][trackKey] = Date.now();
    // Prune entries older than 2 years to avoid localStorage bloat
    const cutoff = Date.now() - 2 * 365 * 24 * 3600 * 1000;
    for (const uk of Object.keys(d)) {
      for (const tk of Object.keys(d[uk])) { if (d[uk][tk] < cutoff) delete d[uk][tk]; }
      if (!Object.keys(d[uk]).length) delete d[uk];
    }
    this.save();
  },
  lastSeen(userKey, trackKey) { return this.load()[userKey]?.[trackKey] || 0; },
};



/* ─── API calls ─── */
const API = {
  key: '',
  async call(method, params = {}) {
    const url = new URL(LASTFM_URL);
    url.searchParams.set('method',  method);
    url.searchParams.set('api_key', this.key);
    url.searchParams.set('format',  'json');
    Object.entries(params).forEach(([k,v]) => url.searchParams.set(k, String(v)));
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const res  = await fetch(url.toString());
        if (!res.ok) throw new Error(`Erreur réseau HTTP ${res.status}`);
        const data = await res.json();
        // Gestion des erreurs API Last.fm avec messages lisibles
        if (data.error) {
          const errorMessages = {
            2:  'Ce service est temporairement indisponible.',
            4:  'Clé API invalide. Vérifiez vos paramètres.',
            6:  'Paramètre invalide.',
            8:  'Erreur de service temporaire. Réessayez.',
            9:  'Clé API expirée ou suspendue.',
            10: 'Clé API refusée — accès non autorisé.',
            17: 'Connexion requise.',
            26: 'Limite de requêtes dépassée. Patientez.',
            29: 'Limite de requêtes dépassée. Patientez.',
          };
          throw new Error(errorMessages[data.error] || (data.message || `Erreur API Last.fm (code ${data.error})`));
        }
        return data;
      } catch(e) {
        if (attempt === 2) throw e;
        await sleep(800 * (attempt + 1));
      }
    }
  },
  async getFriends(username, page = 1) {
    return this.call('user.getFriends', { user: username, recenttracks: 1, page, limit: 50 });
  },
  async getInfo(username)               { return this.call('user.getInfo',    { user: username }); },
  async getRecentTrack(username, limit = 3) { return this.call('user.getRecentTracks', { user: username, limit }); },
  async getTopArtists(username, period = 'overall', limit = 5) { return this.call('user.getTopArtists', { user: username, period, limit }); },
  async getTopTracks(username, period = 'overall', limit = 5)  { return this.call('user.getTopTracks',  { user: username, period, limit }); },
  async getTopAlbums(username, period = 'overall', limit = 3)  { return this.call('user.getTopAlbums',  { user: username, period, limit }); },
  async getWeeklyArtists(username)  { return this.call('user.getTopArtists',  { user: username, period: '7day', limit: 1 }); },
  async getRecentTracksRange(username, from, to, limit = 10) { return this.call('user.getRecentTracks', { user: username, from, to, limit }); },
  async getTrackInfo(artist, track, username) {
    return this.call('track.getInfo', { artist, track, username, autocorrect: 1 });
  },
  async getArtistInfo(artist, username) {
    return this.call('artist.getInfo', { artist, username, autocorrect: 1 });
  },
};

/* ═══════════════════════════════════════════════
   Main app state
═══════════════════════════════════════════════ */
const FR = window.FR = {
  username: '',
  friends: [],
  liveStatuses: {},
  myStatus: null,
  liveTimer: null,
  currentTab: 'home',
  currentFilter: 'all',
  friendsQuery: '',
  favQuery: '',
  currentSearchUser: null,

  /* ── Color Sync state ── */
  _colorSyncEnabled: false,
  _colorSyncCanvas:  null,
  _colorSyncCtx:     null,
  _colorSyncActive:  false,
  _visibilityBound:  false,

  /* ── Push notification state ── */
  _pushEnabled: false,
  _lastNotified: {},
  _lastLiveTracks: {},   // { friendLcName: 'artist|track' } — detects track changes for badge refresh

  /* ── Boot ── */
  async init() {
    const apiKey = localStorage.getItem(LS_APIKEY) || '';
    const user   = localStorage.getItem(LS_USERNAME) || '';
    const theme  = localStorage.getItem(LS_THEME)  || 'dark';
    const accent = localStorage.getItem(LS_ACCENT) || 'purple';
    document.documentElement.setAttribute('data-theme',  theme);
    document.documentElement.setAttribute('data-accent', accent);

    if (!apiKey || !user) { this.showSetup(); return; }

    API.key       = apiKey;
    this.username = user;

    this._colorSyncEnabled = localStorage.getItem(LS_COLOR_SYNC) === '1';
    this._pushEnabled = localStorage.getItem(LS_PUSH) === '1' && Notification?.permission === 'granted';

    this.showApp();
    this.bindEvents();
    this.renderRecentSearches();
    this.updateFavBadge();
    this.renderFavorites();
    this.renderSettingsState();
    this.renderHomeTab();
    this._loadSidebarProfile();
    await this.loadFriends();
  },

  showSetup() {
    this.stopLivePolling(); // Stopper le polling avant de quitter l'app
    $('#setup-screen').classList.remove('hidden');
    $('#app-shell').classList.add('hidden');
  },
  showApp()   { $('#setup-screen').classList.add('hidden');    $('#app-shell').classList.remove('hidden'); },

  async _loadSidebarProfile() {
    try {
      const data = await API.getInfo(this.username);
      const u    = data.user;
      const av   = imgUrl(u.image);
      $('#sb-username').textContent  = u.name || this.username;
      $('#sb-scrobbles').textContent = fmt(u.playcount) + ' scrobbles';
      $('#settings-username-display').textContent = u.name || this.username;
      const apiKey = localStorage.getItem(LS_APIKEY) || '';
      const masked = apiKey.length > 8 ? apiKey.slice(0,4) + '••••' + apiKey.slice(-4) : '••••••••';
      const settingsKeyEl = $('#settings-apikey-display');
      if (settingsKeyEl) settingsKeyEl.textContent = masked;
      const sbAv = $('#sb-av');
      const sbFb = $('#sb-av-fallback');
      if (av) {
        sbAv.src = av; sbAv.style.display = 'block';
        if (sbFb) sbFb.style.zIndex = '0';
      } else {
        sbAv.style.display = 'none';
        if (sbFb) sbFb.textContent = (u.name || '?').charAt(0).toUpperCase();
      }
    } catch {
      $('#sb-username').textContent = this.username;
      $('#settings-username-display').textContent = this.username;
    }
  },

  openSidebar()  {
    const burger = $('#btn-burger');
    if (burger) { burger.setAttribute('aria-expanded', 'true'); }
    $('#fr-sidebar').classList.add('open'); $('#fr-sidebar-ov').classList.add('open'); document.body.style.overflow = 'hidden';
  },
  closeSidebar() {
    const burger = $('#btn-burger');
    if (burger) { burger.setAttribute('aria-expanded', 'false'); }
    $('#fr-sidebar').classList.remove('open'); $('#fr-sidebar-ov').classList.remove('open'); document.body.style.overflow = '';
  },

  /* ── Events ── */
  bindEvents() {
    $('#btn-burger')?.addEventListener('click', () => this.openSidebar());
    $('#btn-sb-close')?.addEventListener('click', () => this.closeSidebar());
    $('#fr-sidebar-ov')?.addEventListener('click', () => this.closeSidebar());

    $$('.fr-nav-lnk').forEach(btn => btn.addEventListener('click', () => { this.switchTab(btn.dataset.tab); this.closeSidebar(); }));
    $$('.fr-bn-item').forEach(btn => btn.addEventListener('click', () => this.switchTab(btn.dataset.tab)));

    // Friends filter
    const fsInput = $('#friends-search');
    fsInput?.addEventListener('input', () => {
      this.friendsQuery = fsInput.value.toLowerCase().trim();
      $('#friends-search-clear')?.classList.toggle('hidden', !fsInput.value);
      this.renderFriendsGrid();
    });
    $('#friends-search-clear')?.addEventListener('click', () => {
      fsInput.value = ''; this.friendsQuery = '';
      $('#friends-search-clear').classList.add('hidden');
      this.renderFriendsGrid();
    });
    $$('.fr-filter-chips .fr-chip').forEach(chip => chip.addEventListener('click', () => {
      $$('.fr-filter-chips .fr-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      this.currentFilter = chip.dataset.filter;
      this.renderFriendsGrid();
    }));

    // Refresh
    $('#btn-refresh')?.addEventListener('click', async () => {
      const btn = $('#btn-refresh'); btn.classList.add('spinning');
      await this.refreshLiveStatuses();
      await sleep(400); btn.classList.remove('spinning');
    });

    // Search tab
    const searchIn  = $('#search-username');
    const searchBtn = $('#search-btn');
    const clearBtn  = $('#search-big-clear');
    const triggerSearch = () => { const val = searchIn?.value.trim(); if (val) this.doSearch(val); };
    searchIn?.addEventListener('input', () => clearBtn?.classList.toggle('hidden', !searchIn.value.trim()));
    searchIn?.addEventListener('keydown', e => { if (e.key === 'Enter') triggerSearch(); });
    searchBtn?.addEventListener('click', triggerSearch);
    clearBtn?.addEventListener('click', () => {
      if (searchIn) searchIn.value = '';
      clearBtn.classList.add('hidden');
      this.currentSearchUser = null;
      this.resetSearchUI();
    });
    $('#clear-recent-btn')?.addEventListener('click', () => { Recent.clear(); this.renderRecentSearches(); });

    // Favorites search
    const favIn = $('#fav-search');
    favIn?.addEventListener('input', () => { this.favQuery = favIn.value.toLowerCase().trim(); this.renderFavorites(); });

    // Modal close
    const overlay = $('#profile-modal-overlay');
    overlay?.addEventListener('click', e => { if (e.target === overlay) this.closeModal(); });
    $('#profile-modal-close')?.addEventListener('click', () => this.closeModal());
    document.addEventListener('keydown', e => {
      if (e.key === 'Escape') {
        if ($('#top5-overlay') && !$('#top5-overlay').classList.contains('hidden')) this.closeTop5();
        else if (overlay?.classList.contains('open')) this.closeModal();
      }
    });

    // Settings: theme buttons
    $$('[data-theme-val]').forEach(btn => btn.addEventListener('click', () => {
      const t = btn.dataset.themeVal;
      localStorage.setItem(LS_THEME, t);
      document.documentElement.setAttribute('data-theme', t);
      this.renderSettingsState();
      $$('.fr-sb-th-btn').forEach(b => b.classList.toggle('active', b.dataset.themeVal === t));
    }));

    // Settings: accent swatches
    $$('[data-accent]').forEach(btn => btn.addEventListener('click', () => {
      const a = btn.dataset.accent;
      localStorage.setItem(LS_ACCENT, a);
      if (this._colorSyncActive) this._resetColorSync();
      document.documentElement.setAttribute('data-accent', a);
      this.renderSettingsState();
    }));

    // Color Sync toggle
    const colorSyncToggle = $('#color-sync-toggle');
    if (colorSyncToggle) {
      colorSyncToggle.checked = this._colorSyncEnabled;
      colorSyncToggle.addEventListener('change', () => {
        this._colorSyncEnabled = colorSyncToggle.checked;
        localStorage.setItem(LS_COLOR_SYNC, this._colorSyncEnabled ? '1' : '0');
        if (!this._colorSyncEnabled && this._colorSyncActive) {
          this._resetColorSync();
        } else if (this._colorSyncEnabled) {
          const status = this.liveStatuses[this.username.toLowerCase()];
          if (status?.art) this._applyColorSync(status.art);
        }
        this.showToast(this._colorSyncEnabled ? '🎨 Color Sync activé' : 'Color Sync désactivé', this._colorSyncEnabled ? 'success' : '');
      });
    }

    // Push notifications
    $('#btn-enable-push')?.addEventListener('click', () => this.setupPushNotifications());

    // Top 5 modal
    $('#home-top5-btn')?.addEventListener('click', () => this.showTop5());
    $('#top5-close')?.addEventListener('click', () => this.closeTop5());
    $('#top5-overlay')?.addEventListener('click', e => { if (e.target === $('#top5-overlay')) this.closeTop5(); });
  },

  /* ── Tab switching ── */
  switchTab(name) {
    this.currentTab = name;
    $$('.fr-nav-lnk').forEach(t => {
      t.classList.toggle('active', t.dataset.tab === name);
      t.setAttribute('aria-selected', t.dataset.tab === name ? 'true' : 'false');
    });
    $$('.fr-bn-item').forEach(t => {
      t.classList.toggle('active', t.dataset.tab === name);
      t.setAttribute('aria-selected', t.dataset.tab === name ? 'true' : 'false');
    });
    $$('.tab-content').forEach(s => s.classList.toggle('active', s.id === `tab-content-${name}`));
    const labels = { home:'Accueil', friends:'Amis', search:'Recherche', favorites:'Favoris', settings:'Paramètres' };
    const labelEl = $('#hd-tab-label');
    if (labelEl) labelEl.textContent = labels[name] || '';
    if (name === 'favorites') this.renderFavorites();
    if (name === 'settings')  this.renderSettingsState();
    if (name === 'home')      this.renderHomeTab();
  },

  /* ═══════════════════════════════════════
     SETTINGS
  ═══════════════════════════════════════ */
  renderSettingsState() {
    const theme  = localStorage.getItem(LS_THEME)  || 'dark';
    const accent = localStorage.getItem(LS_ACCENT) || 'purple';
    $$('[data-theme-val]').forEach(btn => btn.classList.toggle('active', btn.dataset.themeVal === theme));
    $$('.fr-sb-th-btn').forEach(btn  => btn.classList.toggle('active', btn.dataset.themeVal === theme));
    $$('[data-accent]').forEach(btn  => btn.classList.toggle('active', btn.dataset.accent === accent));
    // Color sync toggle
    const cst = $('#color-sync-toggle');
    if (cst) cst.checked = this._colorSyncEnabled;
    // Push button state
    const pushBtn   = $('#btn-enable-push');
    const pushLabel = $('#push-btn-label');
    const pushIcon  = $('#push-btn-icon');
    if (pushBtn && pushLabel && pushIcon) {
      const granted = this._pushEnabled && Notification?.permission === 'granted';
      pushBtn.classList.toggle('active', granted);
      pushLabel.textContent = granted ? 'Activées ✓' : 'Activer';
      pushIcon.className = granted ? 'fas fa-bell' : 'fas fa-bell-slash';
    }
  },

  /* ═══════════════════════════════════════
     FRIENDS — load & render
  ═══════════════════════════════════════ */
  async loadFriends() {
    const grid = $('#friends-grid');
    if (grid) grid.innerHTML = this._buildSkeletons(6);
    this._hideAllEmpties('friends');
    try {
      const all = await this._fetchAllFriends();
      this.friends = all;
      this._updateStatStrip();
      this.renderFriendsGrid();
      this.renderHomeTab();
      this.startLivePolling();
    } catch (e) {
      if (grid) grid.innerHTML = '';
      this._showEmpty('friends-error');
      const errMsg = $('#friends-error-msg');
      if (errMsg) errMsg.textContent = e.message || 'Erreur lors du chargement des amis.';
    }
  },

  async _fetchAllFriends() {
    const allFriends = [];
    let page = 1, totalPages = 1;
    do {
      const data     = await API.getFriends(this.username, page);
      const attr     = data.friends?.['@attr'] || {};
      totalPages     = parseInt(attr.totalPages || 1);
      const list     = data.friends?.user || [];
      const arr      = Array.isArray(list) ? list : [list];
      allFriends.push(...arr);
      page++;
    } while (page <= totalPages && allFriends.length < MAX_FRIENDS);

    return allFriends.map(u => ({
      name:        u.name || '',
      realname:    u.realname || '',
      country:     u.country || '',
      playcount:   parseInt(u.playcount || 0),
      registered:  u.registered?.['#text'] || '',
      image:       imgUrl(u.image),
      subscriber:  u.subscriber === '1',
      recentTrack: u.recenttrack || null,
    }));
  },

  renderFriendsGrid() {
    const grid = $('#friends-grid');
    if (!grid) return;
    const list = this._filteredFriends();
    this._hideAllEmpties('friends');

    if (this.friends.length === 0) { grid.innerHTML = ''; this._showEmpty('friends-empty-none'); return; }
    if (list.length === 0)         { grid.innerHTML = ''; this._showEmpty('friends-empty-filter'); return; }

    const { coincidences } = this._computeGroupStats();

    grid.innerHTML = list.map((f, i) => this._buildFriendCard(f, i, coincidences)).join('');

    list.forEach(f => {
      const card = $(`[data-username="${f.name}"]`, grid);
      if (!card) return;
      $('[data-action="fav"]',  card)?.addEventListener('click', e => { e.stopPropagation(); this.toggleFav(f, card); });
      $('[data-action="view"]', card)?.addEventListener('click', e => { e.stopPropagation(); this.openProfileModal(f.name); });
      card.addEventListener('click', () => this.openProfileModal(f.name));
    });

    this.renderActivityFeed();
    this.renderDiscoveryWall().catch(() => {});
  },

  _filteredFriends() {
    return this.friends.filter(f => {
      const q = this.friendsQuery;
      if (q && !f.name.toLowerCase().includes(q) && !f.realname.toLowerCase().includes(q)) return false;
      if (this.currentFilter === 'live') return !!this.liveStatuses[f.name.toLowerCase()]?.nowPlaying;
      if (this.currentFilter === 'fav')  return Favs.has(f.name);
      return true;
    });
  },

  _buildFriendCard(f, delay = 0, coincidences = new Set()) {
    const live   = this.liveStatuses[f.name.toLowerCase()];
    const isLive = live?.nowPlaying;
    const isFav  = Favs.has(f.name);
    const av     = f.image || '';
    const avHtml = av
      ? `<img class="fr-av" src="${escHtml(av)}" alt="${escHtml(f.name)}" loading="lazy"
             onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
      : '';
    const avFallback = `<div class="fr-av" style="background:${this._nameColor(f.name)};display:${av?'none':'flex'};align-items:center;justify-content:center;color:#fff;font-size:1.1rem;font-weight:800;">${escHtml(f.name.charAt(0).toUpperCase())}</div>`;

    // ── Activity Aura Badges ─────────────────────────────
    const todayScrob = live?.todayScrobbles ?? 0;
    const daysSince  = live?.daysSinceLastScrobble ?? 0;
    const isFlame    = todayScrob > 50;
    const isMoon     = !isLive && daysSince > 3 && daysSince < 9999;
    const auraHtml   = (isFlame || isMoon)
      ? `<div class="fr-aura-wrap">${isFlame ? '<span class="fr-aura-badge fr-aura-flame" title="' + todayScrob + ' scrobbles aujourd\'hui">🔥</span>' : ''}${isMoon ? '<span class="fr-aura-badge fr-aura-moon" title="Absent depuis ' + Math.floor(daysSince) + ' jours">🌙</span>' : ''}</div>`
      : '';

    // Musical coincidence: same artist as another friend
    const isSameArtist = isLive && live?.artist && coincidences.has(live.artist.toLowerCase());

    let npHtml = '';
    if (isLive) {
      const spQuery = encodeURIComponent(`${live.artist} ${live.track}`);
      const ytQuery = encodeURIComponent(`${live.artist} ${live.track}`);
      // La pochette d'album : image OU fallback (jamais les deux visibles en même temps)
      const artBlock = live.art
        ? `<img class="fr-np-art" src="${escHtml(live.art)}" alt="${escHtml(live.album||live.track)}" loading="lazy"
               onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
           <div class="fr-np-art np-art-fallback" style="display:none;background:${this._nameColor(live.artist||'')}">${(live.artist||'?').charAt(0)}</div>`
        : `<div class="fr-np-art np-art-fallback" style="display:flex;background:${this._nameColor(live.artist||'')}">${(live.artist||'?').charAt(0)}</div>`;

      npHtml = `
        <div class="fr-np-bar">
          ${artBlock}
          <div class="fr-np-info">
            <div class="fr-np-track">${escHtml(live.track)}</div>
            <div class="fr-np-artist">${escHtml(live.artist)}${live.album ? ` · <em style="opacity:.7">${escHtml(live.album)}</em>` : ''}</div>
            ${(live.myPlayCount > 0) ? `<div class="fr-my-play-badge"><i class="fas fa-headphones"></i> Déjà écouté ${live.myPlayCount}×</div>` : ''}
          </div>
          <div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px;flex-shrink:0">
            <div class="fr-np-icon"><span></span><span></span><span></span><span></span></div>
            <div style="display:flex;gap:4px;margin-top:2px">
              <a class="fr-np-play-btn" href="https://open.spotify.com/search/${spQuery}" target="_blank" rel="noopener"
                 onclick="event.stopPropagation()" title="Écouter sur Spotify"><i class="fab fa-spotify"></i></a>
              <a class="fr-np-play-btn yt" href="https://music.youtube.com/search?q=${ytQuery}" target="_blank" rel="noopener"
                 onclick="event.stopPropagation()" title="Écouter sur YouTube Music"><i class="fab fa-youtube"></i></a>
            </div>
          </div>
        </div>`;
    } else if (live?.track) {
      // Dernier morceau écouté — même logique sans doublon
      const lastArtBlock = live.art
        ? `<img class="fr-last-art" src="${escHtml(live.art)}" alt="${escHtml(live.track)}" loading="lazy"
               onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
           <div class="fr-last-art np-art-fallback sm" style="display:none;background:${this._nameColor(live.artist||'')}">${(live.artist||'?').charAt(0)}</div>`
        : `<div class="fr-last-art np-art-fallback sm" style="display:flex;background:${this._nameColor(live.artist||'')}">${(live.artist||'?').charAt(0)}</div>`;

      npHtml = `
        <div class="fr-last-played">
          ${lastArtBlock}
          <div class="fr-last-info">
            <div class="fr-last-track">${escHtml(live.track)}</div>
            <div class="fr-last-artist">${escHtml(live.artist)}</div>
          </div>
          <span class="fr-last-when">${live.ts ? timeAgo(live.ts) : ''}</span>
        </div>`;
    }

    return `
      <div class="fr-card${isLive?' is-live':''}${isSameArtist?' same-artist-glow':''}"
           data-username="${escHtml(f.name)}" style="animation-delay:${delay*40}ms"
           role="button" tabindex="0" aria-label="Voir le profil de ${escHtml(f.name)}">
        <div class="fr-card-header">
          <div class="fr-av-wrap">
            ${avHtml}${avFallback}
            ${isLive ? '<div class="fr-av-dot np-pulse"></div>' : ''}
          ${auraHtml}
          </div>
          <div class="fr-card-info">
            <div class="fr-card-name">
              ${escHtml(f.name)}
              ${f.subscriber ? '<i class="fas fa-crown" style="color:#f59e0b;font-size:.65rem;margin-left:5px" title="Subscriber"></i>' : ''}
              ${isSameArtist ? '<span class="fr-coincidence-badge" title="Coïncidence musicale !">🎵</span>' : ''}
            </div>
            <div class="fr-card-meta">
              ${f.country ? `<span class="fr-card-country"><i class="fas fa-map-marker-alt"></i>${escHtml(f.country)}</span>` : ''}
              <span class="fr-card-scrobbles"><i class="fas fa-music"></i>${fmt(f.playcount)}</span>
            </div>
            ${f.realname ? `<div class="fr-card-registered" style="font-size:.73rem;color:var(--text-dim)">${escHtml(f.realname)}</div>` : ''}
          </div>
          <div class="fr-card-actions">
            <button class="fr-action-btn${isFav?' fav-active':''}" data-action="fav"
                    title="${isFav?'Retirer des favoris':'Ajouter aux favoris'}">
              <i class="fa${isFav?'s':'r'} fa-star"></i>
            </button>
            <button class="fr-action-btn" data-action="view" title="Voir le profil">
              <i class="fas fa-user-circle"></i>
            </button>
          </div>
        </div>
        ${npHtml}
      </div>`;
  },

  /* ════════════════════════════════════════
     MON STATUT — my own now playing
  ════════════════════════════════════════ */
  renderMyStatus() {
    const sections = ['#my-status-section', '#home-my-status-section'];
    const status = this.liveStatuses[this.username.toLowerCase()];

    if (!status?.nowPlaying || !status.track) {
      sections.forEach(sel => {
        const s = $(sel);
        if (s) { s.classList.add('hidden'); s.innerHTML = ''; }
      });
      if (this._colorSyncActive) this._resetColorSync();
      return;
    }

    const artHtml = status.art
      ? `<img class="my-status-art" src="${escHtml(status.art)}" alt="${escHtml(status.track)}"
             loading="lazy" id="my-status-art-img" crossorigin="anonymous"
             onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
      : '';
    const artFallback = `<div class="my-status-art-fallback" style="background:${this._nameColor(status.artist||'')};display:${status.art?'none':'flex'}">${(status.artist||'?').charAt(0)}</div>`;

    const html = `
      <div class="my-status-card">
        <span class="my-status-label">Mon statut</span>
        ${artHtml}${artFallback}
        <div class="my-status-info">
          <div class="my-status-meta">
            <span class="live-dot sm"></span>
            <span class="my-status-name">${escHtml(this.username)}</span>
          </div>
          <div class="my-status-track">${escHtml(status.track)}</div>
          <div class="my-status-artist">${escHtml(status.artist)}${status.album ? ` · ${escHtml(status.album)}` : ''}</div>
        </div>
        <div class="my-status-icon"><span></span><span></span><span></span><span></span></div>
      </div>`;

    sections.forEach(sel => {
      const s = $(sel);
      if (s) { s.innerHTML = html; s.classList.remove('hidden'); }
    });

    // Color Sync — extract accent from album art
    if (this._colorSyncEnabled && status.art) {
      this._applyColorSync(status.art);
    }
  },

  /* ════════════════════════════════════════
     COLOR SYNC
  ════════════════════════════════════════ */
  _applyColorSync(imgSrc) {
    if (!imgSrc) return;

    // Tentative avec crossOrigin=anonymous (nécessaire pour canvas getImageData)
    const tryExtract = (src, withCors) => {
      return new Promise((resolve, reject) => {
        const img = new Image();
        if (withCors) img.crossOrigin = 'anonymous';
        img.onload = () => resolve(img);
        img.onerror = () => reject(new Error('img load error'));
        img.src = src + (withCors ? '' : '');
      });
    };

    const extract = async () => {
      let img;
      try {
        img = await tryExtract(imgSrc, true);
      } catch {
        // CORS refusé : on ne peut pas extraire la couleur
        return;
      }

      try {
        if (!this._colorSyncCanvas) {
          this._colorSyncCanvas = document.createElement('canvas');
          this._colorSyncCtx    = this._colorSyncCanvas.getContext('2d');
        }
        const canvas = this._colorSyncCanvas;
        const ctx    = this._colorSyncCtx;
        canvas.width = 32; canvas.height = 32;
        ctx.drawImage(img, 0, 0, 32, 32);

        // Peut lancer SecurityError si canvas taint malgré crossOrigin
        const data = ctx.getImageData(0, 0, 32, 32).data;

        // Collecter les pixels saturés (ignorer les quasi-gris)
        const samples = [];
        for (let i = 0; i < data.length; i += 4) {
          const pr = data[i], pg = data[i+1], pb = data[i+2], pa = data[i+3];
          if (pa < 128) continue;
          const max = Math.max(pr,pg,pb), min = Math.min(pr,pg,pb);
          const sat = max > 0 ? (max - min) / max : 0;
          if (sat > 0.20 && max > 35 && max < 235) samples.push([pr, pg, pb]);
        }
        if (samples.length < 6) return; // Image trop terne → pas de color sync

        // Moyenne des pixels colorés
        let r = 0, g = 0, b = 0;
        samples.forEach(([pr,pg,pb]) => { r += pr; g += pg; b += pb; });
        r = Math.round(r / samples.length);
        g = Math.round(g / samples.length);
        b = Math.round(b / samples.length);

        // Légère saturation supplémentaire
        const max = Math.max(r,g,b), min = Math.min(r,g,b);
        if (max !== min) {
          const sat   = (max - min) / max;
          const boost = Math.min(1.7, 1 / sat * 0.85);
          const mid   = (max + min) / 2;
          r = Math.max(0, Math.min(255, Math.round(mid + (r - mid) * boost)));
          g = Math.max(0, Math.min(255, Math.round(mid + (g - mid) * boost)));
          b = Math.max(0, Math.min(255, Math.round(mid + (b - mid) * boost)));
        }

        const hex     = '#' + [r,g,b].map(v => v.toString(16).padStart(2,'0')).join('');
        const hexLt   = `rgba(${r},${g},${b},0.14)`;
        const hexCont = `rgba(${r},${g},${b},0.22)`;
        const hexGlow = `rgba(${r},${g},${b},0.45)`;
        const el = document.documentElement;
        el.style.setProperty('--accent',           hex);
        el.style.setProperty('--accent-h',         hex);
        el.style.setProperty('--accent-2',         hex);
        el.style.setProperty('--accent-lt',        hexLt);
        el.style.setProperty('--accent-container', hexCont);
        el.style.setProperty('--border-glow',      hexGlow);
        const brightness = (r*299 + g*587 + b*114) / 1000;
        el.style.setProperty('--accent-on',        brightness > 145 ? '#000' : '#fff');
        el.style.setProperty('--accent-on-cont',   brightness > 145 ? '#000' : '#fff');
        document.documentElement.classList.add('color-sync-active');
        this._colorSyncActive = true;
      } catch (secErr) {
        // Canvas taint (SecurityError) malgré crossOrigin → CDN ne supporte pas CORS
        // On passe silencieusement sans afficher d'erreur
      }
    };

    extract().catch(() => {});
  },

  _resetColorSync() {
    if (!this._colorSyncActive) return;
    ['--accent','--accent-h','--accent-2','--accent-lt','--accent-container','--border-glow','--accent-on','--accent-on-cont'].forEach(v =>
      document.documentElement.style.removeProperty(v)
    );
    document.documentElement.classList.remove('color-sync-active');
    this._colorSyncActive = false;
  },

  /* ════════════════════════════════════════
     GROUP STATS — coincidences + trending
  ════════════════════════════════════════ */
  _computeGroupStats() {
    const artistCount = {};
    for (const [lcName, status] of Object.entries(this.liveStatuses)) {
      if (lcName === this.username.toLowerCase()) continue;
      if (status.nowPlaying && status.artist) {
        const key = status.artist.toLowerCase();
        if (!artistCount[key]) artistCount[key] = { name: status.artist, count: 0, users: [] };
        artistCount[key].count++;
        artistCount[key].users.push(lcName);
      }
    }
    let topArtist = null, topCount = 0;
    for (const data of Object.values(artistCount)) {
      if (data.count > topCount) { topCount = data.count; topArtist = data; }
    }
    // Artists shared by 2+ friends simultaneously
    const coincidences = new Set(
      Object.entries(artistCount).filter(([,d]) => d.count >= 2).map(([k]) => k)
    );
    return { topArtist, coincidences };
  },

  /* ════════════════════════════════════════
     ACCUEIL TAB
  ════════════════════════════════════════ */
  renderHomeTab() {
    // Stats counters
    const total = this.friends.length;
    const live  = this.friends.filter(f => this.liveStatuses[f.name.toLowerCase()]?.nowPlaying).length;
    const fav   = Favs.count();
    const totalEl = $('#home-total-count'); if (totalEl) totalEl.textContent = total || '—';
    const liveEl  = $('#home-live-count');  if (liveEl)  liveEl.textContent  = live  || '0';
    const favEl   = $('#home-fav-count');   if (favEl)   favEl.textContent   = fav   || '0';

    // Trending strip
    const { topArtist } = this._computeGroupStats();
    const trendEl = $('#home-trending-text');
    if (trendEl) {
      if (topArtist && topArtist.count >= 1) {
        const plural = topArtist.count > 1
          ? `${topArtist.count} amis écoutent`
          : '1 ami écoute';
        trendEl.textContent = `L'artiste le + écouté : ${topArtist.name} (${plural} en ce moment)`;
      } else if (total > 0) {
        trendEl.textContent = 'Aucun ami en écoute pour l\'instant.';
      } else {
        trendEl.textContent = 'Chargement des statistiques de groupe…';
      }
    }

    // Quick contacts (favorites only)
    const quickRow   = $('#home-quick-row');
    const quickEmpty = $('#home-quick-empty');
    if (quickRow) {
      const favs = Favs.all().slice(0, 12);
      if (!favs.length) {
        quickRow.innerHTML = '';
        if (quickEmpty) quickEmpty.classList.remove('hidden');
      } else {
        if (quickEmpty) quickEmpty.classList.add('hidden');
        quickRow.innerHTML = favs.map((f, i) => {
          const isLive = !!this.liveStatuses[f.name.toLowerCase()]?.nowPlaying;
          const av = f.image || '';
          return `
            <div class="fr-home-quick-card${isLive?' is-live':''}" data-username="${escHtml(f.name)}"
                 style="animation-delay:${i*30}ms" role="button" tabindex="0" title="${escHtml(f.name)}">
              <div class="fr-home-quick-av-wrap">
                ${av ? `<img class="fr-home-quick-av" src="${escHtml(av)}" alt="${escHtml(f.name)}" loading="lazy"
                             onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
                <div class="fr-home-quick-av-fallback" style="background:${this._nameColor(f.name)};${av?'display:none;':''}">${f.name.charAt(0).toUpperCase()}</div>
                ${isLive ? '<div class="fr-home-quick-live-dot"></div>' : ''}
              </div>
              <div class="fr-home-quick-name">${escHtml(f.name)}</div>
            </div>`;
        }).join('');
        $$('.fr-home-quick-card', quickRow).forEach(card => {
          card.addEventListener('click', () => this.openProfileModal(card.dataset.username));
        });
      }
    }

    // Mini activity feed (top 6)
    const feedList  = $('#home-feed-list');
    const feedEmpty = $('#home-feed-empty');
    const livePill  = $('#home-live-pill');
    if (feedList) {
      const allItems = [];
      for (const [lcName, status] of Object.entries(this.liveStatuses)) {
        if (lcName === this.username.toLowerCase()) continue;
        const friend    = this.friends.find(f => f.name.toLowerCase() === lcName) || Favs.all().find(f => f.name.toLowerCase() === lcName);
        const username  = friend?.name || lcName;
        const userImage = status.userImage || friend?.image || '';
        if (status.nowPlaying && status.track) {
          allItems.push({ username, userImage, track: status.track, artist: status.artist, album: status.album||'', art: status.art, nowPlaying: true, ts: Math.floor(Date.now()/1000), myPlayCount: status.myPlayCount || 0 });
        }
        if (Array.isArray(status.recentTracks)) {
          for (const rt of status.recentTracks) {
            if (!rt.ts || rt.ts <= 0) continue;
            allItems.push({ ...rt, username, userImage });
          }
        }
      }
      allItems.sort((a,b) => { if (a.nowPlaying && !b.nowPlaying) return -1; if (!a.nowPlaying && b.nowPlaying) return 1; return (b.ts||0)-(a.ts||0); });
      const seen = new Set();
      const unique = allItems.filter(item => {
        const k = `${item.username.toLowerCase()}|${item.track.toLowerCase()}`;
        if (seen.has(k)) return false; seen.add(k); return true;
      });
      const top = unique.slice(0, 6);
      if (!top.length) {
        feedList.innerHTML = '';
        if (feedEmpty) feedEmpty.classList.remove('hidden');
        if (livePill)  livePill.classList.add('hidden');
      } else {
        if (feedEmpty) feedEmpty.classList.add('hidden');
        if (livePill)  livePill.classList.toggle('hidden', !top.some(t => t.nowPlaying));
        feedList.innerHTML = top.map((item, i) => this._buildFeedItem(item, i)).join('');
        $$('.fr-feed-item', feedList).forEach(el => el.addEventListener('click', () => {
          const u = el.dataset.username; if (u) this.openProfileModal(u);
        }));
      }
    }

    // Mirror my-status in home tab
    const homeStatus = $('#home-my-status-section');
    const mainStatus = $('#my-status-section');
    if (homeStatus && mainStatus) {
      homeStatus.innerHTML = mainStatus.innerHTML;
      homeStatus.classList.toggle('hidden', mainStatus.classList.contains('hidden'));
    }

    // New sections: Coïncidences, Discovery, Flashback
    this._renderHomeCoincidences();
    this.renderHomeDiscovery();
    // Flashback is async — call without await to avoid blocking
    this.renderHomeFlashback().catch(() => {});
  },

  /* ════════════════════════════════════════
     ACTIVITY FEED (friends tab)
  ════════════════════════════════════════ */
  renderActivityFeed() {
    const section  = $('#friends-feed-section');
    const feedList = $('#friends-feed-list');
    if (!section || !feedList) return;

    const allItems = [];

    for (const [lcName, status] of Object.entries(this.liveStatuses)) {
      if (lcName === this.username.toLowerCase()) continue;
      const friend    = this.friends.find(f => f.name.toLowerCase() === lcName) || Favs.all().find(f => f.name.toLowerCase() === lcName);
      const username  = friend?.name || lcName;
      const userImage = status.userImage || friend?.image || '';

      if (status.nowPlaying && status.track) {
        allItems.push({ username, userImage, track: status.track, artist: status.artist, album: status.album||'', art: status.art, nowPlaying: true, ts: Math.floor(Date.now()/1000), myPlayCount: status.myPlayCount || 0 });
      }
      if (Array.isArray(status.recentTracks)) {
        for (const rt of status.recentTracks) {
          if (!rt.ts || rt.ts <= 0) continue;
          allItems.push({ ...rt, username, userImage });
        }
      }
    }

    if (!allItems.length) { section.classList.add('hidden'); return; }

    allItems.sort((a,b) => { if (a.nowPlaying && !b.nowPlaying) return -1; if (!a.nowPlaying && b.nowPlaying) return 1; return (b.ts||0)-(a.ts||0); });

    const seen   = new Set();
    const unique = allItems.filter(item => {
      const key = `${item.username.toLowerCase()}|${item.track.toLowerCase()}`;
      if (seen.has(key)) return false; seen.add(key); return true;
    });

    const top = unique.slice(0, 10);
    section.classList.remove('hidden');
    feedList.innerHTML = top.map((item, i) => this._buildFeedItem(item, i)).join('');

    $$('.fr-feed-item', feedList).forEach(el => {
      el.addEventListener('click', () => { const u = el.dataset.username; if (u) this.openProfileModal(u); });
    });
  },

  _buildFeedItem(item, delay = 0) {
    // Context badge computation
    const ONE_YEAR  = 365 * 24 * 3600 * 1000;
    const ONE_MONTH =  30 * 24 * 3600 * 1000;
    const trackKey  = `${(item.artist||'').toLowerCase()}|${(item.track||'').toLowerCase()}`;
    const userKey   = item.username.toLowerCase();
    const lastSeen  = TrackSeen.lastSeen(userKey, trackKey);
    const nowMs     = Date.now();
    let badgeHtml   = '';
    if (!item.nowPlaying) {
      if (lastSeen && (nowMs - lastSeen) > ONE_YEAR) {
        badgeHtml = `<span class="fr-ctx-badge fr-badge-archive" title="Non écouté depuis plus d'un an">📦 Archive</span>`;
      } else if (!lastSeen && item.ts && (nowMs / 1000 - item.ts) < (30 * 86400)) {
        badgeHtml = `<span class="fr-ctx-badge fr-badge-new" title="Piste récemment écoutée">✨ Nouveauté</span>`;
      }
    }
    TrackSeen.mark(userKey, trackKey);

    const userAvHtml = item.userImage
      ? `<img class="fr-feed-user-av" src="${escHtml(item.userImage)}" alt="${escHtml(item.username)}"
             loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
      : '';
    const userAvFallback = `<div class="fr-feed-user-av" style="background:${this._nameColor(item.username)};display:${item.userImage?'none':'flex'};align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.75rem;">${item.username.charAt(0).toUpperCase()}</div>`;

    // Image de la pochette OU fallback coloré — jamais les deux visibles
    const artBlock = item.art
      ? `<img class="fr-feed-art" src="${escHtml(item.art)}" alt="${escHtml(item.track)}"
             loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
         <div class="fr-feed-art np-art-fallback" style="display:none;background:${this._nameColor(item.artist||'')}">${(item.artist||'?').charAt(0)}</div>`
      : `<div class="fr-feed-art np-art-fallback" style="display:flex;background:${this._nameColor(item.artist||'')}">${(item.artist||'?').charAt(0)}</div>`;

    const timeHtml = item.nowPlaying
      ? `<span class="fr-feed-now"><span class="live-dot sm"></span>En écoute</span>`
      : `<span class="fr-feed-time">${item.ts ? timeAgo(item.ts) : ''}</span>`;

    const playHtml = item.nowPlaying ? (() => {
      const spQ = encodeURIComponent(`${item.artist} ${item.track}`);
      const ytQ = encodeURIComponent(`${item.artist} ${item.track}`);
      return `
        <div class="fr-feed-play-row" onclick="event.stopPropagation()">
          <a class="fr-np-play-btn" href="https://open.spotify.com/search/${spQ}" target="_blank" rel="noopener" title="Spotify"><i class="fab fa-spotify"></i></a>
          <a class="fr-np-play-btn yt" href="https://music.youtube.com/search?q=${ytQ}" target="_blank" rel="noopener" title="YouTube Music"><i class="fab fa-youtube"></i></a>
        </div>`;
    })() : '';

    return `
      <div class="fr-feed-item${item.nowPlaying?' is-live':''}" data-username="${escHtml(item.username)}"
           style="animation-delay:${delay*30}ms" role="button" tabindex="0">
        <div class="fr-feed-art-wrap">
          ${artBlock}
          ${item.nowPlaying ? '<div class="fr-feed-np-overlay"><div class="fr-np-icon sm"><span></span><span></span><span></span></div></div>' : ''}
        </div>
        <div class="fr-feed-body">
          <div class="fr-feed-track">${escHtml(item.track)}${badgeHtml}${(item.nowPlaying && (item.myPlayCount||0) > 0) ? '<span class="fr-my-play-badge sm"><i class="fas fa-headphones"></i> ' + item.myPlayCount + '×</span>' : ''}</div>
          <div class="fr-feed-artist">${escHtml(item.artist||'')}${item.album ? ` <span class="fr-feed-album">· ${escHtml(item.album)}</span>` : ''}</div>
          <div class="fr-feed-meta">
            <div class="fr-feed-user">
              ${userAvHtml}${userAvFallback}
              <span>${escHtml(item.username)}</span>
            </div>
            ${timeHtml}
          </div>
          ${playHtml}
        </div>
      </div>`;
  },

  /* ── Live polling ── */
  startLivePolling() {
    clearInterval(this.liveTimer);
    this.refreshLiveStatuses();
    this.liveTimer = setInterval(() => {
      // Ne pas poller si l'onglet est masqué (économie de batterie/réseau)
      if (!document.hidden) this.refreshLiveStatuses();
    }, LIVE_POLL_MS);

    // Reprendre le polling immédiatement quand l'utilisateur revient sur l'onglet
    if (!this._visibilityBound) {
      this._visibilityBound = true;
      document.addEventListener('visibilitychange', () => {
        if (!document.hidden && this.liveTimer) {
          // Rafraîchissement immédiat à la reprise de l'onglet
          this.refreshLiveStatuses();
        }
      });
    }
  },

  stopLivePolling() {
    clearInterval(this.liveTimer);
    this.liveTimer = null;
  },

  async refreshLiveStatuses() {
    const selfUser = { name: this.username, image: '' };

    const friendNames = new Set(this.friends.map(f => f.name.toLowerCase()));
    const favsExtra   = Favs.all().filter(f => !friendNames.has(f.name.toLowerCase()));
    const searchExtra = [];
    if (this.currentSearchUser && !friendNames.has(this.currentSearchUser.name.toLowerCase())) {
      const alreadyFav = favsExtra.some(f => f.name.toLowerCase() === this.currentSearchUser.name.toLowerCase());
      if (!alreadyFav) searchExtra.push(this.currentSearchUser);
    }

    const allUsers = [selfUser, ...this.friends, ...favsExtra, ...searchExtra];
    if (!allUsers.length) return;

    const BATCH = 8;
    for (let i = 0; i < allUsers.length; i += BATCH) {
      const batch = allUsers.slice(i, i + BATCH);
      await Promise.all(batch.map(f => this._fetchLiveStatus(f)));
      if (i + BATCH < allUsers.length) await sleep(300);
    }

    this._updateStatStrip();
    this.renderMyStatus();
    this.renderFriendsGrid();
    this.renderFavorites();
    this.renderHomeTab();
    this._checkPushNotifications();

    if (this.currentSearchUser) this._patchSearchResultLive(this.currentSearchUser.name);

    const now    = new Date().toLocaleTimeString('fr-FR', { hour:'2-digit', minute:'2-digit' });
    const statUpd = $('#stat-updated');
    const sbUpd   = $('#sb-stat-updated');
    if (statUpd) statUpd.textContent = `màj ${now}`;
    if (sbUpd)   sbUpd.textContent   = `màj ${now}`;
  },

  async _fetchLiveStatus(friend) {
    try {
      const data   = await API.getRecentTrack(friend.name, 3);
      const tracks = data.recenttracks?.track || [];
      const arr    = Array.isArray(tracks) ? tracks : [tracks];
      if (!arr.length) return;

      const first      = arr[0];
      const nowPlaying = first['@attr']?.nowplaying === 'true';

      const recentTracks = arr
        .filter(t => t['@attr']?.nowplaying !== 'true')
        .map(t => ({
          track:     t.name || '',
          artist:    t.artist?.['#text'] || t.artist || '',
          album:     t.album?.['#text'] || '',
          art:       imgUrl(t.image),
          ts:        parseInt(t.date?.uts || 0),
          username:  friend.name,
          userImage: friend.image || '',
        }));

      // ── Compute daysSinceLastScrobble for moon badge ──────────────
      const lastNonLive = nowPlaying ? recentTracks[0] : null;
      const lastTs = nowPlaying
        ? (lastNonLive?.ts || 0)
        : parseInt(first.date?.uts || 0);
      const daysSinceLastScrobble = lastTs > 0
        ? (Date.now() / 1000 - lastTs) / 86400
        : 999;

      // Preserve todayScrobbles & myPlayCount from previous poll if track unchanged
      const prevStatus  = this.liveStatuses[friend.name.toLowerCase()];
      const newTrackKey = nowPlaying
        ? `${(first.artist?.['#text'] || '').toLowerCase()}|${(first.name || '').toLowerCase()}`
        : '';
      const prevTrackKey = this._lastLiveTracks[friend.name.toLowerCase()] || '';

      const status = {
        nowPlaying,
        track:      first.name || '',
        artist:     first.artist?.['#text'] || first.artist || '',
        album:      first.album?.['#text'] || '',
        art:        imgUrl(first.image),
        ts:         nowPlaying ? null : parseInt(first.date?.uts || 0),
        userImage:  friend.image || '',
        recentTracks,
        daysSinceLastScrobble,
        todayScrobbles:  prevStatus?.todayScrobbles  ?? 0,
        myPlayCount:     (nowPlaying && prevTrackKey === newTrackKey) ? (prevStatus?.myPlayCount ?? 0) : 0,
      };
      this.liveStatuses[friend.name.toLowerCase()] = status;

      // ── Trigger background today-scrobbles fetch (non-blocking, daily cache) ──
      this._fetchTodayScrobbles(friend.name).then(count => {
        const s = this.liveStatuses[friend.name.toLowerCase()];
        if (s) s.todayScrobbles = count;
      }).catch(() => {});

      // ── Trigger myPlayCount fetch when live track changes (non-blocking) ──
      if (nowPlaying && status.track && status.artist && newTrackKey !== prevTrackKey) {
        this._lastLiveTracks[friend.name.toLowerCase()] = newTrackKey;
        this._getMyPlayCount(status.artist, status.track).then(count => {
          const s = this.liveStatuses[friend.name.toLowerCase()];
          if (s) s.myPlayCount = count;
        }).catch(() => {});
      }

      // Mark recently-seen tracks (for Archive/Nouveauté badges)
      const uKey = friend.name.toLowerCase();
      if (status.track) TrackSeen.mark(uKey, `${(status.artist||'').toLowerCase()}|${status.track.toLowerCase()}`);
      recentTracks.forEach(rt => {
        if (rt.track) TrackSeen.mark(uKey, `${(rt.artist||'').toLowerCase()}|${rt.track.toLowerCase()}`);
      });
    } catch {
      // Keep old status on error
    }
  },

  _updateStatStrip() {
    const total = this.friends.length;
    const live  = this.friends.filter(f => this.liveStatuses[f.name.toLowerCase()]?.nowPlaying).length;
    const totalEl  = $('#stat-total');    if (totalEl)  totalEl.textContent  = total;
    const liveEl   = $('#stat-live');     if (liveEl)   liveEl.textContent   = live;
    const sbTotal  = $('#sb-stat-total'); if (sbTotal)  sbTotal.textContent  = total;
    const sbLiveV  = $('#sb-stat-live');  if (sbLiveV)  sbLiveV.textContent  = live;
    const sbLiveDot = $('#sb-live-dot');
    if (sbLiveDot) {
      sbLiveDot.classList.toggle('hidden', live === 0);
      const cnt = sbLiveDot.querySelector('#sb-live-count');
      if (cnt) cnt.textContent = live;
    }
  },

  /* ═══════════════════════════════════════
     TOP 5 MODAL
  ═══════════════════════════════════════ */
  async showTop5() {
    const overlay = $('#top5-overlay');
    const body    = $('#top5-body');
    if (!overlay || !body) return;

    overlay.classList.remove('hidden');
    body.innerHTML = `
      <div style="text-align:center;padding:40px 24px;color:var(--text-muted)">
        <i class="fas fa-circle-notch fa-spin" style="color:var(--accent);font-size:1.4rem"></i>
        <p style="margin-top:12px;font-size:.85rem">Chargement du classement…</p>
      </div>`;

    // ── Group Weekly Top (parallel with individual data) ──
    const groupWeeklyPromise = this._buildGroupWeeklyTop(this.friends);

    // Sort friends by overall playcount, take top 5
    const top5 = [...this.friends].sort((a,b) => b.playcount - a.playcount).slice(0, 5);
    if (!top5.length) {
      body.innerHTML = `<p style="text-align:center;color:var(--text-muted);padding:32px">Aucun ami trouvé.</p>`;
      return;
    }

    // Fetch weekly top artist for each
    const results = await Promise.allSettled(top5.map(f => API.getWeeklyArtists(f.name)));

    body.innerHTML = top5.map((f, i) => {
      const weeklyData   = results[i]?.status === 'fulfilled' ? results[i].value : null;
      const weekArtist   = weeklyData?.topartists?.artist?.[0];
      const weeklyArtist = weekArtist?.name    || '—';
      const weeklyPlays  = weekArtist?.playcount ? fmt(weekArtist.playcount) + ' plays' : '';
      const isLive = !!this.liveStatuses[f.name.toLowerCase()]?.nowPlaying;
      const liveStatus = this.liveStatuses[f.name.toLowerCase()];
      const av = f.image || '';

      // Médaille pour les 3 premiers
      const medals = ['🥇','🥈','🥉'];
      const rankDisplay = i < 3 ? medals[i] : (i + 1);

      return `
        <div class="top5-row" style="animation-delay:${i*70}ms" role="button" tabindex="0"
             data-username="${escHtml(f.name)}">
          <span class="top5-rank" title="Rang ${i+1}">${rankDisplay}</span>
          <div class="top5-av-wrap">
            ${av ? `<img src="${escHtml(av)}" alt="${escHtml(f.name)}"
                        onerror="this.style.display='none';this.nextElementSibling.style.removeProperty('display')">` : ''}
            <div style="${av?'display:none;':''}background:${this._nameColor(f.name)}">${f.name.charAt(0).toUpperCase()}</div>
            ${isLive ? '<div class="top5-live-dot"></div>' : ''}
          </div>
          <div class="top5-info">
            <div class="top5-name">
              ${escHtml(f.name)}
              ${f.subscriber ? '<i class="fas fa-crown" style="color:#f59e0b;font-size:.6rem" title="Subscriber"></i>' : ''}
              ${isLive ? '<span class="fm-live-badge" style="font-size:.6rem;padding:2px 6px"><span class="live-dot sm"></span>LIVE</span>' : ''}
            </div>
            <div class="top5-sub">
              ${isLive && liveStatus?.track
                ? `🎵 ${escHtml(liveStatus.track)} — ${escHtml(liveStatus.artist)}`
                : `Cette semaine : ${escHtml(weeklyArtist)}${weeklyPlays ? ` · ${weeklyPlays}` : ''}`}
            </div>
          </div>
          <div class="top5-plays">
            <strong>${fmt(f.playcount)}</strong>
            <span>scrobbles</span>
          </div>
        </div>`;
    }).join('');

    $$('.top5-row', body).forEach(row => {
      row.addEventListener('click', () => {
        this.closeTop5();
        this.openProfileModal(row.dataset.username);
      });
    });

    // ── Append group weekly top ──────────────────────────────────────────────
    try {
      const weeklyTop = await groupWeeklyPromise;
      if (weeklyTop?.length) {
        const weeklySection = document.createElement('div');
        weeklySection.className = 'top5-group-section';
        weeklySection.innerHTML = `
          <div class="top5-group-hd">
            <i class="fas fa-globe" style="color:var(--accent)"></i>
            <span>Artiste du groupe — 7 jours</span>
          </div>
          ${weeklyTop.map((a, i) => `
            <div class="top5-group-row" style="animation-delay:${i*60}ms">
              <span class="top5-group-rank">${i + 1}</span>
              <div class="top5-group-info">
                <span class="top5-group-name">${escHtml(a.name)}</span>
                <span class="top5-group-meta">${a.friendCount} ami${a.friendCount > 1 ? 's' : ''} · ${fmt(a.plays)} écoutes</span>
              </div>
              <a class="fr-np-play-btn" href="https://open.spotify.com/search/${encodeURIComponent(a.name)}"
                 target="_blank" rel="noopener" onclick="event.stopPropagation()" title="Spotify">
                <i class="fab fa-spotify"></i>
              </a>
            </div>`).join('')}`;
        body.prepend(weeklySection);
      }
    } catch {}
  },

  closeTop5() {
    const overlay = $('#top5-overlay');
    if (overlay) overlay.classList.add('hidden');
  },

  /* ═══════════════════════════════════════
     WEB PUSH NOTIFICATIONS
  ═══════════════════════════════════════ */
  async setupPushNotifications() {
    if (!('Notification' in window)) {
      this.showToast('❌ Notifications non supportées par ce navigateur', '');
      return;
    }
    if (this._pushEnabled && Notification.permission === 'granted') {
      // Toggle off
      this._pushEnabled = false;
      localStorage.setItem(LS_PUSH, '0');
      this.renderSettingsState();
      this.showToast('🔕 Notifications désactivées', '');
      return;
    }
    try {
      const permission = await Notification.requestPermission();
      if (permission === 'granted') {
        this._pushEnabled = true;
        localStorage.setItem(LS_PUSH, '1');
        this.renderSettingsState();
        this.showToast('🔔 Notifications activées !', 'success');
        // Fire a welcome notification
        new Notification('LastStats — Notifications activées', {
          body: 'Vous serez notifié quand vos favoris commencent à écouter.',
          icon: 'icons/icon-192.png',
          tag: 'lastfm-welcome',
        });
      } else {
        this._pushEnabled = false;
        localStorage.setItem(LS_PUSH, '0');
        this.renderSettingsState();
        this.showToast('❌ Permission refusée', '');
      }
    } catch (e) {
      this.showToast('❌ Erreur lors de la demande de permission', '');
    }
  },

  _checkPushNotifications() {
    if (!this._pushEnabled || Notification?.permission !== 'granted') return;
    const favNames = new Set(Favs.all().map(f => f.name.toLowerCase()));

    // Clean up old notification keys (older than 1h)
    const now = Date.now();
    Object.keys(this._lastNotified).forEach(k => {
      if (now - this._lastNotified[k] > 3_600_000) delete this._lastNotified[k];
    });

    for (const [lcName, status] of Object.entries(this.liveStatuses)) {
      if (!favNames.has(lcName)) continue;
      if (!status.nowPlaying || !status.track) continue;

      const key = `${lcName}|${(status.track+'').toLowerCase()}|${(status.artist+'').toLowerCase()}`;
      if (this._lastNotified[key]) continue;
      this._lastNotified[key] = now;

      const friend = this.friends.find(f => f.name.toLowerCase() === lcName)
                  || Favs.all().find(f => f.name.toLowerCase() === lcName);
      const displayName = friend?.name || lcName;

      try {
        const notif = new Notification(`🎵 ${displayName} écoute maintenant`, {
          body: `${status.track} — ${status.artist}`,
          icon: status.art || friend?.image || '',
          tag:  `lastfm-live-${lcName}`,
          badge: 'icons/icon-72.png',
        });
        notif.onclick = () => {
          window.focus();
          this.closeTop5();
          this.openProfileModal(displayName);
        };
      } catch {}
    }
  },

  /* ═══════════════════════════════════════
     FAVORITES — live-first sort
  ═══════════════════════════════════════ */
  renderFavorites() {
    const grid = $('#favorites-grid');
    if (!grid) return;
    let favs = Favs.all();

    if (this.favQuery) {
      favs = favs.filter(f =>
        f.name.toLowerCase().includes(this.favQuery) ||
        (f.realname || '').toLowerCase().includes(this.favQuery)
      );
    }

    const emptyEl = $('#fav-empty');
    if (!favs.length) {
      grid.innerHTML = '';
      if (emptyEl) emptyEl.classList.remove('hidden');
      return;
    }
    if (emptyEl) emptyEl.classList.add('hidden');

    const liveFavs    = favs.filter(f =>  this.liveStatuses[f.name.toLowerCase()]?.nowPlaying);
    const offlineFavs = favs.filter(f => !this.liveStatuses[f.name.toLowerCase()]?.nowPlaying);
    const sorted      = [...liveFavs, ...offlineFavs];

    grid.innerHTML = sorted.map((f, i) => this._buildFriendCard(f, i)).join('');

    sorted.forEach(f => {
      const card = $(`[data-username="${f.name}"]`, grid);
      if (!card) return;
      $('[data-action="fav"]',  card)?.addEventListener('click', e => { e.stopPropagation(); this.toggleFav(f, card); this.renderFavorites(); });
      $('[data-action="view"]', card)?.addEventListener('click', e => { e.stopPropagation(); this.openProfileModal(f.name); });
      card.addEventListener('click', () => this.openProfileModal(f.name));
    });
  },

  toggleFav(info, card) {
    const added = Favs.toggle(info);
    this.updateFavBadge();
    const btn  = $('[data-action="fav"]', card);
    const icon = btn && $('i', btn);
    if (btn && icon) {
      btn.classList.toggle('fav-active', added);
      btn.title      = added ? 'Retirer des favoris' : 'Ajouter aux favoris';
      icon.className = added ? 'fas fa-star' : 'far fa-star';
    }
    this.showToast(added ? '⭐ Ajouté aux favoris' : 'Retiré des favoris', added ? 'success' : '');
  },

  updateFavBadge() {
    const n = Favs.count();
    const sbBadge = $('#sb-fav-badge');
    if (sbBadge) { sbBadge.textContent = n; sbBadge.classList.toggle('hidden', n === 0); }
    const bnBadge = $('#bn-fav-badge');
    if (bnBadge) { bnBadge.textContent = n; bnBadge.classList.toggle('hidden', n === 0); }
    // Also update home count
    const favEl = $('#home-fav-count');
    if (favEl) favEl.textContent = n || '0';
  },

  /* ═══════════════════════════════════════
     SEARCH
  ═══════════════════════════════════════ */
  async doSearch(query) {
    query = query.trim();
    if (!query) return;

    const searchIn = $('#search-username');
    if (searchIn) searchIn.value = query;
    $('#search-big-clear')?.classList.remove('hidden');

    $('#recent-searches-section')?.classList.add('hidden');
    this._hideAllSearchStates();
    $('#search-results-section')?.classList.remove('hidden');
    $('#search-loading')?.classList.remove('hidden');
    const titleEl = $('#search-results-title');
    if (titleEl) titleEl.textContent = `Profil : ${query}`;

    this.currentSearchUser = null;

    try {
      const data = await API.getInfo(query);
      const user = data.user;
      if (!user) throw new Error('Profil introuvable');

      Recent.add(user.name);
      this.renderRecentSearches();

      this.currentSearchUser = { name: user.name, image: imgUrl(user.image) };

      const livePromise = this._fetchLiveStatus(this.currentSearchUser).then(() => {
        this._patchSearchResultLive(user.name);
      });

      $('#search-loading')?.classList.add('hidden');
      this._renderSearchResult(user);
      livePromise.catch(() => {});

    } catch (e) {
      $('#search-loading')?.classList.add('hidden');
      if (e.message?.includes('User not found') || e.message?.includes('No user')) {
        $('#search-not-found')?.classList.remove('hidden');
      } else {
        $('#search-error')?.classList.remove('hidden');
        const errMsg = $('#search-error-msg');
        if (errMsg) errMsg.textContent = e.message || 'Erreur lors de la recherche.';
      }
    }
  },

  _patchSearchResultLive(username) {
    const liveStatus = this.liveStatuses[username.toLowerCase()];
    if (!liveStatus) return;

    const liveEl = $('#search-result-live-badge');
    if (liveEl) liveEl.classList.toggle('hidden', !liveStatus.nowPlaying);

    const npWrap = $('#search-result-np-wrap');
    if (npWrap) {
      if (liveStatus.nowPlaying && liveStatus.track) {
        const artHtml = liveStatus.art
          ? `<img class="fr-np-art" src="${escHtml(liveStatus.art)}" alt="${escHtml(liveStatus.track)}"
                 loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
             <div class="fr-np-art np-art-fallback" style="display:none;background:${this._nameColor(liveStatus.artist||'')};">${(liveStatus.artist||'?').charAt(0)}</div>`
          : `<div class="fr-np-art np-art-fallback" style="display:flex;background:${this._nameColor(liveStatus.artist||'')};">${(liveStatus.artist||'?').charAt(0)}</div>`;
        const spQ = encodeURIComponent(`${liveStatus.artist} ${liveStatus.track}`);
        const ytQ = encodeURIComponent(`${liveStatus.artist} ${liveStatus.track}`);
        npWrap.innerHTML = `
          <div class="fr-np-bar" style="margin-top:10px">
            ${artHtml}
            <div class="fr-np-info">
              <div class="fr-np-track">${escHtml(liveStatus.track)}</div>
              <div class="fr-np-artist">${escHtml(liveStatus.artist||'')}${liveStatus.album ? ` · <em style="opacity:.7">${escHtml(liveStatus.album)}</em>` : ''}</div>
            </div>
            <div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px;flex-shrink:0">
              <div class="fr-np-icon"><span></span><span></span><span></span><span></span></div>
              <div style="display:flex;gap:4px;margin-top:2px">
                <a class="fr-np-play-btn" href="https://open.spotify.com/search/${spQ}" target="_blank" rel="noopener" title="Spotify"><i class="fab fa-spotify"></i></a>
                <a class="fr-np-play-btn yt" href="https://music.youtube.com/search?q=${ytQ}" target="_blank" rel="noopener" title="YouTube Music"><i class="fab fa-youtube"></i></a>
              </div>
            </div>
          </div>`;
        npWrap.classList.remove('hidden');
      } else {
        npWrap.innerHTML = '';
        npWrap.classList.add('hidden');
      }
    }
  },

  _renderSearchResult(user) {
    const av    = imgUrl(user.image);
    const isFav = Favs.has(user.name);
    const info  = {
      name:      user.name,
      realname:  user.realname || '',
      country:   user.country  || '',
      playcount: parseInt(user.playcount || 0),
      image:     av,
    };

    const avHtml = av
      ? `<img class="fr-profile-av" src="${escHtml(av)}" alt="${escHtml(user.name)}" loading="lazy"
             onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
      : '';
    const avFallback = `<div class="fr-profile-av" style="background:${this._nameColor(user.name)};display:${av?'none':'flex'};align-items:center;justify-content:center;font-size:1.5rem;font-weight:700;color:#fff">${user.name.charAt(0).toUpperCase()}</div>`;

    const html = `
      <div class="fr-result-cards">
        <div class="fr-profile-card" id="search-result-main" data-username="${escHtml(user.name)}">
          ${avHtml}${avFallback}
          <div class="fr-profile-body">
            <div class="fr-profile-name">
              ${escHtml(user.name)}
              <span class="fr-search-live-badge hidden" id="search-result-live-badge">
                <span class="live-dot sm"></span>En écoute
              </span>
              ${user.subscriber==='1'?'<i class="fas fa-crown" style="color:#f59e0b;font-size:.7rem" title="Subscriber"></i>':''}
            </div>
            ${user.realname ? `<div class="fr-profile-realname">${escHtml(user.realname)}</div>` : ''}
            <div class="fr-profile-stats">
              <span class="fr-profile-stat"><i class="fas fa-music"></i><strong>${fmt(user.playcount)}</strong> scrobbles</span>
              ${user.country ? `<span class="fr-profile-stat"><i class="fas fa-map-marker-alt"></i>${escHtml(user.country)}</span>` : ''}
              ${user.registered?.['#text'] || user.registered?.unixtime ? `<span class="fr-profile-stat"><i class="fas fa-calendar-alt"></i>Depuis ${escHtml(formatRegDate(user.registered?.['#text'] || user.registered?.unixtime))}</span>` : ''}
            </div>
            <div id="search-result-np-wrap" class="hidden"></div>
            <div style="display:flex;gap:8px;margin-top:10px;flex-wrap:wrap">
              <button class="fr-expand-btn" id="search-expand-btn">
                <i class="fas fa-chart-bar"></i> Stats détaillées
              </button>
              <button class="fr-expand-btn" id="search-open-full-btn">
                <i class="fas fa-user-circle"></i> Profil complet
              </button>
              <a href="https://www.last.fm/user/${encodeURIComponent(user.name)}" target="_blank" rel="noopener"
                 class="fr-expand-btn" style="text-decoration:none" onclick="event.stopPropagation()">
                <i class="fab fa-lastfm"></i> last.fm
              </a>
            </div>
          </div>
          <div class="fr-profile-actions">
            <button class="fr-action-btn${isFav?' fav-active':''}" id="search-fav-btn"
                    title="${isFav?'Retirer des favoris':'Ajouter aux favoris'}">
              <i class="fa${isFav?'s':'r'} fa-star"></i>
            </button>
          </div>
        </div>
        <div id="search-advanced-detail" class="hidden"></div>
      </div>`;

    const resList = $('#search-results-list');
    if (resList) resList.innerHTML = html;

    $('#search-open-full-btn')?.addEventListener('click', () => this.openProfileModal(user.name));

    $('#search-fav-btn')?.addEventListener('click', () => {
      const btn  = $('#search-fav-btn');
      const icon = btn && $('i', btn);
      const added = Favs.toggle(info);
      if (btn) btn.classList.toggle('fav-active', added);
      if (btn) btn.title = added ? 'Retirer des favoris' : 'Ajouter aux favoris';
      if (icon) icon.className = added ? 'fas fa-star' : 'far fa-star';
      this.updateFavBadge();
      this.showToast(added ? '⭐ Ajouté aux favoris' : 'Retiré des favoris', added ? 'success' : '');
    });

    let expanded = false;
    $('#search-expand-btn')?.addEventListener('click', async () => {
      if (expanded) return;
      expanded = true;
      const btn = $('#search-expand-btn');
      if (btn) { btn.innerHTML = '<i class="fas fa-circle-notch fa-spin"></i> Chargement…'; btn.disabled = true; }
      try {
        const [artists, tracks, albums] = await Promise.all([
          API.getTopArtists(user.name, 'overall', 5),
          API.getTopTracks(user.name, 'overall', 5),
          API.getTopAlbums(user.name, 'overall', 3),
        ]);
        this._renderAdvancedDetail(user.name, artists, tracks, albums);
        if (btn) btn.innerHTML = '<i class="fas fa-check"></i> Chargé';
      } catch {
        if (btn) { btn.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Erreur'; btn.disabled = false; }
        expanded = false;
      }
    });
  },

  _renderAdvancedDetail(username, artistsData, tracksData, albumsData) {
    const artists = artistsData?.topartists?.artist || [];
    const tracks  = tracksData?.toptracks?.track    || [];
    const albums  = albumsData?.topalbums?.album     || [];

    const buildList = (items, getImg, getName, getSub, getPlays) => {
      if (!items.length) return '<p style="color:var(--text-muted);font-size:.8rem;padding:4px 0">Aucune donnée</p>';
      return items.slice(0, 5).map((item, idx) => {
        const imgSrc = getImg(item);
        // Image OU fallback, pas les deux
        const mediaEl = imgSrc
          ? `<img src="${escHtml(imgSrc)}" alt="${escHtml(getName(item))}" loading="lazy"
                 style="width:36px;height:36px;border-radius:4px;object-fit:cover;flex-shrink:0"
                 onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
             <div style="width:36px;height:36px;border-radius:4px;flex-shrink:0;background:${this._nameColor(getName(item))};display:none;align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.8rem">${getName(item).charAt(0)}</div>`
          : `<div style="width:36px;height:36px;border-radius:4px;flex-shrink:0;background:${this._nameColor(getName(item))};display:flex;align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.8rem">${getName(item).charAt(0)}</div>`;
        return `
          <div class="fm-top-row">
            <span class="fm-top-rank">${idx+1}</span>
            ${mediaEl}
            <div class="fm-top-info" style="min-width:0">
              <div class="fm-top-name" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${escHtml(getName(item))}</div>
              ${getSub(item) ? `<div class="fm-top-sub">${escHtml(getSub(item))}</div>` : ''}
            </div>
            <span class="fm-top-plays">${fmt(getPlays(item))}</span>
          </div>`;
      }).join('');
    };

    const html = `
      <div class="fr-profile-detail">
        <div class="fr-detail-section">
          <div class="fr-detail-label"><i class="fas fa-microphone-alt"></i> Top Artistes</div>
          <div class="fm-tops">${buildList(Array.isArray(artists)?artists:[artists], a=>imgUrl(a.image), a=>a.name, ()=>'', a=>a.playcount)}</div>
        </div>
        <div class="fr-detail-section">
          <div class="fr-detail-label"><i class="fas fa-music"></i> Top Morceaux</div>
          <div class="fm-tops">${buildList(Array.isArray(tracks)?tracks:[tracks], t=>imgUrl(t.image), t=>t.name, t=>t.artist?.name||'', t=>t.playcount)}</div>
        </div>
        <div class="fr-detail-section" style="margin-bottom:0">
          <div class="fr-detail-label"><i class="fas fa-compact-disc"></i> Top Albums</div>
          <div class="fm-tops">${buildList(Array.isArray(albums)?albums:[albums], a=>imgUrl(a.image), a=>a.name, a=>a.artist?.name||'', a=>a.playcount)}</div>
        </div>
        <div style="margin-top:14px;display:flex;gap:8px;flex-wrap:wrap">
          <a href="index.html?user=${encodeURIComponent(username)}"
             class="fm-btn fm-btn-primary" style="text-decoration:none;flex:0 0 auto">
            <i class="fas fa-chart-line"></i> Voir dans LastStats
          </a>
        </div>
      </div>`;

    const detail = $('#search-advanced-detail');
    if (detail) { detail.innerHTML = html; detail.classList.remove('hidden'); }
  },

  _hideAllSearchStates() {
    ['search-loading','search-not-found','search-error'].forEach(id => $('#'+id)?.classList.add('hidden'));
    const resList = $('#search-results-list');
    if (resList) resList.innerHTML = '';
  },

  /* ── Recent searches ── */
  renderRecentSearches() {
    const list  = Recent.load();
    const el    = $('#recent-searches-list');
    const empty = $('#recent-empty');
    if (!el) return;

    if (!list.length) {
      el.innerHTML = '';
      if (empty) empty.classList.remove('hidden');
      return;
    }
    if (empty) empty.classList.add('hidden');

    el.innerHTML = list.map(r => `
      <div class="fr-recent-item" data-username="${escHtml(r.username)}">
        <i class="fas fa-history ri-icon"></i>
        <span class="ri-user">${escHtml(r.username)}</span>
        <span class="ri-time">${timeAgo(Math.floor(r.ts / 1000))}</span>
        <button class="ri-del" data-del="${escHtml(r.username)}" title="Supprimer" onclick="event.stopPropagation()">
          <i class="fas fa-times"></i>
        </button>
      </div>`).join('');

    $$('.fr-recent-item', el).forEach(item => {
      item.addEventListener('click', () => {
        const u = item.dataset.username;
        if (u) {
          const searchIn = $('#search-username');
          if (searchIn) searchIn.value = u;
          $('#search-big-clear')?.classList.remove('hidden');
          this.doSearch(u);
        }
      });
      $('[data-del]', item)?.addEventListener('click', e => {
        const u = e.currentTarget.dataset.del;
        Recent.remove(u);
        this.renderRecentSearches();
      });
    });
  },

  resetSearchUI() {
    this._hideAllSearchStates();
    $('#search-results-section')?.classList.add('hidden');
    $('#recent-searches-section')?.classList.remove('hidden');
    this.renderRecentSearches();
  },

  /* ═══════════════════════════════════════
     PROFILE MODAL — with Spotify/YouTube CTA
  ═══════════════════════════════════════ */
  async openProfileModal(username) {
    const overlay = $('#profile-modal-overlay');
    const body    = $('#profile-modal-body');
    const modal   = $('#profile-modal');
    if (!overlay || !body) return;

    if (modal) modal.scrollTop = 0;

    body.innerHTML = `
      <div style="padding:80px 24px;display:flex;align-items:center;justify-content:center;gap:12px;color:var(--text-muted)">
        <i class="fas fa-circle-notch fa-spin" style="color:var(--accent)"></i>
        Chargement du profil…
      </div>`;

    overlay.removeAttribute('aria-hidden');
    overlay.classList.remove('closing');
    overlay.classList.add('open');
    document.body.style.overflow = 'hidden';

    try {
      const [infoData, artistsData, tracksData] = await Promise.all([
        API.getInfo(username),
        API.getTopArtists(username, 'overall', 5),
        API.getTopTracks(username, 'overall', 5),
      ]);

      const user       = infoData.user;
      const av         = imgUrl(user.image);
      const isFav      = Favs.has(user.name);
      const liveStatus = this.liveStatuses[username.toLowerCase()];
      const isLive     = liveStatus?.nowPlaying;

      const info = {
        name:      user.name,
        realname:  user.realname || '',
        country:   user.country  || '',
        playcount: parseInt(user.playcount || 0),
        image:     av,
      };

      const artists = artistsData?.topartists?.artist || [];
      const tracks  = tracksData?.toptracks?.track    || [];

      const buildTop = (items, getImg, getName, getSub, getPlays, limit = 5) =>
        (Array.isArray(items) ? items : [items]).slice(0, limit).map((item, idx) => {
          const imgSrc = getImg(item);
          // Image OU fallback, jamais les deux visibles
          const mediaEl = imgSrc
            ? `<img class="fm-top-img" src="${escHtml(imgSrc)}" alt="${escHtml(getName(item))}" loading="lazy"
                   onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
               <div class="fm-top-img" style="display:none;background:${this._nameColor(getName(item))};align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.8rem">${getName(item).charAt(0)}</div>`
            : `<div class="fm-top-img" style="display:flex;background:${this._nameColor(getName(item))};align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.8rem">${getName(item).charAt(0)}</div>`;
          return `
            <div class="fm-top-row">
              <span class="fm-top-rank">${idx+1}</span>
              ${mediaEl}
              <div class="fm-top-info">
                <div class="fm-top-name">${escHtml(getName(item))}</div>
                ${getSub(item) ? `<div class="fm-top-sub">${escHtml(getSub(item))}</div>` : ''}
              </div>
              <span class="fm-top-plays">${fmt(getPlays(item))}</span>
            </div>`;
        }).join('');

      // Build Spotify/YouTube listen section from top track
      const topTrack   = (Array.isArray(tracks) ? tracks : [tracks])[0];
      const topArtist  = (Array.isArray(artists) ? artists : [artists])[0];
      let mediaSection = '';
      if (topTrack || (isLive && liveStatus?.track)) {
        const trackName  = isLive ? liveStatus.track  : topTrack?.name || '';
        const artistName = isLive ? liveStatus.artist : topTrack?.artist?.name || topArtist?.name || '';
        const albumArt   = isLive ? liveStatus.art    : imgUrl(topTrack?.image) || '';
        const spQ  = encodeURIComponent(`${artistName} ${trackName}`);
        const ytQ  = encodeURIComponent(`${artistName} ${trackName}`);
        const scQ  = encodeURIComponent(`${artistName} ${trackName}`);
        const deQ  = encodeURIComponent(`${artistName} ${trackName}`);
        mediaSection = `
          <div class="fm-media-section">
            <div class="fm-media-label">
              ${isLive ? '<span class="live-dot sm" style="margin-right:6px"></span>En écoute maintenant' : '<i class="fas fa-headphones" style="margin-right:6px"></i>Écouter maintenant'}
            </div>
            <div class="fm-media-track-row">
              ${albumArt
                ? `<img class="fm-media-art" src="${escHtml(albumArt)}" alt="${escHtml(trackName)}"
                       onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
                : ''}
              <div class="fm-media-art-fallback" style="background:${this._nameColor(artistName)};display:${albumArt?'none':'flex'}">${(artistName||'?').charAt(0)}</div>
              <div class="fm-media-info">
                <div class="fm-media-track-name">${escHtml(trackName)}</div>
                <div class="fm-media-artist-name">${escHtml(artistName)}</div>
              </div>
            </div>
            <div class="fm-media-btns">
              <a class="fm-media-btn spotify" href="https://open.spotify.com/search/${spQ}" target="_blank" rel="noopener">
                <i class="fab fa-spotify"></i><span>Spotify</span>
              </a>
              <a class="fm-media-btn youtube" href="https://music.youtube.com/search?q=${ytQ}" target="_blank" rel="noopener">
                <i class="fab fa-youtube"></i><span>YouTube</span>
              </a>
              <a class="fm-media-btn soundcloud" href="https://soundcloud.com/search?q=${scQ}" target="_blank" rel="noopener">
                <i class="fab fa-soundcloud"></i><span>SoundCloud</span>
              </a>
              <a class="fm-media-btn deezer" href="https://www.deezer.com/search/${deQ}" target="_blank" rel="noopener">
                <i class="fas fa-music"></i><span>Deezer</span>
              </a>
            </div>
          </div>`;
      }

      body.innerHTML = `
        <div class="fm-hero">
          <div class="fm-hero-bg" style="${av?`background-image:url('${escHtml(av)}')`:''}" aria-hidden="true"></div>
          <div class="fm-hero-overlay" aria-hidden="true"></div>
          <div class="fm-hero-content">
            ${av
              ? `<img class="fm-av" src="${escHtml(av)}" alt="${escHtml(user.name)}"
                     onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
              : ''}
            <div class="fm-av" style="background:${this._nameColor(user.name)};display:${av?'none':'flex'};align-items:center;justify-content:center;font-size:1.8rem;font-weight:700;color:#fff">${user.name.charAt(0).toUpperCase()}</div>
            <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;justify-content:center">
              <span class="fm-name">${escHtml(user.name)}</span>
              ${isLive ? '<span class="fm-live-badge"><span class="live-dot sm"></span>LIVE</span>' : ''}
              ${user.subscriber==='1'?'<i class="fas fa-crown" style="color:#f59e0b" title="Subscriber"></i>':''}
            </div>
            ${user.realname ? `<div style="font-size:.78rem;color:rgba(255,255,255,.65)">${escHtml(user.realname)}</div>` : ''}
            ${user.country  ? `<div class="fm-country"><i class="fas fa-map-marker-alt" style="margin-right:3px"></i>${escHtml(user.country)}</div>` : ''}
          </div>
        </div>

        <div class="fm-body">

          ${isLive && liveStatus ? `
          <div class="fr-np-bar" style="margin-bottom:14px">
            ${liveStatus.art
              ? `<img class="fr-np-art" src="${escHtml(liveStatus.art)}" alt="${escHtml(liveStatus.track)}" loading="lazy"
                     onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
                 <div class="fr-np-art np-art-fallback" style="display:none;background:${this._nameColor(liveStatus.artist||'')}">${(liveStatus.artist||'?').charAt(0)}</div>`
              : `<div class="fr-np-art np-art-fallback" style="display:flex;background:${this._nameColor(liveStatus.artist||'')}">${(liveStatus.artist||'?').charAt(0)}</div>`
            }
            <div class="fr-np-info">
              <div class="fr-np-track">${escHtml(liveStatus.track)}</div>
              <div class="fr-np-artist">${escHtml(liveStatus.artist||'')}${liveStatus.album ? ` · <em style="opacity:.7">${escHtml(liveStatus.album)}</em>` : ''}</div>
            </div>
            <div class="fr-np-icon"><span></span><span></span><span></span><span></span></div>
          </div>` : ''}

          ${mediaSection}

          <div class="fm-stats-row">
            <div class="fm-stat-chip"><i class="fas fa-music"></i><strong>${fmt(user.playcount)}</strong><span>scrobbles</span></div>
            <div class="fm-stat-chip"><i class="fas fa-list"></i><strong>${fmt(user.playlists || 0)}</strong><span>playlists</span></div>
            <div class="fm-stat-chip"><i class="fas fa-calendar-alt"></i><strong>${formatRegDate(user.registered?.['#text'] || user.registered?.unixtime)}</strong><span>inscrit</span></div>
          </div>

          <div class="fm-section-label"><i class="fas fa-microphone-alt"></i> Top Artistes</div>
          <div class="fm-tops" style="margin-bottom:16px">
            ${buildTop(artists, a=>imgUrl(a.image), a=>a.name, ()=>'', a=>a.playcount)}
          </div>

          <div class="fm-section-label"><i class="fas fa-music"></i> Top Morceaux</div>
          <div class="fm-tops" style="margin-bottom:16px">
            ${buildTop(tracks, t=>imgUrl(t.image), t=>t.name, t=>t.artist?.name||'', t=>t.playcount)}
          </div>

          <div class="fm-actions">
            <a href="index.html?user=${encodeURIComponent(user.name)}" target="_blank" rel="noopener"
               class="fm-btn fm-btn-primary" style="text-decoration:none">
              <i class="fas fa-chart-line"></i> Stats complètes
            </a>
            <button class="fm-btn fm-btn-outline${isFav?' fav-active':''}" id="modal-fav-btn">
              <i class="fa${isFav?'s':'r'} fa-star"></i> ${isFav ? 'Favori ✓' : 'Favori'}
            </button>
            <a href="https://www.last.fm/user/${encodeURIComponent(user.name)}" target="_blank" rel="noopener"
               class="fm-btn fm-btn-outline" style="text-decoration:none;flex:0 0 auto">
              <i class="fab fa-lastfm"></i>
            </a>
          </div>
        </div>`;

      $('#modal-fav-btn')?.addEventListener('click', () => {
        const btn   = $('#modal-fav-btn');
        const added = Favs.toggle(info);
        if (btn) btn.classList.toggle('fav-active', added);
        const icon = btn && $('i', btn);
        if (icon) icon.className = added ? 'fas fa-star' : 'far fa-star';
        if (btn) btn.lastChild.textContent = added ? ' Favori ✓' : ' Favori';
        this.updateFavBadge();
        this.showToast(added ? '⭐ Ajouté aux favoris' : 'Retiré des favoris', added ? 'success' : '');
        this.renderFriendsGrid();
        this.renderFavorites();
      });

    } catch (e) {
      body.innerHTML = `
        <div style="padding:48px 24px;text-align:center;color:var(--text-muted)">
          <i class="fas fa-exclamation-triangle" style="font-size:2rem;color:#f87171;margin-bottom:12px;display:block"></i>
          <p>Impossible de charger ce profil.</p>
          <p style="font-size:.8rem;margin-top:6px">${escHtml(e.message || '')}</p>
          <button onclick="window.FR.closeModal()"
                  style="margin-top:16px;padding:8px 20px;border-radius:99px;border:1px solid var(--border);font-size:.82rem;color:var(--text-muted)">
            Fermer
          </button>
        </div>`;
    }
  },

  closeModal() {
    const overlay = $('#profile-modal-overlay');
    if (!overlay) return;
    overlay.classList.add('closing');
    overlay.setAttribute('aria-hidden', 'true');
    overlay.addEventListener('animationend', () => {
      overlay.classList.remove('open', 'closing');
    }, { once: true });
    // Fallback safety — in case animationend never fires
    setTimeout(() => { if (overlay.classList.contains('closing')) overlay.classList.remove('open', 'closing'); }, 450);
    document.body.style.overflow = '';
  },


  /* ════════════════════════════════════════
     COÏNCIDENCES MUSICALES — home section
  ════════════════════════════════════════ */
  _renderHomeCoincidences() {
    const el      = $('#home-coincidences-body');
    const section = $('#home-coincidences-section');
    if (!el || !section) return;

    const { coincidences } = this._computeGroupStats();
    const myStatus  = this.liveStatuses[this.username.toLowerCase()];
    const myArtistK = myStatus?.nowPlaying ? (myStatus.artist || '').toLowerCase() : null;

    const items = [];

    // Self ↔ friend coincidences
    if (myArtistK) {
      for (const [lcName, status] of Object.entries(this.liveStatuses)) {
        if (lcName === this.username.toLowerCase()) continue;
        if (status.nowPlaying && (status.artist || '').toLowerCase() === myArtistK) {
          const friend = this.friends.find(f => f.name.toLowerCase() === lcName);
          items.push({
            icon: 'fa-headphones',
            color: 'var(--accent)',
            text: `Toi et <strong>${escHtml(friend?.name || lcName)}</strong> écoutez <strong>${escHtml(status.artist)}</strong> en ce moment !`,
          });
        }
      }
    }

    // Friend-to-friend coincidences (2+ friends same artist simultaneously)
    for (const artistKey of coincidences) {
      const matches = Object.entries(this.liveStatuses)
        .filter(([k]) => k !== this.username.toLowerCase())
        .filter(([, s]) => s.nowPlaying && (s.artist || '').toLowerCase() === artistKey);
      if (matches.length >= 2) {
        const names = matches.slice(0, 3).map(([k]) => {
          const fr = this.friends.find(f => f.name.toLowerCase() === k);
          return escHtml(fr?.name || k);
        });
        const artistName = matches[0][1].artist || artistKey;
        const namesList  = names.length === 2
          ? `<strong>${names[0]}</strong> et <strong>${names[1]}</strong>`
          : `<strong>${names[0]}</strong>, <strong>${names[1]}</strong> et ${matches.length - 2} autre(s)`;
        items.push({
          icon: 'fa-music',
          color: '#f59e0b',
          text: `${namesList} écoutent <strong>${escHtml(artistName)}</strong> simultanément`,
        });
      }
    }

    section.classList.toggle('hidden', items.length === 0);
    el.innerHTML = items.map(item => `
      <div class="fr-coincidence-card">
        <div class="fr-coincidence-icon" style="color:${item.color}"><i class="fas ${item.icon}"></i></div>
        <div class="fr-coincidence-text">${item.text}</div>
      </div>`).join('');
  },

  /* ════════════════════════════════════════
     DISCOVERY — "À découvrir" section
  ════════════════════════════════════════ */
  renderHomeDiscovery() {
    const el      = $('#home-discovery-body');
    const section = $('#home-discovery-section');
    if (!el || !section) return;

    // Collect my own recent artists from liveStatuses
    const myRecentArtists = new Set();
    const myStatus = this.liveStatuses[this.username.toLowerCase()];
    if (myStatus) {
      if (myStatus.artist) myRecentArtists.add(myStatus.artist.toLowerCase());
      (myStatus.recentTracks || []).forEach(rt => { if (rt.artist) myRecentArtists.add(rt.artist.toLowerCase()); });
    }

    // Count per artist how many friends listened to it
    const artistFriends = {};
    for (const [lcName, status] of Object.entries(this.liveStatuses)) {
      if (lcName === this.username.toLowerCase()) continue;
      const friend = this.friends.find(f => f.name.toLowerCase() === lcName);
      const friendName = friend?.name || lcName;
      const seen = new Set();
      const artists = [];
      if (status.artist) artists.push(status.artist);
      (status.recentTracks || []).forEach(rt => { if (rt.artist) artists.push(rt.artist); });
      artists.forEach(a => {
        const key = a.toLowerCase();
        if (seen.has(key)) return; seen.add(key);
        if (!artistFriends[key]) artistFriends[key] = { name: a, friends: [], count: 0 };
        artistFriends[key].friends.push(friendName);
        artistFriends[key].count++;
      });
    }

    const discoveries = Object.values(artistFriends)
      .filter(a => a.count >= 2 && !myRecentArtists.has(a.name.toLowerCase()))
      .sort((a, b) => b.count - a.count)
      .slice(0, 3);

    // "Classique du groupe" — most shared artist overall among friends
    const classique = Object.values(artistFriends)
      .filter(a => a.count >= 3)
      .sort((a, b) => b.count - a.count)[0];

    if (!discoveries.length && !classique) {
      section.classList.add('hidden'); return;
    }
    section.classList.remove('hidden');

    let html = '';
    if (discoveries.length) {
      html += discoveries.map(d => `
        <div class="fr-discovery-item">
          <div class="fr-discovery-icon"><i class="fas fa-users"></i></div>
          <div class="fr-discovery-body">
            <div class="fr-discovery-artist">${escHtml(d.name)}</div>
            <div class="fr-discovery-meta">${d.count} ami${d.count > 1 ? 's' : ''} écoutent cet artiste cette semaine</div>
          </div>
          <a class="fr-discovery-listen-btn" href="https://open.spotify.com/search/${encodeURIComponent(d.name)}"
             target="_blank" rel="noopener" onclick="event.stopPropagation()" title="Écouter sur Spotify">
            <i class="fab fa-spotify"></i>
          </a>
        </div>`).join('');
    }
    if (classique) {
      html += `
        <div class="fr-discovery-classique">
          <i class="fas fa-trophy" style="color:#f59e0b;flex-shrink:0"></i>
          <div>
            <div class="fr-discovery-cl-label">Classique du groupe</div>
            <div class="fr-discovery-cl-artist">${escHtml(classique.name)}</div>
            <div class="fr-discovery-cl-meta">${classique.count} ami${classique.count > 1 ? 's' : ''} l'écoutent régulièrement</div>
          </div>
          <a class="fr-discovery-listen-btn" href="https://open.spotify.com/search/${encodeURIComponent(classique.name)}"
             target="_blank" rel="noopener" onclick="event.stopPropagation()" title="Écouter sur Spotify">
            <i class="fab fa-spotify"></i>
          </a>
        </div>`;
    }
    el.innerHTML = html;
  },

  /* ════════════════════════════════════════
     FLASHBACK — "Souvenirs" section
     Affiche ce que l'utilisateur écoutait il y a 1 an, 2 ans et 5 ans.
  ════════════════════════════════════════ */
  async renderHomeFlashback() {
    const el      = $('#home-flashback-body');
    const section = $('#home-flashback-section');
    if (!el || !section) return;

    const now = Date.now();

    // Cache 6 h
    try {
      const cached = JSON.parse(localStorage.getItem(LS_FLASHBACK_KEY) || 'null');
      if (cached?.html && now - cached.ts < 6 * 3600 * 1000) {
        el.innerHTML = cached.html; section.classList.remove('hidden'); return;
      }
    } catch {}

    el.innerHTML = '<div class="fr-flashback-loading"><i class="fas fa-circle-notch fa-spin"></i></div>';
    section.classList.remove('hidden');

    const periods = [
      { label: 'Il y a 1 an',  years: 1 },
      { label: 'Il y a 2 ans', years: 2 },
      { label: 'Il y a 5 ans', years: 5 },
    ];

    const results = [];
    for (const { label, years } of periods) {
      const targetSec = Math.floor(now / 1000) - years * 365 * 86400;
      const fromSec   = targetSec - 4 * 86400;
      const toSec     = targetSec + 4 * 86400;
      try {
        const data   = await API.getRecentTracksRange(this.username, fromSec, toSec, 20);
        const tracks = data.recenttracks?.track || [];
        const arr    = Array.isArray(tracks) ? tracks : [tracks];
        const valid  = arr.filter(t => t['@attr']?.nowplaying !== 'true' && t.name);
        if (!valid.length) { results.push({ label, empty: true }); await sleep(200); continue; }

        // Most-played artist in window
        const artistMap = {};
        valid.forEach(t => {
          const a = t.artist?.['#text'] || t.artist || '';
          if (!a) return;
          const k = a.toLowerCase();
          if (!artistMap[k]) artistMap[k] = { name: a, count: 0, art: imgUrl(t.image) };
          artistMap[k].count++;
          if (imgUrl(t.image) && !artistMap[k].art) artistMap[k].art = imgUrl(t.image);
        });
        const topArtist = Object.values(artistMap).sort((a,b) => b.count - a.count)[0];
        // Most recent track overall in window
        const topTrack  = valid[0];

        results.push({
          label,
          artist:   topArtist?.name || topTrack.artist?.['#text'] || topTrack.artist || '',
          track:    topTrack.name   || '',
          art:      imgUrl(topTrack.image) || topArtist?.art || '',
          month:    new Date(fromSec * 1000 + 4 * 86400000).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' }),
          plays:    topArtist?.count || 1,
          empty:    false,
        });
      } catch {
        results.push({ label, empty: true });
      }
      await sleep(200);
    }

    const filled = results.filter(r => !r.empty);
    let html;
    if (!filled.length) {
      html = '<div class="fr-flashback-empty"><i class="fas fa-clock" style="opacity:.3"></i><p>Pas assez de données pour les périodes passées.</p></div>';
    } else {
      html = `
        <div class="fr-flashback-timeline">
          ${filled.map((r, i) => {
            const spQ = encodeURIComponent(`${r.artist} ${r.track}`);
            const ytQ = encodeURIComponent(`${r.artist} ${r.track}`);
            return `
              <div class="fr-flashback-item" style="animation-delay:${i * 80}ms">
                <div class="fr-flashback-line"></div>
                <div class="fr-flashback-dot"></div>
                <div class="fr-flashback-content">
                  <div class="fr-flashback-period">${escHtml(r.label)}</div>
                  <div class="fr-flashback-month">${escHtml(r.month)}</div>
                  <div class="fr-flashback-track">${escHtml(r.track)}</div>
                  <div class="fr-flashback-artist">
                    <i class="fas fa-microphone-alt" style="font-size:.65rem;opacity:.6;margin-right:4px"></i>${escHtml(r.artist)}
                    ${r.plays > 1 ? `<span class="fr-flashback-plays">${r.plays}× ce mois-là</span>` : ''}
                  </div>
                  <div class="fr-flashback-btns">
                    <a class="fr-fb-btn fr-fb-spotify" href="https://open.spotify.com/search/${spQ}"
                       target="_blank" rel="noopener" title="Écouter sur Spotify">
                      <i class="fab fa-spotify"></i><span>Spotify</span>
                    </a>
                    <a class="fr-fb-btn fr-fb-yt" href="https://music.youtube.com/search?q=${ytQ}"
                       target="_blank" rel="noopener" title="Écouter sur YouTube Music">
                      <i class="fab fa-youtube"></i><span>YouTube</span>
                    </a>
                  </div>
                </div>
              </div>`;
          }).join('')}
        </div>`;
    }
    el.innerHTML = html;
    try { localStorage.setItem(LS_FLASHBACK_KEY, JSON.stringify({ html, ts: now })); } catch {}
  },

  /* ═══════════════════════════════════════
     Utilities
  ═══════════════════════════════════════ */
  _buildSkeletons(n) {
    return Array.from({length: n}, () => `
      <div class="sk-card">
        <div class="sk-av sk"></div>
        <div class="sk-body">
          <div class="sk-ln w70 mt4 sk"></div>
          <div class="sk-ln w50 mt8 sk"></div>
          <div class="sk-ln w80 mt8 sk"></div>
        </div>
      </div>`).join('');
  },

  _hideAllEmpties(prefix) {
    $$(`[id^="${prefix}-empty"], [id^="${prefix}-error"]`).forEach(el => el.classList.add('hidden'));
  },

  _showEmpty(id) {
    $('#'+id)?.classList.remove('hidden');
  },

  _nameColor(name) {
    if (!name) return 'var(--accent-container)';
    let hash = 0;
    for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    const h = Math.abs(hash) % 360;
    return `hsl(${h},45%,40%)`;
  },

  /* ── Toast ── */
  _toastTimer: null,
  showToast(msg, type = '') {
    const el = $('#fr-toast');
    if (!el) return;
    el.textContent = msg;
    el.className   = `fr-toast${type?' '+type:''}`;
    el.classList.remove('hidden');
    clearTimeout(this._toastTimer);
    this._toastTimer = setTimeout(() => {
      el.classList.add('hide');
      setTimeout(() => { el.classList.add('hidden'); el.classList.remove('hide'); }, 300);
    }, 2400);
  },

  /* ════════════════════════════════════════
     FEATURE 1 — Déjà écouté N× par vous
     Récupère le userplaycount d'un titre via track.getInfo.
     Cache localStorage 6h, purgé à 24h.
  ════════════════════════════════════════ */
  async _getMyPlayCount(artist, track) {
    const key     = `${(artist||'').toLowerCase()}|${(track||'').toLowerCase()}`;
    const now     = Date.now();
    let   cache   = {};
    try { cache = JSON.parse(localStorage.getItem(LS_TRACK_PLAYS_CACHE) || '{}'); } catch {}

    // Return from cache if fresh (6 h)
    if (cache[key] && now - cache[key].ts < 6 * 3600 * 1000) return cache[key].count;

    try {
      const data  = await API.getTrackInfo(artist, track, this.username);
      const count = parseInt(data?.track?.userplaycount || 0);
      cache[key]  = { count, ts: now };
      // Prune entries older than 24 h
      const cutoff = now - 24 * 3600 * 1000;
      for (const k of Object.keys(cache)) { if (cache[k].ts < cutoff) delete cache[k]; }
      try { localStorage.setItem(LS_TRACK_PLAYS_CACHE, JSON.stringify(cache)); } catch {}
      return count;
    } catch { return 0; }
  },

  /* ════════════════════════════════════════
     FEATURE 4 — Scrobbles du jour (badge 🔥)
     Récupère le total depuis minuit local.
     Cache 2h par utilisateur, valeur remplacée au lendemain.
  ════════════════════════════════════════ */
  async _fetchTodayScrobbles(username) {
    const today   = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const now     = Date.now();
    let   cache   = {};
    try { cache = JSON.parse(localStorage.getItem(LS_DAILY_SCROBBLES) || '{}'); } catch {}

    const entry = cache[username.toLowerCase()];
    // Fresh if same day AND fetched < 2 h ago
    if (entry?.date === today && now - entry.ts < 2 * 3600 * 1000) return entry.count;

    const midnight = new Date(); midnight.setHours(0, 0, 0, 0);
    const fromSec  = Math.floor(midnight.getTime() / 1000);
    try {
      const data  = await API.call('user.getRecentTracks', { user: username, from: fromSec, limit: 1 });
      const total = parseInt(data?.recenttracks?.['@attr']?.total || 0);
      cache[username.toLowerCase()] = { count: total, date: today, ts: now };
      try { localStorage.setItem(LS_DAILY_SCROBBLES, JSON.stringify(cache)); } catch {}
      return total;
    } catch { return entry?.count ?? 0; }
  },

  /* ════════════════════════════════════════
     FEATURE 3 — Mur des Dernières Découvertes
     Pour chaque ami en écoute live, vérifie si l'artiste
     est "nouveau" pour lui (userplaycount ≤ 3).
     Cache 12h par paire (ami, artiste).
  ════════════════════════════════════════ */
  async renderDiscoveryWall() {
    const section = $('#friends-discovery-section');
    const body    = $('#friends-discovery-list');
    if (!section || !body) return;

    const liveFriends = Object.entries(this.liveStatuses)
      .filter(([k]) => k !== this.username.toLowerCase())
      .filter(([, s]) => s.nowPlaying && s.artist && s.track)
      .slice(0, 8); // Cap API calls

    if (!liveFriends.length) { section.classList.add('hidden'); return; }

    const now   = Date.now();
    let   dcache = {};
    try { dcache = JSON.parse(localStorage.getItem(LS_DISCOVERY_CACHE) || '{}'); } catch {}

    const discoveries = [];
    for (const [lcName, status] of liveFriends) {
      const cacheKey = `${lcName}|${status.artist.toLowerCase()}`;
      let   playcount;

      if (dcache[cacheKey] && now - dcache[cacheKey].ts < 12 * 3600 * 1000) {
        playcount = dcache[cacheKey].count;
      } else {
        try {
          const data = await API.getArtistInfo(status.artist, lcName);
          playcount  = parseInt(data?.artist?.stats?.userplaycount || 0);
          dcache[cacheKey] = { count: playcount, ts: now };
          // Prune old entries
          const cutoff = now - 24 * 3600 * 1000;
          for (const k of Object.keys(dcache)) { if (dcache[k].ts < cutoff) delete dcache[k]; }
          try { localStorage.setItem(LS_DISCOVERY_CACHE, JSON.stringify(dcache)); } catch {}
        } catch { continue; }
        await sleep(120); // Rate-limit guard
      }

      if (playcount >= 0 && playcount <= 3) {
        const friend = this.friends.find(f => f.name.toLowerCase() === lcName)
                     || Favs.all().find(f => f.name.toLowerCase() === lcName);
        discoveries.push({
          username: friend?.name || lcName,
          avatar:   status.userImage || friend?.image || '',
          artist:   status.artist,
          track:    status.track,
          art:      status.art,
          playcount,
        });
      }
    }

    if (!discoveries.length) { section.classList.add('hidden'); return; }
    section.classList.remove('hidden');

    body.innerHTML = discoveries.map(d => {
      const spQ = encodeURIComponent(`${d.artist} ${d.track}`);
      const ytQ = encodeURIComponent(`${d.artist} ${d.track}`);
      return `
        <div class="fr-disc-item" data-username="${escHtml(d.username)}" role="button" tabindex="0">
          <div class="fr-disc-art-wrap">
            ${d.art
              ? `<img src="${escHtml(d.art)}" alt="${escHtml(d.artist)}" loading="lazy"
                     onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
              : ''}
            <div class="fr-disc-art-fallback" style="background:${this._nameColor(d.artist)};display:${d.art?'none':'flex'}">${(d.artist||'?').charAt(0)}</div>
          </div>
          <div class="fr-disc-body">
            <div class="fr-disc-user-row">
              ${d.avatar ? `<img class="fr-disc-av" src="${escHtml(d.avatar)}" alt="${escHtml(d.username)}"
                                loading="lazy" onerror="this.style.display='none'">` : ''}
              <span class="fr-disc-username">${escHtml(d.username)}</span>
              <span class="fr-disc-new-badge">✨ ${d.playcount === 0 ? '1ère écoute' : 'Découverte'}</span>
            </div>
            <div class="fr-disc-artist">${escHtml(d.artist)}</div>
            <div class="fr-disc-track">${escHtml(d.track)}</div>
          </div>
          <div class="fr-disc-actions" onclick="event.stopPropagation()">
            <a href="https://open.spotify.com/search/${spQ}" target="_blank" rel="noopener"
               class="fr-np-play-btn" title="Spotify"><i class="fab fa-spotify"></i></a>
            <a href="https://music.youtube.com/search?q=${ytQ}" target="_blank" rel="noopener"
               class="fr-np-play-btn yt" title="YouTube"><i class="fab fa-youtube"></i></a>
          </div>
        </div>`;
    }).join('');

    $$('.fr-disc-item', body).forEach(el => {
      el.addEventListener('click', () => this.openProfileModal(el.dataset.username));
    });
  },

  /* ════════════════════════════════════════
     FEATURE 5 — Top artiste du groupe (7j)
     Récupère le top artiste hebdo de chaque ami (max 15),
     calcule un score pondéré par rang et retourne le top 5.
     Cache 2h dans localStorage.
  ════════════════════════════════════════ */
  async _buildGroupWeeklyTop(friends) {
    const now = Date.now();
    try {
      const cached = JSON.parse(localStorage.getItem(LS_GROUP_WEEKLY_KEY) || 'null');
      if (cached?.data && now - cached.ts < 2 * 3600 * 1000) return cached.data;
    } catch {}

    if (!friends?.length) return [];

    const targets = [...friends].sort((a, b) => b.playcount - a.playcount).slice(0, 15);
    const artistScore = {};

    const results = await Promise.allSettled(
      targets.map(f => API.getTopArtists(f.name, '7day', 5))
    );

    results.forEach((r) => {
      if (r.status !== 'fulfilled') return;
      const list = r.value?.topartists?.artist || [];
      const arr  = Array.isArray(list) ? list : [list];
      arr.forEach((a, rank) => {
        if (!a?.name) return;
        const key = a.name.toLowerCase();
        if (!artistScore[key]) artistScore[key] = { name: a.name, score: 0, friendCount: 0, plays: 0 };
        // Weighted score: 1st place = 5 pts … 5th = 1 pt
        artistScore[key].score       += Math.max(1, 5 - rank);
        artistScore[key].friendCount += 1;
        artistScore[key].plays       += parseInt(a.playcount || 0);
      });
    });

    const top5 = Object.values(artistScore)
      .sort((a, b) => b.score - a.score || b.friendCount - a.friendCount)
      .slice(0, 5);

    try { localStorage.setItem(LS_GROUP_WEEKLY_KEY, JSON.stringify({ data: top5, ts: now })); } catch {}
    return top5;
  },

};

/* ── Boot ── */
document.addEventListener('DOMContentLoaded', () => FR.init());
