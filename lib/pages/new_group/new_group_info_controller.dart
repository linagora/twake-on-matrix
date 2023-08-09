import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';

extension NewGroupInfoController on NewGroupController {
  void listenGroupNameChanged() {
    groupNameTextEditingController.addListener(() {
      groupName = groupNameTextEditingController.text;
      haveGroupNameNotifier.value =
          groupNameTextEditingController.text.isNotEmpty;
    });
  }

  void moveToGroupChatScreen() async {
    Logs().d('NewGroupInfoController::moveToGroupChatScreen()');
    groupNameFocusNode.unfocus();
    final client = Matrix.of(context).client;
    if (avatarNotifier.value != null) {
      uploadAvatarNewGroupChat(
        matrixClient: client,
        entity: avatarNotifier.value!,
      );
    } else {
      createNewGroup();
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
