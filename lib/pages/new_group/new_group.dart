import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/create_new_group_chat_state.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/domain/model/room/create_new_group_chat_request.dart';
import 'package:fluffychat/domain/usecase/room/create_new_group_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_interactor.dart';
import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view.dart';
import 'package:fluffychat/presentation/mixins/image_picker_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_group/new_group_info_controller.dart';
import 'package:fluffychat/utils/dialog/warning_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({Key? key}) : super(key: key);

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends ContactsSelectionController<NewGroup>
    with ImagePickerMixin {
  final uploadContentInteractor = getIt.get<UploadContentInteractor>();
  final createNewGroupChatInteractor =
      getIt.get<CreateNewGroupChatInteractor>();
  final groupNameTextEditingController = TextEditingController();
  final avatarNotifier = ValueNotifier<AssetEntity?>(null);
  final createRoomStateNotifier =
      ValueNotifier<Either<Failure, Success>>(Right(CreateNewGroupInitial()));

  final haveGroupNameNotifier = ValueNotifier(false);
  final groupNameFocusNode = FocusNode();
  StreamSubscription? uploadContentInteractorStreamSubscription;
  StreamSubscription? createNewGroupChatInteractorStreamSubscription;

  String groupName = "";

  @override
  void initState() {
    super.initState();
    listenGroupNameChanged();
    _registerListenerForSelectedImagesChanged();
  }

  @override
  void dispose() {
    super.dispose();
    imagePickerController.dispose();
    haveGroupNameNotifier.dispose();
    avatarNotifier.dispose();
    uploadContentInteractorStreamSubscription?.cancel();
    createNewGroupChatInteractorStreamSubscription?.cancel();
  }

  @override
  String getTitle(BuildContext context) {
    return L10n.of(context)!.newGroupChat;
  }

  @override
  String getHintText(BuildContext context) {
    return L10n.of(context)!.whoWouldYouLikeToAdd;
  }

  @override
  void onSubmit() {
    moveToNewGroupInfoScreen();
  }

  Future<ServerConfig> getServerConfig() async {
    final serverConfig = await Matrix.of(context).client.getConfig();
    return serverConfig;
  }

  Future<Set<PresentationContact>> getAllContactsGroupChat({
    bool isCustomDisplayName = true,
  }) async {
    final userId = Matrix.of(context).client.userID;
    final profile =
        await Matrix.of(context).client.getProfileFromUserId(userId!);
    final newContactsList = {
      PresentationContact(
        displayName:
            isCustomDisplayName ? L10n.of(context)!.you : profile.displayName,
        matrixId: Matrix.of(context).client.userID,
      )
    };
    newContactsList.addAll(getSelectedValidContacts(contactsList));
    return newContactsList;
  }

  void _getDefaultGroupName(Set<PresentationContact> contactLis) async {
    if (contactLis.length <= 3) {
      final groupName =
          contactLis.map((contact) => contact.displayName).join(", ");
      groupNameTextEditingController.text = groupName;
      groupNameTextEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: groupNameTextEditingController.text.length),
      );
      groupNameFocusNode.requestFocus();
    } else {
      groupNameTextEditingController.clear();
    }
  }

  void moveToNewGroupInfoScreen() async {
    final contactList =
        await getAllContactsGroupChat(isCustomDisplayName: false);
    _getDefaultGroupName(contactList);
    await showGeneralDialog(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      context: context,
      useRootNavigator: false,
      barrierColor: Colors.white,
      transitionBuilder: (context, animation1, animation2, widget) {
        return NewGroupChatInfo(
          contactsList: contactList,
          newGroupController: this,
        );
      },
    );
  }

  void createNewGroup({String? urlAvatar}) {
    final client = Matrix.of(context).client;
    createNewGroupChatAction(
      matrixClient: client,
      createNewGroupChatRequest: CreateNewGroupChatRequest(
        groupName: groupName,
        invite: getSelectedValidContacts(contactsList)
            .map((contact) => contact.matrixId)
            .whereNotNull()
            .toList(),
        enableEncryption: true,
        urlAvatar: urlAvatar,
      ),
    );
  }

  void uploadAvatarNewGroupChat({
    required Client matrixClient,
    required AssetEntity entity,
  }) {
    uploadContentInteractorStreamSubscription = uploadContentInteractor
        .execute(
          matrixClient: matrixClient,
          entity: entity,
        )
        .listen(
          (event) => _handleUploadAvatarNewGroupChatOnData(context, event),
          onDone: _handleUploadAvatarNewGroupChatOnDone,
          onError: _handleUploadAvatarNewGroupChatOnError,
        );
  }

  void createNewGroupChatAction({
    required Client matrixClient,
    required CreateNewGroupChatRequest createNewGroupChatRequest,
  }) {
    createNewGroupChatInteractorStreamSubscription =
        createNewGroupChatInteractor
            .execute(
              matrixClient: matrixClient,
              createNewGroupChatRequest: createNewGroupChatRequest,
            )
            .listen(
              (event) => _handleCreateNewGroupChatChatOnData(context, event),
              onDone: _handleCreateNewGroupChatOnDone,
              onError: _handleCreateNewGroupChatOnError,
            );
  }

  void _handleUploadAvatarNewGroupChatOnData(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    Logs().d('NewGroupController::_handleUploadAvatarNewGroupChatOnData()');
    createRoomStateNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e(
          'NewGroupController::_handleUploadAvatarNewGroupChatOnData() - failure: $failure',
        );
        WarningDialog.showCancelable(
          context,
          message: L10n.of(context)!
              .youAreUploadingPhotosDoYouWantToCancelOrContinue,
          acceptText: L10n.of(context)!.continueProcess,
          onAccept: () {
            WarningDialog.hideWarningDialog(context);
            createNewGroup();
          },
        );
      },
      (success) {
        Logs().d(
          'NewGroupController::_handleUploadAvatarNewGroupChatOnData() - success: $success',
        );
        if (success is UploadContentSuccess) {
          final urlAvatar = success.uri.toString();
          createNewGroup(urlAvatar: urlAvatar);
        }
      },
    );
  }

  void _handleUploadAvatarNewGroupChatOnDone() {
    Logs().d(
      'NewGroupController::_handleUploadAvatarNewGroupChatOnDone() - done',
    );
  }

  void _handleUploadAvatarNewGroupChatOnError(
    dynamic error,
    StackTrace? stackTrace,
  ) {
    Logs().e(
      'NewGroupController::_handleUploadAvatarNewGroupChatOnError() - error: $error | stackTrace: $stackTrace',
    );
  }

  void _handleCreateNewGroupChatChatOnData(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    Logs().d('NewGroupController::_handleCreateNewGroupChatChatOnData()');
    createRoomStateNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e(
          'NewGroupController::_handleCreateNewGroupChatChatOnData() - failure: $failure',
        );
      },
      (success) {
        Logs().d(
          'NewGroupController::_handleCreateNewGroupChatChatOnData() - success: $success',
        );
        if (success is CreateNewGroupChatSuccess) {
          removeAllImageSelected();
          _goToRoom(context, success.roomId);
        }
      },
    );
  }

  void _handleCreateNewGroupChatOnDone() {
    Logs().d('NewGroupController::_handleCreateNewGroupChatOnDone() - done');
  }

  void _handleCreateNewGroupChatOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e(
      'NewGroupController::_handleUploadAvatarNewGroupChatOnError() - error: $error | stackTrace: $stackTrace',
    );
  }

  void _goToRoom(BuildContext context, String roomId) {
    context.go("/rooms/$roomId");
  }

  void _registerListenerForSelectedImagesChanged() {
    imagePickerController.addListener(() {
      numberSelectedImagesNotifier.value =
          imagePickerController.selectedAssets.length;
    });

    numberSelectedImagesNotifier.addListener(() {
      if (numberSelectedImagesNotifier.value == 1) {
        Navigator.pop(context);
        avatarNotifier.value = imagePickerController.selectedAssets.first.asset;
        removeAllImageSelected();
      }
    });
  }

  void showImagesPickerAction({
    required BuildContext context,
  }) async {
    if (isCreatingRoom) {
      return;
    }
    final currentPermissionPhotos = await getCurrentPhotoPermission();
    final currentPermissionCamera = await getCurrentCameraPermission();
    if (currentPermissionPhotos != null && currentPermissionCamera != null) {
      showImagesPickerBottomSheet(
        context: context,
        permissionStatusPhotos: currentPermissionPhotos,
        permissionStatusCamera: currentPermissionCamera,
        onItemAction: (_) {},
      );
    }
  }

  bool get isCreatingRoom {
    return createRoomStateNotifier.value.fold(
          (failure) => false,
          (success) =>
              success is UploadContentLoading ||
              success is CreateNewGroupChatLoading,
        ) ??
        false;
  }

  @override
  void removeAllImageSelected() {
    uploadContentInteractorStreamSubscription?.cancel();
    imagePickerController.clearAssetCounter();
    numberSelectedImagesNotifier.value = 0;
    Logs().d(
      'NewGroupController::_removeAllImageSelected() - numberSelectedImagesNotifier.value  ${numberSelectedImagesNotifier.value}',
    );
  }

  @override
  Widget build(BuildContext context) => ContactsSelectionView(this);
}
