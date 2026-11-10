import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/room/invite_user_state.dart';
import 'package:twake_chat/domain/usecase/room/unban_and_invite_users_interactor.dart';
import 'package:twake_chat/pages/new_group/contacts_selection.dart';
import 'package:twake_chat/pages/new_group/contacts_selection_view.dart';
import 'package:twake_chat/presentation/extensions/invite_user_exception_extension.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:twake_chat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';

class InvitationSelection extends ConsumerStatefulWidget {
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
  List<String> get disabledContactIds => Matrix.of(context).client
      .getRoomById(_roomId!)!
      // Someone who knocked can still be invited.
      .getParticipants([Membership.join, Membership.invite])
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
    final room = _room;
    final navigator = Navigator.of(context);
    // A federated invite can take minutes: leave now, report on the page below.
    navigator.pop();

    getIt
        .get<UnbanAndInviteUsersInteractor>()
        .execute(room: room, userIds: selectedContacts)
        .listen(
          (event) {
            if (!navigator.mounted) return;
            final hostContext = navigator.context;
            final state = event.fold(
              (failure) => failure,
              (success) => success,
            );

            if (state is InviteUserSuccess) {
              TwakeSnackBar.show(
                hostContext,
                L10n.of(hostContext)!.contactHasBeenInvitedToTheGroup,
              );
              return;
            }

            if (state is InviteUserSomeFailed) {
              showConfirmAlertDialog(
                context: hostContext,
                message: state.inviteUserPartialFailureException
                    .getLocalizedErrorMessage(hostContext),
                isArrangeActionButtonsVertical: true,
                okLabel: L10n.of(hostContext)!.gotIt,
              );
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            Logs().e('InvitationSelection::performInvite', error, stackTrace);
          },
        );
  }

  @override
  Widget build(BuildContext context) =>
      ContactsSelectionView(this, bannedHighlight: true, room: _room);
}
