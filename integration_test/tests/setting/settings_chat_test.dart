import '../../base/test_base.dart';
import '../../scenarios/settings_chat_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Toggle a chat setting and verify it persists after reopening Settings > Chat',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => SettingsChatToggleScenario($, robots),
  );
}
