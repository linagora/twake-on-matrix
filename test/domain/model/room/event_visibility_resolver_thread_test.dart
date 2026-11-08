import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/matrix_events/event_visibility_resolver.dart';

import 'room_extension_test.mocks.dart';

/// THR-M-01: thread replies stay out of the main timeline and out of the
/// chat-list "last message"; the root and classic replies stay.
void main() {
  late MockRoom room;

  const rootId = r'$root';

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn('!room:example.com');
  });

  Event message({
    required String eventId,
    String body = 'hello',
    Map<String, Object?>? relatesTo,
    Map<String, dynamic>? unsigned,
    String type = EventTypes.Message,
  }) => Event(
    type: type,
    content: {'msgtype': 'm.text', 'body': body, 'm.relates_to': ?relatesTo},
    eventId: eventId,
    senderId: '@alice:example.com',
    originServerTs: DateTime.utc(2026, 11, 6, 10),
    room: room,
    unsigned: unsigned,
  );

  Event threadReply({
    String eventId = r'$reply',
    String type = EventTypes.Message,
  }) => message(
    eventId: eventId,
    body: 'in the thread',
    type: type,
    relatesTo: {
      'rel_type': RelationshipTypes.thread,
      'event_id': rootId,
      'is_falling_back': true,
      'm.in_reply_to': {'event_id': rootId},
    },
  );

  group('main timeline', () {
    test('a thread reply is not shown in the main timeline', () {
      expect(
        EventVisibilityResolver.isVisibleInTimeline(threadReply()),
        isFalse,
      );
    });

    test(
      'a thread reply sent without the reply fallback is not shown either',
      () {
        final reply = message(
          eventId: r'$reply',
          relatesTo: {'rel_type': RelationshipTypes.thread, 'event_id': rootId},
        );

        expect(EventVisibilityResolver.isVisibleInTimeline(reply), isFalse);
      },
    );

    test('an undecryptable thread reply is not shown in the main timeline', () {
      // m.relates_to stays in clear outside the ciphertext.
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
        originServerTs: DateTime.utc(2026, 11, 6, 10),
        room: room,
      );

      expect(EventVisibilityResolver.isVisibleInTimeline(encrypted), isFalse);
    });

    test('the thread root stays in the main timeline', () {
      final root = message(
        eventId: rootId,
        body: 'root',
        unsigned: {
          'm.relations': {
            'm.thread': {
              'count': 2,
              'current_user_participated': false,
              'latest_event': {
                'event_id': r'$reply',
                'type': EventTypes.Message,
                'sender': '@bob:example.com',
                'origin_server_ts': 1,
                'content': {'msgtype': 'm.text', 'body': 'in the thread'},
              },
            },
          },
        },
      );

      expect(EventVisibilityResolver.isVisibleInTimeline(root), isTrue);
    });

    test(
      'a classic reply with only m.in_reply_to stays in the main timeline',
      () {
        final reply = message(
          eventId: r'$classic',
          relatesTo: {
            'm.in_reply_to': {'event_id': rootId},
          },
        );

        expect(EventVisibilityResolver.isVisibleInTimeline(reply), isTrue);
      },
    );
  });

  /// THR-M-01. Once deleted, a reply loses `m.relates_to` (event.dart:255-289)
  /// and nothing in the event says it was in a thread any more: the room
  /// Chat and the thread Chat would then both show it, with the same
  /// GlobalObjectKey. The thread counters store remembers the ids of the
  /// replies it saw ([ThreadUnreadStore.knownThreadReplyIds]).
  group('a deleted thread reply', () {
    Event deleted(Event event) =>
        Event.fromJson(event.toJson(), room)..setRedactionEvent(
          Event(
            type: EventTypes.Redaction,
            content: const {},
            eventId: r'$redaction',
            senderId: '@alice:example.com',
            originServerTs: DateTime.utc(2026, 11, 6, 11),
            redacts: event.eventId,
            room: room,
          ),
        );

    test('stays out of the main timeline when its id is known as a thread '
        'reply', () {
      final reply = deleted(threadReply());

      expect(
        EventVisibilityResolver.isVisibleInTimeline(
          reply,
          knownThreadReplyIds: {r'$reply'},
        ),
        isFalse,
      );
    });

    test('still shows, deleted, on the thread screen', () {
      final reply = deleted(threadReply());

      expect(
        EventVisibilityResolver.isVisibleInTimeline(
          reply,
          inThread: true,
          knownThreadReplyIds: {r'$reply'},
        ),
        isTrue,
      );
    });

    test('a deleted message of the room itself stays in the main '
        'timeline', () {
      final ordinary = deleted(message(eventId: r'$ordinary'));

      expect(
        EventVisibilityResolver.isVisibleInTimeline(
          ordinary,
          knownThreadReplyIds: {r'$reply'},
        ),
        isTrue,
      );
    });
  });

  group('chat list last message', () {
    test('a thread reply is not eligible as last message (sync check)', () {
      expect(
        EventVisibilityResolver.isEligibleForChatListPreviewSync(threadReply()),
        isFalse,
      );
    });

    test('a thread reply is not eligible as last message', () async {
      expect(
        await EventVisibilityResolver.isEligibleForChatListPreview(
          room,
          threadReply(),
        ),
        isFalse,
      );
    });

    test('an edit of a thread reply is not eligible as last message', () async {
      final reply = threadReply();
      when(room.getEventById(reply.eventId)).thenAnswer((_) async => reply);
      final edit = message(
        eventId: r'$edit',
        body: '* fixed',
        relatesTo: {
          'rel_type': RelationshipTypes.edit,
          'event_id': reply.eventId,
        },
      );
      edit.content['m.new_content'] = {'msgtype': 'm.text', 'body': 'fixed'};

      expect(
        await EventVisibilityResolver.isEligibleForChatListPreview(room, edit),
        isFalse,
      );
    });

    test('a classic reply stays eligible as last message', () async {
      final reply = message(
        eventId: r'$classic',
        relatesTo: {
          'm.in_reply_to': {'event_id': rootId},
        },
      );

      expect(
        await EventVisibilityResolver.isEligibleForChatListPreview(room, reply),
        isTrue,
      );
    });
  });
}
