import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/public_rooms/usecases/get_knocked_public_room_ids_usecase.dart';

import '../fake_public_rooms_repository.dart';

void main() {
  test('execute_always_returnsTheRoomsWithAPendingRequest', () async {
    // Arrange
    final repository = FakePublicRoomsRepository(knocked: {'!b'});

    // Act
    final ids = await GetKnockedPublicRoomIdsUseCase(
      repository,
    ).execute(['!a', '!b']);

    // Assert
    expect(ids, {'!b'});
    expect(repository.knockedQueries, [
      ['!a', '!b'],
    ]);
  });
}
