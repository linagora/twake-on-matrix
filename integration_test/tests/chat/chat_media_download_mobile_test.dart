import '../../base/test_base.dart';
import '../../scenarios/chat_media_download_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Receiver opens a received image in the image viewer',
    scenarioBuilder: ($, robots) => ReceiverOpensImageScenario($, robots),
  );
  TestBase().runPatrolTest(
    description: 'Receiver downloads a received video, then plays it',
    scenarioBuilder: ($, robots) =>
        ReceiverDownloadsAndPlaysVideoScenario($, robots),
  );
  TestBase().runPatrolTest(
    description: 'Receiver downloads a received PDF, then opens it',
    scenarioBuilder: ($, robots) =>
        ReceiverDownloadsAndOpensPdfScenario($, robots),
  );
  TestBase().runPatrolTest(
    description: 'Receiver downloads several received PDFs at the same time',
    scenarioBuilder: ($, robots) =>
        ReceiverDownloadsSeveralPdfsScenario($, robots),
  );
}
