import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_input_row_web.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

Future<void> _pump(WidgetTester tester, {Widget? moreButton}) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: ChatInputRowWeb(
            inputBar: const SizedBox(),
            onTapMoreBtn: () {},
            onEmojiAction: (_) {},
            moreButton: moreButton,
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
}
