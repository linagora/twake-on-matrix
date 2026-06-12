import '../../base/test_base.dart';
import '../../scenarios/forward_message_scenario.dart';

void main() {
  // After single forward: ForwardController pops itself then routes to the
  // receiver's ChatView.
  TestBase().runPatrolTest(
    tags: ['forward_message_test01'],
    description: 'Forward a message to a single recipient',
    scenarioBuilder: ($, robots) => ForwardSingleRecipientScenario($, robots),
  );

  // After multi forward: ForwardController pops back to the source ChatView and
  // shows a success snackbar.
  TestBase().runPatrolTest(
    tags: ['forward_message_test02'],
    description: 'Forward a message to multiple recipients',
    scenarioBuilder: ($, robots) => ForwardMultiRecipientScenario($, robots),
  );
}
