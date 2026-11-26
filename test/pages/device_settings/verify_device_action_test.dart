import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/device_settings.dart';
import 'package:twake_chat/pages/device_settings/device_settings_view_model.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/twake_app.dart';

const _userId = '@me:example.org';
const _deviceId = 'NOKEYS';
const _noKeysMessage =
    "This device can't be verified because it has no encryption keys.";

class _FakeDeviceKeys extends Fake implements DeviceKeys {
  var startVerificationCalls = 0;

  @override
  Future<KeyVerification> startVerification() {
    startVerificationCalls++;
    return Completer<KeyVerification>().future;
  }
}

class _FakeClient extends Fake implements Client {
  /// Keys the server returns for the device when they are refetched.
  DeviceKeys? keysOnServer;
  var refreshCalls = 0;

  @override
  String? get userID => _userId;

  @override
  Map<String, DeviceKeysList> userDeviceKeys = {};

  @override
  Future<void> updateUserDeviceKeys({Set<String>? additionalUsers}) async {
    refreshCalls++;
    final keys = keysOnServer;
    if (keys == null) return;
    (userDeviceKeys[_userId] ??= DeviceKeysList(
      _userId,
      this,
    )).deviceKeys[_deviceId] = keys;
  }
}

class _FakeViewModel extends Fake implements DevicesSettingsViewModel {}

Future<void> _tapVerify(WidgetTester tester, Client client) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: TwakeApp.routerKey,
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
              client,
              _FakeViewModel(),
              Device(deviceId: _deviceId),
            ),
            child: const Text('verify'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('verify'));
  // The loading dialog animates forever, so settle by time, not by frames.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton<ResponsiveUtils>(ResponsiveUtils());
    }
  });

  testWidgets('GIVEN no device keys are known for the user\n'
      'WHEN verify is tapped and the refresh brings none\n'
      'THEN a message is shown and nothing throws', (tester) async {
    final client = _FakeClient();

    await _tapVerify(tester, client);

    expect(tester.takeException(), isNull);
    expect(client.refreshCalls, 1);
    expect(find.text(_noKeysMessage), findsOneWidget);
  });

  testWidgets('GIVEN the device never uploaded its device keys\n'
      'WHEN verify is tapped and the refresh brings none\n'
      'THEN a message is shown and nothing throws', (tester) async {
    final client = _FakeClient();
    client.userDeviceKeys[_userId] = DeviceKeysList(_userId, client);

    await _tapVerify(tester, client);

    expect(tester.takeException(), isNull);
    expect(client.refreshCalls, 1);
    expect(find.text(_noKeysMessage), findsOneWidget);
  });

  testWidgets('GIVEN the device keys are only missing locally\n'
      'WHEN verify is tapped and the refresh brings them\n'
      'THEN the verification starts and no message is shown', (tester) async {
    final keys = _FakeDeviceKeys();
    final client = _FakeClient()..keysOnServer = keys;

    await _tapVerify(tester, client);

    expect(tester.takeException(), isNull);
    expect(client.refreshCalls, 1);
    expect(keys.startVerificationCalls, 1);
    expect(find.text(_noKeysMessage), findsNothing);
  });
}
