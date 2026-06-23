import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../factories/robot_factory_provider.dart';
import 'base_test_scenario.dart';
import 'test_app_initializer.dart';
import 'web_benign_error_filter.dart';

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
    required ScenarioBuilder scenarioBuilder,
    dynamic tags = const [],
    // Marks a test that is intentionally mobile-only — it exercises a
    // capability the web target cannot reach locally (system clipboard,
    // `$.native.*`, a non-resolvable account, or a backend the local web
    // harness lacks). Such tests are skipped on web instead of failing the
    // suite, and run unchanged on mobile.
    bool mobileOnly = false,
  }) {
    // On web a `mobileOnly` test must not be REGISTERED at all (not merely
    // skipped). Patrol web's Playwright runner boots the Flutter app
    // (`page.goto("/")` + `initialise`) for every registered test *before*
    // evaluating `patrolTest.skip(...)`, so a skipped test still pays a full
    // app-boot cycle. A file that leads with — or consists only of — skipped
    // tests then stalls the runner before the first real test starts (the
    // observed 20-min job hang). Returning here removes the test from
    // `__patrol__getTests()`, so Playwright never boots a page for it.
    // Mobile is unaffected (`kIsWeb` is false), so coverage is preserved.
    if (kIsWeb && mobileOnly) return;

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
      nativeAutomatorConfig: defaultNativeConfig,
      tags: tags,
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
      ($) async {
        await initTwakeChat();
        installWebBenignErrorFilter();
        await loginAndRun($);
        final robots = createRobotFactory($);
        await scenarioBuilder($, robots).runTestLogic();
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
}
