import 'package:fluffychat/pages/chat_details/chat_details_view.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_contact_rows.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_header.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class ProfileInformationRobot extends CoreRobot {
  ProfileInformationRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(AppBar).$(TwakeIconButton);
  }

  PatrolFinder getTitle() {
    return $(AppBar).$(Text);
  }

  PatrolFinder getAvatar() {
    return $(ProfileInfoHeader).$(Avatar);
  }

  PatrolFinder getDisplayName() {
    return $(ProfileInfoHeader).$(Text).at(0);
  }

  PatrolFinder getOnlineStatus() {
    return $(ProfileInfoHeader).$(Text).at(1);
  }

  PatrolFinder getMatrixAddress() {
    return $(ProfileInfoContactRows).$(Text).at(1);
  }

  PatrolFinder getMatrixAddressCopyIcon() {
    const copyAddressData = IconData(0xE190, fontFamily: 'MaterialIcons');
    return $(ProfileInfoContactRows).$(Icon).containing(find.byIcon(copyAddressData));
  }

  PatrolFinder getSentMessageBtn() {
    const sentMsgData = IconData(0xE154, fontFamily: 'MaterialIcons');
    return $(InkWell).containing(find.byIcon(sentMsgData));
  }

  PatrolFinder getRemoveFromBtn() {
    const removeAccountData = IconData(0xEFA9, fontFamily: 'MaterialIcons');
    return $(InkWell).containing(find.byIcon(removeAccountData));
  }

  PatrolFinder getTransferOwnerShipBtn() {
    return $(InkWell).containing($("Transfer ownership"));
  }

  Future<void> backToGroupInfomationScreen() async{
    await getBackIcon().tap();
    await $.waitUntilVisible($(ChatDetailsView));
  }

}