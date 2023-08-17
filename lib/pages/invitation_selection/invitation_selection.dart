import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notiifer.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';

class InvitationSelection extends StatefulWidget {
  const InvitationSelection({Key? key}) : super(key: key);

  @override
  InvitationSelectionController createState() =>
      InvitationSelectionController();
}

class InvitationSelectionController extends State<InvitationSelection>
    with SearchContactsController {
  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();
  String? get roomId => GoRouterState.of(context).pathParameters['roomid'];
  List<String> get joinedContacts => Matrix.of(context)
      .client
      .getRoomById(roomId!)!
      .getParticipants()
      .map((participant) => participant.id)
      .toList();

  @override
  void initState() {
    initSearchContacts();
    super.initState();
  }

  @override
  void dispose() {
    disposeSearchContacts();
    super.dispose();
  }

  void inviteAction() async {
    final room = Matrix.of(context).client.getRoomById(roomId!)!;
    if (OkCancelResult.ok !=
        await showOkCancelAlertDialog(
          context: context,
          title: L10n.of(context)!.inviteContactToGroup(
            room.getLocalizedDisplayname(
              MatrixLocals(L10n.of(context)!),
            ),
          ),
          okLabel: L10n.of(context)!.yes,
          cancelLabel: L10n.of(context)!.cancel,
        )) {
      return;
    }
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => Future.wait(
        selectedContactsMapNotifier.contactsList
            .map((contact) => room.invite(contact.matrixId ?? "")),
      ),
    );
    if (success.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.contactHasBeenInvitedToTheGroup),
        ),
      );
      context.go('/rooms/${room.id}');
    }
  }

  @override
  Widget build(BuildContext context) => InvitationSelectionView(this);
}
