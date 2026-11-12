import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/app_bars/twake_app_bar.dart';

import 'activity_test_support.dart';

/// THR-M-12, slice 1, found on the real app (QA 2026-11-12): on a wide
/// screen the title « Activity » touched the left edge of its pane (1 px),
/// where the titles of the other tabs (Chats, Settings) start 16 px in.
/// The title of the tab starts where the title of « Chats » starts.
void main() {
  /// Where the title of the Chats tab starts, in the theme of the app, on
  /// a screen of the same width.
  Future<double> chatsTitleLeft(WidgetTester tester) async {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: (context, child) => Theme(
          data: TwakeThemes.buildTheme(context, Brightness.light),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            appBar: TwakeAppBar(title: 'Chats', context: context),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getTopLeft(find.text('Chats')).dx;
  }

  testWidgets('on a wide screen, the title « Activity » starts where the '
      'title « Chats » starts', (tester) async {
    await pumpActivityPage(
      tester,
      repository: FakeActivityRepository(),
      wide: true,
      appTheme: true,
    );
    final activityLeft = tester.getTopLeft(find.text('Activity')).dx;

    final chatsLeft = await chatsTitleLeft(tester);

    expect(activityLeft, chatsLeft);
  });
}
