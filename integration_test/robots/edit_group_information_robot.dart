import 'package:fluffychat/pages/chat_details/chat_details_edit_option.dart';
import 'package:fluffychat/pages/chat_details/removed/removed_view.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class EditGroupInformationRobot extends CoreRobot {
  EditGroupInformationRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(AppBar).$(TwakeIconButton);
  }

  PatrolFinder getTitle() {
    return $(AppBar).$(Text);
  }

  PatrolFinder getRemoveUserOption() {
    return $(ChatDetailsEditOption).containing($("Removed Users"));
  }  

  Future<void> openBannedUserList() async{
    await getRemoveUserOption().tap();
    await $.waitUntilVisible($(RemovedView));
  }
}
