import 'package:patrol/patrol.dart';

import 'robot_factory.dart';
import 'web_robot_factory.dart';

/// Provider swapped in on the Flutter Web target via conditional export
/// (`robot_factory_provider.dart`).
RobotFactory createRobotFactory(PatrolIntegrationTester $) =>
    WebRobotFactory($);
