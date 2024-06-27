import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/domain/app_state/settings/update_profile_failure.dart';
import 'package:fluffychat/domain/app_state/settings/update_profile_success.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_interactor.dart';
import 'package:fluffychat/domain/usecase/settings/update_profile_interactor.dart';
import 'package:fluffychat/event/twake_event_dispatcher.dart';
import 'package:fluffychat/event/twake_inapp_event_types.dart';
import 'package:fluffychat/pages/multiple_accounts/multiple_accounts_picker.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/get_avatar_ui_state.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/get_clients_ui_state.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/get_profile_ui_state.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view.dart';
import 'package:fluffychat/presentation/extensions/multiple_accounts/client_profile_extension.dart';
import 'package:fluffychat/presentation/multiple_account/client_profile_presentation.dart';
import 'package:fluffychat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/single_image_picker_mixin.dart';
import 'package:fluffychat/presentation/multiple_account/twake_chat_presentation_account.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/on_account_data_listen_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class SettingsProfile extends StatefulWidget {
  const SettingsProfile({
    super.key,
  });

  @override
  State<SettingsProfile> createState() => SettingsProfileController();
}

class SettingsProfileController extends State<SettingsProfile>
    with
        CommonMediaPickerMixin,
        SingleImagePickerMixin,
        PopupContextMenuActionMixin,
        PopupMenuWidgetMixin,
        OnProfileChangeMixin {
  final uploadProfileInteractor = getIt.get<UpdateProfileInteractor>();
  final uploadContentInteractor = getIt.get<UploadContentInteractor>();
  final uploadContentWebInteractor =
      getIt.get<UploadContentInBytesInteractor>();

  final MenuController menuController = MenuController();

  Profile? currentProfile;
  AssetEntity? assetEntity;
  FilePickerResult? filePickerResult;

  List<TwakeChatPresentationAccount> _multipleAccounts = [];

  final TwakeEventDispatcher twakeEventDispatcher =
      getIt.get<TwakeEventDispatcher>();

  final ValueNotifier<bool> isEditedProfileNotifier = ValueNotifier(false);

  final ValueNotifier<Either<Failure, Success>> settingsProfileUIState =
      ValueNotifier<Either<Failure, Success>>(Right(GetAvatarInitialUIState()));

  final settingsMultiAccountsUIState = ValueNotifier<Either<Failure, Success>>(
    Right(GetClientsInitialUIState()),
  );

  Client get client => Matrix.of(context).client;

  bool get _hasEditedDisplayName =>
      displayNameEditingController.text != displayName;

  String get displayName =>
      currentProfile?.displayName ??
      client.mxid(context).localpart ??
      client.mxid(context);

  final TextEditingController displayNameEditingController =
      TextEditingController();
  final TextEditingController matrixIdEditingController =
      TextEditingController();

  final FocusNode displayNameFocusNode = FocusNode(
    debugLabel: 'displayNameFocusNode',
  );

  List<SettingsProfileEnum> get getListProfileMobile =>
      getListProfileBasicInfo + getListProfileWorkIdentitiesInfo;

  final List<SettingsProfileEnum> getListProfileBasicInfo = [
    SettingsProfileEnum.displayName,
  ];

  final List<SettingsProfileEnum> getListProfileWorkIdentitiesInfo = [
    SettingsProfileEnum.matrixId,
  ];

  List<SheetAction<AvatarAction>> actions() => [
        SheetAction(
          key: AvatarAction.file,
          label: L10n.of(context)!.changeProfileAvatar,
          icon: Icons.add_a_photo_outlined,
        ),
        if (currentProfile?.avatarUrl != null)
          SheetAction(
            key: AvatarAction.remove,
            label: L10n.of(context)!.removeYourAvatar,
            isDestructiveAction: true,
            icon: Icons.delete_outlined,
          ),
      ];

  TextEditingController? getController(
    SettingsProfileEnum settingsProfileEnum,
  ) {
    switch (settingsProfileEnum) {
      case SettingsProfileEnum.displayName:
        return displayNameEditingController;
      case SettingsProfileEnum.matrixId:
        return matrixIdEditingController;
      default:
        return null;
    }
  }

  FocusNode? getFocusNode(SettingsProfileEnum settingsProfileEnum) {
    switch (settingsProfileEnum) {
      case SettingsProfileEnum.displayName:
        return displayNameFocusNode;
      default:
        return null;
    }
  }

  void _handleRemoveAvatarAction() async {
    if (assetEntity != null || filePickerResult != null) {
      isEditedProfileNotifier.toggle();
    }
    if (currentProfile?.avatarUrl == null) {
      _clearImageInLocal();
      settingsProfileUIState.value = Right<Failure, Success>(
        GetProfileUIStateSuccess(
          currentProfile!,
        ),
      );
    } else {
      TwakeDialog.showLoadingDialog(context);
      final newProfile = Profile(
        userId: client.userID!,
        displayName: displayName,
        avatarUrl: null,
      );
      settingsProfileUIState.value =
          Right<Failure, Success>(GetProfileUIStateSuccess(newProfile));
      _uploadProfile(isDeleteAvatar: true);
    }
  }

  void _getImageOnWeb(
    BuildContext context,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    Logs().d(
      'SettingsProfile::_getImageOnWeb(): FilePickerResult - $result',
    );
    if (result == null || result.files.single.bytes == null) {
      return;
    } else {
      if (!isEditedProfileNotifier.value) {
        isEditedProfileNotifier.toggle();
      }
      settingsProfileUIState.value = Right<Failure, Success>(
        GetAvatarInBytesUIStateSuccess(
          filePickerResult: result,
        ),
      );
      Logs().d(
        'SettingsProfile::_getImageOnWeb(): AvatarWebNotifier - $result',
      );
    }
  }

  void _showImagesPickerAction() async {
    if (PlatformInfos.isWeb) {
      _getImageOnWeb(context);
      return;
    }
    final currentPermissionPhotos = await getCurrentMediaPermission();
    if (currentPermissionPhotos != null) {
      final imagePickerController = createImagePickerController();
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
        settingsProfileUIState.value = Right<Failure, Success>(
          GetAvatarInStreamUIStateSuccess(
            assetEntity: selectedAsset?.asset,
          ),
        );
        if (!isEditedProfileNotifier.value) {
          isEditedProfileNotifier.toggle();
        }
        imagePickerController.removeAllSelectedItem();
      }
    });

    return imagePickerController;
  }

  void onTapAvatarInMobile() async {
    final action = await showModalActionSheet<AvatarAction>(
      context: context,
      title: L10n.of(context)!.changeYourAvatar,
      actions: actions(),
    );
    if (action == null) return;
    if (action == AvatarAction.remove) {
      _handleRemoveAvatarAction();
      return;
    }
    _showImagesPickerAction();
  }

  List<PopupMenuItem> listContextMenuBuilder(
    BuildContext context,
  ) {
    final listAction = [
      SettingsProfileContextMenuActions.edit,
      SettingsProfileContextMenuActions.delete,
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

  void _handleActionContextMenu(SettingsProfileContextMenuActions action) {
    switch (action) {
      case SettingsProfileContextMenuActions.edit:
        _showImagesPickerAction();
        break;
      case SettingsProfileContextMenuActions.delete:
        _handleRemoveAvatarAction();
        break;
    }
  }

  void _sendAccountDataEvent({
    required Profile profile,
  }) async {
    Logs().d(
      'SettingsProfileController::_handleSyncProfile() - Syncing profile',
    );
    twakeEventDispatcher.sendAccountDataEvent(
      client: client,
      basicEvent: BasicEvent(
        type: TwakeInappEventTypes.uploadAvatarEvent,
        content: profile.toJson(),
      ),
    );
    Logs().d(
      'SettingsProfileController::_handleSyncProfile() - Syncing success',
    );
  }

  void _setAvatarInStream() {
    if (assetEntity != null) {
      uploadContentInteractor
          .execute(
            matrixClient: client,
            entity: assetEntity!,
          )
          .listen(
            (event) => _handleUploadAvatarOnData(context, event),
            onDone: _handleUploadAvatarOnDone,
            onError: _handleUploadAvatarOnError,
          );
    } else {
      _uploadProfile(displayName: displayNameEditingController.text);
    }
  }

  void _setAvatarInBytes() {
    if (filePickerResult != null) {
      uploadContentWebInteractor
          .execute(
            matrixClient: client,
            filePickerResult: filePickerResult!,
          )
          .listen(
            (event) => _handleUploadAvatarOnData(context, event),
            onDone: _handleUploadAvatarOnDone,
            onError: _handleUploadAvatarOnError,
          );
    } else {
      _uploadProfile(displayName: displayNameEditingController.text);
    }
  }

  void onUploadProfileAction() {
    displayNameFocusNode.unfocus();
    TwakeDialog.showLoadingDialog(context);
    if (PlatformInfos.isMobile) {
      _setAvatarInStream();
    } else {
      _setAvatarInBytes();
    }
  }

  void _clearImageInLocal() {
    Logs().d(
      'SettingsProfile::_clearImageInLocal() - Clear image in local',
    );
    if (assetEntity != null) {
      assetEntity = null;
    }
    if (filePickerResult != null) {
      filePickerResult = null;
    }
  }

  void _handleUploadAvatarOnDone() {
    Logs().d(
      'SettingsProfile::_handleUploadAvatarOnDone() - done',
    );
  }

  void _handleUploadAvatarOnError(
    dynamic error,
    StackTrace? stackTrace,
  ) {
    TwakeDialog.hideLoadingDialog(context);
    Logs().e(
      'SettingsProfile::_handleUploadAvatarOnError() - error: $error | stackTrace: $stackTrace',
    );
  }

  void _handleUploadAvatarOnData(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    Logs().d('SettingsProfile::_handleUploadAvatarOnData()');
    event.fold(
      (failure) {
        Logs().e(
          'SettingsProfile::_handleUploadAvatarOnData() - failure: $failure',
        );
        if (failure is UploadContentFailed) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(
            context,
            failure.exception.toString(),
          );
        } else if (failure is FileTooBigMatrix) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(
            context,
            failure.fileTooBigMatrixException.toString(),
          );
        }
      },
      (success) {
        Logs().d(
          'SettingsProfile::_handleUploadAvatarOnData() - success: $success',
        );
        if (success is UploadContentSuccess) {
          _uploadProfile(
            avatarUr: success.uri,
            displayName: _hasEditedDisplayName
                ? displayNameEditingController.text
                : null,
          );
        }
      },
    );
  }

  void _uploadProfile({
    Uri? avatarUr,
    String? displayName,
    bool isDeleteAvatar = false,
  }) async {
    uploadProfileInteractor
        .execute(
          client: client,
          avatarUrl: avatarUr,
          isDeleteAvatar: isDeleteAvatar,
          displayName: displayName,
        )
        .listen(
          (event) => _handleUploadProfileOnData(context, event),
          onDone: _handleUploadProfileOnDone,
          onError: _handleUploadProfileOnError,
        );
  }

  void _handleUploadProfileOnDone() {
    Logs().d(
      'SettingsProfile::_handleUploadProfileOnDone() - done',
    );
  }

  void _handleUploadProfileOnError(
    dynamic error,
    StackTrace? stackTrace,
  ) {
    TwakeDialog.hideLoadingDialog(context);
    Logs().e(
      'SettingsProfile::_handleUploadProfileOnError() - error: $error | stackTrace: $stackTrace',
    );
  }

  void _handleUploadProfileOnData(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    Logs().d('SettingsProfile::_handleUploadProfileOnData()');
    event.fold(
      (failure) {
        Logs().e(
          'SettingsProfile::_handleUploadProfileOnData() - failure: $failure',
        );
        if (failure is UpdateProfileFailure) {
          _handleUpdateProfileFailure(failure.exception.toString());
        }
      },
      (success) {
        Logs().d(
          'SettingsProfile::_handleUploadProfileOnData() - success: $success',
        );
        if (success is UpdateProfileSuccess) {
          final newProfile = Profile(
            userId: client.userID!,
            displayName: success.displayName ?? displayName,
            avatarUrl: success.avatar ?? currentProfile?.avatarUrl,
          );
          _sendAccountDataEvent(profile: newProfile);
          if (!success.isDeleteAvatar) {
            isEditedProfileNotifier.toggle();
          }
          _getCurrentProfile(client, isUpdated: true);
          TwakeDialog.hideLoadingDialog(context);
        }
      },
    );
  }

  void _getCurrentProfile(
    Client client, {
    isUpdated = false,
  }) async {
    final profile = await client.getProfileFromUserId(
      client.userID!,
      cache: !isUpdated,
      getFromRooms: false,
    );
    Logs().d(
      'SettingsProfileController::_getCurrentProfile() - currentProfile: $profile',
    );
    settingsProfileUIState.value =
        Right<Failure, Success>(GetProfileUIStateSuccess(profile));
    Logs().d(
      'SettingsProfileController::_getCurrentProfile() - currentProfile: ${settingsProfileUIState.value}',
    );
    if (profile.avatarUrl == null) {
      _clearImageInLocal();
    }
    displayNameEditingController.text = displayName;
    matrixIdEditingController.text = client.mxid(context);
  }

  void handleTextEditOnChange(SettingsProfileEnum settingsProfileEnum) {
    switch (settingsProfileEnum) {
      case SettingsProfileEnum.displayName:
        _listeningDisplayNameHasChange();
        break;
      default:
        break;
    }
  }

  void _listeningDisplayNameHasChange() {
    if (displayNameEditingController.text.isEmpty) {
      isEditedProfileNotifier.value = false;
      return;
    }
    isEditedProfileNotifier.value =
        displayNameEditingController.text != displayName;
    Logs().d(
      'SettingsProfileController::_listeningDisplayNameHasChange() - ${isEditedProfileNotifier.value}',
    );
  }

  void copyEventsAction(SettingsProfileEnum settingsProfileEnum) {
    switch (settingsProfileEnum) {
      case SettingsProfileEnum.matrixId:
        Clipboard.setData(ClipboardData(text: client.mxid(context)));
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.copiedMatrixIdToClipboard,
        );
        break;
      default:
        break;
    }
  }

  Future<void> _getMultipleAccounts(
    Client currentActiveClient,
  ) async {
    try {
      settingsMultiAccountsUIState.value = Right(GetClientsLoadingUIState());
      final profileBundles = await _getClientProfiles();
      _multipleAccounts = profileBundles
          .where((clientProfile) => clientProfile != null)
          .map(
            (clientProfile) => clientProfile!.toTwakeChatPresentationAccount(
              currentActiveClient,
            ),
          )
          .toList();
      settingsMultiAccountsUIState.value = Right(
        GetClientsSuccessUIState(
          multipleAccounts: _multipleAccounts,
        ),
      );
    } catch (e) {
      Logs().e(
        'SettingsProfileController::_getMultipleAccounts() - Error: $e',
      );
      settingsMultiAccountsUIState.value = Left<Failure, Success>(
        GetClientsFailureUIState(
          exception: e,
        ),
      );
    }
  }

  Future<List<ClientProfilePresentation?>> _getClientProfiles() async {
    try {
      final profiles = await Future.wait(
        (await ClientManager.getClients()).map((client) async {
          final profileBundle = await client.fetchOwnProfile();
          Logs().d(
            'SettingsProfileController::getProfileBundles() - ClientName - ${client.clientName}',
          );
          Logs().d(
            'SettingsProfileController::getProfileBundles() - UserId - ${client.userID}',
          );
          return ClientProfilePresentation(
            profile: profileBundle,
            client: client,
          );
        }),
      );

      return profiles.toList();
    } catch (e) {
      Logs().e(
        'SettingsProfileController::getProfileBundles() - Error: $e',
      );
      rethrow;
    }
  }

  void onBottomButtonTap({
    required List<TwakeChatPresentationAccount> multipleAccounts,
  }) {
    MultipleAccountsPickerController(
      context: context,
      multipleAccounts: multipleAccounts,
    ).showMultipleAccountsPicker(
      client,
      onGoToAccountSettings: () {
        context.go('/rooms/profile');
      },
    );
  }

  void _handleViewState() {
    settingsProfileUIState.addListener(() {
      Logs().d(
        "settingsProfileUIState()::_handleViewState(): ${settingsProfileUIState.value}",
      );
      settingsProfileUIState.value.fold(
        (failure) => null,
        (success) {
          switch (success.runtimeType) {
            case const (GetAvatarInStreamUIStateSuccess):
              final uiState = success as GetAvatarInStreamUIStateSuccess;
              assetEntity = uiState.assetEntity;
              break;
            case const (GetAvatarInBytesUIStateSuccess):
              final uiState = success as GetAvatarInBytesUIStateSuccess;
              filePickerResult = uiState.filePickerResult;
              break;
            case const (GetProfileUIStateSuccess):
              final uiState = success as GetProfileUIStateSuccess;
              currentProfile = uiState.profile;
              break;
            default:
              break;
          }
        },
      );
    });
  }

  void _handleUpdateProfileFailure(String errorMessage) {
    TwakeDialog.hideLoadingDialog(context);
    TwakeSnackBar.show(
      context,
      errorMessage,
    );
    _clearImageInLocal();
    if (currentProfile != null) {
      _sendAccountDataEvent(profile: currentProfile!);
    }
  }

  @override
  void initState() {
    _handleViewState();
    _getCurrentProfile(client);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      updateNewProfileForAccount();
      _getMultipleAccounts(client);
    });
    super.initState();
  }

  void updateNewProfileForAccount() {
    listenOnProfileChangeStream(
      client: Matrix.of(context).client,
      currentProfile: currentProfile,
      onProfileChanged: (newProfile) {
        final indexOldAccount = _multipleAccounts
            .indexWhere((element) => element.accountId == client.userID);
        if (indexOldAccount < 0) {
          return;
        }
        final newAccount = ClientProfilePresentation(
          client: Matrix.of(context).client,
          profile: newProfile,
        ).toTwakeChatPresentationAccount(Matrix.of(context).client);
        _multipleAccounts[indexOldAccount] = newAccount;
        settingsMultiAccountsUIState.value = Right<Failure, Success>(
          GetClientsSuccessUIState(
            multipleAccounts: _multipleAccounts,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _clearImageInLocal();
    onAccountDataSubscription?.cancel();
    displayNameEditingController.dispose();
    matrixIdEditingController.dispose();
    displayNameFocusNode.dispose();
    settingsProfileUIState.dispose();
    isEditedProfileNotifier.dispose();
    settingsMultiAccountsUIState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsProfileView(
      controller: this,
    );
  }
}
