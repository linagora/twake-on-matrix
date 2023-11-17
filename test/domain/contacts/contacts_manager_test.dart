import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/usecase/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/phonebook_contact_interactor.dart';
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
    TestWidgetsFlutterBinding.ensureInitialized();
    GetItInitializer().setUp();
  });

  group('Request permission on web and tomContacts', () {
    late ContactsManager contactsManager;
    late MockGetTomContactsInteractor mockGetTomContactsInteractor;

    setUp(() {
      getIt.registerSingleton<MockGetTomContactsInteractor>(
        MockGetTomContactsInteractor(),
      );
    });

    test('TomContact is Empty', () async {
      contactsManager = getIt.get<ContactsManager>();

      mockGetTomContactsInteractor = getIt.get<MockGetTomContactsInteractor>();

      when(
        mockGetTomContactsInteractor.execute(
          limit: AppConfig.maxFetchContacts,
        ),
      ).thenAnswer(
        (_) async* {
          yield const Right(ContactsLoading());
          yield const Right(GetContactsSuccess(contacts: []));
        },
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: false,
      );

      await mockGetTomContactsInteractor
          .execute(limit: AppConfig.maxFetchContacts)
          .forEach(
            (event) => contactsManager.setContactsNotifier(event),
          );

      final contacts = contactsManager.getContactsNotifier().value;
      final phonebookContacts =
          contactsManager.getPhonebookContactsNotifier().value;

      final successState = contacts.getSuccessOrNull<GetContactsSuccess>();

      expect(successState?.contacts != null, true);
      expect(successState?.contacts, []);
      expect(successState?.contacts.isEmpty, true);

      expect(
        contacts,
        const Right(GetContactsSuccess(contacts: [])),
      );
      expect(phonebookContacts, const Right(GetPhonebookContactsInitial()));
    });

    test('TomContact is not empty', () async {
      contactsManager = getIt.get<ContactsManager>();

      mockGetTomContactsInteractor = getIt.get<MockGetTomContactsInteractor>();

      final phonebookContacts =
          contactsManager.getPhonebookContactsNotifier().value;

      when(
        mockGetTomContactsInteractor.execute(
          limit: AppConfig.maxFetchContacts,
        ),
      ).thenAnswer(
        (_) async* {
          yield const Right(ContactsLoading());
          yield Right(GetContactsSuccess(contacts: tomContacts));
        },
      );

      expect(
        contactsManager.getContactsNotifier().value,
        const Right(ContactsInitial()),
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: false,
      );

      await mockGetTomContactsInteractor
          .execute(limit: AppConfig.maxFetchContacts)
          .forEach(
            (event) => contactsManager.setContactsNotifier(event),
          );

      final successState = contactsManager
          .getContactsNotifier()
          .value
          .getSuccessOrNull<GetContactsSuccess>();

      expect(successState?.contacts != null, true);
      expect(successState?.contacts.isEmpty, false);

      expect(
        contactsManager.getContactsNotifier().value,
        Right(GetContactsSuccess(contacts: tomContacts)),
      );
      expect(phonebookContacts, const Right(GetPhonebookContactsInitial()));
    });
  });

  group('Request permission on mobile', () {
    late ContactsManager contactsManager;
    late MockGetTomContactsInteractor mockGetTomContactsInteractor;
    late MockPhonebookContactInteractor mockPhonebookContactInteractor;

    setUp(() {
      getIt.registerSingleton<MockGetTomContactsInteractor>(
        MockGetTomContactsInteractor(),
      );
      getIt.registerSingleton<MockPhonebookContactInteractor>(
        MockPhonebookContactInteractor(),
      );
    });

    test('Request contacts is denied && TomContacts isEmpty', () async {
      contactsManager = getIt.get<ContactsManager>();

      mockGetTomContactsInteractor = getIt.get<MockGetTomContactsInteractor>();

      when(
        mockGetTomContactsInteractor.execute(
          limit: AppConfig.maxFetchContacts,
        ),
      ).thenAnswer(
        (_) async* {
          yield const Right(ContactsLoading());
          yield const Right(GetContactsSuccess(contacts: []));
        },
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: false,
      );

      await mockGetTomContactsInteractor
          .execute(limit: AppConfig.maxFetchContacts)
          .forEach(
            (event) => contactsManager.setContactsNotifier(event),
          );

      final contacts = contactsManager.getContactsNotifier().value;
      final phonebookContacts =
          contactsManager.getPhonebookContactsNotifier().value;

      final successState = contacts.getSuccessOrNull<GetContactsSuccess>();

      expect(successState?.contacts != null, true);
      expect(successState?.contacts, []);
      expect(successState?.contacts.isEmpty, true);

      expect(
        contacts,
        const Right(GetContactsSuccess(contacts: [])),
      );
      expect(phonebookContacts, const Right(GetPhonebookContactsInitial()));
    });

    test('Request contacts is denied && TomContact is not empty', () async {
      contactsManager = getIt.get<ContactsManager>();

      mockGetTomContactsInteractor = getIt.get<MockGetTomContactsInteractor>();

      final phonebookContacts =
          contactsManager.getPhonebookContactsNotifier().value;

      when(
        mockGetTomContactsInteractor.execute(
          limit: AppConfig.maxFetchContacts,
        ),
      ).thenAnswer(
        (_) async* {
          yield const Right(ContactsLoading());
          yield Right(GetContactsSuccess(contacts: tomContacts));
        },
      );

      expect(
        contactsManager.getContactsNotifier().value,
        const Right(ContactsInitial()),
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: false,
      );

      await mockGetTomContactsInteractor
          .execute(limit: AppConfig.maxFetchContacts)
          .forEach(
            (event) => contactsManager.setContactsNotifier(event),
          );

      final successState = contactsManager
          .getContactsNotifier()
          .value
          .getSuccessOrNull<GetContactsSuccess>();

      expect(successState?.contacts != null, true);
      expect(successState?.contacts.isEmpty, false);

      expect(
        contactsManager.getContactsNotifier().value,
        Right(GetContactsSuccess(contacts: tomContacts)),
      );
      expect(phonebookContacts, const Right(GetPhonebookContactsInitial()));
    });

    test(
        'Request contacts is granted && TomContact is not empty && Phonebook isEmpty',
        () async {
      contactsManager = getIt.get<ContactsManager>();

      mockGetTomContactsInteractor = getIt.get<MockGetTomContactsInteractor>();

      mockPhonebookContactInteractor =
          getIt.get<MockPhonebookContactInteractor>();

      when(
        mockGetTomContactsInteractor.execute(
          limit: AppConfig.maxFetchContacts,
        ),
      ).thenAnswer(
        (_) async* {
          yield const Right(ContactsLoading());
          yield Right(GetContactsSuccess(contacts: tomContacts));
        },
      );

      when(
        mockPhonebookContactInteractor.execute(),
      ).thenAnswer(
        (_) async* {
          yield const Right(GetPhonebookContactsLoading(progress: 0));
          yield const Right(GetPhonebookContactsSuccess(contacts: []));
        },
      );

      expect(
        contactsManager.getContactsNotifier().value,
        const Right(ContactsInitial()),
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
      );

      await mockGetTomContactsInteractor
          .execute(limit: AppConfig.maxFetchContacts)
          .forEach(
            (event) => contactsManager.setContactsNotifier(event),
          )
          .whenComplete(() async {
        expect(
          contactsManager.getPhonebookContactsNotifier().value,
          const Right(GetPhonebookContactsInitial()),
        );
        await mockPhonebookContactInteractor.execute().forEach(
              (event) => contactsManager.setPhonebookContactsNotifier(event),
            );
      });

      final successState = contactsManager
          .getContactsNotifier()
          .value
          .getSuccessOrNull<GetContactsSuccess>();

      expect(successState?.contacts != null, true);
      expect(successState?.contacts.isEmpty, false);

      expect(
        contactsManager.getContactsNotifier().value,
        Right(GetContactsSuccess(contacts: tomContacts)),
      );

      final phonebookSuccessState = contactsManager
          .getPhonebookContactsNotifier()
          .value
          .getSuccessOrNull<GetPhonebookContactsSuccess>();

      expect(phonebookSuccessState?.contacts != null, true);
      expect(phonebookSuccessState?.contacts.isEmpty, true);

      expect(
        contactsManager.getPhonebookContactsNotifier().value,
        const Right(GetPhonebookContactsSuccess(contacts: [])),
      );
    });

    test(
        'Request contacts is granted && TomContact is not empty && Phonebook isNotEmpty',
        () async {
      contactsManager = getIt.get<ContactsManager>();

      mockGetTomContactsInteractor = getIt.get<MockGetTomContactsInteractor>();

      mockPhonebookContactInteractor =
          getIt.get<MockPhonebookContactInteractor>();

      when(
        mockGetTomContactsInteractor.execute(
          limit: AppConfig.maxFetchContacts,
        ),
      ).thenAnswer(
        (_) async* {
          yield const Right(ContactsLoading());
          yield Right(GetContactsSuccess(contacts: tomContacts));
        },
      );

      when(
        mockPhonebookContactInteractor.execute(),
      ).thenAnswer(
        (_) async* {
          yield const Right(GetPhonebookContactsLoading(progress: 0));
          yield Right(GetPhonebookContactsSuccess(contacts: phonebookContacts));
        },
      );

      expect(
        contactsManager.getContactsNotifier().value,
        const Right(ContactsInitial()),
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
      );

      await mockGetTomContactsInteractor
          .execute(limit: AppConfig.maxFetchContacts)
          .forEach(
            (event) => contactsManager.setContactsNotifier(event),
          )
          .whenComplete(() async {
        expect(
          contactsManager.getPhonebookContactsNotifier().value,
          const Right(GetPhonebookContactsInitial()),
        );
        await mockPhonebookContactInteractor.execute().forEach(
              (event) => contactsManager.setPhonebookContactsNotifier(event),
            );
      });

      final successState = contactsManager
          .getContactsNotifier()
          .value
          .getSuccessOrNull<GetContactsSuccess>();

      expect(successState?.contacts != null, true);
      expect(successState?.contacts.isEmpty, false);

      expect(
        contactsManager.getContactsNotifier().value,
        Right(GetContactsSuccess(contacts: tomContacts)),
      );

      final phonebookSuccessState = contactsManager
          .getPhonebookContactsNotifier()
          .value
          .getSuccessOrNull<GetPhonebookContactsSuccess>();

      expect(phonebookSuccessState?.contacts != null, true);
      expect(phonebookSuccessState?.contacts.isEmpty, false);

      expect(
        contactsManager.getPhonebookContactsNotifier().value,
        Right(GetPhonebookContactsSuccess(contacts: phonebookContacts)),
      );
    });
  });
}
