import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings_view.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_item.dart';
import 'package:twake_chat/pages/personal_qr/personal_qr.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_view.dart';
import 'package:twake_chat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

import '../home_robot.dart';

class SettingsProfileRobot extends HomeRobot {
  SettingsProfileRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  PatrolFinder profileEntry() {
    return $(SettingsKeys.listViewContent.key).$(InkWell).containing(Avatar);
  }

  PatrolFinder profileView() {
    return $(SettingsProfileView);
  }

  PatrolFinder title() {
    return profileView().$(AppBar).$(_l10n.profile);
  }

  PatrolFinder item(SettingsProfileEnum settingsProfileEnum) {
    return profileView().$(
      find.byWidgetPredicate(
        (widget) =>
            widget is SettingsProfileItemBuilder &&
            widget.settingsProfileEnum == settingsProfileEnum,
      ),
    );
  }

  PatrolFinder displayNameEditIcon() {
    return item(
      SettingsProfileEnum.displayName,
    ).$(find.byIcon(Icons.edit_outlined));
  }

  PatrolFinder matrixIdCopyIcon() {
    return item(
      SettingsProfileEnum.matrixId,
    ).$(find.byIcon(Icons.content_copy));
  }

  PatrolFinder avatarEditBadge() {
    return profileView().$(find.byIcon(Icons.edit));
  }

  PatrolFinder qrCodeButton() {
    return profileView().$(AppBar).$(find.byIcon(Icons.qr_code));
  }

  PatrolFinder multipleAccountsButton() {
    return profileView()
        .$(InkWell)
        .containing(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == _l10n.addAnotherAccount ||
                    widget.data == _l10n.switchAccounts),
          ),
        );
  }

  PatrolFinder backButton() {
    return profileView().$(AppBar).$(find.byIcon(Icons.arrow_back_ios));
  }

  Future<void> openProfile() async {
    await profileEntry().tap();
    await $.waitUntilVisible(profileView());
  }

  String? getValueOf(SettingsProfileEnum settingsProfileEnum) {
    final widget = item(settingsProfileEnum).evaluate().first.widget;
    return (widget as SettingsProfileItemBuilder).textEditingController?.text;
  }

  Future<String> waitForValueOf(
    SettingsProfileEnum settingsProfileEnum, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await $.waitUntilVisible(item(settingsProfileEnum));
    final deadline = DateTime.now().add(timeout);
    var value = getValueOf(settingsProfileEnum) ?? '';
    while (value.isEmpty && DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 100));
      value = getValueOf(settingsProfileEnum) ?? '';
    }
    return value;
  }

  Future<void> copyMatrixId() async {
    await matrixIdCopyIcon().tap();
    await $.waitUntilVisible($(_l10n.copiedMatrixIdToClipboard));
  }

  Future<void> openAvatarMenu() async {
    await avatarEditBadge().tap();
    // "Set profile avatar" is the no-avatar label from #3482, not on main yet.
    final labels = {_l10n.changeProfileAvatar, 'Set profile avatar'};
    await $.waitUntilVisible(
      $(
        find.byWidgetPredicate(
          (widget) => widget is Text && labels.contains(widget.data),
        ),
      ),
    );
  }

  Future<void> openQrCode() async {
    await qrCodeButton().tap();
    await $.waitUntilVisible($(PersonalQr));
  }

  Future<void> openMultipleAccountsPicker() async {
    await multipleAccountsButton().tap();
    await $.waitUntilVisible($(_l10n.selectAccount));
  }

  Future<void> backToSettings() async {
    await backButton().tap();
    await $.waitUntilVisible($(SettingsView));
  }
}
