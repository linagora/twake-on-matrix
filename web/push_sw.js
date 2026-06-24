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
    self.registration.showNotification('Twake Chat', {
      body: 'New message',
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      tag: roomId || 'twake-message',
      renotify: true,
      data: { roomId: roomId },
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
