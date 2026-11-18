import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/utils/background_push.dart';
import 'package:twake_chat/utils/push_helper.dart';

import '../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const roomId = '!shared:s';
  final keyOfA = notificationIdKey('@a:s', roomId);
  final keyOfB = notificationIdKey('@b:s', roomId);
  final cancelled = <Object?>[];

  // BackgroundPush is a singleton whose store keeps the first preferences
  // instance: write through that one instead of resetting the mock.
  Future<void> storeIds(Map<String, int> ids) async =>
      (await SharedPreferences.getInstance()).setString(
        SettingKeys.notificationCurrentIds,
        jsonEncode(ids),
      );

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    cancelled.clear();
    await storeIds({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'cancel') {
            final args = call.arguments;
            cancelled.add(args is Map ? args['id'] : args);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('notification id', () {
    test('two accounts in the same room get two distinct ids', () async {
      final idOfA = await mapRoomIdToInt(keyOfA);
      final idOfB = await mapRoomIdToInt(keyOfB);

      expect(idOfA, isNot(idOfB));
      expect(await mapRoomIdToInt(keyOfA), idOfA);
    });

    test('an id stored for the room alone is kept and not reused', () async {
      await storeIds({roomId: 0});

      expect(await mapRoomIdToInt(keyOfA), 1);
      expect(notificationIdKeys('@a:s', roomId), {keyOfA, roomId});
    });
  });

  group('cancelNotification', () {
    late BackgroundPush push;

    setUp(() async {
      final client = await getClient();
      push = BackgroundPush.clientOnly(client)..rebind(client);
    });

    test('clearing one account leaves the other account\'s one', () async {
      await storeIds({keyOfA: 0, keyOfB: 1});

      await push.cancelNotification(roomId, userId: '@a:s');

      expect(cancelled, [0]);
    });

    test('an id stored for the room alone is cleared too', () async {
      await storeIds({roomId: 3, keyOfB: 1});

      await push.cancelNotification(roomId, userId: '@a:s');

      expect(cancelled, [3]);
    });
  });
}
