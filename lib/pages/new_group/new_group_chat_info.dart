import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/room/upload_content_state.dart';
import 'package:twake_chat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:twake_chat/domain/model/extensions/validator_failure_extension.dart';
import 'package:twake_chat/domain/model/verification/name_with_space_only_validator.dart';
import 'package:twake_chat/domain/model/verification/new_name_request.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_controller.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_state.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_view.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/states/new_group_form.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/presentation/extensions/invite_user_exception_extension.dart';
import 'package:twake_chat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:twake_chat/presentation/mixins/pick_avatar_mixin.dart';
import 'package:twake_chat/presentation/mixins/single_image_picker_mixin.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';
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
import 'package:twake_chat/config/first_column_inner_routes.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class NewGroupChatInfo extends ConsumerStatefulWidget {
  final Set<PresentationContact> contactsList;

  final NewGroupKind kind;

  /// The space the flow was opened from, chosen beforehand.
  final String? parentSpaceId;

  const NewGroupChatInfo({
    super.key,
    required this.contactsList,
    this.kind = NewGroupKind.group,
    this.parentSpaceId,
  });

  @override
  ConsumerState<NewGroupChatInfo> createState() =>
      NewGroupChatInfoScreenState();
}

class NewGroupChatInfoScreenState extends ConsumerState<NewGroupChatInfo>
    with CommonMediaPickerMixin, SingleImagePickerMixin, PickAvatarMixin {
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
  Set<PresentationContact> get contactsList => widget.contactsList;

  NewGroupKind get kind => widget.kind;

  bool get isFeed => kind.isFeed;

  bool get isSpace => kind.isSpace;

  late final parentSpaceNotifier = ValueNotifier<String?>(widget.parentSpaceId);

  final topicTextEditingController = TextEditingController();

  void setEncrypted({required bool isEncrypted}) {
    groupPrivacyNotifier.value = groupPrivacyNotifier.value.withEncryption(
      isEncrypted: isEncrypted,
    );
  }

  void setPublic({required bool isPublic}) {
    groupPrivacyNotifier.value = groupPrivacyNotifier.value.withPublic(
      isPublic: isPublic,
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
    final client = ref.read(activeMatrixClientProvider);
    if (client == null) return;
    if (PlatformInfos.isMobile) {
      groupNameFocusNode.unfocus();
      final entity = avatarAssetEntityNotifier.value;
      if (entity == null) return createNewGroup();
      uploadContentInteractor
          .execute(matrixClient: client, entity: entity)
          .listen(
            _handleUploadAvatarOnData,
            onError: _handleUploadAvatarOnError,
          );
    } else {
      final matrixFile = avatarFilePickerNotifier.value;
      if (matrixFile == null) return createNewGroup();
      uploadContentWebInteractor
          .execute(matrixClient: client, matrixFile: matrixFile)
          .listen(
            _handleUploadAvatarOnData,
            onError: _handleUploadAvatarOnError,
          );
    }
  }

  /// A link can name a space the user may not add to: it is not kept.
  String? get _validParentSpaceId {
    final parentId = parentSpaceNotifier.value;
    return ref.read(addableSpacesProvider).any((space) => space.id == parentId)
        ? parentId
        : null;
  }

  /// Checked on the resolved parent: a link or « None » can leave a plain
  /// group without anybody.
  bool get canSubmit =>
      contactsList.isNotEmpty ||
      !kind.isMemberRequired(parentSpaceId: _validParentSpaceId);

  void createNewGroup({String? urlAvatar}) {
    unawaited(
      ref
          .read(newGroupChatInfoControllerProvider.notifier)
          .create(
            NewGroupForm(
              groupName: groupNameTextEditingController.text,
              invitees: contactsList.map((contact) => contact.matrixId),
              privacy: groupPrivacyNotifier.value,
              kind: kind,
              topic: topicTextEditingController.text,
              parentSpaceId: _validParentSpaceId,
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
          onAccept: createNewGroup,
        );
      },
      (success) {
        if (success is UploadContentSuccess) {
          createNewGroup(urlAvatar: success.uri.toString());
        }
      },
    );
  }

  void _handleUploadAvatarOnError(Object error, StackTrace stackTrace) {
    Logs().e('NewGroupChatInfo::upload avatar', error, stackTrace);
    _handleUploadAvatarOnData(Left(UploadContentFailed(exception: error)));
  }

  Future<void> _onStateChanged(NewGroupChatInfoState next) async {
    final l10n = L10n.of(context)!;
    switch (next) {
      case NewGroupChatInfoFailed(:final reason):
        await showConfirmAlertDialog(
          context: context,
          message: switch (reason) {
            NewGroupFailureReason.spaceRefused => l10n.createForbidden,
            NewGroupFailureReason.feedNotSupported =>
              l10n.feedNotSupportedByHomeserver,
            NewGroupFailureReason.other when widget.kind.isSpace =>
              l10n.createFailed,
            NewGroupFailureReason.other => l10n.inviteUserErrorMessage,
          },
          isArrangeActionButtonsVertical: true,
          okLabel: l10n.gotIt,
        );
      case NewGroupChatInfoDone(
        :final roomId,
        :final groupName,
        :final inviteFailure,
      ):
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
    // Where the flow went through the inner navigator, whatever the width.
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
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

  String? getErrorMessage(String content) => NameWithSpaceOnlyValidator()
      .validate(NewNameRequest(content))
      .fold(
        (failure) =>
            failure is VerifyNameFailure ? failure.getMessage(context) : null,
        (_) => null,
      );

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
    groupPrivacyNotifier.dispose();
    avatarAssetEntityNotifier.dispose();
    avatarUploadStateNotifier.dispose();
    groupNameTextEditingController.dispose();
    topicTextEditingController.dispose();
    parentSpaceNotifier.dispose();
    groupNameFocusNode.dispose();
    avatarFilePickerNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      newGroupChatInfoControllerProvider,
      (_, next) => unawaited(_onStateChanged(next)),
    );
    return NewGroupChatInfoView(this);
  }
}
