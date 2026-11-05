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
import 'package:twake_chat/providers/legacy_active_client_provider.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';

import 'room_list_providers_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SpaceRepository>(), MockSpec<Client>()])
void main() {
  setUp(() {
    _repository = MockSpaceRepository();
    _changes = StreamController<int>.broadcast();
    addTearDown(_changes.close);
    when(_repository.watchRoomChanges()).thenAnswer((_) => _changes.stream);
    when(_repository.getRoomListEntries()).thenReturn(const [_space]);
    when(
      _repository.getSpaceChildren('!s'),
    ).thenAnswer((_) async => const [SpaceChannel(roomId: '!a', name: 'A')]);
  });

  _roomListFilterControllerTests();
  _shownRoomListFilterTests();
  _spaceChildrenTests();
  _spaceJoinControllerTests();
  _roomListContentTests();
}

const _space = RoomListEntry(id: '!s', kind: RoomKind.space, childIds: ['!a']);

/// Joined when `/hierarchy` was read: the room list decides what it is now.
const _subSpace = SpaceChannel(
  roomId: '!sub',
  name: 'Sub',
  isSpace: true,
  isJoinable: true,
  isJoined: true,
);
late MockSpaceRepository _repository;
late StreamController<int> _changes;

ProviderContainer _newContainer({List overrides = const []}) =>
    ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        spaceRepositoryProvider.overrideWithValue(_repository),
        savedFoldersProvider.overrideWith((ref) => const Stream.empty()),
        foldedSpacesControllerProvider.overrideWith(_NoFold.new),
        ...overrides.cast(),
      ],
    );

void _roomListFilterControllerTests() {
  group('RoomListFilterController', () {
    test('whenAccountChanges_startsOnAll', () {
      final first = MockClient();
      when(first.userID).thenReturn('@a:own.org');
      final second = MockClient();
      when(second.userID).thenReturn('@b:own.org');
      final container = _newContainer();
      final active = container.read(legacyActiveClientProvider.notifier);
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
}

RoomListFilter _shownFilterWith(List<Folder> folders) {
  final container = _newContainer(
    overrides: [roomListFoldersProvider.overrideWithValue(folders)],
  );
  container
      .read(roomListFilterControllerProvider.notifier)
      .select(const RoomListFilter.folder('Work'));
  return container.read(shownRoomListFilterProvider);
}

void _shownRoomListFilterTests() {
  group('shownRoomListFilter', () {
    test('whenSelectedFolderIsGone_fallsBackOnAll', () {
      final shown = _shownFilterWith(const [Folder.user('Other')]);

      expect(shown, const RoomListFilter.all());
    });

    test('whenSelectedFolderExists_showsIt', () {
      final shown = _shownFilterWith(const [Folder.user('Work')]);

      expect(shown, const RoomListFilter.folder('Work'));
    });
  });
}

void _spaceChildrenTests() {
  group('spaceChildren', () {
    test('whenOtherRoomsChange_doesNotReadAgain', () async {
      final container = _newContainer();
      container.listen(spaceChildrenProvider('!s'), (_, _) {});
      await pumpEventQueue();

      _changes.add(1);
      await pumpEventQueue();

      verify(_repository.getSpaceChildren('!s')).called(1);
    });

    test('whenSpaceListsSomethingElse_readsAgain', () async {
      final container = _newContainer();
      container.listen(spaceChildrenProvider('!s'), (_, _) {});
      await pumpEventQueue();

      when(_repository.getRoomListEntries()).thenReturn([
        _space.copyWith(childIds: ['!a', '!b']),
      ]);
      _changes.add(1);
      await pumpEventQueue();

      verify(_repository.getSpaceChildren('!s')).called(2);
    });

    test('whenReadingFailsAfterASuccess_keepsWhatWasRead', () async {
      final container = _newContainer();
      container.listen(spaceChildrenProvider('!s'), (_, _) {});
      await pumpEventQueue();

      when(
        _repository.getSpaceChildren('!s'),
      ).thenThrow(const SpaceChildrenUnavailableException());
      container.invalidate(spaceChildrenProvider('!s'));
      await pumpEventQueue();

      expect(container.read(spaceChildrenProvider('!s')).value, const [
        SpaceChannel(roomId: '!a', name: 'A'),
      ]);
    });
  });
}

void _spaceJoinControllerTests() {
  group('SpaceJoinController', () {
    test('join_whileTheSameJoinRuns_startsNoSecondOne', () async {
      final container = _newContainer();
      final pending = Completer<void>();
      when(
        _repository.joinRoom(any, via: anyNamed('via')),
      ).thenAnswer((_) => pending.future);
      final controller = container.read(spaceJoinControllerProvider.notifier);
      const child = SpaceChannel(roomId: '!a', name: 'A');

      final first = controller.join('!s', child);
      final second = await controller.join('!s', child);
      pending.complete();

      expect(second, isFalse);
      expect(await first, isTrue);
      verify(_repository.joinRoom('!a', via: const [])).called(1);
    });

    test('join_always_joinsThroughItsViaAndReadsTheSpaceAgain', () async {
      final container = _newContainer();
      container.listen(spaceChildrenProvider('!s'), (_, _) {});
      await pumpEventQueue();

      // Long enough for a provider nobody listens to to be disposed.
      when(_repository.joinRoom(any, via: anyNamed('via'))).thenAnswer((
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

      verify(_repository.joinRoom('!a', via: ['good.org'])).called(1);
      verify(_repository.getSpaceChildren('!s')).called(2);
    });
  });
}

void _roomListContentTests() {
  group('roomListContent', () {
    test('whenAll_offersJoinableSubSpaces', () async {
      when(_repository.getSpaceChildren('!s')).thenAnswer(
        (_) async => const [
          SpaceChannel(
            roomId: '!sub',
            name: 'Sub',
            isSpace: true,
            isJoinable: true,
          ),
        ],
      );
      final container = _newContainer();
      container.listen(roomListContentProvider(null), (_, _) {});
      await pumpEventQueue();

      final content = container.read(roomListContentProvider(null));

      expect(content.visible, const [_space]);
      expect(content.joinableBySpace['!s']!.single.roomId, '!sub');
    });

    test('whenASubSpaceIsLeftAfterTheRead_offersItAgain', () async {
      when(
        _repository.getSpaceChildren('!s'),
      ).thenAnswer((_) async => const [_subSpace]);
      final container = _newContainer();
      container.listen(roomListContentProvider(null), (_, _) {});
      await pumpEventQueue();

      final content = container.read(roomListContentProvider(null));

      expect(content.joinableBySpace['!s']!.single.roomId, '!sub');
    });

    test('whenASubSpaceIsJoinedAfterTheRead_stopsOfferingIt', () async {
      when(_repository.getRoomListEntries()).thenReturn(const [
        _space,
        RoomListEntry(id: '!sub', kind: RoomKind.space),
      ]);
      when(_repository.getSpaceChildren(any)).thenAnswer((invocation) async {
        return invocation.positionalArguments.first == '!s'
            ? const [_subSpace]
            : const [];
      });
      final container = _newContainer();
      container.listen(roomListContentProvider(null), (_, _) {});
      await pumpEventQueue();

      final content = container.read(roomListContentProvider(null));

      expect(content.joinableBySpace['!s'], isEmpty);
    });

    test('whenSpaceIsOnlyInvited_readsNoHierarchy', () async {
      when(
        _repository.getRoomListEntries(),
      ).thenReturn([_space.copyWith(isJoined: false)]);
      final container = _newContainer();
      container.listen(roomListContentProvider(null), (_, _) {});
      await pumpEventQueue();

      verifyNever(_repository.getSpaceChildren(any));
    });

    test('whenOtherView_offersNothingButKeepsWhatWasRead', () async {
      final container = _newContainer();
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

      verify(_repository.getSpaceChildren('!s')).called(1);
    });
  });
}

class _NoFold extends FoldedSpacesController {
  @override
  Future<Set<String>> build() async => const {};
}
