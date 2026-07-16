import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/device_settings/device_settings_state.dart';
import 'package:fluffychat/pages/device_settings/device_settings_view_model.dart';
import 'package:fluffychat/pages/key_verification/key_verification_dialog.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'user_device_list_item.dart';
import '../../widgets/matrix.dart';

class DevicesSettings extends ConsumerWidget {
  const DevicesSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = Matrix.of(context).client;
    final notifier = ref.read(devicesSettingsViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        context: context,
        title: L10n.of(context)!.deviceKeys,
        centerTitle: true,
        withDivider: true,
        leading: getIt.get<ResponsiveUtils>().isMobile(context)
            ? Padding(
                padding: TwakeAppBarStyle.leadingIconPadding,
                child: IconButton(
                  tooltip: L10n.of(context)!.back,
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => context.pop(),
                  iconSize: TwakeAppBarStyle.leadingIconSize,
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: FutureBuilder<void>(
        future: notifier.loadUserDevices(client),
        builder: (BuildContext context, snapshot) {
          final state = ref.watch(devicesSettingsViewModelProvider);
          if (snapshot.hasError || state is DevicesSettingsError) {
            return MaxWidthBody(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outlined),
                    Text(
                      state is DevicesSettingsError
                          ? state.exception.toString()
                          : snapshot.error.toString(),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done ||
              state is DevicesSettingsInitial) {
            return const MaxWidthBody(
              child: Center(
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
            );
          }
          final isMobile = getIt.get<ResponsiveUtils>().isMobile(context);
          return Column(
            children: [
              if (notifier.showVerificationBanner(client))
                LinagoraBanner(
                  message: L10n.of(
                    context,
                  )!.deviceVerificationWarningOnSettingsScreen,
                  actionLabel: L10n.of(context)!.verify,
                ),
              Expanded(
                child: Container(
                  color: isMobile
                      ? null
                      : LinagoraSysColors.material().surfaceVariant,
                  padding: isMobile
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(24),
                  child: MaxWidthBody(
                    child: isMobile
                        ? const _DevicesList()
                        : Container(
                            decoration: BoxDecoration(
                              color: LinagoraSysColors.material().onPrimary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const _DevicesList(),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DevicesList extends ConsumerWidget {
  const _DevicesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = Matrix.of(context).client;
    final notifier = ref.read(devicesSettingsViewModelProvider.notifier);
    final state = ref.watch(devicesSettingsViewModelProvider);
    final thisDevice = notifier.thisDevice(client);
    final notThisDevice = notifier.notThisDevice(client);
    final errorDeletingDevices = switch (state) {
      DevicesSettingsDeleteDevicesError(:final message) => message,
      _ => null,
    };
    final loadingDeletingDevices = state is DevicesSettingsDeletingDevices;
    final isMobile = getIt.get<ResponsiveUtils>().isMobile(context);

    return ListView.builder(
      itemCount: notThisDevice.length + 1,
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (thisDevice != null)
                UserDeviceListItem(
                  thisDevice,
                  rename: (d) => renameDeviceAction(context, notifier, d),
                  verify: (d) => verifyDeviceAction(context, notifier, d),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: isMobile
                      ? LinagoraSpacing.base * 5
                      : LinagoraSpacing.base * 2,
                ),
                child: Divider(
                  height: 1,
                  thickness: LinagoraDividerStyle.material().thickness,
                  color: LinagoraDividerStyle.material().color,
                ),
              ),
              if (notThisDevice.isNotEmpty)
                ListTile(
                  title: Text(
                    errorDeletingDevices ??
                        L10n.of(context)!.removeAllOtherDevices,
                    style: Theme.of(context)
                        .extension<LinagoraTextThemeExtension>()!
                        .bodyMedium2
                        .copyWith(color: LinagoraSysColors.material().error),
                  ),
                  onTap: loadingDeletingDevices
                      ? null
                      : () => removeDevicesAction(
                          context,
                          notifier,
                          notThisDevice,
                        ),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(L10n.of(context)!.noOtherDevicesFound),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: isMobile
                      ? LinagoraSpacing.base * 5
                      : LinagoraSpacing.base * 2,
                ),
                child: Divider(
                  height: 1,
                  thickness: LinagoraDividerStyle.material().thickness,
                  color: LinagoraDividerStyle.material().color,
                ),
              ),
            ],
          );
        }
        i--;
        final device = notThisDevice[i];
        return UserDeviceListItem(
          device,
          rename: (d) => renameDeviceAction(context, notifier, d),
          remove: (d) => removeDevicesAction(context, notifier, [d]),
          verify: (d) => verifyDeviceAction(context, notifier, d),
          block: (d) => blockDeviceAction(context, notifier, d),
          unblock: (d) => unblockDeviceAction(context, notifier, d),
          showDivider: isMobile,
        );
      },
    );
  }
}

Future<void> removeDevicesAction(
  BuildContext context,
  DevicesSettingsViewModel notifier,
  List<Device> devices,
) async {
  if (await showOkCancelAlertDialog(
        useRootNavigator: false,
        context: context,
        title: L10n.of(context)!.areYouSure,
        okLabel: L10n.of(context)!.yes,
        cancelLabel: L10n.of(context)!.cancel,
      ) ==
      OkCancelResult.cancel) {
    return;
  }
  final client = Matrix.of(context).client;
  final deviceIds = devices.map((d) => d.deviceId).toList();

  try {
    notifier.setLoadingDeletingDevices(true);
    notifier.setErrorDeletingDevices(null);
    await client.uiaRequestBackground(
      (auth) => client.deleteDevices(deviceIds, auth: auth),
    );
    notifier.reload();
  } catch (e, s) {
    Logs().v('Error while deleting devices', e, s);
    notifier.setErrorDeletingDevices(e.toString());
  } finally {
    notifier.setLoadingDeletingDevices(false);
  }
}

Future<void> renameDeviceAction(
  BuildContext context,
  DevicesSettingsViewModel notifier,
  Device device,
) async {
  final displayName = await showTextInputDialog(
    useRootNavigator: false,
    context: context,
    title: L10n.of(context)!.changeDeviceName,
    okLabel: L10n.of(context)!.ok,
    cancelLabel: L10n.of(context)!.cancel,
    textFields: [DialogTextField(hintText: device.displayName)],
  );
  if (displayName == null) return;
  final client = Matrix.of(context).client;
  final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
    future: () =>
        client.updateDevice(device.deviceId, displayName: displayName.single),
  );
  if (success.error == null) {
    notifier.reload();
  }
}

Future<void> verifyDeviceAction(
  BuildContext context,
  DevicesSettingsViewModel notifier,
  Device device,
) async {
  final client = Matrix.of(context).client;
  final req = await client
      .userDeviceKeys[client.userID!]!
      .deviceKeys[device.deviceId]!
      .startVerification();
  req.onUpdate = () {
    if ({
      KeyVerificationState.error,
      KeyVerificationState.done,
    }.contains(req.state)) {
      notifier.refreshDeviceKeys();
    }
  };
  await KeyVerificationDialog(request: req).show(context);
}

Future<void> blockDeviceAction(
  BuildContext context,
  DevicesSettingsViewModel notifier,
  Device device,
) async {
  final client = Matrix.of(context).client;
  final key =
      client.userDeviceKeys[client.userID!]!.deviceKeys[device.deviceId]!;
  if (key.directVerified) {
    await key.setVerified(false);
  }
  await key.setBlocked(true);
  notifier.refreshDeviceKeys();
}

Future<void> unblockDeviceAction(
  BuildContext context,
  DevicesSettingsViewModel notifier,
  Device device,
) async {
  final client = Matrix.of(context).client;
  final key =
      client.userDeviceKeys[client.userID!]!.deviceKeys[device.deviceId]!;
  await key.setBlocked(false);
  notifier.refreshDeviceKeys();
}
