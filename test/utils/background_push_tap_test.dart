import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/utils/background_push.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

import '../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../fake_client.dart';

/// The app is up and runs [clientOrNull].
class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.clientOrNull);

  @override
  final Client? clientOrNull;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

/// Review of #3609 (jbrnzl background_push.dart:803): our local notification
/// already says whether the message is a thread reply (`thread_root_id` in
/// its payload, next to `event_id`). Its tap must not fetch the event again
/// to find out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Written for the threads on: pinned, not left to the default of the flag.
  late bool threadsFlagBefore;
  setUp(() {
    threadsFlagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
  });
  tearDown(() => AppConfig.threadsEnabled = threadsFlagBefore);

  const roomId = '!room:example.com';
  const rootId = r'$root';
  const eventId = r'$message';

  late MockClient tapClient;
  late MockRoom room;
  late BackgroundPush push;

  setUp(() async {
    tapClient = MockClient();
    room = MockRoom();
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(tapClient);
    when(tapClient.getRoomById(roomId)).thenReturn(room);
    push = BackgroundPush(_FakeMatrixState(tapClient), await getClient());
    TwakeApp.router.go('/');
  });

  Event serverEvent({String? threadRootId}) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': 'hello',
      if (threadRootId != null)
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': threadRootId,
          'is_falling_back': true,
        },
    },
    eventId: eventId,
    senderId: '@bob:example.com',
    originServerTs: DateTime.utc(2026, 11, 16),
    room: room,
  );

  Future<String> tap(
    Map<String, Object?> payload, {
    String? pushEventId,
  }) async {
    await push.onSelectNotification(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: jsonEncode(payload),
      ),
      eventId: pushEventId,
    );
    return TwakeApp.router.routeInformationProvider.value.uri.toString();
  }

  test('a tap on a message of the room opens the room on it, without '
      'fetching the event', () async {
    when(room.getEventById(any)).thenAnswer((_) async => serverEvent());

    final location = await tap({'room_id': roomId, 'event_id': eventId});

    expect(location, const RoomRoute(roomid: roomId, event: eventId).location);
    verifyNever(room.getEventById(any));
  });

  test('a tap on a thread reply opens its thread on the reply, without '
      'fetching the event', () async {
    when(
      room.getEventById(any),
    ).thenAnswer((_) async => serverEvent(threadRootId: rootId));

    final location = await tap({
      'room_id': roomId,
      'event_id': eventId,
      'thread_root_id': rootId,
    });

    expect(
      location,
      const ThreadRoute(
        roomid: roomId,
        rootid: rootId,
        event: eventId,
      ).location,
    );
    verifyNever(room.getEventById(any));
  });

  /// A notification shown before the payload carried the event id says
  /// nothing about threads: the event still tells.
  test('a tap on a notification whose payload has no event id still looks '
      'the event up', () async {
    when(
      room.getEventById(eventId),
    ).thenAnswer((_) async => serverEvent(threadRootId: rootId));

    final location = await tap({'room_id': roomId}, pushEventId: eventId);

    expect(
      location,
      const ThreadRoute(
        roomid: roomId,
        rootid: rootId,
        event: eventId,
      ).location,
    );
  });
}
