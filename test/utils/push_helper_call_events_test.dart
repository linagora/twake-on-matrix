import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// ignore: depend_on_referenced_packages
import 'package:vodozemac/vodozemac.dart' as vod;
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/push_helper.dart';

import '../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const roomId = '!726s6s6q:example.com';
  final shown = <Object?>[];
  late Client client;
  Future<void> Function()? onFirstShow;

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
    onFirstShow = null;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'show') {
            shown.add(call.arguments);
            final deliver = onFirstShow;
            onFirstShow = null;
            if (deliver != null) unawaited(deliver());
          }
          if (call.method == 'initialize') return true;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> push(
    String type,
    Map<String, Object?> content, {
    String? eventId,
  }) => pushHelper(
    PushNotification.fromJson({
      'devices': [],
      'event_id': eventId ?? '\$push${type.hashCode}',
      'room_id': roomId,
      'sender': '@alice:example.com',
      'type': type,
      'content': content,
      'counts': {'unread': 1},
    }),
    client: client,
    l10n: lookupL10n(const Locale('en')),
  );

  // The room key arrives after the generic notification, as it does when the
  // push is faster than the to-device message.
  Future<void> pushEncrypted(String type, Map<String, Object?> content) {
    const senderKey = 'aliceCurve25519SenderKey';
    final session = vod.GroupSession();
    final sessionKey = session.sessionKey;
    onFirstShow = () async {
      await client.encryption!.keyManager
          .setInboundGroupSession(roomId, session.sessionId, senderKey, {
            'algorithm': AlgorithmTypes.megolmV1AesSha2,
            'room_id': roomId,
            'session_id': session.sessionId,
            'session_key': sessionKey,
          });
      await Future.delayed(const Duration(milliseconds: 50));
      client.onSync.add(SyncUpdate(nextBatch: 'key'));
    };
    return push(EventTypes.Encrypted, {
      'algorithm': AlgorithmTypes.megolmV1AesSha2,
      'ciphertext': session.encrypt(
        jsonEncode({'type': type, 'content': content, 'room_id': roomId}),
      ),
      'device_id': 'ALICEDEVICE',
      'sender_key': senderKey,
      'session_id': session.sessionId,
    }, eventId: '\$encrypted${type.hashCode}');
  }

  test('a legacy call invite shows no notification', () async {
    await push(EventTypes.CallInvite, {'call_id': 'c', 'version': '1'});
    expect(shown, isEmpty);
  });

  test('a text message shows a notification', () async {
    await push(EventTypes.Message, {'msgtype': 'm.text', 'body': 'hello'});
    expect(shown, isNotEmpty);
  });

  test('a decrypted call event keeps the generic notification', () async {
    await pushEncrypted(EventTypes.CallInvite, {
      'call_id': 'c',
      'version': '1',
    });
    expect(shown, hasLength(1));
  });

  test('a decrypted text message replaces the generic notification', () async {
    await pushEncrypted(EventTypes.Message, {
      'msgtype': 'm.text',
      'body': 'hello',
    });
    expect(shown, hasLength(2));
  });
}
