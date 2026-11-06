import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/push_helper.dart';

import '../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const roomId = '!726s6s6q:example.com';
  final shown = <Object?>[];
  late Client client;

  setUpAll(() async {
    sqfliteFfiInit();
    client = await getClient(
      database: await MatrixSdkDatabase.init(
        'push_helper_call_events_test',
        database: await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false),
        ),
        sqfliteFactory: databaseFactoryFfi,
      ),
    );
    if (client.getRoomById(roomId) == null) {
      client.rooms.add(
        Room(id: roomId, client: client, membership: Membership.join),
      );
    }
  });

  setUp(() {
    shown.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'show') shown.add(call.arguments);
          if (call.method == 'initialize') return true;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> push(String type, Map<String, Object?> content) => pushHelper(
    PushNotification.fromJson({
      'devices': [],
      'event_id': '\$push${type.hashCode}',
      'room_id': roomId,
      'sender': '@alice:example.com',
      'type': type,
      'content': content,
      'counts': {'unread': 1},
    }),
    client: client,
    l10n: lookupL10n(const Locale('en')),
  );

  test('a legacy call invite shows no notification', () async {
    await push(EventTypes.CallInvite, {'call_id': 'c', 'version': '1'});
    expect(shown, isEmpty);
  });

  test('a text message shows a notification', () async {
    await push(EventTypes.Message, {'msgtype': 'm.text', 'body': 'hello'});
    expect(shown, isNotEmpty);
  });
}
