import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/pages/device_settings/device_settings.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'user_device_list_item.dart';

class DevicesSettingsView extends StatelessWidget {
  final DevicesSettingsController controller;
  final responsive = getIt.get<ResponsiveUtils>();

  DevicesSettingsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        context: context,
        title: L10n.of(context)!.deviceKeys,
        centerTitle: true,
        withDivider: true,
        leading: responsive.isMobile(context)
            ? Padding(
                padding: TwakeAppBarStyle.leadingIconPadding,
                child: IconButton(
                  tooltip: L10n.of(context)!.back,
                  icon: const Icon(Icons.chevron_left_outlined),
                  onPressed: () => context.pop(),
                  iconSize: TwakeAppBarStyle.leadingIconSize,
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: MaxWidthBody(
        child: FutureBuilder<bool>(
          future: controller.loadUserDevices(context),
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outlined),
                    Text(snapshot.error.toString()),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || controller.devices == null) {
              return const Center(
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              );
            }
            return ListView.builder(
              itemCount: controller.notThisDevice.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == 0) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.thisDevice != null)
                        UserDeviceListItem(
                          controller.thisDevice!,
                          rename: controller.renameDeviceAction,
                          remove: (d) => controller.removeDevicesAction([d]),
                          verify: controller.verifyDeviceAction,
                          block: controller.blockDeviceAction,
                          unblock: controller.unblockDeviceAction,
                        ),
                      const Divider(height: 1),
                      if (controller.notThisDevice.isNotEmpty)
                        ListTile(
                          title: Text(
                            controller.errorDeletingDevices ??
                                L10n.of(context)!.removeAllOtherDevices,
                            style: const TextStyle(color: Colors.red),
                          ),
                          trailing: controller.loadingDeletingDevices
                              ? const CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                )
                              : const Icon(Icons.delete_outline),
                          onTap: controller.loadingDeletingDevices
                              ? null
                              : () => controller.removeDevicesAction(
                                    controller.notThisDevice,
                                  ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(L10n.of(context)!.noOtherDevicesFound),
                          ),
                        ),
                      const Divider(height: 1),
                    ],
                  );
                }
                i--;
                return UserDeviceListItem(
                  controller.notThisDevice[i],
                  rename: controller.renameDeviceAction,
                  remove: (d) => controller.removeDevicesAction([d]),
                  verify: controller.verifyDeviceAction,
                  block: controller.blockDeviceAction,
                  unblock: controller.unblockDeviceAction,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
