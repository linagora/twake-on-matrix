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
}
