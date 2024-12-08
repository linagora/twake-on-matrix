import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'settings_notifications.dart';

class SettingsNotificationsView extends StatelessWidget {
  final SettingsNotificationsController controller;
  final responsive = getIt.get<ResponsiveUtils>();

  SettingsNotificationsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.notifications,
        context: context,
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
        withScrolling: true,
        child: StreamBuilder(
          stream: Matrix.of(context)
              .client
              .onAccountData
              .stream
              .where((event) => event.type == 'm.push_rules'),
          builder: (BuildContext context, _) {
            return Column(
              children: [
                SwitchListTile.adaptive(
                  value: !Matrix.of(context).client.allPushNotificationsMuted,
                  title: Text(
                    Matrix.of(context).client.allPushNotificationsMuted
                        ? L10n.of(context)!.enable_notifications
                        : L10n.of(context)!.disable_notifications,
                  ),
                  onChanged: (_) =>
                      TwakeDialog.showFutureLoadingDialogFullScreen(
                    future: () => Matrix.of(context)
                        .client
                        .setMuteAllPushNotifications(
                          !Matrix.of(context).client.allPushNotificationsMuted,
                        ),
                  ),
                ),
                if (!Matrix.of(context).client.allPushNotificationsMuted) ...{
                  const Divider(thickness: 1),
                  ListTile(
                    title: Text(
                      L10n.of(context)!.pushRules,
                      style: ListItemStyle.titleTextStyle(
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  for (final item in NotificationSettingsItem.items)
                    SwitchListTile.adaptive(
                      value: controller.getNotificationSetting(item) ?? true,
                      title: Text(item.title(context)),
                      onChanged: (bool enabled) =>
                          controller.setNotificationSetting(item, enabled),
                    ),
                },
                const Divider(thickness: 1),
                ListTile(
                  title: Text(
                    L10n.of(context)!.devices,
                    style: ListItemStyle.titleTextStyle(
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                FutureBuilder<List<Pusher>?>(
                  future: controller.pusherFuture ??=
                      Matrix.of(context).client.getPushers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      Center(
                        child: Text(
                          snapshot.error!.toLocalizedString(context),
                        ),
                      );
                    }
                    if (snapshot.connectionState != ConnectionState.done) {
                      const Center(
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      );
                    }
                    final pushers = snapshot.data ?? [];
                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: pushers.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(
                          '${pushers[i].appDisplayName} - ${pushers[i].appId}',
                        ),
                        subtitle: Text(pushers[i].data.url.toString()),
                        onTap: () => controller.onPusherTap(pushers[i]),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
