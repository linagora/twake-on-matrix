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

/// Report (26/11): "I cannot open my thread on iOS". On iOS the tap on a
/// remote notification hands the app only what the push carries (room and
/// event ids, no thread root, see AppDelegate didReceive): the app must find
/// out the reply belongs to a thread. Hypothesis H1: on a cold start or a slow
/// network the reply takes longer than the wait of the tap, and the user
/// lands in the room, where a thread reply is not shown, instead of the
/// thread.
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

  /// The user taps the iOS notification of the thread reply; the reply
  /// reaches the app after [loadTime]. Where the user lands once things
  /// settle.
  String tapIosNotification(Duration loadTime) {
    late String location;
    fakeAsync((async) {
      when(
        room.getEventById(replyId),
      ).thenAnswer((_) => Future.delayed(loadTime, threadReply));
      // What AppDelegate.didReceive passes: the userInfo of the push.
      push.iOSUserSelectedNoti({'room_id': roomId, 'event_id': replyId});
      async.elapse(loadTime + const Duration(seconds: 30));
      location = TwakeApp.router.routeInformationProvider.value.uri.toString();
    });
    return location;
  }

  final thread = const ThreadRoute(
    roomid: roomId,
    rootid: rootId,
    event: replyId,
  ).location;

  test('a thread reply that loads at once opens its thread', () {
    expect(tapIosNotification(const Duration(milliseconds: 200)), thread);
  });

  test('a thread reply that takes 8 s to load (cold start, slow network) '
      'still opens its thread, not the room', () {
    expect(tapIosNotification(const Duration(seconds: 8)), thread);
  });
}
