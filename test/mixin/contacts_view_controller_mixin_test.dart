import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_success.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:matrix/matrix.dart' hide Contact;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../fixtures/contact_fixtures.dart';
import 'contacts_view_controller_mixin_test.mocks.dart';

class ConcretePresentationSearch extends PresentationSearch {
  const ConcretePresentationSearch({
    required String super.displayName,
    required super.emails,
    required super.phoneNumbers,
    required ContactStatus status,
  });

  @override
  String get id => "@test:domain.com";
}

class CustomContactsViewControllerMixin with ContactsViewControllerMixin {}

@GenerateNiceMocks([
  MockSpec<BuildContext>(),
  MockSpec<Client>(),
  MockSpec<MatrixLocalizations>(),
  MockSpec<ContactsViewControllerMixin>(),
])
void main() {
  const debouncerIntervalInMilliseconds = 300;

  final List<Contact> tomContacts = [
    ContactFixtures.contact1,
    ContactFixtures.contact2,
  ];

  final List<Contact> phonebookContacts = [
    ContactFixtures.contact4,
    ContactFixtures.contact5,
  ];

  final List<ConcretePresentationSearch> recentContacts = [
    ConcretePresentationSearch(
      displayName: "Alice test",
      emails: {
        PresentationEmail(
          email: '"alicetest@domain.com"',
          thirdPartyId: 'thirdPartyId',
          thirdPartyIdType: ThirdPartyIdType.email,
        ),
      },
      phoneNumbers: {
        PresentationPhoneNumber(
          phoneNumber: "+84111111111",
          thirdPartyId: 'thirdPartyId',
          thirdPartyIdType: ThirdPartyIdType.msisdn,
        ),
      },
      status: ContactStatus.active,
    ),
  ];

  group('Test ContactsViewControllerMixin on Web', () {
    late MockContactsViewControllerMixin mockContactsViewControllerMixin;
    late Client mockClient;
    late MatrixLocalizations mockMatrixLocalizations;
    late BuildContext mockBuildContext;

    setUp(() {
      mockContactsViewControllerMixin = MockContactsViewControllerMixin();
      mockMatrixLocalizations = MockMatrixLocalizations();
      mockClient = MockClient();
      mockBuildContext = MockBuildContext();
    });

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is empty.\n'
      'AND presentationContactNotifier return GetContactsIsEmpty'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () {
        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsIsEmpty'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () {
        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsSuccess'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () {
        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(Right(GetContactsSuccess(contacts: tomContacts))),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        final presentationContact = mockContactsViewControllerMixin
            .presentationContactNotifier
            .value
            .getSuccessOrNull();

        expect(presentationContact is GetContactsSuccess, true);

        expect(
          (presentationContact as GetContactsSuccess).contacts.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is empty.\n'
      'AND presentationContactNotifier return GetContactsFailure'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsFailure state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () {
        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            const Left(GetContactsFailure(keyword: '', exception: dynamic)),
          ),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsFailure(keyword: '', exception: dynamic)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is empty.\n'
      'AND presentationContactNotifier return GetContactsIsEmpty'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n'
      'AFTER that, enable search mode with keyword is 123'
      'THEN search by keyword return no result'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeyword = '123';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeyword;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeyword,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeyword);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsIsEmpty'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n'
      'AFTER that, enable search mode with keyword is 123'
      'THEN search by keyword return no result'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeyword = '123';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeyword;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeyword,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeyword);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsSuccess'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n'
      'AFTER that, enable search mode with keyword is 123'
      'THEN search by keyword return no result'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeyword = '123';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(Right(GetContactsSuccess(contacts: tomContacts))),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeyword;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeyword,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeyword);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsSuccess'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n'
      'AFTER that, enable search mode'
      'THEN search by keyword return contacts with keyword a'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeyword = 'a';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(Right(GetContactsSuccess(contacts: tomContacts))),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeyword;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            Right(
              GetPresentationContactsSuccess(
                contacts: tomContacts,
                keyword: searchKeyword,
              ),
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeyword,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeyword);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .first
              .displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
                  .getSuccessOrNull()
              is GetPresentationContactsSuccess,
          true,
        );

        final presentationContact =
            mockContactsViewControllerMixin.presentationContactNotifier.value
                    .getSuccessOrNull()
                as GetPresentationContactsSuccess;

        expect(presentationContact.keyword, keyword);

        expect(presentationContact.contacts.isNotEmpty, true);

        expect(presentationContact.contacts.length, 2);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsSuccess'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsInitial.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n'
      'AFTER that, enable search mode'
      '[Search 1] search by keyword return contacts with keyword A'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n'
      '[Search 2] search by keyword return contacts with keyword Alice test'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsInitial state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeywordFirst = 'A';
        const searchKeywordSecond = 'Alice test';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(Right(GetContactsSuccess(contacts: tomContacts))),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeywordFirst;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            Right(
              GetPresentationContactsSuccess(
                contacts: tomContacts,
                keyword: searchKeywordFirst,
              ),
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeywordFirst,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeywordFirst);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .first
              .displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
                  .getSuccessOrNull()
              is GetPresentationContactsSuccess,
          true,
        );

        final presentationContact =
            mockContactsViewControllerMixin.presentationContactNotifier.value
                    .getSuccessOrNull()
                as GetPresentationContactsSuccess;

        expect(presentationContact.keyword, keyword);

        expect(presentationContact.contacts.isNotEmpty, true);

        expect(presentationContact.contacts.length, 2);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeywordSecond;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            const Right(
              GetPresentationContactsSuccess(
                contacts: [],
                keyword: searchKeywordSecond,
              ),
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Right(GetPhonebookContactsInitial())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeywordSecond,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeywordSecond);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .first
              .displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
                  .getSuccessOrNull()
              is GetPresentationContactsSuccess,
          true,
        );

        final presentationContactTwo =
            mockContactsViewControllerMixin.presentationContactNotifier.value
                    .getSuccessOrNull()
                as GetPresentationContactsSuccess;

        expect(presentationContactTwo.keyword, searchKeywordSecond);

        expect(presentationContactTwo.contacts.isNotEmpty, false);

        expect(presentationContactTwo.contacts.length, 0);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Right(GetPhonebookContactsInitial()),
        );
      },
    );
  });

  group('Test ContactsViewControllerMixin on Mobile', () {
    late MockContactsViewControllerMixin mockContactsViewControllerMixin;
    late Client mockClient;
    late MatrixLocalizations mockMatrixLocalizations;
    late BuildContext mockBuildContext;

    setUp(() {
      mockContactsViewControllerMixin = MockContactsViewControllerMixin();
      mockMatrixLocalizations = MockMatrixLocalizations();
      mockClient = MockClient();
      mockBuildContext = MockBuildContext();
    });
    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is empty.\n'
      'AND presentationContactNotifier return GetContactsIsEmpty'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsIsEmpty.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n',
      () {
        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );
      },
    );

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsIsEmpty'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsIsEmpty.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n',
      () {
        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );
      },
    );

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsSuccess'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsSuccess.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsSuccess state.\n',
      () {
        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(Right(GetContactsSuccess(contacts: tomContacts))),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            Right(
              GetPhonebookContactsSuccess(
                contacts: phonebookContacts,
                progress: 100,
              ),
            ),
          ),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        final presentationContact = mockContactsViewControllerMixin
            .presentationContactNotifier
            .value
            .getSuccessOrNull();

        expect(presentationContact is GetContactsSuccess, true);

        expect(
          (presentationContact as GetContactsSuccess).contacts.isNotEmpty,
          true,
        );

        final presentationPhonebookContact = mockContactsViewControllerMixin
            .presentationPhonebookContactNotifier
            .value
            .getSuccessOrNull();

        expect(
          presentationPhonebookContact is GetPhonebookContactsSuccess,
          true,
        );

        expect(
          (presentationPhonebookContact as GetPhonebookContactsSuccess)
              .contacts
              .isNotEmpty,
          true,
        );
      },
    );

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is empty.\n'
      'AND presentationContactNotifier return GetContactsFailure'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsFailure.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsFailure state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsFailure state.\n',
      () {
        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            const Left(GetContactsFailure(keyword: '', exception: dynamic)),
          ),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            const Left(
              GetPhonebookContactsFailure(exception: dynamic, contacts: []),
            ),
          ),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsFailure(keyword: '', exception: dynamic)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(
            GetPhonebookContactsFailure(exception: dynamic, contacts: []),
          ),
        );
      },
    );

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is empty.\n'
      'AND presentationContactNotifier return GetContactsIsEmpty'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsIsEmpty.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n'
      'AFTER that, enable search mode with keyword is 123'
      'THEN search by keyword return no result'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeyword = '123';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeyword;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeyword,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeyword);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );
      },
    );

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsIsEmpty'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsIsEmpty.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n'
      'AFTER that, enable search mode with keyword is 123'
      'THEN search by keyword return no result'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeyword = '123';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeyword;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeyword,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeyword);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsSuccess'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsSuccess.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n'
      'AFTER that, enable search mode with keyword is 123'
      'THEN search by keyword return no result'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeyword = '123';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(Right(GetContactsSuccess(contacts: tomContacts))),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            Right(
              GetPhonebookContactsSuccess(
                contacts: phonebookContacts,
                progress: 100,
              ),
            ),
          ),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          Right(
            GetPhonebookContactsSuccess(
              contacts: phonebookContacts,
              progress: 100,
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeyword;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom([]));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(ValueNotifierCustom(const Left(GetContactsIsEmpty())));

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeyword,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeyword);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsSuccess'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsSuccess.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsSuccess state.\n'
      'AFTER that, enable search mode'
      'THEN search by keyword return contacts with keyword a'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeyword = 'a';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(Right(GetContactsSuccess(contacts: tomContacts))),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            Right(
              GetPhonebookContactsSuccess(
                contacts: phonebookContacts,
                progress: 100,
              ),
            ),
          ),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          Right(
            GetPhonebookContactsSuccess(
              contacts: phonebookContacts,
              progress: 100,
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeyword;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            Right(
              GetPresentationContactsSuccess(
                contacts: tomContacts,
                keyword: searchKeyword,
              ),
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeyword,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeyword);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .first
              .displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
                  .getSuccessOrNull()
              is GetPresentationContactsSuccess,
          true,
        );

        final presentationContact =
            mockContactsViewControllerMixin.presentationContactNotifier.value
                    .getSuccessOrNull()
                as GetPresentationContactsSuccess;

        expect(presentationContact.keyword, keyword);

        expect(presentationContact.contacts.isNotEmpty, true);

        expect(presentationContact.contacts.length, 2);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND search mode is disable.\n'
      'AND presentationRecentContactNotifier return SearchRecentChatSuccess with contacts is not empty.\n'
      'AND presentationContactNotifier return GetContactsSuccess'
      'AND presentationPhonebookContactNotifier return GetPhonebookContactsSuccess.\n'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsSuccess state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsSuccess state.\n'
      'AFTER that, enable search mode'
      '[Search 1] search by keyword return contacts with keyword A'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n'
      '[Search 2] search by keyword return contacts with keyword Alice test'
      'THEN presentationRecentContactNotifier SHOULD have SearchRecentChatSuccess state.\n'
      'THEN presentationContactNotifier SHOULD have GetContactsIsEmpty state.\n'
      'THEN presentationPhonebookContactNotifier SHOULD have GetPhonebookContactsIsEmpty state.\n',
      () async {
        final Debouncer<String> debouncer = Debouncer(
          const Duration(milliseconds: debouncerIntervalInMilliseconds),
          initialValue: '',
        );

        const searchKeywordFirst = 'A';
        const searchKeywordSecond = 'Alice test';
        String? keyword;

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(false));

        when(
          mockContactsViewControllerMixin.textEditingController,
        ).thenReturn(TextEditingController());

        mockContactsViewControllerMixin.textEditingController.addListener(() {
          debouncer.value =
              mockContactsViewControllerMixin.textEditingController.text;
        });

        debouncer.values.listen((value) {
          keyword = value;
        });

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(Right(GetContactsSuccess(contacts: tomContacts))),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            Right(
              GetPhonebookContactsSuccess(
                contacts: phonebookContacts,
                progress: 100,
              ),
            ),
          ),
        );

        mockContactsViewControllerMixin.initialFetchContacts(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        verify(
          mockContactsViewControllerMixin.initialFetchContacts(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          Right(
            GetPhonebookContactsSuccess(
              contacts: phonebookContacts,
              progress: 100,
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.isSearchModeNotifier,
        ).thenReturn(ValueNotifier(true));

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeywordFirst;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            Right(
              GetPresentationContactsSuccess(
                contacts: tomContacts,
                keyword: searchKeywordFirst,
              ),
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeywordFirst,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeywordFirst);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .first
              .displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
                  .getSuccessOrNull()
              is GetPresentationContactsSuccess,
          true,
        );

        final presentationContact =
            mockContactsViewControllerMixin.presentationContactNotifier.value
                    .getSuccessOrNull()
                as GetPresentationContactsSuccess;

        expect(presentationContact.keyword, keyword);

        expect(presentationContact.contacts.isNotEmpty, true);

        expect(presentationContact.contacts.length, 2);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );

        mockContactsViewControllerMixin.textEditingController.text =
            searchKeywordSecond;

        when(
          mockContactsViewControllerMixin.presentationRecentContactNotifier,
        ).thenReturn(ValueNotifierCustom(recentContacts));

        when(
          mockContactsViewControllerMixin.presentationContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(
            const Right(
              GetPresentationContactsSuccess(
                contacts: [],
                keyword: searchKeywordSecond,
              ),
            ),
          ),
        );

        when(
          mockContactsViewControllerMixin.presentationPhonebookContactNotifier,
        ).thenReturn(
          ValueNotifierCustom(const Left(GetPhonebookContactsIsEmpty())),
        );

        mockContactsViewControllerMixin.refreshAllContactsTest(
          context: mockBuildContext,
          client: mockClient,
          matrixLocalizations: mockMatrixLocalizations,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockContactsViewControllerMixin.refreshAllContactsTest(
            context: mockBuildContext,
            client: mockClient,
            matrixLocalizations: mockMatrixLocalizations,
          ),
        ).called(1);

        expect(
          mockContactsViewControllerMixin.isSearchModeNotifier.value,
          true,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text.isEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.textEditingController.text,
          searchKeywordSecond,
        );

        expect(keyword != null, true);

        expect(keyword, searchKeywordSecond);

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier
              .value
              .first
              .displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
                  .getSuccessOrNull()
              is GetPresentationContactsSuccess,
          true,
        );

        final presentationContactTwo =
            mockContactsViewControllerMixin.presentationContactNotifier.value
                    .getSuccessOrNull()
                as GetPresentationContactsSuccess;

        expect(presentationContactTwo.keyword, searchKeywordSecond);

        expect(presentationContactTwo.contacts.isNotEmpty, false);

        expect(presentationContactTwo.contacts.length, 0);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier
              .value,
          const Left(GetPhonebookContactsIsEmpty()),
        );
      },
    );
  });
}
