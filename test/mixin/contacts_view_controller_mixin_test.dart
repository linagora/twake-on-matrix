import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_success.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../domain/contacts/contacts_manager_test.mocks.dart';
import 'contacts_view_controller_mixin_test.mocks.dart';

class ConcretePresentationSearch extends PresentationSearch {
  const ConcretePresentationSearch({
    required String displayName,
    required String email,
    required String phoneNumber,
    required ContactStatus status,
  }) : super(
          displayName: displayName,
          email: email,
        );

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
    const Contact(
      email: "alice1@domain.com",
      displayName: "Alice 1",
      matrixId: "@alice1:domain.com",
      phoneNumber: "07 81 12 38 61",
      status: ContactStatus.active,
    ),
    const Contact(
      email: "alice2@domain.com",
      displayName: "Alice 2",
      matrixId: "@alice2:domain.com",
      phoneNumber: "02 81 12 38 61",
      status: ContactStatus.active,
    ),
    const Contact(
      email: "alice3@domain.com",
      displayName: "Alice 3",
      matrixId: "@alice3:domain.com",
      phoneNumber: "03 81 12 38 61",
      status: ContactStatus.active,
    ),
    const Contact(
      email: "alice4@domain.com",
      displayName: "Alice 4",
      matrixId: "@alice4:domain.com",
      phoneNumber: "04 81 12 38 61",
      status: ContactStatus.inactive,
    ),
    const Contact(
      email: "alice5@domain.com",
      displayName: "Alice 5",
      matrixId: "@alice5:domain.com",
      phoneNumber: "05 81 12 38 61",
      status: ContactStatus.inactive,
    ),
  ];

  final List<Contact> phonebookContacts = [
    const Contact(
      email: "bob@domain.com",
      displayName: "BoB",
    ),
    const Contact(
      displayName: "BoB1",
      phoneNumber: "11 22 33 44 55",
    ),
    const Contact(
      email: "bob2@domain.com",
      displayName: "BoB2",
      phoneNumber: "+84000000000",
    ),
    const Contact(
      email: "bob3@domain.com",
      displayName: "BoB 3",
    ),
    const Contact(
      email: "bob@domain.com",
      displayName: "BoB",
    ),
  ];

  final List<ConcretePresentationSearch> recentContacts = [
    const ConcretePresentationSearch(
      displayName: "Alice test",
      email: "alicetest@domain.com",
      phoneNumber: "+84111111111",
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        final presentationContact = mockContactsViewControllerMixin
            .presentationContactNotifier.value
            .getSuccessOrNull();

        expect(
          presentationContact is GetContactsSuccess,
          true,
        );

        expect(
          (presentationContact as GetContactsSuccess).contacts.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsFailure(keyword: '', exception: dynamic)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier.value.first.displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
              .getSuccessOrNull() is GetPresentationContactsSuccess,
          true,
        );

        final presentationContact = mockContactsViewControllerMixin
            .presentationContactNotifier.value
            .getSuccessOrNull() as GetPresentationContactsSuccess;

        expect(presentationContact.keyword, keyword);

        expect(presentationContact.contacts.isNotEmpty, true);

        expect(presentationContact.contacts.length, 5);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier.value.first.displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
              .getSuccessOrNull() is GetPresentationContactsSuccess,
          true,
        );

        final presentationContact = mockContactsViewControllerMixin
            .presentationContactNotifier.value
            .getSuccessOrNull() as GetPresentationContactsSuccess;

        expect(presentationContact.keyword, keyword);

        expect(presentationContact.contacts.isNotEmpty, true);

        expect(presentationContact.contacts.length, 5);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier.value.first.displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
              .getSuccessOrNull() is GetPresentationContactsSuccess,
          true,
        );

        final presentationContactTwo = mockContactsViewControllerMixin
            .presentationContactNotifier.value
            .getSuccessOrNull() as GetPresentationContactsSuccess;

        expect(presentationContactTwo.keyword, searchKeywordSecond);

        expect(presentationContactTwo.contacts.isNotEmpty, false);

        expect(presentationContactTwo.contacts.length, 0);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
        );

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
              .presentationRecentContactNotifier.value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        final presentationContact = mockContactsViewControllerMixin
            .presentationContactNotifier.value
            .getSuccessOrNull();

        expect(
          presentationContact is GetContactsSuccess,
          true,
        );

        expect(
          (presentationContact as GetContactsSuccess).contacts.isNotEmpty,
          true,
        );

        final presentationPhonebookContact = mockContactsViewControllerMixin
            .presentationPhonebookContactNotifier.value
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
            const Left(GetPhonebookContactsFailure(exception: dynamic)),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsFailure(keyword: '', exception: dynamic)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
          const Left(GetPhonebookContactsFailure(exception: dynamic)),
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
        );

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
              .presentationRecentContactNotifier.value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value,
          [],
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
        );

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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
          Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
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
        ).thenReturn(
          ValueNotifierCustom(const Left(GetContactsIsEmpty())),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          false,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          const Left(GetContactsIsEmpty()),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
          Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier.value.first.displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
              .getSuccessOrNull() is GetPresentationContactsSuccess,
          true,
        );

        final presentationContact = mockContactsViewControllerMixin
            .presentationContactNotifier.value
            .getSuccessOrNull() as GetPresentationContactsSuccess;

        expect(presentationContact.keyword, keyword);

        expect(presentationContact.contacts.isNotEmpty, true);

        expect(presentationContact.contacts.length, 5);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value,
          Right(GetContactsSuccess(contacts: tomContacts)),
        );

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
          Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier.value.first.displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
              .getSuccessOrNull() is GetPresentationContactsSuccess,
          true,
        );

        final presentationContact = mockContactsViewControllerMixin
            .presentationContactNotifier.value
            .getSuccessOrNull() as GetPresentationContactsSuccess;

        expect(presentationContact.keyword, keyword);

        expect(presentationContact.contacts.isNotEmpty, true);

        expect(presentationContact.contacts.length, 5);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
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
              .presentationRecentContactNotifier.value.isNotEmpty,
          true,
        );

        expect(
          mockContactsViewControllerMixin
              .presentationRecentContactNotifier.value.first.displayName,
          'Alice test',
        );

        expect(
          mockContactsViewControllerMixin.presentationContactNotifier.value
              .getSuccessOrNull() is GetPresentationContactsSuccess,
          true,
        );

        final presentationContactTwo = mockContactsViewControllerMixin
            .presentationContactNotifier.value
            .getSuccessOrNull() as GetPresentationContactsSuccess;

        expect(presentationContactTwo.keyword, searchKeywordSecond);

        expect(presentationContactTwo.contacts.isNotEmpty, false);

        expect(presentationContactTwo.contacts.length, 0);

        expect(
          mockContactsViewControllerMixin
              .presentationPhonebookContactNotifier.value,
          const Left(GetPhonebookContactsIsEmpty()),
        );
      },
    );
  });

  group(
    'Test refreshRecentContacts in ContactsViewControllerMixin',
    () {
      late CustomContactsViewControllerMixin contactsViewControllerMixin;
      late GetIt getIt;

      setUpAll(() {
        getIt = GetIt.instance;
        getIt.registerSingleton<SearchRecentChatInteractor>(
          SearchRecentChatInteractor(),
        );
        getIt.registerFactory<MockGetTomContactsInteractor>(
          () => MockGetTomContactsInteractor(),
        );
        getIt.registerFactory<MockPhonebookContactInteractor>(
          () => MockPhonebookContactInteractor(),
        );
        getIt.registerSingleton<ContactsManager>(
          ContactsManager(
            getTomContactsInteractor: MockGetTomContactsInteractor(),
            phonebookContactInteractor: MockPhonebookContactInteractor(),
          ),
        );
        contactsViewControllerMixin = CustomContactsViewControllerMixin();
      });

      test(
        'WHEN handleSearchRecentContacts is called.\n'
        'AND not existed recent item in tomContacts\n'
        'THEN recentFiltered have the list same recentChat\n',
        () {
          final List<PresentationSearch> tomContacts = [
            const ContactPresentationSearch(
              matrixId: 'matrix_id_1',
              email: 'email1@gmail.com',
              displayName: 'display_name_1',
            ),
            const ContactPresentationSearch(
              matrixId: 'matrix_id_2',
              email: 'email2@gmail.com',
              displayName: 'display_name_2',
            ),
            const ContactPresentationSearch(
              matrixId: 'matrix_id_3',
              email: 'email3@gmail.com',
              displayName: 'display_name_3',
            ),
            const ContactPresentationSearch(
              matrixId: 'matrix_id_4',
              email: 'email4@gmail.com',
              displayName: 'display_name_4',
            ),
          ];

          final List<PresentationSearch> recentChat = [
            const RecentChatPresentationSearch(
              directChatMatrixID: 'room_id_5',
              displayName: 'display_name_1',
            ),
            const RecentChatPresentationSearch(
              roomId: 'room_id_6',
              displayName: 'display_name_2',
            ),
            const RecentChatPresentationSearch(
              roomId: 'room_id_9',
              displayName: 'display_name_9',
            ),
            const RecentChatPresentationSearch(
              roomId: 'room_id_10',
              displayName: 'display_name_10',
            ),
          ];

          final recentFiltered =
              contactsViewControllerMixin.handleSearchRecentContacts(
            contacts: tomContacts,
            recentChat: recentChat,
            keyword: '',
          );

          expect(recentFiltered.isNotEmpty, true);

          expect(recentFiltered.length, 4);

          expect(recentFiltered, containsAll(recentChat));
        },
      );

      test(
        'WHEN handleSearchRecentContacts is called.\n'
        'AND recent list have one item duplicated in tom contact\n'
        'THEN recentFiltered have list but not include duplicated item\n',
        () {
          final List<PresentationSearch> tomContacts = [
            const ContactPresentationSearch(
              matrixId: 'matrix_id_1',
              email: 'email1@gmail.com',
              displayName: 'display_name_1',
            ),
            const ContactPresentationSearch(
              matrixId: 'matrix_id_2',
              email: 'email2@gmail.com',
              displayName: 'display_name_2',
            ),
            const ContactPresentationSearch(
              matrixId: 'matrix_id_3',
              email: 'email3@gmail.com',
              displayName: 'display_name_3',
            ),
            const ContactPresentationSearch(
              matrixId: 'matrix_id_4',
              email: 'email4@gmail.com',
              displayName: 'display_name_4',
            ),
          ];

          final List<PresentationSearch> recentChat = [
            const RecentChatPresentationSearch(
              roomId: 'room_id_1',
              directChatMatrixID: 'matrix_id_1',
              displayName: 'display_name_1',
            ),
            const RecentChatPresentationSearch(
              roomId: 'room_id_6',
              displayName: 'display_name_2',
            ),
            const RecentChatPresentationSearch(
              roomId: 'room_id_9',
              displayName: 'display_name_9',
            ),
            const RecentChatPresentationSearch(
              roomId: 'room_id_10',
              displayName: 'display_name_10',
            ),
          ];

          final recentFiltered =
              contactsViewControllerMixin.handleSearchRecentContacts(
            contacts: tomContacts,
            recentChat: recentChat,
            keyword: 'matrix_id_1',
          );

          expect(recentFiltered.isNotEmpty, true);

          expect(recentFiltered.length, 3);

          expect(recentFiltered.length < recentChat.length, true);
        },
      );
    },
  );
}
