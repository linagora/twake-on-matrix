import 'package:fluffychat/pages/chat/events/images_builder/sending_image_info_widget.dart';
import 'package:fluffychat/pages/chat/seen_by_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../base/base_test_scenario.dart';
import '../robots/home_robot.dart';
import 'chat_scenario.dart';

/// Mobile-only: send an image while offline, then retry once connectivity is
/// restored. Toggling Wi-Fi / cellular goes through `$.native.*`, which the web
/// target cannot reach — the test is registered with `mobileOnly: true` and
/// skipped on web. It drives the UI through the concrete mobile robots since it
/// never runs cross-platform.
class ChatImageRetryScenario extends BaseTestScenario {
  ChatImageRetryScenario(super.$, super.robots);

  static const _searchPhrase = String.fromEnvironment(
    'SearchByTitle',
    defaultValue: 'My Default Group',
  );

  @override
  Future<void> runTestLogic() async {
    final chatScenario = ChatScenario($);

    // 1. Navigate to a chat room.
    await HomeRobot($).gotoChatListScreen();
    await chatScenario.openChatGroup(_searchPhrase);

    // 2. Turn off internet.
    await $.native.disableWifi();
    await $.native.disableCellular();
    await $.pumpAndTrySettle();

    // 3. Send an image.
    await chatScenario.sendImage();

    // 4. Verify the upload failed and the retry button is shown.
    final retryBtn = $(
      SendingImageInfoWidget,
    ).$(IconButton).containing(find.byIcon(Icons.refresh));
    await $.waitUntilVisible(retryBtn, timeout: const Duration(seconds: 30));
    expect(
      retryBtn.exists,
      isTrue,
      reason: 'Retry button should be visible after failed upload',
    );

    // 5. Turn internet back on.
    await $.native.enableWifi();
    await $.native.enableCellular();
    await $.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 5));

    // 6. Hit retry.
    await chatScenario.retryImageUpload();

    // 7. Success: the retry button disappears and the send-status icon appears.
    await chatScenario.waitUntilAbsent(
      $,
      retryBtn,
      timeout: const Duration(seconds: 60),
    );
    final seenIcon = $(SeenByRow).$(Icon);
    await $.waitUntilVisible(seenIcon, timeout: const Duration(seconds: 30));
    expect(
      seenIcon.exists,
      isTrue,
      reason: 'Image should be successfully sent and show status icon',
    );
  }
}
