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
  static const _copyAddressIcon = IconData(0xE190, fontFamily: 'MaterialIcons');
  static const _sentMsgIcon = IconData(0xE154, fontFamily: 'MaterialIcons');
  static const _removeAccountIcon =
      IconData(0xEFA9, fontFamily: 'MaterialIcons');

  PatrolFinder getBackIcon() {
    return $(AppBar).$(TwakeIconButton);
  }

  PatrolFinder getTitle() {
    return $(AppBar).$(Text);
  }

  PatrolFinder getAvatar() {
    return $(ProfileInfoHeader).$(Avatar);
  }

  PatrolFinder getOnlineStatus() {
    return $(ProfileInfoHeader).$(Text).at(1);
  }

  PatrolFinder getMatrixAddress() {
    return $(ProfileInfoContactRows).$(Text).at(1);
  }

  PatrolFinder getMatrixAddressCopyIcon() {
    return $(ProfileInfoContactRows)
        .$(Icon)
        .containing(find.byIcon(_copyAddressIcon));
  }

  PatrolFinder getSentMessageBtn() {
    return $(InkWell).containing(find.byIcon(_sentMsgIcon));
  }

  PatrolFinder getRemoveFromBtn() {
    return $(InkWell).containing(find.byIcon(_removeAccountIcon));
  }

  PatrolFinder getTransferOwnerShipBtn() {
    return $(InkWell).containing($("Transfer ownership"));
  }

  Future<void> backToGroupInformationScreen() async {
    await getBackIcon().tap();
    await $.waitUntilVisible($(ChatDetailsView));
  }
}
