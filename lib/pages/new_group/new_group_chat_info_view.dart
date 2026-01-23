import 'package:byte_converter/byte_converter.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info_style.dart';
import 'package:fluffychat/pages/new_group/new_group_info_controller.dart';
import 'package:fluffychat/pages/new_group/widget/expansion_participants_list.dart';
import 'package:fluffychat/presentation/model/pick_avatar_state.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/stream_image_view.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class NewGroupChatInfoView extends StatelessWidget {
  final NewGroupChatInfoController newGroupInfoController;

  const NewGroupChatInfoView(
    this.newGroupInfoController, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: _buildAppBar(context),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: NewGroupChatInfoStyle.profilePadding,
                      child: _buildChangeProfileWidget(context),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      L10n.of(context)!.addAPhoto,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    Text(
                      L10n.of(context)!.maxImageSize(
                        AppConfig
                            .defaultMaxUploadAvtarSizeInBytes.bytes.megaBytes
                            .toInt(),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: LinagoraRefColors.material().neutral[40],
                          ),
                    ),
                    const SizedBox(height: 32),
                    _buildGroupNameTextField(context),
                    const SizedBox(height: 16),
                    _EncryptionSettingTile(
                      enableEncryptionNotifier:
                          newGroupInfoController.enableEncryptionNotifier,
                      onChanged: (value) {
                        newGroupInfoController.toggleEnableEncryption();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Padding(
          padding: NewGroupChatInfoStyle.padding,
          child: ExpansionParticipantsList(
            contactsList: newGroupInfoController.contactsList ?? {},
          ),
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: newGroupInfoController.haveGroupNameNotifier,
        builder: (context, value, child) {
          if (!value) {
            return const SizedBox.shrink();
          }
          return child!;
        },
        child: ValueListenableBuilder<Either<Failure, Success>?>(
          valueListenable: newGroupInfoController.createRoomStateNotifier,
          builder: (context, _, __) {
            return ValueListenableBuilder<Either<Failure, Success>?>(
              valueListenable: newGroupInfoController.inviteUserStateNotifier,
              builder: (context, _, ___) {
                if (newGroupInfoController.isCreatingRoom) {
                  return const TwakeFloatingActionButton(
                    customIcon: SizedBox(child: CircularProgressIndicator()),
                  );
                }
                return TwakeFloatingActionButton(
                  icon: Icons.done,
                  onTap: () => newGroupInfoController.moveToGroupChatScreen(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(
        NewGroupChatInfoStyle.toolbarHeight,
      ),
      child: TwakeAppBar(
        title: L10n.of(context)!.newGroupChat,
        context: context,
        centerTitle: true,
        withDivider: true,
        enableLeftTitle: true,
        isDialog: true,
        leading: TwakeIconButton(
          paddingAll: 8,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => Navigator.of(context).pop(),
          icon: Icons.arrow_back_ios,
        ),
      ),
    );
  }

  Widget _buildChangeProfileWidget(BuildContext context) {
    return InkWell(
      onTap: () =>
          newGroupInfoController.showImagesPickerAction(context: context),
      customBorder: const CircleBorder(),
      child: Container(
        width: NewGroupChatInfoStyle.profileSize(context),
        height: NewGroupChatInfoStyle.profileSize(context),
        decoration: BoxDecoration(
          color: LinagoraRefColors.material().tertiary[60],
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: NewGroupChatInfoStyle.responsive.isMobile(context)
            ? _AvatarForMobileBuilder(
                avatarMobileNotifier:
                    newGroupInfoController.avatarAssetEntityNotifier,
              )
            : _AvatarForWebBuilder(
                avatarWebNotifier: newGroupInfoController.pickAvatarUIState,
                onImageLoaded: newGroupInfoController.updateAvatarFilePicker,
              ),
      ),
    );
  }

  Widget _buildGroupNameTextField(BuildContext context) {
    return Padding(
      padding: NewGroupChatInfoStyle.groupNameTextFieldPadding,
      child: ValueListenableBuilder(
        valueListenable: newGroupInfoController.createRoomStateNotifier,
        builder: (context, value, child) {
          return ValueListenableBuilder(
            valueListenable:
                newGroupInfoController.groupNameTextEditingController,
            builder: (context, value, _) {
              return TextField(
                controller:
                    newGroupInfoController.groupNameTextEditingController,
                focusNode: newGroupInfoController.groupNameFocusNode,
                enabled: !newGroupInfoController.isCreatingRoom,
                decoration: InputDecoration(
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: LinagoraSysColors.material().error,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.shadow),
                  ),
                  errorText: newGroupInfoController.getErrorMessage(
                    newGroupInfoController.groupNameTextEditingController.text,
                  ),
                  errorStyle:
                      TextStyle(color: LinagoraSysColors.material().error),
                  labelText: L10n.of(context)!.widgetName,
                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  hintText: L10n.of(context)!.enterGroupName,
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: LinagoraRefColors.material().neutral[60],
                      ),
                  contentPadding: NewGroupChatInfoStyle.contentPadding,
                ),
                contextMenuBuilder: mobileTwakeContextMenuBuilder,
              );
            },
          );
        },
      ),
    );
  }
}

class _AvatarForMobileBuilder extends StatelessWidget {
  final ValueNotifier<AssetEntity?> avatarMobileNotifier;

  const _AvatarForMobileBuilder({
    required this.avatarMobileNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: avatarMobileNotifier,
      builder: (context, value, child) {
        if (value == null) {
          return child!;
        }
        return ClipOval(
          child: SizedBox.fromSize(
            size: const Size.fromRadius(
              NewGroupChatInfoStyle.avatarRadiusForMobile,
            ),
            child: AssetEntityImage(
              value,
              thumbnailSize: const ThumbnailSize(
                NewGroupChatInfoStyle.thumbnailSizeWidth,
                NewGroupChatInfoStyle.thumbnailSizeHeight,
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
      },
      child: Icon(
        Icons.camera_alt_outlined,
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

class _AvatarForWebBuilder extends StatelessWidget {
  final ValueNotifier<Either<Failure, Success>> avatarWebNotifier;
  final Function(MatrixFile) onImageLoaded;

  const _AvatarForWebBuilder({
    required this.avatarWebNotifier,
    required this.onImageLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: avatarWebNotifier,
      builder: (context, uiState, child) => uiState.fold(
        (failure) {
          if (failure is GetAvatarBigSizeUIStateFailure ||
              failure is GetAvatarUIStateFailure) {
            return child!;
          }
          return const SizedBox();
        },
        (success) {
          if (success is GetAvatarOnWebUIStateSuccess) {
            return ClipOval(
              child: SizedBox.fromSize(
                size: const Size.fromRadius(
                  NewGroupChatInfoStyle.avatarRadiusForWeb,
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
      child: Icon(
        Icons.add_a_photo_outlined,
        color: LinagoraSysColors.material().onPrimary,
      ),
    );
  }
}

class _EncryptionSettingTile extends StatelessWidget {
  final ValueNotifier<bool> enableEncryptionNotifier;

  final ValueChanged<bool?>? onChanged;

  const _EncryptionSettingTile({
    required this.enableEncryptionNotifier,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, right: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SvgPicture.asset(
              ImagePaths.icE2EEncryptionMessageIndicator,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                LinagoraRefColors.material().tertiary[30] ?? Colors.transparent,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    L10n.of(context)!.enableEncryption,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          letterSpacing: 0.15,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(height: 4.0),
                ValueListenableBuilder<bool>(
                  valueListenable: enableEncryptionNotifier,
                  builder: (context, isEnable, child) {
                    return Column(
                      children: [
                        Text(
                          L10n.of(context)!.encryptionMessage,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                letterSpacing: 0.5,
                                color: LinagoraSysColors.material().tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        AnimatedSize(
                          alignment: Alignment.topCenter,
                          duration: const Duration(milliseconds: 50),
                          child: isEnable
                              ? Text(
                                  L10n.of(context)!.encryptionWarning,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        letterSpacing: 0.4,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: enableEncryptionNotifier,
            builder: (context, isEnable, child) {
              return Checkbox(
                value: isEnable,
                onChanged: (value) => onChanged?.call(value),
                side: WidgetStateBorderSide.resolveWith(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return const BorderSide(
                        color: Colors.transparent,
                        width: 2.0,
                      );
                    }
                    return BorderSide(
                      color: LinagoraRefColors.material().tertiary[30] ??
                          Colors.transparent,
                      width: 2.0,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
