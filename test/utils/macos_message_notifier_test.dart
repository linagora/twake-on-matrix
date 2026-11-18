import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/push/twake_local_notification_payload.dart';
import 'package:twake_chat/utils/macos_message_notifier.dart';
import 'package:twake_chat/utils/message_notification_decision.dart';

class _Shown {
  _Shown(this.id, this.title, this.body, this.payload);
  final int id;
  final String title;
  final String body;
  final String? payload;
}

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
    shown.add(_Shown(id, title, body, payload));
  }
}

MessageNotificationCandidate candidate({
  String roomId = '!room:example.com',
  String senderId = '@alice:example.com',
  String eventType = EventTypes.Message,
  bool isRoomMuted = false,
  String? activeRoomId,
  bool appInForeground = false,
}) => MessageNotificationCandidate(
  roomId: roomId,
  senderId: senderId,
  ownUserId: '@me:example.com',
  eventType: eventType,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: isRoomMuted,
  activeRoomId: activeRoomId,
  appInForeground: appInForeground,
);

MessageNotificationContent content({
  String roomTitle = 'Project room',
  String senderName = 'Alice',
  String body = 'secret plan',
  String eventId = r'$e1',
  bool isDirectChat = false,
}) => MessageNotificationContent(
  roomTitle: roomTitle,
  senderName: senderName,
  body: body,
  eventId: eventId,
  isDirectChat: isDirectChat,
);

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
        candidate(),
        content(),
        showPreview: true,
      );

      expect(shown, isTrue);
      expect(plugin.shown, hasLength(1));
      expect(plugin.shown.single.title, 'Project room');
    },
  );

  test('with the preview on, a group message shows sender and text', () async {
    await notifier.notify(candidate(), content(), showPreview: true);

    expect(plugin.shown.single.body, 'Alice: secret plan');
  });

  test('with the preview on, a direct message shows the text alone', () async {
    await notifier.notify(
      candidate(),
      content(isDirectChat: true),
      showPreview: true,
    );

    expect(plugin.shown.single.body, 'secret plan');
  });

  test('with the preview off, the text never leaves the app', () async {
    await notifier.notify(candidate(), content(), showPreview: false);

    expect(plugin.shown.single.body, 'New message');
    expect(plugin.shown.single.body, isNot(contains('secret')));
  });

  test('my own message shows nothing', () async {
    final shown = await notifier.notify(
      candidate(senderId: '@me:example.com'),
      content(),
      showPreview: true,
    );

    expect(shown, isFalse);
    expect(plugin.shown, isEmpty);
  });

  test('an event that is not a message shows nothing', () async {
    await notifier.notify(
      candidate(eventType: EventTypes.RoomMember),
      content(),
      showPreview: true,
    );

    expect(plugin.shown, isEmpty);
  });

  test('a muted room shows nothing', () async {
    await notifier.notify(
      candidate(isRoomMuted: true),
      content(),
      showPreview: true,
    );

    expect(plugin.shown, isEmpty);
  });

  test('the room open in the foreground shows nothing', () async {
    await notifier.notify(
      candidate(
        roomId: '!a:example.com',
        activeRoomId: '!a:example.com',
        appInForeground: true,
      ),
      content(),
      showPreview: true,
    );

    expect(plugin.shown, isEmpty);
  });

  test('tapping the notification can open the room of the message', () async {
    await notifier.notify(
      candidate(roomId: '!room:example.com'),
      content(eventId: r'$e42'),
      showPreview: true,
    );

    final payload = TwakeLocalNotificationPayload.fromJson(
      jsonDecode(plugin.shown.single.payload!) as Map<String, dynamic>,
    );
    expect(payload.roomId, '!room:example.com');
    expect(payload.receiverId, '@me:example.com');
    expect(payload.eventId, r'$e42');
  });

  test('two messages of a room replace each other', () async {
    await notifier.notify(
      candidate(),
      content(eventId: r'$e1'),
      showPreview: true,
    );
    await notifier.notify(
      candidate(),
      content(eventId: r'$e2'),
      showPreview: true,
    );

    expect(plugin.shown[0].id, plugin.shown[1].id);
  });

  test('two rooms get two notifications', () async {
    await notifier.notify(
      candidate(roomId: '!a:example.com'),
      content(),
      showPreview: true,
    );
    await notifier.notify(
      candidate(roomId: '!b:example.com'),
      content(),
      showPreview: true,
    );

    expect(plugin.shown[0].id, isNot(plugin.shown[1].id));
  });

  test('a plugin failure does not break the message stream', () async {
    plugin.failure = Exception('notification center refused');

    final shown = await notifier.notify(
      candidate(),
      content(),
      showPreview: true,
    );

    expect(shown, isFalse);
  });
}
