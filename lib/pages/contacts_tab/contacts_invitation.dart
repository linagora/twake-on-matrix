import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/generate_invitation_link_state.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_medium_enum.dart';
import 'package:fluffychat/domain/usecase/invitation/generate_invitation_link_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/send_invitation_interactor.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_view.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class ContactsInvitation extends StatefulWidget {
  final PresentationContact contact;

  const ContactsInvitation({super.key, required this.contact});

  @override
  State<ContactsInvitation> createState() => ContactsInvitationController();
}

class ContactsInvitationController extends State<ContactsInvitation> {
  final SendInvitationInteractor _sendInvitationInteractor =
      getIt.get<SendInvitationInteractor>();

  final GenerateInvitationLinkInteractor _generateInvitationLinkInteractor =
      getIt.get<GenerateInvitationLinkInteractor>();

  final ValueNotifier<PresentationThirdPartyContact?> selectedContact =
      ValueNotifier(null);

  final ValueNotifier<Either<Failure, Success>> sendInvitationNotifier =
      ValueNotifier(const Right(SendInvitationInitial()));

  final ValueNotifier<Either<Failure, Success>> generateInvitationLinkNotifier =
      ValueNotifier(const Right(GenerateInvitationLinkInitial()));

  void onSelectContact(PresentationThirdPartyContact contact) {
    if (selectedContact.value == null) {
      selectedContact.value = contact;
    } else {
      if (selectedContact.value == contact) {
        selectedContact.value = null;
      } else {
        selectedContact.value = contact;
      }
    }
  }

  ({
    String contact,
    InvitationMediumEnum medium,
  })? _getInvitationData(PresentationThirdPartyContact contact) {
    return switch (contact) {
      final PresentationPhoneNumber phoneNumber => (
          contact: phoneNumber.phoneNumber,
          medium: InvitationMediumEnum.phone,
        ),
      final PresentationEmail email => (
          contact: email.email,
          medium: InvitationMediumEnum.email,
        ),
      _ => null,
    };
  }

  void onSendInvitation(PresentationThirdPartyContact contact) {
    final invitationData = _getInvitationData(contact);

    if (invitationData != null) {
      _sendInvitationInteractor
          .execute(
        contact: invitationData.contact,
        medium: invitationData.medium,
      )
          .listen((state) {
        sendInvitationNotifier.value = state;
      });
    }
  }

  void _onSelectContactDefault(PresentationContact contact) {
    if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
      onSelectContact(contact.phoneNumbers!.first);
      return;
    }

    if (contact.emails != null && contact.emails!.isNotEmpty) {
      onSelectContact(contact.emails!.first);
      return;
    }
  }

  void _onSendInvitationStateListener() {
    sendInvitationNotifier.value.fold(
      (failure) {
        if (failure is SendInvitationFailureState) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.failedToSendInvitation,
          );
        }
      },
      (success) {
        if (success is SendInvitationSuccessState) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.invitationHasBeenSuccessfullySent,
          );
          Navigator.of(context).pop();
        }
      },
    );
  }

  void onGenerateInvitationLink() {
    final contact = selectedContact.value;
    if (contact == null) {
      return;
    }
    final invitationData = _getInvitationData(contact);

    if (invitationData != null) {
      _generateInvitationLinkInteractor
          .execute(
        contact: invitationData.contact,
        medium: invitationData.medium,
      )
          .listen((state) {
        generateInvitationLinkNotifier.value = state;
      });
    }
  }

  void _onGenerateInvitationLinkStateListener() {
    generateInvitationLinkNotifier.value.fold(
      (failure) {
        TwakeDialog.hideLoadingDialog(context);

        if (failure is GenerateInvitationLinkFailureState) {
          TwakeSnackBar.show(
            context,
            failure.message ?? L10n.of(context)!.failedToSendFiles,
          );
          return;
        }

        if (failure is GenerateInvitationLinkIsEmptyState) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.invitationLinkIsEmpty,
          );
          return;
        }
      },
      (success) {
        if (success is GenerateInvitationLinkLoadingState) {
          TwakeDialog.showLoadingDialog(context);
          return;
        } else {
          TwakeDialog.hideLoadingDialog(context);
        }
        if (success is GenerateInvitationLinkSuccessState) {
          Share.shareUri(
            Uri.parse(success.link),
          );
          return;
        }
      },
    );
  }

  @override
  void initState() {
    _onSelectContactDefault(widget.contact);
    sendInvitationNotifier.addListener(() {
      _onSendInvitationStateListener();
    });
    generateInvitationLinkNotifier.addListener(() {
      _onGenerateInvitationLinkStateListener();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ContactsInvitationView(
      controller: this,
      contact: widget.contact,
    );
  }
}
