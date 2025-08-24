import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'twake_list_item_robot.dart';

class NewChatRobot extends CoreRobot {
  NewChatRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(TwakeIconButton).containing(find.byTooltip('Back'));
  }

  PatrolFinder getSearchIcon() {
    return $(TwakeIconButton).containing(find.byTooltip('Search'));
  }

  PatrolFinder getSearchField() {
    return $(TextField).first;
  }

  PatrolFinder getNewGroupChatIcon() {
    return $(InkWell).containing(find.text('New Group Chat'));
  }

  Future<void> makeASearch(String searchKey) async {
    await getSearchIcon().tap();
    await getSearchField().enterText(searchKey);
    await waitForEitherVisible($: $, first: $(TwakeListItem), second: $("No Results"), timeout: const Duration(seconds: 10));
  }

  Future<void> clickOnNewGroupChatIcon() async{
    await getNewGroupChatIcon().tap();
    await $.waitUntilVisible($(AppBar).$("Add members"));
  }

  List<TwakeListItemRobot> getListOfAccount() {   
    final List<TwakeListItemRobot> groupList = [];

    final matches = $(TwakeListItem).evaluate();
    for (final element in matches) {
      final finder = $(element.widget.runtimeType);
      groupList.add(TwakeListItemRobot($, finder));
    }
    return groupList;
  }
}
