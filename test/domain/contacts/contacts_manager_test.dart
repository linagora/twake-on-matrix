import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/phonebook_contact_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'contacts_manager_test.mocks.dart';

@GenerateMocks([GetTomContactsInteractor, PhonebookContactInteractor])
void main() {
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

  setUpAll(() {
    HiveCacheStore('${Directory.current.path}/test/data/file_store');
  });

  group('ContactsManager Unit test - ENV: WEB', () {
    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
      'THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      'THEN phonebookContactInteractor in ContactsManager SHOULD have ContactsInitial state.\n'
      'THEN list ToM contact SHOULD is empty.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Right(GetContactsSuccess(contacts: [])),
          ]),
        );

        verifyNever(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: false,
        );

        await Future.delayed(const Duration(seconds: 2));

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            const GetContactsSuccess(contacts: []),
          ],
        );

        final phonebookContacts =
            contactsManager.getPhonebookContactsNotifier().value;

        verifyNever(mockPhonebookContactInteractor.execute());

        expect(phonebookContacts, const Right(GetPhonebookContactsInitial()));
      },
    );

    test(
      'WHEN it is not available to get Phonebook contact.\n'
      'AND contactsNotifier return GetContactsSuccess with contacts is not empty.\n'
      'THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      'THEN phonebookContactInteractor in ContactsManager SHOULD have ContactsInitial state.\n'
      'THEN list ToM contact SHOULD is not empty.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(GetContactsSuccess(contacts: tomContacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: false,
        );

        await Future.delayed(const Duration(seconds: 2));

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            GetContactsSuccess(contacts: tomContacts),
          ],
        );

        final phonebookContacts =
            contactsManager.getPhonebookContactsNotifier().value;

        verifyNever(mockPhonebookContactInteractor.execute());

        expect(phonebookContacts, const Right(GetPhonebookContactsInitial()));
      },
    );

    test(
      'WHEN it is not available to get Phonebook contact.\n'
      'THEN contactsNotifier in ContactsManager SHOULD have GetContactsFailure state.\n'
      'THEN phonebookContactInteractor in ContactsManager SHOULD have ContactsInitial state.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];
        final List<Failure> listTomContactsFailureState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsFailure(keyword: '', exception: dynamic)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => listTomContactsFailureState.add(failure),
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        verifyNever(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: false,
        );

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        await Future.delayed(const Duration(seconds: 2));

        expectLater(listTomContactsSuccessState.length, 1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
          ],
        );

        expectLater(
          listTomContactsFailureState,
          [
            const GetContactsFailure(keyword: '', exception: dynamic),
          ],
        );

        final phonebookContacts =
            contactsManager.getPhonebookContactsNotifier().value;

        verifyNever(mockPhonebookContactInteractor.execute());
        expect(phonebookContacts, const Right(GetPhonebookContactsInitial()));
      },
    );
  });

  group('ContactsManager Unit test - ENV: Mobile', () {
    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
      'AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
      'THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      'THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      'THEN list ToM contact SHOULD is empty.\n'
      'THEN list Phonebook contact SHOULD is empty.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Right(GetContactsSuccess(contacts: [])),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            const Right(GetPhonebookContactsSuccess(contacts: [])),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
                (failure) => null,
                (success) => listPhonebookContactsSuccessState.add(success),
              );
        });

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            const GetContactsSuccess(contacts: []),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
            const GetPhonebookContactsSuccess(contacts: []),
          ],
        );
      },
    );

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND call initialSynchronizeContacts success.\n'
      'AND THEN call initialSynchronizeContacts again.\n'
      'AND contactsNotifier return GetContactsSuccess with contacts is not empty.\n'
      'AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is not empty.\n'
      'THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      'THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      'THEN list ToM contact SHOULD is not empty.\n'
      'THEN list Phonebook contact SHOULD is not empty.\n'
      'THEN contactsNotifier and phonebookContactInteractor just call only one time.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(GetContactsSuccess(contacts: tomContacts)),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
                (failure) => null,
                (success) => listPhonebookContactsSuccessState.add(success),
              );
        });

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getSuccessOrNull<ContactsInitial>() !=
              null,
          true,
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 5));

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getSuccessOrNull<GetContactsSuccess>() !=
              null,
          true,
        );

        expect(
          contactsManager
                  .getPhonebookContactsNotifier()
                  .value
                  .getSuccessOrNull<GetPhonebookContactsSuccess>() !=
              null,
          true,
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            GetContactsSuccess(contacts: tomContacts),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
            GetPhonebookContactsSuccess(contacts: phonebookContacts),
          ],
        );
      },
    );

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND call initialSynchronizeContacts.\n'
      'AND contactsNotifier is LoadingState.\n'
      'AND THEN call initialSynchronizeContacts again.\n'
      'AND contactsNotifier not call again\n'
      'AND contactsNotifier return ContactLoadingState with contacts is not empty.\n'
      'AND phonebookContactInteractor not call.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) async* {
            yield const Right(ContactsLoading());
            await Future.delayed(const Duration(seconds: 5));
          },
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        expect(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
          ],
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 2));

        verify(
          contactsManager.getTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verifyNever(
          contactsManager.phonebookContactInteractor.execute(),
        );
      },
    );

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND call initialSynchronizeContacts.\n'
      'AND contactsNotifier is LoadingState and call initialSynchronizeContacts again.\n'
      'AND GetTomContactInteractor called 1 \n'
      'AND GetPhonebookContactInteractor called 0.\n'
      'AFTER the first time call initialSynchronizeContacts is success.\n'
      'THEN GetTomContactInteractor called 1 and GetPhonebookContactInteractor call 1\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) async* {
            yield const Right(ContactsLoading());
            await Future.delayed(const Duration(seconds: 10));
            yield Right(GetContactsSuccess(contacts: tomContacts));
          },
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        expect(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
          ],
        );

        verify(
          contactsManager.getTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verifyNever(
          contactsManager.phonebookContactInteractor.execute(),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 10));

        expect(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            GetContactsSuccess(contacts: tomContacts),
          ],
        );

        verify(
          contactsManager.phonebookContactInteractor.execute(),
        ).called(1);
      },
    );

    test(
      '[Account-A] WHEN it is available get Phonebook contact.\n'
      '[Account-A] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
      '[Account-A] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
      '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      '[Account-A] THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      '[Account-A] THEN list ToM contact SHOULD is empty.\n'
      '[Account-A] THEN list Phonebook contact SHOULD is empty.\n'
      'Trigger UI => switch to another account and call synchronize contacts.\n'
      '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
      '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
      '[Account-B] THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      '[Account-B] THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      '[Account-B] THEN list ToM contact SHOULD is empty.\n'
      '[Account-B] THEN list Phonebook contact SHOULD is empty.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            const Left(GetPhonebookContactsIsEmpty()),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
                (failure) => null,
                (success) => listPhonebookContactsSuccessState.add(success),
              );
        });

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 1);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 1);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
          ],
        );

        /// Trigger switch account
        contactsManager.reSyncContacts();

        listTomContactsSuccessState.clear();

        listPhonebookContactsSuccessState.clear();

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            const Left(GetPhonebookContactsIsEmpty()),
          ]),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 1);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 1);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
          ],
        );
      },
    );

    test(
      '[Account-A] WHEN it is available get Phonebook contact.\n'
      '[Account-A] AND call initialSynchronizeContacts success.\n'
      '[Account-A] AND contactsNotifier return GetContactsSuccess with contacts is not empty.\n'
      '[Account-A] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is not empty.\n'
      '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      '[Account-A] THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      '[Account-A] THEN list ToM contact SHOULD is not empty.\n'
      '[Account-A] THEN list Phonebook contact SHOULD is not empty.\n'
      '[Account-A] THEN contactsNotifier and phonebookContactInteractor just call only one time.\n'
      'Trigger UI => switch to another account and call synchronize contacts.\n'
      '[Account-B] AND THEN call initialSynchronizeContacts again.\n'
      '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is not empty.\n'
      '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is not empty.\n'
      '[Account-B] THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      '[Account-B] THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      '[Account-B] THEN list ToM contact SHOULD is not empty.\n'
      '[Account-B] THEN list Phonebook contact SHOULD is not empty.\n'
      '[Account-B] THEN contactsNotifier and phonebookContactInteractor just call only one time.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(GetContactsSuccess(contacts: tomContacts)),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
                (failure) => null,
                (success) => listPhonebookContactsSuccessState.add(success),
              );
        });

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getSuccessOrNull<ContactsInitial>() !=
              null,
          true,
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            GetContactsSuccess(contacts: tomContacts),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
            GetPhonebookContactsSuccess(contacts: phonebookContacts),
          ],
        );

        /// Trigger switch account

        contactsManager.reSyncContacts();

        listTomContactsSuccessState.clear();

        listPhonebookContactsSuccessState.clear();

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(GetContactsSuccess(contacts: tomContacts)),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
          ]),
        );

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getSuccessOrNull<ContactsInitial>() !=
              null,
          true,
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            GetContactsSuccess(contacts: tomContacts),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
            GetPhonebookContactsSuccess(contacts: phonebookContacts),
          ],
        );
      },
    );

    test(
      '[Account-A] WHEN it is available get Phonebook contact.\n'
      '[Account-A] AND call initialSynchronizeContacts success.\n'
      '[Account-A] AND contactsNotifier return GetContactsSuccess with contacts is not empty.\n'
      '[Account-A] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is not empty.\n'
      '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      '[Account-A] THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      '[Account-A] THEN list ToM contact SHOULD is not empty.\n'
      '[Account-A] THEN list Phonebook contact SHOULD is not empty.\n'
      '[Account-A] THEN contactsNotifier and phonebookContactInteractor just call only one time.\n'
      'Trigger UI => switch to another account and call synchronize contacts.\n'
      '[Account-B] AND THEN call initialSynchronizeContacts again.\n'
      '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
      '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is not empty.\n'
      '[Account-B] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
      '[Account-B] THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      '[Account-B] THEN list ToM contact SHOULD is empty.\n'
      '[Account-B] THEN list Phonebook contact SHOULD is not empty.\n'
      '[Account-B] THEN contactsNotifier and phonebookContactInteractor just call only one time.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(GetContactsSuccess(contacts: tomContacts)),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
                (failure) => null,
                (success) => listPhonebookContactsSuccessState.add(success),
              );
        });

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getSuccessOrNull<ContactsInitial>() !=
              null,
          true,
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getSuccessOrNull<GetContactsSuccess>() !=
              null,
          true,
        );

        expect(
          contactsManager
                  .getPhonebookContactsNotifier()
                  .value
                  .getSuccessOrNull<GetPhonebookContactsSuccess>() !=
              null,
          true,
        );

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            GetContactsSuccess(contacts: tomContacts),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
            GetPhonebookContactsSuccess(contacts: phonebookContacts),
          ],
        );

        /// Trigger switch account

        contactsManager.reSyncContacts();

        listTomContactsSuccessState.clear();

        listPhonebookContactsSuccessState.clear();

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
          ]),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getFailureOrNull<GetContactsIsEmpty>() !=
              null,
          true,
        );

        expect(
          contactsManager
                  .getPhonebookContactsNotifier()
                  .value
                  .getSuccessOrNull<GetPhonebookContactsSuccess>() !=
              null,
          true,
        );
        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 1);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
            GetPhonebookContactsSuccess(contacts: phonebookContacts),
          ],
        );
      },
    );

    test(
      '[Account-A] WHEN it is available get Phonebook contact.\n'
      '[Account-A] AND call initialSynchronizeContacts success.\n'
      '[Account-A] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
      '[Account-A] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
      '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
      '[Account-A] THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
      '[Account-A] THEN list ToM contact SHOULD is empty.\n'
      '[Account-A] THEN list Phonebook contact SHOULD is empty.\n'
      '[Account-A] THEN contactsNotifier and phonebookContactInteractor just call only one time.\n'
      'Trigger UI => switch to another account and call synchronize contacts.\n'
      '[Account-B] AND THEN call initialSynchronizeContacts again.\n'
      '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
      '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is not empty.\n'
      '[Account-B] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
      '[Account-B] THEN phonebookContactInteractor in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
      '[Account-B] THEN list ToM contact SHOULD is empty.\n'
      '[Account-B] THEN list Phonebook contact SHOULD is not empty.\n'
      '[Account-B] THEN contactsNotifier and phonebookContactInteractor just call only one time.\n',
      () async {
        final mockGetTomContactsInteractor = MockGetTomContactsInteractor();
        final mockPhonebookContactInteractor = MockPhonebookContactInteractor();

        final contactsManager = ContactsManager(
          getTomContactsInteractor: mockGetTomContactsInteractor,
          phonebookContactInteractor: mockPhonebookContactInteractor,
        );

        final List<Success> listTomContactsSuccessState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            const Left(GetPhonebookContactsIsEmpty()),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
                (failure) => null,
                (success) => listTomContactsSuccessState.add(success),
              );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
                (failure) => null,
                (success) => listPhonebookContactsSuccessState.add(success),
              );
        });

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getFailureOrNull<GetContactsIsEmpty>() !=
              null,
          true,
        );

        expect(
          contactsManager
                  .getPhonebookContactsNotifier()
                  .value
                  .getFailureOrNull<GetPhonebookContactsIsEmpty>() !=
              null,
          true,
        );

        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 1);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 1);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
          ],
        );

        /// Trigger switch account

        contactsManager.reSyncContacts();

        listTomContactsSuccessState.clear();

        listPhonebookContactsSuccessState.clear();

        when(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(GetContactsSuccess(contacts: tomContacts)),
          ]),
        );

        when(mockPhonebookContactInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading(progress: 0)),
            Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
          ]),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
        );

        await Future.delayed(const Duration(seconds: 1));

        expect(
          contactsManager
                  .getContactsNotifier()
                  .value
                  .getSuccessOrNull<GetContactsSuccess>() !=
              null,
          true,
        );

        expect(
          contactsManager
                  .getPhonebookContactsNotifier()
                  .value
                  .getSuccessOrNull<GetPhonebookContactsSuccess>() !=
              null,
          true,
        );
        verify(
          mockGetTomContactsInteractor.execute(
            limit: AppConfig.maxFetchContacts,
          ),
        ).called(1);

        verify(
          mockPhonebookContactInteractor.execute(),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(
          listTomContactsSuccessState,
          [
            const ContactsLoading(),
            GetContactsSuccess(contacts: tomContacts),
          ],
        );

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(
          listPhonebookContactsSuccessState,
          [
            const GetPhonebookContactsLoading(progress: 0),
            GetPhonebookContactsSuccess(contacts: phonebookContacts),
          ],
        );
      },
    );
  });
}
