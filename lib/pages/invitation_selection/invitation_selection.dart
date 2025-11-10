import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/invite_user_state.dart';
import 'package:fluffychat/domain/usecase/room/invite_user_interactor.dart';
import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';

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

  void performInvite() {
    final selectedContacts = selectedContactsMapNotifier.contactsList
        .map((contact) => contact.matrixId!)
        .toList();

    final subscription = getIt
        .get<InviteUserInteractor>()
        .execute(
          matrixClient: client,
          roomId: _room.id,
          userIds: selectedContacts,
        )
        .listen((event) async {
      final state = event.fold((failure) => failure, (success) => success);

      if (state is InviteUserLoading) {
        TwakeDialog.showLoadingDialog(context);
        return;
      }

      if (state is InviteUserSuccess) {
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.contactHasBeenInvitedToTheGroup,
        );
        inviteSuccessAction();
        return;
      }

      if (state is InviteUserSomeFailed) {
        final failedUsers = state.inviteUserPartialFailureException.failedUsers;
        Logs().e(
          'NewGroupController::_handleInviteUsersOnEvent - failed to invite users: ${failedUsers.keys.toList()}',
        );
        await showConfirmAlertDialog(
          context: context,
          message: L10n.of(context)!.failedToAddMembers(
            failedUsers.keys.length,
          ),
          isArrangeActionButtonsVertical: true,
          okLabel: L10n.of(context)!.gotIt,
        );
        inviteSuccessAction();
        return;
      }
    });

    subscription.onDone(
      () {
        TwakeDialog.hideLoadingDialog(context);
        subscription.cancel();
      },
    );
  }

  void inviteSuccessAction() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ContactsSelectionView(this);
}
