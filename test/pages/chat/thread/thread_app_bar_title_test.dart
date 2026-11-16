import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_app_bar_title.dart';

/// THR-M-04: header of the thread screen: title "Thread", subtitle = the root
/// text on one line.
void main() {
  const longRoot =
      'This root message is long enough to need more than one line on a '
      'phone screen, so the header must cut it instead of growing taller';

  Future<void> pumpTitle(WidgetTester tester, String rootText) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: LocalizationService.supportedLocales,
          home: Scaffold(
            appBar: AppBar(title: ThreadAppBarTitle(rootText: rootText)),
          ),
        ),
      );

  testWidgets('the title is "Thread"', (tester) async {
    await pumpTitle(tester, 'Lunch on Friday?');

    expect(find.text('Thread'), findsOneWidget);
  });

  testWidgets('the subtitle is the root text', (tester) async {
    await pumpTitle(tester, 'Lunch on Friday?');

    expect(find.text('Lunch on Friday?'), findsOneWidget);
  });

  testWidgets('a long root text stays on one line', (tester) async {
    await pumpTitle(tester, 'Short');
    final oneLineHeight = tester.getSize(find.text('Short')).height;

    await pumpTitle(tester, longRoot);

    final subtitle = find.text(longRoot);
    expect(subtitle, findsOneWidget);
    expect(tester.getSize(subtitle).height, oneLineHeight);
  });
}
