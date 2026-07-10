import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/invitation/generate_invitation_link_state.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/domain/app_state/invitation/store_invitation_status_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/invitation/invitation_medium_enum.dart';
import 'package:fluffychat/domain/usecase/invitation/generate_invitation_link_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/send_invitation_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/store_invitation_status_interactor.dart';
import 'package:fluffychat/pages/contacts_tab/providers/contacts_invitation_providers.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_view_model.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSendInvitationInteractor implements SendInvitationInteractor {
  final Stream<Either<Failure, Success>> states;

  FakeSendInvitationInteractor(this.states);

  @override
  Stream<Either<Failure, Success>> execute({
    required String contact,
    required String contactId,
    required InvitationMediumEnum medium,
  }) => states;
}

class FakeGenerateInvitationLinkInteractor
    implements GenerateInvitationLinkInteractor {
  final Stream<Either<Failure, Success>> states;

  FakeGenerateInvitationLinkInteractor(this.states);

  @override
  Stream<Either<Failure, Success>> execute({
    String? contact,
    InvitationMediumEnum? medium,
  }) => states;
}

class FakeStoreInvitationStatusInteractor
    implements StoreInvitationStatusInteractor {
  final Stream<Either<Failure, Success>> states;

  FakeStoreInvitationStatusInteractor(this.states);

  @override
  Stream<Either<Failure, Success>> execute({
    required String userId,
    required String contactId,
    required String invitationId,
  }) => states;
}

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

  test('maps legacy send invitation states to AsyncValue', () async {
    final email = PresentationEmail(
      email: 'test@example.com',
      thirdPartyId: 'email-id',
      thirdPartyIdType: ThirdPartyIdType.email,
    );
    final interactor = FakeSendInvitationInteractor(
      Stream<Either<Failure, Success>>.fromIterable([
        const Right(SendInvitationLoadingState()),
        const Left(InvalidEmailFailureState()),
      ]),
    );
    final testContainer = ProviderContainer(
      overrides: [
        sendInvitationInteractorProvider.overrideWithValue(interactor),
      ],
    );
    addTearDown(testContainer.dispose);

    final operation = testContainer
        .read(contactsInvitationViewModelProvider.notifier)
        .sendInvitation(contact: email, contactId: 'contact-id');

    expect(
      testContainer
          .read(contactsInvitationViewModelProvider)
          .sendInvitationState
          .isLoading,
      isTrue,
    );

    await operation;

    final actionState = testContainer
        .read(contactsInvitationViewModelProvider)
        .sendInvitationState;
    expect(actionState.hasError, isTrue);
    expect(actionState.error, isA<InvalidEmailFailureState>());
  });

  test('maps legacy invitation link states to AsyncValue', () async {
    final email = PresentationEmail(
      email: 'test@example.com',
      thirdPartyId: 'email-id',
      thirdPartyIdType: ThirdPartyIdType.email,
    );
    final interactor = FakeGenerateInvitationLinkInteractor(
      Stream<Either<Failure, Success>>.fromIterable([
        const Right(GenerateInvitationLinkLoadingState()),
        const Right(
          GenerateInvitationLinkSuccessState(
            link: 'https://example.com/invitation',
            id: 'invitation-id',
          ),
        ),
      ]),
    );
    final testContainer = ProviderContainer(
      overrides: [
        generateInvitationLinkInteractorProvider.overrideWithValue(interactor),
      ],
    );
    addTearDown(testContainer.dispose);
    final contact = PresentationContact(emails: {email});

    final operation = testContainer
        .read(contactsInvitationViewModelProvider.notifier)
        .generateInvitationLink(contact);

    expect(
      testContainer
          .read(contactsInvitationViewModelProvider)
          .generateInvitationLinkState
          .isLoading,
      isTrue,
    );

    await operation;

    expect(
      testContainer
          .read(contactsInvitationViewModelProvider)
          .generateInvitationLinkState
          .value,
      Uri.parse('https://example.com/invitation'),
    );
  });

  test('reports successful invitation status storage', () async {
    final interactor = FakeStoreInvitationStatusInteractor(
      Stream<Either<Failure, Success>>.fromIterable([
        const Right(StoreInvitationStatusLoadingState()),
        const Right(
          StoreInvitationStatusSuccessState(
            contactId: 'contact-id',
            userId: 'user-id',
            invitationId: 'invitation-id',
          ),
        ),
      ]),
    );
    final testContainer = ProviderContainer(
      overrides: [
        storeInvitationStatusInteractorProvider.overrideWithValue(interactor),
      ],
    );
    addTearDown(testContainer.dispose);

    final isStored = await testContainer
        .read(contactsInvitationViewModelProvider.notifier)
        .storeInvitationStatus(
          userId: 'user-id',
          contactId: 'contact-id',
          invitationId: 'invitation-id',
        );

    expect(isStored, isTrue);
  });

  test('reports failed invitation status storage', () async {
    final interactor = FakeStoreInvitationStatusInteractor(
      Stream<Either<Failure, Success>>.fromIterable([
        const Right(StoreInvitationStatusLoadingState()),
        const Left(
          StoreInvitationStatusFailureState(
            exception: 'storage failed',
            contactId: 'contact-id',
            userId: 'user-id',
            invitationId: 'invitation-id',
          ),
        ),
      ]),
    );
    final testContainer = ProviderContainer(
      overrides: [
        storeInvitationStatusInteractorProvider.overrideWithValue(interactor),
      ],
    );
    addTearDown(testContainer.dispose);

    final isStored = await testContainer
        .read(contactsInvitationViewModelProvider.notifier)
        .storeInvitationStatus(
          userId: 'user-id',
          contactId: 'contact-id',
          invitationId: 'invitation-id',
        );

    expect(isStored, isFalse);
  });
}
