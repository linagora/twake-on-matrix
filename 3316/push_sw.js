/* Twake Chat — service worker: Web Push (RFC 8030) + precache.
 *
 * Pusher is event_id_only (same privacy contract as mobile): the push carries
 * NO message content — only event_id/room_id. The SW shows a generic
 * notification; the app fetches the content when the user clicks it. Sygnal's
 * events_only flag suppresses content-less count-clear pushes, so every push
 * maps to a real event (satisfies userVisibleOnly).
 *
 * A scope can only be controlled by a single service worker, so push and
 * precache share this file. Do not add a second registration under /web/: it
 * would silently replace this one.
 *
 * ponytail: no JS test harness in this Flutter repo.
 */

'use strict';

// Injected at build time by scripts/generate-sw-manifest.py. Empty on purpose:
// an unbuilt worker falls through to the network rather than breaking.
const RESOURCES = /*{{TWAKE_PRECACHE_RESOURCES}}*/ {};
const CORE = /*{{TWAKE_PRECACHE_CORE}}*/ [];

const CACHE_NAME = 'twake-chat-cache';
const TEMP = 'twake-chat-cache-temp';
const MANIFEST = 'twake-chat-manifest';

// Keys in RESOURCES are scope-relative: the app is deployed under /web/, not at
// the origin root.
function resourceKey(url) {
  const scope = self.registration.scope;
  if (!url.startsWith(scope)) return null;
  const key = url.substring(scope.length);
  return key === '' ? '/' : key;
}

// skipWaiting is required: without it a new version stays in `waiting` behind
// the old worker while any tab is open. CORE uses {cache:'reload'} so a new
// manifest is never installed against stale bytes.
self.addEventListener('install', function (event) {
  self.skipWaiting();
  event.waitUntil(
    caches.open(TEMP).then(function (cache) {
      return cache.addAll(
        CORE.map(function (value) {
          return new Request(value, { cache: 'reload' });
        })
      );
    })
  );
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    (async function () {
      try {
        var contentCache = await caches.open(CACHE_NAME);
        const tempCache = await caches.open(TEMP);
        const manifestCache = await caches.open(MANIFEST);
        const manifest = await manifestCache.match('manifest');

        if (!manifest) {
          await caches.delete(CACHE_NAME);
          contentCache = await caches.open(CACHE_NAME);
          for (const request of await tempCache.keys()) {
            const response = await tempCache.match(request);
            await contentCache.put(request, response);
          }
          await caches.delete(TEMP);
          await manifestCache.put(
            'manifest',
            new Response(JSON.stringify(RESOURCES))
          );
          await self.clients.claim();
          return;
        }

        const oldManifest = await manifest.json();
        for (const request of await contentCache.keys()) {
          const key = resourceKey(request.url);
          if (key === null || !RESOURCES[key] ||
              RESOURCES[key] !== oldManifest[key]) {
            await contentCache.delete(request);
          }
        }
        for (const request of await tempCache.keys()) {
          const response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        await manifestCache.put(
          'manifest',
          new Response(JSON.stringify(RESOURCES))
        );
        await self.clients.claim();
      } catch (error) {
        // A half-written cache is worse than none.
        console.log('[Twake Chat] service worker activation failed: ', error);
        await caches.delete(CACHE_NAME);
        await caches.delete(TEMP);
        await caches.delete(MANIFEST);
      }
    })()
  );
});

self.addEventListener('fetch', function (event) {
  if (event.request.method !== 'GET') return;

  // config.json is deliberately absent from RESOURCES: it is injected at deploy
  // time, so it must always come from the network.
  const key = resourceKey(event.request.url);
  if (key === null || !RESOURCES[key]) return;

  // Serving index.html from cache would hide a deploy.
  if (key === '/') return onlineFirst(event);

  event.respondWith(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.match(event.request).then(function (response) {
        return (
          response ||
          fetch(event.request).then(function (fetched) {
            if (fetched && fetched.ok) cache.put(event.request, fetched.clone());
            return fetched;
          })
        );
      });
    })
  );
});

function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request)
      .then(function (response) {
        return caches.open(CACHE_NAME).then(function (cache) {
          cache.put(event.request, response.clone());
          return response;
        });
      })
      .catch(function (error) {
        return caches.open(CACHE_NAME).then(function (cache) {
          return cache.match(event.request).then(function (response) {
            if (response != null) return response;
            throw error;
          });
        });
      })
  );
}

self.addEventListener('push', function (event) {
  var data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {
    data = {};
  }
  // event_id_only: Sygnal flattens the payload, so we get { event_id, room_id,
  // counts, ... } plus the pusher's default_payload merged in at top level.
  // title/body come from default_payload — generic, app-localized strings set
  // at registration in the account language (NOT message content). Fall back to
  // English constants if absent (e.g. a pre-default_payload pusher).
  var n = data.notification || data || {};
  var roomId = n.room_id || '';
  var eventId = n.event_id || '';
  var title = n.title || 'Twake Chat';
  var body = n.body || 'New message';

  // The SW is the single notification owner on web (foreground + background).
  // Always show; the event_id tag dedupes repeats/retries of the same event.
  event.waitUntil(
    self.registration.showNotification(title, {
      body: body,
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      tag: eventId || roomId || 'twake-message',
      renotify: true,
      data: { roomId: roomId, eventId: eventId },
    })
  );
});

self.addEventListener('pushsubscriptionchange', function (event) {
  // Endpoint rotated (expiry/reset). Re-subscribe so pushes keep arriving;
  // the Matrix pusher is re-synced by setupWebPush on the next app open
  // (it drops the stale pusher). applicationServerKey accepts the base64url
  // VAPID string directly.
  event.waitUntil(
    fetch('config.json')
      .then(function (r) { return r.json(); })
      .then(function (cfg) {
        if (!cfg || !cfg.vapid_public_key) return;
        return self.registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: cfg.vapid_public_key,
        });
      })
      .catch(function (error) {
        console.log('[Twake Chat] pushsubscriptionchange re-subscribe failed: ', error);
      })
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var roomId = (event.notification.data || {}).roomId || '';
  var target = roomId ? '/#/rooms/' + roomId : '/';

  event.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(function (clientList) {
        for (var i = 0; i < clientList.length; i++) {
          var client = clientList[i];
          if ('focus' in client) {
            if (roomId && 'navigate' in client) client.navigate(target);
            return client.focus();
          }
        }
        if (self.clients.openWindow) return self.clients.openWindow(target);
      })
  );
});
