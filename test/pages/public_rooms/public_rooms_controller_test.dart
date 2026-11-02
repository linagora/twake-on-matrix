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

  Future<(ProviderContainer, PublicRoomsState)> loadFirstPage(
    StreamController<List<PublicRoom>> pages,
  ) async {
    repository.directoryController = pages;
    final container = makeContainer();
    container.listen(publicRoomsControllerProvider, (_, _) {});
    pages.add([publicRoom('!first')]);
    final first = await container.read(publicRoomsControllerProvider.future);
    return (container, first);
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

  test('build_whenMorePagesCome_appendsThemAndStopsLoading', () async {
    // Arrange
    final pages = StreamController<List<PublicRoom>>();
    final (container, first) = await loadFirstPage(pages);

    // Act
    pages.add([publicRoom('!second')]);
    await pages.close();
    await pumpEventQueue();

    // Assert
    expect(first.rooms.map((room) => room.roomId), ['!first']);
    expect(first.isLoadingMore, isTrue);
    final state = container.read(publicRoomsControllerProvider).requireValue;
    expect(state.rooms.map((room) => room.roomId), ['!first', '!second']);
    expect(state.isLoadingMore, isFalse);
  });

  test('build_whenALaterPageFails_keepsTheRoomsShown', () async {
    // Arrange
    final pages = StreamController<List<PublicRoom>>();
    final (container, _) = await loadFirstPage(pages);

    // Act
    pages.addError(PublicRoomsFetchFailedException(cause: Exception('down')));
    await pages.close();
    await pumpEventQueue();

    // Assert
    final state = container.read(publicRoomsControllerProvider).requireValue;
    expect(state.rooms.map((room) => room.roomId), ['!first']);
    expect(state.isLoadingMore, isFalse);
  });

  test('build_always_asksTheRequestStateOfRoomsOnApprovalOnly', () async {
    // Arrange
    repository.knocked = {'!knock'};
    final container = makeContainer();

    // Act
    await loadedController(container);
    await pumpEventQueue();

    // Assert
    expect(repository.knockedQueries, [
      ['!knock'],
    ]);
    expect(
      container
          .read(publicRoomsControllerProvider)
          .requireValue
          .requestedRoomIds,
      {'!knock'},
    );
  });

  test('build_whenTheRequestStateFails_leavesTheRoomsAskable', () async {
    // Arrange
    repository.knockedError = const PublicRoomsNoClientException();
    final container = makeContainer();

    // Act
    await loadedController(container);
    await pumpEventQueue();

    // Assert
    final state = container.read(publicRoomsControllerProvider).requireValue;
    expect(state.requestedRoomIds, isEmpty);
    expect(state.rooms.map((room) => room.roomId), ['!open', '!knock']);
  });

  test('open_whenTheRequestIsSent_marksTheRoomRequested', () async {
    // Arrange
    final container = makeContainer();
    final controller = await loadedController(container);

    // Act
    await controller.open(
      publicRoom('!knock', access: PublicRoomAccess.approval),
    );

    // Assert
    final state = container.read(publicRoomsControllerProvider).requireValue;
    expect(state.requestedRoomIds, {'!knock'});
    expect(state.pendingRoomId, isNull);
  });

  test('open_whenTheRequestIsAlreadyPending_ignoresTheTap', () async {
    // Arrange
    repository.knocked = {'!knock'};
    final container = makeContainer();
    final controller = await loadedController(container);
    await pumpEventQueue();

    // Act
    final result = await controller.open(
      publicRoom('!knock', access: PublicRoomAccess.approval),
    );

    // Assert
    expect(result, isA<PublicRoomOpenIgnored>());
    expect(repository.knockedIds, isEmpty);
  });
}
