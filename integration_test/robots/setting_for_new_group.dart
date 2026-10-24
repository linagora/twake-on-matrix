import 'package:twake_chat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
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

  // Encryption is the last setting toggle while the group is private.
  PatrolFinder getEncryptionToggle() {
    return $(LinagoraSettingItem).last;
  }

  // Only shown when the well-known enables public groups.
  PatrolFinder getMakePublicToggle() {
    return $(LinagoraSettingItem).first;
  }

  Future<void> settingForNewGroup(
    String name, {
    bool encription = false,
    bool isPublic = false,
  }) async {
    await getNameTextField().enterText(name);
    if (isPublic) {
      await getMakePublicToggle().tap();
    }
    if (encription) {
      await getEncryptionToggle().tap();
    }
  }
}
