import 'package:fluffychat/pages/chat_search/chat_search_view.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'twake_list_item_robot.dart';

class ChatSearchViewRobot extends CoreRobot {
  ChatSearchViewRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(ChatSearchView).$(TwakeIconButton).containing(find.byTooltip('Back'));
  }

  PatrolFinder getTextField() {
    return $(ChatSearchView).$(AppBar).$(TextField);
  }

  PatrolFinder getSearchIcon() {
    return getTextField().$(Icon).at(0);
  }

  PatrolFinder getCloseIcon() {
    return getTextField().$(IconButton);
  }

  Future<List<TwakeListItemRobot>> getListOfChatSeach() async {
    final List<TwakeListItemRobot> groupList = [];

    // Evaluate once to find how many TwakeListItem widgets exist
    final matches = $(TwakeListItem).evaluate();
    for (final element in matches) {
      final finder = $(element.widget.runtimeType);
      groupList.add(TwakeListItemRobot($, finder));
    }
    return groupList;
  }
  
}
