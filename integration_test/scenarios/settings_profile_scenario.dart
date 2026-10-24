import 'package:twake_chat/presentation/enum/settings/settings_profile_enum.dart';

import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/setting/settings_profile_robot.dart';

abstract class _SettingsProfileScenario extends BaseTestScenario {
  _SettingsProfileScenario(super.$, super.robots);

  late final profile = SettingsProfileRobot($);

  Future<void> openProfile() async {
    await robots.homeRobot().gotoSettingScreen();
    await profile.openProfile();
  }
}

class SettingsProfileOpenScenario extends _SettingsProfileScenario {
  SettingsProfileOpenScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();
    await openProfile();

    s.softAssertEquals(profile.title().exists, true, 'Profile title missing');

    final displayName = await profile.waitForValueOf(
      SettingsProfileEnum.displayName,
    );
    s.softAssertEquals(
      displayName.isNotEmpty,
      true,
      'display name row is empty',
    );

    const username = String.fromEnvironment('USERNAME');
    final expectedPrefix = username.startsWith('@') ? username : '@$username:';
    final matrixId = await profile.waitForValueOf(SettingsProfileEnum.matrixId);
    s.softAssertEquals(
      matrixId.startsWith(expectedPrefix),
      true,
      'Matrix ID "$matrixId" does not start with "$expectedPrefix"',
    );

    s.verifyAll();
  }
}

/// CI Synapse allows profile edits, so only the "allowed" branch is testable.
class SettingsProfileCapabilitiesScenario extends _SettingsProfileScenario {
  SettingsProfileCapabilitiesScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await openProfile();

    await $.waitUntilVisible(profile.displayNameEditIcon());
    await $.waitUntilVisible(profile.avatarEditBadge());
  }
}

class SettingsProfileCopyMatrixIdScenario extends _SettingsProfileScenario {
  SettingsProfileCopyMatrixIdScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await openProfile();
    await profile.waitForValueOf(SettingsProfileEnum.matrixId);
    await profile.copyMatrixId();
  }
}

class SettingsProfileAvatarMenuScenario extends _SettingsProfileScenario {
  SettingsProfileAvatarMenuScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await openProfile();
    await $.waitUntilVisible(profile.avatarEditBadge());
    await profile.openAvatarMenu();
  }
}

class SettingsProfileQrCodeScenario extends _SettingsProfileScenario {
  SettingsProfileQrCodeScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await openProfile();
    await profile.openQrCode();
  }
}

class SettingsProfileMultipleAccountsScenario extends _SettingsProfileScenario {
  SettingsProfileMultipleAccountsScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await openProfile();
    await $.waitUntilVisible(profile.multipleAccountsButton());
    await profile.openMultipleAccountsPicker();
  }
}

class SettingsProfileBackScenario extends _SettingsProfileScenario {
  SettingsProfileBackScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await openProfile();
    await profile.backToSettings();
  }
}
