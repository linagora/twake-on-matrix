import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'room_status_extension_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Room>(),
  MockSpec<Event>(),
  MockSpec<Client>(),
  MockSpec<Timeline>(),
])
void main() {
  group('getSeenByUsers', () {
    late MockRoom mockRoom;
    late MockClient mockClient;
    late MockTimeline mockTimeline;

    const ownUserId = '@me:example.com';
    const otherUserId = '@other:example.com';

    MockEvent createEvent(String eventId, List<Receipt> receipts) {
      final event = MockEvent();
      when(event.eventId).thenReturn(eventId);
      when(event.receipts).thenReturn(receipts);
      return event;
    }

    setUp(() {
      mockRoom = MockRoom();
      mockClient = MockClient();
      mockTimeline = MockTimeline();

      when(mockRoom.client).thenReturn(mockClient);
      when(mockClient.userID).thenReturn(ownUserId);
    });

    test('returns empty list when timeline is empty', () {
      when(mockTimeline.events).thenReturn([]);

      expect(mockRoom.getSeenByUsers(mockTimeline), isEmpty);
    });

    test('returns empty list when only own user has receipts', () {
      final ownUser = MockUser(ownUserId);
      final event = createEvent('ev1', [Receipt(ownUser, DateTime.now())]);
      when(mockTimeline.events).thenReturn([event]);

      expect(mockRoom.getSeenByUsers(mockTimeline), isEmpty);
    });

    test('returns other user who has receipt on latest event', () {
      final otherUser = MockUser(otherUserId);
      final event = createEvent('ev1', [Receipt(otherUser, DateTime.now())]);
      when(mockTimeline.events).thenReturn([event]);

      final result = mockRoom.getSeenByUsers(mockTimeline);
      expect(result, hasLength(1));
      expect(result.first.id, otherUserId);
    });

    test('accumulates receipts from newer events down to target', () {
      final user1 = MockUser('@a:example.com');
      final user2 = MockUser('@b:example.com');

      final newest = createEvent('ev1', [Receipt(user1, DateTime.now())]);
      final target = createEvent('ev2', [Receipt(user2, DateTime.now())]);
      final older = createEvent('ev3', []);

      when(mockTimeline.events).thenReturn([newest, target, older]);

      final result = mockRoom.getSeenByUsers(mockTimeline, eventId: 'ev2');
      expect(
        result.map((u) => u.id),
        containsAll(['@a:example.com', '@b:example.com']),
      );
    });

    test('does not include receipts from events older than target', () {
      final user1 = MockUser('@a:example.com');
      final user2 = MockUser('@b:example.com');

      final newest = createEvent('ev1', [Receipt(user1, DateTime.now())]);
      final target = createEvent('ev2', []);
      final older = createEvent('ev3', [Receipt(user2, DateTime.now())]);

      when(mockTimeline.events).thenReturn([newest, target, older]);

      final result = mockRoom.getSeenByUsers(mockTimeline, eventId: 'ev2');
      expect(result.map((u) => u.id), contains('@a:example.com'));
      expect(result.map((u) => u.id), isNot(contains('@b:example.com')));
    });

    test(
      'uses timeline receipts progression when target has no direct receipt',
      () {
        final user1 = MockUser('@a:example.com');
        final user2 = MockUser('@b:example.com');
        final user3 = MockUser('@c:example.com');

        final newest = createEvent('ev1', [Receipt(user1, DateTime.now())]);
        final beforeTarget = createEvent('ev2', [
          Receipt(user2, DateTime.now()),
        ]);
        final target = createEvent('ev3', []);
        final older = createEvent('ev4', [Receipt(user3, DateTime.now())]);

        when(
          mockTimeline.events,
        ).thenReturn([newest, beforeTarget, target, older]);

        final result = mockRoom.getSeenByUsers(mockTimeline, eventId: 'ev3');
        expect(
          result.map((u) => u.id),
          containsAll(['@a:example.com', '@b:example.com']),
        );
        expect(result.map((u) => u.id), isNot(contains('@c:example.com')));
      },
    );

    test('returns empty list when target eventId is not found in timeline', () {
      final user1 = MockUser('@a:example.com');
      final user2 = MockUser('@b:example.com');

      final event1 = createEvent('ev1', [Receipt(user1, DateTime.now())]);
      final event2 = createEvent('ev2', [Receipt(user2, DateTime.now())]);
      when(mockTimeline.events).thenReturn([event1, event2]);

      expect(
        mockRoom.getSeenByUsers(mockTimeline, eventId: 'ev-unknown'),
        isEmpty,
      );
    });

    test('excludes own user from results even with mixed receipts', () {
      final ownUser = MockUser(ownUserId);
      final otherUser = MockUser(otherUserId);

      final event = createEvent('ev1', [
        Receipt(ownUser, DateTime.now()),
        Receipt(otherUser, DateTime.now()),
      ]);
      when(mockTimeline.events).thenReturn([event]);

      final result = mockRoom.getSeenByUsers(mockTimeline);
      expect(result, hasLength(1));
      expect(result.first.id, otherUserId);
    });
  });

  group('hasLastEventBeenSeenByOthers', () {
    late MockRoom mockRoom;
    late MockEvent mockEvent;
    late MockClient mockClient;

    const ownUserId = '@me:example.com';
    const otherUserId = '@other:example.com';

    setUp(() {
      mockRoom = MockRoom();
      mockEvent = MockEvent();
      mockClient = MockClient();

      when(mockRoom.client).thenReturn(mockClient);
      when(mockClient.userID).thenReturn(ownUserId);
    });

    test('returns false when lastEvent is null', () {
      when(mockRoom.lastEvent).thenReturn(null);

      expect(mockRoom.hasLastEventBeenSeenByOthers, false);
    });

    test('returns false when receipts is empty', () {
      when(mockRoom.lastEvent).thenReturn(mockEvent);
      when(mockEvent.receipts).thenReturn([]);

      expect(mockRoom.hasLastEventBeenSeenByOthers, false);
    });

    test('returns false when only receipt is from current user', () {
      final ownUser = MockUser(ownUserId);

      when(mockRoom.lastEvent).thenReturn(mockEvent);
      when(mockEvent.receipts).thenReturn([Receipt(ownUser, DateTime.now())]);

      expect(mockRoom.hasLastEventBeenSeenByOthers, false);
    });

    test('returns true when receipt is from another user', () {
      final otherUser = MockUser(otherUserId);

      when(mockRoom.lastEvent).thenReturn(mockEvent);
      when(mockEvent.receipts).thenReturn([Receipt(otherUser, DateTime.now())]);

      expect(mockRoom.hasLastEventBeenSeenByOthers, true);
    });

    test(
      'returns true when receipts contain both current user and other user',
      () {
        final ownUser = MockUser(ownUserId);
        final otherUser = MockUser(otherUserId);

        when(mockRoom.lastEvent).thenReturn(mockEvent);
        when(mockEvent.receipts).thenReturn([
          Receipt(ownUser, DateTime.now()),
          Receipt(otherUser, DateTime.now()),
        ]);

        expect(mockRoom.hasLastEventBeenSeenByOthers, true);
      },
    );

    test('returns true when multiple other users have seen the event', () {
      final otherUser1 = MockUser(otherUserId);
      final otherUser2 = MockUser('@another:example.com');

      when(mockRoom.lastEvent).thenReturn(mockEvent);
      when(mockEvent.receipts).thenReturn([
        Receipt(otherUser1, DateTime.now()),
        Receipt(otherUser2, DateTime.now()),
      ]);

      expect(mockRoom.hasLastEventBeenSeenByOthers, true);
    });
  });
}

class MockUser extends Mock implements User {
  final String _id;

  MockUser(this._id);

  @override
  String get id => _id;
}
