import '../../base/test_base.dart';
import '../../scenarios/login_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Should see chat list after successful login',
    test: ($) async {
      final loginScenario = LoginScenario(
        $,
        username: const String.fromEnvironment('USERNAME'),
        serverUrl: const String.fromEnvironment('SERVER_URL'),
        password: const String.fromEnvironment('PASSWORD'),
      );

      await loginScenario.execute();
    },
  );
}
