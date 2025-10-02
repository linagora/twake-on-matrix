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

enum UserLevel { member, admin, owner, moderator }
class ChatDetailScenario extends BaseScenario {
  ChatDetailScenario(super.$);

  Future<void> makeASearch(String searchText) async {
    await ChatGroupDetailRobot($).getSearchIcon().tap();
    await $.waitUntilVisible($(AppBar).$(TextField));
    await $(AppBar).$(TextField).enterText(searchText);
    // await SearchRobot($).enterSearchText(searchText);
    await ChatGroupDetailRobot($).waitForEitherVisible($: $, first: $(TwakeListItem), second: $("No Results"), timeout: const Duration(seconds: 10));
    await Future.delayed(const Duration(seconds: 2));
  }

  UserLevel parseUserLevel(String? s) {
    final v = (s ?? '').trim().toLowerCase();
    final head = v.split(RegExp(r'\s+|\(')).first;

    return UserLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == head,
      orElse: () => UserLevel.member,
    );
  }
  
  // Future<void> verifyProfileInfoOfAMember(TwakeListItemRobot twakeListItemRow, {bool isCurrentUser = true}) async {
  //   final row = twakeListItemRow.root;
  //   await row.tap();
  //   final owner = row.$(Text).at(1).text;
  //   final matrixAddress = row.$(Text).at(2).text ?? "";
  //   await $.waitUntilVisible($(ProfileInfoView));
  //   await verifyProfileInfo(matrixAddress, isCurrentUser: isCurrentUser, level: parseUserLevel(owner));
  //   await ProfileInformationRobot($).backToGroupInfomationScreen();
  // }
  
  Future<void> verifyProfileInfoOfAllMember(SoftAssertHelper s) async {
    final List<TwakeListItemRobot> items = await GroupInformationRobot($).getListOfMembers();

    for (final item in items) {
      final row = item.root;
      final owner = row.$(Text).at(1).text;
      final matrixAddress = row.$(Text).at(2).text ?? "";
      const currentAccount  = String.fromEnvironment('CurrentAccount');
      if(matrixAddress == currentAccount)
      {
        await verifyProfileInfoOfAMember(s, matrixAddress, isCurrentUser: true, level: parseUserLevel(owner));
      }
      else
      {
        await verifyProfileInfoOfAMember(s, matrixAddress, isCurrentUser: false, level: parseUserLevel(owner));
      }
    }
  }

  Future<void> verifyProfileInfoOfAMember(SoftAssertHelper s, String matrixAdress, {bool isCurrentUser = true,
    UserLevel level = UserLevel.member,}) async {
    final memberRow = GroupInformationRobot($).getMember(matrixAdress);
    await memberRow.tap();
    await $.waitUntilVisible($(ProfileInfoView));
    await verifyProfileInfo(s, matrixAdress, isCurrentUser: isCurrentUser, level: level);
    await ProfileInformationRobot($).backToGroupInfomationScreen();
  }

  Future<void> verifyProfileInfo(SoftAssertHelper s, String matrixAdress, {bool isCurrentUser = true,
    UserLevel level = UserLevel.member,}) async {
    
    s.softAssertEquals(ProfileInformationRobot($).getAvatar().exists, true, "Avatar is not shown");
    final actualDisplayName = matrixAdress.substring(matrixAdress.indexOf("@")+1, matrixAdress.indexOf(":"));
    s.softAssertEquals(ProfileInformationRobot($).getDisplayName().text == actualDisplayName
    , true, "displayName is not correct, actualDisplayName is $actualDisplayName",);
    s.softAssertEquals(ProfileInformationRobot($).getOnlineStatus().exists, true, "online status is not shown");
    s.softAssertEquals(ProfileInformationRobot($).getMatrixAddress().text == matrixAdress, true, "Matrix address is not correct",);

    const currentAccount  = String.fromEnvironment('CurrentAccount');
    if(matrixAdress != currentAccount)
    {
      s.softAssertEquals(ProfileInformationRobot($).getSentMessageBtn().exists, true, "Sent message button is not shown");
    }

    if((matrixAdress != currentAccount) & ((level == UserLevel.owner) || (level == UserLevel.admin)))
    {
      s.softAssertEquals(ProfileInformationRobot($).getRemoveFromBtn().exists, true, "Remove account button is not shown");
      s.softAssertEquals(ProfileInformationRobot($).getTransferOwnerShipBtn().exists, true, "TransferOwnerShip is not shown");
    }
  }

}
