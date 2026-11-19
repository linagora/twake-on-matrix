import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../factories/robot_factory_provider.dart';
import 'base_test_scenario.dart';
import 'test_app_initializer.dart';

typedef TestLogin = ({String serverUrl, String username, String password});

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
    // Marks a test that needs the staging TOM REST backend (served at
    // `/_twake`) — e.g. the contacts-visibility setting.
    bool requiresBackend = false,
    // Marks a test that needs real hardware (Wi-Fi toggling, system
    // clipboard) rather than an emulator.
    bool requiresHardware = false,
    // Changes server state the test does not own: LOCAL_HARNESS only.
    bool requiresDisposableServer = false,
    // Logs in to another account than the default SERVER_URL/USERNAME one.
    TestLogin? login,
  }) {
    // LOCAL_HARNESS: throwaway Synapse, no TOM backend or real hardware.
    const localHarness = bool.fromEnvironment('LOCAL_HARNESS');
    final skipReason = switch ((
      localHarness,
      requiresBackend,
      requiresHardware,
      requiresDisposableServer,
    )) {
      (true, true, _, _) => 'needs the TOM backend, absent from LOCAL_HARNESS',
      (true, _, true, _) => 'needs real hardware, absent from LOCAL_HARNESS',
      (false, _, _, true) => 'changes server state, LOCAL_HARNESS only',
      _ => null,
    };

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
      // Patrol's skip takes no reason, so the report shows it in the name.
      skipReason == null ? description : '$description [skipped: $skipReason]',
      skip: skipReason != null,
      timeout: testTimeout,
      config: patrolConfig,
      nativeAutomatorConfig: defaultNativeConfig,
      tags: tags,
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
      ($) async {
        await initTwakeChat();
        await loginAndRun($, login: login);
        final robots = createRobotFactory($);
        await scenarioBuilder($, robots).runTestLogic();
      },
    );
  }

  Future<void> initTwakeChat() async {
    await initTestApp();
  }

  Future<void> loginAndRun(
    PatrolIntegrationTester $, {
    TestLogin? login,
  }) async {
    if (login != null) {
      if (login.serverUrl.isEmpty ||
          login.username.isEmpty ||
          login.password.isEmpty) {
        throw StateError('Login override is incomplete (missing define?)');
      }
      // The SSO bypass gets its token from SSO_URL, whatever the server URL.
      if (const String.fromEnvironment('SSO_URL').isNotEmpty) {
        throw StateError('Login override needs password login: unset SSO_URL');
      }
    }
    // Route the auto-login through the platform factory so web uses
    // `WebLoginRobot` (waits for `AutoHomeserverPicker`, then
    // `m.login.password`) and mobile keeps `LoginRobot` (waits for
    // `TwakeWelcome`, OIDC/SSO bypass). The mobile path is byte-equivalent
    // to the previous `LoginScenario.login()`.
    final loginRobot = createRobotFactory($).loginRobot();
    await loginRobot.loginViaApi(
      serverUrl: login?.serverUrl ?? const String.fromEnvironment('SERVER_URL'),
      username: login?.username ?? const String.fromEnvironment('USERNAME'),
      password: login?.password ?? const String.fromEnvironment('PASSWORD'),
    );
    await loginRobot.grantNotificationPermission();
  }
}
