import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_summary.dart';

import '../../../domain/model/room/room_extension_test.mocks.dart';

/// THR-M-02: the card under a root shows the number of replies and the last
/// reply, built from the server aggregation (`unsigned.m.relations.m.thread`)
/// and kept up to date with the replies received live.
/// With `AppConfig.threadsEnabled` on; off, see threads_disabled_test.dart.
void main() {
  late MockRoom room;
  late bool flagBefore;

  const alice = '@alice:example.com';
  const bob = '@bob:example.com';
  const rootId = r'$root';

  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    room = MockRoom();
    when(room.id).thenReturn('!room:example.com');
    // The members the room knows: a name, and a picture for Bob alone.
    when(room.unsafeGetUserFromMemoryOrFallback(any)).thenAnswer((call) {
      final id = call.positionalArguments.first as String;
      return User(
        id,
        room: room,
        displayName: _names[id],
        avatarUrl: id == bob ? 'mxc://example.com/bob' : null,
      );
    });
  });

  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  const carol = '@carol:example.com';
  const dan = '@dan:example.com';

  DateTime at(int minute) => DateTime.utc(2026, 11, 6, 10, minute);

  Map<String, Object?> threadRelation(String root) => {
    'rel_type': RelationshipTypes.thread,
    'event_id': root,
    'is_falling_back': true,
  };

  Map<String, Object?> replyJson({
    required String eventId,
    required String body,
    required int minute,
    String sender = bob,
  }) => {
    'event_id': eventId,
    'type': EventTypes.Message,
    'sender': sender,
    'origin_server_ts': at(minute).millisecondsSinceEpoch,
    'content': {
      'msgtype': 'm.text',
      'body': body,
      'm.relates_to': threadRelation(rootId),
    },
  };

  Event root({
    int? count,
    Map<String, Object?>? latest,
    bool participated = false,
    String sender = alice,
    String body = 'Root text',
  }) => Event(
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': body},
    eventId: rootId,
    senderId: sender,
    originServerTs: at(0),
    room: room,
    unsigned: count == null
        ? null
        : {
            'm.relations': {
              'm.thread': {
                'count': count,
                'current_user_participated': participated,
                'latest_event': ?latest,
              },
            },
          },
  );

  Event reply({
    required String eventId,
    required String body,
    required int minute,
    String sender = bob,
    String threadRoot = rootId,
  }) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': body,
      'm.relates_to': threadRelation(threadRoot),
    },
    eventId: eventId,
    senderId: sender,
    originServerTs: at(minute),
    room: room,
  );

  Event edit({
    required String eventId,
    required String target,
    required String newBody,
    required int minute,
  }) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': '* $newBody',
      'm.new_content': {'msgtype': 'm.text', 'body': newBody},
      'm.relates_to': {'rel_type': RelationshipTypes.edit, 'event_id': target},
    },
    eventId: eventId,
    senderId: bob,
    originServerTs: at(minute),
    room: room,
  );

  Event reaction({required String target, required int minute}) => Event(
    type: EventTypes.Reaction,
    content: {
      'm.relates_to': {
        'rel_type': RelationshipTypes.reaction,
        'event_id': target,
        'key': '👍',
      },
    },
    eventId: r'$reaction',
    senderId: alice,
    originServerTs: at(minute),
    room: room,
  );

  final serverLatest = replyJson(
    eventId: r'$r2',
    body: 'See you tomorrow',
    minute: 2,
  );

  group('no card', () {
    test('a message without replies has no thread summary', () {
      expect(ThreadSummary.fromRoot(root()), isNull);
    });

    test('a root whose server count is zero has no thread summary', () {
      // "Start a thread" opened then left without sending anything.
      expect(ThreadSummary.fromRoot(root(count: 0)), isNull);
    });

    test('replies to another root do not make a card', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(
            eventId: r'$other',
            body: 'elsewhere',
            minute: 3,
            threadRoot: r'$another_root',
          ),
        ],
      );

      expect(summary, isNull);
    });
  });

  group('from the server aggregation', () {
    test('the summary has the server count and latest reply', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
      )!;

      expect(summary.rootEventId, rootId);
      expect(summary.replyCount, 2);
      expect(summary.lastReply?.eventId, r'$r2');
      expect(summary.lastReply?.senderId, bob);
      expect(summary.lastReplyText, 'See you tomorrow');
    });

    test('the last reply is never the root text', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 1, latest: serverLatest, body: 'Root text'),
      )!;

      expect(summary.lastReplyText, isNot('Root text'));
      expect(summary.lastReply?.eventId, isNot(rootId));
    });
  });

  group('live replies', () {
    test('a new reply received by sync raises the count and becomes the '
        'last reply', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [reply(eventId: r'$r3', body: 'Fine by me', minute: 5)],
      )!;

      expect(summary.replyCount, 3);
      expect(summary.lastReply?.eventId, r'$r3');
      expect(summary.lastReplyText, 'Fine by me');
    });

    test('replies on a root without aggregation are counted', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r2', body: 'second', minute: 2),
          reply(eventId: r'$r1', body: 'first', minute: 1),
        ],
      )!;

      expect(summary.replyCount, 2);
      expect(summary.lastReply?.eventId, r'$r2');
      expect(summary.lastReplyText, 'second');
    });

    test('the server latest reply received again is not counted twice', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [
          reply(eventId: r'$r2', body: 'See you tomorrow', minute: 2),
        ],
      )!;

      expect(summary.replyCount, 2);
      expect(summary.lastReply?.eventId, r'$r2');
    });

    test(
      'an older reply already counted by the server is not counted again',
      () {
        final summary = ThreadSummary.fromRoot(
          root(count: 2, latest: serverLatest),
          liveEvents: [reply(eventId: r'$r1', body: 'Hello', minute: 1)],
        )!;

        expect(summary.replyCount, 2);
        expect(summary.lastReply?.eventId, r'$r2');
        expect(summary.lastReplyText, 'See you tomorrow');
      },
    );
  });

  group('edits, reactions and redactions', () {
    test(
      'a reaction to the last reply changes neither count nor last reply',
      () {
        final summary = ThreadSummary.fromRoot(
          root(count: 2, latest: serverLatest),
          liveEvents: [reaction(target: r'$r2', minute: 6)],
        )!;

        expect(summary.replyCount, 2);
        expect(summary.lastReply?.eventId, r'$r2');
        expect(summary.lastReplyText, 'See you tomorrow');
      },
    );

    test('an edit of the last reply changes the text shown, not the count', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [
          edit(
            eventId: r'$e1',
            target: r'$r2',
            newBody: 'See you on Monday',
            minute: 7,
          ),
        ],
      )!;

      expect(summary.replyCount, 2);
      expect(summary.lastReply?.eventId, r'$r2');
      expect(summary.lastReplyText, 'See you on Monday');
    });

    test('the most recent edit of the last reply wins', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [
          edit(
            eventId: r'$e2',
            target: r'$r2',
            newBody: 'Second edit',
            minute: 9,
          ),
          edit(
            eventId: r'$e1',
            target: r'$r2',
            newBody: 'First edit',
            minute: 8,
          ),
        ],
      )!;

      expect(summary.lastReplyText, 'Second edit');
    });

    test('an edit of an older reply does not change the last reply text', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r1', body: 'first', minute: 1),
          reply(eventId: r'$r2', body: 'second', minute: 2),
          edit(
            eventId: r'$e1',
            target: r'$r1',
            newBody: 'first fixed',
            minute: 3,
          ),
        ],
      )!;

      expect(summary.replyCount, 2);
      expect(summary.lastReplyText, 'second');
    });

    test('a deleted last reply is skipped for the previous one', () {
      final deleted = reply(eventId: r'$r2', body: 'oops', minute: 2);
      deleted.setRedactionEvent(
        Event(
          type: EventTypes.Redaction,
          content: {},
          eventId: r'$redaction',
          senderId: bob,
          originServerTs: at(3),
          room: room,
        ),
      );

      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r1', body: 'first', minute: 1),
          deleted,
        ],
      )!;

      expect(summary.lastReply?.eventId, r'$r1');
      expect(summary.lastReplyText, 'first');
    });
  });

  /// CodeRabbit 4515287978: only an edit made by the sender of the reply,
  /// as an `m.room.message`, replaces its text (Matrix spec, `m.replace`;
  /// the SDK `Event.getDisplayEvent` keeps the same ones).
  group('edits that do not change the card', () {
    Event bySender(Event event, String sender) =>
        Event.fromJson({...event.toJson(), 'sender': sender}, room);

    test('an edit of the last reply by another member does not change the '
        'text shown', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [
          bySender(
            edit(
              eventId: r'$e1',
              target: r'$r2',
              newBody: 'Text written by Alice',
              minute: 7,
            ),
            alice,
          ),
        ],
      )!;

      expect(summary.lastReplyText, 'See you tomorrow');
    });

    test('a newer edit that cannot be read does not hide the edit of the '
        'sender', () {
      // Its `m.relates_to` stays in clear, its new content does not.
      final undecrypted = Event(
        type: EventTypes.Encrypted,
        content: {
          'algorithm': 'm.megolm.v1.aes-sha2',
          'ciphertext': 'AwgA',
          'session_id': 'unknown',
          'm.relates_to': {
            'rel_type': RelationshipTypes.edit,
            'event_id': r'$r2',
          },
        },
        eventId: r'$e2',
        senderId: bob,
        originServerTs: at(8),
        room: room,
      );

      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [
          edit(
            eventId: r'$e1',
            target: r'$r2',
            newBody: 'See you on Monday',
            minute: 7,
          ),
          undecrypted,
        ],
      )!;

      expect(summary.lastReplyText, 'See you on Monday');
    });
  });

  /// CodeRabbit 4515288006: a reply that quotes a message of the thread
  /// carries the quote fallback in its body (SDK `Room.sendEvent`); the card
  /// shows the reply itself, as the SDK `calcLocalizedBodyFallback(
  /// hideReply: true, hideEdit: true)` does.
  group('a last reply that quotes another message', () {
    const quoting =
        '> <@alice:example.com> Root text\n'
        '\n'
        'Actual reply';

    test('the card shows the reply without the quote', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [reply(eventId: r'$r1', body: quoting, minute: 1)],
      )!;

      expect(summary.lastReplyText, 'Actual reply');
    });

    test('the card shows the reply without the quote when it comes from '
        'the server aggregation', () {
      final summary = ThreadSummary.fromRoot(
        root(
          count: 1,
          latest: replyJson(eventId: r'$r1', body: quoting, minute: 1),
        ),
      )!;

      expect(summary.lastReplyText, 'Actual reply');
    });
  });

  /// THR-M-02 (last reply on the card), spec §1 « Chiffrement ».
  ///
  /// In an E2EE room `unsigned.m.relations.m.thread.latest_event`
  /// is the raw `m.room.encrypted` event; only the live copy is decrypted.
  group('encrypted room', () {
    Map<String, Object?> encryptedJson({
      required String eventId,
      required int minute,
    }) => {
      'event_id': eventId,
      'type': EventTypes.Encrypted,
      'sender': bob,
      'origin_server_ts': at(minute).millisecondsSinceEpoch,
      'content': {
        'algorithm': 'm.megolm.v1.aes-sha2',
        'ciphertext': 'AwgAEnACgAkLmt6qF84IK++J7UDH2Za1YVchHyprqTqsg',
        'device_id': 'BOBDEVICE',
        'sender_key': 'sGeUBZ2bWuMtA7r5bQ2EtgK6mF0RwXzBEPjL8tCaDX0',
        'session_id': 'ZDiaWXGq5Gq8mXkP7dL0Ft7ufY5Vmbq3GEjTb1fuq1o',
        // Kept in clear so the server can aggregate the thread.
        'm.relates_to': threadRelation(rootId),
      },
    };

    test('the decrypted live copy of the server latest reply is shown, and '
        'not counted twice', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: encryptedJson(eventId: r'$r2', minute: 2)),
        liveEvents: [
          reply(eventId: r'$r2', body: 'See you tomorrow', minute: 2),
        ],
      )!;

      expect(summary.replyCount, 2);
      expect(summary.lastReply?.eventId, r'$r2');
      expect(summary.lastReplyText, 'See you tomorrow');
      expect(summary.lastReply?.type, EventTypes.Message);
    });

    test('a deleted server latest reply gives way to the previous reply '
        'known live', () {
      final deleted = reply(eventId: r'$r2', body: 'oops', minute: 2)
        ..setRedactionEvent(
          Event(
            type: EventTypes.Redaction,
            content: {},
            redacts: r'$r2',
            eventId: r'$redaction',
            senderId: bob,
            originServerTs: at(3),
            room: room,
          ),
        );

      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: encryptedJson(eventId: r'$r2', minute: 2)),
        liveEvents: [
          reply(eventId: r'$r1', body: 'first', minute: 1),
          deleted,
        ],
      )!;

      expect(summary.lastReply?.eventId, r'$r1');
      expect(summary.lastReplyText, 'first');
    });

    test('a deleted server latest reply with no other reply known shows no '
        'last reply and is not counted any more', () {
      final deleted = reply(eventId: r'$r2', body: 'oops', minute: 2)
        ..setRedactionEvent(
          Event(
            type: EventTypes.Redaction,
            content: {},
            redacts: r'$r2',
            eventId: r'$redaction',
            senderId: bob,
            originServerTs: at(3),
            room: room,
          ),
        );

      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: encryptedJson(eventId: r'$r2', minute: 2)),
        liveEvents: [deleted],
      );

      expect(summary, isNotNull);
      expect(summary!.replyCount, 1);
      expect(summary.lastReply, isNull);
      expect(summary.lastReplyText, isNull);
    });

    test('a deleted server latest reply is not counted: the thread screen '
        'shows one reply less', () {
      final deleted = reply(eventId: r'$r2', body: 'oops', minute: 2)
        ..setRedactionEvent(
          Event(
            type: EventTypes.Redaction,
            content: {},
            redacts: r'$r2',
            eventId: r'$redaction',
            senderId: bob,
            originServerTs: at(3),
            room: room,
          ),
        );

      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: encryptedJson(eventId: r'$r2', minute: 2)),
        liveEvents: [
          reply(eventId: r'$r1', body: 'first', minute: 1),
          deleted,
        ],
      )!;

      expect(summary.replyCount, 1);
    });
  });

  /// Need (Clément, 2026-11-25, as the web D800 `readRepliers`): the row of
  /// the thread shows the faces of who replied, from the replies the client
  /// holds (server latest reply + live replies): each person once, the most
  /// recent replier first; a deleted reply, an edit or a reaction brings
  /// nobody. The count stays the server count.
  group('the people who replied', () {
    List<String> ids(ThreadSummary summary) => [
      for (final replier in summary.repliers) replier.userId,
    ];

    Event deleted(Event event) => event
      ..setRedactionEvent(
        Event(
          type: EventTypes.Redaction,
          content: {},
          redacts: event.eventId,
          eventId: r'$redaction',
          senderId: event.senderId,
          originServerTs: at(30),
          room: room,
        ),
      );

    test('lists each person once, the most recent replier first', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r1', body: 'one', minute: 1, sender: bob),
          reply(eventId: r'$r2', body: 'two', minute: 2, sender: carol),
          reply(eventId: r'$r3', body: 'three', minute: 3, sender: bob),
          reply(eventId: r'$r4', body: 'four', minute: 4, sender: dan),
        ],
      )!;

      expect(ids(summary), [dan, bob, carol]);
    });

    test('orders by the time of the replies, not by the order received', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r4', body: 'four', minute: 4, sender: dan),
          reply(eventId: r'$r1', body: 'one', minute: 1, sender: bob),
          reply(eventId: r'$r2', body: 'two', minute: 2, sender: carol),
        ],
      )!;

      expect(ids(summary), [dan, carol, bob]);
    });

    test('an old thread with no reply loaded shows the sender of the server '
        'latest reply, and keeps the server count', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 7, latest: serverLatest),
      )!;

      expect(ids(summary), [bob]);
      expect(summary.replyCount, 7);
    });

    test('the server latest reply and the live replies make one list, the '
        'latest reply counted once', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [
          reply(eventId: r'$r1', body: 'Hello', minute: 1, sender: carol),
          // The live copy of the server latest reply.
          reply(eventId: r'$r2', body: 'See you tomorrow', minute: 2),
          reply(eventId: r'$r3', body: 'Fine', minute: 5, sender: dan),
        ],
      )!;

      expect(ids(summary), [dan, bob, carol]);
    });

    test('leaves out the author of the root who did not reply', () {
      final summary = ThreadSummary.fromRoot(
        root(sender: alice),
        liveEvents: [reply(eventId: r'$r1', body: 'one', minute: 1)],
      )!;

      expect(ids(summary), [bob]);
    });

    test('lists the author of the root who also replied', () {
      final summary = ThreadSummary.fromRoot(
        root(sender: alice),
        liveEvents: [
          reply(eventId: r'$r1', body: 'one', minute: 1, sender: bob),
          reply(eventId: r'$r2', body: 'two', minute: 2, sender: alice),
        ],
      )!;

      expect(ids(summary), [alice, bob]);
    });

    test('a deleted reply brings nobody', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r1', body: 'one', minute: 1, sender: bob),
          deleted(
            reply(eventId: r'$r2', body: 'oops', minute: 2, sender: carol),
          ),
        ],
      )!;

      expect(ids(summary), [bob]);
    });

    test('a deleted server latest reply brings nobody', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [
          reply(eventId: r'$r1', body: 'Hello', minute: 1, sender: carol),
          deleted(reply(eventId: r'$r2', body: 'See you tomorrow', minute: 2)),
        ],
      )!;

      expect(ids(summary), [carol]);
    });

    test('an edit or a reaction brings nobody', () {
      final summary = ThreadSummary.fromRoot(
        root(count: 2, latest: serverLatest),
        liveEvents: [
          // By Alice, who never replied.
          reaction(target: r'$r2', minute: 6),
          Event.fromJson({
            ...edit(
              eventId: r'$e1',
              target: r'$r2',
              newBody: 'edited',
              minute: 7,
            ).toJson(),
            'sender': dan,
          }, room),
        ],
      )!;

      expect(ids(summary), [bob]);
    });

    test('replies to another thread bring nobody', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r1', body: 'one', minute: 1, sender: bob),
          reply(
            eventId: r'$other',
            body: 'elsewhere',
            minute: 2,
            sender: dan,
            threadRoot: r'$another_root',
          ),
        ],
      )!;

      expect(ids(summary), [bob]);
    });

    test('keeps every person, past the three the row shows', () {
      const eve = '@eve:example.com';
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r1', body: '1', minute: 1, sender: alice),
          reply(eventId: r'$r2', body: '2', minute: 2, sender: bob),
          reply(eventId: r'$r3', body: '3', minute: 3, sender: carol),
          reply(eventId: r'$r4', body: '4', minute: 4, sender: dan),
          reply(eventId: r'$r5', body: '5', minute: 5, sender: eve),
        ],
      )!;

      expect(ids(summary), [eve, dan, carol, bob, alice]);
    });

    test('gives each one their name and picture as the room knows them', () {
      final summary = ThreadSummary.fromRoot(
        root(),
        liveEvents: [
          reply(eventId: r'$r1', body: 'one', minute: 1, sender: bob),
          reply(eventId: r'$r2', body: 'two', minute: 2, sender: carol),
        ],
      )!;

      final [carolFace, bobFace] = summary.repliers;
      expect(carolFace.displayName, 'Carol Jones');
      expect(carolFace.avatarUrl, isNull);
      expect(bobFace.displayName, 'Bob Martin');
      expect(bobFace.avatarUrl, Uri.parse('mxc://example.com/bob'));
    });
  });
}

/// The display names of the members of the room.
const _names = {
  '@alice:example.com': 'Alice Smith',
  '@bob:example.com': 'Bob Martin',
  '@carol:example.com': 'Carol Jones',
  '@dan:example.com': 'Dan Brown',
};
