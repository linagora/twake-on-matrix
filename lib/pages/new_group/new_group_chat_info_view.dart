import 'package:byte_converter/byte_converter.dart';
import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_style.dart';
import 'package:twake_chat/pages/new_group/new_group_info_controller.dart';
import 'package:twake_chat/pages/new_group/widget/expansion_participants_list.dart';
import 'package:twake_chat/presentation/model/pick_avatar_state.dart';
import 'package:twake_chat/widgets/app_bars/twake_app_bar.dart';
import 'package:twake_chat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:twake_chat/widgets/stream_image_view.dart';
import 'package:twake_chat/widgets/twake_components/twake_fab.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class NewGroupChatInfoView extends StatelessWidget {
  final NewGroupChatInfoController newGroupInfoController;

  final bool isPublicGroupsEnabled;

  const NewGroupChatInfoView(
    this.newGroupInfoController, {
    super.key,
    required this.isPublicGroupsEnabled,
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
                            .defaultMaxUploadAvtarSizeInBytes
                            .bytes
                            .megaBytes
                            .toInt(),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LinagoraRefColors.material().neutral[40],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildGroupNameTextField(context),
                    if (!newGroupInfoController.isFeed) ...[
                      const SizedBox(height: 16),
                      _GroupPrivacySettings(
                        controller: newGroupInfoController,
                        isPublicGroupsEnabled: isPublicGroupsEnabled,
                      ),
                    ],
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
    final l10n = L10n.of(context)!;
    return PreferredSize(
      preferredSize: const Size.fromHeight(NewGroupChatInfoStyle.toolbarHeight),
      child: TwakeAppBar(
        title: newGroupInfoController.isFeed ? l10n.newFeed : l10n.newGroupChat,
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
    final l10n = L10n.of(context)!;
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
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.shadow,
                    ),
                  ),
                  errorText: newGroupInfoController.getErrorMessage(
                    newGroupInfoController.groupNameTextEditingController.text,
                  ),
                  errorStyle: TextStyle(
                    color: LinagoraSysColors.material().error,
                  ),
                  labelText: l10n.widgetName,
                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  hintText: newGroupInfoController.isFeed
                      ? l10n.enterFeedName
                      : l10n.enterGroupName,
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

  const _AvatarForMobileBuilder({required this.avatarMobileNotifier});

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
                return const Center(child: Icon(Icons.error_outline));
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

class _GroupPrivacySettings extends StatelessWidget {
  final NewGroupChatInfoController controller;

  final bool isPublicGroupsEnabled;

  const _GroupPrivacySettings({
    required this.controller,
    required this.isPublicGroupsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isPublicNotifier,
      builder: (context, isPublic, _) {
        return Column(
          children: [
            if (isPublicGroupsEnabled)
              LinagoraSettingItem.selectable(
                title: L10n.of(context)!.makeChatPublic,
                subtitle: L10n.of(context)!.makeChatPublicDescription,
                subtitleMaxLines: null,
                value: isPublic,
                onChanged: controller.setPublic,
              ),
            if (isPublic)
              ValueListenableBuilder<bool>(
                valueListenable: controller.isServerLimitedNotifier,
                builder: (context, isServerLimited, _) {
                  return LinagoraSettingItem.selectable(
                    title: L10n.of(
                      context,
                    )!.groupPrivacyLimitToServer(controller.serverName),
                    subtitle: L10n.of(
                      context,
                    )!.groupPrivacyLimitToServerDescription,
                    subtitleMaxLines: null,
                    value: isServerLimited,
                    onChanged: controller.setServerLimited,
                  );
                },
              )
            else
              _EncryptionSettingTile(
                enableEncryptionNotifier: controller.enableEncryptionNotifier,
                onChanged: (_) => controller.toggleEnableEncryption(),
              ),
          ],
        );
      },
    );
  }
}

class _EncryptionSettingTile extends StatelessWidget {
  final ValueNotifier<bool> enableEncryptionNotifier;

  final ValueChanged<bool>? onChanged;

  const _EncryptionSettingTile({
    required this.enableEncryptionNotifier,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: enableEncryptionNotifier,
      builder: (context, isEnabled, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinagoraSettingItem.selectable(
              title: L10n.of(context)!.enableEncryption,
              subtitle: L10n.of(context)!.encryptionMessage,
              subtitleMaxLines: null,
              value: isEnabled,
              onChanged: onChanged,
            ),
            if (isEnabled)
              Padding(
                padding: const EdgeInsets.only(
                  left: LinagoraSpacing.base * 3,
                  right: LinagoraSpacing.base * 3,
                  bottom: LinagoraSpacing.base * 2,
                ),
                child: Text(
                  L10n.of(context)!.encryptionWarning,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.4,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
