import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/device_settings.dart';
import 'package:twake_chat/pages/device_settings/device_settings_view_model.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

const _userId = '@me:example.org';
const _noKeysMessage =
    "This device can't be verified because it has no encryption keys.";

class _FakeClient extends Fake implements Client {
  @override
  String? get userID => _userId;

  @override
  Map<String, DeviceKeysList> userDeviceKeys = {};
}

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

class _FakeViewModel extends Fake implements DevicesSettingsViewModel {}

Future<void> _tapVerify(WidgetTester tester, Client client) async {
  await tester.pumpWidget(
    provider.Provider<MatrixState>.value(
      value: _FakeMatrixState(client),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => verifyDeviceAction(
                context,
                _FakeViewModel(),
                Device(deviceId: 'NOKEYS'),
              ),
              child: const Text('verify'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('verify'));
  await tester.pump();
}

void main() {
  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton<ResponsiveUtils>(ResponsiveUtils());
    }
  });

  testWidgets('GIVEN no device keys are known for the user\n'
      'WHEN verify is tapped\n'
      'THEN a message is shown and nothing throws', (tester) async {
    await _tapVerify(tester, _FakeClient());

    expect(tester.takeException(), isNull);
    expect(find.text(_noKeysMessage), findsOneWidget);
  });

  testWidgets('GIVEN the device never uploaded its device keys\n'
      'WHEN verify is tapped\n'
      'THEN a message is shown and nothing throws', (tester) async {
    final client = _FakeClient();
    client.userDeviceKeys[_userId] = DeviceKeysList(_userId, client);

    await _tapVerify(tester, client);

    expect(tester.takeException(), isNull);
    expect(find.text(_noKeysMessage), findsOneWidget);
  });
}
