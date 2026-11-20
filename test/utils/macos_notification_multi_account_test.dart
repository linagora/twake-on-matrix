import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/model/push/twake_local_notification_payload.dart';
import 'package:twake_chat/generated/l10n/app_localizations_en.dart';
import 'package:twake_chat/utils/macos_message_notifier.dart';

import 'macos_notification_multi_account_test.mocks.dart';

class _Shown {
  _Shown(this.id, this.title, this.body, this.payload);
  final int id;
  final String title;
  final String body;
  final String payload;
  TwakeLocalNotificationPayload get parsed =>
      TwakeLocalNotificationPayload.fromJson(jsonDecode(payload));
}

class _FakePort implements LocalNotificationsPort {
  final shown = <_Shown>[];
  final cancelled = <int>[];

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async => shown.add(_Shown(id, title, body, payload));

  // Expected new member of the port (cancel one notification by id).
  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

const _roomId = '!shared:example.com';
const _secret = 'secret plan';

MockClient _account(
  String userId, {
  required Map<String, int> unread,
  bool encrypted = false,
  bool muted = false,
}) {
  final client = MockClient();
  when(client.userID).thenReturn(userId);
  when(client.globalPushRules).thenReturn(
    muted
        ? PushRuleSet(
            override: [
              PushRule(
                ruleId: _roomId,
                actions: [],
                enabled: true,
                default$: false,
              ),
            ],
          )
        : null,
  );
  when(client.onRoomState).thenReturn(CachedStreamController());
  for (final entry in unread.entries) {
    final room = Room(
      id: entry.key,
      client: client,
      notificationCount: entry.value,
    );
    if (encrypted) {
      room.setState(
        StrippedStateEvent(
          type: EventTypes.Encryption,
          stateKey: '',
          senderId: userId,
          content: {'algorithm': 'm.megolm.v1.aes-sha2'},
        ),
      );
    }
    when(client.getRoomById(entry.key)).thenReturn(room);
  }
  return client;
}

EventUpdate _message({String roomId = _roomId, String sender = '@bob:x.org'}) =>
    EventUpdate(
      roomID: roomId,
      type: EventUpdateType.timeline,
      content: {
        'type': EventTypes.Message,
        'event_id': r'$e1',
        'sender': sender,
        'origin_server_ts': 1,
        'content': {'msgtype': MessageTypes.Text, 'body': _secret},
      },
    );

Future<bool> _notify(
  _FakePort port,
  Client client,
  EventUpdate update, {
  bool showPreview = false,
  String? activeRoomId,
}) => notifyMacosMessage(
  port: port,
  client: client,
  eventUpdate: update,
  l10n: L10nEn(),
  activeRoomId: activeRoomId,
  appInForeground: false,
  showPreview: showPreview,
);

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  late _FakePort port;
  setUp(() => port = _FakePort());

  test('a message on an inactive account notifies for that account', () async {
    final active = _account('@me-a:x.org', unread: {});
    final inactive = _account('@me-b:x.org', unread: {_roomId: 2});
    // The active account (A) does not know the room; the event is from B.
    expect(active.getRoomById(_roomId), isNull);

    final shown = await _notify(port, inactive, _message());

    expect(shown, isTrue);
    expect(port.shown, hasLength(1));
    expect(port.shown.single.parsed.receiverId, '@me-b:x.org');
    expect(port.shown.single.parsed.roomId, _roomId);
  });

  test('my own message on the event account shows nothing', () async {
    final b = _account('@me-b:x.org', unread: {_roomId: 2});
    expect(await _notify(port, b, _message(sender: '@me-b:x.org')), isFalse);
    expect(port.shown, isEmpty);
  });

  test(
    'a room on both accounts uses the unread count of the event account',
    () async {
      final a = _account('@me-a:x.org', unread: {_roomId: 0});
      final b = _account('@me-b:x.org', unread: {_roomId: 3});

      expect(await _notify(port, a, _message()), isFalse);
      expect(await _notify(port, b, _message()), isTrue);
      expect(port.shown.single.parsed.receiverId, '@me-b:x.org');
    },
  );

  test('a room muted on the event account stays silent even if the other '
      'account does not mute it', () async {
    final a = _account('@me-a:x.org', unread: {_roomId: 1});
    final b = _account('@me-b:x.org', unread: {_roomId: 1}, muted: true);

    expect(await _notify(port, b, _message()), isFalse);
    expect(await _notify(port, a, _message()), isTrue);
    expect(port.shown.single.parsed.receiverId, '@me-a:x.org');
  });

  test('the generic text is shown by default', () async {
    final b = _account('@me-b:x.org', unread: {_roomId: 1});
    await _notify(port, b, _message());
    expect(port.shown.single.body, isNot(contains(_secret)));
  });

  test(
    'an encrypted room never shows the text, even with previews on',
    () async {
      final b = _account('@me-b:x.org', unread: {_roomId: 1}, encrypted: true);
      await _notify(port, b, _message(), showPreview: true);
      expect(port.shown.single.body, isNot(contains(_secret)));
    },
  );

  test('an unencrypted room shows the text when previews are on', () async {
    final b = _account('@me-b:x.org', unread: {_roomId: 1});
    await _notify(port, b, _message(), showPreview: true);
    expect(port.shown.single.body, contains(_secret));
  });

  test('a room read elsewhere gets its notification cancelled with the id '
      'it was shown with', () async {
    final notifier = MacosMessageNotifier(
      port,
      receiverId: '@me:x.org',
      genericBody: 'New message',
    );
    final b = _account('@me:x.org', unread: {_roomId: 1});
    await _notify(port, b, _message());
    final shownId = port.shown.single.id;

    await notifier.cancelRoom(_roomId);

    expect(port.cancelled, [shownId]);
  });

  test('cancelling one room leaves the other rooms alone', () async {
    final notifier = MacosMessageNotifier(
      port,
      receiverId: '@me:x.org',
      genericBody: 'New message',
    );
    await notifier.cancelRoom('!one:x.org');
    expect(port.cancelled, [macosNotificationId('!one:x.org')]);
    expect(
      macosNotificationId('!one:x.org'),
      isNot(macosNotificationId('!two:x.org')),
    );
  });
}
