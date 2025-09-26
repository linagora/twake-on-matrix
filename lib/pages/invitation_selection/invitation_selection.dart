import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';

class InvitationSelection extends StatefulWidget {
  final String roomId;
  final bool? isFullScreen;

  const InvitationSelection({
    super.key,
    required this.roomId,
    this.isFullScreen = true,
  });

  @override
  InvitationSelectionController createState() =>
      InvitationSelectionController();
}

class InvitationSelectionController
    extends ContactsSelectionController<InvitationSelection> {
  String? get _roomId => widget.roomId;

  Room get _room => Matrix.of(context).client.getRoomById(_roomId!)!;

  @override
  bool get isFullScreen => widget.isFullScreen == true;

  @override
  String getTitle(BuildContext context) {
    return L10n.of(context)!.addMember;
  }

  @override
  String getHintText(BuildContext context) {
    return L10n.of(context)!.searchContacts;
  }

  @override
  List<String> get disabledContactIds => Matrix.of(context)
      .client
      .getRoomById(_roomId!)!
      .getParticipants()
      .map((participant) => participant.id)
      .toList();

  @override
  void onSubmit() async {
    performInvite();
  }

  void performInvite() async {
    final selectedContacts = selectedContactsMapNotifier.contactsList
        .map((contact) => contact.matrixId!)
        .toList();
    final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => Future.wait(
        selectedContacts.map((id) => _room.invite(id)),
      ),
    );
    if (success.error == null) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.contactHasBeenInvitedToTheGroup,
      );
      inviteSuccessAction();
      return;
    }
  }

  void inviteSuccessAction() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ContactsSelectionView(this);
}
