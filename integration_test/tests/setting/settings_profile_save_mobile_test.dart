import '../../base/test_base.dart';
import '../../scenarios/settings_profile_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Edit the display name in profile settings, save it, see it after '
        'reopening the screen, then restore it',
    scenarioBuilder: ($, robots) =>
        SettingsProfileSaveDisplayNameScenario($, robots),
  );

  // Clears the avatar for good: the fixture account starts without one.
  TestBase().runPatrolTest(
    description: 'Remove the avatar from profile settings',
    requiresDisposableServer: true,
    scenarioBuilder: ($, robots) =>
        SettingsProfileRemoveAvatarScenario($, robots),
  );
}
