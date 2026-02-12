import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:fluffychat/main.dart' as app;
import '../scenarios/login_scenario.dart';

class TestBase {
  void runPatrolTest({
    required String description,
    required Function(PatrolIntegrationTester $) test,
    NativeAutomatorConfig? nativeAutomatorConfig,
    dynamic tags = const [],
  }) {
    const testTimeoutMs = int.fromEnvironment(
      'GLOBAL_TEST_TIMEOUT_MS',
      defaultValue: 120000,
    );

    const visibleTimeoutMs = int.fromEnvironment(
      'GLOBAL_VISIBLE_TIMEOUT_MS',
      defaultValue: 30000,
    );

    const existsTimeoutMs = int.fromEnvironment(
      'GLOBAL_EXISTS_TIMEOUT_MS',
      defaultValue: 6000,
    );

    const settleTimeoutMs = int.fromEnvironment(
      'GLOBAL_SETTLE_TIMEOUT_MS',
      defaultValue: 6000,
    );

    const nativeFindTimeoutMs = int.fromEnvironment(
      'GLOBAL_NATIVE_FIND_TIMEOUT_MS',
      defaultValue: 6000,
    );

    const patrolConfig = PatrolTesterConfig(
      printLogs: true,
      visibleTimeout: Duration(milliseconds: visibleTimeoutMs),
      existsTimeout: Duration(milliseconds: existsTimeoutMs),
      settleTimeout: Duration(milliseconds: settleTimeoutMs),
    );

    const testTimeout = Timeout(Duration(milliseconds: testTimeoutMs));

    const defaultNativeConfig = NativeAutomatorConfig(
      findTimeout: Duration(milliseconds: nativeFindTimeoutMs),
    );
    patrolTest(
      description,
      timeout: testTimeout,
      config: patrolConfig,
      nativeAutomatorConfig: nativeAutomatorConfig ?? defaultNativeConfig,
      tags: tags,
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
      ($) async {
        await initTwakeChat();
        final originalOnError = FlutterError.onError!;
        FlutterError.onError = (FlutterErrorDetails details) {
          originalOnError(details);
        };
        await loginAndRun($);
        await test($);
      },
    );
  }

  Future<void> initTwakeChat() async {
    app.main();
  }

  Future<void> loginAndRun(PatrolIntegrationTester $) async {
    final loginScenario = LoginScenario(
      $,
      username: const String.fromEnvironment('USERNAME'),
      serverUrl: const String.fromEnvironment('SERVER_URL'),
      password: const String.fromEnvironment('PASSWORD'),
    );

    await loginScenario.login();
  }

  void twakePatrolTest({
    required String description,
    required Function(PatrolIntegrationTester $) test,
    NativeAutomatorConfig? nativeAutomatorConfig,
  }) {
    patrolTest(
      description,
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
        await login($);
        await test($);
      },
    );
  }

  Future<void> login(PatrolIntegrationTester $) async {
    final loginScenario = LoginScenario(
      $,
      username: const String.fromEnvironment('USERNAME'),
      serverUrl: const String.fromEnvironment('SERVER_URL'),
      password: const String.fromEnvironment('PASSWORD'),
    );

    await loginScenario.login();
  }
}
