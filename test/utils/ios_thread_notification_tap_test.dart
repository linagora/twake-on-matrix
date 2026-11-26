import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
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

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.clientOrNull);

  @override
  final Client? clientOrNull;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

/// Report (26/11): "I cannot open my thread on iOS". The tap on an iOS
/// notification hands the app the userInfo of the push (AppDelegate
/// didReceive). Decision (26/11): the NSE puts the thread root of a thread
/// reply in it, at top level under `thread_root_id` (the name Android uses):
/// the tap opens the thread at once, without loading the event, which on a
/// cold start or a slow network outlasts the 5 s wait and led to the room.
/// A push without `thread_root_id` (an older NSE) keeps loading the event.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const roomId = '!room:example.com';
  const rootId = r'$root';
  const replyId = r'$reply';

  late bool flagBefore;
  late MockClient client;
  late MockRoom room;
  late BackgroundPush push;

  setUp(() async {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    client = MockClient();
    room = MockRoom();
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(client.getRoomById(roomId)).thenReturn(room);
    push = BackgroundPush(_FakeMatrixState(client), await getClient());
    TwakeApp.router.go('/');
  });

  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  Event threadReply() => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': 'see you',
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'is_falling_back': true,
      },
    },
    eventId: replyId,
    senderId: '@bob:example.com',
    originServerTs: DateTime.utc(2026, 11, 26),
    room: room,
  );

  /// The user taps the iOS notification whose userInfo is [userInfo]; the
  /// event, if the app asks for it, arrives after [loadTime] (never when
  /// null). Where the user is [after] the tap.
  String tapIosNotification(
    Map<String, Object?> userInfo, {
    Duration? loadTime,
    required Duration after,
  }) {
    late String location;
    fakeAsync((async) {
      when(room.getEventById(replyId)).thenAnswer(
        (_) => loadTime == null
            ? Completer<Event?>().future
            : Future.delayed(loadTime, threadReply),
      );
      push.iOSUserSelectedNoti(userInfo);
      async.elapse(after);
      location = TwakeApp.router.routeInformationProvider.value.uri.toString();
    });
    return location;
  }

  final thread = const ThreadRoute(
    roomid: roomId,
    rootid: rootId,
    event: replyId,
  ).location;

  final roomOnReply = const RoomRoute(roomid: roomId, event: replyId).location;

  group('a push that names its thread root', () {
    const userInfo = {
      'room_id': roomId,
      'event_id': replyId,
      'thread_root_id': rootId,
    };

    test('opens the thread before 5 s when the event would take 8 s to '
        'load', () {
      expect(
        tapIosNotification(
          userInfo,
          loadTime: const Duration(seconds: 8),
          after: const Duration(seconds: 2),
        ),
        thread,
      );
    });

    test('opens the thread before 5 s when the event never loads', () {
      expect(
        tapIosNotification(userInfo, after: const Duration(seconds: 2)),
        thread,
      );
    });

    test('opens the thread without loading the event', () {
      tapIosNotification(userInfo, after: const Duration(seconds: 30));

      verifyNever(room.getEventById(any));
    });
  });

  group('a push without thread root (older NSE)', () {
    const userInfo = {'room_id': roomId, 'event_id': replyId};

    test('opens the thread once the event loads', () {
      expect(
        tapIosNotification(
          userInfo,
          loadTime: const Duration(milliseconds: 200),
          after: const Duration(seconds: 30),
        ),
        thread,
      );
    });

    test('opens the room on the reply when the event never loads', () {
      expect(
        tapIosNotification(userInfo, after: const Duration(seconds: 30)),
        roomOnReply,
      );
    });
  });
}
