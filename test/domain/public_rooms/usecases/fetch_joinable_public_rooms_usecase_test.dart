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
    await FetchJoinablePublicRoomsUseCase(repository).execute().toList();

    // Assert
    expect(repository.requestedLimit, 1000);
    expect(repository.requestedSearchTerm, isNull);
  });

  test('execute_withASearchTerm_asksTheServerForTheFirstMatches', () async {
    // Arrange
    final repository = FakePublicRoomsRepository(
      directory: [publicRoom('!group'), publicRoom('!joined')],
      joined: {'!joined'},
    );

    // Act
    final rooms = await FetchJoinablePublicRoomsUseCase(
      repository,
    ).execute(searchTerm: 'gr').first;

    // Assert
    expect(repository.requestedLimit, 20);
    expect(repository.requestedSearchTerm, 'gr');
    expect(rooms.map((room) => room.roomId), ['!group']);
  });

  test('execute_withASearchTerm_trimsIt', () async {
    // Arrange
    final repository = FakePublicRoomsRepository();

    // Act
    await FetchJoinablePublicRoomsUseCase(
      repository,
    ).execute(searchTerm: ' gr ').toList();

    // Assert
    expect(repository.requestedSearchTerm, 'gr');
  });

  test('execute_withUnderTwoLetters_asksNothing', () async {
    // Arrange
    final repository = FakePublicRoomsRepository();

    // Act
    final pages = await FetchJoinablePublicRoomsUseCase(
      repository,
    ).execute(searchTerm: ' g ').toList();

    // Assert
    expect(pages, isEmpty);
    expect(repository.requestedLimit, isNull);
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
    final rooms = await FetchJoinablePublicRoomsUseCase(
      repository,
    ).execute().first;

    // Assert
    expect(rooms.map((room) => room.roomId), ['!group', '!feed']);
  });

  test('execute_always_emitsOnePageAtATime', () async {
    // Arrange
    final repository = FakePublicRoomsRepository(
      pages: [
        [publicRoom('!a'), publicRoom('!b')],
        [publicRoom('!c')],
      ],
    );

    // Act
    final pages = await FetchJoinablePublicRoomsUseCase(
      repository,
    ).execute().toList();

    // Assert
    expect(pages.map((page) => page.map((room) => room.roomId).toList()), [
      ['!a', '!b'],
      ['!c'],
    ]);
  });

  test('execute_whenTheDirectoryFails_throwsItsTypedException', () async {
    // Arrange
    final repository = FakePublicRoomsRepository(
      fetchError: PublicRoomsFetchFailedException(cause: Exception('down')),
    );

    // Act
    final result = FetchJoinablePublicRoomsUseCase(
      repository,
    ).execute().toList();

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomsFetchFailedException>()));
  });
}
