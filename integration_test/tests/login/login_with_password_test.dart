import '../../base/test_base.dart';
import '../../scenarios/login_with_password_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'User can successfully login with valid credentials',
    scenarioBuilder: ($, robots) => LoginWithPasswordScenario($, robots),
  );
}
