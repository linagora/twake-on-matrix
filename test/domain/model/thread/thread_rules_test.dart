import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';

import '../room/room_extension_test.mocks.dart';

void main() {
  setUp(() {
    _room = MockRoom();
    when(_room.id).thenReturn('!room:example.com');
    when(_room.canSendDefaultMessages).thenReturn(true);
  });

  /// THR-M-03: "Start a thread" in the message menu.
  group('Start a thread', _startThreadTests);

  /// THR-M-06, spec §4 « Reçus » (`thread_id = main`).
  ///
  /// Synapse refuses a `main` receipt on an event related, even
  /// through a reaction or an edit, to a thread event. The one "last event of
  /// the main timeline" every main receipt targets.
  group('newest event of the main timeline', _newestMainEventTests);
}

late MockRoom _room;

const _rootId = r'$root';

const _threadRelation = {
  'rel_type': RelationshipTypes.thread,
  'event_id': _rootId,
  'is_falling_back': true,
};

Event _event({
  required String eventId,
  String type = EventTypes.Message,
  Map<String, Object?> content = const {'msgtype': 'm.text', 'body': 'hello'},
  EventStatus status = EventStatus.synced,
  String? stateKey,
  String? redacts,
}) => Event(
  type: type,
  content: content,
  eventId: eventId,
  senderId: '@alice:example.com',
  stateKey: stateKey,
  originServerTs: DateTime.utc(2026, 11, 6),
  status: status,
  redacts: redacts,
  room: _room,
);

Event _message({Map<String, Object?>? relatesTo}) => _event(
  eventId: r'$message',
  content: {'msgtype': 'm.text', 'body': 'hello', 'm.relates_to': ?relatesTo},
);

Event _undecryptable() => _event(
  eventId: r'$encrypted',
  type: EventTypes.Encrypted,
  content: const {
    'algorithm': 'm.megolm.v1.aes-sha2',
    'ciphertext': 'AwgA',
    'session_id': 'unknown',
  },
);

/// Whether "Start a thread" is offered on [event], which has no thread.
bool _offered(Event event) =>
    ThreadRules.canStartThread(event, hasThread: false);

void _startThreadTests() {
  test('is offered on a message without thread in a room the user can '
      'write in', () {
    expect(_offered(_message()), isTrue);
  });

  test('is not offered when the user cannot write in the room', () {
    when(_room.canSendDefaultMessages).thenReturn(false);

    expect(_offered(_message()), isFalse);
  });

  test('is not offered on a message that already has a thread', () {
    // Only the card opens an existing thread.
    expect(ThreadRules.canStartThread(_message(), hasThread: true), isFalse);
  });

  test('is not offered on an undecryptable message', () {
    expect(_offered(_undecryptable()), isFalse);
  });

  test('is not offered on a thread reply', () {
    expect(_offered(_message(relatesTo: _threadRelation)), isFalse);
  });

  test('is still offered on a classic reply', () {
    final reply = _message(
      relatesTo: {
        'm.in_reply_to': {'event_id': _rootId},
      },
    );

    expect(_offered(reply), isTrue);
  });

  // A thread starts on a message the server has: its replies point to the
  // root's event id, which a message still being sent (or that failed)
  // does not have yet.
  test('is not offered on a message still being sent', () {
    final pending = _event(
      eventId: 'transaction-1',
      status: EventStatus.sending,
    );

    expect(_offered(pending), isFalse);
  });

  test('is not offered on a message that failed to send', () {
    final failed = _event(eventId: 'transaction-2', status: EventStatus.error);

    expect(_offered(failed), isFalse);
  });

  // THR-M-03 offers it in "the menu of a message": a membership change, a
  // reaction or a deletion is not a message.
  for (final (type, content) in [
    (EventTypes.RoomMember, <String, Object?>{'membership': 'join'}),
    (
      EventTypes.Reaction,
      <String, Object?>{
        'm.relates_to': {
          'rel_type': RelationshipTypes.reaction,
          'event_id': r'$message',
          'key': '👍',
        },
      },
    ),
    (EventTypes.Redaction, <String, Object?>{}),
  ]) {
    test('is not offered on a $type event', () {
      final event = _event(
        eventId: r'$not_a_message',
        type: type,
        content: content,
        stateKey: type == EventTypes.RoomMember ? '@alice:example.com' : null,
      );

      expect(_offered(event), isFalse);
    });
  }

  test('is not offered inside the thread screen', () {
    // THR-M-04: no "Start a thread" in a thread, even on its root.
    expect(
      ThreadRules.canStartThread(
        _message(),
        hasThread: false,
        inThreadScreen: true,
      ),
      isFalse,
    );
  });
}

Event _threadReply() => _event(
  eventId: r'$reply',
  content: const {
    'msgtype': 'm.text',
    'body': 'in the thread',
    'm.relates_to': _threadRelation,
  },
);

Event _mainMessage() => _event(
  eventId: r'$main',
  content: const {'msgtype': 'm.text', 'body': 'hi'},
);

String? _newestId(List<Event> events) =>
    ThreadRules.newestMainTimelineEvent(events)?.eventId;

void _newestMainEventTests() {
  test('a reaction to a thread reply is skipped', () {
    final reaction = _event(
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

    expect(_newestId([reaction, _threadReply(), _mainMessage()]), r'$main');
  });

  test('an edit is skipped', () {
    final edit = _event(
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

    expect(_newestId([edit, _mainMessage()]), r'$main');
  });

  test('a redaction event is skipped', () {
    final redaction = _event(
      eventId: r'$redaction',
      type: EventTypes.Redaction,
      content: const {},
      redacts: r'$reply',
    );

    expect(_newestId([redaction, _mainMessage()]), r'$main');
  });

  test('a message still being sent is skipped', () {
    final pending = _event(
      eventId: 'transaction-1',
      status: EventStatus.sending,
    );

    expect(_newestId([pending, _mainMessage()]), r'$main');
  });

  test('a message that failed to send is skipped', () {
    final failed = _event(eventId: 'transaction-2', status: EventStatus.error);

    expect(_newestId([failed, _mainMessage()]), r'$main');
  });

  test('a thread reply is skipped', () {
    expect(_newestId([_threadReply(), _mainMessage()]), r'$main');
  });

  test('the newest plain message is returned', () {
    expect(_newestId([_mainMessage(), _event(eventId: r'$older')]), r'$main');
  });

  test('nothing eligible gives no event', () {
    expect(
      ThreadRules.newestMainTimelineEvent([
        _threadReply(),
        _event(eventId: 'transaction-1', status: EventStatus.sending),
      ]),
      isNull,
    );
  });

  test('an empty timeline gives no event', () {
    expect(ThreadRules.newestMainTimelineEvent(const []), isNull);
  });
}
