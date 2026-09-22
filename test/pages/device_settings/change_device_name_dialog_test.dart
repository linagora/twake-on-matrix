import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';

import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/change_device_name_dialog.dart';

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

const _errorMessage = "We couldn't save the changes. Try again later";

Future<void> _pumpView(
  WidgetTester tester, {
  String initialName = 'My laptop',
  required Future<void> Function(String) onSave,
}) {
  return tester.pumpWidget(
    _wrap(ChangeDeviceNameView(initialName: initialName, onSave: onSave)),
  );
}

Future<void> _pumpAndTapSave(
  WidgetTester tester, {
  required Future<void> Function(String) onSave,
  required String newName,
}) async {
  await _pumpView(tester, onSave: onSave);
  await tester.enterText(find.byType(TextField), newName);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

Future<void> _prefillsInputWithCurrentDeviceName(WidgetTester tester) async {
  await _pumpView(tester, initialName: 'My laptop', onSave: (_) async {});

  expect(tester.takeException(), isNull);
  expect(find.text('My laptop'), findsOneWidget);
}

Future<void> _savingWithNonEmptyNameCallsOnSave(WidgetTester tester) async {
  String? savedName;
  await _pumpAndTapSave(
    tester,
    onSave: (name) async => savedName = name,
    newName: 'New name',
  );

  expect(savedName, 'New name');
}

Future<void> _savingEmptyNameIsNoOp(WidgetTester tester) async {
  var saveCalled = false;
  await _pumpAndTapSave(
    tester,
    onSave: (_) async => saveCalled = true,
    newName: '   ',
  );

  expect(saveCalled, isFalse);
}

Future<void> _onSaveErrorKeepsModalOpenWithError(WidgetTester tester) async {
  await _pumpAndTapSave(
    tester,
    onSave: (_) async => throw Exception('network error'),
    newName: 'New name',
  );

  expect(find.text(_errorMessage), findsOneWidget);
  expect(find.text('New name'), findsOneWidget);
  expect(find.byType(ChangeDeviceNameView), findsOneWidget);
}

Future<void> _editingAfterErrorClearsErrorMessage(WidgetTester tester) async {
  await _pumpAndTapSave(
    tester,
    onSave: (_) async => throw Exception('network error'),
    newName: 'New name',
  );
  expect(find.text(_errorMessage), findsOneWidget);

  await tester.enterText(find.byType(TextField), 'New name 2');
  await tester.pump();

  expect(find.text(_errorMessage), findsNothing);
}

void main() {
  testWidgets(
    'prefills the input with the current device name',
    _prefillsInputWithCurrentDeviceName,
  );

  testWidgets(
    'saving with a non-empty name calls onSave with it',
    _savingWithNonEmptyNameCallsOnSave,
  );

  testWidgets(
    'saving an empty name is a no-op (does not call onSave)',
    _savingEmptyNameIsNoOp,
  );

  testWidgets(
    'when onSave throws, the modal stays open, text is preserved, and the '
    'error message is shown',
    _onSaveErrorKeepsModalOpenWithError,
  );

  testWidgets(
    'editing after an error clears the error message',
    _editingAfterErrorClearsErrorMessage,
  );
}
