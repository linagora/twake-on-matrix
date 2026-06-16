import '../../base/test_base.dart';
import '../../scenarios/chat_image_retry_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'User sends an image without internet, then retries after internet is restored',
    // Mobile-only: toggles Wi-Fi / cellular via `$.native.*`, unavailable on web.
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ChatImageRetryScenario($, robots),
  );
}
