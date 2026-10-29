import '../../base/test_base.dart';
import '../../scenarios/settings_profile_scenario.dart';

// CAPS_DISABLED_* come from scripts/ci/capabilities-disabled-synapse.sh.
void main() {
  TestBase().runPatrolTest(
    description:
        'Profile settings hide the edit controls when the server disables '
        'display name and avatar changes',
    mobileOnly: true,
    login: const (
      serverUrl: String.fromEnvironment('CAPS_DISABLED_SERVER_URL'),
      username: String.fromEnvironment('CAPS_DISABLED_USERNAME'),
      password: String.fromEnvironment('CAPS_DISABLED_PASSWORD'),
    ),
    scenarioBuilder: ($, robots) =>
        SettingsProfileEditsDisabledScenario($, robots),
  );
}
