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

typedef _Shown = ({int id, String title, String body, String payload});

extension on _Shown {
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
  }) async => shown.add((id: id, title: title, body: body, payload: payload));

  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

const _roomId = '!shared:example.com';
const _roomOne = '!one:x.org';
const _roomTwo = '!two:x.org';
const _secret = 'secret plan';
const _userA = '@me-a:x.org';
const _userB = '@me-b:x.org';
const _me = '@me:x.org';
const _bob = '@bob:x.org';

/// One signed-in account and what it knows of [_roomId]: a null [unread]
/// means the account does not know the room.
typedef _Setup = ({String userId, int? unread, bool encrypted, bool muted});

const _aWithoutRoom = (
  userId: _userA,
  unread: null,
  encrypted: false,
  muted: false,
);
const _aRead = (userId: _userA, unread: 0, encrypted: false, muted: false);
const _aUnread = (userId: _userA, unread: 1, encrypted: false, muted: false);
const _bUnread = (userId: _userB, unread: 1, encrypted: false, muted: false);
const _bTwoUnread = (userId: _userB, unread: 2, encrypted: false, muted: false);
const _bThreeUnread = (
  userId: _userB,
  unread: 3,
  encrypted: false,
  muted: false,
);
const _bMuted = (userId: _userB, unread: 1, encrypted: false, muted: true);
const _bEncrypted = (userId: _userB, unread: 1, encrypted: true, muted: false);
const _meUnread = (userId: _me, unread: 1, encrypted: false, muted: false);

/// Generic text, app in the background, no room open.
const _quiet = MacosNotificationState(
  activeRoomId: null,
  appInForeground: false,
  showPreview: false,
);
const _withPreview = MacosNotificationState(
  activeRoomId: null,
  appInForeground: false,
  showPreview: true,
);

PushRuleSet _muteRule() => PushRuleSet(
  override: [
    PushRule(ruleId: _roomId, actions: [], enabled: true, default$: false),
  ],
);

MockClient _account(_Setup setup) {
  final client = MockClient();
  when(client.userID).thenReturn(setup.userId);
  when(client.globalPushRules).thenReturn(setup.muted ? _muteRule() : null);
  when(client.onRoomState).thenReturn(CachedStreamController());
  final unread = setup.unread;
  if (unread == null) return client;
  final room = Room(id: _roomId, client: client, notificationCount: unread);
  if (setup.encrypted) {
    room.setState(
      StrippedStateEvent(
        type: EventTypes.Encryption,
        stateKey: '',
        senderId: setup.userId,
        content: {'algorithm': 'm.megolm.v1.aes-sha2'},
      ),
    );
  }
  when(client.getRoomById(_roomId)).thenReturn(room);
  return client;
}

EventUpdate _textFrom(String sender) => EventUpdate(
  roomID: _roomId,
  type: EventUpdateType.timeline,
  content: {
    'type': EventTypes.Message,
    'event_id': r'$e1',
    'sender': sender,
    'origin_server_ts': 1,
    'content': {'msgtype': MessageTypes.Text, 'body': _secret},
  },
);

/// Bob writes [_secret] in [_roomId].
final _fromBob = _textFrom(_bob);

/// Account B writes [_secret] in [_roomId] from another device.
final _fromMeB = _textFrom(_userB);

Future<bool> _notify(
  _FakePort port,
  Client client,
  EventUpdate update, {
  MacosNotificationState state = _quiet,
}) => notifyMacosMessage(
  port,
  MacosMessageRequest(
    client: client,
    eventUpdate: update,
    l10n: L10nEn(),
    state: state,
  ),
);

MacosMessageNotifier _notifier(_FakePort port) =>
    MacosMessageNotifier(port, receiverId: _me, genericBody: 'New message');

/// One event read on one account, and whether it shows a notification.
typedef _Step = ({_Setup account, EventUpdate update, bool shown});

/// (behaviour, steps in order, receiver of the one notification shown or
/// null when none is shown).
final _visibilityCases = <(String, List<_Step>, String?)>[
  (
    'a message on an inactive account notifies for that account',
    [
      (account: _aWithoutRoom, update: _fromBob, shown: false),
      (account: _bTwoUnread, update: _fromBob, shown: true),
    ],
    _userB,
  ),
  (
    'my own message on the event account shows nothing',
    [(account: _bTwoUnread, update: _fromMeB, shown: false)],
    null,
  ),
  (
    'a room on both accounts uses the unread count of the event account',
    [
      (account: _aRead, update: _fromBob, shown: false),
      (account: _bThreeUnread, update: _fromBob, shown: true),
    ],
    _userB,
  ),
  (
    'a room muted on the event account stays silent even if the other '
        'account does not mute it',
    [
      (account: _bMuted, update: _fromBob, shown: false),
      (account: _aUnread, update: _fromBob, shown: true),
    ],
    _userA,
  ),
];

/// (behaviour, account, state, matcher on the shown text).
final _textCases = <(String, _Setup, MacosNotificationState, Matcher)>[
  (
    'the generic text is shown by default',
    _bUnread,
    _quiet,
    isNot(contains(_secret)),
  ),
  (
    'an encrypted room never shows the text, even with previews on',
    _bEncrypted,
    _withPreview,
    isNot(contains(_secret)),
  ),
  (
    'an unencrypted room shows the text when previews are on',
    _bUnread,
    _withPreview,
    contains(_secret),
  ),
];

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  late _FakePort port;
  setUp(() => port = _FakePort());

  for (final (behaviour, steps, receiver) in _visibilityCases) {
    test(behaviour, () async {
      for (final step in steps) {
        final client = _account(step.account);
        if (step.account.unread == null) {
          expect(client.getRoomById(_roomId), isNull);
        }
        expect(await _notify(port, client, step.update), step.shown);
      }

      if (receiver == null) {
        expect(port.shown, isEmpty);
        return;
      }
      expect(port.shown, hasLength(1));
      expect(port.shown.single.parsed.receiverId, receiver);
      expect(port.shown.single.parsed.roomId, _roomId);
    });
  }

  for (final (behaviour, setup, state, body) in _textCases) {
    test(behaviour, () async {
      await _notify(port, _account(setup), _fromBob, state: state);
      expect(port.shown.single.body, body);
    });
  }

  test('a room read elsewhere gets its notification cancelled with the id '
      'it was shown with', () async {
    final notifier = _notifier(port);
    await _notify(port, _account(_meUnread), _fromBob);
    final shownId = port.shown.single.id;

    await notifier.cancelRoom(_roomId);

    expect(port.cancelled, [shownId]);
  });

  test('cancelling one room leaves the other rooms alone', () async {
    await _notifier(port).cancelRoom(_roomOne);

    expect(port.cancelled, [macosNotificationId(_roomOne)]);
    expect(macosNotificationId(_roomOne), isNot(macosNotificationId(_roomTwo)));
  });
}
