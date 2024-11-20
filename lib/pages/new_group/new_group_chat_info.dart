import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/create_new_group_chat_state.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:fluffychat/domain/model/extensions/validator_failure_extension.dart';
import 'package:fluffychat/domain/model/verification/name_with_space_only_validator.dart';
import 'package:fluffychat/domain/usecase/verify_name_interactor.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info_view.dart';
import 'package:fluffychat/pages/new_group/new_group_info_controller.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/pick_avatar_mixin.dart';
import 'package:fluffychat/presentation/mixins/single_image_picker_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/power_level_manager.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:collection/collection.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/create_new_group_chat_request.dart';
import 'package:fluffychat/domain/usecase/room/create_new_group_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:fluffychat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:fluffychat/utils/dialog/warning_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class NewGroupChatInfo extends StatefulWidget {
  final Set<PresentationContact> contactsList;

  const NewGroupChatInfo({super.key, required this.contactsList});

  @override
  State<StatefulWidget> createState() => NewGroupChatInfoController();
}

class NewGroupChatInfoController extends State<NewGroupChatInfo>
    with CommonMediaPickerMixin, SingleImagePickerMixin, PickAvatarMixin {
  final enableEncryptionNotifier = ValueNotifier(false);
  final haveGroupNameNotifier = ValueNotifier(false);
  final createRoomStateNotifier =
      ValueNotifier<Either<Failure, Success>>(Right(CreateNewGroupInitial()));
  final uploadContentInteractor = getIt.get<UploadContentInteractor>();
  final uploadContentWebInteractor =
      getIt.get<UploadContentInBytesInteractor>();
  final createNewGroupChatInteractor =
      getIt.get<CreateNewGroupChatInteractor>();
  final groupNameTextEditingController = TextEditingController();
  final avatarAssetEntityNotifier = ValueNotifier<AssetEntity?>(null);
  final avatarFilePickerNotifier = ValueNotifier<MatrixFile?>(null);
  VerifyNameInteractor verifyNameInteractor = getIt.get<VerifyNameInteractor>();

  final groupNameFocusNode = FocusNode();
  StreamSubscription? createNewGroupChatInteractorStreamSubscription;

  final responsiveUtils = getIt.get<ResponsiveUtils>();

  String groupName = "";

  Set<PresentationContact>? contactsList;

  Future<ServerConfig> getServerConfig() async {
    final serverConfig = await Matrix.of(context).client.getConfig();
    return serverConfig;
  }

  void toggleEnableEncryption() {
    enableEncryptionNotifier.value = !enableEncryptionNotifier.value;
  }

  Future<Set<PresentationContact>> getAllContactsGroupChat({
    bool isCustomDisplayName = true,
  }) async {
    final userId = Matrix.of(context).client.userID;
    final profile =
        await Matrix.of(context).client.getProfileFromUserId(userId ?? '');
    final newContactsList = {
      PresentationContact(
        displayName:
            isCustomDisplayName ? L10n.of(context)!.you : profile.displayName,
        matrixId: Matrix.of(context).client.userID,
      ),
    };
    newContactsList.addAll(getSelectedValidContacts(contactsList ?? {}));
    return newContactsList;
  }

  void createNewGroup({String? urlAvatar}) {
    final client = Matrix.of(context).client;
    final powerLevelManager = getIt.get<PowerLevelManager>();
    createNewGroupChatAction(
      matrixClient: client,
      createNewGroupChatRequest: CreateNewGroupChatRequest(
        groupName: groupName,
        invite: getSelectedValidContacts(contactsList ?? {})
            .map((contact) => contact.matrixId)
            .whereNotNull()
            .toList(),
        enableEncryption: enableEncryptionNotifier.value,
        urlAvatar: urlAvatar,
        powerLevelContentOverride: {
          'events': powerLevelManager.getDefaultPowerLevelEventForMember(),
          'invite': powerLevelManager.getAdminPowerLevel(),
          'kick': powerLevelManager.getAdminPowerLevel(),
        },
      ),
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
          if (!responsiveUtils.isSingleColumnLayout(context)) {
            context.popInnerAll();
          }
          _goToRoom(success);
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

  void uploadAvatarNewGroupChat({
    required Client matrixClient,
    required AssetEntity entity,
  }) {
    uploadContentInteractor
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

  void uploadAvatarNewGroupChatInBytes({
    required Client matrixClient,
    required MatrixFile matrixFile,
  }) {
    uploadContentWebInteractor
        .execute(
          matrixClient: matrixClient,
          matrixFile: matrixFile,
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

  void _goToRoom(CreateNewGroupChatSuccess success) {
    context.go(
      "/rooms/${success.roomId}",
      extra: ChatRouterInputArgument(
        type: ChatRouterInputArgumentType.draft,
        data: success.groupName,
      ),
    );
  }

  void updateAvatarFilePicker(MatrixFile matrixFile) {
    avatarFilePickerNotifier.value = matrixFile;
  }

  void showImagesPickerAction({
    required BuildContext context,
  }) async {
    if (isCreatingRoom) {
      return;
    }
    if (PlatformInfos.isWeb) {
      pickAvatarImageOnWeb();
      return;
    }
    final currentPermissionPhotos = await getCurrentMediaPermission(context);
    if (currentPermissionPhotos != null) {
      final imagePickerController = createImagePickerController();
      groupNameFocusNode.unfocus();
      showImagePickerBottomSheet(
        context,
        currentPermissionPhotos,
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

  bool get isCreatingRoom {
    return createRoomStateNotifier.value.fold(
      (failure) => false,
      (success) =>
          success is UploadContentLoading ||
          success is CreateNewGroupChatLoading,
    );
  }

  String? getErrorMessage(String content) {
    return verifyNameInteractor
        .execute(content, [NameWithSpaceOnlyValidator()]).fold(
      (failure) {
        if (failure is VerifyNameFailure) {
          return failure.getMessage(context);
        } else {
          return null;
        }
      },
      (success) => null,
    );
  }

  @override
  void initState() {
    listenGroupNameChanged();
    listenToPickAvatarUIState(context);
    contactsList = widget.contactsList;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    disposePickAvatarMixin();
    haveGroupNameNotifier.dispose();
    enableEncryptionNotifier.dispose();
    avatarAssetEntityNotifier.dispose();
    createNewGroupChatInteractorStreamSubscription?.cancel();
    groupNameTextEditingController.dispose();
    groupNameFocusNode.dispose();
    avatarFilePickerNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NewGroupChatInfoView(this);
  }
}
