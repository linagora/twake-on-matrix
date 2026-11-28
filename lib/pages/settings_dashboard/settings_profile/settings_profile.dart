import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/room/upload_content_state.dart';
import 'package:twake_chat/domain/app_state/settings/update_profile_failure.dart';
import 'package:twake_chat/domain/app_state/settings/update_profile_success.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/domain/usecase/settings/update_profile_interactor.dart';
import 'package:twake_chat/event/twake_event_dispatcher.dart';
import 'package:twake_chat/event/twake_inapp_event_types.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.provider.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/pages/multiple_accounts/multiple_accounts_picker.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_controller.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_state.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_capability_check.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_edit_rules.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_view.dart';
import 'package:twake_chat/presentation/extensions/multiple_accounts/client_profile_extension.dart';
import 'package:twake_chat/presentation/mixins/pick_avatar_mixin.dart';
import 'package:twake_chat/presentation/model/pick_avatar_state.dart';
import 'package:twake_chat/presentation/multiple_account/client_profile_presentation.dart';
import 'package:twake_chat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:twake_chat/presentation/mixins/single_image_picker_mixin.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/utils/client_manager.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class SettingsProfile extends ConsumerStatefulWidget {
  const SettingsProfile({super.key});

  @override
  ConsumerState<SettingsProfile> createState() => SettingsProfileScreenState();
}

class SettingsProfileScreenState extends ConsumerState<SettingsProfile>
    with
        CommonMediaPickerMixin,
        SingleImagePickerMixin,
        PopupContextMenuActionMixin,
        PickAvatarMixin,
        SingleTickerProviderStateMixin {
  final uploadProfileInteractor = getIt.get<UpdateProfileInteractor>();
  final uploadContentInteractor = getIt.get<UploadContentInteractor>();
  final uploadContentWebInteractor = getIt
      .get<UploadContentInBytesInteractor>();

  final MenuController menuController = MenuController();

  late final AnimationController animationController;
  static const int _animationDuration = 100;
  ValueNotifier<bool> isExpandedAvatar = ValueNotifier(false);
  Timer? _avatarToggleTimer;

  AssetEntity? assetEntity;
  MatrixFile? matrixFile;

  ProviderSubscription<AsyncValue<SettingsProfileState>>? _profileSubscription;

  final TwakeEventDispatcher twakeEventDispatcher = getIt
      .get<TwakeEventDispatcher>();

  final ValueNotifier<bool> isEditedProfileNotifier = ValueNotifier(false);

  Client get client => ref.read(matrixClientProvider);

  SettingsProfileController get _profileController =>
      ref.read(settingsProfileControllerProvider.notifier);

  AccountProfile? get _profile =>
      ref.read(settingsProfileControllerProvider).value?.profile;

  String? get _editedDisplayName => SettingsProfileEditRules.editedDisplayName(
    text: displayNameEditingController.text,
    currentName: displayName,
  );

  bool get _hasPendingAvatar => assetEntity != null || matrixFile != null;

  void _refreshEditedState() {
    isEditedProfileNotifier.value = SettingsProfileEditRules.hasChanges(
      text: displayNameEditingController.text,
      currentName: displayName,
      hasPendingAvatar: _hasPendingAvatar,
    );
  }

  String get displayName => _nameOf(_profile);

  String _nameOf(AccountProfile? profile) =>
      profile?.displayName ??
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

  bool get hasAvatar => _profile?.avatarUrl?.toString().isNotEmpty ?? false;

  List<SheetAction<AvatarAction>> actions() => [
    SheetAction(
      key: AvatarAction.file,
      label: SettingsProfileContextMenuActions.edit.getTitle(
        context,
        hasAvatar: hasAvatar,
      ),
      icon: Icons.add_a_photo_outlined,
    ),
    if (hasAvatar)
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
    _clearImageInLocal();
    _refreshEditedState();
    if (hasAvatar) {
      TwakeDialog.showLoadingDialog(context);
      _uploadProfile(isDeleteAvatar: true);
    }
  }

  void _showImagesPickerAction() async {
    if (PlatformInfos.isDesktop) {
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
        pickAvatarUIState.value = Right<Failure, Success>(
          GetAvatarOnMobileUIStateSuccess(assetEntity: selectedAsset?.asset),
        );
        _refreshEditedState();
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

  List<Widget> listContextMenuBuilder(
    BuildContext context, {
    required bool hasAvatar,
  }) {
    return [
      SettingsProfileContextMenu(
        hasAvatar: hasAvatar,
        onAction: (action) {
          menuController.close();
          _handleActionContextMenu(action);
        },
      ),
    ];
  }

  void _handleActionContextMenu(SettingsProfileContextMenuActions action) {
    switch (action) {
      case SettingsProfileContextMenuActions.edit:
        _showImagesPickerAction();
        break;
      case SettingsProfileContextMenuActions.delete:
        pickAvatarUIState.value = Right<Failure, Success>(
          GetAvatarInitialUIState(),
        );
        _handleRemoveAvatarAction();
        break;
    }
  }

  static Profile _toSdkProfile(AccountProfile profile) => Profile(
    userId: profile.userId,
    displayName: profile.displayName,
    avatarUrl: profile.avatarUrl,
  );

  void _sendAccountDataEvent({required AccountProfile profile}) async {
    Logs().d(
      'SettingsProfileController::_handleSyncProfile() - Syncing profile',
    );
    twakeEventDispatcher.sendAccountDataEvent(
      client: client,
      basicEvent: BasicEvent(
        type: TwakeInappEventTypes.uploadAvatarEvent,
        content: _toSdkProfile(profile).toJson(),
      ),
    );
    Logs().d(
      'SettingsProfileController::_handleSyncProfile() - Syncing success',
    );
  }

  void _setAvatarInStream() {
    if (assetEntity != null) {
      uploadContentInteractor
          .execute(matrixClient: client, entity: assetEntity!)
          .listen(
            (event) => _handleUploadAvatarOnData(context, event),
            onDone: _handleUploadAvatarOnDone,
            onError: _handleUploadAvatarOnError,
          );
    } else {
      _uploadProfile(displayName: _editedDisplayName);
    }
  }

  void _setAvatarOnWeb() {
    if (matrixFile != null) {
      uploadContentWebInteractor
          .execute(matrixClient: client, matrixFile: matrixFile!)
          .listen(
            (event) => _handleUploadAvatarOnData(context, event),
            onDone: _handleUploadAvatarOnDone,
            onError: _handleUploadAvatarOnError,
          );
    } else {
      _uploadProfile(displayName: _editedDisplayName);
    }
  }

  void onUploadProfileAction() {
    displayNameFocusNode.unfocus();
    TwakeDialog.showLoadingDialog(context);
    if (PlatformInfos.isMobile) {
      _setAvatarInStream();
    } else {
      _setAvatarOnWeb();
    }
  }

  void _clearImageInMemory() {
    Logs().d('SettingsProfile::_clearImageInLocal() - Clear image in local');
    if (assetEntity != null) {
      assetEntity = null;
    }
    if (matrixFile != null) {
      matrixFile = null;
    }
  }

  void _handleUploadAvatarOnDone() {
    Logs().d('SettingsProfile::_handleUploadAvatarOnDone() - done');
  }

  void _handleUploadAvatarOnError(dynamic error, StackTrace? stackTrace) {
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
          TwakeSnackBar.show(context, failure.exception.toString());
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
            displayName: _editedDisplayName,
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
    Logs().d('SettingsProfile::_handleUploadProfileOnDone() - done');
  }

  void _handleUploadProfileOnError(dynamic error, StackTrace? stackTrace) {
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
          _applySavedProfile(
            AccountProfile(
              userId: client.userID!,
              displayName: success.displayName ?? displayName,
              avatarUrl: success.avatar ?? _profile?.avatarUrl,
            ),
          );
        }

        if (success is DeleteProfileSuccess) {
          _applySavedProfile(
            AccountProfile(
              userId: client.userID!,
              displayName: success.displayName ?? displayName,
            ),
          );
          pickAvatarUIState.value = Right<Failure, Success>(
            DeleteAvatarUIStateSuccess(),
          );
        }
      },
    );
  }

  void _applySavedProfile(AccountProfile profile) {
    _sendAccountDataEvent(profile: profile);
    _profileController.applySaved(profile);
    _clearImageInLocal();
    _refreshEditedState();
    unawaited(_profileController.refresh());
    TwakeDialog.hideLoadingDialog(context);
  }

  void _onProfileChanged(
    AsyncValue<SettingsProfileState>? previous,
    AsyncValue<SettingsProfileState> next,
  ) {
    final previousProfile = previous?.value?.profile;
    final profile = next.value?.profile;
    if (profile == null || profile == previousProfile) return;
    if (SettingsProfileEditRules.shouldSyncName(
      text: displayNameEditingController.text,
      shownName: _nameOf(previousProfile),
    )) {
      displayNameEditingController.text = displayName;
    }
    matrixIdEditingController.text = client.mxid(context);
    _refreshEditedState();
  }

  void onDisplayNameChanged() => _refreshEditedState();

  void onDisplayNameSubmitted() {
    if (isEditedProfileNotifier.value) {
      onUploadProfileAction();
    }
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

  // TODO: [transitional] #3828 MultipleAccountsPickerController still takes Clients.
  void onBottomButtonTap(List<AccountProfile> accounts) {
    final profile = _profile;
    final clients = ClientManager.loggedIn(
      ref.read(accountClientRegistryProvider).clients,
    );
    MultipleAccountsPickerController(
      context: context,
      multipleAccounts: [
        for (final account in accounts)
          if (clients.firstWhereOrNull((c) => c.userID == account.userId)
              case final accountClient?)
            ClientProfilePresentation(
              client: accountClient,
              profile: _toSdkProfile(
                profile != null && account.userId == profile.userId
                    ? profile
                    : account,
              ),
            ).toTwakeChatPresentationAccount(client),
      ],
    ).showMultipleAccountsPicker(
      client,
      onGoToAccountSettings: () {
        const ProfileRoute().go(context);
      },
    );
  }

  void _handleViewState() {
    pickAvatarUIState.addListener(() {
      Logs().d(
        "settingsProfileUIState()::_handleViewState(): ${pickAvatarUIState.value}",
      );
      pickAvatarUIState.value.fold(
        (failure) {
          if (failure is GetAvatarBigSizeUIStateFailure ||
              failure is GetAvatarUIStateFailure) {
            _refreshEditedState();
          }
        },
        (success) {
          switch (success) {
            case final GetAvatarOnMobileUIStateSuccess uiState:
              assetEntity = uiState.assetEntity;
              break;
            case final GetAvatarOnWebUIStateSuccess uiState:
              matrixFile = uiState.matrixFile;
              _refreshEditedState();
              break;
            default:
              break;
          }
        },
      );
    });
  }

  void updateMatrixFile(MatrixFile newMatrixFile) {
    matrixFile = newMatrixFile;
    _refreshEditedState();
  }

  void _handleUpdateProfileFailure(String errorMessage) {
    TwakeDialog.hideLoadingDialog(context);
    TwakeSnackBar.show(context, errorMessage);
    _clearImageInLocal();
    _refreshEditedState();
    final profile = _profile;
    if (profile != null) {
      _sendAccountDataEvent(profile: profile);
    }
  }

  void _clearImageInLocal() {
    Logs().d('SettingsProfile::_clearImageInLocal() - Clear image in local');
    if (assetEntity != null) {
      assetEntity = null;
    }
    if (matrixFile != null) {
      matrixFile = null;
    }
  }

  void handleAvatarInfoTap() {
    // Prevent rapid tapping during animation or pending delayed toggle
    if (animationController.isAnimating ||
        (_avatarToggleTimer?.isActive ?? false)) {
      return;
    }
    if (animationController.isCompleted) {
      animationController.reverse();
      _avatarToggleTimer = Timer(
        const Duration(milliseconds: _animationDuration),
        () {
          if (mounted) {
            isExpandedAvatar.value = false;
          }
        },
      );
    } else {
      isExpandedAvatar.value = true;
      _avatarToggleTimer = Timer(
        const Duration(milliseconds: _animationDuration),
        () {
          if (mounted) {
            animationController.forward();
          }
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _animationDuration),
    );
    _handleViewState();
    _profileSubscription = ref.listenManual(
      settingsProfileControllerProvider,
      _onProfileChanged,
    );
    listenToPickAvatarUIState(context);
  }

  @override
  void dispose() {
    _profileSubscription?.close();
    animationController.dispose();
    isExpandedAvatar.dispose();
    _clearImageInLocal();
    _clearImageInMemory();
    disposePickAvatarMixin();
    displayNameEditingController.dispose();
    matrixIdEditingController.dispose();
    displayNameFocusNode.dispose();
    isEditedProfileNotifier.dispose();
    _avatarToggleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsProfileCapabilityCheck(
      userId: client.userID,
      builder: (capabilities, userInfo, _) {
        return SettingsProfileView(
          controller: this,
          capabilities: capabilities,
          userInfo: userInfo,
        );
      },
    );
  }
}
