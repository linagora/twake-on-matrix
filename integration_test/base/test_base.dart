import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:fluffychat/main.dart' as app;
import '../robots/home_robot.dart';
import '../scenarios/login_scenario.dart';

class TestBase {
  void runPatrolTest({
    required String description,
    required Function(PatrolIntegrationTester $) test,
    NativeAutomatorConfig? nativeAutomatorConfig,
  }) {
    patrolTest(description,
        config: const PatrolTesterConfig(
          printLogs: true,
          visibleTimeout: Duration(minutes: 1),
        ),
        nativeAutomatorConfig:
            nativeAutomatorConfig ?? const NativeAutomatorConfig(),
        framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
        ($) async {
      await initTwakeChat();
      final originalOnError = FlutterError.onError!;
      FlutterError.onError = (FlutterErrorDetails details) {
        originalOnError(details);
      };
      await loginAndRun($);
      await test($);
    });
  }

  Future<void> initTwakeChat() async {
    app.main();
  }

  Future<void> loginAndRun(
    PatrolIntegrationTester $,
  ) async {
    final loginScenario = LoginScenario(
      $,
      username: const String.fromEnvironment('USERNAME'),
      serverUrl: const String.fromEnvironment('SERVER_URL'),
      password: const String.fromEnvironment('PASSWORD'),
    );

    await loginScenario.login();
    //because permission to share contact and share media popup always display at contactScreen
    //, so that I go to contactListScreen to close them
    await HomeRobot($).gotoContactListAndGrantContactPermission();
  }
}
