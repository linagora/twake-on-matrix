import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/invitation/generate_invitation_link_state.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';

class ContactsInvitationState extends Equatable {
  final PresentationThirdPartyContact? selectedContact;
  final Either<Failure, Success> sendInvitationState;
  final Either<Failure, Success> generateInvitationLinkState;

  const ContactsInvitationState({
    this.selectedContact,
    this.sendInvitationState = const Right(SendInvitationInitial()),
    this.generateInvitationLinkState = const Right(
      GenerateInvitationLinkInitial(),
    ),
  });

  ContactsInvitationState copyWith({
    PresentationThirdPartyContact? selectedContact,
    bool clearSelectedContact = false,
    Either<Failure, Success>? sendInvitationState,
    Either<Failure, Success>? generateInvitationLinkState,
  }) {
    return ContactsInvitationState(
      selectedContact: clearSelectedContact
          ? null
          : selectedContact ?? this.selectedContact,
      sendInvitationState: sendInvitationState ?? this.sendInvitationState,
      generateInvitationLinkState:
          generateInvitationLinkState ?? this.generateInvitationLinkState,
    );
  }

  @override
  List<Object?> get props => [
    selectedContact,
    sendInvitationState,
    generateInvitationLinkState,
  ];
}
