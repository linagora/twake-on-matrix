import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_view_model.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('selectDefaultContact selects first phone number', () {
    final phoneNumber = PresentationPhoneNumber(
      phoneNumber: '+33123456789',
      thirdPartyId: 'phone-id',
      thirdPartyIdType: ThirdPartyIdType.msisdn,
    );
    final contact = PresentationContact(phoneNumbers: {phoneNumber});

    container
        .read(contactsInvitationViewModelProvider.notifier)
        .selectDefaultContact(contact, isSelectionLocked: false);

    expect(
      container.read(contactsInvitationViewModelProvider).selectedContact,
      phoneNumber,
    );
  });

  test('selectContact toggles selected contact', () {
    final email = PresentationEmail(
      email: 'test@example.com',
      thirdPartyId: 'email-id',
      thirdPartyIdType: ThirdPartyIdType.email,
    );
    final viewModel = container.read(
      contactsInvitationViewModelProvider.notifier,
    );

    viewModel.selectContact(email, isSelectionLocked: false);
    viewModel.selectContact(email, isSelectionLocked: false);

    expect(
      container.read(contactsInvitationViewModelProvider).selectedContact,
      isNull,
    );
  });

  test('selectContact ignores selection when locked', () {
    final email = PresentationEmail(
      email: 'test@example.com',
      thirdPartyId: 'email-id',
      thirdPartyIdType: ThirdPartyIdType.email,
    );

    container
        .read(contactsInvitationViewModelProvider.notifier)
        .selectContact(email, isSelectionLocked: true);

    expect(
      container.read(contactsInvitationViewModelProvider).selectedContact,
      isNull,
    );
  });
}
