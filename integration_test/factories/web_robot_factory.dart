import 'package:patrol/patrol.dart';

import '../robots/abstract/abstract_login_robot.dart';
import '../robots/login_robot.dart';
import 'robot_factory.dart';

/// Web implementation of [RobotFactory].
///
/// Today it reuses the existing robots directly — the `kIsWeb` branches
/// inside `LoginRobot.loginViaApi` already drive the Matrix SDK
/// `m.login.password` path against the local Synapse. Subsequent PRs
/// will introduce dedicated `WebXRobot` classes wherever the UI surface
/// genuinely diverges; this factory is the one place those swaps get
/// wired.
class WebRobotFactory implements RobotFactory {
  const WebRobotFactory(this.$);

  @override
  final PatrolIntegrationTester $;

  @override
  AbstractLoginRobot loginRobot() => LoginRobot($);
}
