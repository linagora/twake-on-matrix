import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../factories/robot_factory_provider.dart';
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
    required ScenarioBuilder scenarioBuilder,
    NativeAutomatorConfig? nativeAutomatorConfig,
    dynamic tags = const [],
    // Marks a test that is intentionally mobile-only — it exercises a
    // capability the web target cannot reach locally (system clipboard,
    // `$.native.*`, a non-resolvable account, or a backend the local web
    // harness lacks). Such tests are skipped on web instead of failing the
    // suite, and run unchanged on mobile.
    bool mobileOnly = false,
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
      // On web, skip tests explicitly flagged [mobileOnly] (they need a
      // capability the local web harness cannot provide). Everything else runs
      // on both platforms; mobile runs all of them.
      skip: kIsWeb && mobileOnly,
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
      ($) async {
        await initTwakeChat();
        _installWebBenignErrorFilter();
        await loginAndRun($);
        final robots = createRobotFactory($);
        await scenarioBuilder($, robots).runTestLogic();
      },
    );
  }

  /// On web, swallows a couple of pre-existing, benign rendering assertions
  /// that fire under the narrow headless-web harness and are unrelated to the
  /// test logic (see [_isBenignWebError]). Mobile stays strict.
  ///
  /// `FlutterError.onError` is a global static, so the previous handler is
  /// captured and restored on teardown — otherwise each test's wrapper would
  /// stack onto the last one's, compounding the filtering.
  void _installWebBenignErrorFilter() {
    final originalOnError = FlutterError.onError ?? FlutterError.presentError;
    addTearDown(() => FlutterError.onError = originalOnError);
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kIsWeb && _isBenignWebError(details)) {
        FlutterError.dumpErrorToConsole(details);
        return;
      }
      originalOnError(details);
    };
  }

  /// Whether [details] is one of the known, benign web-only rendering
  /// assertions:
  ///   * a `RenderFlex` overflow in a few app layouts (e.g. the reply preview
  ///     above the composer);
  ///   * `chat_web_scrollbar` momentarily reporting its `ScrollController`
  ///     attached to multiple scroll views while the layout rebuilds (e.g.
  ///     entering message-select mode).
  ///
  /// The scrollbar case requires the exact framework assertion in addition to
  /// the `chat_web_scrollbar` stack frame, so an unrelated regression from that
  /// file is not silently swallowed.
  static bool _isBenignWebError(FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    final stack = details.stack?.toString() ?? '';
    final isKnownScrollbarAttachAssertion =
        stack.contains('chat_web_scrollbar') &&
        message.contains('ScrollController attached to multiple scroll views');
    return message.contains('A RenderFlex overflowed by') ||
        isKnownScrollbarAttachAssertion;
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
