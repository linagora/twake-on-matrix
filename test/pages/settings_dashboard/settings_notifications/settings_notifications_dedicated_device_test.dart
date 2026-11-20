import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_notifications/settings_notifications.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/twake_app.dart';

const _userId = '@alice:example.com';

// The l10n key of the old tile is gone, so its English title is spelled out.
const _oldTileTitle = 'Dedicated notification sign-in';

class _FakeClient extends Fake implements Client {
  @override
  String? get userID => _userId;

  @override
  String? get deviceID => 'APPDEVICE';

  @override
  Encryption? get encryption => null;

  @override
  Map<String, DeviceKeysList> get userDeviceKeys => {};

  @override
  bool get allPushNotificationsMuted => true;

  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();
}

void main() {
  setUp(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
    FlutterSecureStorage.setMockInitialValues({
      _userId: jsonEncode(
        KeychainSharingRestoreToken(
          session: KeychainSharingSession(
            accessToken: 'dedicated-token',
            userId: _userId,
            deviceId: 'NSEDEVICE',
            homeserverUrl: 'https://example.com',
          ),
          dedicated: true,
        ).toJson(),
      ),
    });
    PlatformInfos.isTestingForIOS = true;
  });

  tearDown(() {
    PlatformInfos.isTestingForIOS = false;
    GetIt.instance.reset();
  });

  testWidgets(
    'with a dedicated notification device, settings show no tile for it',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [matrixClientProvider.overrideWithValue(_FakeClient())],
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
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text(_oldTileTitle), findsNothing);
      // Notifications are muted: only the master switch is left.
      expect(find.byType(SwitchListTile), findsOneWidget);
    },
  );
}
