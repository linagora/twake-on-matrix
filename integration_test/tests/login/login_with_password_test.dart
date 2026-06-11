import 'package:fluffychat/main.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../help/soft_assertion_helper.dart';
import '../../robots/login_robot.dart';

void main() {
  patrolTest(
    'User can successfully login with valid credentials',
    config: const PatrolTesterConfig(
      printLogs: true,
      visibleTimeout: Duration(minutes: 1),
    ),
    nativeAutomatorConfig: NativeAutomatorConfig(),
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
    ($) async {
      // Initialize app without auto-login
      app.main();

      // Set up error handler
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        (originalOnError ?? FlutterError.presentError)(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      final s = SoftAssertHelper();
      final loginRobot = LoginRobot($);

      const username = String.fromEnvironment('USERNAME');
      const password = String.fromEnvironment('PASSWORD');
      const serverUrl = String.fromEnvironment('SERVER_URL');

      expect(username, isNotEmpty, reason: 'Missing USERNAME in --dart-define');
      expect(password, isNotEmpty, reason: 'Missing PASSWORD in --dart-define');
      expect(
        serverUrl,
        isNotEmpty,
        reason: 'Missing SERVER_URL in --dart-define',
      );

      if (kIsWeb) {
        // On web, PATROL_WEB=true keeps AutoHomeserverPicker idle so the
        // test can drive authentication via the Matrix SDK directly.
        await loginRobot.loginViaApi(
          serverUrl: serverUrl,
          username: username,
          password: password,
        );
      } else {
        // On mobile, navigate through the UI login flow.
        if (await loginRobot.isWelcomePageVisible()) {
          await loginRobot.tapOnUseYourCompanyServer();
          await loginRobot.enterServerUrl(serverUrl);
          await loginRobot.clickOnContinueBtn();
        }
        await loginRobot.loginWithPassword(
          username: username,
          password: password,
        );
        await loginRobot.waitForChatList();
      }

      // Verify we're on the chat list screen
      s.softAssertEquals(
        await loginRobot.isChatListVisible(),
        true,
        'Navigated to ChatList',
      );

      // Verify login screen is no longer visible
      s.softAssertEquals(
        await loginRobot.isLoginViewVisible(),
        false,
        'LoginView is no longer visible',
      );

      s.verifyAll();
    },
  );
}
