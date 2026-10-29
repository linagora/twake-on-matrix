import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/dialog/confirmation_dialog_builder.dart';
import 'package:matrix/matrix.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/device_settings/change_device_name_dialog.dart';
import 'package:twake_chat/pages/device_settings/device_settings.dart';
import 'package:twake_chat/pages/device_settings/session_all_actions_dialog.dart';
import 'package:twake_chat/pages/device_settings/user_device_list_item.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/device_extension.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../home_robot.dart';

class DeviceSettingsRobot extends HomeRobot {
  DeviceSettingsRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  PatrolFinder _session(String name) =>
      $(DevicesSettings).$(UserDeviceListItem).containing(find.text(name));

  PatrolFinder _actionsSheet() => $(SessionAllActionsView);

  PatrolFinder _sheetAction(String label) => _actionsSheet().$(label);

  PatrolFinder _removeAllTile() =>
      $(DevicesSettings).$(_l10n.removeAllOtherDevices);

  // Rows are sorted by last activity, so a fresh API session can start below
  // the fold; scroll from the top (current session) down to the target.
  Future<void> _reveal(PatrolFinder target) async {
    final list = $(DevicesSettings).$(Scrollable);
    await $.scrollUntilVisible(
      finder: _currentSession(),
      view: list,
      scrollDirection: AxisDirection.up,
      delta: 200,
    );
    await $.scrollUntilVisible(
      finder: target,
      view: list,
      scrollDirection: AxisDirection.down,
      delta: 200,
    );
  }

  Future<void> _openActions(PatrolFinder row, {required String name}) async {
    await _reveal(row);
    // The row centre can hold the Verify button; tap the name instead.
    await row.$(name).tap();
    await $.waitUntilVisible(_sheetAction(_l10n.changeDeviceName));
  }

  Future<void> _closeActions() async {
    await _actionsSheet().$(_l10n.cancel).tap();
    await waitUntilAbsent($, _actionsSheet());
  }

  Future<void> waitForOtherSessions(List<String> names) async {
    await $.waitUntilVisible(
      _removeAllTile(),
      timeout: const Duration(seconds: 30),
    );
    for (final name in names) {
      await _reveal(_session(name));
    }
  }

  Client get _client => Matrix.of($.tester.element($(DevicesSettings))).client;

  PatrolFinder _currentSession() => $(DevicesSettings).$(
    find.byWidgetPredicate(
      (widget) =>
          widget is UserDeviceListItem &&
          widget.userDevice.deviceId == _client.deviceID,
    ),
  );

  Future<void> _confirmRemoval(String title, String password) async {
    final confirm = $(ConfirmationDialogBuilder).containing(title);
    await $.waitUntilVisible(confirm.$(_l10n.remove));
    await confirm.$(_l10n.remove).tap();

    final passwordDialog = $(
      ConfirmationDialogBuilder,
    ).containing(_l10n.pleaseEnterYourPassword);
    await $.waitUntilVisible(passwordDialog.$(EditableText));
    await passwordDialog.$(EditableText).enterText(password);
    await passwordDialog.$(_l10n.ok).tap();
    await waitUntilAbsent($, passwordDialog);
  }

  Future<void> expectCurrentSessionCannotBeRemoved() async {
    final current = _currentSession();
    await _reveal(current);
    final row = current.evaluate().single.widget as UserDeviceListItem;
    await _openActions(current, name: row.userDevice.displayname);
    expect(_sheetAction(_l10n.removeDevice), findsNothing);
    await _closeActions();
  }

  Future<void> renameSession(String from, String to) async {
    await _openActions(_session(from), name: from);
    await $.waitUntilVisible(_sheetAction(_l10n.removeDevice));
    await _sheetAction(_l10n.changeDeviceName).tap();

    final dialog = $(ChangeDeviceNameView);
    // The dialog centre is empty space, so wait for its field instead.
    await $.waitUntilVisible(dialog.$(EditableText));
    await dialog.$(EditableText).enterText(to);
    await dialog.$(_l10n.save).tap();

    await waitUntilAbsent($, dialog);
    await _reveal(_session(to));
    await waitUntilAbsent($, _session(from));
  }

  Future<void> removeSession(String name, {required String password}) async {
    await _openActions(_session(name), name: name);
    await _sheetAction(_l10n.removeDevice).tap();
    await _confirmRemoval(_l10n.removeDeviceConfirmationTitle, password);
    await waitUntilAbsent(
      $,
      _session(name),
      timeout: const Duration(seconds: 30),
    );
  }

  Future<void> removeAllOtherSessions({required String password}) async {
    await _reveal(_removeAllTile());
    await _removeAllTile().tap();
    await _confirmRemoval(
      _l10n.removeAllOtherDevicesConfirmationTitle,
      password,
    );
    await $.waitUntilVisible(
      $(DevicesSettings).$(_l10n.noOtherDevicesFound),
      timeout: const Duration(seconds: 30),
    );
    expect($(DevicesSettings).$(UserDeviceListItem), findsOneWidget);
    expect(_currentSession(), findsOneWidget);

    // The server must keep the current session, and only it.
    final devices = await _client.getDevices();
    expect(devices?.map((d) => d.deviceId), [_client.deviceID]);
  }
}
