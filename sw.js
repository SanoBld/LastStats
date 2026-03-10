/* ============================================================
   LastStats — Service Worker v8
   Design System : Material You (M3)
   Stratégies : 
     - API & App : Network-First (Priorité données fraîches)
     - Images & Libs : Cache-First (Performance & Data)
   ============================================================ */

const CACHE_NAME = 'laststats-v8';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './style.css',
  './script.js',
  './manifest.json',
  'https://cdn.jsdelivr.net/npm/chart.js' // On met en cache la lib des graphiques
];

// 1. INSTALLATION : Mise en cache initiale
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Mise en cache des ressources critiques');
      return cache.addAll(ASSETS_TO_CACHE);
    }).then(() => self.skipWaiting())
  );
});

// 2. ACTIVATION : Nettoyage des anciens caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter((key) => key !== CACHE_NAME)
            .map((key) => caches.delete(key))
      );
    }).then(() => self.clients.claim())
  );
});

// 3. MESSAGES : Gestion des commandes forcées
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  if (event.data === 'CLEAR_CACHE') {
    caches.keys().then(keys => {
      keys.forEach(key => caches.delete(key));
    });
  }
});

// 4. STRATÉGIES DE REQUÊTES (FETCH)
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // --- A. API LAST.FM (Données Live) ---
  // Stratégie : Network Only (On ne cache jamais les stats qui changent tout le temps)
  if (url.hostname === 'ws.audioscrobbler.com') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return new Response(JSON.stringify({ error: 503, message: 'Hors ligne' }), {
          headers: { 'Content-Type': 'application/json' }
        });
      })
    );
    return;
  }

  // --- B. IMAGES & COVERS (Pochettes d'albums) ---
  // Stratégie : Cache-First (Une pochette d'album ne change jamais, on économise la data)
  if (event.request.destination === 'image' || url.hostname.includes('lastfm.freetls.fastly.net')) {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        return cached || fetch(event.request).then((response) => {
          if (response.ok) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
          }
          return response;
        });
      })
    );
    return;
  }

  // --- C. RESSOURCES LOCALES (HTML, CSS, JS) ---
  // Stratégie : Network-First avec Fallback Cache
  // On veut la version la plus récente du code, mais on affiche le cache si pas de réseau.
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        if (!response || response.status !== 200) return response;
        
        // Mise à jour du cache en arrière-plan
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
        
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});