import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/group_information_robot.dart';
import '../robots/link_preview_robot.dart';

/// The app previews https links only, and the CI homeserver must reach it.
const _previewTarget = 'https://example.com/';

/// In the homeserver's url_preview_ip_range_blacklist, so the preview fails.
const _blockedPreviewTarget = 'https://127.0.0.1/';

class LinkPreviewScenario extends BaseTestScenario {
  LinkPreviewScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final group = (await prepareMobileGroupFixture(this)).title;
    final runId = DateTime.now().microsecondsSinceEpoch;
    final url = '$_previewTarget?e2e=$runId';
    final blockedUrl = '$_blockedPreviewTarget?e2e=$runId';
    final expectedTitle = await _fetchServerPreviewTitle(url);
    expect(
      expectedTitle,
      isNotEmpty,
      reason: 'The homeserver must return an og:title for $url',
    );

    await robots.chatListRobot().openSearchScreen();
    final isRoomOpened = await robots.searchViewRobot().searchAndOpenRoom(
      group,
    );
    if (!isRoomOpened) {
      throw Exception('Test failed: Room "$group" was not found.');
    }

    await robots.chatGroupDetailRobot().sendMessage(url);
    final linkPreview = LinkPreviewRobot($);
    await $.waitUntilVisible(
      linkPreview.timelinePreview(url),
      timeout: const Duration(seconds: 30),
    );
    expect(linkPreview.timelinePreviewTitle(url), expectedTitle);

    await robots.chatGroupDetailRobot().sendMessage(blockedUrl);
    await linkPreview.waitUntilTimelinePreviewSettled(blockedUrl);
    expect(linkPreview.timelinePreview(blockedUrl).exists, isFalse);

    await robots.chatGroupDetailRobot().tapOnChatBarTitle();
    await GroupInformationRobot($).getLinksTab().tap();
    await $.waitUntilVisible(
      linkPreview.linksTabItemTitle(url, expectedTitle!),
      timeout: const Duration(seconds: 30),
    );
  }

  Future<String?> _fetchServerPreviewTitle(String url) async {
    final context = $.tester.element(find.byType(Scaffold).first);
    final client = twake.Matrix.of(context).client;
    final preview = await client.getUrlPreviewAuthed(Uri.parse(url));
    return preview.additionalProperties['og:title'] as String?;
  }
}
