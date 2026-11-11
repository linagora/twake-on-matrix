import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../room_status_extension_test.mocks.dart' show MockTimeline;
import 'thread_fakes.dart';

/// Review 4515562061 (b), the two places that pick the main read target:
/// the room screen reading its timeline, and « Mark as read » in the room
/// list. A reply the app saw in a thread and that was deleted since (it lost
/// its `m.relates_to`) never gets the `main` receipt of the room screen nor
/// `m.fully_read`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _client = RecordingThreadClient();
    when(_client.clientName).thenReturn('account-a');
    when(_client.userID).thenReturn('@me:example.com');
    when(_client.receiptsPublicByDefault).thenReturn(true);
    _room = Room(id: _roomId, client: _client);
    // Seen live in its thread, before it was deleted.
    _client.threadUnread.rememberThreadReply(_liveReply());
  });

  test('the room screen reads the main message, not the deleted '
      'reply', () async {
    final timeline = MockTimeline();
    when(timeline.room).thenReturn(_room);
    when(timeline.events).thenReturn([_deletedReply(), _mainMessage()]);

    await timeline.setMainTimelineReadMarker();

    _verifyMainReadOnMainMessage();
  });

  /// Maintainer decision (11/11), nqhhdev 4521574499: the one unthreaded
  /// receipt of « Mark as read » lands on the newest event, the deleted
  /// reply here (MSC3771: unthreaded covers every thread). `m.fully_read`
  /// stays on the main message.
  test('« Mark as read » keeps m.fully_read on the main message, not on the '
      'deleted reply', () async {
    final main = _mainMessage();
    when(_client.database).thenReturn(StoredEvents([_deletedReply(), main]));
    _room.lastEvent = main;

    await _room.markRoomAndAllThreadsRead();

    expect(_client.fullyRead, [r'$main']);
    expect(_client.receipts, [
      (eventId: _replyId, threadId: null, public: true),
    ]);
  });
}

const _roomId = '!room:example.com';
const _rootId = r'$root';
const _replyId = r'$reply';
const _bob = '@bob:example.com';

late RecordingThreadClient _client;
late Room _room;

final _replySentAt = DateTime.utc(2026, 11, 9, 11);

Event _liveReply() => Event(
  type: EventTypes.Message,
  content: {
    'msgtype': 'm.text',
    'body': 'in the thread',
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': _rootId,
      'is_falling_back': true,
    },
  },
  eventId: _replyId,
  senderId: _bob,
  originServerTs: _replySentAt,
  room: _room,
);

/// The same reply once deleted: no content, no relation.
Event _deletedReply() => deletedEvent(
  eventId: _replyId,
  sender: _bob,
  room: _room,
  sentAt: _replySentAt,
);

Event _mainMessage() => Event(
  type: EventTypes.Message,
  content: const {'msgtype': 'm.text', 'body': 'hi'},
  eventId: r'$main',
  senderId: _bob,
  originServerTs: DateTime.utc(2026, 11, 9, 10),
  room: _room,
);

void _verifyMainReadOnMainMessage() {
  verify(
    _client.postReceipt(_roomId, ReceiptType.mRead, r'$main', threadId: 'main'),
  ).called(1);
  verifyNever(
    _client.postReceipt(any, any, _replyId, threadId: anyNamed('threadId')),
  );
  verifyNever(_client.setReadMarker(any, mFullyRead: _replyId));
}
