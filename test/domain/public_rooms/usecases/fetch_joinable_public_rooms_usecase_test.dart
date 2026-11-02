import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/public_rooms/usecases/fetch_joinable_public_rooms_usecase.dart';

import '../fake_public_rooms_repository.dart';

void main() {
  test('execute_always_asksForTheWholeDirectoryUpToTheLimit', () async {
    // Arrange
    final repository = FakePublicRoomsRepository();

    // Act
    await FetchJoinablePublicRoomsUseCase(repository).execute();

    // Assert
    expect(repository.requestedLimit, 1000);
  });

  test('execute_always_keepsOnlyGroupsAndFeedsNotJoined', () async {
    // Arrange
    final repository = FakePublicRoomsRepository(
      directory: [
        publicRoom('!group'),
        publicRoom('!feed', kind: PublicRoomKind.feed),
        publicRoom('!space', kind: PublicRoomKind.space),
        publicRoom('!other', kind: PublicRoomKind.other),
        publicRoom('!joined'),
      ],
      joined: {'!joined'},
    );

    // Act
    final rooms = await FetchJoinablePublicRoomsUseCase(repository).execute();

    // Assert
    expect(rooms.map((room) => room.roomId), ['!group', '!feed']);
  });

  test('execute_whenTheDirectoryFails_throwsItsTypedException', () async {
    // Arrange
    final repository = FakePublicRoomsRepository(
      fetchError: PublicRoomsFetchFailedException(cause: Exception('down')),
    );

    // Act
    final result = FetchJoinablePublicRoomsUseCase(repository).execute();

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomsFetchFailedException>()));
  });
}
