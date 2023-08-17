import 'package:fluffychat/mixin/invite_external_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';

class InvitationSelection extends StatefulWidget {
  const InvitationSelection({Key? key}) : super(key: key);

  @override
  InvitationSelectionController createState() =>
      InvitationSelectionController();
}

class InvitationSelectionController extends State<InvitationSelection>
    with SearchContactsController, InviteExternalContactMixin {
  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();
  String? get _roomId => GoRouterState.of(context).pathParameters['roomid'];

  Room get _room => Matrix.of(context).client.getRoomById(_roomId!)!;

  String get groupName =>
      _room.name.isEmpty ? L10n.of(context)!.group : _room.name;

  List<String> get joinedContacts => Matrix.of(context)
      .client
      .getRoomById(_roomId!)!
      .getParticipants()
      .map((participant) => participant.id)
      .toList();

  @override
  void initState() {
    initSearchExternalContacts();
    super.initState();
  }

  @override
  void dispose() {
    disposeSearchContacts();
    super.dispose();
  }

  void onSubmit() async {
    if (OkCancelResult.ok !=
        await showOkCancelAlertDialog(
          context: context,
          title: L10n.of(context)!.inviteContactToGroup(
            _room.getLocalizedDisplayname(
              MatrixLocals(L10n.of(context)!),
            ),
          ),
          okLabel: L10n.of(context)!.yes,
          cancelLabel: L10n.of(context)!.cancel,
        )) {
      return;
    }
    final selectedContacts = selectedContactsMapNotifier.contactsList
        .map((contact) => contact.matrixId!)
        .toList();
    performInvite(selectedContacts);
  }

  void performInvite(List<String> ids) async {
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => Future.wait(
        ids.map((id) => _room.invite(id)),
      ),
    );
    if (success.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.contactHasBeenInvitedToTheGroup),
        ),
      );
      context.go('/rooms/$_roomId');
    }
  }

  void onExternalContactAction(
    BuildContext context,
    PresentationContact contact,
  ) {
    showInviteExternalContactDialog(
      context,
      contact,
      () => performInvite([contact.matrixId ?? ""]),
    );
  }

  @override
  Widget build(BuildContext context) => InvitationSelectionView(this);
}
