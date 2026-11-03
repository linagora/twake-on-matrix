import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/public_rooms/usecases/join_public_room_usecase.dart';

import '../fake_public_rooms_repository.dart';

void main() {
  test('execute_whenGivenAnAlias_joinsAndReturnsTheRoomId', () async {
    // Arrange
    final repository = FakePublicRoomsRepository();

    // Act
    final joined = await JoinPublicRoomUseCase(repository).execute('#a:hs');

    // Assert
    expect(joined.roomId, '!a:hs');
    expect(repository.joinedIds, ['#a:hs']);
  });

  test('execute_whenTheJoinFails_throwsJoinFailed', () async {
    // Arrange
    final repository = FakePublicRoomsRepository(
      joinError: PublicRoomJoinFailedException(cause: Exception('forbidden')),
    );

    // Act
    final result = JoinPublicRoomUseCase(repository).execute('!a:hs');

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomJoinFailedException>()));
  });
}
