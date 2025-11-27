import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class SettingForNewGroupRobot extends CoreRobot {
  SettingForNewGroupRobot(super.$);

  PatrolFinder getNameTextField() {
    return $(TextField).last;
  }

  PatrolFinder getConfirmIcon() {
    return $(TwakeFloatingActionButton).last;
  }

  PatrolFinder getEncriptionCkb() {
    return $(Checkbox).last;
  }

  Future<void> settingForNewGroup(
    String name, {
    bool encription = false,
  }) async {
    await getNameTextField().enterText(name);
    if (encription) {
      await getEncriptionCkb().tap();
    }
  }
}
