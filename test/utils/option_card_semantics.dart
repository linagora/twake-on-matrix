import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether a screen reader announces the option card found by [card] as the
/// chosen one: selected, or checked as a radio button is.
///
/// The state may sit on the card or on a node inside it, so every semantics
/// node of the card is read.
bool isAnnouncedAsChosen(WidgetTester tester, Finder card) {
  expect(card, findsOneWidget);
  final nodes = <SemanticsNode>{tester.getSemantics(card)};
  final inside = find.descendant(
    of: card,
    matching: find.byWidgetPredicate((_) => true),
  );
  for (final element in inside.evaluate()) {
    final node = element.renderObject?.debugSemantics;
    if (node != null) nodes.add(node);
  }
  final chosen = anyOf(
    containsSemantics(isSelected: true),
    containsSemantics(isChecked: true),
  );
  return nodes.any((node) => chosen.matches(node, <Object?, Object?>{}));
}
