'use strict';

/* ═══════════════════════════════════════════════════════════════
   friends.js — LastStats Friends & Profile Search
   Requires: style.css, friends.css
   Reads ls_apikey + ls_username from localStorage (set by main app)
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
  async getInfo(username) {
    return this.call('user.getInfo', { user: username });
  },
  async getRecentTrack(username) {
    return this.call('user.getRecentTracks', { user: username, limit: 1 });
  },
  async getTopArtists(username, period = 'overall', limit = 5) {
    return this.call('user.getTopArtists', { user: username, period, limit });
  },
  async getTopTracks(username, period = 'overall', limit = 5) {
    return this.call('user.getTopTracks', { user: username, period, limit });
  },
  async getTopAlbums(username, period = 'overall', limit = 3) {
    return this.call('user.getTopAlbums', { user: username, period, limit });
  },
};

/* ═══════════════════════════════════════════════
   Main app state
═══════════════════════════════════════════════ */
const FR = window.FR = {
  username: '',
  friends: [],
  liveStatuses: {},
  liveTimer: null,
  currentTab: 'friends',
  currentFilter: 'all',
  friendsQuery: '',
  favQuery: '',

  /* ── Boot ── */
  async init() {
    const apiKey = localStorage.getItem(LS_APIKEY) || '';
    const user   = localStorage.getItem(LS_USERNAME) || '';

    // Apply stored theme
    const theme  = localStorage.getItem(LS_THEME)  || 'dark';
    const accent = localStorage.getItem(LS_ACCENT) || 'purple';
    document.documentElement.setAttribute('data-theme',  theme);
    document.documentElement.setAttribute('data-accent', accent);

    if (!apiKey || !user) {
      this.showSetup();
      return;
    }

    API.key       = apiKey;
    this.username = user;

    this.showApp();
    this.bindEvents();
    this.renderRecentSearches();
    this.updateFavBadge();
    this.renderFavorites();
    this.renderSettingsState();

    // Load profile for sidebar display
    this._loadSidebarProfile();
    await this.loadFriends();
  },

  showSetup() {
    $('#setup-screen').classList.remove('hidden');
    $('#app-shell').classList.add('hidden');
  },

  showApp() {
    $('#setup-screen').classList.add('hidden');
    $('#app-shell').classList.remove('hidden');
  },

  async _loadSidebarProfile() {
    try {
      const data = await API.getInfo(this.username);
      const u    = data.user;
      const av   = imgUrl(u.image);

      $('#sb-username').textContent    = u.name || this.username;
      $('#sb-scrobbles').textContent   = fmt(u.playcount) + ' scrobbles';
      $('#settings-username-display').textContent = u.name || this.username;

      const apiKey = localStorage.getItem(LS_APIKEY) || '';
      const masked = apiKey.length > 8 ? apiKey.slice(0,4) + '••••' + apiKey.slice(-4) : '••••••••';
      const settingsKeyEl = $('#settings-apikey-display');
      if (settingsKeyEl) settingsKeyEl.textContent = masked;

      const sbAv = $('#sb-av');
      const sbFb = $('#sb-av-fallback');
      if (av) {
        sbAv.src = av;
        sbAv.style.display = 'block';
        if (sbFb) sbFb.style.zIndex = '0';
      } else {
        sbAv.style.display = 'none';
        if (sbFb) sbFb.textContent = (u.name || '?').charAt(0).toUpperCase();
      }
    } catch {
      // Silently fail; sidebar just shows defaults
      $('#sb-username').textContent  = this.username;
      $('#settings-username-display').textContent = this.username;
    }
  },

  /* ── Sidebar toggle (mobile) ── */
  openSidebar() {
    $('#fr-sidebar').classList.add('open');
    $('#fr-sidebar-ov').classList.add('open');
    document.body.style.overflow = 'hidden';
  },
  closeSidebar() {
    $('#fr-sidebar').classList.remove('open');
    $('#fr-sidebar-ov').classList.remove('open');
    document.body.style.overflow = '';
  },

  /* ── Events ── */
  bindEvents() {
    // Burger + sidebar overlay
    $('#btn-burger')?.addEventListener('click', () => this.openSidebar());
    $('#btn-sb-close')?.addEventListener('click', () => this.closeSidebar());
    $('#fr-sidebar-ov')?.addEventListener('click', () => this.closeSidebar());

    // Sidebar nav links
    $$('.fr-nav-lnk').forEach(btn => {
      btn.addEventListener('click', () => {
        this.switchTab(btn.dataset.tab);
        this.closeSidebar();
      });
    });

    // Bottom nav items
    $$('.fr-bn-item').forEach(btn => {
      btn.addEventListener('click', () => this.switchTab(btn.dataset.tab));
    });

    // Friends filter + search
    const fsInput = $('#friends-search');
    fsInput.addEventListener('input', () => {
      this.friendsQuery = fsInput.value.toLowerCase().trim();
      $('#friends-search-clear').classList.toggle('hidden', !fsInput.value);
      this.renderFriendsGrid();
    });
    $('#friends-search-clear').addEventListener('click', () => {
      fsInput.value = '';
      this.friendsQuery = '';
      $('#friends-search-clear').classList.add('hidden');
      this.renderFriendsGrid();
    });

    // Filter chips
    $$('.fr-filter-chips .fr-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        $$('.fr-filter-chips .fr-chip').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        this.currentFilter = chip.dataset.filter;
        this.renderFriendsGrid();
      });
    });

    // Refresh button
    $('#btn-refresh').addEventListener('click', async () => {
      const btn = $('#btn-refresh');
      btn.classList.add('spinning');
      if (this.currentTab === 'friends') {
        await this.refreshLiveStatuses();
      }
      await sleep(400);
      btn.classList.remove('spinning');
      this.showToast('Mis à jour !', 'success');
    });

    // Search tab
    const searchIn  = $('#search-username');
    const searchBtn = $('#search-btn');
    const clearBtn  = $('#search-big-clear');

    const triggerSearch = () => {
      const val = searchIn.value.trim();
      if (val) this.doSearch(val);
    };

    searchIn.addEventListener('input', () => {
      clearBtn.classList.toggle('hidden', !searchIn.value.trim());
    });
    searchIn.addEventListener('keydown', e => {
      if (e.key === 'Enter') triggerSearch();
    });
    searchBtn.addEventListener('click', triggerSearch);
    clearBtn.addEventListener('click', () => {
      searchIn.value = '';
      clearBtn.classList.add('hidden');
      this.resetSearchUI();
    });

    // Clear recent searches
    $('#clear-recent-btn').addEventListener('click', () => {
      Recent.clear();
      this.renderRecentSearches();
    });

    // Favorites search
    const favIn = $('#fav-search');
    favIn.addEventListener('input', () => {
      this.favQuery = favIn.value.toLowerCase().trim();
      this.renderFavorites();
    });

    // Modal close
    $('#profile-modal-overlay').addEventListener('click', e => {
      if (e.target === e.currentTarget) this.closeModal();
    });
    $('#profile-modal-close').addEventListener('click', () => this.closeModal());

    // Settings: theme buttons
    $$('[data-theme-val]').forEach(btn => {
      btn.addEventListener('click', () => {
        const t = btn.dataset.themeVal;
        localStorage.setItem(LS_THEME, t);
        document.documentElement.setAttribute('data-theme', t);
        this.renderSettingsState();
        this.showToast('Thème appliqué', 'success');
      });
    });

    // Settings: accent swatches
    $$('[data-accent]').forEach(btn => {
      btn.addEventListener('click', () => {
        const a = btn.dataset.accent;
        localStorage.setItem(LS_ACCENT, a);
        document.documentElement.setAttribute('data-accent', a);
        this.renderSettingsState();
        this.showToast('Couleur appliquée', 'success');
      });
    });
  },

  /* ── Tab switching ── */
  switchTab(name) {
    this.currentTab = name;

    // Sidebar nav links
    $$('.fr-nav-lnk').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
    // Bottom nav items
    $$('.fr-bn-item').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
    // Tab sections
    $$('.tab-content').forEach(s => s.classList.toggle('active', s.id === `tab-content-${name}`));

    // Header label
    const labels = { friends:'Amis', search:'Recherche', favorites:'Favoris', settings:'Paramètres' };
    $('#hd-tab-label').textContent = labels[name] || '';

    if (name === 'favorites') this.renderFavorites();
    if (name === 'settings')  this.renderSettingsState();
  },

  /* ═══════════════════════════════════════
     SETTINGS
  ═══════════════════════════════════════ */
  renderSettingsState() {
    const theme  = localStorage.getItem(LS_THEME)  || 'dark';
    const accent = localStorage.getItem(LS_ACCENT) || 'purple';

    // Theme buttons
    $$('[data-theme-val]').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.themeVal === theme);
    });

    // Accent swatches
    $$('[data-accent]').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.accent === accent);
    });
  },

  /* ═══════════════════════════════════════
     FRIENDS — load & render
  ═══════════════════════════════════════ */
  async loadFriends() {
    const grid = $('#friends-grid');
    grid.innerHTML = this._buildSkeletons(6);
    this._hideAllEmpties('friends');

    try {
      const all = await this._fetchAllFriends();
      this.friends = all;
      this._updateStatStrip();
      this.renderFriendsGrid();
      this.startLivePolling();
    } catch (e) {
      grid.innerHTML = '';
      this._showEmpty('friends-error');
      $('#friends-error-msg').textContent = e.message || 'Erreur lors du chargement des amis.';
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
      name:       u.name || '',
      realname:   u.realname || '',
      country:    u.country || '',
      playcount:  parseInt(u.playcount || 0),
      registered: u.registered?.['#text'] || '',
      image:      imgUrl(u.image),
      subscriber: u.subscriber === '1',
      recentTrack:u.recenttrack || null,
    }));
  },

  renderFriendsGrid() {
    const grid = $('#friends-grid');
    const list = this._filteredFriends();
    this._hideAllEmpties('friends');

    if (this.friends.length === 0) {
      grid.innerHTML = '';
      this._showEmpty('friends-empty-none');
      return;
    }
    if (list.length === 0) {
      grid.innerHTML = '';
      this._showEmpty('friends-empty-filter');
      return;
    }

    grid.innerHTML = list.map((f, i) => this._buildFriendCard(f, i)).join('');

    list.forEach(f => {
      const card = $(`[data-username="${f.name}"]`, grid);
      if (!card) return;
      $('[data-action="fav"]',  card)?.addEventListener('click', e => { e.stopPropagation(); this.toggleFav(f, card); });
      $('[data-action="view"]', card)?.addEventListener('click', e => { e.stopPropagation(); this.openProfileModal(f.name); });
      card.addEventListener('click', () => this.openProfileModal(f.name));
    });
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

  _buildFriendCard(f, delay = 0) {
    const live   = this.liveStatuses[f.name.toLowerCase()];
    const isLive = live?.nowPlaying;
    const isFav  = Favs.has(f.name);
    const av     = f.image || '';
    const avHtml = av
      ? `<img class="fr-av" src="${escHtml(av)}" alt="${escHtml(f.name)}" loading="lazy" onerror="this.src='';this.style.display='none'">`
      : `<div class="fr-av" style="background:${this._nameColor(f.name)};display:flex;align-items:center;justify-content:center;color:#fff;font-size:1.1rem;font-weight:700;">${escHtml(f.name.charAt(0).toUpperCase())}</div>`;

    let npHtml = '';
    if (isLive) {
      npHtml = `
        <div class="fr-np-bar">
          ${live.art
            ? `<img class="fr-np-art" src="${escHtml(live.art)}" alt="" loading="lazy">`
            : `<div class="fr-np-art" style="background:${this._nameColor(live.artist)};display:flex;align-items:center;justify-content:center;font-size:.8rem;font-weight:700;color:#fff;">${(live.artist||'?').charAt(0)}</div>`}
          <div class="fr-np-info">
            <div class="fr-np-track">${escHtml(live.track)}</div>
            <div class="fr-np-artist">${escHtml(live.artist)}</div>
          </div>
          <div class="fr-np-icon"><span></span><span></span><span></span><span></span></div>
        </div>`;
    } else if (live?.track) {
      npHtml = `
        <div class="fr-last-played">
          ${live.art
            ? `<img class="fr-last-art" src="${escHtml(live.art)}" alt="" loading="lazy">`
            : `<div class="fr-last-art" style="background:${this._nameColor(live.artist)};display:flex;align-items:center;justify-content:center;font-size:.7rem;font-weight:700;color:#fff;">${(live.artist||'?').charAt(0)}</div>`}
          <div class="fr-last-info">
            <div class="fr-last-track">${escHtml(live.track)}</div>
            <div class="fr-last-artist">${escHtml(live.artist)}</div>
          </div>
          <span class="fr-last-when">${live.ts ? timeAgo(live.ts) : ''}</span>
        </div>`;
    }

    return `
      <div class="fr-card${isLive?' is-live':''}" data-username="${escHtml(f.name)}"
           style="animation-delay:${delay*40}ms" role="button" tabindex="0"
           aria-label="Voir le profil de ${escHtml(f.name)}">
        <div class="fr-card-header">
          <div class="fr-av-wrap">
            ${avHtml}
            ${isLive ? '<div class="fr-av-dot"></div>' : ''}
          </div>
          <div class="fr-card-info">
            <div class="fr-card-name">
              ${escHtml(f.name)}
              ${f.subscriber ? '<i class="fas fa-crown" style="color:#f59e0b;font-size:.65rem;margin-left:5px" title="Subscriber"></i>' : ''}
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

  /* ── Live polling ── */
  startLivePolling() {
    clearInterval(this.liveTimer);
    $('#live-indicator').classList.remove('hidden');
    this.refreshLiveStatuses();
    this.liveTimer = setInterval(() => this.refreshLiveStatuses(), LIVE_POLL_MS);
  },

  async refreshLiveStatuses() {
    if (!this.friends.length) return;
    const BATCH = 8;
    for (let i = 0; i < this.friends.length; i += BATCH) {
      const batch = this.friends.slice(i, i + BATCH);
      await Promise.all(batch.map(f => this._fetchLiveStatus(f)));
      if (i + BATCH < this.friends.length) await sleep(300);
    }
    this._updateStatStrip();
    this.renderFriendsGrid();
    const now = new Date().toLocaleTimeString('fr-FR', { hour:'2-digit', minute:'2-digit' });
    $('#stat-updated').textContent  = `màj ${now}`;
    $('#sb-stat-updated').textContent = `màj ${now}`;
  },

  async _fetchLiveStatus(friend) {
    try {
      const data   = await API.getRecentTrack(friend.name);
      const tracks = data.recenttracks?.track || [];
      const arr    = Array.isArray(tracks) ? tracks : [tracks];
      const track  = arr[0];
      if (!track) return;

      const nowPlaying = track['@attr']?.nowplaying === 'true';
      this.liveStatuses[friend.name.toLowerCase()] = {
        nowPlaying,
        track:  track.name || '',
        artist: track.artist?.['#text'] || track.artist || '',
        art:    imgUrl(track.image),
        ts:     nowPlaying ? null : parseInt(track.date?.uts || 0),
      };
    } catch {
      // Keep old status on error
    }
  },

  _updateStatStrip() {
    const total = this.friends.length;
    const live  = Object.values(this.liveStatuses).filter(s => s.nowPlaying).length;
    $('#stat-total').textContent     = total;
    $('#stat-live').textContent      = live;
    $('#sb-stat-total').textContent  = total;
    $('#sb-stat-live').textContent   = live;

    // Sidebar live dot
    const sbLive = $('#sb-live-dot');
    if (sbLive) {
      sbLive.classList.toggle('hidden', live === 0);
      const cnt = sbLive.querySelector('#sb-live-count');
      if (cnt) cnt.textContent = live;
    }
  },

  /* ═══════════════════════════════════════
     FAVORITES
  ═══════════════════════════════════════ */
  renderFavorites() {
    const grid = $('#favorites-grid');
    let favs   = Favs.all();

    if (this.favQuery) {
      favs = favs.filter(f =>
        f.name.toLowerCase().includes(this.favQuery) ||
        (f.realname || '').toLowerCase().includes(this.favQuery)
      );
    }

    if (!favs.length) {
      grid.innerHTML = '';
      $('#fav-empty').classList.remove('hidden');
      return;
    }

    $('#fav-empty').classList.add('hidden');
    grid.innerHTML = favs.map((f, i) => this._buildFriendCard(f, i)).join('');

    favs.forEach(f => {
      const card = $(`[data-username="${f.name}"]`, grid);
      if (!card) return;
      $('[data-action="fav"]',  card)?.addEventListener('click', e => {
        e.stopPropagation();
        this.toggleFav(f, card);
        this.renderFavorites();
      });
      $('[data-action="view"]', card)?.addEventListener('click', e => {
        e.stopPropagation();
        this.openProfileModal(f.name);
      });
      card.addEventListener('click', () => this.openProfileModal(f.name));
    });
  },

  toggleFav(info, card) {
    const added = Favs.toggle(info);
    this.updateFavBadge();
    const btn  = $('[data-action="fav"]', card);
    const icon = $('i', btn);
    if (btn && icon) {
      btn.classList.toggle('fav-active', added);
      btn.title = added ? 'Retirer des favoris' : 'Ajouter aux favoris';
      icon.className = added ? 'fas fa-star' : 'far fa-star';
    }
    this.showToast(added ? '⭐ Ajouté aux favoris' : 'Retiré des favoris', added ? 'success' : '');
  },

  updateFavBadge() {
    const n = Favs.count();
    // Sidebar badge
    const sbBadge = $('#sb-fav-badge');
    if (sbBadge) {
      sbBadge.textContent = n;
      sbBadge.classList.toggle('hidden', n === 0);
    }
    // Bottom nav badge
    const bnBadge = $('#bn-fav-badge');
    if (bnBadge) {
      bnBadge.textContent = n;
      bnBadge.classList.toggle('hidden', n === 0);
    }
  },

  /* ═══════════════════════════════════════
     SEARCH
  ═══════════════════════════════════════ */
  async doSearch(query) {
    query = query.trim();
    if (!query) return;

    const searchIn = $('#search-username');
    searchIn.value = query;
    $('#search-big-clear').classList.remove('hidden');

    // Hide recent searches, show results section
    $('#recent-searches-section').classList.add('hidden');
    this._hideAllSearchStates();
    $('#search-results-section').classList.remove('hidden');
    $('#search-loading').classList.remove('hidden');
    $('#search-results-title').textContent = `Profil : ${query}`;

    try {
      const data = await API.getInfo(query);
      const user = data.user;
      if (!user) throw new Error('Profil introuvable');

      Recent.add(user.name);
      this.renderRecentSearches();

      $('#search-loading').classList.add('hidden');
      this._renderSearchResult(user);
    } catch (e) {
      $('#search-loading').classList.add('hidden');
      if (e.message?.includes('User not found') || e.message?.includes('No user')) {
        $('#search-not-found').classList.remove('hidden');
      } else {
        $('#search-error').classList.remove('hidden');
        $('#search-error-msg').textContent = e.message || 'Erreur lors de la recherche.';
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

    const html = `
      <div class="fr-result-cards">
        <div class="fr-profile-card" id="search-result-main" data-username="${escHtml(user.name)}">
          ${av
            ? `<img class="fr-profile-av" src="${escHtml(av)}" alt="${escHtml(user.name)}" loading="lazy">`
            : `<div class="fr-profile-av" style="background:${this._nameColor(user.name)};display:flex;align-items:center;justify-content:center;font-size:1.5rem;font-weight:700;color:#fff">${user.name.charAt(0).toUpperCase()}</div>`}
          <div class="fr-profile-body">
            <div class="fr-profile-name">
              ${escHtml(user.name)}
              ${user.subscriber==='1'?'<i class="fas fa-crown" style="color:#f59e0b;font-size:.7rem" title="Subscriber"></i>':''}
            </div>
            ${user.realname ? `<div class="fr-profile-realname">${escHtml(user.realname)}</div>` : ''}
            <div class="fr-profile-stats">
              <span class="fr-profile-stat"><i class="fas fa-music"></i><strong>${fmt(user.playcount)}</strong> scrobbles</span>
              ${user.country ? `<span class="fr-profile-stat"><i class="fas fa-map-marker-alt"></i>${escHtml(user.country)}</span>` : ''}
              ${user.registered?.['#text'] ? `<span class="fr-profile-stat"><i class="fas fa-calendar-alt"></i>Depuis ${escHtml(String(user.registered['#text']).split(', ').pop() || String(user.registered['#text']))}</span>` : ''}
            </div>
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

    $('#search-results-list').innerHTML = html;

    // Open full profile modal
    $('#search-open-full-btn')?.addEventListener('click', () => {
      this.openProfileModal(user.name);
    });

    // Fav button
    $('#search-fav-btn')?.addEventListener('click', () => {
      const btn  = $('#search-fav-btn');
      const icon = $('i', btn);
      const added = Favs.toggle(info);
      btn.classList.toggle('fav-active', added);
      btn.title = added ? 'Retirer des favoris' : 'Ajouter aux favoris';
      if (icon) icon.className = added ? 'fas fa-star' : 'far fa-star';
      this.updateFavBadge();
      this.showToast(added ? '⭐ Ajouté aux favoris' : 'Retiré des favoris', added ? 'success' : '');
    });

    // Expand stats button
    let expanded = false;
    $('#search-expand-btn')?.addEventListener('click', async () => {
      if (expanded) return;
      expanded = true;
      const btn = $('#search-expand-btn');
      btn.innerHTML = '<i class="fas fa-circle-notch fa-spin"></i> Chargement…';
      btn.disabled  = true;

      try {
        const [artists, tracks, albums] = await Promise.all([
          API.getTopArtists(user.name, 'overall', 5),
          API.getTopTracks(user.name, 'overall', 5),
          API.getTopAlbums(user.name, 'overall', 3),
        ]);
        this._renderAdvancedDetail(user.name, artists, tracks, albums);
        btn.innerHTML = '<i class="fas fa-check"></i> Chargé';
      } catch {
        btn.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Erreur';
        btn.disabled  = false;
        expanded      = false;
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
          ? `<img src="${escHtml(imgSrc)}" alt="" loading="lazy" style="width:36px;height:36px;border-radius:4px;object-fit:cover;flex-shrink:0">`
          : `<div style="width:36px;height:36px;border-radius:4px;background:${this._nameColor(getName(item))};display:flex;align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.8rem;flex-shrink:0">${getName(item).charAt(0)}</div>`;
        return `
          <div class="fm-top-row">
            <span class="fm-top-rank">${idx+1}</span>
            ${imgEl}
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
          <div class="fm-tops">
            ${buildList(Array.isArray(artists)?artists:[artists], a=>imgUrl(a.image), a=>a.name, ()=>'', a=>a.playcount)}
          </div>
        </div>
        <div class="fr-detail-section">
          <div class="fr-detail-label"><i class="fas fa-music"></i> Top Morceaux</div>
          <div class="fm-tops">
            ${buildList(Array.isArray(tracks)?tracks:[tracks], t=>imgUrl(t.image), t=>t.name, t=>t.artist?.name||'', t=>t.playcount)}
          </div>
        </div>
        <div class="fr-detail-section" style="margin-bottom:0">
          <div class="fr-detail-label"><i class="fas fa-compact-disc"></i> Top Albums</div>
          <div class="fm-tops">
            ${buildList(Array.isArray(albums)?albums:[albums], a=>imgUrl(a.image), a=>a.name, a=>a.artist?.name||'', a=>a.playcount)}
          </div>
        </div>
        <div style="margin-top:14px;display:flex;gap:8px;flex-wrap:wrap">
          <a href="index.html?user=${encodeURIComponent(username)}"
             class="fm-btn fm-btn-primary" style="text-decoration:none;flex:0 0 auto">
            <i class="fas fa-chart-line"></i> Voir dans LastStats
          </a>
        </div>
      </div>`;

    const detail = $('#search-advanced-detail');
    detail.innerHTML = html;
    detail.classList.remove('hidden');
  },

  _hideAllSearchStates() {
    ['search-loading','search-not-found','search-error'].forEach(id => $('#'+id)?.classList.add('hidden'));
    $('#search-results-list').innerHTML = '';
  },

  /* ── Recent searches ── */
  renderRecentSearches() {
    const list  = Recent.load();
    const el    = $('#recent-searches-list');
    const empty = $('#recent-empty');

    if (!list.length) {
      el.innerHTML = '';
      empty.classList.remove('hidden');
      return;
    }
    empty.classList.add('hidden');

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
          $('#search-username').value = u;
          $('#search-big-clear').classList.remove('hidden');
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
    $('#search-results-section').classList.add('hidden');
    $('#recent-searches-section').classList.remove('hidden');
    this.renderRecentSearches();
  },

  /* ═══════════════════════════════════════
     PROFILE MODAL
  ═══════════════════════════════════════ */
  async openProfileModal(username) {
    const overlay = $('#profile-modal-overlay');
    const body    = $('#profile-modal-body');

    body.innerHTML = `
      <div style="padding:80px 24px;display:flex;align-items:center;justify-content:center;gap:12px;color:var(--text-muted)">
        <i class="fas fa-circle-notch fa-spin" style="color:var(--accent)"></i>
        Chargement du profil…
      </div>`;
    overlay.classList.remove('hidden');
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
            ? `<img class="fm-top-img" src="${escHtml(imgSrc)}" alt="" loading="lazy">`
            : `<div class="fm-top-img" style="background:${this._nameColor(getName(item))};display:flex;align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:.8rem">${getName(item).charAt(0)}</div>`;
          return `
            <div class="fm-top-row">
              <span class="fm-top-rank">${idx+1}</span>
              ${imgEl}
              <div class="fm-top-info">
                <div class="fm-top-name">${escHtml(getName(item))}</div>
                ${getSub(item) ? `<div class="fm-top-sub">${escHtml(getSub(item))}</div>` : ''}
              </div>
              <span class="fm-top-plays">${fmt(getPlays(item))}</span>
            </div>`;
        }).join('');

      body.innerHTML = `
        <div class="fm-hero">
          <div class="fm-hero-bg" style="${av?`background-image:url('${escHtml(av)}')`:''}"></div>
          <div class="fm-hero-overlay"></div>
          <div class="fm-hero-content">
            ${av
              ? `<img class="fm-av" src="${escHtml(av)}" alt="${escHtml(user.name)}">`
              : `<div class="fm-av" style="background:${this._nameColor(user.name)};display:flex;align-items:center;justify-content:center;font-size:1.8rem;font-weight:700;color:#fff">${user.name.charAt(0).toUpperCase()}</div>`}
            <div style="display:flex;align-items:center;gap:8px">
              <span class="fm-name">${escHtml(user.name)}</span>
              ${isLive ? '<span style="background:rgba(34,197,94,.2);border:1px solid rgba(34,197,94,.4);color:#22c55e;font-size:.65rem;font-weight:700;padding:3px 8px;border-radius:99px;letter-spacing:.06em">● LIVE</span>' : ''}
              ${user.subscriber==='1'?'<i class="fas fa-crown" style="color:#f59e0b" title="Subscriber"></i>':''}
            </div>
            ${user.realname ? `<div style="font-size:.78rem;color:rgba(255,255,255,.65)">${escHtml(user.realname)}</div>` : ''}
            ${user.country  ? `<div class="fm-country"><i class="fas fa-map-marker-alt" style="margin-right:3px"></i>${escHtml(user.country)}</div>` : ''}
          </div>
        </div>

        <div class="fm-body">

          ${isLive && liveStatus ? `
          <div class="fr-np-bar" style="margin-bottom:14px">
            ${liveStatus.art ? `<img class="fr-np-art" src="${escHtml(liveStatus.art)}" alt="" loading="lazy">` : ''}
            <div class="fr-np-info">
              <div class="fr-np-track">${escHtml(liveStatus.track)}</div>
              <div class="fr-np-artist">${escHtml(liveStatus.artist)}</div>
            </div>
            <div class="fr-np-icon"><span></span><span></span><span></span><span></span></div>
          </div>` : ''}

          <div class="fm-stats-row">
            <div class="fm-stat-chip">
              <i class="fas fa-music"></i>
              <strong>${fmt(user.playcount)}</strong>
              <span>scrobbles</span>
            </div>
            <div class="fm-stat-chip">
              <i class="fas fa-user-friends"></i>
              <strong>${fmt(user.playlists || 0)}</strong>
              <span>playlists</span>
            </div>
            <div class="fm-stat-chip">
              <i class="fas fa-calendar-alt"></i>
              <strong>${user.registered?.['#text'] ? String(user.registered['#text']).split(', ').pop() || '—' : '—'}</strong>
              <span>inscrit</span>
            </div>
          </div>

          <div style="font-size:.78rem;font-weight:700;color:var(--accent);text-transform:uppercase;letter-spacing:.05em;margin-bottom:8px;display:flex;align-items:center;gap:6px">
            <i class="fas fa-microphone-alt"></i> Top Artistes (all time)
          </div>
          <div class="fm-tops" style="margin-bottom:16px">
            ${buildTop(artists, a=>imgUrl(a.image), a=>a.name, ()=>'', a=>a.playcount)}
          </div>

          <div style="font-size:.78rem;font-weight:700;color:var(--accent);text-transform:uppercase;letter-spacing:.05em;margin-bottom:8px;display:flex;align-items:center;gap:6px">
            <i class="fas fa-music"></i> Top Morceaux (all time)
          </div>
          <div class="fm-tops" style="margin-bottom:16px">
            ${buildTop(tracks, t=>imgUrl(t.image), t=>t.name, t=>t.artist?.name||'', t=>t.playcount)}
          </div>

          <div class="fm-actions">
            <a href="index.html?user=${encodeURIComponent(user.name)}" target="_blank" rel="noopener"
               class="fm-btn fm-btn-primary" style="text-decoration:none">
              <i class="fas fa-chart-line"></i> Stats complètes
            </a>
            <button class="fm-btn fm-btn-outline${isFav?' fav-active':''}" id="modal-fav-btn">
              <i class="fa${isFav?'s':'r'} fa-star"></i> ${isFav ? 'Favori' : 'Favori'}
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
        btn.classList.toggle('fav-active', added);
        const icon = $('i', btn);
        if (icon) icon.className = added ? 'fas fa-star' : 'far fa-star';
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
        </div>`;
    }
  },

  closeModal() {
    $('#profile-modal-overlay').classList.add('hidden');
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
          <div class="sk-ln w70 mt4"></div>
          <div class="sk-ln w50 mt8"></div>
          <div class="sk-ln w80 mt8"></div>
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
