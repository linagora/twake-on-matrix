import 'package:fluffychat/pages/chat/chat_input_row.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/images_picker/image_item_widget.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../base/core_robot.dart';

class SendTextMessageRobot extends CoreRobot {
  SendTextMessageRobot(super.$);

  Future<void> enterTextMessage(String message) async {
    try {
      await $.enterText($(InputBar), message);
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> tapOnSendButton() async {
    try {
      await $.tap($(ChatInputRowSendBtn));
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> tapOnAddAttachmentButton() async {
    try {
      await $.tap($(ChatInputRow).$(TwakeIconButton));
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> selectImage() async {
    try {
      await $.tap($(ImagePickerItemWidget));
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> sendImage() async {
    try {
      await $.tap($((SvgPicture)));
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> dismissMediaPopUp() async {
    try {
      await $.tap($('Next'));
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> grantPhotosAndVideosPermission(
    NativeAutomator nativeAutomator,
  ) async {
    if (await nativeAutomator.isPermissionDialogVisible(
      timeout: const Duration(seconds: 15),
    )) {
      await nativeAutomator.grantPermissionWhenInUse();
    }
  }
  
}
