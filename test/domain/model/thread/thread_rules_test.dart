import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';

import '../room/room_extension_test.mocks.dart';

void main() {
  late MockRoom room;

  const rootId = r'$root';

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn('!room:example.com');
    when(room.canSendDefaultMessages).thenReturn(true);
  });

  Event message({Map<String, Object?>? relatesTo}) => Event(
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': 'hello', 'm.relates_to': ?relatesTo},
    eventId: r'$message',
    senderId: '@alice:example.com',
    originServerTs: DateTime.utc(2026, 11, 6),
    room: room,
  );

  Event undecryptable() => Event(
    type: EventTypes.Encrypted,
    content: {
      'algorithm': 'm.megolm.v1.aes-sha2',
      'ciphertext': 'AwgA',
      'session_id': 'unknown',
    },
    eventId: r'$encrypted',
    senderId: '@alice:example.com',
    originServerTs: DateTime.utc(2026, 11, 6),
    room: room,
  );

  /// THR-M-03: "Start a thread" in the message menu.
  group('Start a thread', () {
    test('is offered on a message without thread in a room the user can '
        'write in', () {
      expect(ThreadRules.canStartThread(message(), hasThread: false), isTrue);
    });

    test('is not offered when the user cannot write in the room', () {
      when(room.canSendDefaultMessages).thenReturn(false);

      expect(ThreadRules.canStartThread(message(), hasThread: false), isFalse);
    });

    test('is not offered on a message that already has a thread', () {
      // Only the card opens an existing thread.
      expect(ThreadRules.canStartThread(message(), hasThread: true), isFalse);
    });

    test('is not offered on an undecryptable message', () {
      expect(
        ThreadRules.canStartThread(undecryptable(), hasThread: false),
        isFalse,
      );
    });

    test('is not offered on a thread reply', () {
      final reply = message(
        relatesTo: {
          'rel_type': RelationshipTypes.thread,
          'event_id': rootId,
          'is_falling_back': true,
        },
      );

      expect(ThreadRules.canStartThread(reply, hasThread: false), isFalse);
    });

    test('is still offered on a classic reply', () {
      final reply = message(
        relatesTo: {
          'm.in_reply_to': {'event_id': rootId},
        },
      );

      expect(ThreadRules.canStartThread(reply, hasThread: false), isTrue);
    });

    test('is not offered inside the thread screen', () {
      // THR-M-04: no "Start a thread" in a thread, even on its root.
      expect(
        ThreadRules.canStartThread(
          message(),
          hasThread: false,
          inThreadScreen: true,
        ),
        isFalse,
      );
    });
  });

  /// THR-M-06, spec §4 « Reçus » (`thread_id = main`).
  ///
  /// Synapse refuses a `main` receipt on an event related, even
  /// through a reaction or an edit, to a thread event. The one "last event of
  /// the main timeline" every main receipt targets.
  group('newest event of the main timeline', () {
    Event event({
      required String eventId,
      String type = EventTypes.Message,
      Map<String, Object?> content = const {'msgtype': 'm.text', 'body': 'hi'},
      EventStatus status = EventStatus.synced,
      String? redacts,
    }) => Event(
      type: type,
      content: content,
      eventId: eventId,
      senderId: '@alice:example.com',
      originServerTs: DateTime.utc(2026, 11, 6),
      status: status,
      redacts: redacts,
      room: room,
    );

    Event threadReply() => event(
      eventId: r'$reply',
      content: {
        'msgtype': 'm.text',
        'body': 'in the thread',
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': rootId,
          'is_falling_back': true,
        },
      },
    );
    Event mainMessage() => event(eventId: r'$main');

    test('a reaction to a thread reply is skipped', () {
      final reaction = event(
        eventId: r'$reaction',
        type: EventTypes.Reaction,
        content: {
          'm.relates_to': {
            'rel_type': RelationshipTypes.reaction,
            'event_id': r'$reply',
            'key': '👍',
          },
        },
      );

      expect(
        ThreadRules.newestMainTimelineEvent([
          reaction,
          threadReply(),
          mainMessage(),
        ])?.eventId,
        r'$main',
      );
    });

    test('an edit is skipped', () {
      final edit = event(
        eventId: r'$edit',
        content: {
          'msgtype': 'm.text',
          'body': '* fixed',
          'm.new_content': {'msgtype': 'm.text', 'body': 'fixed'},
          'm.relates_to': {
            'rel_type': RelationshipTypes.edit,
            'event_id': r'$reply',
          },
        },
      );

      expect(
        ThreadRules.newestMainTimelineEvent([edit, mainMessage()])?.eventId,
        r'$main',
      );
    });

    test('a redaction event is skipped', () {
      final redaction = event(
        eventId: r'$redaction',
        type: EventTypes.Redaction,
        content: const {},
        redacts: r'$reply',
      );

      expect(
        ThreadRules.newestMainTimelineEvent([
          redaction,
          mainMessage(),
        ])?.eventId,
        r'$main',
      );
    });

    test('a message still being sent is skipped', () {
      final pending = event(
        eventId: 'transaction-1',
        status: EventStatus.sending,
      );

      expect(
        ThreadRules.newestMainTimelineEvent([pending, mainMessage()])?.eventId,
        r'$main',
      );
    });

    test('a message that failed to send is skipped', () {
      final failed = event(eventId: 'transaction-2', status: EventStatus.error);

      expect(
        ThreadRules.newestMainTimelineEvent([failed, mainMessage()])?.eventId,
        r'$main',
      );
    });

    test('a thread reply is skipped', () {
      expect(
        ThreadRules.newestMainTimelineEvent([
          threadReply(),
          mainMessage(),
        ])?.eventId,
        r'$main',
      );
    });

    test('the newest plain message is returned', () {
      expect(
        ThreadRules.newestMainTimelineEvent([
          mainMessage(),
          event(eventId: r'$older'),
        ])?.eventId,
        r'$main',
      );
    });

    test('nothing eligible gives no event', () {
      expect(
        ThreadRules.newestMainTimelineEvent([
          threadReply(),
          event(eventId: 'transaction-1', status: EventStatus.sending),
        ]),
        isNull,
      );
    });

    test('an empty timeline gives no event', () {
      expect(ThreadRules.newestMainTimelineEvent(const []), isNull);
    });
  });
}
