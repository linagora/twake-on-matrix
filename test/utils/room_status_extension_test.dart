import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'room_status_extension_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>(), MockSpec<Event>(), MockSpec<Client>()])
void main() {
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
