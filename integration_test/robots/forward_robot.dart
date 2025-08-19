import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../base/core_robot.dart';
import 'menu_robot.dart';
import 'twake_list_item_robot.dart';

class ForwardRobot extends CoreRobot {
  ForwardRobot(super.$);

  Future<PatrolFinder> getBackIcon() async {
    return $(AppBar).$(TwakeIconButton).$(Icon);
  }
  
  Future<List<TwakeListItemRobot>> getListOfRecentContacts() async {
    final List<TwakeListItemRobot> contactList = [];

    // Evaluate once to find how many TwakeInkWell widgets exist
    final matches = $(Material).evaluate();

    for (int i = 0; i < matches.length; i++) {
      final item = $(Material).at(i);
      contactList.add(TwakeListItemRobot($,item));
    }
    return contactList;
  }
}
