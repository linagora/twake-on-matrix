import 'package:fluffychat/pages/profile_info/profile_info_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import '../base/base_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/chat_group_detail_robot.dart';
import 'package:flutter/material.dart';

import '../robots/group_information_robot.dart';
import '../robots/profile_information_robot.dart';
import '../robots/twake_list_item_robot.dart';

class ChatDetailScenario extends BaseScenario {
  ChatDetailScenario(super.$);
  String get _currentAccount => const String.fromEnvironment('CurrentAccount');

  Future<void> makeASearch(String searchText) async {
    await ChatGroupDetailRobot($).getSearchIcon().tap();
    await $.waitUntilVisible($(AppBar).$(TextField));
    await $(AppBar).$(TextField).enterText(searchText);
    await ChatGroupDetailRobot($).waitForEitherVisible(
      $: $,
      first: $(TwakeListItem),
      second: $("No Results"),
      timeout: const Duration(seconds: 10),
    );
    await Future.delayed(const Duration(seconds: 2));
  }

  UserLevel parseUserLevel(String? userlevel) {
    final noSpaces = (userlevel ?? '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ''); // remove all space
    final level = noSpaces.toLowerCase();
    try {
      return UserLevel.values.byName(level);
    } catch (_) {
      return UserLevel.member; // default fallback
    }
  }

  Future<void> verifyProfileInfoOfAllMember(SoftAssertHelper s) async {
    final List<TwakeListItemRobot> items =
        await GroupInformationRobot($).getListOfMembers();

    for (final item in items) {
      final row = item.root;
      final owner = row.$(Text).at(1).text;
      final displayName = row.$(Text).first.text ?? "";
      final matrixAddress = row.$(Text).last.text ?? "";
      await verifyProfileInfoOfAMember(
        s,
        displayName,
        matrixAddress,
        isCurrentUser: matrixAddress == _currentAccount,
        level: parseUserLevel(owner),
      );
      await ProfileInformationRobot($).backToGroupInformationScreen();
      await $.waitUntilVisible(item.root);
      await $.tester.pumpAndSettle();
      //pumAndSettle seems not enough to avoid get value of owner incorrectly
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> verifyProfileInfoOfAMember(
    SoftAssertHelper s,
    String displayName,
    String matrixAddress, {
    bool isCurrentUser = true,
    UserLevel level = UserLevel.member,
  }) async {
    final memberRow = GroupInformationRobot($).getMember(matrixAddress);
    await memberRow.tap();
    await $.waitUntilVisible($(ProfileInfoView));
    await verifyProfileInfo(
      s,
      displayName,
      matrixAddress,
      isCurrentUser: isCurrentUser,
      level: level,
    );
  }

  Future<void> verifyProfileInfo(
    SoftAssertHelper s,
    String displayName,
    String matrixAddress, {
    bool isCurrentUser = true,
    UserLevel level = UserLevel.member,
  }) async {
    s.softAssertEquals(
      ProfileInformationRobot($).getAvatar().exists,
      true,
      "Avatar is not shown",
    );

    final actualName = ProfileInformationRobot($).getDisplayName().text;
    s.softAssertEquals(
      actualName == displayName,
      true,
      "displayName is not correct, expected name is $displayName while actual name is $actualName",
    );

    try {
      s.softAssertEquals(
        ProfileInformationRobot($).getOnlineStatus().exists,
        true,
        "online status is not shown",
      );
    } catch (_) {
      // Ignore: Online status element may not exist for some users
    }
    s.softAssertEquals(
      ProfileInformationRobot($).getMatrixAddress().text == matrixAddress,
      true,
      "Matrix address is not correct",
    );

    if (matrixAddress != _currentAccount) {
      s.softAssertEquals(
        ProfileInformationRobot($).getSentMessageBtn().exists,
        true,
        "Sent message button is not shown",
      );
    }

    if ((matrixAddress != _currentAccount) &&
        ((level == UserLevel.owner) || (level == UserLevel.admin))) {
      s.softAssertEquals(
        ProfileInformationRobot($).getRemoveFromBtn().exists,
        true,
        "Remove account button is not shown",
      );
      s.softAssertEquals(
        ProfileInformationRobot($).getTransferOwnerShipBtn().exists,
        true,
        "TransferOwnerShip is not shown",
      );
    }
  }
}
