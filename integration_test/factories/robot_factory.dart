import 'package:patrol/patrol.dart';

import '../robots/abstract/abstract_login_robot.dart';

/// Contract for producing platform-appropriate robot implementations.
///
/// A conditional-export `robot_factory_provider.dart` picks the right
/// concrete factory at compile time: `MobileRobotFactory` on platforms
/// that expose `dart:io`, `WebRobotFactory` on the web target. Scenarios
/// and tests receive an instance of this factory and never reference a
/// concrete robot class or a platform branch.
///
/// More abstract robot interfaces will be folded into this factory in
/// subsequent PRs (see the cross-platform test architecture issue).
abstract class RobotFactory {
  const RobotFactory();

  PatrolIntegrationTester get $;

  AbstractLoginRobot loginRobot();
}
