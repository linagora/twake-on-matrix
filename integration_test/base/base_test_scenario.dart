import 'package:patrol/patrol.dart';

import '../factories/robot_factory.dart';
import 'base_scenario.dart';

/// Base class for cross-platform test scenarios.
///
/// A scenario receives the Patrol tester (`$`) plus a [RobotFactory] and
/// drives the test exclusively through the factory's abstract robots — never
/// through concrete, platform-specific robot classes. The factory selects the
/// right implementation (mobile / web) at compile time, so the same scenario
/// runs unchanged on every platform.
///
/// Concrete scenarios implement [runTestLogic] with the actual steps. Login
/// is performed by [TestBase] before [runTestLogic] is invoked, so scenarios
/// can assume an authenticated session.
abstract class BaseTestScenario extends BaseScenario {
  final RobotFactory robots;

  const BaseTestScenario(super.$, this.robots);

  /// The test body. Implemented per scenario.
  Future<void> runTestLogic();
}

/// Builds a [BaseTestScenario] from the Patrol tester and the platform
/// [RobotFactory]. Passed to `TestBase.runPatrolTest` as `scenarioBuilder`.
typedef ScenarioBuilder = BaseTestScenario Function(
  PatrolIntegrationTester $,
  RobotFactory robots,
);
