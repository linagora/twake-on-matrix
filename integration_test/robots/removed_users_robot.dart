import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class RemovedUsersRobot extends CoreRobot {
  RemovedUsersRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(AppBar).$(TwakeIconButton);
  }

  PatrolFinder getTitle() {
    return $(AppBar).$(Text);
  }

  PatrolFinder getBanedUser(String matrixAddress) {
    return $(TwakeListItem).containing($(matrixAddress));
  }

  PatrolFinder getUnBanIconUser(String matrixAddress) {
    return getBanedUser(matrixAddress).$(InkWell).containing($("Unban"));
  }
}
