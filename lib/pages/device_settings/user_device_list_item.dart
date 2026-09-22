import 'package:flutter/material.dart';

import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import '../../utils/date_time_extension.dart';
import '../../utils/matrix_sdk_extensions/device_extension.dart';
import '../../widgets/matrix.dart';
import 'session_all_actions_dialog.dart';
import 'session_summary.dart';

class UserDeviceListItem extends StatelessWidget {
  final Device userDevice;
  final void Function(Device)? remove;
  final void Function(Device)? rename;
  final void Function(Device) verify;
  final bool showDivider;

  const UserDeviceListItem(
    this.userDevice, {
    this.remove,
    this.rename,
    required this.verify,
    this.showDivider = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final client = Matrix.of(context).client;
    final keys =
        client.userDeviceKeys[client.userID]?.deviceKeys[userDevice.deviceId];
    final isOwnDevice = userDevice.deviceId == client.deviceID;
    final verified = isOwnDevice || keys?.verified == true;
    final lastActiveText = l10n.lastActiveAgo(
      DateTime.fromMillisecondsSinceEpoch(
        userDevice.lastSeenTs ?? 0,
      ).localizedTimeShort(context),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => SessionAllActionsDialog.show(
        context,
        session: SessionSummary(
          deviceName: userDevice.displayname,
          lastActiveText: lastActiveText,
          platformIcon: userDevice.icon,
          verified: verified,
        ),
        actions: SessionActions(
          onChangeName: () => rename?.call(userDevice),
          onStartVerification: verified ? null : () => verify(userDevice),
          onRemove: isOwnDevice ? null : () => remove?.call(userDevice),
        ),
      ),
      child: SessionDeviceListItem(
        deviceName: userDevice.displayname,
        lastActiveText: lastActiveText,
        platformIcon: userDevice.icon,
        verified: verified,
        unverifiedLabel: l10n.unverified,
        verifyLabel: l10n.verify,
        onVerifyPressed: verified ? null : () => verify(userDevice),
        onDelete: remove == null ? null : () => remove?.call(userDevice),
        showDivider: showDivider,
      ),
    );
  }
}
