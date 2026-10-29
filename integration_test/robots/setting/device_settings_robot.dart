import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/dialog/confirmation_dialog_builder.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/change_device_name_dialog.dart';
import 'package:twake_chat/pages/device_settings/device_settings.dart';
import 'package:twake_chat/pages/device_settings/session_all_actions_dialog.dart';
import 'package:twake_chat/pages/device_settings/user_device_list_item.dart';

import '../home_robot.dart';

class DeviceSettingsRobot extends HomeRobot {
  DeviceSettingsRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  PatrolFinder _session(String name) =>
      $(DevicesSettings).$(UserDeviceListItem).containing(find.text(name));

  PatrolFinder _actionsSheet() => $(SessionAllActionsView);

  PatrolFinder _sheetAction(String label) => _actionsSheet().$(label);

  Future<void> _openActions(PatrolFinder row, {required String name}) async {
    // The row centre can hold the Verify button; tap the name instead.
    await row.$(name).tap();
    await $.waitUntilVisible(_sheetAction(_l10n.changeDeviceName));
  }

  Future<void> _closeActions() async {
    await _actionsSheet().$(_l10n.cancel).tap();
    await waitUntilAbsent($, _actionsSheet());
  }

  Future<void> waitForOtherSession(String name) async {
    await $.waitUntilVisible(
      _session(name),
      timeout: const Duration(seconds: 30),
    );
    await $.waitUntilVisible($(DevicesSettings).$(_l10n.removeAllOtherDevices));
  }

  Future<void> expectCurrentSessionCannotBeRemoved() async {
    final current = $(DevicesSettings).$(UserDeviceListItem).first;
    final name = current.$(Text).evaluate().first.widget as Text;
    await _openActions(current, name: name.data!);
    if (_sheetAction(_l10n.removeDevice).exists) {
      throw TestFailure('The current session offers "${_l10n.removeDevice}"');
    }
    await _closeActions();
  }

  Future<void> renameSession(String from, String to) async {
    await _openActions(_session(from), name: from);
    await $.waitUntilVisible(_sheetAction(_l10n.removeDevice));
    await _sheetAction(_l10n.changeDeviceName).tap();

    final dialog = $(ChangeDeviceNameView);
    await $.waitUntilVisible(dialog);
    await dialog.$(EditableText).enterText(to);
    await dialog.$(_l10n.save).tap();

    await waitUntilAbsent($, dialog);
    await $.waitUntilVisible(_session(to));
    await waitUntilAbsent($, _session(from));
  }

  Future<void> removeSession(String name, {required String password}) async {
    await _openActions(_session(name), name: name);
    await _sheetAction(_l10n.removeDevice).tap();

    final confirm = $(
      ConfirmationDialogBuilder,
    ).containing(_l10n.removeDeviceConfirmationTitle);
    await $.waitUntilVisible(confirm);
    await confirm.$(_l10n.remove).tap();

    final passwordDialog = $(
      ConfirmationDialogBuilder,
    ).containing(_l10n.pleaseEnterYourPassword);
    await $.waitUntilVisible(passwordDialog);
    await passwordDialog.$(EditableText).enterText(password);
    await passwordDialog.$(_l10n.ok).tap();

    await waitUntilAbsent($, passwordDialog);
    await waitUntilAbsent(
      $,
      _session(name),
      timeout: const Duration(seconds: 30),
    );
  }
}
