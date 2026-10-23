import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings_view.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_item.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_redirection_edit_button.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_view.dart';
import 'package:twake_chat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';

import '../home_robot.dart';

class SettingsProfileRobot extends HomeRobot {
  SettingsProfileRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  PatrolFinder profileEntry() {
    return $(SettingsKeys.listViewContent.key).$(InkWell).first;
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

  PatrolFinder redirectionEditButton() {
    return profileView().$(SettingsProfileRedirectionEditButton).$(TextButton);
  }

  PatrolFinder backButton() {
    return profileView().$(AppBar).$(find.byIcon(Icons.arrow_back_ios));
  }

  Future<void> openProfile() async {
    await profileEntry().tap();
    await $.waitUntilVisible(profileView());
  }

  String? valueOf(SettingsProfileEnum settingsProfileEnum) {
    final widget = item(settingsProfileEnum).evaluate().first.widget;
    return (widget as SettingsProfileItemBuilder).textEditingController?.text;
  }

  Future<String> waitForValueOf(
    SettingsProfileEnum settingsProfileEnum, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await $.waitUntilVisible(item(settingsProfileEnum));
    final deadline = DateTime.now().add(timeout);
    var value = valueOf(settingsProfileEnum) ?? '';
    while (value.isEmpty && DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 100));
      value = valueOf(settingsProfileEnum) ?? '';
    }
    return value;
  }

  Future<void> copyMatrixId() async {
    await matrixIdCopyIcon().tap();
    await $.waitUntilVisible($(_l10n.copiedMatrixIdToClipboard));
  }

  Future<void> backToSettings() async {
    await backButton().tap();
    await $.waitUntilVisible($(SettingsView));
  }
}
