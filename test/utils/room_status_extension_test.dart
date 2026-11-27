import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/room_status_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../fake_client.dart';
import 'room_status_extension_test.mocks.dart';

typedef _Scenario = ({
  String name,
  Map<String, String> receipts,
  Map<String, String> mainThreadReceipts,
  String? ownReceipt,
  List<String> seenBy,
});

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Timeline>()])
void main() {
  const ownUserId = '@me:example.com';
  const userA = '@a:example.com';
  const userB = '@b:example.com';
  const newest = r'$newest';
  const newer = r'$newer';
  const target = r'$target';
  const older = r'$older';
  const eventIds = [newest, newer, target, older];

  late MockClient client;

  Room buildRoom({
    Map<String, String> receipts = const {},
    Map<String, String> mainThreadReceipts = const {},
    String? ownReceipt,
  }) {
    LatestReceiptStateForTimeline forTimeline(Map<String, String> others) =>
        LatestReceiptStateForTimeline(
          ownPrivate: null,
          ownPublic: null,
          latestOwnReceipt: ownReceipt == null
              ? null
              : LatestReceiptStateData(ownReceipt, 0),
          otherUsers: others.map(
            (userId, eventId) =>
                MapEntry(userId, LatestReceiptStateData(eventId, 0)),
          ),
        );
    final room = Room(id: '!room:example.com', client: client);
    room.receiptState = LatestReceiptState(
      global: forTimeline(receipts),
      mainThread: mainThreadReceipts.isEmpty
          ? null
          : forTimeline(mainThreadReceipts),
      byThread: {},
    );
    room.states[EventTypes.RoomMember] = {
      for (final userId in [ownUserId, userA, userB])
        userId: Event(
          eventId: '\$member_$userId',
          senderId: userId,
          stateKey: userId,
          type: EventTypes.RoomMember,
          content: {'membership': 'join'},
          originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
          room: room,
        ),
    };
    return room;
  }

  Event buildEvent(Room room, String eventId) => Event(
    eventId: eventId,
    senderId: ownUserId,
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': 'hello'},
    originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
    room: room,
  );

  MockTimeline buildTimeline(Room room, List<String> eventIds) {
    final timeline = MockTimeline();
    when(
      timeline.events,
    ).thenReturn([for (final eventId in eventIds) buildEvent(room, eventId)]);
    return timeline;
  }

  List<String> ids(List<User> users) => users.map((user) => user.id).toList();

  setUp(() {
    client = MockClient();
    when(client.userID).thenReturn(ownUserId);
    when(client.database).thenReturn(EventIdListDatabase(eventIds));
  });

  // The timeline and the chat list must always agree (#3354).
  group('seen by users, in the timeline and from the store', () {
    const scenarios = <_Scenario>[
      (
        name: 'receipt on the event',
        receipts: {userA: target},
        mainThreadReceipts: {},
        ownReceipt: null,
        seenBy: [userA],
      ),
      (
        name: 'receipt on a newer event, such as a reaction',
        receipts: {userA: newest},
        mainThreadReceipts: {},
        ownReceipt: null,
        seenBy: [userA],
      ),
      (
        name: 'receipts from the newest event down to the event',
        receipts: {userA: newer, userB: target},
        mainThreadReceipts: {},
        ownReceipt: null,
        seenBy: [userA, userB],
      ),
      (
        name: 'receipt on an older event',
        receipts: {userA: newest, userB: older},
        mainThreadReceipts: {},
        ownReceipt: null,
        seenBy: [userA],
      ),
      (
        name: 'receipt on an unknown event',
        receipts: {userA: r'$unknown'},
        mainThreadReceipts: {},
        ownReceipt: null,
        seenBy: [],
      ),
      (
        name: 'own receipt only',
        receipts: {},
        mainThreadReceipts: {},
        ownReceipt: newest,
        seenBy: [],
      ),
      (
        name: 'main thread receipt, without duplicating the user',
        receipts: {userA: newest},
        mainThreadReceipts: {userA: newer, userB: older},
        ownReceipt: null,
        seenBy: [userA],
      ),
    ];

    for (final scenario in scenarios) {
      test(scenario.name, () async {
        final room = buildRoom(
          receipts: scenario.receipts,
          mainThreadReceipts: scenario.mainThreadReceipts,
          ownReceipt: scenario.ownReceipt,
        );

        final inTimeline = room.getSeenByUsers(
          buildTimeline(room, eventIds),
          eventId: target,
        );
        final fromStore = await room.getSeenByUsersFromStore(
          buildEvent(room, target),
        );

        expect(ids(inTimeline), unorderedEquals(scenario.seenBy));
        expect(ids(fromStore), unorderedEquals(scenario.seenBy));
      });
    }

    test('exact receipt on an event missing from the known order', () async {
      when(client.database).thenReturn(EventIdListDatabase([newest, older]));
      final room = buildRoom(receipts: {userA: target, userB: newest});

      final inTimeline = room.getSeenByUsers(
        buildTimeline(room, [newest, older]),
        eventId: target,
      );
      final fromStore = await room.getSeenByUsersFromStore(
        buildEvent(room, target),
      );

      expect(ids(inTimeline), [userA]);
      expect(ids(fromStore), [userA]);
    });
  });

  group('getSeenByUsersFromStore', () {
    test('exact receipt when the store cannot be read', () async {
      when(client.database).thenReturn(MockDatabase());
      final room = buildRoom(receipts: {userA: target, userB: newest});

      final fromStore = await room.getSeenByUsersFromStore(
        buildEvent(room, target),
      );

      expect(ids(fromStore), [userA]);
    });
  });

  group('readers stopped at, by own event, once per timeline', () {
    const theirs = r'$theirs';
    const ownSticker = r'$ownSticker';
    const ownText = r'$ownText';
    const theirsOlder = r'$theirsOlder';
    const ownOldest = r'$ownOldest';

    Event typedEvent(
      Room room,
      String eventId, {
      String sender = ownUserId,
      String type = EventTypes.Message,
    }) => Event(
      eventId: eventId,
      senderId: sender,
      type: type,
      content: switch (type) {
        EventTypes.Sticker => {
          'body': 'a sticker',
          'url': 'mxc://example.com/sticker',
          'info': <String, Object?>{},
        },
        EventTypes.Reaction => {
          'm.relates_to': {
            'rel_type': 'm.annotation',
            'event_id': ownText,
            'key': '👍',
          },
        },
        _ => {'msgtype': 'm.text', 'body': 'hello'},
      },
      originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
      room: room,
    );

    /// Newest first: their message, my sticker, my text, their older
    /// message, my oldest text.
    MockTimeline conversation(Room room) {
      final timeline = MockTimeline();
      when(timeline.events).thenReturn([
        typedEvent(room, theirs, sender: userB),
        typedEvent(room, ownSticker, type: EventTypes.Sticker),
        typedEvent(room, ownText),
        typedEvent(room, theirsOlder, sender: userB),
        typedEvent(room, ownOldest),
      ]);
      return timeline;
    }

    /// The reader ids under each own event that has any.
    Map<String, List<String>> shape(Map<String, List<User>> byEvent) => {
      for (final MapEntry(:key, :value) in byEvent.entries)
        if (value.isNotEmpty) key: ids(value)..sort(),
    };

    test('an empty timeline: no reader anywhere', () {
      final room = buildRoom(receipts: {userA: target});

      expect(shape(room.readersStoppedAtByEvent(buildTimeline(room, []))), {});
    });

    test('no receipt: no reader anywhere', () {
      final room = buildRoom();

      expect(shape(room.readersStoppedAtByEvent(conversation(room))), {});
    });

    test('a reader whose receipt is on my message is under it', () {
      final room = buildRoom(receipts: {userA: ownText});

      expect(shape(room.readersStoppedAtByEvent(conversation(room))), {
        ownText: [userA],
      });
    });

    test('a reader whose receipt is on their message between two of mine is '
        'under my older one', () {
      final room = buildRoom(receipts: {userA: theirsOlder});

      expect(shape(room.readersStoppedAtByEvent(conversation(room))), {
        ownOldest: [userA],
      });
    });

    test('a reader whose receipt is on their message after my last one is '
        'under my last one', () {
      final room = buildRoom(receipts: {userA: newest});
      final timeline = MockTimeline();
      when(timeline.events).thenReturn([
        typedEvent(room, newest, sender: userB),
        typedEvent(room, target),
        typedEvent(room, older),
      ]);

      expect(shape(room.readersStoppedAtByEvent(timeline)), {
        target: [userA],
      });
    });

    test('my sticker is my message: a reader past it is under the sticker '
        'only, not under my text before it too', () {
      final room = buildRoom(receipts: {userA: theirs});

      expect(shape(room.readersStoppedAtByEvent(conversation(room))), {
        ownSticker: [userA],
      });
    });

    test('my reaction is not a message: a reader past it is under my last '
        'message', () {
      const ownReaction = r'$ownReaction';
      final room = buildRoom(receipts: {userA: ownReaction});
      final timeline = MockTimeline();
      when(timeline.events).thenReturn([
        typedEvent(room, ownReaction, type: EventTypes.Reaction),
        typedEvent(room, ownText),
        typedEvent(room, ownOldest),
      ]);

      expect(shape(room.readersStoppedAtByEvent(timeline)), {
        ownText: [userA],
      });
    });

    // Review of #3842: my edit and my thread reply are events of the timeline
    // the chat does not draw as a row. A reader stopped at one of them shows
    // under my latest message the chat draws.
    group('my latest events hidden in the chat', () {
      const ownEdit = r'$ownEdit';
      const ownThreadReply = r'$ownThreadReply';
      final threadsWere = AppConfig.threadsEnabled;

      setUp(() => AppConfig.threadsEnabled = true);
      tearDown(() => AppConfig.threadsEnabled = threadsWere);

      Event ownRelated(
        Room room,
        String eventId, {
        required String relType,
        required String target,
      }) => Event(
        eventId: eventId,
        senderId: ownUserId,
        type: EventTypes.Message,
        content: {
          'msgtype': 'm.text',
          'body': '* hello again',
          if (relType == RelationshipTypes.edit)
            'm.new_content': {'msgtype': 'm.text', 'body': 'hello again'},
          'm.relates_to': {'rel_type': relType, 'event_id': target},
        },
        originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
        room: room,
      );

      test('a reader whose receipt is on my edit is under the message I '
          'edited, my latest one the chat draws', () {
        final room = buildRoom(receipts: {userA: ownEdit});
        final timeline = MockTimeline();
        when(timeline.events).thenReturn([
          ownRelated(
            room,
            ownEdit,
            relType: RelationshipTypes.edit,
            target: ownText,
          ),
          typedEvent(room, ownText),
          typedEvent(room, theirsOlder, sender: userB),
          typedEvent(room, ownOldest),
        ]);

        expect(shape(room.readersStoppedAtByEvent(timeline)), {
          ownText: [userA],
        });
      });

      test('a reader whose receipt is on my thread reply is under my latest '
          'message of the chat, not under the reply', () {
        final room = buildRoom(receipts: {userA: ownThreadReply});
        final timeline = MockTimeline();
        when(timeline.events).thenReturn([
          ownRelated(
            room,
            ownThreadReply,
            relType: RelationshipTypes.thread,
            target: ownOldest,
          ),
          typedEvent(room, ownText),
          typedEvent(room, theirsOlder, sender: userB),
          typedEvent(room, ownOldest),
        ]);

        expect(shape(room.readersStoppedAtByEvent(timeline)), {
          ownText: [userA],
        });
      });
    });

    test('each reader is under exactly one of my events', () {
      final room = buildRoom(
        receipts: {userA: theirs, userB: ownText},
        mainThreadReceipts: {userA: ownOldest},
      );

      final readers = [
        for (final users
            in room.readersStoppedAtByEvent(conversation(room)).values)
          ...ids(users),
      ];

      expect(readers, unorderedEquals([userA, userB]));
    });

    test('readers who stopped at the same message are under it together', () {
      final room = buildRoom(receipts: {userA: ownText, userB: ownText});

      expect(shape(room.readersStoppedAtByEvent(conversation(room))), {
        ownText: [userA, userB],
      });
    });

    test('with a main thread receipt too, a reader is under the newest of my '
        'messages they read', () {
      final room = buildRoom(
        receipts: {userA: ownOldest},
        mainThreadReceipts: {userA: ownText},
      );

      expect(shape(room.readersStoppedAtByEvent(conversation(room))), {
        ownText: [userA],
      });
    });

    test('a receipt on an event the timeline does not hold: no reader '
        'anywhere', () {
      final room = buildRoom(receipts: {userA: r'$unknown'});

      expect(shape(room.readersStoppedAtByEvent(conversation(room))), {});
    });

    test('their messages are never keys: only my events hold readers', () {
      final room = buildRoom(receipts: {userA: theirs, userB: theirsOlder});

      final keys = shape(room.readersStoppedAtByEvent(conversation(room))).keys;

      expect(keys, everyElement(isIn([ownSticker, ownText, ownOldest])));
    });
  });

  group('getSeenByUsers', () {
    test('returns empty list when timeline is empty', () {
      final room = buildRoom(receipts: {userA: target});

      expect(room.getSeenByUsers(buildTimeline(room, [])), isEmpty);
    });

    test('defaults to the latest event', () {
      final room = buildRoom(receipts: {userA: newest, userB: newer});

      expect(ids(room.getSeenByUsers(buildTimeline(room, eventIds))), [userA]);
    });
  });
}
