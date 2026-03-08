/* ============================================================
   LastStats — Service Worker v7
   Stratégie : Cache-first pour assets statiques
               Network-first pour appels API Last.fm
   Mis à jour : v7 — support force-update, nouvelles sections
   ============================================================ */

const CACHE_NAME    = 'laststats-v7';
const STATIC_ASSETS = [
  './',
  './index.html',
  './style.css',
  './script.js',
  './manifest.json',
];

/* ── Installation : mise en cache des assets statiques ── */
self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

/* ── Activation : suppression des anciens caches ── */
self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then(keys =>
        Promise.all(
          keys
            .filter(k => k !== CACHE_NAME)
            .map(k => caches.delete(k))
        )
      )
      .then(() => self.clients.claim())
  );
});

/* ── Message : force-update depuis le client ── */
self.addEventListener('message', (e) => {
  if (e.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  if (e.data === 'CLEAR_CACHE') {
    caches.keys().then(keys => Promise.all(keys.map(k => caches.delete(k))));
  }
});

/* ── Interception des requêtes ── */
self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);

  /* API Last.fm → Network first, jamais mis en cache (données live) */
  if (url.hostname === 'ws.audioscrobbler.com') {
    e.respondWith(
      fetch(e.request).catch(() =>
        new Response('{"error":503,"message":"Service indisponible"}', {
          headers: { 'Content-Type': 'application/json' },
        })
      )
    );
    return;
  }

  /* CDN externes (Chart.js, D3, FontAwesome, html2canvas…) → Cache first */
  if (url.hostname !== location.hostname && url.hostname !== '') {
    e.respondWith(
      caches.match(e.request).then(cached =>
        cached ||
        fetch(e.request).then(res => {
          if (!res || res.status !== 200 || res.type === 'opaqueredirect') return res;
          const clone = res.clone();
          caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
          return res;
        })
      )
    );
    return;
  }

  /* Fichiers locaux (index.html, style.css, script.js…) → Network first avec fallback cache */
  /* Stratégie network-first pour que les mises à jour soient immédiatement visibles */
  e.respondWith(
    fetch(e.request)
      .then(res => {
        if (!res || res.status !== 200) return res;
        const clone = res.clone();
        caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
        return res;
      })
      .catch(() => caches.match(e.request))
  );
});
