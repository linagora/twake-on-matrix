import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/invitation/generate_invitation_link_state.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contacts_invitation_state.freezed.dart';

@freezed
abstract class ContactsInvitationState with _$ContactsInvitationState {
  const factory ContactsInvitationState({
    PresentationThirdPartyContact? selectedContact,
    @Default(Right(SendInvitationInitial()))
    Either<Failure, Success> sendInvitationState,
    @Default(Right(GenerateInvitationLinkInitial()))
    Either<Failure, Success> generateInvitationLinkState,
  }) = _ContactsInvitationState;
}
