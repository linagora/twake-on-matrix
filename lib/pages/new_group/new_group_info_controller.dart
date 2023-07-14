import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/domain/model/room/create_new_group_chat_request.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/warning_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';


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
      createNewGroupChatAction(
        matrixClient: client,
        createNewGroupChatRequest: CreateNewGroupChatRequest(
          groupName: groupName,
          invite: getSelectedValidContacts(contactsList)
            .map<String>((contact) => contact.matrixId!)
            .toList(),
          enableEncryption: true,
          urlAvatar: uriAvatar != null ? uriAvatar!.toString() : null,
        ),
      );
    } else {
      final result = await showDialog<bool?>(
        context: context,
        useRootNavigator: false,
        builder: (c) => WarningDialog(
          explainTextRequestWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: L10n.of(context)!.youAreUploadingPhotosDoYouWantToCancelOrContinue,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          onAcceptButton: () => cancelUploadAvatar(),
        ),
      );
    }
  }

  void cancelUploadAvatar() {
    uploadAvatarNewGroupChatNotifier.value = const Left(UploadContentFailed(exception: null));
    removeAllImageSelected();
    Navigator.pop(context);
  }

  Set<PresentationContact> getSelectedValidContacts(
      Iterable<PresentationContact> contactsList,) {
    return contactsList
      .where((contact) => contact.matrixId != null && !contact.matrixId!.isCurrentMatrixId(context))
      .toSet();
  }
}