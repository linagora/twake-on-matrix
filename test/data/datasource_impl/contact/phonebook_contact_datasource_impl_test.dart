import 'package:fluffychat/data/datasource/contact/contacts_provider.dart';
import 'package:fluffychat/data/datasource/contact/sim_country/sim_country_provider.dart';
import 'package:fluffychat/data/datasource_impl/contact/phonebook_contact_datasource_impl.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contact;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'phonebook_contact_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ContactsProvider>(),
  MockSpec<SimCountryProvider>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PhonebookContactDatasourceImpl dataSource;
  late MockContactsProvider mockContactsProvider;
  late MockSimCountryProvider mockSimCountryProvider;

  group('[PhonebookContactDatasourceV2Impl] test\n', () {
    final listAllContacts = [
      const flutter_contact.Contact(
        id: 'id_1',
        displayName: 'Alice',
        phones: [
          flutter_contact.Phone(number: '(212)555-6789'),
          flutter_contact.Phone(number: '2125556789'),
        ],
        emails: [
          flutter_contact.Email(address: 'Alice@domain.com'),
          flutter_contact.Email(address: 'Alice_1@domain.com'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_2',
        displayName: 'Bob',
        phones: [
          flutter_contact.Phone(number: '2124678190'),
          flutter_contact.Phone(number: '(212)467-8190'),
        ],
        emails: [
          flutter_contact.Email(address: 'bob@domain.com'),
          flutter_contact.Email(address: 'bob2@domain.com'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_3',
        displayName: 'Charlie',
        phones: [
          flutter_contact.Phone(number: '212 555-6789'),
          flutter_contact.Phone(number: '2125556789'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_4',
        displayName: 'David',
        phones: [
          flutter_contact.Phone(number: '2124678190'),
          flutter_contact.Phone(number: '212 467-8190'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_5',
        displayName: 'Eve',
        phones: [
          flutter_contact.Phone(number: '+1.123.456.7890'),
          flutter_contact.Phone(number: '11234567890'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_6',
        displayName: 'Frank',
        phones: [
          flutter_contact.Phone(number: '81234977890'),
          flutter_contact.Phone(number: '+8.123.497.7890'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_7',
        displayName: 'Grace',
        phones: [
          flutter_contact.Phone(number: '+1 (800)-555-1234 ext. 123'),
          flutter_contact.Phone(number: '18005551234123'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_8',
        displayName: 'Hank',
        phones: [
          flutter_contact.Phone(number: '18005879106234'),
          flutter_contact.Phone(number: '+1 (800)-587-9106 ext. 234'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_9',
        displayName: 'Ivy',
        phones: [
          flutter_contact.Phone(number: '+1 (800)-555.1234'),
          flutter_contact.Phone(number: '18005551234'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_10',
        displayName: 'Karl',
        phones: [
          flutter_contact.Phone(number: '18005873456'),
          flutter_contact.Phone(number: '+1 (800)-587.3456'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_11',
        displayName: 'Liam',
        phones: [
          flutter_contact.Phone(number: '(212) 555-6789'),
          flutter_contact.Phone(number: '2125556789'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_12',
        displayName: 'Mia',
        phones: [
          flutter_contact.Phone(number: '2125556789'),
          flutter_contact.Phone(number: '(212) 555-6789'),
        ],
      ),
      const flutter_contact.Contact(
        id: 'id_13',
        displayName: 'Nina',
        emails: [
          flutter_contact.Email(address: 'nina@domain.com'),
          flutter_contact.Email(address: 'nina1@domain.com'),
          flutter_contact.Email(address: 'nina2@domain.com'),
          flutter_contact.Email(address: 'nina3@domain.com'),
        ],
      ),
      const flutter_contact.Contact(id: 'id_14', displayName: 'Nina'),
      const flutter_contact.Contact(id: 'id_15', displayName: '222'),
      const flutter_contact.Contact(id: 'id_16', displayName: '222'),
    ];

    setUp(() {
      mockContactsProvider = MockContactsProvider();
      mockSimCountryProvider = MockSimCountryProvider();
      when(
        mockSimCountryProvider.getCountryCode(),
      ).thenAnswer((_) async => 'US');
      final getIt = GetIt.instance;
      getIt.allowReassignment = true;
      getIt.registerFactory<ContactsProvider>(() => mockContactsProvider);
      getIt.registerFactory<SimCountryProvider>(() => mockSimCountryProvider);
      getIt.registerFactory<PhonebookContactDatasourceImpl>(
        () => PhonebookContactDatasourceImpl(
          getIt.get<ContactsProvider>(),
          getIt.get<SimCountryProvider>(),
        ),
      );
      dataSource = getIt.get<PhonebookContactDatasourceImpl>();

      when(
        mockContactsProvider.getAll(properties: anyNamed('properties')),
      ).thenAnswer((_) async => listAllContacts);
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test(
      'Give a list of phonebook contacts'
      'When fetchContacts is called'
      'Then it should return a list of contacts with phone numbers normalized to E.164'
      'Then it should return a list of contacts without duplicated phone number and email'
      'Then it should filter contacts whose phone numbers cannot be resolved to a valid E.164',
      () async {
        // Phone numbers are now normalized to E.164 via phone_numbers_parser (callerIsoCode = 'US').
        // Numbers that cannot be resolved to a valid E.164 are silently dropped:
        //   - Eve (id_5): area code 123 is not a real US area code → both numbers rejected.
        //   - Grace (id_7): ext. notation not supported → both numbers rejected.
        //   - Hank (id_8): ext. notation + too many digits → both numbers rejected.
        // Frank (id_6): '81234977890' → pnp resolves as +81 (Japan) + 234977890.
        final List<Contact> expectedListContact = [
          Contact(
            id: 'id_1',
            displayName: 'Alice',
            phoneNumbers: {PhoneNumber(number: '+12125556789')},
            emails: {
              Email(address: 'Alice@domain.com'),
              Email(address: 'Alice_1@domain.com'),
            },
          ),
          Contact(
            id: 'id_2',
            displayName: 'Bob',
            phoneNumbers: {PhoneNumber(number: '+12124678190')},
            emails: {
              Email(address: 'bob@domain.com'),
              Email(address: 'bob2@domain.com'),
            },
          ),
          Contact(
            id: 'id_3',
            displayName: 'Charlie',
            phoneNumbers: {PhoneNumber(number: '+12125556789')},
            emails: const {},
          ),
          Contact(
            id: 'id_4',
            displayName: 'David',
            phoneNumbers: {PhoneNumber(number: '+12124678190')},
            emails: const {},
          ),
          Contact(
            id: 'id_6',
            displayName: 'Frank',
            phoneNumbers: {PhoneNumber(number: '+81234977890')},
            emails: const {},
          ),
          Contact(
            id: 'id_9',
            displayName: 'Ivy',
            phoneNumbers: {PhoneNumber(number: '+18005551234')},
            emails: const {},
          ),
          Contact(
            id: 'id_10',
            displayName: 'Karl',
            phoneNumbers: {PhoneNumber(number: '+18005873456')},
            emails: const {},
          ),
          Contact(
            id: 'id_11',
            displayName: 'Liam',
            phoneNumbers: {PhoneNumber(number: '+12125556789')},
            emails: const {},
          ),
          Contact(
            id: 'id_12',
            displayName: 'Mia',
            phoneNumbers: {PhoneNumber(number: '+12125556789')},
            emails: const {},
          ),
          Contact(
            id: 'id_13',
            displayName: 'Nina',
            phoneNumbers: const {},
            emails: {
              Email(address: 'nina@domain.com'),
              Email(address: 'nina1@domain.com'),
              Email(address: 'nina2@domain.com'),
              Email(address: 'nina3@domain.com'),
            },
          ),
        ];

        final result = await dataSource.fetchContacts();

        expect(result, isA<List<Contact>>());
        expect(result, equals(expectedListContact));
      },
    );
  });
}
