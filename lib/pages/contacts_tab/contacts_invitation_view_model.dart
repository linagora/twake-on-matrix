import 'package:fluffychat/data/model/invitation/send_invitation_response.dart';
import 'package:fluffychat/domain/app_state/invitation/generate_invitation_link_state.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_medium_enum.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_state.dart';
import 'package:fluffychat/pages/contacts_tab/providers/contacts_invitation_providers.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contacts_invitation_view_model.g.dart';

@riverpod
class ContactsInvitationViewModel extends _$ContactsInvitationViewModel {
  @override
  ContactsInvitationState build() => const ContactsInvitationState();

  void selectDefaultContact(
    PresentationContact contact, {
    required bool isSelectionLocked,
  }) {
    if (state.selectedContact != null) {
      return;
    }
    final phoneNumbers = contact.phoneNumbers;
    if (phoneNumbers != null && phoneNumbers.isNotEmpty) {
      selectContact(phoneNumbers.first, isSelectionLocked: isSelectionLocked);
      return;
    }

    final emails = contact.emails;
    if (emails != null && emails.isNotEmpty) {
      selectContact(emails.first, isSelectionLocked: isSelectionLocked);
    }
  }

  void selectContact(
    PresentationThirdPartyContact contact, {
    required bool isSelectionLocked,
  }) {
    if (isSelectionLocked) {
      return;
    }
    if (state.selectedContact == contact) {
      state = state.copyWith(selectedContact: null);
      return;
    }
    state = state.copyWith(selectedContact: contact);
  }

  Future<void> sendInvitation({
    required PresentationThirdPartyContact contact,
    required String contactId,
  }) async {
    final invitationData = _getInvitationData(contact);
    if (invitationData == null) {
      Logs().e(
        'ContactsInvitationViewModel::sendInvitation '
        'missing invitation data for ${contact.runtimeType}',
      );
      return;
    }

    state = state.copyWith(
      sendInvitationState: const AsyncLoading<SendInvitationResponse?>(),
    );

    Logs().d(
      'ContactsInvitationViewModel::sendInvitation '
      'contactId=$contactId '
      'medium=${invitationData.medium.value} '
      'contactLength=${invitationData.contact.length}',
    );

    try {
      await for (final nextState
          in ref
              .read(sendInvitationInteractorProvider)
              .execute(
                contact: invitationData.contact,
                medium: invitationData.medium,
                contactId: contactId,
              )) {
        Logs().d(
          'ContactsInvitationViewModel::sendInvitation state=$nextState',
        );
        if (!ref.mounted) {
          return;
        }
        state = nextState.fold(
          (failure) => state.copyWith(
            sendInvitationState: AsyncError<SendInvitationResponse?>(
              failure,
              StackTrace.current,
            ),
          ),
          (success) => switch (success) {
            SendInvitationLoadingState() => state.copyWith(
              sendInvitationState:
                  const AsyncLoading<SendInvitationResponse?>(),
            ),
            SendInvitationSuccessState(:final sendInvitationResponse) =>
              state.copyWith(
                sendInvitationState: AsyncData<SendInvitationResponse?>(
                  sendInvitationResponse,
                ),
              ),
            _ => state,
          },
        );
      }
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        sendInvitationState: AsyncError<SendInvitationResponse?>(
          error,
          stackTrace,
        ),
      );
    }
  }

  Future<void> generateInvitationLink(PresentationContact contact) async {
    final primaryContact = contact.primaryContact;
    if (primaryContact == null) {
      return;
    }
    final invitationData = _getInvitationData(primaryContact);
    if (invitationData == null) {
      return;
    }

    state = state.copyWith(
      generateInvitationLinkState: const AsyncLoading<Uri?>(),
    );

    try {
      await for (final nextState
          in ref
              .read(generateInvitationLinkInteractorProvider)
              .execute(
                contact: invitationData.contact,
                medium: invitationData.medium,
              )) {
        if (!ref.mounted) {
          return;
        }
        state = nextState.fold(
          (failure) => state.copyWith(
            generateInvitationLinkState: AsyncError<Uri?>(
              failure,
              StackTrace.current,
            ),
          ),
          (success) => switch (success) {
            GenerateInvitationLinkLoadingState() => state.copyWith(
              generateInvitationLinkState: const AsyncLoading<Uri?>(),
            ),
            GenerateInvitationLinkSuccessState(:final link) => state.copyWith(
              generateInvitationLinkState: AsyncData<Uri?>(Uri.parse(link)),
            ),
            _ => state,
          },
        );
      }
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        generateInvitationLinkState: AsyncError<Uri?>(error, stackTrace),
      );
    }
  }

  Future<void> storeInvitationStatus({
    required String userId,
    required String contactId,
    required String invitationId,
  }) async {
    if (contactId.isEmpty || invitationId.isEmpty) {
      return;
    }

    await for (final nextState
        in ref
            .read(storeInvitationStatusInteractorProvider)
            .execute(
              userId: userId,
              contactId: contactId,
              invitationId: invitationId,
            )) {
      Logs().d('ContactsInvitationViewModel::storeInvitationStatus', nextState);
    }
  }

  ({String contact, InvitationMediumEnum medium})? _getInvitationData(
    PresentationThirdPartyContact contact,
  ) {
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
}
