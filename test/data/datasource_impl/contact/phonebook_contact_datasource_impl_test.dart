import 'package:fluffychat/data/datasource_impl/contact/phonebook_contact_datasource_impl.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PhonebookContactDatasourceImpl dataSource;
  const MethodChannel channel =
      MethodChannel('github.com/QuisApp/flutter_contacts');

  group('[PhonebookContactDatasourceV2Impl] test\n', () {
    final listAllContacts = [
      {
        'id': 'id_1',
        'displayName': 'Alice',
        'phones': [
          {'number': '(212)555-6789'},
          {'number': '2125556789'},
        ],
        'emails': [
          {
            'address': 'Alice@domain.com',
          },
          {
            'address': 'Alice_1@domain.com',
          },
        ],
      },
      {
        'id': 'id_2',
        'displayName': 'Bob',
        'phones': [
          {'number': '2124678190'},
          {'number': '(212)467-8190'},
        ],
        'emails': [
          {
            'address': 'bob@domain.com',
          },
          {
            'address': 'bob2@domain.com',
          }
        ],
      },
      {
        'id': 'id_3',
        'displayName': 'Charlie',
        'phones': [
          {'number': '212 555-6789'},
          {'number': '2125556789'},
        ],
      },
      {
        'id': 'id_4',
        'displayName': 'David',
        'phones': [
          {'number': '2124678190'},
          {'number': '212 467-8190'},
        ],
      },
      {
        'id': 'id_5',
        'displayName': 'Eve',
        'phones': [
          {'number': '+1.123.456.7890'},
          {'number': '11234567890'},
        ],
      },
      {
        'id': 'id_6',
        'displayName': 'Frank',
        'phones': [
          {'number': '81234977890'},
          {'number': '+8.123.497.7890'},
        ],
      },
      {
        'id': 'id_7',
        'displayName': 'Grace',
        'phones': [
          {'number': '+1 (800)-555-1234 ext. 123'},
          {'number': '18005551234123'},
        ],
      },
      {
        'id': 'id_8',
        'displayName': 'Hank',
        'phones': [
          {'number': '18005879106234'},
          {'number': '+1 (800)-587-9106 ext. 234'},
        ],
      },
      {
        'id': 'id_9',
        'displayName': 'Ivy',
        'phones': [
          {'number': '+1 (800)-555.1234'},
          {'number': '18005551234'},
        ],
      },
      {
        'id': 'id_10',
        'displayName': 'Karl',
        'phones': [
          {'number': '18005873456'},
          {'number': '+1 (800)-587.3456'},
        ],
      },
      {
        'id': 'id_11',
        'displayName': 'Liam',
        'phones': [
          {'number': '(212) 555-6789'},
          {'number': '2125556789'},
        ],
      },
      {
        'id': 'id_12',
        'displayName': 'Mia',
        'phones': [
          {'number': '2125556789'},
          {'number': '(212) 555-6789'},
        ],
      },
      {
        'id': 'id_13',
        'displayName': 'Nina',
        'emails': [
          {
            'address': 'nina@domain.com',
          },
          {
            'address': 'nina1@domain.com',
          },
          {
            'address': 'nina2@domain.com',
          },
          {
            'address': 'nina3@domain.com',
          }
        ],
      }
    ];

    setUp(() {
      final getIt = GetIt.instance;
      getIt.registerFactory(
        () => PhonebookContactDatasourceImpl(),
      );
      dataSource = getIt.get<PhonebookContactDatasourceImpl>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'select') {
          return listAllContacts;
        }
        return null;
      });
    });

    test(
        'Give a list of phonebook contacts'
        'When fetchContacts is called'
        'Then it should return a list of contacts without duplicated phone number',
        () async {
      final List<Contact> expectedListContact = [
        Contact(
          id: 'id_1',
          displayName: 'Alice',
          phoneNumbers: {
            PhoneNumber(
              number: '(212)555-6789',
            ),
          },
          emails: {
            Email(
              address: 'Alice@domain.com',
            ),
            Email(
              address: 'Alice_1@domain.com',
            ),
          },
        ),
        Contact(
          id: 'id_2',
          displayName: 'Bob',
          phoneNumbers: {
            PhoneNumber(
              number: '2124678190',
            ),
          },
          emails: {
            Email(
              address: 'bob@domain.com',
            ),
            Email(
              address: 'bob2@domain.com',
            ),
          },
        ),
        Contact(
          id: 'id_3',
          displayName: 'Charlie',
          phoneNumbers: {
            PhoneNumber(
              number: '212 555-6789',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_4',
          displayName: 'David',
          phoneNumbers: {
            PhoneNumber(
              number: '2124678190',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_5',
          displayName: 'Eve',
          phoneNumbers: {
            PhoneNumber(
              number: '+1.123.456.7890',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_6',
          displayName: 'Frank',
          phoneNumbers: {
            PhoneNumber(
              number: '81234977890',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_7',
          displayName: 'Grace',
          phoneNumbers: {
            PhoneNumber(
              number: '+1 (800)-555-1234 ext. 123',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_8',
          displayName: 'Hank',
          phoneNumbers: {
            PhoneNumber(
              number: '18005879106234',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_9',
          displayName: 'Ivy',
          phoneNumbers: {
            PhoneNumber(
              number: '+1 (800)-555.1234',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_10',
          displayName: 'Karl',
          phoneNumbers: {
            PhoneNumber(
              number: '18005873456',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_11',
          displayName: 'Liam',
          phoneNumbers: {
            PhoneNumber(
              number: '(212) 555-6789',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_12',
          displayName: 'Mia',
          phoneNumbers: {
            PhoneNumber(
              number: '2125556789',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_13',
          displayName: 'Nina',
          phoneNumbers: const {},
          emails: {
            Email(
              address: 'nina@domain.com',
            ),
            Email(
              address: 'nina1@domain.com',
            ),
            Email(
              address: 'nina2@domain.com',
            ),
            Email(
              address: 'nina3@domain.com',
            ),
          },
        ),
      ];

      final result = await dataSource.fetchContacts();

      expect(result, isA<List<Contact>>());
      expect(result, equals(expectedListContact));
    });
  });
}
