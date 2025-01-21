import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:flutter_test/flutter_test.dart';

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

}
