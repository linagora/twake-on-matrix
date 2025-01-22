import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat/events/images_builder/image_bubble.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/images_picker/images_picker_grid.dart';
import '../base/base_scenario.dart';
import '../robots/send_text_message_robot.dart';
import 'login_scenario.dart';

class SendImageScenario extends BaseScenario {
  LoginScenario loginScenario;
  SendImageScenario(
    super.$, {
    required this.loginScenario,
  });

  @override
  Future<void> execute() async {
    final SendTextMessageRobot sendMessageRobot = SendTextMessageRobot($);
    await loginScenario.execute();
    await $.tap($(ChatListItem));
    await $.waitUntilVisible($(ChatView));
    await sendMessageRobot.tapOnAddAttachmentButton();
    await sendMessageRobot.dismissMediaPopUp();
    await sendMessageRobot.grantPhotosAndVideosPermission($.nativeAutomator);
    await $.waitUntilVisible($(ImagesPickerGrid));
    await sendMessageRobot.selectImage();
    await sendMessageRobot.sendImage();
    expect(ImageBubble, findsAtLeast(1));
  }
}
