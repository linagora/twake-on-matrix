/// Web integration test — validates login via `m.login.password` against a
/// locally-provisioned Synapse (no SSO / OIDC).
///
/// `web_test_main` boots the app with a dead homeserver (`localhost:1`) so
/// `AutoHomeserverPicker` fails fast. The test then bypasses the UI by
/// calling `client.login()` programmatically — the same API-level bypass
/// used by the mobile integration tests (PRs #2980, #3015).
library;

import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:patrol/patrol.dart';

import '../../base/web_test_main.dart' as app;

void main() {
  patrolTest(
    'Web login — m.login.password against local Synapse',
    config: const PatrolTesterConfig(
      visibleTimeout: Duration(minutes: 2),
      printLogs: true,
    ),
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
    ($) async {
      const username = String.fromEnvironment('USERNAME');
      const password = String.fromEnvironment('PASSWORD');
      const serverUrl = String.fromEnvironment('SERVER_URL');

      expect(serverUrl, isNotEmpty, reason: 'Missing --dart-define=SERVER_URL');
      expect(username, isNotEmpty, reason: 'Missing --dart-define=USERNAME');
      expect(password, isNotEmpty, reason: 'Missing --dart-define=PASSWORD');

      app.main();

      // Wait for AutoHomeserverPicker (dead homeserver → shows quickly)
      // or ChatList (cached session from a previous run).
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (DateTime.now().isBefore(deadline)) {
        await $.tester.pump(const Duration(milliseconds: 200));
        if ($(AutoHomeserverPicker).exists || $(ChatList).exists) break;
      }

      if ($(ChatList).exists) return; // already logged in

      expect(
        $(AutoHomeserverPicker).exists,
        isTrue,
        reason:
            'AutoHomeserverPicker should be visible on web before login. '
            'If this fails, config.json may be overriding web_test_main — '
            'check that initConfigWeb() respects initConfigCompleter.',
      );

      // Bypass the UI: grab the Matrix client and login programmatically.
      final context = $.tester.element(find.byType(AutoHomeserverPicker).first);
      final matrix = Matrix.of(context);
      final client = await matrix.getLoginClient();

      matrix.loginHomeserverSummary = await client
          .checkHomeserver(Uri.parse(serverUrl))
          .toHomeserverSummary();

      await client.login(
        LoginType.mLoginPassword,
        identifier: AuthenticationUserIdentifier(user: username),
        password: password,
        initialDeviceDisplayName: PlatformInfos.clientName,
      );

      // Force the router to re-evaluate redirects → lands on ChatList.
      TwakeApp.router.go('/');
      await $.tester.pump();

      await $(ChatList).waitUntilVisible(timeout: const Duration(seconds: 60));

      expect(
        $(ChatList).exists,
        isTrue,
        reason: 'Should navigate to ChatList after m.login.password',
      );
    },
  );
}
