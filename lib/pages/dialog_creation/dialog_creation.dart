import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/dialog_creation/dialog_creation_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart' as sdk;
import 'package:vrouter/vrouter.dart';


class DialogCreation extends StatefulWidget {

  final Set<PresentationContact> selectedContacts;

  const DialogCreation({
    super.key,
    required this.selectedContacts
  });

  @override
  State<StatefulWidget> createState() => DialogCreationController();
}

class DialogCreationController extends State<DialogCreation> {
  TextEditingController controller = TextEditingController();
  bool publicGroup = false;

  Set<PresentationContact> get matrixContacts {
    return widget.selectedContacts
      .where((contact) => contact.matrixUserId != null)
      .toSet();
  }

  void setPublicGroup(bool b) => setState(() => publicGroup = b);

  void submitAction([_]) async {
    final client = Matrix.of(context).client;
    final roomID = await showFutureLoadingDialog(
      context: context,
      future: () async {
        final roomId = await client.createGroupChat(
          invite: matrixContacts.map((contact) => contact.matrixUserId!).toList(),
          visibility:
              publicGroup ? sdk.Visibility.public : sdk.Visibility.private,
          preset: publicGroup
              ? sdk.CreateRoomPreset.publicChat
              : sdk.CreateRoomPreset.privateChat,
          groupName: controller.text.isNotEmpty ? controller.text : null,
        );
        return roomId;
      },
    );
    if (roomID.error == null) {
      VRouter.of(context).toSegments(['rooms', roomID.result!]);
    }
  }

  @override
  Widget build(BuildContext context) => DialogCreationView(controller: this);
}