import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:flutter/widgets.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:patrol/patrol.dart';

import '../base/core_robot.dart';

class ChatGroupDetailRobot extends CoreRobot {
  ChatGroupDetailRobot(super.$);

  Future<bool> isVisible() async {
    final chatListSelector = $(ChatEventList);
    try {
      await chatListSelector.waitUntilVisible(timeout: const Duration(seconds: 120));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PatrolFinder> getText(String text) async {
    return $(MatrixLinkifyText).containing(text);
  }
}
