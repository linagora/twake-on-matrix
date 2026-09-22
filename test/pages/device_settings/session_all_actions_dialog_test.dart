import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';

import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/session_all_actions_dialog.dart';
import 'package:twake_chat/pages/device_settings/session_summary.dart';

const _ownDeviceSession = SessionSummary(
  deviceName: 'My laptop',
  lastActiveText: 'Last active: just now',
  platformIcon: Icons.desktop_mac_outlined,
  verified: true,
);

const _otherDeviceSession = SessionSummary(
  deviceName: "Someone's phone",
  lastActiveText: 'Last active: 2 hours ago',
  platformIcon: Icons.phone_android_outlined,
  verified: false,
);

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

Future<void> _pumpOwnDevice(
  WidgetTester tester, {
  required VoidCallback onChangeName,
}) {
  return tester.pumpWidget(
    _wrap(
      SessionAllActionsView(
        session: _ownDeviceSession,
        onChangeName: onChangeName,
      ),
    ),
  );
}

Future<void> _pumpOtherDevice(
  WidgetTester tester, {
  required VoidCallback onChangeName,
  required VoidCallback onStartVerification,
  required VoidCallback onRemove,
}) {
  return tester.pumpWidget(
    _wrap(
      SessionAllActionsView(
        session: _otherDeviceSession,
        onChangeName: onChangeName,
        onStartVerification: onStartVerification,
        onRemove: onRemove,
      ),
    ),
  );
}

Future<void> _rendersSessionInfoAndAvailableActions(WidgetTester tester) async {
  await _pumpOtherDevice(
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
}

Future<void> _ownDeviceOnlyShowsChangeDeviceName(WidgetTester tester) async {
  await _pumpOwnDevice(tester, onChangeName: () {});

  expect(tester.takeException(), isNull);
  expect(find.text('Change device name'), findsOneWidget);
  expect(find.text('Start verification'), findsNothing);
  expect(find.text('Remove device'), findsNothing);
}

Future<void> _tappingChangeDeviceNameInvokesCallback(
  WidgetTester tester,
) async {
  var tapped = false;
  await _pumpOwnDevice(tester, onChangeName: () => tapped = true);

  await tester.tap(find.text('Change device name'));
  await tester.pumpAndSettle();

  expect(tapped, isTrue);
}

Future<void> _tappingStartVerificationInvokesCallback(
  WidgetTester tester,
) async {
  var tapped = false;
  await _pumpOtherDevice(
    tester,
    onChangeName: () {},
    onStartVerification: () => tapped = true,
    onRemove: () {},
  );

  await tester.tap(find.text('Start verification'));
  await tester.pumpAndSettle();

  expect(tapped, isTrue);
}

Future<void> _tappingRemoveDeviceInvokesCallback(WidgetTester tester) async {
  var tapped = false;
  await _pumpOtherDevice(
    tester,
    onChangeName: () {},
    onStartVerification: () {},
    onRemove: () => tapped = true,
  );

  await tester.tap(find.text('Remove device'));
  await tester.pumpAndSettle();

  expect(tapped, isTrue);
}

Future<void> _tappingCancelPopsWithoutInvokingAnyAction(
  WidgetTester tester,
) async {
  var tapped = false;
  await _pumpOwnDevice(tester, onChangeName: () => tapped = true);

  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();

  expect(tapped, isFalse);
}

void main() {
  testWidgets(
    'renders session name, last activity and available actions',
    _rendersSessionInfoAndAvailableActions,
  );

  testWidgets(
    'own device only shows Change device name, not Verify/Remove',
    _ownDeviceOnlyShowsChangeDeviceName,
  );

  testWidgets(
    'tapping "Change device name" invokes onChangeName',
    _tappingChangeDeviceNameInvokesCallback,
  );

  testWidgets(
    'tapping "Start verification" invokes onStartVerification',
    _tappingStartVerificationInvokesCallback,
  );

  testWidgets(
    'tapping "Remove device" invokes onRemove',
    _tappingRemoveDeviceInvokesCallback,
  );

  testWidgets(
    'tapping Cancel pops without invoking any action',
    _tappingCancelPopsWithoutInvokingAnyAction,
  );
}
