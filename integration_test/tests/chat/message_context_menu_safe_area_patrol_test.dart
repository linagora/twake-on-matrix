import '../../base/test_base.dart';
import '../../scenarios/message_context_menu_safe_area_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Message context menu has SafeArea and can scroll',
    // Mobile-only: the long-press `PullDownMenu` dialog only exists on mobile
    // (web uses a hover action bar), so its SafeArea internals can't be tested
    // on web.
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        MessageContextMenuSafeAreaScenario($, robots),
  );
}
