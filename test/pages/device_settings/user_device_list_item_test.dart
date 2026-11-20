import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/user_device_list_item.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

const _userId = '@me:example.org';
const _otherDeviceId = 'OTHER';

class _FakeClient extends Fake implements Client {
  @override
  String? get userID => _userId;

  @override
  String? get deviceID => 'CURRENT';

  @override
  bool get encryptionEnabled => false;

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

DeviceKeys _unverifiedKeys(Client client) => DeviceKeys.fromDb({
  'device_id': _otherDeviceId,
  'verified': false,
  'blocked': false,
  'content': {
    'user_id': _userId,
    'device_id': _otherDeviceId,
    'algorithms': <String>[],
    'keys': <String, String>{},
  },
}, client);

Future<void> _pumpItem(
  WidgetTester tester,
  Client client, {
  required void Function(Device) verify,
}) {
  return tester.pumpWidget(
    provider.Provider<MatrixState>.value(
      value: _FakeMatrixState(client),
      child: MaterialApp(
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
          body: UserDeviceListItem(
            Device(deviceId: _otherDeviceId, displayName: 'android'),
            verify: verify,
          ),
        ),
      ),
    ),
  );
}

VoidCallback? _verifyButtonCallback(WidgetTester tester) => tester
    .widget<SessionDeviceListItem>(find.byType(SessionDeviceListItem))
    .onVerifyPressed;

Future<void> _openActions(WidgetTester tester) async {
  await tester.tap(find.text('android'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('GIVEN a device that never uploaded its device keys\n'
      'THEN it is shown as unverified and Verify is not offered', (
    tester,
  ) async {
    final client = _FakeClient();
    client.userDeviceKeys[_userId] = DeviceKeysList(_userId, client);

    await _pumpItem(tester, client, verify: (_) {});

    expect(find.text('Unverified'), findsOneWidget);
    expect(_verifyButtonCallback(tester), isNull);

    await _openActions(tester);
    expect(find.text('Change device name'), findsOneWidget);
    expect(find.text('Start verification'), findsNothing);
  });

  testWidgets('GIVEN an unverified device with device keys\n'
      'THEN Verify is offered on the row and in the actions', (tester) async {
    final client = _FakeClient();
    client.userDeviceKeys[_userId] = DeviceKeysList(_userId, client)
      ..deviceKeys[_otherDeviceId] = _unverifiedKeys(client);
    final verified = <Device>[];

    await _pumpItem(tester, client, verify: verified.add);

    _verifyButtonCallback(tester)!();
    expect(verified.single.deviceId, _otherDeviceId);

    await _openActions(tester);
    expect(find.text('Start verification'), findsOneWidget);
  });
}
