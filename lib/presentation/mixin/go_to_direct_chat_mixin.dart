import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact_constant.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:vrouter/vrouter.dart';

mixin GoToDirectChatMixin {
  void goToChatScreen(
      {required BuildContext context,
      required PresentationContact contact}) async {
    final directRoomId =
        Matrix.of(context).client.getDirectChatFromUserId(contact.matrixId!);
    showFutureLoadingDialog(
      context: context,
      future: () async {
        if (contact.matrixId != null && contact.matrixId!.isNotEmpty) {
          if (directRoomId != null) {
            final roomId = await Matrix.of(context)
                .client
                .startDirectChat(contact.matrixId!);
            VRouter.of(context).toSegments(['rooms', roomId]);
          }
        }
      },
    );
    if (directRoomId == null) {
      goToEmptyChat(context: context, contact: contact);
    }
  }

  void goToEmptyChat(
      {required BuildContext context, required PresentationContact contact}) {
    if (contact.matrixId != Matrix.of(context).client.userID) {
      VRouter.of(context).to('/emptyChat', queryParameters: {
        PresentationContactConstant.receiverId: contact.matrixId ?? '',
        PresentationContactConstant.email: contact.email ?? '',
        PresentationContactConstant.displayName: contact.displayName ?? '',
        PresentationContactConstant.status: contact.status.toString(),
      });
    }
  }
}
