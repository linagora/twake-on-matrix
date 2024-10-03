import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/update_group_chat_failure.dart';
import 'package:fluffychat/domain/app_state/room/update_group_chat_success.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/domain/usecase/room/update_group_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_interactor.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_context_menu_actions.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/leave_chat_mixin.dart';
import 'package:fluffychat/presentation/mixins/pick_avatar_mixin.dart';
import 'package:fluffychat/presentation/mixins/single_image_picker_mixin.dart';
import 'package:fluffychat/presentation/model/pick_avatar_state.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker_grid.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart' as photo_manager;

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
    with
        PopupMenuWidgetMixin,
        CommonMediaPickerMixin,
        SingleImagePickerMixin,
        LeaveChatMixin,
        PickAvatarMixin {
  final updateGroupChatInteractor = getIt.get<UpdateGroupChatInteractor>();

  final uploadContentInteractor = getIt.get<UploadContentInteractor>();
  final uploadContentWebInteractor =
      getIt.get<UploadContentInBytesInteractor>();

  Room? room;

  static const Duration _delayedUpdateAvatarDuration =
      Duration(milliseconds: 500);

  final groupNameTextEditingController = TextEditingController();
  final groupNameEmptyNotifier = ValueNotifier<bool>(false);
  final groupNameFocusNode = FocusNode();

  final descriptionTextEditingController = TextEditingController();
  final descriptionEmptyNotifier = ValueNotifier<bool>(false);
  final descriptionFocusNode = FocusNode();
  MatrixFile? avatarFilePicker;
  photo_manager.AssetEntity? avatarAssetEntity;

  final MenuController menuController = MenuController();

  final isEditedGroupInfoNotifier = ValueNotifier<bool>(false);

  Client get client => Matrix.of(context).client;

  bool _isDeleteAvatar = false;

  bool get _isEditGroupName =>
      groupNameTextEditingController.text != room?.name;

  bool get _isEditDescription =>
      descriptionTextEditingController.text != room?.topic;

  bool get _isEditAvatar =>
      avatarFilePicker != null || avatarAssetEntity != null;

  bool get _enableDeleteAvatarButton =>
      (room?.avatar != null || _isEditAvatar) && !_isDeleteAvatar;

  void onBack() {
    Navigator.of(context).pop();
  }

  List<PopupMenuItem> listContextMenuBuilder(
    BuildContext context,
  ) {
    final listAction = [
      EditChatAvatarContextMenuActions.edit,
      if (_enableDeleteAvatarButton) EditChatAvatarContextMenuActions.delete,
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

  void _handleActionContextMenu(EditChatAvatarContextMenuActions action) {
    switch (action) {
      case EditChatAvatarContextMenuActions.edit:
        _handleEditAvatarAction(context: context);
        break;
      case EditChatAvatarContextMenuActions.delete:
        _handleRemoveAvatarAction();
        break;
    }
  }

  void _handleEditAvatarAction({required BuildContext context}) async {
    if (PlatformInfos.isWeb) {
      pickAvatarImageOnWeb();
      return;
    }
    final currentPermissionPhotos = await getCurrentMediaPermission(context);
    if (currentPermissionPhotos != null) {
      final imagePickerController = createImagePickerController();
      showImagePickerBottomSheet(
        context,
        currentPermissionPhotos,
        imagePickerController,
        type: photo_manager.RequestType.image,
      );
    }
  }

  ImagePickerGridController createImagePickerController() {
    final imagePickerController = ImagePickerGridController(
      AssetCounter(imagePickerMode: ImagePickerMode.single),
    );

    imagePickerController.addListener(() {
      final selectedAsset = imagePickerController.selectedAssets.firstOrNull;
      if (selectedAsset?.asset.type == photo_manager.AssetType.image) {
        if (!imagePickerController.pickFromCamera()) {
          Navigator.pop(context);
        }
        if (!isEditedGroupInfoNotifier.value) {
          isEditedGroupInfoNotifier.toggle();
        }
        if (selectedAsset != null) {
          avatarAssetEntity = selectedAsset.asset;

          pickAvatarUIState.value = Right(
            GetAvatarOnMobileUIStateSuccess(
              assetEntity: avatarAssetEntity,
            ),
          );
        }

        imagePickerController.removeAllSelectedItem();
      }
    });

    return imagePickerController;
  }

  void updateAvatarFilePicker(MatrixFile matrixFile) {
    if (!isEditedGroupInfoNotifier.value) {
      isEditedGroupInfoNotifier.toggle();
    }
    avatarFilePicker = matrixFile;
  }

  void _handleRemoveAvatarAction() async {
    if (avatarFilePicker != null) {
      avatarFilePicker = null;
      pickAvatarUIState.value = Right(
        GetAvatarInitialUIState(),
      );
      if (_isEditDescription || _isEditGroupName) {
        return;
      } else {
        isEditedGroupInfoNotifier.toggle();
      }
    }
    if (avatarAssetEntity != null) {
      avatarAssetEntity = null;
      pickAvatarUIState.value = Right(
        GetAvatarInitialUIState(),
      );
      if (_isEditDescription || _isEditGroupName) {
        return;
      } else {
        isEditedGroupInfoNotifier.toggle();
      }
    }
    if (room?.avatar != null) {
      pickAvatarUIState.value = Right(
        GetAvatarInitialUIState(),
      );
      _isDeleteAvatar = true;
      if (_isEditDescription || _isEditGroupName) {
        return;
      } else {
        isEditedGroupInfoNotifier.toggle();
      }
    }
  }

  void _setAvatarInStream() {
    if (avatarAssetEntity != null) {
      uploadContentInteractor
          .execute(
        matrixClient: client,
        entity: avatarAssetEntity!,
      )
          .listen(
        (event) => _handleUploadAvatarOnData(context, event),
        onDone: () {
          Logs().d(
            'ChatDetailsEdit::_setAvatarInStream() - done',
          );
        },
        onError: (error) {
          Logs().e(
            'ChatDetailsEdit::_setAvatarInStream() - error: $error',
          );
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.oopsSomethingWentWrong,
          );
        },
      );
    } else {
      _updateGroupInfo(
        displayName: groupNameTextEditingController.text,
        description: descriptionTextEditingController.text,
      );
    }
  }

  void _handleUploadAvatarOnData(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    Logs().d('ChatDetailsEdit::_handleUploadAvatarOnData()');
    event.fold(
      (failure) {
        Logs().e(
          'ChatDetailsEdit::_handleUploadAvatarOnData() - failure: $failure',
        );
      },
      (success) {
        Logs().d(
          'ChatDetailsEdit::_handleUploadAvatarOnData() - success: $success',
        );
        if (success is UploadContentSuccess) {
          _updateGroupInfo(
            avatarUr: success.uri,
            displayName: groupNameTextEditingController.text,
            description: descriptionTextEditingController.text,
          );
        }
      },
    );
  }

  void _setAvatarInBytes() {
    if (avatarFilePicker != null) {
      uploadContentWebInteractor
          .execute(
        matrixClient: client,
        matrixFile: avatarFilePicker!,
      )
          .listen(
        (event) => _handleUploadAvatarOnData(context, event),
        onDone: () {
          Logs().d(
            'ChatDetailsEdit::_setAvatarInBytes() - done',
          );
        },
        onError: (error) {
          Logs().e(
            'ChatDetailsEdit::_setAvatarInBytes() - error: $error',
          );
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.oopsSomethingWentWrong,
          );
        },
      );
    } else {
      _updateGroupInfo(
        displayName: groupNameTextEditingController.text,
        description: descriptionTextEditingController.text,
      );
    }
  }

  void _updateGroupInfo({
    Uri? avatarUr,
    String? displayName,
    String? description,
  }) {
    if (room == null) return;
    updateGroupChatInteractor
        .execute(
          client: client,
          room: room!,
          avatarUrl: avatarUr,
          displayName: displayName,
          description: description,
          isDeleteAvatar: _isDeleteAvatar,
        )
        .listen(
          (event) {
            _handleUpdateGroupInfoOnEvents(context, event);
          },
          onDone: _handleUpdateGroupInfoOnDone,
          onError: (error) {
            Logs().e(
              'ChatDetailsEdit::_uploadGroupInfo() - error: $error',
            );
          },
        );
  }

  void handleSaveAction(BuildContext context) async {
    if (groupNameFocusNode.hasFocus) groupNameFocusNode.unfocus();
    if (descriptionFocusNode.hasFocus) descriptionFocusNode.unfocus();
    TwakeDialog.showLoadingDialog(context);
    if (PlatformInfos.isMobile) {
      _setAvatarInStream();
    } else {
      _setAvatarInBytes();
    }
  }

  void _handleUpdateGroupInfoOnEvents(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    Logs().d('ChatDetailsEdit::_handleUpdateGroupInfoOnEvents()');
    event.fold(
      (failure) {
        if (failure is UpdateGroupDisplayNameFailure) {
          Logs().e(
            'ChatDetailsEdit::_handleUpdateGroupInfoOnEvents() - UpdateGroupDisplayNameFailure - ${failure.exception}',
          );
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.oopsSomethingWentWrong,
          );
        } else if (failure is UpdateGroupAvatarFailure) {
          Logs().e(
            'ChatDetailsEdit::_handleUpdateGroupInfoOnEvents() - UpdateGroupAvatarFailure - ${failure.exception}',
          );
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.oopsSomethingWentWrong,
          );
        } else if (failure is UpdateGroupDescriptionFailure) {
          Logs().e(
            'ChatDetailsEdit::_handleUpdateGroupInfoOnEvents() - UpdateGroupDescriptionFailure - ${failure.exception}',
          );
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.oopsSomethingWentWrong,
          );
        } else if (failure is UpdateGroupNameIsEmptyFailure) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.groupNameCannotBeEmpty,
          );
        } else if (failure is UpdateGroupChatFailure) {
          TwakeSnackBar.show(
            context,
            failure.exception.toLocalizedString(context),
          );
        } else {
          Logs().e(
            'ChatDetailsEdit::_handleUpdateGroupInfoOnEvents() - failure: UNKNOWN',
          );
        }
      },
      (success) async {
        if (success is UpdateAvatarGroupChatSuccess) {
          Logs().d(
            'ChatDetailsEdit::_handleUpdateGroupInfoOnEvents() - UpdateAvatarGroupChatSuccess',
          );
          _handleSaveIconOnUpdateSuccess();
          await Future.delayed(_delayedUpdateAvatarDuration).then((_) {
            room = Matrix.of(context).client.getRoomById(widget.roomId);
          });
          _isDeleteAvatar = false;
          avatarFilePicker = null;
          avatarAssetEntity = null;
        } else if (success is UpdateDisplayNameGroupChatSuccess) {
          Logs().d(
            'ChatDetailsEdit::_handleUpdateGroupInfoOnEvents() - UpdateDisplayNameGroupChatSuccess',
          );
          _handleSaveIconOnUpdateSuccess();
        } else if (success is UpdateDescriptionGroupChatSuccess) {
          Logs().d(
            'ChatDetailsEdit::_handleUpdateGroupInfoOnEvents() - UpdateDescriptionGroupChatSuccess',
          );
          _handleSaveIconOnUpdateSuccess();
        } else {
          Logs().d(
            'ChatDetailsEdit::_handleUpdateGroupInfoOnEvents() - success: $success',
          );
        }
      },
    );
  }

  void _handleSaveIconOnUpdateSuccess() {
    if (isEditedGroupInfoNotifier.value) {
      isEditedGroupInfoNotifier.toggle();
    }
  }

  void _handleUpdateGroupInfoOnDone() {
    Logs().d('ChatDetailsEdit::_handleUpdateGroupInfoOnDone()');
    TwakeDialog.hideLoadingDialog(context);
  }

  void _clearImageInMemory() {
    avatarFilePicker = null;
    avatarAssetEntity = null;
  }

  @override
  void dispose() {
    _clearImageInMemory();
    disposePickAvatarMixin();
    groupNameTextEditingController.dispose();
    descriptionTextEditingController.dispose();
    isEditedGroupInfoNotifier.dispose();
    descriptionFocusNode.dispose();
    groupNameFocusNode.dispose();
    super.dispose();
  }

  void _setupGroupNameTextEditingController() {
    groupNameTextEditingController.text = room?.name ?? '';
    groupNameEmptyNotifier.value = groupNameTextEditingController.text.isEmpty;

    groupNameTextEditingController.addListener(() {
      if (_isEditAvatar) {
        return;
      }

      isEditedGroupInfoNotifier.value =
          groupNameTextEditingController.text != room?.name;
      groupNameEmptyNotifier.value =
          groupNameTextEditingController.text.isEmpty;
    });
  }

  void _setupDescriptionTextEditingController() {
    descriptionTextEditingController.text = room?.topic ?? '';
    descriptionEmptyNotifier.value =
        descriptionTextEditingController.text.isEmpty;

    descriptionTextEditingController.addListener(() {
      if (_isEditAvatar) {
        return;
      }

      descriptionEmptyNotifier.value =
          descriptionTextEditingController.text.isEmpty;
      isEditedGroupInfoNotifier.value =
          descriptionTextEditingController.text != room?.topic;
    });
  }

  @override
  void initState() {
    room = Matrix.of(context).client.getRoomById(widget.roomId);
    _setupGroupNameTextEditingController();
    _setupDescriptionTextEditingController();
    listenToPickAvatarUIState(context);
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
