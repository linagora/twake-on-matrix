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
