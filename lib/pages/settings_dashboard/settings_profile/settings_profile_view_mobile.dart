import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/get_avatar_ui_state.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/get_profile_ui_state.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_mobile_style.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SettingsProfileViewMobile extends StatelessWidget {
  final ValueNotifier<Either<Failure, Success>> settingsProfileUIState;
  final VoidCallback onBottomButtonTap;
  final Widget settingsProfileOptions;
  final VoidCallback? onTapAvatar;
  final List<Widget>? menuChildren;
  final MenuController? menuController;
  final ValueNotifier<bool> haveMultipleAccountsNotifier;
  final Client client;

  const SettingsProfileViewMobile({
    super.key,
    required this.settingsProfileOptions,
    required this.onTapAvatar,
    required this.settingsProfileUIState,
    required this.client,
    required this.onBottomButtonTap,
    required this.haveMultipleAccountsNotifier,
    this.menuChildren,
    this.menuController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            Divider(
              height: SettingsProfileViewMobileStyle.dividerHeight,
              color: LinagoraStateLayer(
                LinagoraSysColors.material().surfaceTint,
              ).opacityLayer3,
            ),
            Padding(
              padding: SettingsProfileViewMobileStyle.padding,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  const SizedBox(
                    width: SettingsProfileViewMobileStyle.widthSize,
                  ),
                  ValueListenableBuilder(
                    valueListenable: settingsProfileUIState,
                    builder: (context, uiState, child) => uiState.fold(
                      (failure) => child!,
                      (success) {
                        if (success is GetAvatarInStreamUIStateSuccess &&
                            PlatformInfos.isMobile) {
                          if (success.assetEntity == null) {
                            return child!;
                          }
                          return ClipOval(
                            child: SizedBox.fromSize(
                              size: const Size.fromRadius(
                                AvatarStyle.defaultSize,
                              ),
                              child: AssetEntityImage(
                                width: AvatarStyle.defaultSize,
                                height: AvatarStyle.defaultSize,
                                success.assetEntity!,
                                thumbnailSize: const ThumbnailSize(
                                  SettingsProfileViewMobileStyle.thumbnailSize,
                                  SettingsProfileViewMobileStyle.thumbnailSize,
                                ),
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress != null &&
                                      loadingProgress.cumulativeBytesLoaded !=
                                          loadingProgress.expectedTotalBytes) {
                                    return const Center(
                                      child:
                                          CircularProgressIndicator.adaptive(),
                                    );
                                  }
                                  return child;
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error_outline),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        if (success is GetAvatarInBytesUIStateSuccess &&
                            PlatformInfos.isWeb) {
                          if (success.filePickerResult == null ||
                              success.filePickerResult?.files.single.bytes ==
                                  null) {
                            return child!;
                          }
                          return ClipOval(
                            child: SizedBox.fromSize(
                              size: const Size.fromRadius(
                                AvatarStyle.defaultSize,
                              ),
                              child: Image.memory(
                                success.filePickerResult!.files.single.bytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error_outline),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        if (success is GetProfileUIStateSuccess) {
                          final displayName = success.profile.displayName ??
                              client.mxid(context).localpart ??
                              client.mxid(context);
                          return Material(
                            elevation: Theme.of(context)
                                    .appBarTheme
                                    .scrolledUnderElevation ??
                                4,
                            shadowColor:
                                Theme.of(context).appBarTheme.shadowColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(
                                AvatarStyle.defaultSize,
                              ),
                            ),
                            child: Avatar(
                              mxContent: success.profile.avatarUrl,
                              name: displayName,
                              size: SettingsProfileViewMobileStyle.avatarSize,
                              fontSize:
                                  SettingsProfileViewMobileStyle.avatarFontSize,
                            ),
                          );
                        }
                        return child!;
                      },
                    ),
                    child: const SizedBox.shrink(),
                  ),
                  Positioned(
                    bottom: SettingsProfileViewMobileStyle.positionedBottomSize,
                    right: SettingsProfileViewMobileStyle.positionedRightSize,
                    child: MenuAnchor(
                      controller: menuController,
                      builder: (
                        BuildContext context,
                        MenuController menuController,
                        Widget? child,
                      ) {
                        return GestureDetector(
                          onTap: () {
                            if (PlatformInfos.isWeb) {
                              menuController.isOpen
                                  ? menuController.close()
                                  : menuController.open();
                            } else {
                              onTapAvatar?.call();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(
                                SettingsProfileViewMobileStyle.avatarSize,
                              ),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onPrimary,
                                width: SettingsProfileViewMobileStyle
                                    .iconEditBorderWidth,
                              ),
                            ),
                            padding:
                                SettingsProfileViewMobileStyle.editIconPadding,
                            child: Icon(
                              Icons.edit,
                              size: SettingsProfileViewMobileStyle.iconEditSize,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        );
                      },
                      menuChildren: menuChildren ?? [],
                    ),
                  ),
                ],
              ),
            ),
            settingsProfileOptions,
          ],
        ),
        const Expanded(child: SizedBox()),
        InkWell(
          onTap: onBottomButtonTap,
          child: Container(
            width: double.infinity,
            height: SettingsProfileViewMobileStyle.bottomButtonHeight,
            padding: SettingsProfileViewMobileStyle.paddingBottomButton,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SettingsProfileViewMobileStyle.bottomButtonRadius,
              ),
              color: Theme.of(context).colorScheme.primary,
            ),
            alignment: Alignment.center,
            child: ValueListenableBuilder(
              valueListenable: haveMultipleAccountsNotifier,
              builder: (context, haveMultipleAccounts, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      haveMultipleAccounts
                          ? Icons.group_outlined
                          : Icons.person_add_alt_outlined,
                      size: SettingsProfileViewMobileStyle.iconSize,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    SettingsProfileViewMobileStyle.paddingIconAndText,
                    Text(
                      haveMultipleAccounts
                          ? L10n.of(context)!.switchAccounts
                          : L10n.of(context)!.addAnotherAccount,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        SettingsProfileViewMobileStyle.paddingBottomBottomButton,
      ],
    );
  }
}
