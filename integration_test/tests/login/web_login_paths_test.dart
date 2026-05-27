/// Web integration test — validates two login paths:
///   1. PRD: OIDC helpers throw [UnsupportedError] on web.
///   2. STG: `m.login.password` straight to the homeserver.
///
/// Uses [testWidgets] + [IntegrationTestWidgetsFlutterBinding] instead of
/// [patrolTest] because Patrol 4.5.0's native automation layer
/// (`PatrolBinding.patrolAppService`) is not initialised on web and causes a
/// [LateInitializationError].  We still construct a [PatrolIntegrationTester]
/// manually so the `$()` finder DSL is available.
library;

import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matrix/matrix.dart';
import 'package:patrol/patrol.dart';

import '../../base/api_login_helper.dart';
import '../../base/web_test_main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Web login — PRD path throws UnsupportedError, '
      'STG path logs in via m.login.password', (tester) async {
    // Build a PatrolIntegrationTester manually (bypassing patrolTest which
    // accesses PatrolBinding.patrolAppService — uninitialised on web).
    final platformAutomator = PlatformAutomator(
      config: PlatformAutomatorConfig.defaultConfig(),
    );
    final $ = PatrolIntegrationTester(
      tester: tester,
      config: const PatrolTesterConfig(visibleTimeout: Duration(minutes: 2)),
      platformAutomator: platformAutomator,
    );

    _verifyPrdPathThrowsOnWeb();

    app.main();
    await _loginViaMatrixPassword(tester, $);
  });
}

/// PRD path: OIDC helpers must throw [UnsupportedError] on web because
/// `dart:io` is unavailable — the web stub rejects immediately.
void _verifyPrdPathThrowsOnWeb() {
  if (!kIsWeb) return;
  expect(
    () => fetchAuthToken(username: 'any', password: 'any'),
    throwsA(isA<UnsupportedError>()),
  );
  expect(
    () => sendMessageAsReceiver(message: 'test'),
    throwsA(isA<UnsupportedError>()),
  );
}

/// STG path: authenticate via `m.login.password` through the Matrix SDK,
/// then force the router to land on [ChatList].
Future<void> _loginViaMatrixPassword(
  WidgetTester tester,
  PatrolIntegrationTester $,
) async {
  const username = String.fromEnvironment('USERNAME');
  const password = String.fromEnvironment('PASSWORD');
  const serverUrl = String.fromEnvironment('SERVER_URL');

  expect(username, isNotEmpty, reason: 'Missing USERNAME in --dart-define');
  expect(password, isNotEmpty, reason: 'Missing PASSWORD in --dart-define');
  expect(serverUrl, isNotEmpty, reason: 'Missing SERVER_URL in --dart-define');

  // Wait for either AutoHomeserverPicker (not-yet-logged-in) or ChatList.
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if ($(AutoHomeserverPicker).exists || $(ChatList).exists) break;
  }

  if ($(ChatList).exists) {
    // Already logged in (cached session) — nothing to do.
    return;
  }

  expect(
    $(AutoHomeserverPicker).exists,
    isTrue,
    reason:
        'AutoHomeserverPicker should be visible on web before login. '
        'If this fails the app may still be loading — check web/config.json.',
  );

  // Grab the live Matrix client from the widget tree.
  final context = tester.element(find.byType(AutoHomeserverPicker).first);
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
  await tester.pump();

  await $(ChatList).waitUntilVisible(timeout: const Duration(seconds: 60));

  expect(
    $(ChatList).exists,
    isTrue,
    reason: 'Should navigate to ChatList after m.login.password',
  );
}
