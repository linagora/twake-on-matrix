import 'package:fluffychat/data/model/invitation/send_invitation_response.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contacts_invitation_state.freezed.dart';

@freezed
abstract class ContactsInvitationState with _$ContactsInvitationState {
  const factory ContactsInvitationState({
    PresentationThirdPartyContact? selectedContact,
    @Default(AsyncData<SendInvitationResponse?>(null))
    AsyncValue<SendInvitationResponse?> sendInvitationState,
    @Default(AsyncData<Uri?>(null))
    AsyncValue<Uri?> generateInvitationLinkState,
  }) = _ContactsInvitationState;
}
