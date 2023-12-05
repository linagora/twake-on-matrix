import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

class ChatDetailsEditView extends StatelessWidget {
  final ChatDetailsEditController controller;

  const ChatDetailsEditView(
    this.controller, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.room == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(L10n.of(context)!.oopsSomethingWentWrong),
        ),
        body: Center(
          child: Text(L10n.of(context)!.youAreNoLongerParticipatingInThisChat),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: ChatDetailEditViewStyle.toolbarHeight(context),
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Padding(
          padding: ChatDetailEditViewStyle.navigationAppBarPadding,
          child: Row(
            children: [
              Padding(
                padding: ChatDetailEditViewStyle.backIconPadding,
                child: IconButton(
                  onPressed: controller.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Text(
                L10n.of(context)!.edit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              ValueListenableBuilder<bool>(
                valueListenable: controller.showSaveButtonNotifier,
                builder: (context, value, child) {
                  if (!value) {
                    return const SizedBox.shrink();
                  }
                  return child!;
                },
                child: Padding(
                  padding: ChatDetailEditViewStyle.doneIconPadding,
                  child: IconButton(
                    onPressed: () => controller.handleSaveAction(context),
                    icon: const Icon(Icons.done),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: ChatDetailEditViewStyle.editAvatarPadding,
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Padding(
                    padding: ChatDetailEditViewStyle.avatarPadding,
                    child: SizedBox(
                      width: ChatDetailEditViewStyle.avatarSize(context),
                      height: ChatDetailEditViewStyle.avatarSize(context),
                      child: Hero(
                        tag: 'content_banner',
                        child: _buildAvatar(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: MenuAnchor(
                      controller: controller.menuController,
                      builder: (
                        BuildContext context,
                        MenuController menuController,
                        Widget? child,
                      ) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          padding: ChatDetailEditViewStyle.editIconPadding,
                          child: ElevatedButton(
                            onPressed: () => {
                              menuController.isOpen
                                  ? menuController.close()
                                  : menuController.open(),
                            },
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all(
                                const CircleBorder(),
                              ),
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.all(8.0),
                              ),
                              iconColor: MaterialStateProperty.all(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                              backgroundColor: MaterialStateProperty.all(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: ChatDetailEditViewStyle.editIconSize,
                            ),
                          ),
                        );
                      },
                      menuChildren: controller.listContextMenuBuilder(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: ChatDetailEditViewStyle.avatarAndTextFieldsGap,
            ),
            Column(
              children: [
                _GroupNameField(controller: controller),
                const SizedBox(
                  height: ChatDetailEditViewStyle.textFieldsGap,
                ),
                _DescriptionField(controller: controller),
              ],
            ),
          ],
        ),
      ),
    );
  }

  StatelessWidget _buildAvatar() {
    return PlatformInfos.isMobile
        ? _AvatarForMobileBuilder(
            avatarMobileNotifier: controller.avatarAssetEntityNotifier,
            room: controller.room!,
          )
        : _AvatarForWebBuilder(
            avatarWebNotifier: controller.avatarFilePickerNotifier,
            room: controller.room!,
          );
  }
}

class _BuildInitialAvatar extends StatelessWidget {
  final Room room;

  const _BuildInitialAvatar({
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Avatar(
      fontSize: ChatDetailEditViewStyle.avatarFontSize,
      mxContent: room.avatar,
      name: room.getLocalizedDisplayname(
        MatrixLocals(L10n.of(context)!),
      ),
      size: ChatDetailEditViewStyle.avatarSize(context),
    );
  }
}

class _AvatarForMobileBuilder extends StatelessWidget {
  final ValueNotifier<AssetEntity?> avatarMobileNotifier;
  final Room room;

  const _AvatarForMobileBuilder({
    required this.avatarMobileNotifier,
    required this.room,
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
              ChatDetailEditViewStyle.avatarRadiusForMobile,
            ),
            child: AssetEntityImage(
              value,
              thumbnailSize: const ThumbnailSize(
                ChatDetailEditViewStyle.thumbnailSizeWidth,
                ChatDetailEditViewStyle.thumbnailSizeHeight,
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
      child: _BuildInitialAvatar(room: room),
    );
  }
}

class _AvatarForWebBuilder extends StatelessWidget {
  final ValueNotifier<FilePickerResult?> avatarWebNotifier;
  final Room room;

  const _AvatarForWebBuilder({
    required this.avatarWebNotifier,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: avatarWebNotifier,
      builder: (context, value, child) {
        if (value == null || value.files.single.bytes == null) {
          return child!;
        }
        return ClipOval(
          child: SizedBox.fromSize(
            size: const Size.fromRadius(
              ChatDetailEditViewStyle.avatarRadiusForWeb,
            ),
            child: Image.memory(
              value.files.single.bytes!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error_outline),
                );
              },
            ),
          ),
        );
      },
      child: _BuildInitialAvatar(room: room),
    );
  }
}

class _GroupNameField extends StatelessWidget {
  const _GroupNameField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final ChatDetailsEditController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ChatDetailEditViewStyle.textFieldPadding,
      child: TextField(
        controller: controller.groupNameTextEditingController,
        focusNode: controller.groupNameFocusNode,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.shadow),
          ),
          labelText: L10n.of(context)!.widgetName,
          labelStyle: ChatDetailEditViewStyle.textFieldLabelStyle(context),
          hintText: L10n.of(context)!.enterGroupName,
          hintStyle: ChatDetailEditViewStyle.textFieldHintStyle(context),
          contentPadding: ChatDetailEditViewStyle.contentPadding,
        ),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final ChatDetailsEditController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ChatDetailEditViewStyle.textFieldPadding,
      child: Column(
        children: [
          TextField(
            controller: controller.descriptionTextEditingController,
            focusNode: controller.descriptionFocusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.shadow),
              ),
              labelText: L10n.of(context)!.description,
              labelStyle: ChatDetailEditViewStyle.textFieldLabelStyle(context),
              hintText: L10n.of(context)!.description,
              hintStyle: ChatDetailEditViewStyle.textFieldHintStyle(context),
              contentPadding: ChatDetailEditViewStyle.contentPadding,
            ),
          ),
          const SizedBox(
            height: 2.0,
          ),
          Text(
            L10n.of(context)!.descriptionHelper,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
