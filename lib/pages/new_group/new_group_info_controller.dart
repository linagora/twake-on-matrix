import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
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
    final roomId = await showFutureLoadingDialog(
      context: context,
      future: () async {
        return await Matrix.of(context).client.createGroupChat(
          groupName: groupName,
          invite: getSelectedValidContacts(contactsList)
            .map<String>((contact) => contact.matrixId!)
            .toList(),
          enableEncryption: true,
          preset: CreateRoomPreset.privateChat
        );
      }
    );
    if (roomId.result != null) {
      VRouter.of(context).toSegments(['rooms', roomId.result!]);
    }
  }

  Set<PresentationContact> getSelectedValidContacts(
    Iterable<PresentationContact> contactsList,
  ) {
    return contactsList
      .where((contact) => contact.matrixId != null && !contact.matrixId!.isCurrentMatrixId(context))
      .toSet();
  }
}