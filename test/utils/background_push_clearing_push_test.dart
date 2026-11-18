import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/utils/background_push.dart';

import '../fake_client.dart';

const _notificationsChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

const _unreadRoomId = '!unread:example.com';
const _readRoomId = '!read:example.com';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Client client;
  late BackgroundPush push;
  late List<int> cancelledIds;

  setUp(() async {
    cancelledIds = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'cancel') {
            cancelledIds.add((call.arguments as Map)['id'] as int);
          }
          return null;
        });
    SharedPreferences.setMockInitialValues({
      SettingKeys.notificationCurrentIds: json.encode({
        _unreadRoomId: 1,
        _readRoomId: 2,
      }),
    });
    // In background the app stops its sync loop.
    client = await getClient()
      ..backgroundSync = false;
    // The room was read on another device; the unread one was not.
    client.rooms.addAll([
      Room(id: _unreadRoomId, client: client, notificationCount: 1),
      Room(id: _readRoomId, client: client),
    ]);
    push = BackgroundPush.clientOnly(client)..rebind(client);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
  });

  Future<Map<String, dynamic>> storedIds() async => json.decode(
    (await SharedPreferences.getInstance()).getString(
          SettingKeys.notificationCurrentIds,
        ) ??
        '{}',
  );

  Future<void> settle() async {
    for (var i = 0; i < 500 && cancelledIds.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test(
    'a clearing push removes the notification of a room read elsewhere',
    () async {
      push.onReceiveNotification({
        'data': {'unread': '1', 'prio': 'high'},
      });
      await settle();

      expect(cancelledIds, [2]);
      expect((await storedIds()).keys, [_unreadRoomId]);
    },
  );
}
