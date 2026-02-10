import 'dart:io';

import 'package:fluffychat/pages/new_group/new_group_chat_info_view.dart';
import 'package:fluffychat/pages/new_group/widget/contact_item.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'twake_list_item_robot.dart';

class AddMemberRobot extends CoreRobot {
  AddMemberRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(TwakeIconButton).containing(find.byTooltip('Back'));
  }

  PatrolFinder getSearchIcon() {
    return $(TwakeIconButton).containing(find.byTooltip('Search'));
  }

  PatrolFinder getNewGroupChatIcon() {
    return $(InkWell).containing(find.text('New Group Chat'));
  }

  PatrolFinder getSearchField() {
    return $(TextField).first;
  }

  PatrolFinder getNextIcon() {
    return $(TwakeFloatingActionButton).last;
  }

  PatrolFinder getAgreeInviteMemberBtn() {
    if (Platform.isAndroid) {
      return $(AlertDialog).$(TextButton).containing(find.text('YES'));
    } else {
      return $(
        CupertinoAlertDialog,
      ).$(CupertinoDialogAction).containing(find.text('Yes'));
    }
  }

  PatrolFinder getCancelnviteMemberBtn() {
    if (Platform.isAndroid) {
      return $(AlertDialog).$(TextButton).containing(find.text('CANCEL'));
    } else {
      return $(
        CupertinoAlertDialog,
      ).$(CupertinoDialogAction).containing(find.text('Cancel'));
    }
  }

  Future<void> makeASearch(String searchKey) async {
    await getSearchIcon().tap();
    await typeSlowlyWithPatrol($, getSearchField(), searchKey);
    await waitForEitherVisible(
      $: $,
      first: $(ContactItem),
      second: $("No Results"),
      timeout: const Duration(seconds: 10),
    );
  }

  Future<void> clickOnNextIcon() async {
    await getNextIcon().tap();
    await $.waitUntilVisible($(NewGroupChatInfoView));
  }

  Future<void> selectAllFilteredAccounts() async {
    final accounts = getListOfChatGroup();
    for (final account in accounts) {
      await account.getCheckBox().tap();
    }
  }

  List<TwakeListItemRobot> getListOfChatGroup() {
    final List<TwakeListItemRobot> groupList = [];

    final matches = $(ContactItem).evaluate();
    for (final element in matches) {
      final finder = $(element.widget.runtimeType);
      groupList.add(TwakeListItemRobot($, finder));
    }
    return groupList;
  }
}
