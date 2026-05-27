import 'package:patrol/patrol.dart';

import '../robots/abstract/abstract_login_robot.dart';
import '../robots/login_robot.dart';
import 'robot_factory.dart';

/// Mobile implementation of [RobotFactory].
///
/// Delegates to the concrete robot classes that existed before the
/// cross-platform refactor. As more abstract robot interfaces are added,
/// this factory gains a getter per feature area.
class MobileRobotFactory implements RobotFactory {
  const MobileRobotFactory(this.$);

  @override
  final PatrolIntegrationTester $;

  @override
  AbstractLoginRobot loginRobot() => LoginRobot($);
}
