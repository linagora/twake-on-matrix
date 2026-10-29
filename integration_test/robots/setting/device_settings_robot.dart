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

import '../../base/api_login_helper_io.dart';
import '../home_robot.dart';

class DeviceSettingsRobot extends HomeRobot {
  DeviceSettingsRobot(super.$);

  static const _password = String.fromEnvironment('PASSWORD');

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  Client get _client => Matrix.of($.tester.element($(DevicesSettings))).client;

  PatrolFinder _rowWhere(bool Function(Device device) matches) =>
      $(DevicesSettings).$(
        find.byWidgetPredicate(
          (widget) =>
              widget is UserDeviceListItem && matches(widget.userDevice),
        ),
      );

  PatrolFinder _currentSession() =>
      _rowWhere((device) => device.deviceId == _client.deviceID);

  PatrolFinder _session(PrimaryExtraSession session) =>
      _rowWhere((device) => device.deviceId == session.deviceId);

  String _nameOf(PatrolFinder row) =>
      (row.evaluate().single.widget as UserDeviceListItem)
          .userDevice
          .displayname;

  PatrolFinder _actionsSheet() => $(SessionAllActionsView);

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

  Future<void> _openActions(PatrolFinder row) async {
    await _reveal(row);
    // The row centre can hold the Verify button; tap the name instead.
    await row.$(_nameOf(row)).tap();
    await $.waitUntilVisible(_actionsSheet().$(_l10n.changeDeviceName));
  }

  Future<void> _closeActions() async {
    await _actionsSheet().$(_l10n.cancel).tap();
    await waitUntilAbsent($, _actionsSheet());
  }

  Future<void> _confirmRemoval(PatrolFinder confirm) async {
    await $.waitUntilVisible(confirm.$(_l10n.remove));
    await confirm.$(_l10n.remove).tap();

    final passwordDialog = $(
      ConfirmationDialogBuilder,
    ).containing(_l10n.pleaseEnterYourPassword);
    await $.waitUntilVisible(passwordDialog.$(EditableText));
    await passwordDialog.$(EditableText).enterText(_password);
    await passwordDialog.$(_l10n.ok).tap();
    await waitUntilAbsent($, passwordDialog);
  }

  Future<void> waitForOtherSessions(List<PrimaryExtraSession> sessions) async {
    await $.waitUntilVisible(
      _removeAllTile(),
      timeout: const Duration(seconds: 30),
    );
    for (final session in sessions) {
      await _reveal(_session(session));
    }
  }

  Future<void> expectCurrentSessionCannotBeRemoved() async {
    await _openActions(_currentSession());
    expect(_actionsSheet().$(_l10n.removeDevice), findsNothing);
    await _closeActions();
  }

  Future<void> renameSession(PrimaryExtraSession session, String to) async {
    final row = _session(session);
    await _openActions(row);
    final from = _nameOf(row);
    await $.waitUntilVisible(_actionsSheet().$(_l10n.removeDevice));
    await _actionsSheet().$(_l10n.changeDeviceName).tap();

    final dialog = $(ChangeDeviceNameView);
    // The dialog centre is empty space, so wait for its field instead.
    await $.waitUntilVisible(dialog.$(EditableText));
    await dialog.$(EditableText).enterText(to);
    await dialog.$(_l10n.save).tap();

    await waitUntilAbsent($, dialog);
    await _reveal(row.containing(find.text(to)));
    await waitUntilAbsent($, $(DevicesSettings).$(UserDeviceListItem).$(from));
  }

  Future<void> removeSession(PrimaryExtraSession session) async {
    final row = _session(session);
    await _openActions(row);
    await _actionsSheet().$(_l10n.removeDevice).tap();
    await _confirmRemoval(
      $(
        ConfirmationDialogBuilder,
      ).containing(_l10n.removeDeviceConfirmationTitle),
    );
    await waitUntilAbsent($, row, timeout: const Duration(seconds: 30));
  }

  Future<void> removeAllOtherSessions() async {
    await _reveal(_removeAllTile());
    await _removeAllTile().tap();
    await _confirmRemoval(
      $(
        ConfirmationDialogBuilder,
      ).containing(_l10n.removeAllOtherDevicesConfirmationTitle),
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
