/* Twake Chat — Web Push service worker (RFC 8030).
 * Receives pushes from Sygnal (event_id_only format: no message content),
 * shows a generic notification, and routes clicks into the app.
 * ponytail: no JS test harness in this Flutter repo; covered by the manual
 * chrome://discards freeze repro in the plan's acceptance criteria.
 */

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', function (event) {
  var data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {
    data = {};
  }
  // Sygnal event_id_only payload: { notification: { room_id, event_id, counts, ... } }
  var notification = data.notification || {};
  var roomId = notification.room_id || '';

  event.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(function (clientList) {
        // App already open and visible: the in-app foreground notification
        // (showLocalNotification) handles it, so skip the SW notification to
        // avoid a duplicate. Chrome doesn't penalize userVisibleOnly when a
        // visible window is present.
        var appVisible = clientList.some(function (c) {
          return c.visibilityState === 'visible';
        });
        if (appVisible) return;
        return self.registration.showNotification('Twake Chat', {
          body: 'New message',
          icon: 'icons/Icon-192.png',
          badge: 'icons/Icon-192.png',
          tag: roomId || 'twake-message',
          renotify: true,
          data: { roomId: roomId },
        });
      })
  );
});

self.addEventListener('pushsubscriptionchange', function (event) {
  // Endpoint rotated (expiry/reset). Re-subscribe so pushes keep arriving;
  // the Matrix pusher is re-synced by setupWebPush on the next app open
  // (it drops the stale pusher). applicationServerKey accepts the base64url
  // VAPID string directly. ponytail: read the key from config.json so the SW
  // stays config-driven without a build step.
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
