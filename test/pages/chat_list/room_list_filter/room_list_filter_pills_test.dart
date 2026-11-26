import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_pills.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';

import '../../../providers/fake_active_account.dart';
import '../../../utils/pump_localized.dart';

late ProviderContainer _container;

Future<void> _pump(
  WidgetTester tester,
  List<Folder> folders, {
  bool enabled = true,
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _container = ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [
      ...activeAccountOverrides(null),
      roomListFoldersProvider.overrideWithValue(folders),
    ],
  );
  await pumpLocalized(
    tester,
    _container,
    Scaffold(body: RoomListFilterPills(enabled: enabled)),
  );
}

Material _pill(WidgetTester tester, String label) => tester.widget<Material>(
  find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
);

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

RoomListFilter _selected() => _container.read(roomListFilterControllerProvider);

const _spaces = Folder.builtin(BuiltinFolder.spaces);

void main() {
  testWidgets('always_showsAllThenTheFoldersOnOneRow', (tester) async {
    await _pump(tester, const [_spaces, Folder.user('Work', emoji: '💼')]);

    final all = tester.getRect(find.text('All'));
    final spaces = tester.getRect(find.text('Spaces'));
    final work = tester.getRect(find.text('💼 Work'));
    expect(spaces.left, greaterThan(all.right));
    expect(work.left, greaterThan(spaces.right));
    expect(spaces.center.dy, moreOrLessEquals(all.center.dy));
  });

  testWidgets('whenSelected_isFilledInPrimaryWithoutCheckMark', (tester) async {
    await _pump(tester, const [_spaces]);
    final colors = LinagoraSysColors.material();

    expect(_pill(tester, 'All').color, colors.primary);
    expect(_labelColor(tester, 'All'), colors.onPrimary);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('whenNotSelected_isLightGreyWithoutBorder', (tester) async {
    await _pump(tester, const [_spaces]);
    final colors = LinagoraSysColors.material();

    final pill = _pill(tester, 'Spaces');
    expect(pill.color, colors.surface);
    expect(pill.shape, const StadiumBorder());
    expect(_labelColor(tester, 'Spaces'), colors.onSurface);
  });

  testWidgets('always_startsOnTheSixteenPointEdge', (tester) async {
    await _pump(tester, const [_spaces]);

    final first = find
        .ancestor(of: find.text('All'), matching: find.byType(Material))
        .first;
    expect(tester.getRect(first).left, 16);
  });

  testWidgets('whenFoldersOverflow_scrollsSidewaysWithoutArrows', (
    tester,
  ) async {
    await _pump(tester, [
      for (var i = 0; i < 8; i++) Folder.user('Folder $i'),
    ], width: 320);

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(-1000, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Folder 7')).right, lessThan(320));
  });

  testWidgets('whenPillIsTapped_selectsItsFolder', (tester) async {
    await _pump(tester, const [_spaces]);

    await tester.tap(find.text('Spaces'));
    await tester.pump();

    expect(_selected(), const RoomListFilter.builtin(BuiltinFolder.spaces));
    expect(_pill(tester, 'Spaces').color, LinagoraSysColors.material().primary);
  });

  testWidgets('whenPillIsLongPressed_opensTheFolderMenu', (tester) async {
    await _pump(tester, const [_spaces]);

    await tester.longPress(find.text('Spaces'));
    await tester.pumpAndSettle();

    expect(find.text('Edit folder'), findsOneWidget);
  });

  testWidgets('whenDisabled_aTapChangesNothing', (tester) async {
    await _pump(tester, const [_spaces], enabled: false);

    await tester.tap(find.text('Spaces'));
    await tester.pump();

    expect(_selected(), const RoomListFilter.all());
  });
}
