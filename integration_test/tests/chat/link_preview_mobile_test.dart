import '../../base/test_base.dart';
import '../../scenarios/link_preview_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    tags: ['link_preview_mobile_test01'],
    description:
        'A sent https link shows the homeserver preview title in the chat '
        'and in the Links tab, and a refused preview renders nothing',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => LinkPreviewScenario($, robots),
  );
}
