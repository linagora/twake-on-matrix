/* Twake Chat — Web Push service worker (RFC 8030).
 * Pusher is event_id_only (same privacy contract as mobile): the push carries
 * NO message content — only event_id/room_id. The SW shows a generic
 * notification; the app fetches the content when the user clicks it. No message
 * content ever transits the push service. Sygnal's events_only flag suppresses
 * content-less count-clear pushes, so every push maps to a real event
 * (satisfies userVisibleOnly).
 * ponytail: no JS test harness in this Flutter repo; covered by the manual
 * chrome://discards freeze repro in the plan's acceptance criteria.
 */

// skipWaiting is required: without it a new SW version installs but stays in
// `waiting` behind the old active worker while any tab is open, so users get
// stuck on a stale worker until they manually unregister it (DevTools) — the
// exact problem testers hit. skipWaiting promotes the new version to active on
// the next load, replacing the old one with no user action.
// No clients.claim(): a push SW only needs `push`/`notificationclick` on its
// active worker, never to control app windows. (Verified: claim fires a
// `controllerchange` but does NOT reload this app — flutter.js registers no SW
// and has no controllerchange handler. Omitting claim is simply correct, not a
// reload fix.)
self.addEventListener('install', function () {
  self.skipWaiting();
});

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
