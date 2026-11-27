import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/twake_components/filter_pills.dart';

Future<void> _pumpPill(WidgetTester tester, {VoidCallback? onTap}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FilterPill(label: 'Unread', isSelected: false, onTap: onTap),
          ),
        ),
      ),
    );

void main() {
  testWidgets('always_meetsTheTapTargetGuideline', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpPill(tester, onTap: () {});

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('always_drawsAThirtyTwoPointPill', (tester) async {
    await _pumpPill(tester, onTap: () {});

    final pill = find.descendant(
      of: find.byType(FilterPill),
      matching: find.byType(Material),
    );
    expect(tester.getSize(pill).height, 32);
  });

  testWidgets('whenTappedJustOutsideThePill_callsOnTap', (tester) async {
    var taps = 0;
    await _pumpPill(tester, onTap: () => taps++);
    final pill = tester.getRect(
      find.descendant(
        of: find.byType(FilterPill),
        matching: find.byType(Material),
      ),
    );

    await tester.tapAt(Offset(pill.center.dx, pill.top - 6));
    await tester.tapAt(pill.center);

    expect(taps, 2);
  });
}
