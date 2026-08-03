'use strict';

const STATIC_CACHE = 'ceosmos-tv-static-v3';
const NETWORK_CACHE = 'ceosmos-tv-network-v1';

// Cache First para los assets propios de la app.
const STATIC_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './css/styles.css',
  './js/app.js',
  './js/grid.js',
  './js/firestore-service.js',
  './js/firebase-config.js',
  './icons/icon-192.png',
  './icons/icon-512.png'
];

// Network First para llamadas a la API / Firestore / CDN de Firebase.
const NETWORK_FIRST_ORIGINS = [
  'https://firestore.googleapis.com',
  'https://firebaseinstallations.googleapis.com',
  'https://www.gstatic.com'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((key) => key !== STATIC_CACHE && key !== NETWORK_CACHE)
            .map((key) => caches.delete(key))
        )
      )
  );
  self.clients.claim();
});

const esSameOrigin = (url) => url.origin === self.location.origin;
const esNetworkFirst = (url) =>
  NETWORK_FIRST_ORIGINS.some((origin) => url.origin === origin);

async function estrategiaCacheFirst(request) {
  const cache = await caches.open(STATIC_CACHE);
  const cached = await cache.match(request);
  if (cached) {
    return cached;
  }
  const response = await fetch(request);
  if (response && response.ok) {
    cache.put(request, response.clone());
  }
  return response;
}

async function estrategiaNetworkFirst(request) {
  const cache = await caches.open(NETWORK_CACHE);
  try {
    const response = await fetch(request);
    if (response && response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await cache.match(request);
    if (cached) {
      return cached;
    }
    throw error;
  }
}

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  const url = new URL(event.request.url);

  if (esNetworkFirst(url)) {
    event.respondWith(estrategiaNetworkFirst(event.request));
  } else if (esSameOrigin(url)) {
    event.respondWith(estrategiaCacheFirst(event.request));
  }
});