import '../../base/test_base.dart';
import '../../scenarios/language_setting_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'verify action on App Language screen',
    scenarioBuilder: ($, robots) => LanguageSettingScenario($, robots),
  );
}
