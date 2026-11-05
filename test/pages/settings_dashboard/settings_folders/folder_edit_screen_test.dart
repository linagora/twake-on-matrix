import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:twake_chat/data/repository/folders/folders_repository.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/folders/folders_repository.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folder_edit_screen.dart';
import 'package:twake_chat/providers/room_list/room_list_entries_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../../utils/pump_localized.dart';
import 'folder_edit_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<FoldersRepository>()])
void main() {
  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });
  _folderEditScreenTests();
  _folderEditScreenChatsTests();
  _folderEditScreenSaveTests();
  _folderEditScreenLiveTests();
  _builtinFolderEditScreenTests();
  _waitForFoldersTests();
}

late MockFoldersRepository _repository;
late StreamController<List<Folder>> _saved;
late ProviderContainer _container;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<RoomListEntry> Function()? entries,
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _repository = MockFoldersRepository();
  _saved = StreamController<List<Folder>>.broadcast();
  addTearDown(_saved.close);
  when(_repository.watchFolders()).thenAnswer((_) => _saved.stream);
  // Never resolves: the screen would navigate once _saved.
  when(
    _repository.saveFolders(any, changes: anyNamed('changes')),
  ).thenAnswer((_) => Completer<void>().future);
  _container = ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [
      foldersRepositoryProvider.overrideWithValue(_repository),
      roomListEntriesProvider.overrideWith(
        (ref) =>
            entries?.call() ??
            const [
              RoomListEntry(id: '!dm', name: 'Alice', kind: RoomKind.direct),
              RoomListEntry(id: '!tagged', name: 'Tagged', folders: ['Work']),
              RoomListEntry(id: '!s', name: 'A space', kind: RoomKind.space),
            ],
      ),
    ],
  );
  await pumpLocalized(tester, _container, screen);
}

Future<void> _loadFolders(WidgetTester tester, List<Folder> folders) async {
  _saved.add(folders);
  await tester.pump();
  await tester.pump();
}

void _folderEditScreenTests() {
  group('FolderEditScreen', () {
    testWidgets('whenFoldersAreNotReadYet_waitsThenFillsTheForm', (
      tester,
    ) async {
      await _pump(tester, const FolderEditScreen(name: 'Work'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _loadFolders(tester, const [Folder.user('Work', emoji: '💼')]);

      expect(find.text('Edit folder'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Work'), findsOneWidget);
      // The emoji comes from a picker: it is no text to type.
      expect(find.widgetWithText(LinagoraButton, '💼'), findsOneWidget);
      expect(find.widgetWithText(TextField, '💼'), findsNothing);
    });

    testWidgets('whenNameIsTooLong_keepsTheFirstSixtyCharacters', (
      tester,
    ) async {
      await _pump(tester, const FolderEditScreen());
      await tester.pump();
      await _loadFolders(tester, const []);

      await tester.enterText(
        find.byKey(const ValueKey('folder_name')),
        'x' * 80,
      );
      await tester.pump();

      expect(find.text('x' * 60), findsOneWidget);
    });

    testWidgets('whenFullAndTypingInTheMiddle_keepsTheEndAndTheCaret', (
      tester,
    ) async {
      await _pump(tester, const FolderEditScreen());
      await tester.pump();
      await _loadFolders(tester, const []);
      final field = find.descendant(
        of: find.byKey(const ValueKey('folder_name')),
        matching: find.byType(EditableText),
      );
      final text = '${'a' * 30}!${'b' * 30}';

      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: const TextSelection.collapsed(offset: 31),
        ),
      );
      await tester.pump();

      final value = tester.widget<EditableText>(field).controller.value;
      expect(value.text, '${'a' * 30}${'b' * 30}');
      expect(value.selection.baseOffset, 30);
    });
  });
}

void _folderEditScreenChatsTests() {
  group('FolderEditScreen', () {
    testWidgets('whenChatsShareAName_showsTheirSpaceToTellThemApart', (
      tester,
    ) async {
      await _pump(
        tester,
        const FolderEditScreen(),
        entries: () => const [
          RoomListEntry(id: '!s1', name: 'Alpha', kind: RoomKind.space),
          RoomListEntry(id: '!s2', name: 'Beta', kind: RoomKind.space),
          RoomListEntry(id: '!g1', name: 'General', parentSpaceIds: ['!s1']),
          RoomListEntry(id: '!g2', name: 'General', parentSpaceIds: ['!s2']),
        ],
      );
      await tester.pump();
      await _loadFolders(tester, const []);

      final first = find.byKey(const ValueKey('folder_chat_!g1'));
      final second = find.byKey(const ValueKey('folder_chat_!g2'));
      expect(
        find.descendant(of: first, matching: find.text('Alpha')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: second, matching: find.text('Beta')),
        findsOneWidget,
      );
    });

    testWidgets('whenThereAreManyChats_buildsOnlyThoseInView', (tester) async {
      await _pump(
        tester,
        const FolderEditScreen(),
        entries: () => [
          for (var i = 0; i < 500; i++)
            RoomListEntry(id: '!r$i', name: 'Room $i'),
        ],
      );
      await tester.pump();
      await _loadFolders(tester, const []);

      expect(find.byType(LinagoraSettingItem).evaluate().length, lessThan(100));
    });

    testWidgets('always_namesEachColourForAScreenReader', (tester) async {
      await _pump(tester, const FolderEditScreen());
      await tester.pump();
      await _loadFolders(tester, const []);

      expect(find.byTooltip('Folder colour 1'), findsOneWidget);
      expect(find.byTooltip('Folder colour 8'), findsOneWidget);
    });
  });
}

void _folderEditScreenSaveTests() {
  group('FolderEditScreen', () {
    testWidgets('whenNew_tagsWhatIsTickedAndListsNoSpace', (tester) async {
      await _pump(tester, const FolderEditScreen());
      await tester.pump();
      await _loadFolders(tester, const []);
      expect(find.text('A space'), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('folder_name')), 'New');
      await tester.tap(find.text('Alice'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('folder_save')));
      await tester.tap(find.byKey(const ValueKey('folder_save')));
      await tester.pump();

      verify(
        _repository.saveFolders(
          argThat(contains(const Folder.user('New'))),
          changes: const [
            FolderTagChange(roomId: '!dm', folderName: 'New', isIn: true),
          ],
        ),
      ).called(1);
    });
  });
}

void _folderEditScreenLiveTests() {
  group('FolderEditScreen', () {
    testWidgets('whenAChatArrivesWhileEditing_doesNotExcludeIt', (
      tester,
    ) async {
      final entries = ValueNotifierEntries();
      await _pump(
        tester,
        const FolderEditScreen(name: 'Directs'),
        entries: entries.read,
      );
      await tester.pump();
      await _loadFolders(tester, const [
        Folder.user('Directs', include: [FolderChatType.direct]),
      ]);

      entries.add(const RoomListEntry(id: '!new', kind: RoomKind.direct));
      _container.invalidate(roomListEntriesProvider);
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('folder_save')));
      await tester.tap(find.byKey(const ValueKey('folder_save')));
      await tester.pump();

      verify(
        _repository.saveFolders(
          argThat(
            contains(
              const Folder.user('Directs', include: [FolderChatType.direct]),
            ),
          ),
          changes: anyNamed('changes'),
        ),
      ).called(1);
    });

    testWidgets('whenAKindIsTicked_ticksItsChats', (tester) async {
      await _pump(tester, const FolderEditScreen());
      await tester.pump();
      await _loadFolders(tester, const []);

      await tester.tap(find.byKey(const ValueKey('folder_type_direct')));
      await tester.pump();

      expect(
        tester
            .widget<LinagoraSettingItem>(
              find.byKey(const ValueKey('folder_chat_!dm')),
            )
            .value,
        isTrue,
      );
    });
  });
}

void _waitForFoldersTests() {
  group('FolderEditScreen', () {
    testWidgets('whileFoldersNeverLoad_offersAWayOut', (tester) async {
      await _pump(tester, const FolderEditScreen());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });
  });
}

void _builtinFolderEditScreenTests() {
  group('BuiltinFolderEditScreen', () {
    testWidgets('always_offersItsLooksOnly', (tester) async {
      await _pump(
        tester,
        const BuiltinFolderEditScreen(kind: BuiltinFolder.spaces),
      );
      await tester.pump();
      await _loadFolders(tester, const []);

      expect(find.byKey(const ValueKey('folder_name')), findsOneWidget);
      expect(find.byKey(const ValueKey('folder_type_direct')), findsNothing);
      expect(find.text('Alice'), findsNothing);
    });

    testWidgets('whenItsOwnNameIsTyped_savesNoName', (tester) async {
      await _pump(
        tester,
        const BuiltinFolderEditScreen(kind: BuiltinFolder.spaces),
      );
      await tester.pump();
      await _loadFolders(tester, const []);

      await tester.enterText(
        find.byKey(const ValueKey('folder_name')),
        'Spaces',
      );
      await tester.tap(find.byKey(const ValueKey('folder_save')));
      await tester.pump();

      verify(
        _repository.saveFolders(
          argThat(contains(const Folder.builtin(BuiltinFolder.spaces))),
          changes: anyNamed('changes'),
        ),
      ).called(1);
    });
  });
}

/// Rooms that change under a form.
class ValueNotifierEntries {
  final _entries = <RoomListEntry>[
    const RoomListEntry(id: '!dm', name: 'Alice', kind: RoomKind.direct),
  ];

  List<RoomListEntry> read() => List.of(_entries);

  void add(RoomListEntry entry) => _entries.add(entry);
}
