import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/datasource_impl/activity/activity_datasource_impl.dart';

import '../../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../../utils/thread_unread/thread_fakes.dart';

/// Review of #3606 (activity_page.dart:52, nqhhdev): the page must not
/// import package:matrix ("Legacy code does not grow"). « Mark as read »
/// that the server refuses is logged where the SDK is called, and the
/// failure still reaches the page, which tells the user.
void main() {
  const roomId = '!design:example.org';
  final offline = Exception('offline');

  late bool threadsFlagBefore;
  late MockClient client;
  late ActivityDatasourceImpl datasource;

  setUp(() {
    threadsFlagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    client = MockClient();
    final room = Room(id: roomId, client: client);
    when(client.getRoomById(roomId)).thenReturn(room);
    when(client.receiptsPublicByDefault).thenReturn(true);
    when(client.database).thenReturn(
      StoredEvents([
        Event(
          type: EventTypes.Message,
          content: {'msgtype': 'm.text', 'body': 'hello'},
          eventId: r'$hello',
          senderId: '@bob:example.org',
          originServerTs: DateTime.utc(2026, 11, 20),
          room: room,
        ),
      ]),
    );
    when(
      client.setReadMarker(
        any,
        mFullyRead: anyNamed('mFullyRead'),
        mRead: anyNamed('mRead'),
        mReadPrivate: anyNamed('mReadPrivate'),
      ),
    ).thenThrow(offline);
    datasource = ActivityDatasourceImpl(client);
    Logs().outputEvents.clear();
  });

  tearDown(() {
    datasource.dispose();
    AppConfig.threadsEnabled = threadsFlagBefore;
  });

  test(
    'a room the server refuses to mark as read fails with its error',
    () async {
      await expectLater(
        datasource.markRoomRead(roomId),
        throwsA(same(offline)),
      );
    },
  );

  test(
    'a room the server refuses to mark as read is logged as a warning',
    () async {
      await datasource.markRoomRead(roomId).catchError((_) {});

      expect(
        Logs().outputEvents.where(
          (e) =>
              identical(e.exception, offline) &&
              e.level.index >= Level.warning.index,
        ),
        isNotEmpty,
      );
    },
  );
}
