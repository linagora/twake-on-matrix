import '../../base/test_base.dart';
import '../../scenarios/manage_folder_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'make a folder and filter the room list by it',
    scenarioBuilder: ($, robots) => ManageFolderScenario($, robots),
  );
}
