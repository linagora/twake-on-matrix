import 'dart:async';

import 'package:flutter/gestures.dart';
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
import '../../../providers/fake_active_account.dart';

@GenerateNiceMocks([MockSpec<FoldersRepository>()])
void main() {
  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });
  _foldersScreenTests();
}

late MockFoldersRepository _repository;
late StreamController<List<Folder>> _saved;

Future<void> _pump(
  WidgetTester tester,
  List<Folder> folders, {
  Set<BuiltinFolder> builtinsShown = const {},
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _repository = MockFoldersRepository();
  _saved = StreamController<List<Folder>>.broadcast();
  addTearDown(_saved.close);
  when(_repository.watchFolders()).thenAnswer((_) => _saved.stream);
  // Never resolves: nothing is read back, the call is what counts.
  when(
    _repository.saveFolders(any, changes: anyNamed('changes')),
  ).thenAnswer((_) => Completer<void>().future);
  final container = ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [
      ...activeAccountOverrides(null),
      foldersRepositoryProvider.overrideWithValue(_repository),
    ],
  );
  await pumpLocalized(
    tester,
    container,
    Directionality(textDirection: textDirection, child: const FoldersScreen()),
  );
  await tester.pump();
  _saved.add([
    for (final kind in BuiltinFolder.values)
      if (!builtinsShown.contains(kind)) Folder.builtin(kind, hidden: true),
    ...folders,
  ]);
  await tester.pump();
  await tester.pump();
}

List<Folder> _savedFolders() =>
    verify(
          _repository.saveFolders(captureAny, changes: anyNamed('changes')),
        ).captured.single
        as List<Folder>;

void _foldersScreenTests() {
  group('FoldersScreen', () {
    testWidgets('always_listsTheFoldersInOrder', (tester) async {
      await _pump(tester, const [Folder.user('Work'), Folder.user('Play')]);

      expect(
        tester.getTopLeft(find.text('Work')).dy,
        lessThan(tester.getTopLeft(find.text('Play')).dy),
      );
    });

    testWidgets('whenReordered_savesTheNewOrder', (tester) async {
      await _pump(tester, const [Folder.user('Work'), Folder.user('Play')]);

      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .onReorderItem!(0, 1);
      await tester.pump();

      expect(_savedFolders().whereType<UserFolder>(), [
        const Folder.user('Play'),
        const Folder.user('Work'),
      ]);
    });

    testWidgets('whenDeleteIsConfirmed_savesWithoutTheFolder', (tester) async {
      await _pump(tester, const [Folder.user('Work'), Folder.user('Play')]);

      await tester.tap(find.byTooltip('Delete folder').first);
      await tester.pumpAndSettle();
      expect(find.text('Delete this folder?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(_savedFolders().whereType<UserFolder>(), [
        const Folder.user('Play'),
      ]);
    });

    testWidgets('onDesktop_letsDeleteBeTapped', (tester) async {
      await _pump(tester, const [Folder.user('Work')]);

      expect(find.byIcon(Icons.drag_handle), findsNothing);
      await tester.tap(find.byTooltip('Delete folder'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this folder?'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('onDesktop_reordersOnALongPressDrag', (tester) async {
      await _pump(tester, const [Folder.user('Work'), Folder.user('Play')]);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Work')),
      );
      await tester.pump(kLongPressTimeout + kPressTimeout);
      final distance =
          tester.getCenter(find.text('Play')).dy -
          tester.getCenter(find.text('Work')).dy;
      for (var step = 0; step < 4; step++) {
        await gesture.moveBy(Offset(0, distance / 2));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_savedFolders().whereType<UserFolder>(), [
        const Folder.user('Play'),
        const Folder.user('Work'),
      ]);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('whenDeleteIsCancelled_savesNothing', (tester) async {
      await _pump(tester, const [Folder.user('Work')]);

      await tester.tap(find.byTooltip('Delete folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(_repository.saveFolders(any, changes: anyNamed('changes')));
    });

    testWidgets('whenThereIsNoFolder_showsNoFoldersHeader', (tester) async {
      await _pump(tester, const []);

      expect(find.text('YOUR FOLDERS'), findsNothing);
    });

    testWidgets('whenThereAreFolders_headsThemYourFolders', (tester) async {
      await _pump(tester, const [Folder.user('Work')]);

      expect(find.text('YOUR FOLDERS'), findsOneWidget);
    });

    testWidgets('always_centresBadgeAndDeleteOnTheRow', (tester) async {
      await _pump(
        tester,
        const [],
        builtinsShown: {BuiltinFolder.values.first},
      );

      final row = find.ancestor(
        of: find.byType(FolderBadge),
        matching: find.byType(InkWell),
      );
      final rowCenter = tester.getCenter(row.first).dy;
      expect(tester.getSize(find.byType(FolderBadge)), const Size(40, 40));
      expect(tester.getCenter(find.byType(FolderBadge)).dy, rowCenter);
      expect(
        tester.getCenter(find.byKey(const ValueKey('folder_delete'))).dy,
        rowCenter,
      );
    });

    testWidgets('always_centresTheEmojiOnItsBadge', (tester) async {
      await _pump(tester, const [Folder.user('Work', emoji: '💼')]);

      expect(
        tester.getCenter(find.text('💼')),
        tester.getCenter(find.byType(FolderBadge)),
      );
    });

    testWidgets('always_endsTheDeleteIconOnTheRightEdge', (tester) async {
      await _pump(tester, const [Folder.user('Work')]);

      final icon = find.descendant(
        of: find.byKey(const ValueKey('folder_delete')),
        matching: find.byIcon(Icons.delete_outline),
      );
      expect(tester.getTopRight(icon).dx, tester.view.physicalSize.width - 16);
    });

    testWidgets('inRightToLeft_mirrorsTheBadgeAndDeleteEdges', (tester) async {
      await _pump(tester, const [
        Folder.user('Work'),
      ], textDirection: TextDirection.rtl);

      final icon = find.descendant(
        of: find.byKey(const ValueKey('folder_delete')),
        matching: find.byIcon(Icons.delete_outline),
      );
      final width = tester.view.physicalSize.width;
      expect(tester.getTopRight(find.byType(FolderBadge)).dx, width - 16);
      expect(tester.getTopLeft(icon).dx, 16);
    });

    testWidgets('whenABuiltinIsMissing_offersToAddItBack', (tester) async {
      await _pump(tester, const [Folder.user('Work')]);
      expect(find.text('RECOMMENDED'), findsOneWidget);

      await tester.tap(find.text('Add').first);
      await tester.pump();

      expect(
        _savedFolders(),
        contains(Folder.builtin(BuiltinFolder.values.first)),
      );
    });
  });
}
