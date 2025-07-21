import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';

class MockUser extends Mock implements User {
  final int _powerLevel;

  MockUser(this._powerLevel);

  @override
  int get powerLevel => _powerLevel;
}

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
}
