import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/presentation/enum/settings/settings_profile_enum.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/media_fixture.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/setting/settings_profile_robot.dart';

abstract class _SettingsProfileScenario extends BaseTestScenario {
  _SettingsProfileScenario(super.$, super.robots);

  late final profile = SettingsProfileRobot($);

  String matrixIdPrefix(String username) =>
      username.startsWith('@') ? username : '@$username:';

  Future<void> openProfile() async {
    await robots.homeRobot().gotoSettingScreen();
    await profile.openProfile();
  }
}

/// The default CI Synapse allows profile edits; the disabled case is
/// [SettingsProfileEditsDisabledScenario].
class SettingsProfileOverviewScenario extends _SettingsProfileScenario {
  SettingsProfileOverviewScenario(super.$, super.robots);

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
    final expectedPrefix = matrixIdPrefix(username);
    final matrixId = await profile.waitForValueOf(SettingsProfileEnum.matrixId);
    s.softAssertEquals(
      matrixId.startsWith(expectedPrefix),
      true,
      'Matrix ID "$matrixId" does not start with "$expectedPrefix"',
    );
    s.verifyAll();

    await $.waitUntilVisible(profile.displayNameEditIcon());
    await $.waitUntilVisible(profile.avatarEditBadge());

    await profile.copyMatrixId();
    await profile.backToSettings();
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

/// Restores the original name, through the API if the test fails, so later
/// tests see the fixture.
class SettingsProfileSaveDisplayNameScenario extends _SettingsProfileScenario {
  SettingsProfileSaveDisplayNameScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final serverName =
        (await fetchProfileAsPrimary())?['displayname'] as String?;
    addTearDown(() => setDisplayNameAsPrimary(serverName));
    await openProfile();
    await profile.waitForCapabilities();
    final original = await profile.waitForValueOf(
      SettingsProfileEnum.displayName,
    );
    final edited = 'Patrol ${DateTime.now().millisecondsSinceEpoch}';

    await profile.saveDisplayName(edited);
    await profile.waitUntilValueIs(SettingsProfileEnum.displayName, edited);
    final saved = await fetchProfileAsPrimary();
    expect(saved?['displayname'], edited);

    await profile.backToSettings();
    await profile.openProfile();
    await profile.waitUntilValueIs(SettingsProfileEnum.displayName, edited);

    await profile.saveDisplayName(original);
    await profile.waitUntilValueIs(SettingsProfileEnum.displayName, original);
    final restored = await fetchProfileAsPrimary();
    expect(restored?['displayname'], original);
  }
}

class SettingsProfileRemoveAvatarScenario extends _SettingsProfileScenario {
  SettingsProfileRemoveAvatarScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await setAvatarAsPrimary(imageFixture('profile-avatar.png'));
    await openProfile();
    await profile.waitForCapabilities();
    await profile.waitUntilHasAvatar(true);

    await profile.removeAvatar();
    await profile.waitUntilHasAvatar(false);
    final saved = await fetchProfileAsPrimary();
    expect((saved?['avatar_url'] as String?)?.isEmpty ?? true, true);

    await profile.backToSettings();
    await profile.openProfile();
    await profile.waitForValueOf(SettingsProfileEnum.displayName);
    expect(profile.hasAvatar(), false);
  }
}

/// Runs against a server with `m.set_displayname` and `m.set_avatar_url`
/// disabled; the allowed case is [SettingsProfileOverviewScenario].
class SettingsProfileEditsDisabledScenario extends _SettingsProfileScenario {
  SettingsProfileEditsDisabledScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();
    await openProfile();
    await profile.waitForCapabilities();

    const username = String.fromEnvironment('CAPS_DISABLED_USERNAME');
    final matrixId = await profile.waitForValueOf(SettingsProfileEnum.matrixId);
    s.softAssertEquals(
      matrixId.startsWith(matrixIdPrefix(username)),
      true,
      'logged in as "$matrixId", not the edits-disabled account',
    );
    final displayName = await profile.waitForValueOf(
      SettingsProfileEnum.displayName,
    );
    s.softAssertEquals(
      displayName.isNotEmpty,
      true,
      'display name row is empty',
    );
    s.softAssertEquals(
      profile.displayNameField().exists,
      false,
      'display name is editable',
    );
    s.softAssertEquals(
      profile.displayNameEditIcon().exists,
      false,
      'display name edit icon is shown',
    );
    s.softAssertEquals(
      profile.avatarEditBadge().exists,
      false,
      'avatar edit badge is shown',
    );
    s.verifyAll();
  }
}
