import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';

import '../room/room_extension_test.mocks.dart';

/// THR-M-11: the thread of a reply is read from its `m.relates_to`
/// (`rel_type: m.thread`, `event_id`), so links, search results and the
/// thread screen's live filter can find it.
void main() {
  late MockRoom room;

  const rootId = r'$root';

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn('!room:example.com');
  });

  Event event({
    String type = EventTypes.Message,
    Map<String, Object?>? relatesTo,
    EventStatus status = EventStatus.synced,
  }) => Event(
    type: type,
    content: {'msgtype': 'm.text', 'body': 'text', 'm.relates_to': ?relatesTo},
    eventId: r'$event',
    senderId: '@alice:example.com',
    originServerTs: DateTime.utc(2026, 11, 6),
    room: room,
    status: status,
  );

  test('a thread reply gives the id of its root', () {
    final reply = event(
      relatesTo: {
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'is_falling_back': true,
        'm.in_reply_to': {'event_id': r'$previous'},
      },
    );

    expect(reply.threadRootId, rootId);
  });

  test('the root is read from event_id, not from the reply fallback', () {
    final reply = event(
      relatesTo: {
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'm.in_reply_to': {'event_id': r'$quoted'},
      },
    );

    expect(reply.threadRootId, rootId);
  });

  test('an undecryptable thread reply still gives its root', () {
    final encrypted = Event(
      type: EventTypes.Encrypted,
      content: {
        'algorithm': 'm.megolm.v1.aes-sha2',
        'ciphertext': 'AwgA',
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': rootId,
        },
      },
      eventId: r'$encrypted',
      senderId: '@alice:example.com',
      originServerTs: DateTime.utc(2026, 11, 6),
      room: room,
    );

    expect(encrypted.threadRootId, rootId);
  });

  test('a reply still sending or in error belongs to its thread', () {
    // Local echo and "Retry" in the thread screen rely on this.
    final relation = {
      'rel_type': RelationshipTypes.thread,
      'event_id': rootId,
      'is_falling_back': true,
    };

    expect(
      event(relatesTo: relation, status: EventStatus.sending).threadRootId,
      rootId,
    );
    expect(
      event(relatesTo: relation, status: EventStatus.error).threadRootId,
      rootId,
    );
  });

  test('a classic reply has no thread', () {
    final reply = event(
      relatesTo: {
        'm.in_reply_to': {'event_id': rootId},
      },
    );

    expect(reply.threadRootId, isNull);
  });

  test('an edit has no thread of its own', () {
    final edit = event(
      relatesTo: {'rel_type': RelationshipTypes.edit, 'event_id': rootId},
    );

    expect(edit.threadRootId, isNull);
  });

  test('a reaction has no thread', () {
    final reaction = event(
      type: EventTypes.Reaction,
      relatesTo: {
        'rel_type': RelationshipTypes.reaction,
        'event_id': rootId,
        'key': '👍',
      },
    );

    expect(reaction.threadRootId, isNull);
  });

  test('a plain message has no thread', () {
    expect(event().threadRootId, isNull);
  });

  test('a malformed thread relation without event_id has no thread', () {
    final broken = event(relatesTo: {'rel_type': RelationshipTypes.thread});

    expect(broken.threadRootId, isNull);
  });
}
