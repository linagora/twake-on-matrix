import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.provider.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/presentation/extensions/settings/avatar_upload_extension.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
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
  final MenuController menuController = MenuController();

  late final AnimationController animationController;
  static const int _animationDuration = 100;
  ValueNotifier<bool> isExpandedAvatar = ValueNotifier(false);
  Timer? _avatarToggleTimer;

  AssetEntity? assetEntity;
  MatrixFile? matrixFile;

  ProviderSubscription<AsyncValue<SettingsProfileState>>? _profileSubscription;

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

  Future<void> _handleRemoveAvatarAction() async {
    _clearImageInLocal();
    _refreshEditedState();
    if (!hasAvatar) return;
    TwakeDialog.showLoadingDialog(context);
    try {
      await _profileController.removeAvatar();
      if (!mounted) return;
      pickAvatarUIState.value = Right<Failure, Success>(
        DeleteAvatarUIStateSuccess(),
      );
    } on RemoveOwnAvatarException catch (e) {
      if (mounted) TwakeSnackBar.show(context, e.cause.toString());
    } finally {
      if (mounted) TwakeDialog.hideLoadingDialog(context);
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
      unawaited(_handleRemoveAvatarAction());
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
        unawaited(_handleRemoveAvatarAction());
        break;
    }
  }

  static Profile _toSdkProfile(AccountProfile profile) => Profile(
    userId: profile.userId,
    displayName: profile.displayName,
    avatarUrl: profile.avatarUrl,
  );

  Future<void> onUploadProfileAction() async {
    displayNameFocusNode.unfocus();
    TwakeDialog.showLoadingDialog(context);
    try {
      await _profileController.save(
        displayName: _editedDisplayName,
        avatar: await _pendingAvatar(),
      );
    } on SaveOwnProfileException catch (e) {
      if (mounted) TwakeSnackBar.show(context, e.cause.toString());
    } finally {
      if (mounted) {
        _clearImageInLocal();
        _refreshEditedState();
        TwakeDialog.hideLoadingDialog(context);
      }
    }
  }

  Future<AvatarUpload?> _pendingAvatar() async {
    if (matrixFile case final file?) {
      return AvatarUpload.fromBytes(
        bytes: file.bytes,
        name: file.name,
        mimeType: file.mimeType,
      );
    }
    return assetEntity?.toAvatarUpload();
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
      unawaited(onUploadProfileAction());
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
