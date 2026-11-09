import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';

import '../room/room_extension_test.mocks.dart';

/// Review 4515562061 (b): a deleted thread reply loses its `m.relates_to`,
/// so it no longer says it was in a thread. Taken as the newest event of the
/// main timeline, it got the `main` receipt and `m.fully_read`: a row the
/// room never shows, and the jump to it on opening fails. The ids of the
/// replies the app has seen in a thread tell them apart.
void main() {
  setUp(() {
    _room = MockRoom();
    when(_room.id).thenReturn(_roomId);
  });

  group('a deleted event as the main read target', _deletedEventTests);
}

const _roomId = '!room:example.com';
const _alice = '@alice:example.com';
const _deletedReplyId = r'$deleted_reply';

late MockRoom _room;

/// An event deleted by Alice: no content left, no relation.
Event _deleted(String eventId) => Event(
  type: EventTypes.Message,
  content: const {},
  eventId: eventId,
  senderId: _alice,
  originServerTs: DateTime.utc(2026, 11, 9, 11),
  unsigned: {
    'redacted_because': {
      'type': EventTypes.Redaction,
      'event_id': r'$redaction',
      'sender': _alice,
      'origin_server_ts': DateTime.utc(2026, 11, 9, 12).millisecondsSinceEpoch,
      'content': const {},
      'redacts': eventId,
    },
  },
  room: _room,
);

Event _mainMessage() => Event(
  type: EventTypes.Message,
  content: const {'msgtype': 'm.text', 'body': 'hi'},
  eventId: r'$main',
  senderId: _alice,
  originServerTs: DateTime.utc(2026, 11, 9, 10),
  room: _room,
);

String? _newestId(List<Event> events, Set<String> knownThreadReplyIds) =>
    ThreadRules.newestMainTimelineEvent(
      events,
      knownThreadReplyIds: knownThreadReplyIds,
    )?.eventId;

void _deletedEventTests() {
  test('a deleted reply known from its thread is skipped', () {
    expect(
      _newestId([_deleted(_deletedReplyId), _mainMessage()], {_deletedReplyId}),
      r'$main',
    );
  });

  test('a deleted message of the main timeline still gets the receipt', () {
    // It stays in the room as « message deleted ».
    expect(
      _newestId(
        [_deleted(r'$deleted_main'), _mainMessage()],
        {_deletedReplyId},
      ),
      r'$deleted_main',
    );
  });

  test('only deleted known replies: no event', () {
    expect(_newestId([_deleted(_deletedReplyId)], {_deletedReplyId}), isNull);
  });
}
