'use strict';

const CACHE_VERSION = 'v9';
const CACHE_NAME    = `laststats-${CACHE_VERSION}`;
const IMG_CACHE     = `laststats-img-${CACHE_VERSION}`;
const IMG_MAX       = 100;

const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './style.css',
  './script.js',
  './i18n.js',
  './manifest.json',
  'https://cdn.jsdelivr.net/npm/chart.js',
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ASSETS_TO_CACHE))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(k => k !== CACHE_NAME && k !== IMG_CACHE)
          .map(k => caches.delete(k))
      )
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('message', event => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();

  if (event.data === 'CLEAR_CACHE') {
    caches.keys().then(keys => keys.forEach(k => caches.delete(k)));
  }

  if (event.data?.type === 'SHOW_NOTIFICATION') {
    const { title, body, tag } = event.data;
    self.registration.showNotification(title, {
      body,
      tag:   tag || 'laststats-wrapped',
      icon:  './icons/icon-192.png',
      badge: './icons/icon-32.png',
      data:  { url: 'https://sanobld.github.io/LastStats/#s-wrapped' },
      requireInteraction: false,
      vibrate: [200, 100, 200],
    });
  }
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  const target = event.notification.data?.url || 'https://sanobld.github.io/LastStats/#s-wrapped';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const client of list) {
        if (client.url.startsWith('https://sanobld.github.io/LastStats') && 'focus' in client) {
          client.focus();
          client.navigate(target);
          return;
        }
      }
      if (clients.openWindow) return clients.openWindow(target);
    })
  );
});

/** Evict oldest entries when image cache exceeds IMG_MAX */
async function _trimImgCache() {
  const cache = await caches.open(IMG_CACHE);
  const keys  = await cache.keys();
  if (keys.length > IMG_MAX) {
    await Promise.all(keys.slice(0, keys.length - IMG_MAX).map(k => cache.delete(k)));
  }
}

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Last.fm API — always fresh, graceful offline fallback
  if (url.hostname === 'ws.audioscrobbler.com') {
    event.respondWith(
      fetch(event.request).catch(() =>
        new Response(
          JSON.stringify({ error: 503, message: 'Offline — no network connection' }),
          { status: 503, headers: { 'Content-Type': 'application/json' } }
        )
      )
    );
    return;
  }

  // Album art & Last.fm images — cache-first, capped at IMG_MAX
  if (
    event.request.destination === 'image' ||
    url.hostname.includes('lastfm.freetls.fastly.net')
  ) {
    event.respondWith(
      caches.open(IMG_CACHE).then(async cache => {
        const cached = await cache.match(event.request);
        if (cached) return cached;
        try {
          const response = await fetch(event.request);
          if (response.ok) {
            cache.put(event.request, response.clone());
            _trimImgCache(); // async, non-blocking
          }
          return response;
        } catch {
          return new Response(null, { status: 503 });
        }
      })
    );
    return;
  }

  // App shell — network-first, cache fallback
  event.respondWith(
    fetch(event.request)
      .then(response => {
        if (!response || response.status !== 200) return response;
        caches.open(CACHE_NAME).then(c => c.put(event.request, response.clone()));
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});