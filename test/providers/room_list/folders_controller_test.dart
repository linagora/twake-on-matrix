import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' show Client;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/folders/folders_repository.provider.dart';
import 'package:twake_chat/domain/exception/spaces/folder_exception.dart';
import 'package:twake_chat/domain/repository/folders/folders_repository.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/providers/legacy_active_client_provider.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_entries_provider.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';

import 'folders_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<FoldersRepository>(), MockSpec<Client>()])
void main() {
  setUp(() async {
    _repository = MockFoldersRepository();
    _saved = StreamController<List<Folder>>.broadcast();
    addTearDown(_saved.close);
    when(_repository.watchFolders()).thenAnswer((_) => _saved.stream);
    _container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        foldersRepositoryProvider.overrideWithValue(_repository),
        roomListEntriesProvider.overrideWithValue(const [
          RoomListEntry(id: '!tagged', folders: ['Work']),
          RoomListEntry(id: '!other'),
        ]),
      ],
    );
    _container.listen(foldersControllerProvider, (_, _) {});
    _container.listen(roomListFoldersProvider, (_, _) {});
    await pumpEventQueue();
    await _emit(const [_work, _spaces, _unread, ..._others]);
  });

  _foldersControllerTests();
  _foldersControllerTagOnlyTests();
  _foldersControllerSavesTests();
  _foldersControllerOverlapTests();
  _foldersControllerAccountTests();
  _foldersControllerReorderTests();
  _saveUserFolderTests();
  _saveUserFolderReservedTests();
  _saveUserFolderRenameTests();
  _saveBuiltinTests();
}

const _work = Folder.user('Work');
const _spaces = Folder.builtin(BuiltinFolder.spaces);
const _unread = Folder.builtin(BuiltinFolder.unread);
const _others = [
  Folder.builtin(BuiltinFolder.broadcasts, hidden: true),
  Folder.builtin(BuiltinFolder.directs, hidden: true),
  Folder.builtin(BuiltinFolder.favourites, hidden: true),
];
late MockFoldersRepository _repository;
late StreamController<List<Folder>> _saved;
late ProviderContainer _container;

FoldersController _controller() =>
    _container.read(foldersControllerProvider.notifier);

List<Folder> _shown() => _container.read(roomListFoldersProvider);

void _failSaves() {
  when(
    _repository.saveFolders(any, changes: anyNamed('changes')),
  ).thenThrow(const FolderSaveFailedException());
}

Future<void> _expectSaveFails(Future<void> save) =>
    expectLater(save, throwsA(isA<FolderSaveFailedException>()));

Future<void> _emit(List<Folder> folders) async {
  _saved.add(folders);
  await pumpEventQueue();
}

void _verifySavedOnce(List<Folder> folders) {
  verify(
    _repository.saveFolders(folders, changes: anyNamed('changes')),
  ).called(1);
}

Future<void> _save(String name, {UserFolder? previous}) =>
    _controller().saveUserFolder(
      edited: UserFolder(name),
      previous: previous,
      picked: const {},
      chats: const [],
      reservedNames: const {'Spaces'},
    );

void _foldersControllerTests() {
  group('FoldersController', () {
    test('whenAccountDataIsRead_isLoaded', () {
      expect(_container.read(foldersControllerProvider).isLoaded, isTrue);
      expect(_shown(), [_work, _spaces, _unread]);
    });

    test('remove_whenUserFolder_takesItsTagOffAndSavesTheRest', () async {
      await _controller().remove(_work);

      verify(
        _repository.saveFolders(
          const [_spaces, _unread, ..._others],
          changes: const [
            FolderTagChange(roomId: '!tagged', folderName: 'Work', isIn: false),
          ],
        ),
      ).called(1);
    });

    test('remove_whenTagStaysUntilTheSyncEchoes_dropsTheNameAtOnce', () async {
      await _controller().remove(_work);

      expect(_shown(), [_spaces, _unread]);

      await _controller().remove(_spaces);

      final lastSaved =
          verify(
                _repository.saveFolders(
                  captureAny,
                  changes: anyNamed('changes'),
                ),
              ).captured.last
              as List<Folder>;
      expect(lastSaved.map((folder) => folder.name), isNot(contains('Work')));
    });

    test('remove_whenSaveFails_bringsTheNameBack', () async {
      _failSaves();

      await _expectSaveFails(_controller().remove(_work));

      expect(_shown(), [_work, _spaces, _unread]);
    });

    test('remove_whenListEchoesBeforeTheTags_keepsTheNameAway', () async {
      await _controller().remove(_work);

      await _emit(const [_spaces, _unread, ..._others]);

      expect(_shown(), [_spaces, _unread]);
    });
  });
}

void _foldersControllerTagOnlyTests() {
  group('FoldersController', () {
    test('remove_whenTagOnlyFolderAndSaveFails_bringsTheNameBack', () async {
      _failSaves();
      final tagOnly = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          foldersRepositoryProvider.overrideWithValue(_repository),
          roomListEntriesProvider.overrideWithValue(const [
            RoomListEntry(id: '!z', folders: ['Zed']),
          ]),
        ],
      );
      tagOnly.listen(foldersControllerProvider, (_, _) {});
      tagOnly.listen(roomListFoldersProvider, (_, _) {});
      await pumpEventQueue();
      await _emit(const [_spaces, _unread, ..._others]);

      await _expectSaveFails(
        tagOnly
            .read(foldersControllerProvider.notifier)
            .remove(const Folder.user('Zed')),
      );

      expect(
        tagOnly.read(roomListFoldersProvider),
        contains(const Folder.user('Zed')),
      );
    });

    test('whenTagsAreGone_theNameCanBeUsedAgain', () async {
      final entries = StateProvider<List<RoomListEntry>>(
        (_) => const [
          RoomListEntry(id: '!tagged', folders: ['Work']),
        ],
      );
      final live = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          foldersRepositoryProvider.overrideWithValue(_repository),
          roomListEntriesProvider.overrideWith((ref) => ref.watch(entries)),
        ],
      );
      live.listen(foldersControllerProvider, (_, _) {});
      live.listen(roomListFoldersProvider, (_, _) {});
      await pumpEventQueue();
      await _emit(const [_work, _spaces, _unread, ..._others]);

      await live.read(foldersControllerProvider.notifier).remove(_work);
      live.read(entries.notifier).state = const [RoomListEntry(id: '!tagged')];
      await pumpEventQueue();
      live.read(entries.notifier).state = const [
        RoomListEntry(id: '!tagged', folders: ['Work']),
      ];
      await pumpEventQueue();

      expect(live.read(roomListFoldersProvider), contains(_work));
    });
  });
}

void _foldersControllerSavesTests() {
  group('FoldersController', () {
    test('whenTwoFoldersAreKnownByTagsAlone_showsBoth', () async {
      final tagged = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          foldersRepositoryProvider.overrideWithValue(_repository),
          roomListEntriesProvider.overrideWithValue(const [
            RoomListEntry(id: '!a', folders: ['Home']),
            RoomListEntry(id: '!b', folders: ['Work']),
          ]),
        ],
      );

      final names = tagged
          .read(roomListFoldersProvider)
          .whereType<UserFolder>();

      expect(names.map((folder) => folder.name), ['Home', 'Work']);
    });

    test('whenTwoSavesFail_goesBackToWhatWasLastConfirmed', () async {
      _failSaves();

      final first = _controller().reorder(0, 2);
      final second = _controller().reorder(0, 1);
      await expectLater(first, throwsA(isA<FolderSaveFailedException>()));
      await expectLater(second, throwsA(isA<FolderSaveFailedException>()));

      expect(_shown(), [_work, _spaces, _unread]);
    });

    test('whenTwoSavesOverlap_sendsThemOneAtATime', () async {
      final firstSave = Completer<void>();
      var calls = 0;
      when(
        _repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) {
        calls++;
        return calls == 1 ? firstSave.future : Future.value();
      });

      final first = _controller().reorder(0, 2);
      final second = _controller().reorder(0, 1);
      await pumpEventQueue();
      expect(calls, 1);

      firstSave.complete();
      await Future.wait([first, second]);

      expect(calls, 2);
    });
  });
}

void _foldersControllerOverlapTests() {
  group('FoldersController', () {
    test('whenFirstSaveFailsAndSecondWorks_keepsWhatTheServerHolds', () async {
      var calls = 0;
      when(
        _repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) async {
        if (++calls == 1) throw const FolderSaveFailedException();
      });

      final first = _controller().reorder(0, 2);
      final second = _controller().reorder(0, 1);
      await expectLater(first, throwsA(isA<FolderSaveFailedException>()));
      await second;

      expect(_shown(), [_unread, _spaces, _work]);
    });

    test('whenAnEchoComesDuringASave_keepsWhatTheUserSees', () async {
      final pending = Completer<void>();
      when(
        _repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) => pending.future);

      final save = _controller().reorder(0, 2);
      await pumpEventQueue();
      await _emit(const [_work, _spaces, _unread, ..._others]);

      expect(_shown(), [_spaces, _unread, _work]);
      pending.complete();
      await save;
    });

    test('whenAccountChangesDuringASave_ignoresItsOutcome', () async {
      final pending = Completer<void>();
      when(
        _repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) => pending.future);
      final client = MockClient();
      when(client.userID).thenReturn('@other:own.org');

      final save = _controller().reorder(0, 2);
      await pumpEventQueue();
      _container.read(legacyActiveClientProvider.notifier).setClient(client);
      await pumpEventQueue();
      pending.completeError(const FolderSaveFailedException());
      await expectLater(save, throwsA(isA<FolderSaveFailedException>()));

      expect(_container.read(foldersControllerProvider).saved, isEmpty);

      // The failure of the old account must not leave the counter below zero:
      // the echo of the new account still shows.
      await _emit(const [_spaces, _unread, ..._others]);
      expect(_container.read(foldersControllerProvider).saved, const [
        _spaces,
        _unread,
        ..._others,
      ]);
    });
  });
}

void _foldersControllerAccountTests() {
  group('FoldersController', () {
    test('whenOldAccountSaveFailsWhileNewOneSaves_keepsTheNewList', () async {
      final oldSave = Completer<void>();
      final newSave = Completer<void>();
      var calls = 0;
      when(
        _repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) => ++calls == 1 ? oldSave.future : newSave.future);
      final client = MockClient();
      when(client.userID).thenReturn('@other:own.org');

      final first = _controller().reorder(0, 2);
      await pumpEventQueue();
      _container.read(legacyActiveClientProvider.notifier).setClient(client);
      await pumpEventQueue();
      await _emit(const [_spaces, _unread, ..._others]);
      unawaited(_controller().reorder(0, 1));
      await pumpEventQueue();
      oldSave.completeError(const FolderSaveFailedException());
      await expectLater(first, throwsA(isA<FolderSaveFailedException>()));

      expect(_shown(), [_unread, _spaces, _work]);
      newSave.complete();
    });

    test('remove_whenFolderChangedElsewhere_stillRemovesIt', () async {
      await _emit(const [
        Folder.user('Work', emoji: '💼'),
        _spaces,
        _unread,
        ..._others,
      ]);

      await _controller().remove(_work);

      _verifySavedOnce(const [_spaces, _unread, ..._others]);
    });

    test('remove_whenBuiltin_touchesNoTagAndHidesIt', () async {
      await _controller().remove(_spaces);

      verify(
        _repository.saveFolders(const [
          _work,
          _unread,
          Folder.builtin(BuiltinFolder.broadcasts, hidden: true),
          Folder.builtin(BuiltinFolder.directs, hidden: true),
          Folder.builtin(BuiltinFolder.spaces, hidden: true),
          Folder.builtin(BuiltinFolder.favourites, hidden: true),
        ], changes: const []),
      ).called(1);
    });
  });
}

void _foldersControllerReorderTests() {
  group('FoldersController', () {
    test('reorder_always_showsAtOnceAndNextSaveStartsFromIt', () async {
      final firstSave = Completer<void>();
      when(
        _repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) => firstSave.future);

      unawaited(_controller().reorder(0, 2));
      await pumpEventQueue();
      expect(_shown(), [_spaces, _unread, _work]);

      unawaited(_controller().reorder(0, 1));
      await pumpEventQueue();
      expect(_shown(), [_unread, _spaces, _work]);
      firstSave.complete();
    });

    test('whenSaveFails_putsTheListBackAndThrows', () async {
      _failSaves();

      await _expectSaveFails(_controller().reorder(0, 2));

      expect(_shown(), [_work, _spaces, _unread]);
    });

    test('addBuiltin_always_bringsItBackLast', () async {
      await _controller().addBuiltin(BuiltinFolder.directs);

      expect(_shown().last, const Folder.builtin(BuiltinFolder.directs));
    });
  });
}

void _saveUserFolderTests() {
  group('FoldersController', () {
    group('saveUserFolder', () {
      test('whenNameIsBlank_throws', () async {
        await expectLater(
          _save('  '),
          throwsA(isA<FolderNameRequiredException>()),
        );
      });

      test('whenAnotherFolderHasIt_throwsWhateverTheCase', () async {
        await expectLater(
          _save('WORK'),
          throwsA(isA<FolderNameTakenException>()),
        );
      });

      test('whenItIsTheNameOfABuiltin_throws', () async {
        await expectLater(
          _save('spaces'),
          throwsA(isA<FolderNameTakenException>()),
        );
        await expectLater(
          _save('favourites'),
          throwsA(isA<FolderNameTakenException>()),
        );
      });

      test('whenFolderChangedElsewhere_stillReplacesIt', () async {
        await _emit(const [
          Folder.user('Work', emoji: '💼'),
          _spaces,
          _unread,
          ..._others,
        ]);

        await _save('Job', previous: _work as UserFolder);

        _verifySavedOnce(const [
          Folder.user('Job'),
          _spaces,
          _unread,
          ..._others,
        ]);
      });
    });
  });
}

void _saveUserFolderReservedTests() {
  group('FoldersController', () {
    group('saveUserFolder', () {
      test('whenExistingFolderKeepsAReservedName_saves', () async {
        await _emit(const [
          Folder.user('spaces'),
          _spaces,
          _unread,
          ..._others,
        ]);

        await _controller().saveUserFolder(
          edited: const UserFolder('spaces', emoji: '😀'),
          previous: const UserFolder('spaces'),
          picked: const {},
          chats: const [],
          reservedNames: const {},
        );

        expect(_shown().first, const Folder.user('spaces', emoji: '😀'));
      });

      test('whenABuiltinTakesANameOnlyTheTagsKnow_throws', () async {
        await _emit(const [_spaces, _unread, ..._others]);

        await expectLater(
          _controller().saveBuiltin(
            edited: const BuiltinFolderEntry(
              BuiltinFolder.unread,
              name: 'Work',
            ),
            reservedNames: const {},
          ),
          throwsA(isA<FolderNameTakenException>()),
        );
      });
    });
  });
}

void _saveUserFolderRenameTests() {
  group('FoldersController', () {
    group('saveUserFolder', () {
      test('whenRenameFailedHalfway_retryDoesNotThrow', () async {
        final halfway = ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            foldersRepositoryProvider.overrideWithValue(_repository),
            roomListEntriesProvider.overrideWithValue(const [
              RoomListEntry(id: '!a', folders: ['Work', 'Job']),
            ]),
          ],
        );
        halfway.listen(foldersControllerProvider, (_, _) {});
        await pumpEventQueue();
        await _emit(const [_work, _spaces, _unread, ..._others]);

        await halfway
            .read(foldersControllerProvider.notifier)
            .saveUserFolder(
              edited: const UserFolder('Job'),
              previous: _work as UserFolder,
              picked: const {'!a'},
              chats: const [
                RoomListEntry(id: '!a', folders: ['Work', 'Job']),
              ],
              reservedNames: const {},
            );

        _verifySavedOnce(const [
          Folder.user('Job'),
          _spaces,
          _unread,
          ..._others,
        ]);
      });

      test('whenItKeepsItsOwnName_saves', () async {
        await _save('Work', previous: _work as UserFolder);

        verify(
          _repository.saveFolders(any, changes: anyNamed('changes')),
        ).called(1);
      });

      test('whenSelectedFolderIsRenamed_followsItsNewName', () async {
        _container
            .read(roomListFilterControllerProvider.notifier)
            .select(const RoomListFilter.folder('Work'));

        await _save('Job', previous: _work as UserFolder);

        expect(
          _container.read(roomListFilterControllerProvider),
          const RoomListFilter.folder('Job'),
        );
      });
    });
  });
}

void _saveBuiltinTests() {
  group('FoldersController', () {
    group('saveBuiltin', () {
      test('whenNamedAfterAnotherFilter_throws', () async {
        await expectLater(
          _controller().saveBuiltin(
            edited: const BuiltinFolderEntry(BuiltinFolder.spaces, name: 'New'),
            reservedNames: const {'new'},
          ),
          throwsA(isA<FolderNameTakenException>()),
        );
      });

      test('whenRenamed_keepsItsPlace', () async {
        const renamed = Folder.builtin(BuiltinFolder.spaces, name: 'Mine');

        await _controller().saveBuiltin(
          edited: renamed as BuiltinFolderEntry,
          reservedNames: const {},
        );

        expect(_shown(), [_work, renamed, _unread]);
      });
    });
  });
}
