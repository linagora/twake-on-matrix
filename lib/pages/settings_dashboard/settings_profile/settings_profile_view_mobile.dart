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

class SettingsProfileViewMobile extends StatelessWidget {
  final ValueNotifier<Either<Failure, Success>> settingsProfileUIState;
  final Widget settingsProfileOptions;
  final VoidCallback? onTapAvatar;
  final List<Widget>? menuChildren;
  final MenuController? menuController;
  final Client client;

  const SettingsProfileViewMobile({
    super.key,
    required this.settingsProfileOptions,
    required this.onTapAvatar,
    required this.settingsProfileUIState,
    required this.client,
    this.menuChildren,
    this.menuController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              SizedBox(
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
                            thumbnailSize: ThumbnailSize(
                              SettingsProfileViewMobileStyle.thumbnailSize,
                              SettingsProfileViewMobileStyle.thumbnailSize,
                            ),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress != null &&
                                  loadingProgress.cumulativeBytesLoaded !=
                                      loadingProgress.expectedTotalBytes) {
                                return const Center(
                                  child: CircularProgressIndicator.adaptive(),
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
                        shadowColor: Theme.of(context).appBarTheme.shadowColor,
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
                        padding: SettingsProfileViewMobileStyle.editIconPadding,
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
    );
  }
}
