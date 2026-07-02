import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import '../../config/app_config.dart';
import '../../config/localizations/localization_service.dart';
import '../../generated/l10n/app_localizations.dart';
import '../platform_infos.dart';

/// Local opt-out: the browser push subscription is per-device, so the choice to
/// turn Web Push off lives in [SharedPreferences], not account data. While set,
/// [setupWebPush] is a no-op — this is what makes a pusher deletion from the
/// notification settings actually stick (otherwise the next reload re-creates
/// it). Toggled through [setWebPushEnabled].
const _webPushDisabledKey = 'web_push_disabled_by_user';

Future<bool> _isWebPushDisabledByUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_webPushDisabledKey) ?? false;
}

Future<bool> isWebPushDisabledByUser() => _isWebPushDisabledByUser();

/// Cached, synchronous "Web Push is delivering" flag, updated by [setupWebPush].
/// The in-app (Dart) notification path uses it to know whether the service
/// worker already owns notifications: true → suppress the in-app one (avoid a
/// duplicate); explicit opt-out is checked separately.
bool _webPushActive = false;
bool isWebPushActiveSync() => _webPushActive;

/// Registers a standard Web Push (RFC 8030) subscription as a Matrix pusher,
/// reusing the existing Sygnal `webpush` gateway. The Service Worker
/// (`web/push_sw.js`) is registered by index.html after the app loads.
///
/// Does nothing unless Web Push is enabled, a VAPID key is configured, and the
/// user has already granted notification permission (the prompt is a separate
/// user-gesture step in onboarding — we never prompt here).
Future<void> setupWebPush(Client client) async {
  // Wait for config.json to load: on a warm start setupWebPush can run before
  // loadFromJson, leaving webPushEnabled/vapidPublicKey at their defaults.
  _webPushActive = false;
  await AppConfig.initConfigCompleter.future;
  if (!AppConfig.webPushEnabled) {
    Logs().i('[WebPush] disabled (web_push_enabled=false)');
    return;
  }
  if (AppConfig.vapidPublicKey.isEmpty) {
    Logs().w('[WebPush] no VAPID public key configured');
    return;
  }
  if (!client.isLogged()) return;
  if (await _isWebPushDisabledByUser()) {
    Logs().i('[WebPush] disabled by user (notification settings)');
    return;
  }
  if (web.Notification.permission != 'granted') {
    Logs().i('[WebPush] notification permission not granted');
    return;
  }

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

    final sub = _WebPushSubscription.from(subscription);
    if (!sub.isComplete) {
      Logs().w('[WebPush] Subscription missing p256dh/auth, skipping');
      return;
    }
    await _registerPusher(client, sub);
    _webPushActive = true;
  } catch (e, s) {
    Logs().e('[WebPush] setup failed', e, s);
  }
}

/// The subscription fields Sygnal's webpush pushkind needs.
class _WebPushSubscription {
  final String endpoint;
  final String p256dh;
  final String auth;

  const _WebPushSubscription(this.endpoint, this.p256dh, this.auth);

  factory _WebPushSubscription.from(web.PushSubscription sub) =>
      _WebPushSubscription(
        sub.endpoint,
        _subKey(sub, 'p256dh'),
        _subKey(sub, 'auth'),
      );

  bool get isComplete => p256dh.isNotEmpty && auth.isNotEmpty;
}

/// Whether Web Push is currently active on this browser: feature enabled, a
/// VAPID key is set, the OS/browser permission is granted, and the user hasn't
/// opted out. Drives the notification-settings toggle.
Future<bool> isWebPushActive() async {
  await AppConfig.initConfigCompleter.future;
  if (!AppConfig.webPushEnabled || AppConfig.vapidPublicKey.isEmpty) {
    return false;
  }
  if (web.Notification.permission != 'granted') return false;
  return !(await _isWebPushDisabledByUser());
}

/// Whether the browser permission was permanently denied — the user must
/// re-enable it in the browser site settings; the app can't re-prompt.
bool isWebPushPermissionDenied() => web.Notification.permission == 'denied';

/// Single entry point to enable/disable Web Push from the notification
/// settings. Enabling clears the opt-out, requests permission if needed and
/// (re)registers the pusher; disabling persists the opt-out and tears down the
/// subscription + pusher so it does not silently come back on the next reload.
Future<void> setWebPushEnabled(Client client, bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  if (enabled) {
    await prefs.setBool(_webPushDisabledKey, false);
    if (web.Notification.permission == 'default') {
      await web.Notification.requestPermission().toDart;
    }
    await setupWebPush(client);
  } else {
    await prefs.setBool(_webPushDisabledKey, true);
    await removeWebPush(client, unsubscribe: true);
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
  _webPushActive = false;
  try {
    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    final subscription = await registration.pushManager
        .getSubscription()
        .toDart;
    if (subscription == null) return;
    // pushkey == p256dh (Sygnal webpush contract).
    final p256dh = _subKey(subscription, 'p256dh');
    if (client.isLogged() && p256dh.isNotEmpty) {
      final pushers = await client.getPushers().catchError((_) => <Pusher>[]);
      final pusher = pushers?.firstWhereOrNull((p) => p.pushkey == p256dh);
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

// event_id_only (same as mobile): the push carries NO message content — only
// event_id/room_id. The SW shows a generic notification and the app fetches the
// content when the user clicks it. No message content ever transits the push
// service (FCM/Google), which is the privacy contract we keep on every platform.
const String _webPusherFormat = 'event_id_only';

Future<void> _registerPusher(Client client, _WebPushSubscription sub) async {
  final pushers = await client.getPushers().catchError((e) {
    Logs().w('[WebPush] Unable to request pushers', e);
    return <Pusher>[];
  });

  // Remove every other web pusher for this device's app so the homeserver
  // pushes to exactly one endpoint — leftover pushers from earlier
  // subscriptions cause duplicate notifications. Runs even when the current
  // pusher already exists. (Tradeoff: a second browser signed into the same
  // account is evicted and re-registers on its next load.)
  await _removeOtherWebPushers(client, pushers, sub.p256dh);

  if (pushers?.any((p) => _isCurrentWebPusher(p, sub)) ?? false) {
    Logs().i('[WebPush] Pusher already set');
    return;
  }

  await client.postPusher(_buildWebPusher(client, sub), append: false);
  Logs().i('[WebPush] Pusher registered');
}

/// Sygnal webpush contract: pushkey == p256dh, endpoint + auth in data.
bool _isCurrentWebPusher(Pusher p, _WebPushSubscription sub) =>
    p.pushkey == sub.p256dh &&
    p.appId == AppConfig.pushNotificationsAppId &&
    p.data.url.toString() == AppConfig.pushNotificationsGatewayUrl &&
    p.data.additionalProperties['endpoint'] == sub.endpoint &&
    p.data.additionalProperties['auth'] == sub.auth &&
    p.data.additionalProperties['events_only'] == true &&
    const DeepCollectionEquality().equals(
      p.data.additionalProperties['default_payload'],
      _localizedDefaultPayload(),
    ) &&
    p.data.format == _webPusherFormat;

/// Remove web pushers for this app whose pushkey isn't the current p256dh:
/// stale subscriptions and pre-contract endpoint-keyed pushers. Keeps exactly
/// one live pusher so the homeserver doesn't fan out duplicate pushes.
Future<void> _removeOtherWebPushers(
  Client client,
  List<Pusher>? pushers,
  String currentP256dh,
) async {
  final stale =
      pushers?.where(
        (p) =>
            p.appId == AppConfig.pushNotificationsAppId &&
            p.pushkey != currentP256dh,
      ) ??
      const [];
  for (final pusher in stale) {
    try {
      await client.deletePusher(pusher);
      Logs().i('[WebPush] Removed stale web pusher');
    } catch (e) {
      Logs().w('[WebPush] Failed to remove stale pusher', e);
    }
  }
}

Pusher _buildWebPusher(Client client, _WebPushSubscription sub) {
  final clientName = PlatformInfos.clientName;
  return Pusher(
    pushkey: sub.p256dh,
    appId: AppConfig.pushNotificationsAppId,
    appDisplayName: clientName,
    deviceDisplayName: client.deviceName ?? clientName,
    lang: 'en',
    data: PusherData(
      url: Uri.parse(AppConfig.pushNotificationsGatewayUrl),
      format: _webPusherFormat,
      // events_only: Sygnal drops pushes with no event_id (e.g. unread-count
      // clears). Without it, userVisibleOnly:true forces the SW to show a
      // phantom notification on every count change. (Sygnal webpush docs.)
      additionalProperties: {
        'endpoint': sub.endpoint,
        'auth': sub.auth,
        'events_only': true,
        'default_payload': _localizedDefaultPayload(),
      },
    ),
    kind: 'http',
  );
}

/// Generic notification text in the account's app language. Sygnal echoes
/// default_payload in every push, so the service worker can title/body the
/// notification in the user's language. With event_id_only the push carries no
/// event content — these are just localized, NEUTRAL boilerplate, never message
/// content and never assuming encryption (the SW can't know the room type).
/// Re-registered when the language changes (compared in [_isCurrentWebPusher]
/// + a currentLocale listener in matrix.dart).
Map<String, String> _localizedDefaultPayload() {
  final l10n = lookupL10n(LocalizationService.currentLocale.value);
  return {'title': AppConfig.applicationName, 'body': l10n.newMessage};
}

/// Subscription key (`p256dh` / `auth`) as unpadded base64url.
String _subKey(web.PushSubscription sub, String name) {
  final buffer = sub.getKey(name);
  if (buffer == null) return '';
  final bytes = buffer.toDart.asUint8List();
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// base64url (unpadded) → bytes, for `applicationServerKey`.
Uint8List _decodeVapidKey(String base64Url) {
  final normalized = base64Url.replaceAll('-', '+').replaceAll('_', '/');
  final padded = normalized.padRight((normalized.length + 3) ~/ 4 * 4, '=');
  return base64.decode(padded);
}
