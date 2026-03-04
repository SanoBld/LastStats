/* ============================================================
   LastStats — Service Worker v4
   Stratégie : Cache-first pour assets statiques
               Network-first pour appels API Last.fm
   ============================================================ */
const CACHE_NAME    = 'laststats-v4';
const STATIC_ASSETS = [
  './',
  './index.html',
  './style.css',
  './script.js',
  './manifest.json',
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);

  // API Last.fm → Network first, pas de cache (données dynamiques)
  if (url.hostname === 'ws.audioscrobbler.com') {
    e.respondWith(fetch(e.request).catch(() => new Response('{"error":503}', { headers: { 'Content-Type': 'application/json' } })));
    return;
  }

  // CDN externes (Chart.js, D3, FontAwesome…) → Cache first
  if (url.hostname !== location.hostname && url.hostname !== '') {
    e.respondWith(
      caches.match(e.request).then(cached =>
        cached || fetch(e.request).then(res => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
          return res;
        })
      )
    );
    return;
  }

  // Fichiers locaux → Cache first avec fallback réseau
  e.respondWith(
    caches.match(e.request)
      .then(cached => cached || fetch(e.request).then(res => {
        const clone = res.clone();
        caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
        return res;
      }))
  );
});
