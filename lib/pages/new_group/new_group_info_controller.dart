import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';

extension NewGroupInfoControllerExtension on NewGroupChatInfoController {
  void listenGroupNameChanged() {
    groupNameTextEditingController.addListener(() {
      groupName = groupNameTextEditingController.text;
      haveGroupNameNotifier.value =
          groupNameTextEditingController.text.isNotEmpty &&
              getErrorMessage(groupNameTextEditingController.text) == null;
    });
  }

  void _handleUploadAvatarInBytes(Client client) {
    if (avatarFilePickerNotifier.value != null) {
      uploadAvatarNewGroupChatInBytes(
        matrixClient: client,
        matrixFile: avatarFilePickerNotifier.value!,
      );
    } else {
      createNewGroup();
    }
  }

  void _handleUploadAvatarInStream(Client client) {
    groupNameFocusNode.unfocus();
    if (avatarAssetEntityNotifier.value != null) {
      uploadAvatarNewGroupChat(
        matrixClient: client,
        entity: avatarAssetEntityNotifier.value!,
      );
    } else {
      createNewGroup();
    }
  }

  void moveToGroupChatScreen() async {
    Logs().d('NewGroupInfoController::moveToGroupChatScreen()');
    final client = Matrix.of(context).client;
    if (PlatformInfos.isMobile) {
      _handleUploadAvatarInStream(client);
    } else {
      _handleUploadAvatarInBytes(client);
    }
  }

  Set<PresentationContact> getSelectedValidContacts(
    Iterable<PresentationContact> contactsList,
  ) {
    return contactsList
        .where(
          (contact) =>
              contact.matrixId != null &&
              !contact.matrixId!.isCurrentMatrixId(context),
        )
        .toSet();
  }
}
