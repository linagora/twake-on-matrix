import 'package:fluffychat/config/go_routes/app_routes.dart';
import 'package:fluffychat/presentation/widget_keys/widget_keys.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_item_builder.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/beautify_string_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'settings_security.dart';

class SettingsSecurityView extends StatelessWidget {
  final SettingsSecurityController controller;
  final responsive = getIt.get<ResponsiveUtils>();

  SettingsSecurityView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final refColorTertiary30 = LinagoraRefColors.material().tertiary[30];
    final sysColor = LinagoraSysColors.material();
    final linagoraTextStyleBodyMedium = LinagoraTextStyle.material().bodyMedium;

    return Scaffold(
      backgroundColor: sysColor.onPrimary,
      appBar: TwakeAppBar(
        title: l10n.security,
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
      body: ListTileTheme(
        // TODO: remove when the color scheme is updated
        // ignore: deprecated_member_use
        iconColor: colorScheme.onBackground,
        child: MaxWidthBody(
          withScrolling: true,
          child: Column(
            children: [
              Column(
                children: [
                  Padding(
                    padding: SettingsViewStyle.bodySettingsScreenPadding,
                    child: SettingsItemBuilder(
                      key: SettingsKeys.contactsVisibilityItem.key,
                      title: l10n.contactsVisibility,
                      titleColor: colorScheme.onBackground,
                      subtitle: l10n.whoCanFindMeByMyContacts,
                      leading: Icons.phone_outlined,
                      leadingIconColor: refColorTertiary30,
                      onTap: () {
                        const SecurityContactsVisibilityRoute().push(context);
                      },
                    ),
                  ),
                  Padding(
                    padding: SettingsViewStyle.settingsItemDividerPadding(),
                    child: Divider(
                      color: LinagoraStateLayer(
                        sysColor.surfaceTint,
                      ).opacityLayer3,
                      thickness: SettingsViewStyle.settingsItemDividerThickness,
                      height: SettingsViewStyle.settingsItemDividerHeight,
                    ),
                  ),
                  Padding(
                    padding: SettingsViewStyle.bodySettingsScreenPadding,
                    child: ValueListenableBuilder(
                      valueListenable: controller.ignoredUsersNotifier,
                      builder: (context, ignoredUsers, _) {
                        return SettingsItemBuilder(
                          title: l10n.blockedUsers,
                          titleColor: colorScheme.onBackground,
                          subtitle: ignoredUsers.isEmpty
                              ? null
                              : ignoredUsers.length.toString(),
                          leadingWidget: SvgPicture.asset(
                            ImagePaths.icFrontHand,
                            colorFilter: ColorFilter.mode(
                              refColorTertiary30 ?? sysColor.onSurface,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () {
                            if (ignoredUsers.isNotEmpty) {
                              const SecurityBlockedUsersRoute().push(context);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: SettingsViewStyle.settingsItemDividerPadding(),
                    child: Divider(
                      color: LinagoraStateLayer(
                        sysColor.surfaceTint,
                      ).opacityLayer3,
                      thickness: SettingsViewStyle.settingsItemDividerThickness,
                      height: SettingsViewStyle.settingsItemDividerHeight,
                    ),
                  ),
                ],
              ),
              // Recovery Key section - fetched from ToM server
              FutureBuilder<String?>(
                future: controller.recoveryKeyFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: SettingsViewStyle.bodySettingsScreenPadding,
                        child: SettingsItemBuilder(
                          key: const Key('recovery_key_settings_item'),
                          title: l10n.recoveryKey,
                          titleColor: colorScheme.onBackground,
                          subtitle: '\u2022' * 32,
                          subtitleStyle: linagoraTextStyleBodyMedium.copyWith(
                            color: refColorTertiary30,
                            letterSpacing: 2,
                          ),
                          leadingWidget: SvgPicture.asset(
                            ImagePaths.icRecoveryKey,
                            colorFilter: ColorFilter.mode(
                              refColorTertiary30 ?? sysColor.onSurface,
                              BlendMode.srcIn,
                            ),
                          ),
                          trailingWidget: InkWell(
                            key: const Key('recovery_key_copy_button'),
                            onTap: controller.copyRecoveryKey,
                            child: const Icon(Icons.content_copy),
                          ),
                          onTap: controller.copyRecoveryKey,
                        ),
                      ),
                      Padding(
                        padding: SettingsViewStyle.settingsItemDividerPadding(),
                        child: Divider(
                          color: LinagoraStateLayer(
                            sysColor.surfaceTint,
                          ).opacityLayer3,
                          thickness:
                              SettingsViewStyle.settingsItemDividerThickness,
                          height: SettingsViewStyle.settingsItemDividerHeight,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (Matrix.of(context).client.encryption != null) ...{
                if (PlatformInfos.isMobile)
                  Column(
                    children: [
                      Padding(
                        padding: SettingsViewStyle.bodySettingsScreenPadding,
                        child: SettingsItemBuilder(
                          title: l10n.appLock,
                          titleColor: colorScheme.onBackground,
                          leading: Icons.lock_outlined,
                          onTap: controller.setAppLockAction,
                          leadingIconColor: refColorTertiary30,
                        ),
                      ),
                      Padding(
                        padding: SettingsViewStyle.settingsItemDividerPadding(),
                        child: Divider(
                          color: LinagoraStateLayer(
                            sysColor.surfaceTint,
                          ).opacityLayer3,
                          thickness:
                              SettingsViewStyle.settingsItemDividerThickness,
                          height: SettingsViewStyle.settingsItemDividerHeight,
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: SettingsViewStyle.bodySettingsScreenPadding,
                  child: SettingsItemBuilder(
                    height: 116,
                    title: l10n.yourPublicKey,
                    titleColor: colorScheme.onBackground,
                    subtitle: Matrix.of(
                      context,
                    ).client.fingerprintKey.beautified,
                    subtitleStyle: linagoraTextStyleBodyMedium.copyWith(
                      color: refColorTertiary30,
                      fontFamily: 'monospace',
                    ),
                    leading: Icons.notifications_outlined,
                    onTap: controller.copyPublicKey,
                    leadingIconColor: refColorTertiary30,
                    trailingWidget: InkWell(
                      onTap: controller.copyPublicKey,
                      child: const Icon(Icons.content_copy),
                    ),
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
