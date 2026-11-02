import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_controller.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';

import '../../domain/public_rooms/fake_public_rooms_repository.dart';

void main() {
  late FakePublicRoomsRepository repository;

  ProviderContainer makeContainer() => ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [publicRoomsRepositoryProvider.overrideWithValue(repository)],
  );

  Future<PublicRoomsController> loadedController(
    ProviderContainer container,
  ) async {
    container.listen(publicRoomsControllerProvider, (_, _) {});
    await container.read(publicRoomsControllerProvider.future);
    return container.read(publicRoomsControllerProvider.notifier);
  }

  setUp(() {
    repository = FakePublicRoomsRepository(
      directory: [
        publicRoom('!open'),
        publicRoom('!knock', access: PublicRoomAccess.approval),
        publicRoom('!joined'),
      ],
      joined: {'!joined'},
    );
  });

  test('build_always_listsTheJoinableRooms', () async {
    // Arrange
    final container = makeContainer();

    // Act
    final state = await container.read(publicRoomsControllerProvider.future);

    // Assert
    expect(state.rooms.map((room) => room.roomId), ['!open', '!knock']);
    expect(state.pendingRoomId, isNull);
  });

  test('build_whenTheDirectoryFails_isAnError', () async {
    // Arrange
    repository.fetchError = PublicRoomsFetchFailedException(
      cause: Exception('down'),
    );
    final container = makeContainer();

    // Act
    final result = container.read(publicRoomsControllerProvider.future);

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomsFetchFailedException>()));
  });

  test('open_whenOpen_joinsAndReturnsTheRoomId', () async {
    // Arrange
    final container = makeContainer();
    final controller = await loadedController(container);

    // Act
    final result = await controller.open(publicRoom('!open'));

    // Assert
    expect(result, isA<PublicRoomJoined>());
    expect((result as PublicRoomJoined).roomId, '!open');
    expect(repository.joinedIds, ['!open']);
    expect(repository.knockedIds, isEmpty);
  });

  test('open_whenOnApproval_sendsAKnockInstead', () async {
    // Arrange
    final container = makeContainer();
    final controller = await loadedController(container);

    // Act
    final result = await controller.open(
      publicRoom('!knock', access: PublicRoomAccess.approval),
    );

    // Assert
    expect(result, isA<PublicRoomRequested>());
    expect(repository.knockedIds, ['!knock']);
    expect(repository.joinedIds, isEmpty);
  });

  test('open_whenTheJoinFails_reportsItAndClearsThePendingRoom', () async {
    // Arrange
    repository.joinError = PublicRoomJoinFailedException(
      cause: Exception('forbidden'),
    );
    final container = makeContainer();
    final controller = await loadedController(container);

    // Act
    final result = await controller.open(publicRoom('!open'));

    // Assert
    expect(result, isA<PublicRoomOpenFailed>());
    expect(
      container.read(publicRoomsControllerProvider).value?.pendingRoomId,
      isNull,
    );
  });

  test('open_whileAnotherRoomIsPending_ignoresTheTap', () async {
    // Arrange
    final gate = Completer<void>();
    repository.joinGate = gate;
    addTearDown(gate.complete);
    final container = makeContainer();
    final controller = await loadedController(container);
    unawaited(controller.open(publicRoom('!open')));

    // Act
    final second = await controller.open(publicRoom('!other'));

    // Assert
    expect(second, isA<PublicRoomOpenIgnored>());
    expect(
      container.read(publicRoomsControllerProvider).value?.pendingRoomId,
      '!open',
    );
  });
}
