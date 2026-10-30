import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/room/upload_content_state.dart';
import 'package:twake_chat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/extensions/validator_failure_extension.dart';
import 'package:twake_chat/domain/model/verification/composite_name_validator.dart';
import 'package:twake_chat/domain/model/verification/name_with_space_only_validator.dart';
import 'package:twake_chat/domain/model/verification/new_name_request.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_controller.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_state.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_view.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/states/new_group_form.dart';
import 'package:twake_chat/presentation/extensions/invite_user_exception_extension.dart';
import 'package:twake_chat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:twake_chat/presentation/mixins/pick_avatar_mixin.dart';
import 'package:twake_chat/presentation/mixins/single_image_picker_mixin.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:collection/collection.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:twake_chat/utils/dialog/warning_dialog.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class NewGroupChatInfo extends ConsumerStatefulWidget {
  final Set<PresentationContact> contactsList;

  final bool isFeed;

  const NewGroupChatInfo({
    super.key,
    required this.contactsList,
    this.isFeed = false,
  });

  @override
  ConsumerState<NewGroupChatInfo> createState() =>
      NewGroupChatInfoScreenState();
}

class NewGroupChatInfoScreenState extends ConsumerState<NewGroupChatInfo>
    with CommonMediaPickerMixin, SingleImagePickerMixin, PickAvatarMixin {
  final enableEncryptionNotifier = ValueNotifier(false);
  final groupPrivacyNotifier = ValueNotifier(const GroupPrivacyState());
  final haveGroupNameNotifier = ValueNotifier(false);
  final avatarUploadStateNotifier = ValueNotifier<Either<Failure, Success>?>(
    null,
  );
  // TODO: [transitional] Shared with settings_profile and chat_details_edit; the upload migrates with those modules.
  final uploadContentInteractor = getIt.get<UploadContentInteractor>();
  final uploadContentWebInteractor = getIt
      .get<UploadContentInBytesInteractor>();
  final groupNameTextEditingController = TextEditingController();
  final avatarAssetEntityNotifier = ValueNotifier<AssetEntity?>(null);
  final avatarFilePickerNotifier = ValueNotifier<MatrixFile?>(null);
  final groupNameFocusNode = FocusNode();
  final responsiveUtils = ResponsiveUtils();

  Set<PresentationContact> get contactsList => widget.contactsList;

  bool get isFeed => widget.isFeed;

  void toggleEnableEncryption() {
    enableEncryptionNotifier.value = !enableEncryptionNotifier.value;
  }

  /// Also resets [GroupPrivacyState.isServerLimited] to the well-known default.
  void setPublic({required bool isPublic}) {
    groupPrivacyNotifier.value = GroupPrivacyState(
      isPublic: isPublic,
      isServerLimited:
          isPublic &&
          ref
              .read(loginHomeserverSummaryProvider)
              .isPublicGroupsServerLimitedByDefault,
    );
  }

  void setServerLimited({required bool isServerLimited}) {
    groupPrivacyNotifier.value = groupPrivacyNotifier.value.copyWith(
      isServerLimited: isServerLimited,
    );
  }

  bool get isUploadingAvatar =>
      avatarUploadStateNotifier.value?.fold(
        (_) => false,
        (success) => success is UploadContentLoading,
      ) ??
      false;

  bool get isCreatingRoom =>
      isUploadingAvatar || ref.read(newGroupChatInfoControllerProvider).isBusy;

  void moveToGroupChatScreen() {
    final client = ref.read(activeMatrixClientProvider).client;
    if (client == null) return;
    if (PlatformInfos.isMobile) {
      groupNameFocusNode.unfocus();
      final entity = avatarAssetEntityNotifier.value;
      if (entity == null) return createNewGroup();
      uploadContentInteractor
          .execute(matrixClient: client, entity: entity)
          .listen(_handleUploadAvatarOnData);
    } else {
      final matrixFile = avatarFilePickerNotifier.value;
      if (matrixFile == null) return createNewGroup();
      uploadContentWebInteractor
          .execute(matrixClient: client, matrixFile: matrixFile)
          .listen(_handleUploadAvatarOnData);
    }
  }

  void createNewGroup({String? urlAvatar}) {
    unawaited(
      ref
          .read(newGroupChatInfoControllerProvider.notifier)
          .create(
            NewGroupForm(
              groupName: groupNameTextEditingController.text,
              invitees: contactsList.map((contact) => contact.matrixId),
              enableEncryption: enableEncryptionNotifier.value,
              privacy: groupPrivacyNotifier.value,
              isFeed: isFeed,
              urlAvatar: urlAvatar,
            ),
          ),
    );
  }

  void _handleUploadAvatarOnData(Either<Failure, Success> event) {
    if (!mounted) return;
    avatarUploadStateNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e('NewGroupChatInfo::upload avatar failed: $failure');
        WarningDialog.showCancelable(
          context,
          message: L10n.of(
            context,
          )!.youAreUploadingPhotosDoYouWantToCancelOrContinue,
          acceptText: L10n.of(context)!.continueProcess,
          onAccept: () {
            WarningDialog.hideWarningDialog(context);
            createNewGroup();
          },
        );
      },
      (success) {
        if (success is UploadContentSuccess) {
          createNewGroup(urlAvatar: success.uri.toString());
        }
      },
    );
  }

  Future<void> _onStateChanged(
    NewGroupChatInfoState? previous,
    NewGroupChatInfoState next,
  ) async {
    final l10n = L10n.of(context)!;
    switch (next) {
      case NewGroupChatInfoFailed(:final reason):
        await showConfirmAlertDialog(
          context: context,
          message: reason == NewGroupFailureReason.feedNotSupported
              ? l10n.feedNotSupportedByHomeserver
              : l10n.inviteUserErrorMessage,
          isArrangeActionButtonsVertical: true,
          okLabel: l10n.gotIt,
        );
      case NewGroupChatInfoDone(:final roomId, :final groupName):
        final inviteFailure = next.inviteFailure;
        if (inviteFailure != null) {
          await showConfirmAlertDialog(
            context: context,
            message: inviteFailure.getLocalizedErrorMessage(context),
            isArrangeActionButtonsVertical: true,
            okLabel: l10n.gotIt,
          );
        }
        if (!mounted) return;
        _completeGroupCreation(roomId: roomId, groupName: groupName);
      case NewGroupChatInfoIdle() ||
          NewGroupChatInfoCreating() ||
          NewGroupChatInfoInviting():
        break;
    }
  }

  void _completeGroupCreation({required String roomId, String? groupName}) {
    if (!responsiveUtils.isSingleColumnLayout(context)) {
      context.popInnerAll();
    }
    RoomRoute(
      roomid: roomId,
      $extra: ChatRouterInputArgument(
        type: ChatRouterInputArgumentType.draft,
        data: groupName,
      ),
    ).go(context);
  }

  void updateAvatarFilePicker(MatrixFile matrixFile) {
    avatarFilePickerNotifier.value = matrixFile;
  }

  void showImagesPickerAction({required BuildContext context}) async {
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

  String? getErrorMessage(String content) {
    return CompositeNameValidator([
      NameWithSpaceOnlyValidator(),
    ]).validate(NewNameRequest(content)).fold((failure) {
      if (failure is VerifyNameFailure) {
        return failure.getMessage(context);
      } else {
        return null;
      }
    }, (success) => null);
  }

  void _onGroupNameChanged() {
    final text = groupNameTextEditingController.text;
    haveGroupNameNotifier.value =
        text.isNotEmpty && getErrorMessage(text) == null;
  }

  @override
  void initState() {
    groupNameTextEditingController.addListener(_onGroupNameChanged);
    listenToPickAvatarUIState(context);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    disposePickAvatarMixin();
    haveGroupNameNotifier.dispose();
    enableEncryptionNotifier.dispose();
    groupPrivacyNotifier.dispose();
    avatarAssetEntityNotifier.dispose();
    avatarUploadStateNotifier.dispose();
    groupNameTextEditingController.dispose();
    groupNameFocusNode.dispose();
    avatarFilePickerNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      newGroupChatInfoControllerProvider,
      (previous, next) => unawaited(_onStateChanged(previous, next)),
    );
    return NewGroupChatInfoView(this);
  }
}
