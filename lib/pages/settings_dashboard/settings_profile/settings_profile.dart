import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_dashboard_manager.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view.dart';
import 'package:fluffychat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
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
  final settingsDashboardManagerController =
      SettingsDashboardManagerController();

  final ValueNotifier<bool> isEditedProfileNotifier = ValueNotifier(false);

  Client get client => Matrix.of(context).client;

  String get mxid => settingsDashboardManagerController.mxid(context);

  String get displayName =>
      settingsDashboardManagerController.displayName(context);

  final TextEditingController displayNameEditingController =
      TextEditingController();
  final TextEditingController matrixIdEditingController =
      TextEditingController();

  final FocusNode displayNameFocusNode = FocusNode(
    debugLabel: 'displayNameFocusNode',
  );

  List<SettingsProfileEnum> get getListProfileMobile =>
      getListProfileBasicInfo + getListProfileWorkIdentitiesInfo;

  List<SettingsProfileEnum> getListProfileBasicInfo = [
    SettingsProfileEnum.displayName,
  ];

  List<SettingsProfileEnum> getListProfileWorkIdentitiesInfo = [
    SettingsProfileEnum.matrixId
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

  void setAvatarAction() async {
    final actions = [
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
      if (settingsDashboardManagerController.profileNotifier.value.avatarUrl !=
          null)
        SheetAction(
          key: AvatarAction.remove,
          label: L10n.of(context)!.removeYourAvatar,
          isDestructiveAction: true,
          icon: Icons.delete_outlined,
        ),
    ];
    final action = actions.length == 1
        ? actions.single.key
        : await showModalActionSheet<AvatarAction>(
            context: context,
            title: L10n.of(context)!.changeYourAvatar,
            actions: actions,
          );
    if (action == null) return;
    final matrix = Matrix.of(context);
    if (action == AvatarAction.remove) {
      final success = await showFutureLoadingDialog(
        context: context,
        future: () => matrix.client.setAvatar(null),
      );
      if (success.error == null) {
        _getProfileFromUserId(isUpdated: true);
      }
      return;
    }
    MatrixFile file;
    if (PlatformInfos.isMobile) {
      final result = await ImagePicker().pickImage(
        source: action == AvatarAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 50,
      );
      if (result == null) return;
      file = MatrixFile(
        bytes: await result.readAsBytes(),
        name: result.path,
      );
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final pickedFile = result?.files.firstOrNull;
      if (pickedFile == null) return;
      file = MatrixFile(
        bytes: pickedFile.bytes!,
        name: pickedFile.name,
      );
    }
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => matrix.client.setAvatar(file),
    );
    if (success.error == null) {
      _getProfileFromUserId(isUpdated: true);
    }
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
      _getProfileFromUserId(isUpdated: true);
    }
  }

  void _getProfileFromUserId({
    isUpdated = false,
  }) async {
    final profile = await client.getProfileFromUserId(
      client.userID!,
      cache: !isUpdated,
      getFromRooms: false,
    );
    Logs().d(
      'SettingsProfile::_getProfileFromUserId() - avatarUrl: ${profile.avatarUrl} - displayName: ${profile.displayName} - userId: ${profile.userId}',
    );
    settingsDashboardManagerController.profileNotifier.value = profile;
    displayNameEditingController.text = displayName;
    matrixIdEditingController.text = mxid;
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
      'SettingsProfile::_listeningDisplayNameHasChange() - ${isEditedProfileNotifier.value}',
    );
  }

  void _initProfile() {
    if (widget.profile == null) {
      _getProfileFromUserId();
      return;
    }
    settingsDashboardManagerController.profileNotifier.value = widget.profile!;
    displayNameEditingController.text = displayName;
    matrixIdEditingController.text = mxid;
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
