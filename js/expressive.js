// M3 Expressive press feedback: keeps the "pressed" shape visible for at least a
// moment so even a quick tap shows the morph (CSS :active alone flashes too fast).
(function () {
  const SEL = '.project-actions a, .project-actions button, .contact-links a, .about-cta, ' +
    '.lang-toggle, .theme-toggle, .nav-logo, .back-link, .help-external-link, .dl-option, .dl-back, .cm-btn, .cm-sha, .feature-chips span, .project-tags span, ' +
    '.footer .footer-links.footer-buttons a, .rel-filter-btn, .rel-gh, .rel-more, .rel-toggle, .rel-asset, .rel-plat-sum, .cm-tr-btn, .color-random, .m3-carousel-btn';
  document.addEventListener('pointerdown', (e) => {
    const el = e.target.closest(SEL);
    if (!el) return;
    el.classList.add('is-pressed');
    // release once, then drop all three listeners (a leftover pointerleave
    // listener used to cut short the pressed shape of the next press)
    const events = ['pointerup', 'pointercancel', 'pointerleave'];
    const release = () => {
      events.forEach((ev) => el.removeEventListener(ev, release));
      setTimeout(() => el.classList.remove('is-pressed'), 140);
    };
    events.forEach((ev) => el.addEventListener(ev, release));
  });
})();


// Hero grid vibration: tiny buzz while the pointer moves over the header, a thump on press.
(function () {
  var grid = document.querySelector('.project-hero-grid');
  var head = grid && grid.parentElement;
  if (!head || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var idle;
  head.addEventListener('pointermove', function (e) {
    var r = grid.getBoundingClientRect();
    grid.style.setProperty('--mx', (e.clientX - r.left) + 'px');
    grid.style.setProperty('--my', (e.clientY - r.top) + 'px');
    if (grid.classList.contains('is-press')) return;
    grid.classList.add('is-hover');
  });
  head.addEventListener('pointerleave', function () { clearTimeout(idle); grid.classList.remove('is-hover'); });
  head.addEventListener('pointerdown', function (e) {
    var r = grid.getBoundingClientRect();
    grid.style.setProperty('--mx', (e.clientX - r.left) + 'px');
    grid.style.setProperty('--my', (e.clientY - r.top) + 'px');
    grid.classList.remove('is-hover', 'is-press');
    void grid.offsetWidth;
    grid.classList.add('is-press');
  });
  grid.addEventListener('animationend', function (e) { if (e.animationName === 'grid-flash') grid.classList.remove('is-press'); });
})();


// Music (Last.fm, SanoBld): logo becomes a spinning star with moving bars; optional theme colors from the cover.
(function () {
  var grid = document.querySelector('.project-hero-grid');
  var logo = document.querySelector('.project-logo');
  // Public web key (not secret, it is in the page on purpose)
  var URL = 'https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=SanoBld&limit=1&format=json&api_key=d3390e1dcc15a77e5bd2c33bbb488de7';
  var lastId = '';
  var SS = window.sessionStorage;
  function ss(k, v) { try { if (v === undefined) return SS.getItem(k); if (v === null) SS.removeItem(k); else SS.setItem(k, v); } catch (e) {} return null; }
  lastId = ss('music-id') || '';
  function hashHue(str) { var h = 0; for (var i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) >>> 0; return h % 360; }
  // Main hue of the cover (small canvas); falls back to a hue from the title if the image is blocked
  function coverHue(url, fallback, cb) {
    if (!url || url.indexOf('2a96cbd8b46e442fc41c2b86b821562f') > -1) return cb(fallback);
    var img = new Image(); img.crossOrigin = 'anonymous';
    img.onload = function () {
      try {
        var c = document.createElement('canvas'); c.width = c.height = 32;
        var x = c.getContext('2d'); x.drawImage(img, 0, 0, 32, 32);
        // Most common vivid hue (36 bins of 10 degrees, weighted by saturation x brightness), then a fine mean around it
        var d = x.getImageData(0, 0, 32, 32).data, bins = [], i, k;
        for (k = 0; k < 36; k++) bins.push(0);
        var px = [];
        for (i = 0; i < d.length; i += 4) {
          var r = d[i] / 255, g = d[i + 1] / 255, b = d[i + 2] / 255;
          var mx = Math.max(r, g, b), mn = Math.min(r, g, b), df = mx - mn, s = mx ? df / mx : 0;
          if (s < .2 || mx < .2) continue;
          var h = 0;
          if (mx === r) h = ((g - b) / df + 6) % 6; else if (mx === g) h = (b - r) / df + 2; else h = (r - g) / df + 4;
          h *= 60;
          var w = s * mx; px.push([h, w]); bins[Math.floor(h / 10) % 36] += w;
        }
        if (!px.length) return cb(fallback);
        var best = 0;
        for (k = 1; k < 36; k++) if (bins[k] + (bins[(k + 1) % 36] + bins[(k + 35) % 36]) * .5 > bins[best] + (bins[(best + 1) % 36] + bins[(best + 35) % 36]) * .5) best = k;
        var cx = best * 10 + 5, sx = 0, sy = 0;
        px.forEach(function (p) {
          var dd = Math.abs(((p[0] - cx + 540) % 360) - 180);
          if (dd <= 20) { sx += Math.cos(p[0] * Math.PI / 180) * p[1]; sy += Math.sin(p[0] * Math.PI / 180) * p[1]; }
        });
        cb((Math.atan2(sy, sx) * 180 / Math.PI + 360) % 360);
      } catch (e) { cb(fallback); }
    };
    img.onerror = function () { cb(fallback); };
    img.src = url;
  }
  var PH = '2a96cbd8b46e442fc41c2b86b821562f';   // Last.fm "no image" placeholder
  // JSONP: no CORS problem (iTunes: callback=..., Deezer: output=jsonp&callback=...)
  function jsonp(url, cb) {
    var n = '__lsj' + Date.now() + Math.floor(Math.random() * 1e5), s = document.createElement('script'), done = false;
    function end(d) { if (done) return; done = true; try { delete window[n]; } catch (e) { window[n] = undefined; } if (s.parentNode) s.parentNode.removeChild(s); cb(d); }
    window[n] = end; s.onerror = function () { end(null); };
    s.src = url + (url.indexOf('?') > -1 ? '&' : '?') + 'callback=' + n;
    document.head.appendChild(s);
    setTimeout(function () { end(null); }, 7000);
  }
  // Cover url, same idea as the app (image_service.dart): iTunes, then Deezer (artist AND title must match), then the Last.fm image.
  function norm(x) { return String(x || '').toLowerCase().replace(/\(.*?\)|\[.*?\]/g, '').replace(/[^a-z0-9]+/g, ''); }
  function like(a, b) { a = norm(a); b = norm(b); return !!a && !!b && (a === b || a.indexOf(b) > -1 || b.indexOf(a) > -1); }
  function findCover(t, cb) {
    var imgs = t.image || [], u = imgs.length ? imgs[imgs.length - 1]['#text'] : '';
    var artist = t.artist['#text'] || '', title = t.name || '';
    var fallback = (u && u.indexOf(PH) < 0) ? u : '';
    var q = encodeURIComponent(artist + ' ' + title);
    jsonp('https://itunes.apple.com/search?media=music&entity=song&limit=8&term=' + q, function (d) {
      var res = (d && d.results) || [];
      for (var i = 0; i < res.length; i++) {
        if (like(artist, res[i].artistName) && like(title, res[i].trackName) && res[i].artworkUrl100)
          return cb(res[i].artworkUrl100.replace('100x100', '600x600'));
      }
      jsonp('https://api.deezer.com/search/track?limit=10&output=jsonp&q=' + q, function (d2) {
        var it = (d2 && d2.data) || [];
        for (var j = 0; j < it.length; j++) {
          var al = it[j].album || {};
          if (like(title, it[j].title) && like(artist, it[j].artist && it[j].artist.name) && (al.cover_xl || al.cover_big))
            return cb(al.cover_xl || al.cover_big);
        }
        cb(fallback);
      });
    });
  }
  var head = grid && grid.parentElement;
  var playing = false, covers = [], idx = -1, curUrl = '', timer = null, started = false;
  // Everything here only runs when the option "colors from the music" is ON (no calls, no animation otherwise)
  function enabled() { try { return localStorage.getItem('accent-music') === '1'; } catch (e) { return false; } }
  function showCover() { covers.forEach(function (c, i) { if (c) c.classList.toggle('is-on', playing && i === idx && !!curUrl); }); }
  function set(on) {
    playing = on;
    if (grid) grid.classList.toggle('is-playing', on);
    if (logo) logo.classList.toggle('is-playing', on);
    showCover();
  }
  function mkCover() {
    var c = document.createElement('div');
    c.className = 'project-hero-bg project-hero-cover';
    c.setAttribute('aria-hidden', 'true');
    head.insertBefore(c, grid);
    return c;
  }
  // Very blurred cover behind the cells; a new cover cross-fades with the old one (same speed as the color change)
  function setCover(url, instant) {
    if (!head || !grid) return;
    if (!url) { curUrl = ''; showCover(); return; }
    if (url === curUrl) { showCover(); return; }
    curUrl = url;
    var im = new Image();
    im.onload = function () {
      if (curUrl !== url) return;
      var n = idx === 0 ? 1 : 0;
      if (!covers[n]) covers[n] = mkCover();
      var c = covers[n];
      c.style.backgroundImage = 'url("' + url + '")';
      if (instant) c.style.transition = 'none';
      idx = n; showCover();
      if (instant) { void c.offsetWidth; c.style.transition = ''; }
    };
    im.src = url;
  }
  function check() {
    if (document.hidden || !enabled()) return;
    fetch(URL).then(function (r) { return r.json(); }).then(function (d) {
      if (!started) return;
      var t = d && d.recenttracks && d.recenttracks.track;
      t = Array.isArray(t) ? t[0] : t;
      var on = !!(t && t['@attr'] && t['@attr'].nowplaying === 'true');
      set(on);
      ss('music-on', on ? '1' : '0');
      var am = window.accentMusic;
      if (!on) { lastId = ''; ss('music-id', null); ss('music-cover', null); setCover(''); if (am) am.clear(); return; }
      var id = (t.artist['#text'] || '') + '|' + t.name;
      var same = (id === lastId);
      var keep = same && window.__musicHue !== undefined;   // same track after navigation: keep the color, no animation
      if (same && ss('music-cover')) { setCover(ss('music-cover')); if (keep) return; }
      findCover(t, function (url) {
        if (!started) return;
        ss('music-cover', url || null); setCover(url);
        if (!am || keep) return;
        lastId = id; ss('music-id', id);
        coverHue(url, hashHue(id), function (h) { am.show(h, same); });
      });
    }).catch(function () {});
  }
  function start() {
    if (started || !grid) return;
    started = true;
    // Coming from another page: show the playing look at once, no fade-in (no pop at load)
    var root = document.documentElement;
    if (ss('music-on') === '1') {
      root.classList.add('ls-init');
      set(true); setCover(ss('music-cover') || '', true);
      requestAnimationFrame(function () { requestAnimationFrame(function () { setTimeout(function () { root.classList.remove('ls-init'); }, 60); }); });
    }
    check();
    timer = setInterval(check, 30000);
    document.addEventListener('visibilitychange', check);
  }
  function stop() {
    if (!started) return;
    started = false;
    clearInterval(timer);
    document.removeEventListener('visibilitychange', check);
    set(false); setCover('');
    covers.forEach(function (c) { if (c && c.parentNode) setTimeout(function () { c.parentNode && c.parentNode.removeChild(c); }, 1000); });
    covers = []; idx = -1; curUrl = ''; lastId = '';
    ss('music-on', null); ss('music-id', null); ss('music-cover', null);
    if (window.accentMusic) window.accentMusic.clear();
  }
  window.addEventListener('accent-music-change', function (e) { if (e.detail) start(); else stop(); });
  if (enabled()) start();
})();
