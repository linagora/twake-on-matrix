import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_notifications/settings_notifications.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

const _userId = '@alice:example.com';
const _appDeviceId = 'APPDEVICE';
const _dedicatedToken = 'dedicated-token';

/// A homeserver without SSO: only password login.
class _PasswordOnlyClient extends Fake implements Client {
  _PasswordOnlyClient(this.httpClient);

  @override
  final http.Client httpClient;

  @override
  String? get userID => _userId;

  @override
  String? get deviceID => _appDeviceId;

  @override
  Uri? get homeserver => Uri.parse('https://example.com');

  @override
  Encryption? get encryption => null;

  @override
  Map<String, DeviceKeysList> get userDeviceKeys => {};

  @override
  bool get allPushNotificationsMuted => true;

  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();

  @override
  Future<List<LoginFlow>?> getLoginFlows() async => [
    LoginFlow(type: AuthenticationTypes.password),
  ];
}

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

String _dedicatedSlot() => jsonEncode(
  KeychainSharingRestoreToken(
    session: KeychainSharingSession(
      accessToken: _dedicatedToken,
      userId: _userId,
      deviceId: 'NSEDEVICE',
      homeserverUrl: 'https://example.com',
    ),
    dedicated: true,
  ).toJson(),
);

void main() {
  late Map<String, String> store;
  late List<http.Request> requests;

  setUp(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
    store = {};
    requests = [];
    FlutterSecureStorage.setMockInitialValues(store);
    PlatformInfos.isTestingForIOS = true;
  });

  tearDown(() {
    PlatformInfos.isTestingForIOS = false;
    GetIt.instance.reset();
  });

  final title = lookupL10n(const Locale('en')).dedicatedNotificationSignIn;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    final httpClient = MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 200);
    });
    await tester.pumpWidget(
      Provider<MatrixState>.value(
        value: _FakeMatrix(_PasswordOnlyClient(httpClient)),
        child: Builder(
          builder: (context) => MaterialApp(
            navigatorKey: TwakeApp.routerKey = GlobalKey<NavigatorState>(),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(context, Brightness.light, null),
            home: const SettingsNotifications(),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets(
    'without SSO, a user with a dedicated device sees its tile, switched on',
    (tester) async {
      store[_userId] = _dedicatedSlot();

      await pumpSettings(tester);

      final tile = find.widgetWithText(SwitchListTile, title);
      expect(tile, findsOneWidget);
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    },
  );

  testWidgets('without a dedicated device, the tile is not shown', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text(title), findsNothing);
  });

  testWidgets(
    'without SSO, turning the tile off logs the dedicated device out',
    (tester) async {
      store[_userId] = _dedicatedSlot();
      await pumpSettings(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, title));
      await settle(tester);

      final logout = requests.where((r) => r.url.path.endsWith('/logout'));
      expect(logout, hasLength(1));
      expect(logout.single.headers['authorization'], 'Bearer $_dedicatedToken');
      expect(store.containsKey(_userId), isFalse);
      expect(find.text(title), findsNothing);
    },
  );
}
