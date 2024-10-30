import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_item.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_mobile.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_style.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_web.dart';
import 'package:fluffychat/presentation/model/settings/settings_profile_presentation.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class SettingsProfileView extends StatelessWidget {
  final SettingsProfileController controller;

  static const ValueKey settingsProfileViewMobileKey =
      ValueKey('settingsProfileViewMobile');

  static const ValueKey settingsProfileViewWebKey =
      ValueKey('settingsProfileViewWeb');

  const SettingsProfileView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = getIt.get<ResponsiveUtils>();
    return Scaffold(
      appBar: TwakeAppBar(
        title: L10n.of(context)!.profile,
        leading: responsive.isMobile(context)
            ? IconButton(
                icon: const Icon(
                  Icons.chevron_left_outlined,
                  size: SettingsProfileViewStyle.sizeIcon,
                ),
                onPressed: () => context.pop(),
              )
            : const SizedBox.shrink(),
        actions: [
          ValueListenableBuilder(
            valueListenable: controller.isEditedProfileNotifier,
            builder: (context, edited, _) {
              if (!edited) return const SizedBox();
              return Padding(
                padding: SettingsProfileViewStyle.actionButtonPadding,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    SettingsProfileViewStyle.borderRadius,
                  ),
                  onTap: () => controller.onUploadProfileAction(),
                  child: Padding(
                    padding: SettingsProfileViewStyle.paddingTextButton,
                    child: Text(
                      L10n.of(context)!.done,
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
      backgroundColor: responsive.isWebDesktop(context)
          ? Theme.of(context).colorScheme.surface
          : LinagoraSysColors.material().onPrimary,
      body: Padding(
        padding: SettingsProfileViewStyle.paddingBody,
        child: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            const WidthPlatformBreakpoint(
              end: ResponsiveUtils.minDesktopWidth,
            ): SlotLayout.from(
              key: settingsProfileViewMobileKey,
              builder: (_) {
                return SettingsProfileViewMobile(
                  client: controller.client,
                  settingsProfileUIState: controller.pickAvatarUIState,
                  onTapAvatar: controller.onTapAvatarInMobile,
                  onTapMultipleAccountsButton: (multipleAccounts) =>
                      controller.onBottomButtonTap(
                    multipleAccounts: multipleAccounts,
                  ),
                  settingsMultiAccountsUIState:
                      controller.settingsMultiAccountsUIState,
                  menuChildren: controller.listContextMenuBuilder(context),
                  menuController: controller.menuController,
                  settingsProfileOptions: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return SettingsProfileItemBuilder(
                        settingsProfileEnum:
                            controller.getListProfileMobile[index],
                        title: controller.getListProfileMobile[index]
                            .getTitle(context),
                        settingsProfileUIState: controller.pickAvatarUIState,
                        settingsProfilePresentation:
                            SettingsProfilePresentation(
                          settingsProfileType: controller
                              .getListProfileMobile[index]
                              .getSettingsProfileType(),
                        ),
                        suffixIcon: controller.getListProfileMobile[index]
                            .getTrailingIcon(),
                        leadingIcon: controller.getListProfileMobile[index]
                            .getLeadingIcon(),
                        focusNode: controller.getFocusNode(
                          controller.getListProfileMobile[index],
                        ),
                        textEditingController: controller.getController(
                          controller.getListProfileMobile[index],
                        ),
                        onChange: (_, settingsProfileEnum) {
                          controller
                              .handleTextEditOnChange(settingsProfileEnum);
                        },
                        onCopyAction: () => controller.copyEventsAction(
                          controller.getListProfileMobile[index],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 16);
                    },
                    itemCount: controller.getListProfileMobile.length,
                  ),
                  onImageLoaded: controller.updateMatrixFile,
                  currentProfile: controller.currentProfile,
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
                      return SettingsProfileItemBuilder(
                        settingsProfileUIState: controller.pickAvatarUIState,
                        settingsProfileEnum:
                            controller.getListProfileBasicInfo[index],
                        title: controller.getListProfileBasicInfo[index]
                            .getTitle(context),
                        settingsProfilePresentation:
                            SettingsProfilePresentation(
                          settingsProfileType: controller
                              .getListProfileBasicInfo[index]
                              .getSettingsProfileType(),
                        ),
                        suffixIcon: controller.getListProfileBasicInfo[index]
                            .getTrailingIcon(),
                        focusNode: controller.getFocusNode(
                          controller.getListProfileBasicInfo[index],
                        ),
                        textEditingController: controller.getController(
                          controller.getListProfileBasicInfo[index],
                        ),
                        onChange: (_, settingsProfileEnum) {
                          controller
                              .handleTextEditOnChange(settingsProfileEnum);
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 16);
                    },
                    itemCount: controller.getListProfileBasicInfo.length,
                  ),
                  onImageLoaded: controller.updateMatrixFile,
                  workIdentitiesInfoWidget: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return SettingsProfileItemBuilder(
                        settingsProfileUIState: controller.pickAvatarUIState,
                        settingsProfileEnum:
                            controller.getListProfileWorkIdentitiesInfo[index],
                        title: controller
                            .getListProfileWorkIdentitiesInfo[index]
                            .getTitle(context),
                        settingsProfilePresentation:
                            SettingsProfilePresentation(
                          settingsProfileType: controller
                              .getListProfileWorkIdentitiesInfo[index]
                              .getSettingsProfileType(),
                        ),
                        suffixIcon: controller
                            .getListProfileWorkIdentitiesInfo[index]
                            .getTrailingIcon(),
                        focusNode: controller.getFocusNode(
                          controller.getListProfileWorkIdentitiesInfo[index],
                        ),
                        textEditingController: controller.getController(
                          controller.getListProfileWorkIdentitiesInfo[index],
                        ),
                        onChange: (_, settingsProfileEnum) {
                          controller
                              .handleTextEditOnChange(settingsProfileEnum);
                        },
                        onCopyAction: () => controller.copyEventsAction(
                          controller.getListProfileWorkIdentitiesInfo[index],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 16);
                    },
                    itemCount: controller.getListProfileBasicInfo.length,
                  ),
                );
              },
            ),
          },
        ),
      ),
    );
  }
}
