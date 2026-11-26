import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_draft/draft_chat_empty_widget.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

void main() {
  setUp(() => getIt.registerSingleton<ResponsiveUtils>(ResponsiveUtils()));
  tearDown(getIt.reset);

  Future<void> pumpIn(WidgetTester tester, double height) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: height,
                child: const Center(child: DraftChatEmpty()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('fits in the space left by the keyboard', (tester) async {
    await pumpIn(tester, 190);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DraftChatEmpty)).height, 190);
  });

  testWidgets('keeps its natural size when there is room', (tester) async {
    await pumpIn(tester, 600);

    final card = find
        .descendant(
          of: find.byType(DraftChatEmpty),
          matching: find.byType(InkWell),
        )
        .first;
    final fitted = find
        .descendant(
          of: find.byType(DraftChatEmpty),
          matching: find.byType(FittedBox),
        )
        .first;
    expect(tester.getSize(fitted), tester.getSize(card));
  });
}
