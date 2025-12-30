import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_members_page.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item/participant_list_item.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_header.dart';
import 'package:fluffychat/pages/profile_info/profile_info_view.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import '../base/base_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/chat_group_detail_robot.dart';
import 'package:flutter/material.dart';
import '../robots/group_information_robot.dart';
import '../robots/profile_information_robot.dart';

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
    await $(ParticipantListItem).waitUntilVisible();

    final participantListItems = $.tester
        .widgetList<ParticipantListItem>(
          find.byType(ParticipantListItem),
        )
        .toList();

    for (final item in participantListItems) {
      final displayName = item.member.displayName ?? "";
      final matrixAddress = item.member.id;
      await verifyProfileInfoOfAMember(
        s,
        displayName,
        matrixAddress,
        isCurrentUser: matrixAddress == _currentAccount,
        level: item.member.getDefaultPowerLevelMember,
      );
      await ProfileInformationRobot($).backToGroupInformationScreen();
      await $.waitUntilVisible($(ChatDetailsMembersPage));
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
    required DefaultPowerLevelMember level,
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
    required DefaultPowerLevelMember level,
  }) async {
    s.softAssertEquals(
      ProfileInformationRobot($).getAvatar().exists,
      true,
      "Avatar is not shown",
    );

    s.softAssertEquals(
      $(ProfileInfoHeader).$(displayName).exists,
      true,
      "displayName is not $displayName",
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
        ((level == DefaultPowerLevelMember.owner) ||
            (level == DefaultPowerLevelMember.admin))) {
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
