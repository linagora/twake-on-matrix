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
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_entries_provider.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';

import 'folders_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<FoldersRepository>(), MockSpec<Client>()])
void main() {
  const work = Folder.user('Work');
  const spaces = Folder.builtin(BuiltinFolder.spaces);
  const unread = Folder.builtin(BuiltinFolder.unread);
  const others = [
    Folder.builtin(BuiltinFolder.broadcasts, hidden: true),
    Folder.builtin(BuiltinFolder.directs, hidden: true),
    Folder.builtin(BuiltinFolder.favourites, hidden: true),
  ];
  late MockFoldersRepository repository;
  late StreamController<List<Folder>> saved;
  late ProviderContainer container;

  setUp(() async {
    repository = MockFoldersRepository();
    saved = StreamController<List<Folder>>.broadcast();
    addTearDown(saved.close);
    when(repository.watchFolders()).thenAnswer((_) => saved.stream);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        foldersRepositoryProvider.overrideWithValue(repository),
        roomListEntriesProvider.overrideWithValue(const [
          RoomListEntry(id: '!tagged', folders: ['Work']),
          RoomListEntry(id: '!other'),
        ]),
      ],
    );
    container.listen(foldersControllerProvider, (_, _) {});
    container.listen(roomListFoldersProvider, (_, _) {});
    await pumpEventQueue();
    saved.add(const [work, spaces, unread, ...others]);
    await pumpEventQueue();
  });

  FoldersController controller() =>
      container.read(foldersControllerProvider.notifier);

  List<Folder> shown() => container.read(roomListFoldersProvider);

  group('FoldersController', () {
    test('whenAccountDataIsRead_isLoaded', () {
      expect(container.read(foldersControllerProvider).isLoaded, isTrue);
      expect(shown(), [work, spaces, unread]);
    });

    test('remove_whenUserFolder_takesItsTagOffAndSavesTheRest', () async {
      await controller().remove(work);

      verify(
        repository.saveFolders(
          const [spaces, unread, ...others],
          changes: const [
            FolderTagChange(roomId: '!tagged', folderName: 'Work', isIn: false),
          ],
        ),
      ).called(1);
    });

    test('remove_whenTagStaysUntilTheSyncEchoes_dropsTheNameAtOnce', () async {
      await controller().remove(work);

      expect(shown(), [spaces, unread]);

      await controller().remove(spaces);

      final lastSaved =
          verify(
                repository.saveFolders(
                  captureAny,
                  changes: anyNamed('changes'),
                ),
              ).captured.last
              as List<Folder>;
      expect(lastSaved.map((folder) => folder.name), isNot(contains('Work')));
    });

    test('remove_whenSaveFails_bringsTheNameBack', () async {
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenThrow(const FolderSaveFailedException());

      await expectLater(
        controller().remove(work),
        throwsA(isA<FolderSaveFailedException>()),
      );

      expect(shown(), [work, spaces, unread]);
    });

    test('remove_whenListEchoesBeforeTheTags_keepsTheNameAway', () async {
      await controller().remove(work);

      saved.add(const [spaces, unread, ...others]);
      await pumpEventQueue();

      expect(shown(), [spaces, unread]);
    });

    test('remove_whenTagOnlyFolderAndSaveFails_bringsTheNameBack', () async {
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenThrow(const FolderSaveFailedException());
      final tagOnly = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          foldersRepositoryProvider.overrideWithValue(repository),
          roomListEntriesProvider.overrideWithValue(const [
            RoomListEntry(id: '!z', folders: ['Zed']),
          ]),
        ],
      );
      tagOnly.listen(foldersControllerProvider, (_, _) {});
      tagOnly.listen(roomListFoldersProvider, (_, _) {});
      await pumpEventQueue();
      saved.add(const [spaces, unread, ...others]);
      await pumpEventQueue();

      await expectLater(
        tagOnly
            .read(foldersControllerProvider.notifier)
            .remove(const Folder.user('Zed')),
        throwsA(isA<FolderSaveFailedException>()),
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
          foldersRepositoryProvider.overrideWithValue(repository),
          roomListEntriesProvider.overrideWith((ref) => ref.watch(entries)),
        ],
      );
      live.listen(foldersControllerProvider, (_, _) {});
      live.listen(roomListFoldersProvider, (_, _) {});
      await pumpEventQueue();
      saved.add(const [work, spaces, unread, ...others]);
      await pumpEventQueue();

      await live.read(foldersControllerProvider.notifier).remove(work);
      live.read(entries.notifier).state = const [RoomListEntry(id: '!tagged')];
      await pumpEventQueue();
      live.read(entries.notifier).state = const [
        RoomListEntry(id: '!tagged', folders: ['Work']),
      ];
      await pumpEventQueue();

      expect(live.read(roomListFoldersProvider), contains(work));
    });

    test('whenTwoFoldersAreKnownByTagsAlone_showsBoth', () async {
      final tagged = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          foldersRepositoryProvider.overrideWithValue(repository),
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
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenThrow(const FolderSaveFailedException());

      final first = controller().reorder(0, 2);
      final second = controller().reorder(0, 1);
      await expectLater(first, throwsA(isA<FolderSaveFailedException>()));
      await expectLater(second, throwsA(isA<FolderSaveFailedException>()));

      expect(shown(), [work, spaces, unread]);
    });

    test('whenTwoSavesOverlap_sendsThemOneAtATime', () async {
      final firstSave = Completer<void>();
      var calls = 0;
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) {
        calls++;
        return calls == 1 ? firstSave.future : Future.value();
      });

      final first = controller().reorder(0, 2);
      final second = controller().reorder(0, 1);
      await pumpEventQueue();
      expect(calls, 1);

      firstSave.complete();
      await Future.wait([first, second]);

      expect(calls, 2);
    });

    test('whenFirstSaveFailsAndSecondWorks_keepsWhatTheServerHolds', () async {
      var calls = 0;
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) async {
        if (++calls == 1) throw const FolderSaveFailedException();
      });

      final first = controller().reorder(0, 2);
      final second = controller().reorder(0, 1);
      await expectLater(first, throwsA(isA<FolderSaveFailedException>()));
      await second;

      expect(shown(), [unread, spaces, work]);
    });

    test('whenAnEchoComesDuringASave_keepsWhatTheUserSees', () async {
      final pending = Completer<void>();
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) => pending.future);

      final save = controller().reorder(0, 2);
      await pumpEventQueue();
      saved.add(const [work, spaces, unread, ...others]);
      await pumpEventQueue();

      expect(shown(), [spaces, unread, work]);
      pending.complete();
      await save;
    });

    test('whenAccountChangesDuringASave_ignoresItsOutcome', () async {
      final pending = Completer<void>();
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) => pending.future);
      final client = MockClient();
      when(client.userID).thenReturn('@other:own.org');

      final save = controller().reorder(0, 2);
      await pumpEventQueue();
      container.read(activeMatrixClientProvider.notifier).setClient(client);
      await pumpEventQueue();
      pending.completeError(const FolderSaveFailedException());
      await expectLater(save, throwsA(isA<FolderSaveFailedException>()));

      expect(container.read(foldersControllerProvider).saved, isEmpty);

      // The failure of the old account must not leave the counter below zero:
      // the echo of the new account still shows.
      saved.add(const [spaces, unread, ...others]);
      await pumpEventQueue();
      expect(container.read(foldersControllerProvider).saved, const [
        spaces,
        unread,
        ...others,
      ]);
    });

    test('whenOldAccountSaveFailsWhileNewOneSaves_keepsTheNewList', () async {
      final oldSave = Completer<void>();
      final newSave = Completer<void>();
      var calls = 0;
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) => ++calls == 1 ? oldSave.future : newSave.future);
      final client = MockClient();
      when(client.userID).thenReturn('@other:own.org');

      final first = controller().reorder(0, 2);
      await pumpEventQueue();
      container.read(activeMatrixClientProvider.notifier).setClient(client);
      await pumpEventQueue();
      saved.add(const [spaces, unread, ...others]);
      await pumpEventQueue();
      unawaited(controller().reorder(0, 1));
      await pumpEventQueue();
      oldSave.completeError(const FolderSaveFailedException());
      await expectLater(first, throwsA(isA<FolderSaveFailedException>()));

      expect(shown(), [unread, spaces, work]);
      newSave.complete();
    });

    test('remove_whenFolderChangedElsewhere_stillRemovesIt', () async {
      saved.add(const [
        Folder.user('Work', emoji: '💼'),
        spaces,
        unread,
        ...others,
      ]);
      await pumpEventQueue();

      await controller().remove(work);

      verify(
        repository.saveFolders(const [
          spaces,
          unread,
          ...others,
        ], changes: anyNamed('changes')),
      ).called(1);
    });

    test('remove_whenBuiltin_touchesNoTagAndHidesIt', () async {
      await controller().remove(spaces);

      verify(
        repository.saveFolders(const [
          work,
          unread,
          Folder.builtin(BuiltinFolder.broadcasts, hidden: true),
          Folder.builtin(BuiltinFolder.directs, hidden: true),
          Folder.builtin(BuiltinFolder.spaces, hidden: true),
          Folder.builtin(BuiltinFolder.favourites, hidden: true),
        ], changes: const []),
      ).called(1);
    });

    test('reorder_always_showsAtOnceAndNextSaveStartsFromIt', () async {
      final firstSave = Completer<void>();
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenAnswer((_) => firstSave.future);

      unawaited(controller().reorder(0, 2));
      await pumpEventQueue();
      expect(shown(), [spaces, unread, work]);

      unawaited(controller().reorder(0, 1));
      await pumpEventQueue();
      expect(shown(), [unread, spaces, work]);
      firstSave.complete();
    });

    test('whenSaveFails_putsTheListBackAndThrows', () async {
      when(
        repository.saveFolders(any, changes: anyNamed('changes')),
      ).thenThrow(const FolderSaveFailedException());

      await expectLater(
        controller().reorder(0, 2),
        throwsA(isA<FolderSaveFailedException>()),
      );

      expect(shown(), [work, spaces, unread]);
    });

    test('addBuiltin_always_bringsItBackLast', () async {
      await controller().addBuiltin(BuiltinFolder.directs);

      expect(shown().last, const Folder.builtin(BuiltinFolder.directs));
    });

    group('saveUserFolder', () {
      Future<void> save(String name, {UserFolder? previous}) =>
          controller().saveUserFolder(
            edited: UserFolder(name),
            previous: previous,
            picked: const {},
            chats: const [],
            reservedNames: const {'Spaces'},
          );

      test('whenNameIsBlank_throws', () async {
        await expectLater(
          save('  '),
          throwsA(isA<FolderNameRequiredException>()),
        );
      });

      test('whenAnotherFolderHasIt_throwsWhateverTheCase', () async {
        await expectLater(
          save('WORK'),
          throwsA(isA<FolderNameTakenException>()),
        );
      });

      test('whenItIsTheNameOfABuiltin_throws', () async {
        await expectLater(
          save('spaces'),
          throwsA(isA<FolderNameTakenException>()),
        );
        await expectLater(
          save('favourites'),
          throwsA(isA<FolderNameTakenException>()),
        );
      });

      test('whenFolderChangedElsewhere_stillReplacesIt', () async {
        saved.add(const [
          Folder.user('Work', emoji: '💼'),
          spaces,
          unread,
          ...others,
        ]);
        await pumpEventQueue();

        await save('Job', previous: work as UserFolder);

        verify(
          repository.saveFolders(const [
            Folder.user('Job'),
            spaces,
            unread,
            ...others,
          ], changes: anyNamed('changes')),
        ).called(1);
      });

      test('whenExistingFolderKeepsAReservedName_saves', () async {
        saved.add(const [Folder.user('spaces'), spaces, unread, ...others]);
        await pumpEventQueue();

        await controller().saveUserFolder(
          edited: const UserFolder('spaces', emoji: '😀'),
          previous: const UserFolder('spaces'),
          picked: const {},
          chats: const [],
          reservedNames: const {},
        );

        expect(shown().first, const Folder.user('spaces', emoji: '😀'));
      });

      test('whenABuiltinTakesANameOnlyTheTagsKnow_throws', () async {
        saved.add(const [spaces, unread, ...others]);
        await pumpEventQueue();

        await expectLater(
          controller().saveBuiltin(
            edited: const BuiltinFolderEntry(
              BuiltinFolder.unread,
              name: 'Work',
            ),
            reservedNames: const {},
          ),
          throwsA(isA<FolderNameTakenException>()),
        );
      });

      test('whenRenameFailedHalfway_retryDoesNotThrow', () async {
        final halfway = ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            foldersRepositoryProvider.overrideWithValue(repository),
            roomListEntriesProvider.overrideWithValue(const [
              RoomListEntry(id: '!a', folders: ['Work', 'Job']),
            ]),
          ],
        );
        halfway.listen(foldersControllerProvider, (_, _) {});
        await pumpEventQueue();
        saved.add(const [work, spaces, unread, ...others]);
        await pumpEventQueue();

        await halfway
            .read(foldersControllerProvider.notifier)
            .saveUserFolder(
              edited: const UserFolder('Job'),
              previous: work as UserFolder,
              picked: const {'!a'},
              chats: const [
                RoomListEntry(id: '!a', folders: ['Work', 'Job']),
              ],
              reservedNames: const {},
            );

        verify(
          repository.saveFolders(const [
            Folder.user('Job'),
            spaces,
            unread,
            ...others,
          ], changes: anyNamed('changes')),
        ).called(1);
      });

      test('whenItKeepsItsOwnName_saves', () async {
        await save('Work', previous: work as UserFolder);

        verify(
          repository.saveFolders(any, changes: anyNamed('changes')),
        ).called(1);
      });

      test('whenSelectedFolderIsRenamed_followsItsNewName', () async {
        container
            .read(roomListFilterControllerProvider.notifier)
            .select(const RoomListFilter.folder('Work'));

        await save('Job', previous: work as UserFolder);

        expect(
          container.read(roomListFilterControllerProvider),
          const RoomListFilter.folder('Job'),
        );
      });
    });

    group('saveBuiltin', () {
      test('whenNamedAfterAnotherFilter_throws', () async {
        await expectLater(
          controller().saveBuiltin(
            edited: const BuiltinFolderEntry(BuiltinFolder.spaces, name: 'New'),
            reservedNames: const {'new'},
          ),
          throwsA(isA<FolderNameTakenException>()),
        );
      });

      test('whenRenamed_keepsItsPlace', () async {
        const renamed = Folder.builtin(BuiltinFolder.spaces, name: 'Mine');

        await controller().saveBuiltin(
          edited: renamed as BuiltinFolderEntry,
          reservedNames: const {},
        );

        expect(shown(), [work, renamed, unread]);
      });
    });
  });
}
