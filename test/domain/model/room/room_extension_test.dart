import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'room_extension_test.mocks.dart';

class MockUser extends Mock implements User {
  final int _powerLevel;
  final String _id;

  MockUser(this._powerLevel, {String id = ''}) : _id = id;

  @override
  int get powerLevel => _powerLevel;

  @override
  String get id => _id;
}

@GenerateNiceMocks([MockSpec<Room>()])
void main() {
  group('SortByPowerLevel', () {
    test('sortByPowerLevel sorts users by power level in descending order', () {
      // Arrange
      final user1 = MockUser(50);
      final user2 = MockUser(100);
      final user3 = MockUser(0);
      final users = [user1, user2, user3];

      // Act
      final sortedUsers = users.sortByPowerLevel();

      // Assert
      expect(sortedUsers.map((u) => u.powerLevel), [100, 50, 0]);
    });

    test('sortByPowerLevel with empty list', () {
      // Arrange
      final users = <User>[];

      // Act
      final sortedUsers = users.sortByPowerLevel();

      // Assert
      expect(sortedUsers, isEmpty);
    });

    test('sortByPowerLevel with already sorted list', () {
      // Arrange
      final user1 = MockUser(100);
      final user2 = MockUser(50);
      final user3 = MockUser(0);
      final users = [user1, user2, user3];

      // Act
      final sortedUsers = users.sortByPowerLevel();

      // Assert
      expect(sortedUsers.map((u) => u.powerLevel), [100, 50, 0]);
    });

    test('sortByPowerLevel with users with same power level', () {
      // Arrange
      final user1 = MockUser(100);
      final user2 = MockUser(50);
      final user3 = MockUser(100);
      final users = [user1, user2, user3];

      // Act
      final sortedUsers = users.sortByPowerLevel();

      // Assert
      expect(sortedUsers.map((u) => u.powerLevel), [100, 100, 50]);
    });
  });

  group('NullableRoomExtension', () {
    test('canSelectToInvite with null room', () {
      // Arrange
      const Room? room = null;
      const contactId = '@user:example.com';

      // Act
      final result = room.canSelectToInvite(contactId);

      // Assert
      expect(result, true);
    });

    test('canSelectToInvite with room where user is not banned', () {
      // Arrange
      final room = MockRoom();
      const contactId = '@user:example.com';

      when(room.canBan).thenReturn(false);
      when(room.getBannedMembers()).thenReturn([]);

      // Act
      final result = room.canSelectToInvite(contactId);

      // Assert
      expect(result, true);
    });

    test('canSelectToInvite with room where user is banned', () {
      // Arrange
      final room = MockRoom();
      const contactId = '@user:example.com';
      final bannedUser = MockUser(100, id: contactId);

      when(room.canBan).thenReturn(false);
      when(room.getBannedMembers()).thenReturn([bannedUser]);

      // Act
      final result = room.canSelectToInvite(contactId);

      // Assert
      expect(result, false);
    });

    test('canSelectToInvite with room where user is admin', () {
      // Arrange
      final room = MockRoom();
      const contactId = '@user:example.com';

      when(room.canBan).thenReturn(true);

      // Act
      final result = room.canSelectToInvite(contactId);

      // Assert
      expect(result, true);
    });
  });
}
