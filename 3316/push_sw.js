/* Twake Chat — service worker: Web Push (RFC 8030) + precache.
 *
 * PUSH. Pusher is event_id_only (same privacy contract as mobile): the push
 * carries NO message content — only event_id/room_id. The SW shows a generic
 * notification; the app fetches the content when the user clicks it. No message
 * content ever transits the push service. Sygnal's events_only flag suppresses
 * content-less count-clear pushes, so every push maps to a real event
 * (satisfies userVisibleOnly).
 *
 * PRECACHE. Flutter does not content-hash its build output, so an HTTP cache
 * cannot be used to serve it: every asset would either revalidate on each load
 * or go stale forever. The invalidation mechanism is this manifest instead — a
 * path/MD5 map regenerated at every build, diffed on activation. Flutter used to
 * ship exactly this as flutter_service_worker.js; it was removed in 3.39
 * (flutter/flutter#176834), which is why the logic lives here now.
 *
 * ONE SCOPE, ONE WORKER. A scope can only be controlled by a single service
 * worker, so push and precache have to share this file. Do not add a second
 * registration under /web/: it would silently replace this one.
 *
 * ponytail: no JS test harness in this Flutter repo.
 */

'use strict';

// Injected at build time by scripts/generate-sw-manifest.py. Left empty here on
// purpose: an unbuilt worker must not pretend to hold a cache. With an empty
// manifest every fetch falls through to the network, which is exactly the
// behaviour we had before precaching existed.
const RESOURCES = /*{{TWAKE_PRECACHE_RESOURCES}}*/ {};
const CORE = /*{{TWAKE_PRECACHE_CORE}}*/ [];

const CACHE_NAME = 'twake-chat-cache';
const TEMP = 'twake-chat-cache-temp';
const MANIFEST = 'twake-chat-manifest';

/// Path of [url] relative to this worker's scope, or null when out of scope.
/// Keys in RESOURCES are scope-relative, so this must not assume the app is
/// served from the origin root: it is deployed under /web/.
function resourceKey(url) {
  const scope = self.registration.scope;
  if (!url.startsWith(scope)) return null;
  const key = url.substring(scope.length);
  return key === '' ? '/' : key;
}

// skipWaiting is required: without it a new SW version installs but stays in
// `waiting` behind the old active worker while any tab is open, so users get
// stuck on a stale worker until they manually unregister it (DevTools).
// CORE is fetched with {cache:'reload'} so the app shell bypasses the HTTP
// cache and we never install a new manifest against stale bytes.
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

// Populate the content cache from the shell downloaded during install, keeping
// every resource whose MD5 did not move since the previous manifest.
self.addEventListener('activate', function (event) {
  event.waitUntil(
    (async function () {
      try {
        var contentCache = await caches.open(CACHE_NAME);
        const tempCache = await caches.open(TEMP);
        const manifestCache = await caches.open(MANIFEST);
        const manifest = await manifestCache.match('manifest');

        if (!manifest) {
          // First install: nothing to diff against, start from a clean cache.
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
          // Evict what the new build dropped or changed; the rest is reused.
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
        // A half-written cache is worse than none: drop everything and let the
        // next load repopulate from the network.
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

  const key = resourceKey(event.request.url);
  // Out of scope, or not a precached resource (config.json is deliberately
  // excluded from the manifest: it is injected at deploy time, not at build
  // time). Let the browser handle it — nginx serves it with `no-cache`.
  if (key === null || !RESOURCES[key]) return;

  // index.html carries the manifest version, so it must never be served from
  // cache while the network is reachable, or a deploy would never be noticed.
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
        // Offline: fall back to the last shell we saw.
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
  // VAPID string directly. config.json is never precached, so this always
  // reads the deployed values.
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
