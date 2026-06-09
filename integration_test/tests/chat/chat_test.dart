import '../../base/test_base.dart';
import '../../scenarios/chat_dm_creation_scenarios.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'create a new message with a user who has been chatted with before',
    scenarioBuilder: ($, robots) => CreateDmWithExistingUserScenario($, robots),
  );

  TestBase().runPatrolTest(
    description:
        "Create a new message with a user who hasn't been chatted with before",
    scenarioBuilder: ($, robots) => CreateDmWithNewUserScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'create a new message with the non-existing account',
    scenarioBuilder: ($, robots) =>
        CreateDmWithNonExistingUserScenario($, robots),
  );
}
