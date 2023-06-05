import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

extension NewGroupInfoController on NewGroupController {

  void listenGroupNameChanged() {
    groupNameTextEditingController.addListener(() {
      groupName = groupNameTextEditingController.text;
      haveGroupNameNotifier.value = groupNameTextEditingController.text.isNotEmpty;
    });
  }

  void moveToGroupChatScreen() async {
    final roomId = await Matrix.of(context).client.createGroupChat(
      groupName: groupName,
      invite: getSelectedValidContacts(contactsList)
        .map<String>((contact) => contact.matrixId!)
        .toList(),
      enableEncryption: isEnableEEEncryptionNotifier.value,
      preset: isGroupPrivate 
        ? CreateRoomPreset.privateChat
        : CreateRoomPreset.publicChat,
    );

    VRouter.of(context).toSegments(['rooms', roomId]);
  }

  void onGroupPrivacyChanged(bool switchValue) {
    isGroupPrivate = switchValue;
    isEnableEEEncryptionNotifier.value = !switchValue;
  }

  Set<PresentationContact> getSelectedValidContacts(
    Iterable<PresentationContact> contactsList,
  ) {
    return contactsList
      .where((contact) => contact.matrixId != null && !contact.matrixId!.isCurrentMatrixId(context))
      .toSet();
  }
}