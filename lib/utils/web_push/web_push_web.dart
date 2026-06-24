import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:web/web.dart' as web;

import '../../config/app_config.dart';
import '../platform_infos.dart';

/// Registers a standard Web Push (RFC 8030) subscription as a Matrix pusher,
/// reusing the existing Sygnal `webpush` gateway. The Service Worker
/// (`web/push_sw.js`) is registered by index.html after the app loads.
///
/// Does nothing unless Web Push is enabled, a VAPID key is configured, and the
/// user has already granted notification permission (the prompt is a separate
/// user-gesture step in onboarding — we never prompt here).
Future<void> setupWebPush(Client client) async {
  if (!AppConfig.webPushEnabled) return;
  if (AppConfig.vapidPublicKey.isEmpty) return;
  if (!client.isLogged()) return;
  if (web.Notification.permission != 'granted') return;

  try {
    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    final pushManager = registration.pushManager;

    var subscription = await pushManager.getSubscription().toDart;
    subscription ??= await pushManager
        .subscribe(
          web.PushSubscriptionOptionsInit(
            userVisibleOnly: true,
            applicationServerKey: _decodeVapidKey(
              AppConfig.vapidPublicKey,
            ).toJS,
          ),
        )
        .toDart;

    await _registerPusher(client, subscription.endpoint);
  } catch (e, s) {
    Logs().e('[WebPush] setup failed', e, s);
  }
}

/// Removes this client's Matrix pusher on logout.
/// At logout the token is usually already gone, so [client.deletePusher] is
/// best-effort; the local `unsubscribe()` makes the endpoint invalid and the
/// gateway drops the stale pusher on the next push (410 Gone).
///
/// [unsubscribe] must be false for a partial (multi-account) logout: the browser
/// push subscription is shared across accounts, so unsubscribing would break
/// notifications for the accounts still signed in. Only the true last-account
/// logout unsubscribes the browser.
Future<void> removeWebPush(Client client, {bool unsubscribe = true}) async {
  try {
    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    final subscription = await registration.pushManager
        .getSubscription()
        .toDart;
    if (subscription == null) return;
    final endpoint = subscription.endpoint;
    if (client.isLogged()) {
      final pushers = await client.getPushers().catchError((_) => <Pusher>[]);
      final pusher = pushers?.firstWhereOrNull((p) => p.pushkey == endpoint);
      if (pusher != null) await client.deletePusher(pusher);
    }
    if (unsubscribe) {
      await subscription.unsubscribe().toDart;
      Logs().i('[WebPush] Unsubscribed');
    } else {
      Logs().i(
        '[WebPush] Pusher removed (subscription kept for other accounts)',
      );
    }
  } catch (e, s) {
    Logs().w('[WebPush] removeWebPush failed', e, s);
  }
}

Future<void> _registerPusher(Client client, String endpoint) async {
  final clientName = PlatformInfos.clientName;
  // Plain appId (no device suffix): it must match the Sygnal `app_id`.
  // The endpoint is the per-browser pushkey, so devices stay distinct.
  const appId = 'app.twake.web.chat';
  final gatewayUrl = AppConfig.pushNotificationsGatewayUrl;

  final pushers = await client.getPushers().catchError((e) {
    Logs().w('[WebPush] Unable to request pushers', e);
    return <Pusher>[];
  });
  final alreadySet =
      pushers?.any(
        (p) =>
            p.pushkey == endpoint &&
            p.appId == appId &&
            p.data.url.toString() == gatewayUrl &&
            p.data.format == AppConfig.pushNotificationsPusherFormat,
      ) ??
      false;
  if (alreadySet) {
    Logs().i('[WebPush] Pusher already set');
    return;
  }

  // Don't sweep other pushers sharing this appId: the same account may be
  // signed in on another browser/session with a different endpoint. Truly
  // rotated endpoints age out on the gateway's first 410 Gone response.

  await client.postPusher(
    Pusher(
      pushkey: endpoint,
      appId: appId,
      appDisplayName: clientName,
      deviceDisplayName: client.deviceName ?? clientName,
      lang: 'en',
      data: PusherData(
        url: Uri.parse(gatewayUrl),
        format: AppConfig.pushNotificationsPusherFormat,
      ),
      kind: 'http',
    ),
    append: false,
  );
  Logs().i('[WebPush] Pusher registered');
}

/// base64url (unpadded) → bytes, for `applicationServerKey`.
Uint8List _decodeVapidKey(String base64Url) {
  final normalized = base64Url.replaceAll('-', '+').replaceAll('_', '/');
  final padded = normalized.padRight((normalized.length + 3) ~/ 4 * 4, '=');
  return base64.decode(padded);
}
