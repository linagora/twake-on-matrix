import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/get_clients_ui_state.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_mobile_style.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/model/pick_avatar_state.dart';
import 'package:fluffychat/presentation/multiple_account/twake_chat_presentation_account.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_style.dart';
import 'package:fluffychat/widgets/stream_image_view.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef OnTapMultipleAccountsButton = void Function(
  List<TwakeChatPresentationAccount> multipleAccounts,
);

class SettingsProfileViewMobile extends StatelessWidget {
  final ValueNotifier<Either<Failure, Success>> settingsProfileUIState;
  final OnTapMultipleAccountsButton onTapMultipleAccountsButton;
  final Widget settingsProfileOptions;
  final VoidCallback? onTapAvatar;
  final List<Widget>? menuChildren;
  final MenuController? menuController;
  final ValueNotifier<Either<Failure, Success>> settingsMultiAccountsUIState;
  final Client client;
  final Function(MatrixFile) onImageLoaded;
  final ValueNotifier<Profile?> currentProfile;

  const SettingsProfileViewMobile({
    super.key,
    required this.settingsProfileOptions,
    required this.currentProfile,
    required this.onTapAvatar,
    required this.settingsProfileUIState,
    required this.client,
    required this.onTapMultipleAccountsButton,
    required this.settingsMultiAccountsUIState,
    required this.onImageLoaded,
    this.menuChildren,
    this.menuController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
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
                        if (success is GetAvatarOnMobileUIStateSuccess &&
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
                        if (success is GetAvatarOnWebUIStateSuccess &&
                            PlatformInfos.isWeb) {
                          if (success.matrixFile?.readStream == null) {
                            return child!;
                          }
                          return ClipOval(
                            child: SizedBox.fromSize(
                              size: const Size.fromRadius(
                                AvatarStyle.defaultSize,
                              ),
                              child: StreamImageViewer(
                                matrixFile: success.matrixFile!,
                                onImageLoaded: onImageLoaded,
                              ),
                            ),
                          );
                        }
                        return child!;
                      },
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: currentProfile,
                      builder: (context, profile, _) {
                        final displayName = profile?.displayName ??
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
                            mxContent: profile?.avatarUrl,
                            name: displayName,
                            size: SettingsProfileViewMobileStyle.avatarSize,
                            fontSize:
                                SettingsProfileViewMobileStyle.avatarFontSize,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: SettingsProfileViewMobileStyle.positionedBottomSize,
                    right: SettingsProfileViewMobileStyle.positionedRightSize,
                    child: MenuAnchor(
                      controller: menuController,
                      style: MenuStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          PopupMenuWidgetStyle.defaultMenuColor(context),
                        ),
                      ),
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
        if (PlatformInfos.isMobile)
          ValueListenableBuilder(
            valueListenable: settingsMultiAccountsUIState,
            builder: (context, uiState, child) => uiState.fold(
              (failure) => child!,
              (success) {
                if (success is GetClientsLoadingUIState) {
                  return Container(
                    width: double.infinity,
                    height: SettingsProfileViewMobileStyle.bottomButtonHeight,
                    padding: SettingsProfileViewMobileStyle.paddingBottomButton,
                    margin: SettingsProfileViewMobileStyle.marginBottomButton,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        SettingsProfileViewMobileStyle.bottomButtonRadius,
                      ),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: SettingsProfileViewMobileStyle.indicatorScale,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: SettingsProfileViewMobileStyle
                                .indicatorStrokeWidth,
                          ),
                        ),
                        SettingsProfileViewMobileStyle.paddingIconAndText,
                        Text(
                          L10n.of(context)!.loadingPleaseWait,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                if (success is GetClientsSuccessUIState) {
                  return InkWell(
                    onTap: () => onTapMultipleAccountsButton.call(
                      success.multipleAccounts,
                    ),
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      height: SettingsProfileViewMobileStyle.bottomButtonHeight,
                      padding:
                          SettingsProfileViewMobileStyle.paddingBottomButton,
                      margin: SettingsProfileViewMobileStyle.marginBottomButton,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          SettingsProfileViewMobileStyle.bottomButtonRadius,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            success.haveMultipleAccounts
                                ? Icons.group_outlined
                                : Icons.person_add_alt_outlined,
                            size: SettingsProfileViewMobileStyle.iconSize,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          SettingsProfileViewMobileStyle.paddingIconAndText,
                          Text(
                            success.haveMultipleAccounts
                                ? L10n.of(context)!.switchAccounts
                                : L10n.of(context)!.addAnotherAccount,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return child!;
              },
            ),
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}
