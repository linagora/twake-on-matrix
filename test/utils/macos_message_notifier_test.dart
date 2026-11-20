import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/push/twake_local_notification_payload.dart';
import 'package:twake_chat/utils/macos_message_notifier.dart';
import 'package:twake_chat/utils/message_notification_decision.dart';

typedef _Shown = ({int id, String title, String body, String payload});

class _FakePlugin implements LocalNotificationsPort {
  final shown = <_Shown>[];
  Object? failure;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    final f = failure;
    if (f != null) throw f;
    shown.add((id: id, title: title, body: body, payload: payload));
  }

  @override
  Future<void> cancel(int id) async {}
}

/// A message from Alice in '!room:example.com', app in the background.
const _fromAlice = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _fromMe = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@me:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _membership = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.RoomMember,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _muted = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: true,
  activeRoomId: null,
  appInForeground: false,
);

const _openInForeground = MessageNotificationCandidate(
  roomId: '!a:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: '!a:example.com',
  appInForeground: true,
);

const _inRoomA = MessageNotificationCandidate(
  roomId: '!a:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _inRoomB = MessageNotificationCandidate(
  roomId: '!b:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

/// Alice writes 'secret plan' in the group 'Project room'.
const _groupMessage = MessageNotificationContent(
  roomTitle: 'Project room',
  senderName: 'Alice',
  body: 'secret plan',
  eventId: r'$e1',
  isDirectChat: false,
);

const _directMessage = MessageNotificationContent(
  roomTitle: 'Project room',
  senderName: 'Alice',
  body: 'secret plan',
  eventId: r'$e1',
  isDirectChat: true,
);

const _nextGroupMessage = MessageNotificationContent(
  roomTitle: 'Project room',
  senderName: 'Alice',
  body: 'secret plan',
  eventId: r'$e2',
  isDirectChat: false,
);

const _messageE42 = MessageNotificationContent(
  roomTitle: 'Project room',
  senderName: 'Alice',
  body: 'secret plan',
  eventId: r'$e42',
  isDirectChat: false,
);

/// (behaviour, candidate) pairs that must show no notification.
const _silentCases = <(String, MessageNotificationCandidate)>[
  ('my own message shows nothing', _fromMe),
  ('an event that is not a message shows nothing', _membership),
  ('a muted room shows nothing', _muted),
  ('the room open in the foreground shows nothing', _openInForeground),
];

void main() {
  late _FakePlugin plugin;
  late MacosMessageNotifier notifier;

  setUp(() {
    plugin = _FakePlugin();
    notifier = MacosMessageNotifier(
      plugin,
      receiverId: '@me:example.com',
      genericBody: 'New message',
    );
  });

  test(
    'an incoming message shows one notification titled with the room',
    () async {
      final shown = await notifier.notify(
        _fromAlice,
        _groupMessage,
        showPreview: true,
      );

      expect(shown, isTrue);
      expect(plugin.shown, hasLength(1));
      expect(plugin.shown.single.title, 'Project room');
    },
  );

  test('with the preview on, a group message shows sender and text', () async {
    await notifier.notify(_fromAlice, _groupMessage, showPreview: true);

    expect(plugin.shown.single.body, 'Alice: secret plan');
  });

  test('with the preview on, a direct message shows the text alone', () async {
    await notifier.notify(_fromAlice, _directMessage, showPreview: true);

    expect(plugin.shown.single.body, 'secret plan');
  });

  test('with the preview off, the text never leaves the app', () async {
    await notifier.notify(_fromAlice, _groupMessage, showPreview: false);

    expect(plugin.shown.single.body, 'New message');
    expect(plugin.shown.single.body, isNot(contains('secret')));
  });

  for (final (behaviour, candidate) in _silentCases) {
    test(behaviour, () async {
      final shown = await notifier.notify(
        candidate,
        _groupMessage,
        showPreview: true,
      );

      expect(shown, isFalse);
      expect(plugin.shown, isEmpty);
    });
  }

  test('tapping the notification can open the room of the message', () async {
    await notifier.notify(_fromAlice, _messageE42, showPreview: true);

    final payload = TwakeLocalNotificationPayload.fromJson(
      jsonDecode(plugin.shown.single.payload) as Map<String, dynamic>,
    );
    expect(payload.roomId, '!room:example.com');
    expect(payload.receiverId, '@me:example.com');
    expect(payload.eventId, r'$e42');
  });

  test('two messages of a room replace each other', () async {
    await notifier.notify(_fromAlice, _groupMessage, showPreview: true);
    await notifier.notify(_fromAlice, _nextGroupMessage, showPreview: true);

    expect(plugin.shown[0].id, plugin.shown[1].id);
  });

  test('two rooms get two notifications', () async {
    await notifier.notify(_inRoomA, _groupMessage, showPreview: true);
    await notifier.notify(_inRoomB, _groupMessage, showPreview: true);

    expect(plugin.shown[0].id, isNot(plugin.shown[1].id));
  });

  test('a plugin failure does not break the message stream', () async {
    plugin.failure = Exception('notification center refused');

    final shown = await notifier.notify(
      _fromAlice,
      _groupMessage,
      showPreview: true,
    );

    expect(shown, isFalse);
  });
}
