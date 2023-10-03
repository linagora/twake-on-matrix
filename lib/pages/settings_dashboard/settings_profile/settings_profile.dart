import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/event/twake_event_dispatcher.dart';
import 'package:fluffychat/event/twake_inapp_event_types.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_item_style.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view.dart';
import 'package:fluffychat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SettingsProfile extends StatefulWidget {
  final Profile? profile;

  const SettingsProfile({
    super.key,
    required this.profile,
  });

  @override
  State<SettingsProfile> createState() => SettingsProfileController();
}

class SettingsProfileController extends State<SettingsProfile> {
  final ValueNotifier<Profile> profileNotifier = ValueNotifier(
    Profile(userId: ''),
  );

  final TwakeEventDispatcher twakeEventDispatcher =
      getIt.get<TwakeEventDispatcher>();

  final ValueNotifier<bool> isEditedProfileNotifier = ValueNotifier(false);

  Client get client => Matrix.of(context).client;

  MatrixState get matrix => Matrix.of(context);

  String get displayName =>
      profileNotifier.value.displayName ??
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
    SettingsProfileEnum.matrixId
  ];

  List<SheetAction<AvatarAction>> actions() => [
        if (PlatformInfos.isMobile)
          SheetAction(
            key: AvatarAction.camera,
            label: L10n.of(context)!.openCamera,
            isDefaultAction: true,
            icon: Icons.camera_alt_outlined,
          ),
        SheetAction(
          key: AvatarAction.file,
          label: L10n.of(context)!.openGallery,
          icon: Icons.photo_outlined,
        ),
        if (profileNotifier.value.avatarUrl != null)
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
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => matrix.client.setAvatar(null),
    );
    if (success.error == null) {
      _getCurrentProfile(client, isUpdated: true);
    }
    return;
  }

  Future<MatrixFile?> _handleGetAvatarInByte() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final pickedFile = result?.files.firstOrNull;
    if (pickedFile == null || pickedFile.bytes == null) return null;
    return MatrixFile(
      bytes: pickedFile.bytes!,
      name: pickedFile.name,
    );
  }

  Future<MatrixFile?> _handleGetAvatarInStream(AvatarAction action) async {
    final result = await ImagePicker().pickImage(
      source: action == AvatarAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: AppConfig.imageQuality,
    );
    if (result == null) return null;
    return MatrixFile(
      bytes: await result.readAsBytes(),
      name: result.path,
    );
  }

  void _handleGetAvatarAction(AvatarAction action) async {
    MatrixFile file;
    if (PlatformInfos.isMobile) {
      final matrixFile = await _handleGetAvatarInStream(action);
      if (matrixFile == null) return;
      file = matrixFile;
    } else {
      final matrixFile = await _handleGetAvatarInByte();
      if (matrixFile == null) return;
      file = matrixFile;
    }
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => matrix.client.setAvatar(file),
    );
    if (success.error == null) {
      _getCurrentProfile(client, isUpdated: true);
    }
  }

  void setAvatarAction() async {
    final action = actions().length == 1
        ? actions().single.key
        : await showModalActionSheet<AvatarAction>(
            context: context,
            title: L10n.of(context)!.changeYourAvatar,
            actions: actions(),
          );
    if (action == null) return;
    if (action == AvatarAction.remove) {
      _handleRemoveAvatarAction();
    }
    _handleGetAvatarAction(action);
  }

  void _handleSyncProfile() async {
    Logs().d(
      'SettingsProfileController::_handleSyncProfile() - Syncing profile',
    );
    twakeEventDispatcher.sendAccountDataEvent(
      client: client,
      basicEvent: BasicEvent(
        type: TwakeInappEventTypes.uploadAvatarEvent,
        content: profileNotifier.value.toJson(),
      ),
    );
    Logs().d(
      'SettingsProfileController::_handleSyncProfile() - Syncing success',
    );
  }

  void setDisplayNameAction() async {
    if (displayNameFocusNode.hasFocus) {
      displayNameFocusNode.unfocus();
    }
    final matrix = Matrix.of(context);
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => matrix.client.setDisplayName(
        matrix.client.userID!,
        displayNameEditingController.text,
      ),
    );
    if (success.error == null) {
      isEditedProfileNotifier.toggle();
      _getCurrentProfile(client, isUpdated: true);
    }
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
    profileNotifier.value = profile;
    displayNameEditingController.text = displayName;
    matrixIdEditingController.text = client.mxid(context);
    _handleSyncProfile();
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
    isEditedProfileNotifier.value =
        displayNameEditingController.text != displayName;
    Logs().d(
      'SettingsProfileController::_listeningDisplayNameHasChange() - ${isEditedProfileNotifier.value}',
    );
  }

  void _initProfile() {
    if (widget.profile == null) {
      _getCurrentProfile(client);
      return;
    }
    profileNotifier.value = widget.profile!;
    displayNameEditingController.text = displayName;
    matrixIdEditingController.text = client.mxid(context);
  }

  void copyEventsAction(SettingsProfileEnum settingsProfileEnum) {
    switch (settingsProfileEnum) {
      case SettingsProfileEnum.matrixId:
        Clipboard.setData(ClipboardData(text: client.mxid(context)));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            width: SettingsProfileItemStyle.widthSnackBar(context),
            padding: SettingsProfileItemStyle.snackBarPadding,
            content: Text(
              L10n.of(context)!.copiedMatrixIdToClipboard,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.background,
                  ),
            ),
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    _initProfile();
    super.initState();
  }

  @override
  void dispose() {
    displayNameEditingController.dispose();
    matrixIdEditingController.dispose();
    displayNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsProfileView(
      controller: this,
    );
  }
}
