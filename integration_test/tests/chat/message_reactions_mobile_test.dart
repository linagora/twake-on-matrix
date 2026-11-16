import '../../base/test_base.dart';
import '../../scenarios/message_reactions_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    tags: ['message_reactions_mobile_test01'],
    description: 'React from the quick reaction row, then remove it',
    scenarioBuilder: ($, robots) => QuickReactionScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['message_reactions_mobile_test02'],
    description: 'React from the full emoji picker and find it in Recent',
    scenarioBuilder: ($, robots) => PickerReactionScenario($, robots),
  );
}
