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

  Future<PublicRoomsState> stateAfterLaterPages(
    void Function(StreamController<List<PublicRoom>> pages) sendLaterPages,
  ) async {
    final pages = StreamController<List<PublicRoom>>();
    final (container, _) = await loadFirstPage(pages);
    sendLaterPages(pages);
    await pages.close();
    await pumpEventQueue();
    return container.read(publicRoomsControllerProvider).requireValue;
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
    // Act
    final state = await stateAfterLaterPages(
      (pages) => pages.addError(
        PublicRoomsFetchFailedException(cause: Exception('down')),
      ),
    );

    // Assert
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

  test('build_whenALaterPageRepeatsARoom_listsItOnce', () async {
    // Act
    final state = await stateAfterLaterPages(
      (pages) => pages.add([publicRoom('!first'), publicRoom('!second')]),
    );

    // Assert
    expect(state.rooms.map((room) => room.roomId), ['!first', '!second']);
  });

  test('build_whenALaterPageThrowsAnUntypedError_stopsLoading', () async {
    // Arrange
    final errors = <Object>[];
    late ProviderContainer container;
    final pages = StreamController<List<PublicRoom>>();

    // Act
    await runZonedGuarded(() async {
      (container, _) = await loadFirstPage(pages);
      pages.addError(StateError('malformed page'));
      await pumpEventQueue();
    }, (error, _) => errors.add(error));

    // Assert
    expect(errors.single, isA<StateError>());
    expect(
      container.read(publicRoomsControllerProvider).requireValue.isLoadingMore,
      isFalse,
    );
  });

  test('open_whenTheJoinedRoomIsNotInSyncYet_saysSo', () async {
    // Arrange
    repository.isJoinInSync = false;
    final container = makeContainer();
    final controller = await loadedController(container);

    // Act
    final result = await controller.open(publicRoom('!open'));

    // Assert
    expect(result, isA<PublicRoomJoinedNotInSync>());
  });

  List<PublicRoom> approvalRooms(String prefix, int count) => [
    for (var i = 0; i < count; i++)
      publicRoom('!$prefix$i', access: PublicRoomAccess.approval),
  ];

  test('build_always_looksUpRequestsFiveAtATimeAcrossPages', () async {
    // Arrange
    repository.pages = [approvalRooms('a', 7), approvalRooms('b', 7)];
    final container = makeContainer();

    // Act
    await loadedController(container);
    await pumpEventQueue();

    // Assert
    expect(repository.knockedQueries.map((query) => query.length), [
      5,
      2,
      5,
      2,
    ]);
    expect(repository.maxLookupsInFlight, 1);
  });

  test('build_whenDisposedDuringLookups_stopsAskingTheServer', () async {
    // Arrange
    final gate = Completer<void>();
    repository
      ..pages = [approvalRooms('a', 12)]
      ..knocked = {'!a0'}
      ..lookupGate = gate;
    final container = makeContainer();
    await loadedController(container);
    await pumpEventQueue();

    // Act
    container.dispose();
    gate.complete();
    await pumpEventQueue();

    // Assert
    expect(repository.knockedQueries, hasLength(1));
  });

  test('open_whenDisposedDuringTheJoin_stillReturnsTheResult', () async {
    // Arrange
    final gate = Completer<void>();
    repository.joinGate = gate;
    final container = makeContainer();
    final controller = await loadedController(container);
    final result = controller.open(publicRoom('!open'));

    // Act
    container.dispose();
    gate.complete();

    // Assert
    expect(await result, isA<PublicRoomJoined>());
  });

  test('open_whenDisposedDuringTheRequest_stillReturnsTheResult', () async {
    // Arrange
    final gate = Completer<void>();
    repository.knockGate = gate;
    final container = makeContainer();
    final controller = await loadedController(container);
    final result = controller.open(
      publicRoom('!knock', access: PublicRoomAccess.approval),
    );

    // Act
    container.dispose();
    gate.complete();

    // Assert
    expect(await result, isA<PublicRoomRequested>());
  });

  test('build_whenDisposedWhileALaterPageLoads_stopsQuietly', () async {
    // Arrange
    final pages = StreamController<List<PublicRoom>>();
    final (container, _) = await loadFirstPage(pages);

    // Act
    container.dispose();
    pages.add([publicRoom('!second')]);
    await pages.close();
    await pumpEventQueue();

    // Assert
    expect(pages.hasListener, isFalse);
  });

  test('build_whenTheFirstPageRepeatsARoom_listsItOnce', () async {
    // Arrange
    repository.pages = [
      [publicRoom('!a'), publicRoom('!a'), publicRoom('!b')],
    ];
    final container = makeContainer();

    // Act
    final state = await container.read(publicRoomsControllerProvider.future);

    // Assert
    expect(state.rooms.map((room) => room.roomId), ['!a', '!b']);
  });

  test('build_whenALaterPageRepeatsARoom_looksItUpOnce', () async {
    // Arrange
    repository.pages = [
      [publicRoom('!a', access: PublicRoomAccess.approval)],
      [
        publicRoom('!a', access: PublicRoomAccess.approval),
        publicRoom('!b', access: PublicRoomAccess.approval),
      ],
    ];
    final container = makeContainer();

    // Act
    await loadedController(container);
    await pumpEventQueue();

    // Assert
    expect(repository.knockedQueries, [
      ['!a'],
      ['!b'],
    ]);
  });

  test('open_whenTheJoinThrowsAnUntypedError_clearsThePendingRoom', () async {
    // Arrange
    repository.joinUntypedError = StateError('unexpected');
    final container = makeContainer();
    final controller = await loadedController(container);

    // Act
    final result = controller.open(publicRoom('!open'));

    // Assert
    await expectLater(result, throwsA(isA<StateError>()));
    expect(
      container.read(publicRoomsControllerProvider).requireValue.pendingRoomId,
      isNull,
    );
  });
}
