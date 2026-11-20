import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/push_helper.dart';

import '../fake_client.dart';

/// Reviews of #3609.
/// - nqhhdev push_helper.dart:142 [0]: a push for the room being read must
///   stay silent even when the event cannot be fetched (before, the room on
///   screen returned before the fetch; now a timeout or a missing event
///   throws and the catch shows "New message in Twake" for that room).
/// - nqhhdev notification_location.dart:14 [1]: with
///   `AppConfig.threadsEnabled` off a thread reply is an ordinary message of
///   the room: a reply in the open room does not notify.
/// - jbrnzl push_helper.dart:372 [5]: the local notification carries the
///   event id (and the thread root of a reply) so a tap, a cold start
///   included, opens the thread without fetching.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const roomId = '!726s6s6q:example.com';
  const rootId = r'$root';
  late Client client;
  late bool flagBefore;
  final shown = <Map<Object?, Object?>>[];

  setUpAll(() async {
    sqfliteFfiInit();
    client = await getClient(
      database: await MatrixSdkDatabase.init(
        'push_helper_notification_rules_test',
        database: await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false),
        ),
        sqfliteFactory: databaseFactoryFfi,
      ),
    );
    // A keyword rule: a message that says "admin" notifies and highlights.
    await client.handleSync(
      SyncUpdate(
        nextBatch: 'rules',
        accountData: [
          BasicEvent(
            type: 'm.push_rules',
            content: {
              'global': {
                'content': [
                  {
                    'rule_id': 'admin',
                    'default': false,
                    'enabled': true,
                    'pattern': 'admin',
                    'actions': [
                      'notify',
                      {'set_tweak': 'highlight'},
                    ],
                  },
                ],
              },
            },
          ),
        ],
      ),
    );
    if (client.getRoomById(roomId) == null) {
      client.rooms.add(
        Room(id: roomId, client: client, membership: Membership.join),
      );
    }
  });

  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    // Written for the threads on: pinned, not left to the default of the flag.
    AppConfig.threadsEnabled = true;
    shown.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'show') {
            shown.add(Map<Object?, Object?>.from(call.arguments as Map));
          }
          if (call.method == 'initialize') return true;
          return null;
        });
  });

  tearDown(() {
    AppConfig.threadsEnabled = flagBefore;
    client.syncPresence = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  var counter = 0;

  /// A push in the foreground. [content] null: the push carries no event, it
  /// has to be fetched from the server (which does not know it).
  Future<String> push({
    Map<String, Object?>? content,
    String? activeRoomId,
    ({String roomId, String threadRootId})? activeThread,
  }) async {
    final eventId = '\$push${counter++}';
    try {
      await pushHelper(
        PushNotification.fromJson({
          'devices': [],
          'event_id': eventId,
          'room_id': roomId,
          'sender': '@alice:example.com',
          'type': EventTypes.Message,
          'content': ?content,
          'counts': {'unread': 1},
        }),
        client: client,
        l10n: lookupL10n(const Locale('en')),
        activeRoomId: activeRoomId,
        activeThread: activeThread,
      );
    } catch (_) {
      // pushHelper rethrows after its fallback notification: what counts is
      // what the user sees.
    }
    return eventId;
  }

  Map<String, Object?> payloadOfLastNotification() =>
      jsonDecode(shown.last['payload']! as String) as Map<String, Object?>;

  const text = {'msgtype': 'm.text', 'body': 'hello'};
  // Mentions the account (@admin): a followed or highlighted reply notifies.
  const threadReply = {
    'msgtype': 'm.text',
    'body': 'hello admin',
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': rootId,
      'is_falling_back': true,
    },
  };

  group('a push whose event cannot be fetched', () {
    test('the room on screen stays silent', () async {
      await push(activeRoomId: roomId);

      expect(shown, isEmpty);
    });

    /// Review of #3609 (nqhhdev push_helper.dart:124): in the background
    /// the presence is unavailable and the router still holds the last room;
    /// that room is not read live, its failed fetch shows the fallback.
    test('the last room on screen, with the app in the background, keeps '
        'the fallback notification', () async {
      client.syncPresence = PresenceType.unavailable;

      await push(activeRoomId: roomId);

      expect(shown, hasLength(1));
    });

    test('another room than the one on screen keeps the fallback '
        'notification', () async {
      await push(activeRoomId: '!other:example.com');

      expect(shown, hasLength(1));
    });

    test('no room on screen keeps the fallback notification', () async {
      await push();

      expect(shown, hasLength(1));
    });
  });

  group('threads flag off: a thread reply is a message of the room', () {
    test('a reply in the room on screen stays silent', () async {
      AppConfig.threadsEnabled = false;

      await push(content: threadReply, activeRoomId: roomId);

      expect(shown, isEmpty);
    });

    test('a reply in a room not on screen notifies', () async {
      AppConfig.threadsEnabled = false;

      await push(content: threadReply, activeRoomId: '!other:example.com');

      expect(shown, hasLength(1));
    });
  });

  group('the payload of the local notification', () {
    test('carries the room, the receiver and the event id', () async {
      final eventId = await push(content: text);

      final payload = payloadOfLastNotification();
      expect(payload, containsPair('room_id', roomId));
      expect(payload, containsPair('receiver_id', client.userID));
      expect(payload, containsPair('event_id', eventId));
    });

    test('of a thread reply carries the root of its thread', () async {
      final eventId = await push(content: threadReply);

      expect(payloadOfLastNotification(), containsPair('event_id', eventId));
      expect(
        payloadOfLastNotification(),
        containsPair('thread_root_id', rootId),
      );
    });

    test('of a message of the room has no thread root', () async {
      await push(content: text);

      expect(
        payloadOfLastNotification().containsKey('thread_root_id'),
        isFalse,
      );
    });

    test('with the threads flag off has no thread root', () async {
      AppConfig.threadsEnabled = false;

      await push(content: threadReply);

      expect(
        payloadOfLastNotification().containsKey('thread_root_id'),
        isFalse,
      );
    });
  });
}
