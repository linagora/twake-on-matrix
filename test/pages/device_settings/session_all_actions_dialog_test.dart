import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';

import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/session_all_actions_dialog.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
    locale: const Locale('en'),
    localizationsDelegates: const [
      L10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: LocalizationService.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  Future<void> pumpOwnDevice(
    WidgetTester tester, {
    required VoidCallback onChangeName,
  }) {
    return tester.pumpWidget(
      _wrap(
        SessionAllActionsView(
          deviceName: 'My laptop',
          lastActiveText: 'Last active: just now',
          platformIcon: Icons.desktop_mac_outlined,
          verified: true,
          onChangeName: onChangeName,
        ),
      ),
    );
  }

  Future<void> pumpOtherDevice(
    WidgetTester tester, {
    required VoidCallback onChangeName,
    required VoidCallback onStartVerification,
    required VoidCallback onRemove,
  }) {
    return tester.pumpWidget(
      _wrap(
        SessionAllActionsView(
          deviceName: "Someone's phone",
          lastActiveText: 'Last active: 2 hours ago',
          platformIcon: Icons.phone_android_outlined,
          verified: false,
          onChangeName: onChangeName,
          onStartVerification: onStartVerification,
          onRemove: onRemove,
        ),
      ),
    );
  }

  testWidgets('renders session name, last activity and available actions', (
    tester,
  ) async {
    await pumpOtherDevice(
      tester,
      onChangeName: () {},
      onStartVerification: () {},
      onRemove: () {},
    );

    expect(tester.takeException(), isNull);
    expect(find.text("Someone's phone"), findsOneWidget);
    expect(find.text('Last active: 2 hours ago'), findsOneWidget);
    expect(find.text('Change device name'), findsOneWidget);
    expect(find.text('Start verification'), findsOneWidget);
    expect(find.text('Remove device'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('own device only shows Change device name, not Verify/Remove', (
    tester,
  ) async {
    await pumpOwnDevice(tester, onChangeName: () {});

    expect(tester.takeException(), isNull);
    expect(find.text('Change device name'), findsOneWidget);
    expect(find.text('Start verification'), findsNothing);
    expect(find.text('Remove device'), findsNothing);
  });

  testWidgets('tapping "Change device name" invokes onChangeName', (
    tester,
  ) async {
    var tapped = false;
    await pumpOwnDevice(tester, onChangeName: () => tapped = true);

    await tester.tap(find.text('Change device name'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('tapping "Start verification" invokes onStartVerification', (
    tester,
  ) async {
    var tapped = false;
    await pumpOtherDevice(
      tester,
      onChangeName: () {},
      onStartVerification: () => tapped = true,
      onRemove: () {},
    );

    await tester.tap(find.text('Start verification'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('tapping "Remove device" invokes onRemove', (tester) async {
    var tapped = false;
    await pumpOtherDevice(
      tester,
      onChangeName: () {},
      onStartVerification: () {},
      onRemove: () => tapped = true,
    );

    await tester.tap(find.text('Remove device'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('tapping Cancel pops without invoking any action', (
    tester,
  ) async {
    var tapped = false;
    await pumpOwnDevice(tester, onChangeName: () => tapped = true);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tapped, isFalse);
  });
}
