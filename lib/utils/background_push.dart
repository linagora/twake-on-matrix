/*
 *   Famedly
 *   Copyright (C) 2020, 2021 Famedly GmbH
 *   Copyright (C) 2021 Fluffychat
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fcm_shared_isolate/fcm_shared_isolate.dart';
import 'package:fluffychat/domain/model/extensions/push/push_notification_extension.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/extensions/go_router_extensions.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/utils/push_helper.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:unifiedpush/unifiedpush.dart';

import '../config/app_config.dart';
import '../config/setting_keys.dart';
import 'famedlysdk_store.dart';
import 'platform_infos.dart';

class NoTokenException implements Exception {
  String get cause => 'Cannot get push token';
}

class BackgroundPush {
  static BackgroundPush? _instance;
  static const apnChannel = MethodChannel('twake_apn');
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Client client;
  MatrixState? _matrixState;
  String? _pushToken;
  void Function(String errorMsg, {Uri? link})? onFcmError;
  L10n? l10n;
  Store? _store;

  Store get store => _store ??= Store();

  Future<void> loadLocale() async {
    final context = _matrixState?.context;
    // inspired by _lookupL10n in .dart_tool/flutter_gen/gen_l10n/l10n.dart
    l10n ??= (context != null ? L10n.of(context) : null) ??
        (await L10n.delegate.load(View.of(context!).platformDispatcher.locale));
  }

  final pendingTests = <String, Completer<void>>{};

  final dynamic fcmSharedIsolate = FcmSharedIsolate();

  DateTime? lastReceivedPush;

  bool upAction = false;

  BackgroundPush._(this.client) {
    onRoomSync ??= client.onSync.stream
        .where((s) => s.hasRoomUpdate)
        .listen((s) => _onClearingPush(getFromServer: false));
    if (Platform.isAndroid) {
      UnifiedPush.initialize(
        onNewEndpoint: _newUpEndpoint,
        onRegistrationFailed: _upUnregistered,
        onUnregistered: _upUnregistered,
        onMessage: _onUpMessage,
      );
      fcmSharedIsolate?.setListeners(
        onMessage: (message) {
          onReceiveNotification(message);
        },
      );
    } else if (Platform.isIOS) {
      apnChannel.setMethodCallHandler((call) async {
        Logs().v('[Push] Received APN call: $call');
        if (call.method == 'willPresent') {
          onReceiveNotification(call.arguments);
        } else if (call.method == 'didReceive') {
          iOSUserSelectedNoti(call.arguments);
        }
      });
      getIosInitialNoti();
    }
  }

  factory BackgroundPush.clientOnly(
    Client client,
  ) {
    _instance ??= BackgroundPush._(client);
    return _instance!;
  }

  factory BackgroundPush(
    MatrixState matrixState,
    Client client, {
    final void Function(String errorMsg, {Uri? link})? onFcmError,
  }) {
    final instance = BackgroundPush.clientOnly(client);
    instance._matrixState = matrixState;
    instance.onFcmError = onFcmError;
    return instance;
  }

  StreamSubscription<SyncUpdate>? onRoomSync;

  Future<void> cancelNotification(String roomId) async {
    Logs().v('Cancel notification for room', roomId);
    final id = await mapRoomIdToInt(roomId);
    await FlutterLocalNotificationsPlugin().cancel(id);

    // Workaround for app icon badge not updating
    if (Platform.isIOS) {
      final unreadCount = client.rooms
          .where((room) => room.isUnreadOrInvited && room.id != roomId)
          .length;
      if (unreadCount == 0) {
        FlutterAppBadger.removeBadge();
      } else {
        FlutterAppBadger.updateBadgeCount(unreadCount);
      }
      return;
    }
  }

  Future<void> setupPusher({
    String? gatewayUrl,
    String? token,
    Set<String?>? oldTokens,
    bool useDeviceSpecificAppId = false,
  }) async {
    final clientName = PlatformInfos.clientName;
    oldTokens ??= <String>{};
    final pushers = await (client.getPushers().catchError((e) {
          Logs().w('[Push] Unable to request pushers', e);
          return <Pusher>[];
        })) ??
        [];
    var setNewPusher = false;
    // Just the plain app id, we add the .data_message suffix later
    final appId = AppConfig.pushNotificationsAppId;
    // we need the deviceAppId to remove potential legacy UP pusher
    var deviceAppId = '$appId.${client.deviceID}';
    // appId may only be up to 64 chars as per spec
    if (deviceAppId.length > 64) {
      deviceAppId = deviceAppId.substring(0, 64);
    }
    final thisAppId = useDeviceSpecificAppId ? deviceAppId : appId;
    if (gatewayUrl != null && token != null) {
      final currentPushers = pushers.where((pusher) => pusher.pushkey == token);
      if (currentPushers.length == 1 &&
          currentPushers.first.kind == 'http' &&
          currentPushers.first.appId == thisAppId &&
          currentPushers.first.appDisplayName == clientName &&
          currentPushers.first.deviceDisplayName == client.deviceName &&
          currentPushers.first.lang == 'en' &&
          currentPushers.first.data.url.toString() == gatewayUrl &&
          currentPushers.first.data.format ==
              AppConfig.pushNotificationsPusherFormat) {
        Logs().i('[Push] Pusher already set');
      } else {
        Logs().i('Need to set new pusher');
        oldTokens.add(token);
        if (client.isLogged()) {
          setNewPusher = true;
        }
      }
    } else {
      Logs().w('[Push] Missing required push credentials');
    }
    for (final pusher in pushers) {
      if ((token != null &&
              pusher.pushkey != token &&
              deviceAppId == pusher.appId) ||
          oldTokens.contains(pusher.pushkey)) {
        try {
          await client.deletePusher(pusher);
          Logs().i('[Push] Removed legacy pusher for this device');
        } catch (err) {
          Logs().w('[Push] Failed to remove old pusher', err);
        }
      }
    }
    if (setNewPusher) {
      try {
        await client.postPusher(
          Pusher(
            pushkey: token!,
            appId: thisAppId,
            appDisplayName: clientName,
            deviceDisplayName: client.deviceName!,
            lang: 'en',
            data: PusherData(
              url: Uri.parse(gatewayUrl!),
              format: AppConfig.pushNotificationsPusherFormat,
              additionalProperties: PlatformInfos.isIOS
                  ? {
                      "default_payload": {
                        "aps": {
                          "mutable-content": 1,
                          "content-available": 1,
                          "badge": 1,
                          "sound": "default",
                          "alert": {
                            "loc-key": "newMessageInTwake",
                            "loc-args": [],
                          },
                        },
                        "pusher_notification_client_identifier":
                            client.pusherNotificationClientIdentifier,
                      },
                    }
                  : {},
            ),
            kind: 'http',
          ),
          append: false,
        );
      } catch (e, s) {
        Logs().e('[Push] Unable to set pushers', e, s);
      }
    }
  }

  bool _wentToRoomOnStartup = false;

  Future<void> setupPush() async {
    Logs().d("SetupPush");
    if (client.onLoginStateChanged.value != LoginState.loggedIn ||
        !PlatformInfos.isMobile ||
        _matrixState == null) {
      return;
    }
    // Do not setup unifiedpush if this has been initialized by
    // an unifiedpush action
    if (upAction) {
      return;
    }
    if (!PlatformInfos.isIOS &&
        (await UnifiedPush.getDistributors()).isNotEmpty) {
      await setupUp();
    } else {
      await setupPushGateway();
    }

    // ignore: unawaited_futures
    _flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails()
        .then((details) {
      if (details == null ||
          !details.didNotificationLaunchApp ||
          _wentToRoomOnStartup ||
          _matrixState == null) {
        return;
      }
      _wentToRoomOnStartup = true;
      onSelectNotification(details.notificationResponse);
    });
  }

  Future<void> _noFcmWarning() async {
    if (_matrixState == null) {
      return;
    }
    if (await store.getItemBool(SettingKeys.showNoGoogle, true) == true) {
      return;
    }
    await loadLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (PlatformInfos.isAndroid) {
        onFcmError?.call(
          l10n!.noGoogleServicesWarning,
          link: Uri.parse(
            AppConfig.enablePushTutorial,
          ),
        );
        return;
      }
      onFcmError?.call(l10n!.oopsPushError);
    });
  }

  Future<void> setupPushGateway() async {
    Logs().v('Setup Push Gateway');
    if (_pushToken?.isEmpty ?? true) {
      try {
        if (PlatformInfos.isIOS) {
          // Request iOS permission before getting the token
          await fcmSharedIsolate?.requestPermission();
        } else if (Platform.isAndroid) {
          await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();
        }
        _pushToken = await (Platform.isIOS
            ? apnChannel.invokeMethod("getToken")
            : fcmSharedIsolate?.getToken());
        Logs().d('BackgroundPush::pushToken: $_pushToken');
        if (_pushToken == null) throw ('PushToken is null');
      } catch (e, s) {
        Logs().w('[Push] cannot get token', e, e is String ? null : s);
        await _noFcmWarning();
        return;
      }
    }
    await setupPusher(
      gatewayUrl: AppConfig.pushNotificationsGatewayUrl,
      token: _pushToken,
    );
  }

  Future<void> getIosInitialNoti() async {
    try {
      final noti = await apnChannel.invokeMethod('getInitialNoti');
      Logs().v('[Push] Got initial notification: $noti');
      if (noti != null) {
        iOSUserSelectedNoti(noti);
      }
    } catch (e, s) {
      Logs().e('[Push] Failed to get initial notification', e, s);
    }
  }

  void iOSUserSelectedNoti(dynamic noti) {
    // roomId is payload if noti is local
    final roomId = noti['room_id'] ?? noti['payload'];
    goToRoom(roomId);
  }

  void onReceiveNotification(dynamic message) {
    Logs().d(
      'BackgroundPush::onReceiveNotification(): Message $message}',
    );
    final notification = _parseMessagePayload(message);
    pushHelper(
      notification,
      client: client,
      l10n: l10n,
      activeRoomId: _matrixState?.activeRoomId,
      onSelectNotification: onSelectNotification,
    );
    Logs().d('BackgroundPush::onMessage(): finished pushHelper');
  }

  Future<void> onSelectNotification(NotificationResponse? response) {
    return goToRoom(response?.payload);
  }

  Future<void> goToRoom(String? roomId) async {
    try {
      Logs().v('[Push] Attempting to go to room $roomId...');
      _clearAllNavigatorAvailable(roomId: roomId);
      if (_matrixState == null || roomId == null) {
        return;
      }
      await client.roomsLoading;
      await client.accountDataLoading;
      // ignore: unused_local_variable
      final isStory = client
              .getRoomById(roomId)
              ?.getState(EventTypes.RoomCreate)
              ?.content
              .tryGet<String>('type') ==
          ClientStoriesExtension.storiesRoomType;
      if (client.getRoomById(roomId) == null) {
        Logs().v('[Push] Room $roomId not found, syncing...');
        await client.waitForRoomInSync(roomId);
      }
      TwakeApp.router.go('/rooms/$roomId');
    } catch (e, s) {
      Logs().e('[Push] Failed to open room', e, s);
    }
  }

  Future<void> setupUp() async {
    await UnifiedPush.registerAppWithDialog(_matrixState!.context);
  }

  Future<void> _newUpEndpoint(String newEndpoint, String i) async {
    upAction = true;
    if (newEndpoint.isEmpty) {
      await _upUnregistered(i);
      return;
    }
    var endpoint =
        'https://matrix.gateway.unifiedpush.org/_matrix/push/v1/notify';
    try {
      final url = Uri.parse(newEndpoint)
          .replace(
            path: '/_matrix/push/v1/notify',
            query: '',
          )
          .toString()
          .split('?')
          .first;
      final res =
          json.decode(utf8.decode((await http.get(Uri.parse(url))).bodyBytes));
      if (res['gateway'] == 'matrix' ||
          (res['unifiedpush'] is Map &&
              res['unifiedpush']['gateway'] == 'matrix')) {
        endpoint = url;
      }
    } catch (e) {
      Logs().i(
        '[Push] No self-hosted unified push gateway present: $newEndpoint',
      );
    }
    Logs().i('[Push] UnifiedPush using endpoint $endpoint');
    final oldTokens = <String?>{};
    try {
      final fcmToken = await fcmSharedIsolate?.getToken();
      oldTokens.add(fcmToken);
    } catch (_) {}
    await setupPusher(
      gatewayUrl: endpoint,
      token: newEndpoint,
      oldTokens: oldTokens,
      useDeviceSpecificAppId: true,
    );
    await store.setItem(SettingKeys.unifiedPushEndpoint, newEndpoint);
    await store.setItemBool(SettingKeys.unifiedPushRegistered, true);
  }

  Future<void> _upUnregistered(String i) async {
    upAction = true;
    Logs().i('[Push] Removing UnifiedPush endpoint...');
    final oldEndpoint = await store.getItem(SettingKeys.unifiedPushEndpoint);
    await store.setItemBool(SettingKeys.unifiedPushRegistered, false);
    await store.deleteItem(SettingKeys.unifiedPushEndpoint);
    if (oldEndpoint?.isNotEmpty ?? false) {
      // remove the old pusher
      await setupPusher(
        oldTokens: {oldEndpoint},
      );
    }
  }

  Future<void> _onUpMessage(Uint8List message, String i) async {
    upAction = true;
    final data = Map<String, dynamic>.from(
      json.decode(utf8.decode(message))['notification'],
    );
    // UP may strip the devices list
    data['devices'] ??= [];
    await pushHelper(
      PushNotification.fromJson(data),
      client: client,
      l10n: l10n,
      activeRoomId: _matrixState?.activeRoomId,
    );
  }

  /// Workaround for the problem that local notification IDs must be int but we
  /// sort by [roomId] which is a String. To make sure that we don't have duplicated
  /// IDs we map the [roomId] to a number and store this number.
  late Map<String, int> idMap;

  Future<void> _loadIdMap() async {
    idMap = Map<String, int>.from(
      json.decode(
        (await store.getItem(SettingKeys.notificationCurrentIds)) ?? '{}',
      ),
    );
  }

  Future<int> mapRoomIdToInt(String roomId) async {
    await _loadIdMap();
    int? currentInt;
    try {
      currentInt = idMap[roomId];
    } catch (_) {
      currentInt = null;
    }
    if (currentInt != null) {
      return currentInt;
    }
    var nCurrentInt = 0;
    while (idMap.values.contains(currentInt)) {
      nCurrentInt++;
    }
    idMap[roomId] = nCurrentInt;
    await store.setItem(SettingKeys.notificationCurrentIds, json.encode(idMap));
    return nCurrentInt;
  }

  bool _clearingPushLock = false;

  Future<void> _onClearingPush({bool getFromServer = true}) async {
    if (_clearingPushLock) {
      return;
    }
    try {
      _clearingPushLock = true;
      late Iterable<String> emptyRooms;
      if (getFromServer) {
        Logs().v('[Push] Got new clearing push');
        var syncErrored = false;
        if (client.syncPending) {
          Logs().v('[Push] waiting for existing sync');
          // we need to catchError here as the Future might be in a different execution zone
          await client.oneShotSync().catchError((e) {
            syncErrored = true;
            Logs().v('[Push] Error one-shot syncing', e);
          });
        }
        if (!syncErrored) {
          Logs().v('[Push] single oneShotSync');
          // we need to catchError here as the Future might be in a different execution zone
          await client.oneShotSync().catchError((e) {
            syncErrored = true;
            Logs().v('[Push] Error one-shot syncing', e);
          });
          if (!syncErrored) {
            emptyRooms = client.rooms
                .where((r) => r.notificationCount == 0)
                .map((r) => r.id);
          }
        }
        if (syncErrored) {
          try {
            Logs().v(
              '[Push] failed to sync for fallback push, fetching notifications endpoint...',
            );
            final notifications = await client.getNotifications(limit: 20);
            final notificationRooms =
                notifications.notifications.map((n) => n.roomId).toSet();
            emptyRooms = client.rooms
                .where((r) => !notificationRooms.contains(r.id))
                .map((r) => r.id);
          } catch (e) {
            Logs().v(
              '[Push] failed to fetch pending notifications for clearing push, falling back...',
              e,
            );
            emptyRooms = client.rooms
                .where((r) => r.notificationCount == 0)
                .map((r) => r.id);
          }
        }
      } else {
        emptyRooms = client.rooms
            .where((r) => r.notificationCount == 0)
            .map((r) => r.id);
      }
      await _loadIdMap();
      var changed = false;
      for (final roomId in emptyRooms) {
        final id = idMap[roomId];
        if (id != null) {
          idMap.remove(roomId);
          changed = true;
          await _flutterLocalNotificationsPlugin.cancel(id);
        }
      }
      if (changed) {
        await store.setItem(
          SettingKeys.notificationCurrentIds,
          json.encode(idMap),
        );
      }
    } finally {
      _clearingPushLock = false;
    }
  }

  PushNotification _parseMessagePayload(dynamic message) {
    Logs().d('BackgroundPush::_parseMessagePayload()');
    try {
      return PushNotificationExtensions().fromOriginalJson(
        Map<String, dynamic>.from(message['data'] ?? message),
      );
    } catch (e) {
      Logs().e('BackgroundPush::_parseMessagePayload() exception: $e');
      return PushNotificationExtensions().error();
    }
  }

  void clearAllNotifications() {
    if (Platform.isIOS) {
      apnChannel.invokeMethod('clearAll');
    }
  }

  Future<void> removeCurrentPusher() async {
    if (_pushToken == null) return;
    await setupPusher(
      oldTokens: {_pushToken},
    );
  }

  void _clearAllNavigatorAvailable({
    String? roomId,
  }) {
    Logs().d(
      "BackgroundPush:: - Current active room id  @2 ${TwakeApp.router.activeRoomId}",
    );
    if (roomId != null &&
        TwakeApp.router.activeRoomId?.contains(roomId) == true) {
      return;
    }

    final canPopNavigation = TwakeApp.router.routerDelegate.canPop();
    Logs().d("BackgroundPush:: - Can pop other Navigation  $canPopNavigation");
    if (canPopNavigation) {
      TwakeApp.router.routerDelegate.pop();
    }
  }
}
