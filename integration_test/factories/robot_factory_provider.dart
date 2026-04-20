/// Public entry point for resolving a [RobotFactory] at compile time.
///
/// Scenarios and `TestBase` import this file and call
/// `createRobotFactory($)` without caring about the platform. The Dart
/// conditional export below picks the mobile provider by default and
/// swaps in the web provider on targets that expose `dart.library.js_interop`
/// — i.e. Flutter Web.
///
/// This is the only platform-branching point in the test tree. Everything
/// else depends on the abstract interfaces exposed by [RobotFactory].
library;

export 'mobile_robot_factory_provider.dart'
    if (dart.library.js_interop) 'web_robot_factory_provider.dart';
