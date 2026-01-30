import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/pages/chat/events/images_builder/sending_image_info_widget.dart';
import 'package:fluffychat/pages/chat/seen_by_row.dart';
import '../../base/test_base.dart';
import '../../robots/home_robot.dart';
import '../../scenarios/chat_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'User sends an image without internet, then retries after internet is restored',
    test: ($) async {
      final chatScenario = ChatScenario($);

      // 1. Navigate to a chat room
      const searchPhrase = String.fromEnvironment(
        'SearchByTitle',
        defaultValue: 'My Default Group',
      );
      await HomeRobot($).gotoChatListScreen();
      await chatScenario.openChatGroup(searchPhrase);

      // 2. Turn off internet
      await $.native.disableWifi();
      await $.native.disableCellular();
      await $.pumpAndTrySettle();

      // 3. Send an image
      await chatScenario.sendImage();

      // 4. Verify that the upload failed and the retry button is shown
      final retryBtn = $(SendingImageInfoWidget)
          .$(IconButton)
          .containing(find.byIcon(Icons.refresh));
      await $.waitUntilVisible(retryBtn, timeout: const Duration(seconds: 30));
      expect(
        retryBtn.exists,
        isTrue,
        reason: 'Retry button should be visible after failed upload',
      );

      // 5. Turn on internet
      await $.native.enableWifi();
      await $.native.enableCellular();
      await $.pumpAndSettle();

      // Wait a bit for network to actually be restored and detected by the app if needed
      await Future.delayed(const Duration(seconds: 5));

      // 6. Hit retry button
      await chatScenario.retryImageUpload();

      // 7. Expect the message is retried successfully
      // Success is indicated by the retry button disappearing and the send status icon appearing
      await chatScenario.waitUntilAbsent(
        $,
        retryBtn,
        timeout: const Duration(seconds: 60),
      );

      // Additional verification: check for the seen by row / send status icon
      final seenIcon = $(SeenByRow).$(Icon);
      await $.waitUntilVisible(seenIcon, timeout: const Duration(seconds: 30));
      expect(
        seenIcon.exists,
        isTrue,
        reason: 'Image should be successfully sent and show status icon',
      );
    },
  );
}
