import '../../base/test_base.dart';
import '../../scenarios/forward_sticker_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    tags: ['forward_sticker_web_test01'],
    description: 'Forward a received sticker as an image',
    webOnly: true,
    scenarioBuilder: ($, robots) => ForwardStickerWebScenario($, robots),
  );
}
