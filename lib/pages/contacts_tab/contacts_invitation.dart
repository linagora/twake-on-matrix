import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/invitation/invitation_status_response.dart';
import 'package:fluffychat/domain/app_state/invitation/generate_invitation_link_state.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_view_model.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_view.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';

class ContactsInvitation extends ConsumerStatefulWidget {
  final PresentationContact contact;
  final String userId;
  final InvitationStatusResponse? invitationStatus;

  const ContactsInvitation({
    super.key,
    required this.contact,
    required this.userId,
    this.invitationStatus,
  });

  @override
  ConsumerState<ContactsInvitation> createState() =>
      _ContactsInvitationScreenState();
}

class _ContactsInvitationScreenState extends ConsumerState<ContactsInvitation> {
  bool get _isSelectionLocked =>
      widget.invitationStatus?.invitation?.medium != null;

  void _listenStateEffects() {
    ref.listen<ContactsInvitationState>(contactsInvitationViewModelProvider, (
      previous,
      next,
    ) {
      if (previous?.sendInvitationState != next.sendInvitationState) {
        _onSendInvitationStateChanged(next.sendInvitationState);
      }
      if (previous?.generateInvitationLinkState !=
          next.generateInvitationLinkState) {
        _onGenerateInvitationLinkStateChanged(next.generateInvitationLinkState);
      }
    });
  }

  void _onSendInvitationStateChanged(Either<Failure, Success> state) {
    state.fold(
      (failure) {
        if (failure is InvitationAlreadySentState) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.youAlreadySentAnInvitationToThisContact,
          );
          return;
        }
        if (failure is InvalidPhoneNumberFailureState) {
          TwakeSnackBar.show(context, L10n.of(context)!.invalidPhoneNumber);
          return;
        }
        if (failure is InvalidEmailFailureState) {
          TwakeSnackBar.show(context, L10n.of(context)!.invalidEmail);
          return;
        }
        if (failure is SendInvitationFailureState) {
          TwakeSnackBar.show(context, L10n.of(context)!.failedToSendInvitation);
          return;
        }
      },
      (success) {
        if (success is SendInvitationSuccessState) {
          _onStoreInvitationStatus(
            userId: widget.userId,
            contactId: widget.contact.id ?? '',
            invitationId: success.sendInvitationResponse.id ?? '',
          );
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.invitationHasBeenSuccessfullySent,
          );
          Navigator.of(context).pop(success.sendInvitationResponse.id ?? '');
          return;
        }
      },
    );
  }

  void _onGenerateInvitationLinkStateChanged(Either<Failure, Success> state) {
    state.fold(
      (failure) {
        TwakeDialog.hideLoadingDialog(context);

        if (failure is GenerateInvitationLinkFailureState) {
          TwakeSnackBar.show(
            context,
            failure.message ?? L10n.of(context)!.failedToSendFiles,
          );
          return;
        }
        if (failure is InvalidPhoneNumberFailureState) {
          TwakeSnackBar.show(context, L10n.of(context)!.invalidPhoneNumber);
          return;
        }
        if (failure is InvalidEmailFailureState) {
          TwakeSnackBar.show(context, L10n.of(context)!.invalidEmail);
          return;
        }
        if (failure is GenerateInvitationLinkIsEmptyState) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.failedToGenerateInvitationLink,
          );
          return;
        }
      },
      (success) async {
        if (success is GenerateInvitationLinkLoadingState) {
          TwakeDialog.showLoadingDialog(context);
          return;
        } else {
          TwakeDialog.hideLoadingDialog(context);
        }
        if (success is GenerateInvitationLinkSuccessState) {
          await Share.shareUri(Uri.parse(success.link));
          Navigator.of(context).pop();
          return;
        }
      },
    );
  }

  void _onStoreInvitationStatus({
    required String userId,
    required String contactId,
    required String invitationId,
  }) {
    ref
        .read(contactsInvitationViewModelProvider.notifier)
        .storeInvitationStatus(
          userId: userId,
          contactId: contactId,
          invitationId: invitationId,
        );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(contactsInvitationViewModelProvider.notifier)
          .selectDefaultContact(
            widget.contact,
            isSelectionLocked: _isSelectionLocked,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    _listenStateEffects();
    final state = ref.watch(contactsInvitationViewModelProvider);
    return ContactsInvitationView(
      contact: widget.contact,
      state: state,
      onGenerateInvitationLink: () {
        ref
            .read(contactsInvitationViewModelProvider.notifier)
            .generateInvitationLink(widget.contact);
      },
      onSelectContact: (contact) {
        ref
            .read(contactsInvitationViewModelProvider.notifier)
            .selectContact(contact, isSelectionLocked: _isSelectionLocked);
      },
      onSendInvitation: (contact) {
        Logs().d(
          'ContactsInvitation::onSendInvitation '
          'contactId=${widget.contact.id} '
          'selectedContactType=${contact.runtimeType} '
          'userIdPresent=${widget.userId.isNotEmpty}',
        );
        ref
            .read(contactsInvitationViewModelProvider.notifier)
            .sendInvitation(
              contact: contact,
              contactId: widget.contact.id ?? '',
            );
      },
    );
  }
}
