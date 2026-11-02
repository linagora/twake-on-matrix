import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/providers/room_list/folded_spaces_controller.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';

import 'room_list_providers_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SpaceRepository>(), MockSpec<Client>()])
void main() {
  const space = RoomListEntry(id: '!s', kind: RoomKind.space, childIds: ['!a']);
  late MockSpaceRepository repository;
  late StreamController<int> changes;

  setUp(() {
    repository = MockSpaceRepository();
    changes = StreamController<int>.broadcast();
    addTearDown(changes.close);
    when(repository.watchRoomChanges()).thenAnswer((_) => changes.stream);
    when(repository.getRoomListEntries()).thenReturn(const [space]);
    when(
      repository.getSpaceChildren('!s'),
    ).thenAnswer((_) async => const [SpaceChannel(roomId: '!a', name: 'A')]);
  });

  ProviderContainer newContainer({List overrides = const []}) =>
      ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          spaceRepositoryProvider.overrideWithValue(repository),
          savedFoldersProvider.overrideWith((ref) => const Stream.empty()),
          foldedSpacesControllerProvider.overrideWith(_NoFold.new),
          ...overrides.cast(),
        ],
      );

  group('RoomListFilterController', () {
    test('whenAccountChanges_startsOnAll', () {
      final first = MockClient();
      when(first.userID).thenReturn('@a:own.org');
      final second = MockClient();
      when(second.userID).thenReturn('@b:own.org');
      final container = newContainer();
      final active = container.read(activeMatrixClientProvider.notifier);
      active.setClient(first);
      container
          .read(roomListFilterControllerProvider.notifier)
          .select(const RoomListFilter.folder('Work'));

      active.setClient(second);

      expect(
        container.read(roomListFilterControllerProvider),
        const RoomListFilter.all(),
      );
    });
  });

  group('shownRoomListFilter', () {
    test('whenSelectedFolderIsGone_fallsBackOnAll', () {
      final container = newContainer(
        overrides: [
          roomListFoldersProvider.overrideWithValue(const [
            Folder.user('Other'),
          ]),
        ],
      );
      container
          .read(roomListFilterControllerProvider.notifier)
          .select(const RoomListFilter.folder('Work'));

      expect(
        container.read(shownRoomListFilterProvider),
        const RoomListFilter.all(),
      );
    });

    test('whenSelectedFolderExists_showsIt', () {
      final container = newContainer(
        overrides: [
          roomListFoldersProvider.overrideWithValue(const [
            Folder.user('Work'),
          ]),
        ],
      );
      container
          .read(roomListFilterControllerProvider.notifier)
          .select(const RoomListFilter.folder('Work'));

      expect(
        container.read(shownRoomListFilterProvider),
        const RoomListFilter.folder('Work'),
      );
    });
  });

  group('spaceChildren', () {
    test('whenOtherRoomsChange_doesNotReadAgain', () async {
      final container = newContainer();
      container.listen(spaceChildrenProvider('!s'), (_, _) {});
      await pumpEventQueue();

      changes.add(1);
      await pumpEventQueue();

      verify(repository.getSpaceChildren('!s')).called(1);
    });

    test('whenSpaceListsSomethingElse_readsAgain', () async {
      final container = newContainer();
      container.listen(spaceChildrenProvider('!s'), (_, _) {});
      await pumpEventQueue();

      when(repository.getRoomListEntries()).thenReturn([
        space.copyWith(childIds: ['!a', '!b']),
      ]);
      changes.add(1);
      await pumpEventQueue();

      verify(repository.getSpaceChildren('!s')).called(2);
    });

    test('whenReadingFailsAfterASuccess_keepsWhatWasRead', () async {
      final container = newContainer();
      container.listen(spaceChildrenProvider('!s'), (_, _) {});
      await pumpEventQueue();

      when(
        repository.getSpaceChildren('!s'),
      ).thenThrow(const SpaceChildrenUnavailableException());
      container.invalidate(spaceChildrenProvider('!s'));
      await pumpEventQueue();

      expect(container.read(spaceChildrenProvider('!s')).value, const [
        SpaceChannel(roomId: '!a', name: 'A'),
      ]);
    });
  });

  group('SpaceJoinController', () {
    test('join_always_joinsThroughItsViaAndReadsTheSpaceAgain', () async {
      final container = newContainer();
      container.listen(spaceChildrenProvider('!s'), (_, _) {});
      await pumpEventQueue();

      // Long enough for a provider nobody listens to to be disposed.
      when(repository.joinRoom(any, via: anyNamed('via'))).thenAnswer((
        _,
      ) async {
        await pumpEventQueue();
      });
      await container
          .read(spaceJoinControllerProvider.notifier)
          .join(
            '!s',
            const SpaceChannel(roomId: '!a', name: 'A', via: ['good.org']),
          );
      await pumpEventQueue();

      verify(repository.joinRoom('!a', via: ['good.org'])).called(1);
      verify(repository.getSpaceChildren('!s')).called(2);
    });
  });

  group('roomListContent', () {
    test('whenAll_offersJoinableSubSpaces', () async {
      when(repository.getSpaceChildren('!s')).thenAnswer(
        (_) async => const [
          SpaceChannel(
            roomId: '!sub',
            name: 'Sub',
            isSpace: true,
            isJoinable: true,
          ),
        ],
      );
      final container = newContainer();
      container.listen(roomListContentProvider(null), (_, _) {});
      await pumpEventQueue();

      final content = container.read(roomListContentProvider(null));

      expect(content.visible, const [space]);
      expect(content.joinableBySpace['!s']!.single.roomId, '!sub');
    });

    test('whenSpaceIsOnlyInvited_readsNoHierarchy', () async {
      when(
        repository.getRoomListEntries(),
      ).thenReturn([space.copyWith(isJoined: false)]);
      final container = newContainer();
      container.listen(roomListContentProvider(null), (_, _) {});
      await pumpEventQueue();

      verifyNever(repository.getSpaceChildren(any));
    });

    test('whenOtherView_offersNothingButKeepsWhatWasRead', () async {
      final container = newContainer();
      container.listen(roomListContentProvider(null), (_, _) {});
      await pumpEventQueue();
      final views = container.read(roomListFilterControllerProvider.notifier);

      views.select(const RoomListFilter.builtin(BuiltinFolder.unread));
      await pumpEventQueue();
      expect(
        container.read(roomListContentProvider(null)).joinableBySpace,
        isEmpty,
      );
      views.select(const RoomListFilter.all());
      await pumpEventQueue();

      verify(repository.getSpaceChildren('!s')).called(1);
    });
  });
}

class _NoFold extends FoldedSpacesController {
  @override
  Future<Set<String>> build() async => const {};
}
