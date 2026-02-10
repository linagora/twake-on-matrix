import 'package:fluffychat/config/go_routes/app_route_paths.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_item_builder.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/beautify_string_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
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
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.security,
        context: context,
        centerTitle: true,
        withDivider: true,
        leading: responsive.isMobile(context)
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
      body: ListTileTheme(
        // TODO: remove when the color scheme is updated
        // ignore: deprecated_member_use
        iconColor: Theme.of(context).colorScheme.onBackground,
        child: MaxWidthBody(
          withScrolling: true,
          child: Column(
            children: [
              // #869 Hide privacy settings for now
              // ListTile(
              //   leading: const Icon(Icons.camera_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(L10n.of(context)!.whoCanSeeMyStories),
              //   onTap: () => context.go('/stories'),
              // ),
              Column(
                children: [
                  Padding(
                    padding: SettingsViewStyle.bodySettingsScreenPadding,
                    child: SettingsItemBuilder(
                      key: const Key('contacts_visibility_settings_item'),
                      title: L10n.of(context)!.contactsVisibility,
                      titleColor: Theme.of(context).colorScheme.onBackground,
                      subtitle: L10n.of(context)!.whoCanFindMeByMyContacts,
                      leading: Icons.phone_outlined,
                      leadingIconColor:
                          LinagoraRefColors.material().tertiary[30],
                      onTap: () {
                        context.push(AppRoutePaths.contactsVisibilityFull);
                      },
                    ),
                  ),
                  Padding(
                    padding: SettingsViewStyle.settingsItemDividerPadding(),
                    child: Divider(
                      color: LinagoraStateLayer(
                        LinagoraSysColors.material().surfaceTint,
                      ).opacityLayer3,
                      thickness: SettingsViewStyle.settingsItemDividerThikness,
                      height: SettingsViewStyle.settingsItemDividerHeight,
                    ),
                  ),
                  Padding(
                    padding: SettingsViewStyle.bodySettingsScreenPadding,
                    child: ValueListenableBuilder(
                      valueListenable: controller.ignoredUsersNotifier,
                      builder: (context, ignoredUsers, _) {
                        return SettingsItemBuilder(
                          title: L10n.of(context)!.blockedUsers,
                          titleColor: Theme.of(
                            context,
                          ).colorScheme.onBackground,
                          subtitle: ignoredUsers.isEmpty
                              ? null
                              : ignoredUsers.length.toString(),
                          leadingWidget: SvgPicture.asset(
                            ImagePaths.icFrontHand,
                            colorFilter: ColorFilter.mode(
                              LinagoraRefColors.material().tertiary[30] ??
                                  LinagoraSysColors.material().onSurface,
                              BlendMode.srcIn,
                            ),
                          ),
                          onTap: () {
                            if (ignoredUsers.isNotEmpty) {
                              context.push('/rooms/security/blockedUsers');
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
                        LinagoraSysColors.material().surfaceTint,
                      ).opacityLayer3,
                      thickness: SettingsViewStyle.settingsItemDividerThikness,
                      height: SettingsViewStyle.settingsItemDividerHeight,
                    ),
                  ),
                ],
              ),
              // ListTile(
              //   leading: const Icon(Icons.password_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(
              //     L10n.of(context)!.changePassword,
              //   ),
              //   onTap: controller.changePasswordAccountAction,
              // ),
              // ListTile(
              //   leading: const Icon(Icons.mail_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(L10n.of(context)!.passwordRecovery),
              //   onTap: () => context.go('/3pid'),
              // ),
              if (Matrix.of(context).client.encryption != null) ...{
                if (PlatformInfos.isMobile)
                  Column(
                    children: [
                      Padding(
                        padding: SettingsViewStyle.bodySettingsScreenPadding,
                        child: SettingsItemBuilder(
                          title: L10n.of(context)!.appLock,
                          titleColor: Theme.of(
                            context,
                          ).colorScheme.onBackground,
                          leading: Icons.lock_outlined,
                          onTap: controller.setAppLockAction,
                          leadingIconColor:
                              LinagoraRefColors.material().tertiary[30],
                        ),
                      ),
                      Padding(
                        padding: SettingsViewStyle.settingsItemDividerPadding(),
                        child: Divider(
                          color: LinagoraStateLayer(
                            LinagoraSysColors.material().surfaceTint,
                          ).opacityLayer3,
                          thickness:
                              SettingsViewStyle.settingsItemDividerThikness,
                          height: SettingsViewStyle.settingsItemDividerHeight,
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: SettingsViewStyle.bodySettingsScreenPadding,
                  child: SettingsItemBuilder(
                    height: 116,
                    title: L10n.of(context)!.yourPublicKey,
                    titleColor: Theme.of(context).colorScheme.onBackground,
                    subtitle: Matrix.of(
                      context,
                    ).client.fingerprintKey.beautified,
                    subtitleStyle: LinagoraTextStyle.material().bodyMedium
                        .copyWith(
                          color: LinagoraRefColors.material().tertiary[30],
                          fontFamily: 'monospace',
                        ),
                    leading: Icons.notifications_outlined,
                    onTap: controller.copyPublicKey,
                    leadingIconColor: LinagoraRefColors.material().tertiary[30],
                    trailingWidget: InkWell(
                      onTap: controller.copyPublicKey,
                      child: const Icon(Icons.content_copy),
                    ),
                  ),
                ),
              },
              //TODO #1734: Remove dehydrate and delete account
              // ListTile(
              //   leading: const Icon(Icons.tap_and_play),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(
              //     L10n.of(context)!.dehydrate,
              //     style: const TextStyle(color: Colors.red),
              //   ),
              //   onTap: controller.dehydrateAction,
              // ),
              // ListTile(
              //   leading: const Icon(Icons.delete_outlined),
              //   trailing: const Icon(Icons.chevron_right_outlined),
              //   title: Text(
              //     L10n.of(context)!.deleteAccount,
              //     style: const TextStyle(color: Colors.red),
              //   ),
              //   onTap: controller.deleteAccountAction,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
