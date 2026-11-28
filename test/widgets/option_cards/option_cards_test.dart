import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:twake_chat/widgets/option_cards/option_cards.dart';

import '../../utils/option_card_semantics.dart';

const _teaCard = ValueKey<String>('option-tea');
const _coffeeCard = ValueKey<String>('option-coffee');
const _milkCard = ValueKey<String>('option-milk');
const _teaPreview = ValueKey<String>('preview-tea');
const _coffeePreview = ValueKey<String>('preview-coffee');

/// What the cards are given: the choice held, the layout, the size of each
/// preview, and a third choice or not.
class _Setup {
  const _Setup({
    this.value = 'tea',
    this.layout = OptionCardsLayout.stacked,
    this.preview = const Size(120, 60),
    this.withMilk = false,
  });

  final String value;
  final OptionCardsLayout layout;
  final Size preview;
  final bool withMilk;
}

/// Two choices (three [_Setup.withMilk]), each with a label and a preview, on
/// a phone-wide screen. Returns what the user chose, in order.
Future<List<String>> _pump(
  WidgetTester tester, [
  _Setup setup = const _Setup(),
]) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chosen = <String>[];
  final preview = setup.preview;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
      home: Scaffold(
        body: SingleChildScrollView(
          child: OptionCards<String>(
            value: setup.value,
            layout: setup.layout,
            onChanged: chosen.add,
            choices: [
              OptionCardChoice<String>(
                value: 'tea',
                label: 'Tea',
                key: _teaCard,
                preview: SizedBox.fromSize(key: _teaPreview, size: preview),
              ),
              OptionCardChoice<String>(
                value: 'coffee',
                label: 'Coffee',
                key: _coffeeCard,
                preview: SizedBox.fromSize(key: _coffeePreview, size: preview),
              ),
              if (setup.withMilk)
                OptionCardChoice<String>(
                  value: 'milk',
                  label: 'Milk',
                  key: _milkCard,
                  preview: SizedBox.fromSize(size: preview),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  return chosen;
}

/// [inside] is drawn in the card [card].
void _expectInCard(Key card, Finder inside) => expect(
  find.descendant(of: find.byKey(card), matching: inside),
  findsOneWidget,
);

/// Where the cards [cards] are, in order.
List<Rect> _rects(WidgetTester tester, List<Key> cards) => [
  for (final card in cards) tester.getRect(find.byKey(card)),
];

/// [rects] are within the width of a phone, the first one to the last one.
void _expectOnThePhone(List<Rect> rects) {
  expect(rects.first.left, greaterThanOrEqualTo(0));
  expect(rects.last.right, lessThanOrEqualTo(390));
}

void main() {
  _contentTests();
  _layoutTests();
}

void _contentTests() {
  group('option cards', () {
    testWidgets('show one card per choice, with its label and its preview', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byKey(_teaCard), findsOneWidget);
      expect(find.byKey(_coffeeCard), findsOneWidget);
      _expectInCard(_teaCard, find.text('Tea'));
      _expectInCard(_teaCard, find.byKey(_teaPreview));
      _expectInCard(_coffeeCard, find.text('Coffee'));
      _expectInCard(_coffeeCard, find.byKey(_coffeePreview));
    });

    testWidgets('a tap on the label of a card chooses it', (tester) async {
      final chosen = await _pump(tester);

      await tester.tap(find.text('Coffee'));

      expect(chosen, ['coffee']);
    });

    testWidgets('a tap on the preview of a card chooses it', (tester) async {
      final chosen = await _pump(tester);

      await tester.tap(find.byKey(_coffeePreview));

      expect(chosen, ['coffee']);
    });

    testWidgets('a screen reader hears which card is chosen', (tester) async {
      await _pump(tester, const _Setup(value: 'coffee'));

      expect(isAnnouncedAsChosen(tester, find.byKey(_coffeeCard)), isTrue);
      expect(isAnnouncedAsChosen(tester, find.byKey(_teaCard)), isFalse);
    });

    testWidgets('a screen reader can read the label of each card', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.bySemanticsLabel(RegExp('Tea')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Coffee')), findsWidgets);
    });
  });
}

void _layoutTests() {
  group('option cards, laid out', () {
    testWidgets('side by side: the cards share one row, the first one first, '
        'within the width of a phone', (tester) async {
      await _pump(
        tester,
        const _Setup(
          layout: OptionCardsLayout.sideBySide,
          preview: Size(120, 240),
        ),
      );

      final [tea, coffee] = _rects(tester, [_teaCard, _coffeeCard]);
      expect(tea.top, coffee.top);
      expect(tea.right, lessThanOrEqualTo(coffee.left));
      _expectOnThePhone([tea, coffee]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('side by side with three choices: the three share one row, in '
        'order, within the width of a phone', (tester) async {
      await _pump(
        tester,
        const _Setup(
          layout: OptionCardsLayout.sideBySide,
          preview: Size(80, 200),
          withMilk: true,
        ),
      );

      final [tea, coffee, milk] = _rects(tester, [
        _teaCard,
        _coffeeCard,
        _milkCard,
      ]);
      expect([coffee.top, milk.top], [tea.top, tea.top]);
      expect(tea.right, lessThanOrEqualTo(coffee.left));
      expect(coffee.right, lessThanOrEqualTo(milk.left));
      _expectOnThePhone([tea, coffee, milk]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stacked: the cards are one above the other, the first one on '
        'top, within the width of a phone', (tester) async {
      await _pump(tester, const _Setup(preview: Size(300, 60)));

      final [tea, coffee] = _rects(tester, [_teaCard, _coffeeCard]);
      expect(tea.left, coffee.left);
      expect(tea.bottom, lessThanOrEqualTo(coffee.top));
      _expectOnThePhone([tea, tea]);
      expect(tester.takeException(), isNull);
    });
  });
}
