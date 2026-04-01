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
const LS_PUSH       = 'ls_push_enabled';

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

/* ─── Favorites ─── */
const Favs = {
  _data: null,
  load() {
    if (this._data) return this._data;
    try { this._data = JSON.parse(localStorage.getItem(LS_FAV_KEY) || '{}'); }
    catch { this._data = {}; }
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
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        if (data.error) throw new Error(data.message || `API error ${data.error}`);
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
  async getWeeklyArtists(username) { return this.call('user.getTopArtists', { user: username, period: '7day', limit: 1 }); },
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

  /* ── Push notification state ── */
  _pushEnabled: false,
  _lastNotified: {},

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

  showSetup() { $('#setup-screen').classList.remove('hidden'); $('#app-shell').classList.add('hidden'); },
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

  openSidebar()  { $('#fr-sidebar').classList.add('open'); $('#fr-sidebar-ov').classList.add('open'); document.body.style.overflow = 'hidden'; },
  closeSidebar() { $('#fr-sidebar').classList.remove('open'); $('#fr-sidebar-ov').classList.remove('open'); document.body.style.overflow = ''; },

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
    $$('.fr-sb-th-btn').forEach(btn => btn.addEventListener('click', () => {
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
    $$('.fr-nav-lnk').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
    $$('.fr-bn-item').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
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

    // Musical coincidence: same artist as another friend
    const isSameArtist = isLive && live?.artist && coincidences.has(live.artist.toLowerCase());

    let npHtml = '';
    if (isLive) {
      const spQuery = encodeURIComponent(`${live.artist} ${live.track}`);
      const ytQuery = encodeURIComponent(`${live.artist} ${live.track}`);
      npHtml = `
        <div class="fr-np-bar">
          ${live.art
            ? `<img class="fr-np-art" src="${escHtml(live.art)}" alt="${escHtml(live.album||live.track)}" loading="lazy"
                   onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
            : ''}
          <div class="fr-np-art np-art-fallback" style="background:${this._nameColor(live.artist||'')};display:${live.art?'none':'flex'}">${(live.artist||'?').charAt(0)}</div>
          <div class="fr-np-info">
            <div class="fr-np-track">${escHtml(live.track)}</div>
            <div class="fr-np-artist">${escHtml(live.artist)}${live.album ? ` · <em style="opacity:.7">${escHtml(live.album)}</em>` : ''}</div>
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
      npHtml = `
        <div class="fr-last-played">
          ${live.art
            ? `<img class="fr-last-art" src="${escHtml(live.art)}" alt="${escHtml(live.track)}" loading="lazy"
                   onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
            : ''}
          <div class="fr-last-art np-art-fallback sm" style="background:${this._nameColor(live.artist||'')};display:${live.art?'none':'flex'}">${(live.artist||'?').charAt(0)}</div>
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
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      try {
        if (!this._colorSyncCanvas) {
          this._colorSyncCanvas = document.createElement('canvas');
          this._colorSyncCtx    = this._colorSyncCanvas.getContext('2d');
        }
        const canvas = this._colorSyncCanvas;
        const ctx    = this._colorSyncCtx;
        canvas.width = 32; canvas.height = 32;
        ctx.drawImage(img, 0, 0, 32, 32);
        const data = ctx.getImageData(0, 0, 32, 32).data;

        // Collect vibrant pixels (skip near-gray)
        const samples = [];
        for (let i = 0; i < data.length; i += 4) {
          const pr = data[i], pg = data[i+1], pb = data[i+2], pa = data[i+3];
          if (pa < 128) continue;
          const max = Math.max(pr,pg,pb), min = Math.min(pr,pg,pb);
          const sat = max > 0 ? (max - min) / max : 0;
          if (sat > 0.25 && max > 40 && max < 230) samples.push([pr, pg, pb]);
        }
        if (samples.length < 8) return;

        // Average colorful pixels
        let r = 0, g = 0, b = 0;
        samples.forEach(([pr,pg,pb]) => { r += pr; g += pg; b += pb; });
        r = Math.round(r / samples.length);
        g = Math.round(g / samples.length);
        b = Math.round(b / samples.length);

        // Boost saturation slightly
        const max = Math.max(r,g,b), min = Math.min(r,g,b);
        if (max !== min) {
          const sat   = (max - min) / max;
          const boost = Math.min(1.6, 1 / sat * 0.8);
          const mid   = (max + min) / 2;
          r = Math.max(0, Math.min(255, Math.round(mid + (r - mid) * boost)));
          g = Math.max(0, Math.min(255, Math.round(mid + (g - mid) * boost)));
          b = Math.max(0, Math.min(255, Math.round(b + (b - mid) * boost)));
        }

        const hex    = '#' + [r,g,b].map(v => v.toString(16).padStart(2,'0')).join('');
        const hexLt  = `rgba(${r},${g},${b},0.14)`;
        const hexCont = `rgba(${r},${g},${b},0.22)`;
        const hexGlow = `rgba(${r},${g},${b},0.4)`;
        const el = document.documentElement;
        el.style.setProperty('--accent',           hex);
        el.style.setProperty('--accent-h',         hex);
        el.style.setProperty('--accent-2',         hex);
        el.style.setProperty('--accent-lt',        hexLt);
        el.style.setProperty('--accent-container', hexCont);
        el.style.setProperty('--border-glow',      hexGlow);
        const brightness = (r*299 + g*587 + b*114) / 1000;
        el.style.setProperty('--accent-on', brightness > 128 ? '#000' : '#fff');
        this._colorSyncActive = true;
      } catch {
        // CORS taint — silently ignore
      }
    };
    img.onerror = () => {};
    img.src = imgSrc;
  },

  _resetColorSync() {
    if (!this._colorSyncActive) return;
    ['--accent','--accent-h','--accent-2','--accent-lt','--accent-container','--border-glow','--accent-on'].forEach(v =>
      document.documentElement.style.removeProperty(v)
    );
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
          allItems.push({ username, userImage, track: status.track, artist: status.artist, album: status.album||'', art: status.art, nowPlaying: true, ts: Math.floor(Date.now()/1000) });
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
        allItems.push({ username, userImage, track: status.track, artist: status.artist, album: status.album||'', art: status.art, nowPlaying: true, ts: Math.floor(Date.now()/1000) });
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
    const userAvHtml = item.userImage
      ? `<img class="fr-feed-user-av" src="${escHtml(item.userImage)}" alt="${escHtml(item.username)}"
             loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
      : '';
    const userAvFallback = `<div class="fr-feed-user-av" style="background:${this._nameColor(item.username)};display:${item.userImage?'none':'flex'};align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.75rem;">${item.username.charAt(0).toUpperCase()}</div>`;

    const artHtml = item.art
      ? `<img class="fr-feed-art" src="${escHtml(item.art)}" alt="${escHtml(item.track)}"
             loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
      : '';
    const artFallback = `<div class="fr-feed-art np-art-fallback" style="background:${this._nameColor(item.artist||'')};display:${item.art?'none':'flex'}">${(item.artist||'?').charAt(0)}</div>`;

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
          ${artHtml}${artFallback}
          ${item.nowPlaying ? '<div class="fr-feed-np-overlay"><div class="fr-np-icon sm"><span></span><span></span><span></span></div></div>' : ''}
        </div>
        <div class="fr-feed-body">
          <div class="fr-feed-track">${escHtml(item.track)}</div>
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
    this.liveTimer = setInterval(() => this.refreshLiveStatuses(), LIVE_POLL_MS);
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

      this.liveStatuses[friend.name.toLowerCase()] = {
        nowPlaying,
        track:      first.name || '',
        artist:     first.artist?.['#text'] || first.artist || '',
        album:      first.album?.['#text'] || '',
        art:        imgUrl(first.image),
        ts:         nowPlaying ? null : parseInt(first.date?.uts || 0),
        userImage:  friend.image || '',
        recentTracks,
      };
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

      return `
        <div class="top5-row" style="animation-delay:${i*70}ms" role="button" tabindex="0"
             data-username="${escHtml(f.name)}">
          <span class="top5-rank">${i+1}</span>
          <div class="top5-av-wrap">
            ${av ? `<img src="${escHtml(av)}" alt="${escHtml(f.name)}"
                        onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
            <div style="display:${av?'none':'flex'};background:${this._nameColor(f.name)}">${f.name.charAt(0).toUpperCase()}</div>
            ${isLive ? '<div class="top5-live-dot"></div>' : ''}
          </div>
          <div class="top5-info">
            <div class="top5-name">
              ${escHtml(f.name)}
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
            <span style="font-size:.7rem;color:var(--text-muted);display:block">scrobbles</span>
          </div>
        </div>`;
    }).join('');

    $$('.top5-row', body).forEach(row => {
      row.addEventListener('click', () => {
        this.closeTop5();
        this.openProfileModal(row.dataset.username);
      });
    });
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
                 loading="lazy" onerror="this.style.display='none'">`
          : `<div class="fr-np-art np-art-fallback" style="background:${this._nameColor(liveStatus.artist||'')}">${(liveStatus.artist||'?').charAt(0)}</div>`;
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
              ${user.registered?.['#text'] ? `<span class="fr-profile-stat"><i class="fas fa-calendar-alt"></i>Depuis ${escHtml(String(user.registered['#text']).split(', ').pop() || String(user.registered['#text']))}</span>` : ''}
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
        const imgEl  = imgSrc
          ? `<img src="${escHtml(imgSrc)}" alt="${escHtml(getName(item))}" loading="lazy"
                 style="width:36px;height:36px;border-radius:4px;object-fit:cover;flex-shrink:0"
                 onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
          : '';
        const fallback = `<div style="width:36px;height:36px;border-radius:4px;flex-shrink:0;background:${this._nameColor(getName(item))};display:${imgSrc?'none':'flex'};align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.8rem">${getName(item).charAt(0)}</div>`;
        return `
          <div class="fm-top-row">
            <span class="fm-top-rank">${idx+1}</span>
            ${imgEl}${fallback}
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
          const imgEl  = imgSrc
            ? `<img class="fm-top-img" src="${escHtml(imgSrc)}" alt="${escHtml(getName(item))}" loading="lazy"
                   onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
            : '';
          const fallback = `<div class="fm-top-img" style="background:${this._nameColor(getName(item))};display:${imgSrc?'none':'flex'};align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.8rem">${getName(item).charAt(0)}</div>`;
          return `
            <div class="fm-top-row">
              <span class="fm-top-rank">${idx+1}</span>
              ${imgEl}${fallback}
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
                     onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
              : ''}
            <div class="fr-np-art np-art-fallback" style="background:${this._nameColor(liveStatus.artist||'')};display:${liveStatus.art?'none':'flex'}">${(liveStatus.artist||'?').charAt(0)}</div>
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
            <div class="fm-stat-chip"><i class="fas fa-calendar-alt"></i><strong>${user.registered?.['#text'] ? String(user.registered['#text']).split(', ').pop() || '—' : '—'}</strong><span>inscrit</span></div>
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
    setTimeout(() => overlay.classList.remove('open', 'closing'), 400);
    document.body.style.overflow = '';
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
};

/* ── Boot ── */
document.addEventListener('DOMContentLoaded', () => FR.init());
