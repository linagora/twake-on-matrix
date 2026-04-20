import 'package:patrol/patrol.dart';

import 'mobile_robot_factory.dart';
import 'robot_factory.dart';

/// Default provider on platforms that expose `dart:io`.
///
/// The public `robot_factory_provider.dart` conditionally exports this
/// file so that importers call `createRobotFactory($)` without having to
/// know which platform they are compiled for.
RobotFactory createRobotFactory(PatrolIntegrationTester $) =>
    MobileRobotFactory($);
