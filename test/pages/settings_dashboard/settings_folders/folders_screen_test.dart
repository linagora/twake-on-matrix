import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/folders/folders_repository.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/folders/folders_repository.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folders_screen.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../../utils/pump_localized.dart';
import 'folders_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<FoldersRepository>()])
void main() {
  late MockFoldersRepository repository;
  late StreamController<List<Folder>> saved;

  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  Future<void> pump(
    WidgetTester tester,
    List<Folder> folders, {
    Set<BuiltinFolder> builtinsShown = const {},
  }) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = MockFoldersRepository();
    saved = StreamController<List<Folder>>.broadcast();
    addTearDown(saved.close);
    when(repository.watchFolders()).thenAnswer((_) => saved.stream);
    // Never resolves: nothing is read back, the call is what counts.
    when(
      repository.saveFolders(any, changes: anyNamed('changes')),
    ).thenAnswer((_) => Completer<void>().future);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [foldersRepositoryProvider.overrideWithValue(repository)],
    );
    await pumpLocalized(tester, container, const FoldersScreen());
    await tester.pump();
    saved.add([
      for (final kind in BuiltinFolder.values)
        if (!builtinsShown.contains(kind)) Folder.builtin(kind, hidden: true),
      ...folders,
    ]);
    await tester.pump();
    await tester.pump();
  }

  List<Folder> savedFolders() =>
      verify(
            repository.saveFolders(captureAny, changes: anyNamed('changes')),
          ).captured.single
          as List<Folder>;

  group('FoldersScreen', () {
    testWidgets('always_listsTheFoldersInOrder', (tester) async {
      await pump(tester, const [Folder.user('Work'), Folder.user('Play')]);

      expect(
        tester.getTopLeft(find.text('Work')).dy,
        lessThan(tester.getTopLeft(find.text('Play')).dy),
      );
    });

    testWidgets('whenReordered_savesTheNewOrder', (tester) async {
      await pump(tester, const [Folder.user('Work'), Folder.user('Play')]);

      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .onReorderItem!(0, 1);
      await tester.pump();

      expect(savedFolders().whereType<UserFolder>(), [
        const Folder.user('Play'),
        const Folder.user('Work'),
      ]);
    });

    testWidgets('whenDeleteIsConfirmed_savesWithoutTheFolder', (tester) async {
      await pump(tester, const [Folder.user('Work'), Folder.user('Play')]);

      await tester.tap(find.byTooltip('Delete folder').first);
      await tester.pumpAndSettle();
      expect(find.text('Delete this folder?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(savedFolders().whereType<UserFolder>(), [
        const Folder.user('Play'),
      ]);
    });

    testWidgets('whenDeleteIsCancelled_savesNothing', (tester) async {
      await pump(tester, const [Folder.user('Work')]);

      await tester.tap(find.byTooltip('Delete folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(repository.saveFolders(any, changes: anyNamed('changes')));
    });

    testWidgets('whenABuiltinIsMissing_offersToAddItBack', (tester) async {
      await pump(tester, const [Folder.user('Work')]);
      expect(find.text('Recommended'), findsOneWidget);

      await tester.tap(find.text('Add').first);
      await tester.pump();

      expect(
        savedFolders(),
        contains(Folder.builtin(BuiltinFolder.values.first)),
      );
    });
  });
}
