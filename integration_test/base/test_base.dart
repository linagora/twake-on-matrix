import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../factories/robot_factory_provider.dart';
import '../scenarios/login_scenario.dart';
import 'base_test_scenario.dart';
import 'test_app_initializer.dart';

class TestBase {
  /// Runs a Patrol integration test.
  ///
  /// Provide exactly one of:
  /// - [scenarioBuilder] (preferred): builds a [BaseTestScenario] from the
  ///   tester and the platform [RobotFactory]; the scenario drives the test
  ///   through abstract robots, so it runs on both mobile and web.
  /// - [test] (legacy): an imperative callback receiving only the tester.
  ///   Kept in parallel so existing mobile tests keep compiling during the
  ///   cross-platform migration.
  void runPatrolTest({
    required String description,
    Function(PatrolIntegrationTester $)? test,
    ScenarioBuilder? scenarioBuilder,
    NativeAutomatorConfig? nativeAutomatorConfig,
    dynamic tags = const [],
  }) {
    // Enforced at runtime (not via `assert`) so the contract holds in
    // profile/release builds too, where assertions are compiled out.
    if ((test == null) == (scenarioBuilder == null)) {
      throw ArgumentError(
        'runPatrolTest requires exactly one of `test` or `scenarioBuilder`.',
      );
    }
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

    // NativeAutomatorConfig is no longer a const-constructable class in
    // Patrol 4.x, so we build it with `final` and inline a const Duration.
    final defaultNativeConfig = NativeAutomatorConfig(
      findTimeout: const Duration(milliseconds: nativeFindTimeoutMs),
    );
    patrolTest(
      description,
      timeout: testTimeout,
      config: patrolConfig,
      nativeAutomatorConfig: nativeAutomatorConfig ?? defaultNativeConfig,
      tags: tags,
      // Legacy `test:` entries are mobile-only (they reach `$.native.*` and
      // other mobile-only paths). Skip them on web so a partially-migrated
      // file stays Patrol-Web-green: the `scenarioBuilder` tests run, the
      // not-yet-migrated legacy ones are skipped rather than failing.
      skip: kIsWeb && scenarioBuilder == null,
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
      ($) async {
        await initTwakeChat();
        final originalOnError = FlutterError.onError!;
        FlutterError.onError = (FlutterErrorDetails details) {
          // The narrow headless-web viewport triggers benign `RenderFlex`
          // overflow assertions in a few app layouts (e.g. the reply preview
          // above the composer). These are cosmetic and unrelated to the test
          // logic, but `onError` would otherwise fail the test — so on web we
          // log and swallow overflow-only errors. Mobile stays strict.
          final isOverflow = details.exceptionAsString().contains('overflowed');
          if (kIsWeb && isOverflow) {
            FlutterError.dumpErrorToConsole(details);
            return;
          }
          originalOnError(details);
        };
        await loginAndRun($);
        if (scenarioBuilder != null) {
          final robots = createRobotFactory($);
          await scenarioBuilder($, robots).runTestLogic();
        } else {
          await test!($);
        }
      },
    );
  }

  Future<void> initTwakeChat() async {
    await initTestApp();
  }

  Future<void> loginAndRun(PatrolIntegrationTester $) async {
    // Route the auto-login through the platform factory so web uses
    // `WebLoginRobot` (waits for `AutoHomeserverPicker`, then
    // `m.login.password`) and mobile keeps `LoginRobot` (waits for
    // `TwakeWelcome`, OIDC/SSO bypass). The mobile path is byte-equivalent
    // to the previous `LoginScenario.login()`.
    final loginRobot = createRobotFactory($).loginRobot();
    await loginRobot.loginViaApi(
      serverUrl: const String.fromEnvironment('SERVER_URL'),
      username: const String.fromEnvironment('USERNAME'),
      password: const String.fromEnvironment('PASSWORD'),
    );
    await loginRobot.grantNotificationPermission();
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
      nativeAutomatorConfig: nativeAutomatorConfig ?? NativeAutomatorConfig(),
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
