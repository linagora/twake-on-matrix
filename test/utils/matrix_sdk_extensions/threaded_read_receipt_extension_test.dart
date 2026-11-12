import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/models/timeline_chunk.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../room_status_extension_test.mocks.dart' show MockTimeline;
import '../thread_unread/thread_fakes.dart';

/// THR-M-06: the mobile sends threaded receipts only, like the web, so its
/// receipts on the room no longer clear the unread threads read on the web.
/// « Mark as read » in the room list is the exception (maintainer decision
/// 11/11): see test/utils/thread_unread/mark_room_and_all_threads_read_test.dart.
void main() {
  const roomId = '!room:example.com';
  const rootId = r'$root';

  late MockRoom room;
  late MockClient client;
  late bool flagBefore;

  Event message(String eventId) => _message(eventId, room);
  ThreadRef thread(String rootEventId) => ThreadRef(roomId, rootEventId);

  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    room = MockRoom();
    client = MockClient();
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(client.receiptsPublicByDefault).thenReturn(true);
  });

  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  group('with threads off', _threadsOffTests);

  void verifyNoUnthreadedReceipt() {
    verifyNever(client.postReceipt(any, any, any));
    verifyNever(
      client.setReadMarker(
        any,
        mFullyRead: anyNamed('mFullyRead'),
        mRead: argThat(isNotNull, named: 'mRead'),
        mReadPrivate: anyNamed('mReadPrivate'),
      ),
    );
    verifyNever(
      client.setReadMarker(
        any,
        mFullyRead: anyNamed('mFullyRead'),
        mRead: anyNamed('mRead'),
        mReadPrivate: argThat(isNotNull, named: 'mReadPrivate'),
      ),
    );
  }

  group('main timeline', () {
    test('reading the room sends a receipt on the main thread', () async {
      await room.setMainTimelineReadMarker(message(r'$last'));

      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mRead,
          r'$last',
          threadId: 'main',
        ),
      ).called(1);
      verifyNoUnthreadedReceipt();
    });

    test('m.fully_read keeps following the main timeline', () async {
      await room.setMainTimelineReadMarker(message(r'$last'));

      verify(client.setReadMarker(roomId, mFullyRead: r'$last')).called(1);
    });

    test('with private receipts the main thread receipt is private', () async {
      when(client.receiptsPublicByDefault).thenReturn(false);

      await room.setMainTimelineReadMarker(message(r'$last'));

      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mReadPrivate,
          r'$last',
          threadId: 'main',
        ),
      ).called(1);
      verifyNever(
        client.postReceipt(
          any,
          ReceiptType.mRead,
          any,
          threadId: anyNamed('threadId'),
        ),
      );
      verifyNoUnthreadedReceipt();
    });
  });

  group('thread screen', () {
    test(
      'reading a thread sends a receipt with the root as thread id',
      () async {
        await room.setThreadReadMarker(message(r'$reply'), thread(rootId));

        verify(
          client.postReceipt(
            roomId,
            ReceiptType.mRead,
            r'$reply',
            threadId: rootId,
          ),
        ).called(1);
        verifyNoUnthreadedReceipt();
      },
    );

    test('reading a thread does not move m.fully_read of the room', () async {
      await room.setThreadReadMarker(message(r'$reply'), thread(rootId));

      verifyNever(
        client.setReadMarker(
          any,
          mFullyRead: anyNamed('mFullyRead'),
          mRead: anyNamed('mRead'),
          mReadPrivate: anyNamed('mReadPrivate'),
        ),
      );
    });

    test('reading a thread sends nothing on the main thread', () async {
      await room.setThreadReadMarker(message(r'$reply'), thread(rootId));

      verifyNever(client.postReceipt(any, any, any, threadId: 'main'));
    });
  });

  /// The room screen reads the main timeline on every view update while it
  /// sits at the bottom. A receipt the server already has must not be sent
  /// again: one POST per update is useless traffic on a failing network.
  group('reading the main timeline again', () {
    late Room realRoom;
    late MockTimeline timeline;

    Event mainMessage(String eventId) => _message(eventId, realRoom);

    LatestReceiptStateForTimeline ownMain(String eventId) {
      final data = LatestReceiptStateData(
        eventId,
        DateTime.utc(2026, 11, 6, 10, 1).millisecondsSinceEpoch,
      );
      return LatestReceiptStateForTimeline(
        ownPrivate: null,
        ownPublic: data,
        latestOwnReceipt: data,
        otherUsers: {},
      );
    }

    void verifyNothingSent() {
      verifyNever(
        client.postReceipt(any, any, any, threadId: anyNamed('threadId')),
      );
      verifyNever(
        client.setReadMarker(
          any,
          mFullyRead: anyNamed('mFullyRead'),
          mRead: anyNamed('mRead'),
          mReadPrivate: anyNamed('mReadPrivate'),
        ),
      );
    }

    setUp(() {
      // An account whose old unthreaded receipt is far behind.
      final staleGlobal = LatestReceiptStateData(
        r'$old',
        DateTime.utc(2026, 10, 30).millisecondsSinceEpoch,
      );
      realRoom = Room(
        id: roomId,
        client: client,
        receiptState: LatestReceiptState(
          global: LatestReceiptStateForTimeline(
            ownPrivate: null,
            ownPublic: staleGlobal,
            latestOwnReceipt: staleGlobal,
            otherUsers: {},
          ),
          mainThread: ownMain(r'$last'),
        ),
      );
      timeline = MockTimeline();
      when(timeline.room).thenReturn(realRoom);
      when(
        timeline.events,
      ).thenReturn([mainMessage(r'$last'), mainMessage(r'$before')]);
    });

    test('sends nothing when the main receipt is already on the newest main '
        'event', () async {
      await timeline.setMainTimelineReadMarker();

      verifyNothingSent();
    });

    test('sends nothing when asked for the event the main receipt is already '
        'on', () async {
      await timeline.setMainTimelineReadMarker(event: mainMessage(r'$last'));

      verifyNothingSent();
    });

    test('a newer main event is read', () async {
      when(
        timeline.events,
      ).thenReturn([mainMessage(r'$newer'), mainMessage(r'$last')]);

      await timeline.setMainTimelineReadMarker();

      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mRead,
          r'$newer',
          threadId: 'main',
        ),
      ).called(1);
      verify(client.setReadMarker(roomId, mFullyRead: r'$newer')).called(1);
    });
  });
}

Event _message(String eventId, Room room) => Event(
  type: EventTypes.Message,
  content: {'msgtype': 'm.text', 'body': 'hello'},
  eventId: eventId,
  senderId: '@bob:example.com',
  originServerTs: DateTime.utc(2026, 11, 6, 10),
  room: room,
);

/// Review of #3608 (nqhhdev): `AppConfig.threadsEnabled` gates this level.
/// Off, the receipts are the ones of before threads: unthreaded (no
/// `thread_id`), so reading the room also reads its thread replies on the
/// server, and `m.fully_read` follows the read event.
void _threadsOffTests() {
  const roomId = '!room:example.com';
  const rootId = r'$root';

  late RecordingThreadClient client;
  late Room room;

  setUp(() {
    AppConfig.threadsEnabled = false;
    client = RecordingThreadClient();
    when(client.receiptsPublicByDefault).thenReturn(true);
    room = Room(id: roomId, client: client);
  });

  Event threadReply(String eventId) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': 'in the thread',
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'is_falling_back': true,
        'm.in_reply_to': {'event_id': rootId},
      },
    },
    eventId: eventId,
    senderId: '@bob:example.com',
    originServerTs: DateTime.utc(2026, 11, 6, 10, 5),
    room: room,
  );

  test('reading the room sends an unthreaded receipt on the event', () async {
    await room.setMainTimelineReadMarker(_message(r'$last', room));

    expect(client.receipts, [
      (eventId: r'$last', threadId: null, public: true),
    ]);
    expect(client.fullyRead, [r'$last']);
  });

  test('with private receipts the unthreaded receipt is private', () async {
    when(client.receiptsPublicByDefault).thenReturn(false);

    await room.setMainTimelineReadMarker(_message(r'$last', room));

    expect(client.receipts, [
      (eventId: r'$last', threadId: null, public: false),
    ]);
  });

  test('reading the room up to a thread reply reads the reply too', () async {
    // A real timeline: the SDK `Timeline.setReadMarker` of before threads
    // may serve.
    when(client.onTimelineEvent).thenReturn(CachedStreamController());
    when(client.onHistoryEvent).thenReturn(CachedStreamController());
    when(client.onSync).thenReturn(CachedStreamController());
    when(client.onCancelSendEvent).thenReturn(CachedStreamController());
    final timeline = Timeline(
      room: room,
      chunk: TimelineChunk(
        events: [threadReply(r'$reply'), _message(r'$main', room)],
      ),
    );
    addTearDown(timeline.cancelSubscriptions);

    await timeline.setMainTimelineReadMarker();

    expect(client.receipts, [
      (eventId: r'$reply', threadId: null, public: true),
    ]);
    expect(client.fullyRead, [r'$reply']);
  });
}
