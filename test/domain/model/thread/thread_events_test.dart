import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_events.dart';

import '../room/room_extension_test.mocks.dart';

typedef _Page = ({List<Event> events, String? nextBatch});

/// `/relations/<root>?recurse=true&dir=b` on a server the test drives: every
/// call waits until the test answers it or makes it fail.
class _Server {
  final List<String?> calls = [];
  final List<Completer<_Page>> _pending = [];

  Future<_Page> fetchPage(String? from) {
    calls.add(from);
    final completer = Completer<_Page>();
    _pending.add(completer);
    return completer.future;
  }

  /// Answers the oldest call still waiting, once the pending work has run.
  Future<void> answer(List<Event> newestFirst, {String? nextBatch}) async {
    await pumpEventQueue();
    _pending.removeAt(0).complete((events: newestFirst, nextBatch: nextBatch));
  }

  Future<void> fail() async {
    await pumpEventQueue();
    _pending.removeAt(0).completeError(Exception('offline'));
  }
}

/// THR-M-04: the thread screen shows the root, then its replies, loaded by
/// pages going up (`/relations`) and completed by the live room timeline.
/// Spec §5: the SDK has no thread timeline, so these are the events of the
/// screen.
///
/// Conventions these specs fix:
/// - the first page is fetched as soon as [ThreadEvents] is created;
/// - [ThreadEvents.ready] completes normally, also when that page fails;
/// - a page comes newest first (`dir=b`), and [ThreadEvents.events] is
///   newest first whatever the order of the pages and of the timeline.
void main() {
  const rootId = r'$root';

  late MockRoom room;
  late _Server server;
  late List<Event> relations;

  DateTime at(int minute) => DateTime.utc(2026, 11, 6, 10, minute);

  Map<String, Object?> threadRelation() => {
    'rel_type': RelationshipTypes.thread,
    'event_id': rootId,
    'is_falling_back': true,
  };

  Event root() => Event(
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': 'the root'},
    eventId: rootId,
    senderId: '@alice:example.com',
    originServerTs: at(0),
    room: room,
  );

  Event reply(String eventId, int minute, {String? body}) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': body ?? 'reply $eventId',
      'm.relates_to': threadRelation(),
    },
    eventId: eventId,
    senderId: '@bob:example.com',
    originServerTs: at(minute),
    room: room,
  );

  /// How a reply of an E2EE room comes from `/relations`: the relation stays
  /// in clear, the text is not readable before decryption.
  Event encryptedReply(String eventId, int minute) => Event(
    type: EventTypes.Encrypted,
    content: {
      'algorithm': 'm.megolm.v1.aes-sha2',
      'ciphertext': 'AwgAEnACgAkLmt6qF84IK++J7UDH2Za1YVchHyprqTqsg',
      'session_id': 'unknown-session',
      'm.relates_to': threadRelation(),
    },
    eventId: eventId,
    senderId: '@bob:example.com',
    originServerTs: at(minute),
    room: room,
  );

  Event mainMessage(String eventId, int minute) => Event(
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': 'in the room'},
    eventId: eventId,
    senderId: '@bob:example.com',
    originServerTs: at(minute),
    room: room,
  );

  Event redaction(String eventId, {required String redacts}) => Event(
    type: EventTypes.Redaction,
    content: const {},
    eventId: eventId,
    senderId: '@bob:example.com',
    originServerTs: at(50),
    redacts: redacts,
    room: room,
  );

  /// The copy the SDK keeps once [event] is redacted: `m.relates_to` and the
  /// text are gone (event.dart:255-289).
  Event redactedCopyOf(Event event) =>
      Event.fromJson(event.toJson(), room)
        ..setRedactionEvent(redaction(r'$redaction', redacts: event.eventId));

  Event edit(String eventId, {required String of, required int minute}) =>
      Event(
        type: EventTypes.Message,
        content: {
          'msgtype': 'm.text',
          'body': '* fixed',
          'm.new_content': {'msgtype': 'm.text', 'body': 'fixed'},
          'm.relates_to': {'rel_type': RelationshipTypes.edit, 'event_id': of},
        },
        eventId: eventId,
        senderId: '@bob:example.com',
        originServerTs: at(minute),
        room: room,
      );

  Event reaction(String eventId, {required String to, required int minute}) =>
      Event(
        type: EventTypes.Reaction,
        content: {
          'm.relates_to': {
            'rel_type': RelationshipTypes.reaction,
            'event_id': to,
            'key': '👍',
          },
        },
        eventId: eventId,
        senderId: '@carol:example.com',
        originServerTs: at(minute),
        room: room,
      );

  ThreadEvents create() => ThreadEvents(
    rootEventId: rootId,
    fetchPage: server.fetchPage,
    onRelation: relations.add,
  );

  /// A thread screen whose first page arrived.
  Future<ThreadEvents> opened(
    List<Event> firstPage, {
    String? nextBatch,
  }) async {
    final thread = create();
    await server.answer(firstPage, nextBatch: nextBatch);
    await thread.ready;
    thread.updateLive(const [], root: root());
    return thread;
  }

  List<String> idsOf(ThreadEvents thread) =>
      thread.events.map((e) => e.eventId).toList();

  Event only(ThreadEvents thread, String eventId) =>
      thread.events.singleWhere((e) => e.eventId == eventId);

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn('!room:example.com');
    server = _Server();
    relations = [];
  });

  group('content of the thread', () {
    test('replies newest first, then the root last', () async {
      final thread = await opened([reply(r'$r3', 3), reply(r'$r2', 2)]);

      thread.updateLive([
        mainMessage(r'$main', 30),
        reply(r'$r4', 20),
      ], root: root());

      expect(idsOf(thread), [r'$r4', r'$r3', r'$r2', rootId]);
    });

    test('a reply both in a page and in the live timeline is listed '
        'once', () async {
      final thread = await opened([reply(r'$r2', 2), reply(r'$r1', 1)]);

      thread.updateLive([reply(r'$r2', 2)], root: root());

      expect(idsOf(thread), [r'$r2', r'$r1', rootId]);
    });

    test('a message of the room is not listed', () async {
      final thread = await opened(const []);

      thread.updateLive([mainMessage(r'$main', 30)], root: root());

      expect(idsOf(thread), [rootId]);
    });
  });

  group('first page', () {
    test('is fetched from the newest reply when the screen opens', () async {
      create();
      await pumpEventQueue();

      expect(server.calls, [null]);
    });

    test('ready waits for the first page', () async {
      final thread = create();
      var ready = false;
      unawaited(thread.ready.then((_) => ready = true));
      await pumpEventQueue();
      expect(ready, isFalse);
      expect(thread.isLoading, isTrue);

      await server.answer([reply(r'$r1', 1)]);
      await thread.ready;

      expect(thread.isLoading, isFalse);
      expect(idsOf(thread), contains(r'$r1'));
    });

    test('ready completes when the first page fails, and the user can try '
        'again', () async {
      final thread = create();
      final ready = expectLater(
        thread.ready.timeout(const Duration(seconds: 1)),
        completes,
      );

      await server.fail();

      await ready;
      expect(thread.isLoading, isFalse);
      expect(thread.canLoadMore, isTrue);

      unawaited(thread.loadMore());
      await pumpEventQueue();
      expect(server.calls, [null, null]);
    });

    test('a thread whose replies all fit in one page has nothing more to '
        'load', () async {
      final thread = await opened([reply(r'$r1', 1)]);

      expect(thread.canLoadMore, isFalse);
    });
  });

  group('older pages', () {
    test('two loads at once fetch the page once', () async {
      final thread = await opened([reply(r'$r9', 9)], nextBatch: 'b1');

      final first = thread.loadMore();
      final second = thread.loadMore();
      await pumpEventQueue();
      expect(server.calls, [null, 'b1']);

      await server.answer([reply(r'$r8', 8)], nextBatch: 'b2');
      await Future.wait([first, second]);

      expect(server.calls, [null, 'b1']);
      expect(idsOf(thread), [r'$r9', r'$r8', rootId]);
      expect(thread.canLoadMore, isTrue);
    });

    test('a load asked while the first page is on its way waits for it, '
        'without a second fetch', () async {
      final thread = create();

      final load = thread.loadMore();
      await server.answer([reply(r'$r1', 1)]);
      await load;

      expect(server.calls, [null]);
    });

    test('a failed page is reported to the caller, keeps the thread '
        'loadable, and is not fetched again on its own', () async {
      final thread = await opened([reply(r'$r9', 9)], nextBatch: 'b1');

      final load = expectLater(thread.loadMore(), throwsException);
      await server.fail();

      await load;
      expect(thread.canLoadMore, isTrue);
      expect(thread.isLoading, isFalse);
      await pumpEventQueue();
      expect(server.calls, [null, 'b1']);
    });

    test('after a failed page, the next load fetches the same page '
        'again', () async {
      final thread = await opened([reply(r'$r9', 9)], nextBatch: 'b1');
      final failed = expectLater(thread.loadMore(), throwsException);
      await server.fail();
      await failed;

      final retry = thread.loadMore();
      await pumpEventQueue();
      expect(server.calls, [null, 'b1', 'b1']);
      await server.answer([reply(r'$r8', 8)]);
      await retry;

      expect(idsOf(thread), [r'$r9', r'$r8', rootId]);
    });

    test('both callers of a shared load are told it failed', () async {
      final thread = await opened([reply(r'$r9', 9)], nextBatch: 'b1');

      final first = expectLater(thread.loadMore(), throwsException);
      final second = expectLater(thread.loadMore(), throwsException);
      await server.fail();

      await first;
      await second;
    });

    test('the last page leaves nothing to load', () async {
      final thread = await opened([reply(r'$r9', 9)], nextBatch: 'b1');

      final load = thread.loadMore();
      await server.answer([reply(r'$r8', 8)]);
      await load;

      expect(thread.canLoadMore, isFalse);
    });
  });

  /// The SDK strips `m.relates_to` from a redacted event: a filter on the
  /// thread relation no longer finds it.
  group('deleted replies', () {
    test('a reply in a page deleted live is listed once, deleted, without '
        'its old text', () async {
      final r2 = reply(r'$r2', 2, body: 'secret');
      final thread = await opened([r2, reply(r'$r1', 1)]);

      thread.updateLive([redactedCopyOf(r2)], root: root());

      expect(idsOf(thread), [r'$r2', r'$r1', rootId]);
      expect(only(thread, r'$r2').redacted, isTrue);
      expect(only(thread, r'$r2').text, isNot(contains('secret')));
    });

    test('a reply seen live, then deleted live, stays listed '
        'deleted', () async {
      final thread = await opened(const []);
      final r5 = reply(r'$r5', 5, body: 'secret');
      thread.updateLive([r5], root: root());

      thread.updateLive([redactedCopyOf(r5)], root: root());

      expect(idsOf(thread), [r'$r5', rootId]);
      expect(only(thread, r'$r5').redacted, isTrue);
    });

    test('an old reply only known from a page shows deleted when its '
        'deletion arrives live', () async {
      final thread = await opened([reply(r'$r1', 1, body: 'secret')]);

      thread.applyRedaction(redaction(r'$redaction', redacts: r'$r1'));

      expect(idsOf(thread), [r'$r1', rootId]);
      expect(only(thread, r'$r1').redacted, isTrue);
      expect(only(thread, r'$r1').text, isNot(contains('secret')));
    });

    test('the deletion of an event outside the thread adds nothing', () async {
      final thread = await opened([reply(r'$r1', 1)]);

      thread.applyRedaction(redaction(r'$redaction', redacts: r'$main'));

      expect(idsOf(thread), [r'$r1', rootId]);
      expect(only(thread, r'$r1').redacted, isFalse);
    });
  });

  /// `/relations` with `recurse: true` also returns the edits and reactions
  /// of the replies: the screen hands them to the room timeline so an old
  /// reply shows its edit and its reactions.
  group('edits and reactions of old replies', () {
    test('are not listed as replies', () async {
      final thread = await opened([
        reaction(r'$like', to: r'$r1', minute: 3),
        edit(r'$fix', of: r'$r1', minute: 2),
        reply(r'$r1', 1),
      ]);

      expect(idsOf(thread), [r'$r1', rootId]);
    });

    test('are handed over, each one once', () async {
      await opened([
        reaction(r'$like', to: r'$r1', minute: 3),
        edit(r'$fix', of: r'$r1', minute: 2),
        reply(r'$r1', 1),
      ]);

      expect(
        relations.map((e) => e.eventId),
        unorderedEquals([r'$like', r'$fix']),
      );
    });

    test('of a reply on an older page are handed over too', () async {
      // The edit is newer than every reply of the first page.
      await opened([edit(r'$fix', of: r'$r0', minute: 9)], nextBatch: 'b1');

      expect(relations.map((e) => e.eventId), [r'$fix']);
    });
  });

  group('encrypted room', () {
    test(
      'a reply from a page that cannot be decrypted yet is listed',
      () async {
        final thread = await opened([encryptedReply(r'$r1', 1)]);

        expect(idsOf(thread), [r'$r1', rootId]);
      },
    );

    test('a reply decrypted later replaces its undecryptable copy', () async {
      final thread = await opened([encryptedReply(r'$r1', 1)]);

      thread.replaceEvent(reply(r'$r1', 1, body: 'now readable'));

      expect(only(thread, r'$r1').type, EventTypes.Message);
      expect(only(thread, r'$r1').text, 'now readable');
    });

    test('the decrypted live copy wins over the page copy', () async {
      final thread = await opened([encryptedReply(r'$r1', 1)]);

      thread.updateLive([reply(r'$r1', 1, body: 'readable')], root: root());

      expect(only(thread, r'$r1').type, EventTypes.Message);
    });

    test('a decrypted event that is not a reply does not enter the '
        'thread', () async {
      final thread = await opened([reply(r'$r1', 1)]);

      thread.replaceEvent(mainMessage(r'$main', 30));

      expect(idsOf(thread), [r'$r1', rootId]);
    });
  });

  /// The list is read on every frame: it is built again only when it
  /// changes.
  group('the same list until something changes', () {
    test('two reads give the same list', () async {
      final thread = await opened([reply(r'$r1', 1)]);

      expect(identical(thread.events, thread.events), isTrue);
    });

    test('the same live timeline again gives the same list', () async {
      final thread = await opened([reply(r'$r1', 1)]);
      final live = [reply(r'$r2', 2), mainMessage(r'$main', 30)];
      final theRoot = root();
      thread.updateLive(live, root: theRoot);
      final before = thread.events;

      thread.updateLive(live, root: theRoot);

      expect(identical(thread.events, before), isTrue);
    });

    test('a new live reply gives a new list that holds it', () async {
      final thread = await opened([reply(r'$r1', 1)]);
      final before = thread.events;

      thread.updateLive([reply(r'$r2', 2)], root: root());

      expect(identical(thread.events, before), isFalse);
      expect(idsOf(thread), [r'$r2', r'$r1', rootId]);
    });
  });
}
