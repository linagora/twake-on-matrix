import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import '../../utils/date_time_extension.dart';
import '../../utils/matrix_sdk_extensions/device_extension.dart';
import '../../widgets/matrix.dart';

enum UserDeviceListItemAction { rename, remove, verify, block, unblock }

class UserDeviceListItem extends StatelessWidget {
  final Device userDevice;
  final void Function(Device)? remove;
  final void Function(Device)? rename;
  final void Function(Device) verify;
  final void Function(Device)? block;
  final void Function(Device)? unblock;
  final bool showDivider;

  const UserDeviceListItem(
    this.userDevice, {
    this.remove,
    this.rename,
    required this.verify,
    this.block,
    this.unblock,
    this.showDivider = false,
    super.key,
  });

  Future<void> _openActionSheet(
    BuildContext context,
    DeviceKeys? keys,
    bool isOwnDevice,
  ) async {
    final action = await showModalActionSheet<UserDeviceListItemAction>(
      context: context,
      title: '${userDevice.displayName} (${userDevice.deviceId})',
      actions: [
        SheetAction(
          key: UserDeviceListItemAction.rename,
          label: L10n.of(context)!.changeDeviceName,
        ),
        if (!isOwnDevice && keys != null) ...{
          if (!keys.blocked && block != null)
            SheetAction(
              key: UserDeviceListItemAction.block,
              label: L10n.of(context)!.blockDevice,
              isDestructiveAction: true,
            ),
          if (keys.blocked && unblock != null)
            SheetAction(
              key: UserDeviceListItemAction.unblock,
              label: L10n.of(context)!.unblockDevice,
              isDestructiveAction: true,
            ),
        },
      ],
    );
    if (action == null) return;
    switch (action) {
      case UserDeviceListItemAction.rename:
        rename?.call(userDevice);
        break;
      case UserDeviceListItemAction.remove:
        remove?.call(userDevice);
        break;
      case UserDeviceListItemAction.verify:
        verify(userDevice);
        break;
      case UserDeviceListItemAction.block:
        block?.call(userDevice);
        break;
      case UserDeviceListItemAction.unblock:
        unblock?.call(userDevice);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final keys =
        client.userDeviceKeys[client.userID]?.deviceKeys[userDevice.deviceId];
    final isOwnDevice = userDevice.deviceId == client.deviceID;
    final verified = isOwnDevice || keys == null || keys.verified;

    return GestureDetector(
      onTap: () => _openActionSheet(context, keys, isOwnDevice),
      child: SessionDeviceListItem(
        deviceName: userDevice.displayname,
        lastActiveText: L10n.of(context)!.lastActiveAgo(
          DateTime.fromMillisecondsSinceEpoch(
            userDevice.lastSeenTs ?? 0,
          ).localizedTimeShort(context),
        ),
        platformIcon: userDevice.icon,
        verified: verified,
        unverifiedLabel: L10n.of(context)!.unverified,
        verifyLabel: L10n.of(context)!.verify,
        onVerifyPressed: verified ? null : () => verify(userDevice),
        onDelete: remove == null ? null : () => remove?.call(userDevice),
        showDivider: showDivider,
      ),
    );
  }
}
