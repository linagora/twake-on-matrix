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

  group('[PhonebookContactDatasourceImpl]', () {
    final listAllContacts = [
      {
        'displayName': 'Alice',
        'phones': [
          {'number': '(212)555-6789'},
          {'number': '2125556789'},
        ],
      },
      {
        'displayName': 'Bob',
        'phones': [
          {'number': '2124678190'},
          {'number': '(212)467-8190'},
        ],
      },
      {
        'displayName': 'Charlie',
        'phones': [
          {'number': '212 555-6789'},
          {'number': '2125556789'},
        ],
      },
      {
        'displayName': 'David',
        'phones': [
          {'number': '2124678190'},
          {'number': '212 467-8190'},
        ],
      },
      {
        'displayName': 'Eve',
        'phones': [
          {'number': '+1.123.456.7890'},
          {'number': '11234567890'},
        ],
      },
      {
        'displayName': 'Frank',
        'phones': [
          {'number': '81234977890'},
          {'number': '+8.123.497.7890'},
        ],
      },
      {
        'displayName': 'Grace',
        'phones': [
          {'number': '+1 (800)-555-1234 ext. 123'},
          {'number': '18005551234123'},
        ],
      },
      {
        'displayName': 'Hank',
        'phones': [
          {'number': '18005879106234'},
          {'number': '+1 (800)-587-9106 ext. 234'},
        ],
      },
      {
        'displayName': 'Ivy',
        'phones': [
          {'number': '+1 (800)-555.1234'},
          {'number': '18005551234'},
        ],
      },
      {
        'displayName': 'Karl',
        'phones': [
          {'number': '18005873456'},
          {'number': '+1 (800)-587.3456'},
        ],
      },
      {
        'displayName': 'Liam',
        'phones': [
          {'number': '(212) 555-6789'},
          {'number': '2125556789'},
        ],
      },
      {
        'displayName': 'Mia',
        'phones': [
          {'number': '2125556789'},
          {'number': '(212) 555-6789'},
        ],
      },
      {
        'displayName': 'Nina',
        'emails': [
          {
            'address': 'nina@domain.com',
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
        'fetchContacts should return a list of contacts without duplicated phone number',
        () async {
      final List<Contact> expectedListContact = [
        const Contact(
          displayName: 'Alice',
          phoneNumber: '(212)555-6789',
        ),
        const Contact(
          displayName: 'Bob',
          phoneNumber: '2124678190',
        ),
        const Contact(
          displayName: 'Charlie',
          phoneNumber: '212 555-6789',
        ),
        const Contact(
          displayName: 'David',
          phoneNumber: '2124678190',
        ),
        const Contact(
          displayName: 'Eve',
          phoneNumber: '+1.123.456.7890',
        ),
        const Contact(
          displayName: 'Frank',
          phoneNumber: '81234977890',
        ),
        const Contact(
          displayName: 'Grace',
          phoneNumber: '+1 (800)-555-1234 ext. 123',
        ),
        const Contact(
          displayName: 'Hank',
          phoneNumber: '18005879106234',
        ),
        const Contact(
          displayName: 'Ivy',
          phoneNumber: '+1 (800)-555.1234',
        ),
        const Contact(
          displayName: 'Karl',
          phoneNumber: '18005873456',
        ),
        const Contact(
          displayName: 'Liam',
          phoneNumber: '(212) 555-6789',
        ),
        const Contact(
          displayName: 'Mia',
          phoneNumber: '2125556789',
        ),
        const Contact(
          displayName: 'Nina',
          email: 'nina@domain.com',
        ),
      ];

      final result = await dataSource.fetchContacts();

      expect(result, isA<List<Contact>>());
      expect(result, equals(expectedListContact));
    });
  });
}
