import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_input_row_web.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

const _field = Key('field');
const _send = Key('send');

Future<void> _pump(
  WidgetTester tester, {
  Widget? moreButton,
  Widget? sendButton,
}) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: Scaffold(
      body: ChatInputRowWeb(
        inputBar: const SizedBox(key: _field, height: 40),
        onTapMoreBtn: () {},
        onEmojiAction: (_) {},
        moreButton: moreButton,
        sendButton: sendButton,
      ),
    ),
  ),
);

void main() {
  setUp(() => getIt.registerSingleton<ResponsiveUtils>(ResponsiveUtils()));
  tearDown(() async => getIt.reset());

  testWidgets('shows the "+" button of the web layout by default', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(TwakeIconButton), findsWidgets);
    expect(find.byKey(const Key('menu')), findsNothing);
  });

  testWidgets('shows the button it was given in place of the "+" button', (
    tester,
  ) async {
    await _pump(tester, moreButton: const SizedBox(key: Key('menu')));

    expect(find.byKey(const Key('menu')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is TwakeIconButton && w.icon == Icons.add_circle_outline,
      ),
      findsNothing,
    );
  });

  // The compact composer of a wide screen (review of #3843): the field on
  // top, then one row of tools under it, the send button at its far right.
  group('the compact composer, given its send button', () {
    Future<void> pumpCompact(WidgetTester tester) => _pump(
      tester,
      sendButton: const SizedBox(key: _send, width: 40, height: 40),
    );

    testWidgets('shows the send button once', (tester) async {
      await pumpCompact(tester);

      expect(find.byKey(_send), findsOneWidget);
    });

    testWidgets('puts the send button under the field, in the row of the '
        '"+" and emoji buttons', (tester) async {
      await pumpCompact(tester);

      final send = tester.getCenter(find.byKey(_send));
      expect(send.dy, greaterThan(tester.getBottomLeft(find.byKey(_field)).dy));
      expect(send.dy, closeTo(tester.getCenter(find.byTooltip('More')).dy, 1));
      expect(
        send.dy,
        closeTo(tester.getCenter(find.byTooltip('Emojis')).dy, 1),
      );
    });

    testWidgets('puts the send button at the far right of the tools', (
      tester,
    ) async {
      await pumpCompact(tester);

      expect(
        tester.getCenter(find.byKey(_send)).dx,
        greaterThan(tester.getCenter(find.byTooltip('Emojis')).dx),
      );
    });
  });

  testWidgets('without a send button: the "+", the field and the emoji '
      'button share one row', (tester) async {
    await _pump(tester);

    final field = tester.getCenter(find.byKey(_field)).dy;
    expect(find.byKey(_send), findsNothing);
    expect(tester.getCenter(find.byTooltip('Emojis')).dy, closeTo(field, 20));
    expect(
      tester.getCenter(find.byTooltip('More')).dx,
      lessThan(tester.getCenter(find.byKey(_field)).dx),
    );
  });
}
