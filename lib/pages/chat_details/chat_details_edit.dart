import 'package:dartz/dartz.dart' hide State;
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/update_group_chat_success.dart';
import 'package:fluffychat/domain/usecase/room/update_group_chat_interactor.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_context_menu_actions.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/single_image_picker_mixin.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker_grid.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

class ChatDetailsEdit extends StatefulWidget {
  final String roomId;

  const ChatDetailsEdit({
    super.key,
    required this.roomId,
  });

  @override
  ChatDetailsEditController createState() => ChatDetailsEditController();
}

class ChatDetailsEditController extends State<ChatDetailsEdit>
    with PopupMenuWidgetMixin, CommonMediaPickerMixin, SingleImagePickerMixin {
  final updateGroupChatInteractor = getIt.get<UpdateGroupChatInteractor>();

  Room? room;

  final groupNameTextEditingController = TextEditingController();
  final groupNameFocusNode = FocusNode();

  final descriptionTextEditingController = TextEditingController();
  final descriptionFocusNode = FocusNode();

  AssetEntity? assetEntity;
  final avatarAssetEntityNotifier = ValueNotifier<AssetEntity?>(null);

  FilePickerResult? filePickerResult;
  final avatarFilePickerNotifier = ValueNotifier<FilePickerResult?>(null);

  final MenuController menuController = MenuController();

  final showSaveButtonNotifier = ValueNotifier<bool>(false);

  void onBack() {
    Navigator.of(context).pop();
  }

  List<PopupMenuItem> listContextMenuBuilder(
    BuildContext context,
  ) {
    final listAction = [
      ChatDetailsEditContextMenuActions.edit,
      ChatDetailsEditContextMenuActions.delete,
    ];
    return listAction.map((action) {
      return PopupMenuItem(
        padding: EdgeInsets.zero,
        child: popupItemByTwakeAppRouter(
          context,
          action.getTitle(context),
          iconAction: action.getIcon(),
          isClearCurrentPage: false,
          onCallbackAction: () {
            menuController.close();
            _handleActionContextMenu(action);
          },
        ),
      );
    }).toList();
  }

  void _handleActionContextMenu(ChatDetailsEditContextMenuActions action) {
    switch (action) {
      case ChatDetailsEditContextMenuActions.edit:
        _handleEditAvatarAction(context: context);
        break;
      case ChatDetailsEditContextMenuActions.delete:
        _handleRemoveAvatarAction();
        break;
    }
  }

  void _handleEditAvatarAction({required BuildContext context}) async {
    if (PlatformInfos.isWeb) {
      _getImageOnWeb(context);
      return;
    }
    final currentPermissionPhotos = await getCurrentMediaPermission();
    final currentPermissionCamera = await getCurrentCameraPermission();
    if (currentPermissionPhotos != null && currentPermissionCamera != null) {
      final imagePickerController = createImagePickerController();
      groupNameFocusNode.unfocus();
      showImagePickerBottomSheet(
        context,
        currentPermissionPhotos,
        currentPermissionCamera,
        imagePickerController,
      );
    }
  }

  ImagePickerGridController createImagePickerController() {
    final imagePickerController = ImagePickerGridController(
      AssetCounter(imagePickerMode: ImagePickerMode.single),
    );

    imagePickerController.addListener(() {
      final selectedAsset = imagePickerController.selectedAssets.firstOrNull;
      if (selectedAsset?.asset.type == AssetType.image) {
        if (!imagePickerController.pickFromCamera()) {
          Navigator.pop(context);
        }
        avatarAssetEntityNotifier.value = selectedAsset?.asset;
        imagePickerController.removeAllSelectedItem();
      }
    });

    return imagePickerController;
  }

  void _getImageOnWeb(
    BuildContext context,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    Logs().d(
      'ChatDetailsEditController::_getImageOnWeb(): FilePickerResult - $result',
    );
    if (result == null || result.files.single.bytes == null) {
      return;
    } else {
      avatarFilePickerNotifier.value = result;
      Logs().d(
        'ChatDetailsEditController::_getImageOnWeb(): AvatarWebNotifier - ${avatarFilePickerNotifier.value}',
      );
    }
  }

  void _handleRemoveAvatarAction() async {
    try {
      await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () => room!.setAvatar(null),
      );
    } catch (e, s) {
      Logs().e(
        'ChatDetailsEdit::__handleRemoveAvatarAction - Unable to remove avatar',
        e,
        s,
      );
    }
  }

  void handleSaveAction(BuildContext context) async {
    MatrixFile? avatar;
    if (PlatformInfos.isWeb && avatarFilePickerNotifier.value != null) {
      avatar = MatrixFile.fromMimeType(
        bytes: avatarFilePickerNotifier.value!.files.single.bytes,
        name: avatarFilePickerNotifier.value!.files.single.name,
        filePath: '',
      );
    } else if (avatarAssetEntityNotifier.value != null) {
      avatar = MatrixFile.fromMimeType(
        bytes: await avatarAssetEntityNotifier.value!.originBytes,
        name: avatarAssetEntityNotifier.value!.title!,
        filePath: '',
      );
    }

    final newDisplayName = groupNameTextEditingController.text != room!.name
        ? groupNameTextEditingController.text
        : null;

    final newDescription = descriptionTextEditingController.text != room!.topic
        ? descriptionTextEditingController.text
        : null;

    updateGroupChatInteractor
        .execute(
          room: room!,
          avatar: avatar,
          displayName: newDisplayName,
          description: newDescription,
        )
        .listen((event) => _handleUpdateGroupInfosOnEvents(context, event));
  }

  void _handleUpdateGroupInfosOnEvents(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    Logs().d('ChatDetailsEdit::_handleUpdateGroupInfosOnEvents()');
    event.fold(
      (failure) {
        Logs().e(
          'ChatDetailsEdit::_handleUpdateGroupInfosOnEvents() - failure: $failure',
        );
      },
      (success) {
        Logs().d(
          'ChatDetailsEdit::_handleUpdateGroupInfosOnEvents() - success: $success',
        );
        if (success is UpdateGroupChatSuccess) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  void dispose() {
    groupNameTextEditingController.dispose();
    groupNameFocusNode.dispose();
    avatarFilePickerNotifier.dispose();
    avatarAssetEntityNotifier.dispose();
    super.dispose();
  }

  void _setupGroupNameTextEditingController() {
    groupNameTextEditingController.text = room?.name ?? '';
    groupNameTextEditingController.addListener(() {
      if (groupNameTextEditingController.text != room?.name) {
        showSaveButtonNotifier.value = true;
      }
    });
  }

  void _setupDescriptionTextEditingController() {
    descriptionTextEditingController.text = room?.topic ?? '';
    descriptionTextEditingController.addListener(() {
      if (descriptionTextEditingController.text != room?.topic) {
        showSaveButtonNotifier.value = true;
      }
    });
  }

  void _listenToAvatarAssetEntityNotifier() {
    avatarAssetEntityNotifier.addListener(() {
      if (avatarAssetEntityNotifier.value != null) {
        showSaveButtonNotifier.value = true;
      }
    });
  }

  void _listenToAvatarFilePickerNotifier() {
    avatarFilePickerNotifier.addListener(() {
      if (avatarFilePickerNotifier.value != null) {
        showSaveButtonNotifier.value = true;
      }
    });
  }

  @override
  void initState() {
    room = Matrix.of(context).client.getRoomById(widget.roomId);
    _setupGroupNameTextEditingController();
    _setupDescriptionTextEditingController();
    _listenToAvatarAssetEntityNotifier();
    _listenToAvatarFilePickerNotifier();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatDetailEditViewStyle.fixedWidth,
      child: ChatDetailsEditView(
        this,
      ),
    );
  }
}
