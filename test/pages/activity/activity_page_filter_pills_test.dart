import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/widgets/twake_components/filter_pills.dart';

import 'activity_test_support.dart';

/// #3812: the filters and the search of the Activity look like the ones of
/// Chats (#3773).
void main() {
  group('filter pills', _filterPillTests);
  group('page', _pageTests);
}

Future<void> _pumpPage(WidgetTester tester) => pumpActivityPage(
  tester,
  ActivityPageSetup(repository: FakeActivityRepository()),
);

Material _pill(WidgetTester tester, String label) => tester.widget<Material>(
  find
      .descendant(
        of: find.widgetWithText(FilterPill, label),
        matching: find.byType(Material),
      )
      .first,
);

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void _filterPillTests() {
  testWidgets('the filters are pills on one row, from the 16 pt edge', (
    tester,
  ) async {
    await _pumpPage(tester);

    expect(find.byType(FilterPill), findsNWidgets(4));
    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.getRect(find.byType(FilterPill).first).left, 16);
    final all = tester.getCenter(find.text('All')).dy;
    expect(tester.getCenter(find.text('Replies')).dy, moreOrLessEquals(all));
  });

  testWidgets('the selected filter is filled in primary, without check mark', (
    tester,
  ) async {
    await _pumpPage(tester);
    final colors = LinagoraSysColors.material();

    expect(_pill(tester, 'All').color, colors.primary);
    expect(_labelColor(tester, 'All'), colors.onPrimary);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('the other filters are light grey, without border', (
    tester,
  ) async {
    await _pumpPage(tester);
    final colors = LinagoraSysColors.material();

    expect(_pill(tester, 'Unread').color, colors.surface);
    expect(_pill(tester, 'Unread').shape, const StadiumBorder());
    expect(_labelColor(tester, 'Unread'), colors.onSurface);
  });

  testWidgets('a tapped filter becomes the selected one', (tester) async {
    await _pumpPage(tester);

    await selectFilter(tester, 'Mentions');

    expect(
      _pill(tester, 'Mentions').color,
      LinagoraSysColors.material().primary,
    );
    final selected = tester
        .widgetList<FilterPill>(find.byType(FilterPill))
        .where((pill) => pill.isSelected);
    expect(selected.map((pill) => pill.label), ['Mentions']);
  });
}

void _pageTests() {
  testWidgets('the page is white, so the grey pills and search stand out', (
    tester,
  ) async {
    await _pumpPage(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, LinagoraSysColors.material().onPrimary);
  });

  testWidgets('the search field is the rounded grey field of Chats', (
    tester,
  ) async {
    await _pumpPage(tester);

    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.filled, isTrue);
    final border = decoration.border! as OutlineInputBorder;
    expect(border.borderSide, BorderSide.none);
    expect(border.borderRadius, BorderRadius.circular(24));
  });
}
