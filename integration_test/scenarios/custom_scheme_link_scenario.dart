import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/home_robot.dart';
import 'chat_scenario.dart';

/// Mobile-only: tapping a link with a custom scheme hands it to the OS as-is.
/// No app handles `visio://` on the test devices, so the app reports that it
/// cannot open the URI. Before the fix, `visio://…` opened `https://visio` in
/// the in-app browser instead. Web is not covered: the browser does not report
/// whether a custom scheme was handled, so there is nothing to assert.
class CustomSchemeLinkScenario extends BaseTestScenario {
  CustomSchemeLinkScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final chatScenario = ChatScenario($);
    final suffix = DateTime.now().millisecondsSinceEpoch;

    await HomeRobot($).gotoChatListScreen();
    final fixture = await prepareMobileGroupFixture(this);
    final chat = await chatScenario.openChatGroup(fixture.title);

    // Markdown links are sent as HTML anchors, like the message of the issue.
    // A single message keeps the test within the global timeout, as typing is
    // slow.
    final anchorLabel = 'Join visio $suffix';
    const anchorUri = 'visio://toto';
    final plainUri = 'visio://meet.example.com/room-$suffix';

    await chatScenario.sendAMesage('[$anchorLabel]($anchorUri) $plainUri');
    await chatScenario.verifyMessageIsShown(anchorLabel, true);

    for (final (tappedText, uri) in [
      (anchorLabel, anchorUri),
      (plainUri, plainUri),
    ]) {
      await chat.tapTextInMessage(tappedText);

      final cantOpen = $(SnackBar).containing(find.textContaining(uri));
      await $.waitUntilVisible(cantOpen);
      expect(
        cantOpen.exists,
        isTrue,
        reason: 'Tapping $uri should report it cannot be opened',
      );

      // The snackbar covers the bottom of the timeline, where the next link is.
      await cantOpen.$(Icons.close).tap();
      await chatScenario.waitUntilAbsent($, cantOpen);
    }
  }
}
