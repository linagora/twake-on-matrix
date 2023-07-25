import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/utils/dialog/warning_dialog.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
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
    if (numberSelectedImagesNotifier.value != 1) {
      final client = Matrix.of(context).client;
      // FIXME: When upload
      // createNewGroupChatAction(
      //   matrixClient: client,
      //   createNewGroupChatRequest: CreateNewGroupChatRequest(
      //     groupName: groupName,
      //     invite: getSelectedValidContacts(contactsList)
      //       .map<String>((contact) => contact.matrixId!)
      //       .toList(),
      //     enableEncryption: true,
      //     urlAvatar: uriAvatar != null ? uriAvatar!.toString() : null,
      //   ),
      // );
    } else {
      WarningDialog.showWarningDialog(context,onAcceptButton: () => cancelUploadAvatar(context));
    }
  }

  void cancelUploadAvatar(BuildContext context) {
    // FIXME: Dont understand it
    // uploadAvatarNewGroupChatNotifier.value = const Left(UploadContentFailed(exception: null));
    removeAllImageSelected();
    WarningDialog.hideWarningDialog(context);
  }

  Set<PresentationContact> getSelectedValidContacts(
      Iterable<PresentationContact> contactsList,) {
    return contactsList
      .where((contact) => contact.matrixId != null && !contact.matrixId!.isCurrentMatrixId(context))
      .toSet();
  }
}