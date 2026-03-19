import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'settings_notifications.dart';

class SettingsNotificationsView extends StatelessWidget {
  final SettingsNotificationsController controller;
  final responsive = getIt.get<ResponsiveUtils>();

  SettingsNotificationsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final client = Matrix.of(context).client;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        title: l10n.notifications,
        context: context,
        centerTitle: true,
        withDivider: true,
        leading: responsive.isMobile(context)
            ? Padding(
                padding: TwakeAppBarStyle.leadingIconPadding,
                child: IconButton(
                  tooltip: l10n.back,
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: context.pop,
                  iconSize: TwakeAppBarStyle.leadingIconSize,
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: MaxWidthBody(
        withScrolling: true,
        child: StreamBuilder(
          stream: client.onAccountData.stream.where(
            (event) => event.type == 'm.push_rules',
          ),
          builder: (BuildContext context, _) {
            return Column(
              children: [
                SwitchListTile.adaptive(
                  value: !client.allPushNotificationsMuted,
                  title: Text(
                    client.allPushNotificationsMuted
                        ? l10n.enable_notifications
                        : l10n.disable_notifications,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  onChanged: (_) =>
                      TwakeDialog.showFutureLoadingDialogFullScreen(
                        future: () => client.setMuteAllPushNotifications(
                          !client.allPushNotificationsMuted,
                        ),
                      ),
                ),
                if (!client.allPushNotificationsMuted) ...{
                  const Divider(thickness: 1),
                  ListTile(
                    title: Text(
                      l10n.pushRules,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final item in NotificationSettingsItem.items)
                    SwitchListTile.adaptive(
                      value: controller.getNotificationSetting(item) ?? true,
                      title: Text(
                        item.title(context),
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      onChanged: (bool enabled) =>
                          controller.setNotificationSetting(item, enabled),
                    ),
                },
              ],
            );
          },
        ),
      ),
    );
  }
}
