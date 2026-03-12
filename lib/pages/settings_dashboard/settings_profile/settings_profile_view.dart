import 'package:fluffychat/config/go_routes/app_route_paths.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/capabilities/capabilities_extension.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_item.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_redirection_edit_button.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_mobile.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_style.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_web.dart';
import 'package:fluffychat/presentation/model/settings/settings_profile_presentation.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class SettingsProfileView extends StatelessWidget {
  final SettingsProfileController controller;
  final Capabilities? capabilities;

  static const ValueKey settingsProfileViewMobileKey = ValueKey(
    'settingsProfileViewMobile',
  );

  static const ValueKey settingsProfileViewWebKey = ValueKey(
    'settingsProfileViewWeb',
  );

  const SettingsProfileView({
    super.key,
    required this.controller,
    required this.capabilities,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = getIt.get<ResponsiveUtils>();
    final l10n = L10n.of(context)!;

    return Scaffold(
      appBar: TwakeAppBar(
        title: l10n.profile,
        leading: responsive.isMobile(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: SettingsProfileViewStyle.sizeIcon,
                ),
                onPressed: context.pop,
              )
            : const SizedBox.shrink(),
        actions: [
          if (PlatformInfos.isMobile)
            TwakeIconButton(
              icon: Icons.qr_code,
              iconColor: LinagoraSysColors.material().primary,
              onTap: () => context.go(AppRoutePaths.profileQrFull),
            ),
          ValueListenableBuilder(
            valueListenable: controller.isEditedProfileNotifier,
            builder: (context, edited, _) {
              if (!edited) {
                return SettingsProfileRedirectionEditButton(
                  capabilities: capabilities,
                );
              }
              return Padding(
                padding: SettingsProfileViewStyle.actionButtonPadding,
                child: InkWell(
                  borderRadius: .circular(
                    SettingsProfileViewStyle.borderRadius,
                  ),
                  onTap: () => controller.onUploadProfileAction(),
                  child: Padding(
                    padding: SettingsProfileViewStyle.paddingTextButton,
                    child: Text(
                      l10n.done,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        centerTitle: true,
        context: context,
        withDivider: true,
      ),
      backgroundColor: backgroundColor(responsive, context),
      body: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          const WidthPlatformBreakpoint(
            end: ResponsiveUtils.minDesktopWidth,
          ): SlotLayout.from(
            key: settingsProfileViewMobileKey,
            builder: (_) {
              return SettingsProfileViewMobile(
                client: controller.client,
                responsive: responsive,
                settingsProfileUIState: controller.pickAvatarUIState,
                onTapAvatar: controller.onTapAvatarInMobile,
                onTapMultipleAccountsButton: (multipleAccounts) => controller
                    .onBottomButtonTap(multipleAccounts: multipleAccounts),
                settingsMultiAccountsUIState:
                    controller.settingsMultiAccountsUIState,
                menuChildren: controller.listContextMenuBuilder(context),
                menuController: controller.menuController,
                animationController: controller.animationController,
                onAvatarInfoTap: controller.handleAvatarInfoTap,
                isExpandedAvatar: controller.isExpandedAvatar,
                settingsProfileOptions: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final settingsProfile =
                        controller.getListProfileMobile[index];

                    return SettingsProfileItemBuilder(
                      settingsProfileEnum: settingsProfile,
                      title: settingsProfile.getTitle(context),
                      settingsProfilePresentation: SettingsProfilePresentation(
                        settingsProfileType: settingsProfile
                            .getSettingsProfileType(),
                      ),
                      suffixIcon: settingsProfile.getTrailingIcon(),
                      leadingIcon: settingsProfile.getLeadingIcon(),
                      onEditRequested: () {
                        final focusNode = controller.getFocusNode(
                          settingsProfile,
                        );
                        focusNode?.requestFocus();
                      },
                      textEditingController: controller.getController(
                        settingsProfile,
                      ),
                      onCopyAction: () =>
                          controller.copyEventsAction(settingsProfile),
                      canEditDisplayName:
                          capabilities?.canEditDisplayName == true,
                      enableDivider:
                          index != (controller.getListProfileMobile.length - 1),
                    );
                  },
                  separatorBuilder: (_, _) {
                    return const SizedBox(height: 8);
                  },
                  itemCount: controller.getListProfileMobile.length,
                ),
                onImageLoaded: controller.updateMatrixFile,
                currentProfile: controller.currentProfile,
                canEditAvatar: capabilities?.canEditAvatar == true,
              );
            },
          ),
          const WidthPlatformBreakpoint(
            begin: ResponsiveUtils.minDesktopWidth,
          ): SlotLayout.from(
            key: settingsProfileViewWebKey,
            builder: (_) {
              return SettingsProfileViewWeb(
                currentProfile: controller.currentProfile,
                settingsProfileUIState: controller.pickAvatarUIState,
                client: controller.client,
                menuChildren: controller.listContextMenuBuilder(context),
                menuController: controller.menuController,
                basicInfoWidget: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final settingsProfile =
                        controller.getListProfileBasicInfo[index];

                    return SettingsProfileItemBuilder(
                      settingsProfileEnum: settingsProfile,
                      title: settingsProfile.getTitle(context),
                      settingsProfilePresentation: SettingsProfilePresentation(
                        settingsProfileType: settingsProfile
                            .getSettingsProfileType(),
                      ),
                      suffixIcon: settingsProfile.getTrailingIcon(),
                      onEditRequested: () {
                        final focusNode = controller.getFocusNode(
                          settingsProfile,
                        );
                        focusNode?.requestFocus();
                      },
                      textEditingController: controller.getController(
                        settingsProfile,
                      ),
                      canEditDisplayName:
                          capabilities?.canEditDisplayName == true,
                    );
                  },
                  separatorBuilder: (_, _) {
                    return const SizedBox(height: 16);
                  },
                  itemCount: controller.getListProfileBasicInfo.length,
                ),
                onImageLoaded: controller.updateMatrixFile,
                workIdentitiesInfoWidget: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final workIdentityInfo =
                        controller.getListProfileWorkIdentitiesInfo[index];

                    return SettingsProfileItemBuilder(
                      settingsProfileEnum: workIdentityInfo,
                      title: workIdentityInfo.getTitle(context),
                      settingsProfilePresentation: SettingsProfilePresentation(
                        settingsProfileType: workIdentityInfo
                            .getSettingsProfileType(),
                      ),
                      suffixIcon: workIdentityInfo.getTrailingIcon(),
                      onEditRequested: () {
                        final focusNode = controller.getFocusNode(
                          workIdentityInfo,
                        );
                        focusNode?.requestFocus();
                      },
                      textEditingController: controller.getController(
                        workIdentityInfo,
                      ),
                      onCopyAction: () =>
                          controller.copyEventsAction(workIdentityInfo),
                      canEditDisplayName:
                          capabilities?.canEditDisplayName == true,
                    );
                  },
                  separatorBuilder: (_, _) {
                    return const SizedBox(height: 16);
                  },
                  itemCount: controller.getListProfileWorkIdentitiesInfo.length,
                ),
                canEditAvatar: capabilities?.canEditAvatar == true,
              );
            },
          ),
        },
      ),
    );
  }

  Color backgroundColor(ResponsiveUtils responsive, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (PlatformInfos.isMobile) {
      return colorScheme.surface;
    } else {
      return responsive.isWebDesktop(context)
          ? colorScheme.surface
          : LinagoraSysColors.material().onPrimary;
    }
  }
}
