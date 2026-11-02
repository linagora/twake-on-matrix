import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_bar.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';

import '../../../utils/pump_localized.dart';

void main() {
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester,
    List<Folder> folders, {
    bool enabled = true,
  }) async {
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [roomListFoldersProvider.overrideWithValue(folders)],
    );
    await pumpLocalized(
      tester,
      container,
      Scaffold(body: RoomListFilterBar(enabled: enabled)),
    );
  }

  RoomListFilter selected() => container.read(roomListFilterControllerProvider);

  group('RoomListFilterBar', () {
    testWidgets('always_showsAllThenTheFoldersByName', (tester) async {
      await pump(tester, const [
        Folder.builtin(BuiltinFolder.spaces),
        Folder.builtin(BuiltinFolder.unread, name: 'New'),
        Folder.user('Work', emoji: '💼'),
      ]);

      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList();
      expect(labels, ['All', 'Spaces', 'New', '💼 Work']);
    });

    testWidgets('whenChipIsTapped_selectsItsViewAndShowsItsMenu', (
      tester,
    ) async {
      await pump(tester, const [Folder.builtin(BuiltinFolder.spaces)]);
      expect(find.byIcon(Icons.more_vert), findsNothing);

      await tester.tap(find.text('Spaces'));
      await tester.pump();

      expect(selected(), const RoomListFilter.builtin(BuiltinFolder.spaces));
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('whenAllIsSelected_hasNoMenu', (tester) async {
      await pump(tester, const []);

      await tester.tap(find.text('All'));
      await tester.pump();

      expect(selected(), const RoomListFilter.all());
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('whenMenuIsOpened_offersToEditAndDelete', (tester) async {
      await pump(tester, const [Folder.user('Work')]);
      await tester.tap(find.text('Work'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit folder'), findsOneWidget);
      expect(find.text('Delete folder'), findsOneWidget);
    });

    testWidgets('whenNothingOverflows_hasNoArrow', (tester) async {
      await pump(tester, const [Folder.user('Work')]);
      await tester.pump();

      expect(find.byTooltip('Previous'), findsNothing);
      expect(find.byTooltip('Next'), findsNothing);
    });

    testWidgets('whenTheRowOverflows_showsLabelledArrows', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, [
        for (var i = 0; i < 8; i++) Folder.user('Folder number $i'),
      ]);
      await tester.pump();
      await tester.pump();

      expect(find.byTooltip('Previous'), findsOneWidget);
      expect(find.byTooltip('Next'), findsOneWidget);
    });

    testWidgets('whenNameIsVeryLong_capsTheChipWidth', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, [Folder.user('W' * 60)]);

      final chip = find.byType(FilterChip);
      expect(tester.getSize(chip.last).width, lessThanOrEqualTo(240));
    });

    testWidgets('whenTheSelectedChipEndsOffScreen_scrollsItIntoView', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final longName = 'L' * 60;
      await pump(tester, [const Folder.user('A'), Folder.user(longName)]);
      await tester.pump();

      // The chip starts in view and its menu button is far out of it.
      await tester.tapAt(
        tester.getTopLeft(find.byType(FilterChip).last) + const Offset(20, 10),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byIcon(Icons.more_vert)).right,
        lessThanOrEqualTo(360),
      );
    });

    testWidgets('whenDisabled_ignoresATap', (tester) async {
      await pump(tester, const [Folder.user('Work')], enabled: false);

      await tester.tap(find.text('Work'));
      await tester.pump();

      expect(selected(), const RoomListFilter.all());
    });

    testWidgets('whenRightClicked_opensTheMenuAtThePointer', (tester) async {
      await pump(tester, const [Folder.user('Work')]);

      await tester.tapAt(
        tester.getCenter(find.text('Work')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit folder'), findsOneWidget);
    });
  });
}
