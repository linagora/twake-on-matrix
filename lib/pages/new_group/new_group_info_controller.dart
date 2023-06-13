import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:fluffychat/domain/model/room/new_room_request.dart';
import 'package:fluffychat/pages/settings/settings.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

extension NewGroupInfoController on NewGroupController {
  void listenGroupNameChanged() {
    groupNameTextEditingController.addListener(() {
      groupName = groupNameTextEditingController.text;
      haveGroupNameNotifier.value = groupNameTextEditingController.text.isNotEmpty;
    });
  }

  void createNewRoomAction() async {
    final client = Matrix.of(context).client;
    createRoomStreamController.createRoom(
        client,
        NewRoomRequest(
          groupName: groupName,
          invite: getSelectedValidContacts(contactsList)
              .map<String>((contact) => contact.matrixId!)
              .toList(),
          createRoomPreset:
              isGroupPublic ? CreateRoomPreset.publicChat : CreateRoomPreset.privateChat,
          enableEncryption: isEnableEEEncryptionNotifier.value,
          avatar: avatar,
        ));
  }

  void onGroupPrivacyChanged(bool switchValue) {
    isGroupPublic = switchValue;
    isEnableEEEncryptionNotifier.value = !switchValue;
  }

  Set<PresentationContact> getSelectedValidContacts(
    Iterable<PresentationContact> contactsList,
  ) {
    return contactsList
      .where((contact) => contact.matrixId != null && !contact.matrixId!.isCurrentMatrixId(context))
      .toSet();
  }

  Future<AvatarAction?> _getSaveAvatarActions(BuildContext context) async {
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
    ];

    final action = actions.length == 1
    ? actions.single.key
    : await showModalActionSheet<AvatarAction>(
        context: context,
        title: L10n.of(context)!.changeGroupAvatar,
        actions: actions,
      );

    return action;
  }

  void saveAvatarAction(BuildContext context) async {
    final action = await _getSaveAvatarActions(context);
    if (action == null) return;

    MatrixFile file;
    if (PlatformInfos.isMobile) {
      final result = await ImagePicker().pickImage(
        source: action == AvatarAction.camera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50,
      );
      if (result == null) return;
      file = MatrixFile(
        bytes: await result.readAsBytes(),
        name: result.path,
      );
    } else {
      final result = await FilePickerCross.importFromStorage(type: FileTypeCross.image);
      if (result.fileName == null) return;
      file = MatrixFile(
        bytes: result.toUint8List(),
        name: result.fileName!,
      );
    }

    avatar = file;
  }
}