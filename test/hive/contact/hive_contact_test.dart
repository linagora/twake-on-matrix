import 'package:fluffychat/data/datasource/contact/hive_third_party_contact_datasource.dart';
import 'package:fluffychat/data/datasource_impl/contact/hive_third_party_contact_datasource_impl.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/data/repository/contact/hive_third_party_contact_repository_impl.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/repository/contact/hive_contact_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_tom_collection_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hive contact test', () {
    setUpAll(() async {
      getIt.registerLazySingletonAsync<HiveCollectionToMDatabase>(
        () => getHiveCollectionsDatabase(),
      );

      getIt.registerFactory<HiveThirdPartyContactDatasource>(
        () => HiveThirdPartyContactDatasourceImpl(),
      );

      getIt.registerFactory<HiveContactRepository>(
        () => HiveThirdPartyContactRepositoryImpl(),
      );
    });

    tearDown(() async {
      final hiveCollectionToMDatabase = await getIt
          .getAsync<HiveCollectionToMDatabase>();
      await hiveCollectionToMDatabase.clear();
    });

    test('Give a contact\n'
        'When store contact is called\n'
        'Then the contact is stored in the database', () async {
      final repository = getIt.get<HiveContactRepository>();
      final contacts = [
        Contact(
          id: 'id_1',
          displayName: 'Alice',
          phoneNumbers: {
            PhoneNumber(number: '(212)555-6789', matrixId: '@david:matrix.org'),
          },
          emails: {
            Email(address: 'david@gmail.com', matrixId: '@david:matrix.org'),
          },
        ),
      ];
      await repository.saveThirdPartyContactsForUser('12345678910', contacts);

      final hiveContacts = await repository.getThirdPartyContactByUserId(
        '12345678910',
      );

      expect(hiveContacts.isNotEmpty, true);

      expect(hiveContacts.length, 1);

      expect(hiveContacts.first.id, contacts.first.id);

      expect(hiveContacts.first.displayName, contacts.first.displayName);

      expect(
        hiveContacts.first.phoneNumbers?.first.number,
        contacts.first.phoneNumbers?.first.number,
      );

      expect(
        hiveContacts.first.phoneNumbers?.first.matrixId,
        contacts.first.phoneNumbers?.first.matrixId,
      );

      expect(
        hiveContacts.first.emails?.first.address,
        contacts.first.emails?.first.address,
      );

      expect(
        hiveContacts.first.emails?.first.matrixId,
        contacts.first.emails?.first.matrixId,
      );
    });

    test('Give list contact\n'
        'When store list contact is called\n'
        'Then all contact is stored in the database', () async {
      final repository = getIt.get<HiveContactRepository>();
      final contacts = [
        Contact(
          id: 'id_1',
          displayName: 'Alice',
          phoneNumbers: {
            PhoneNumber(number: '(212)555-6789', matrixId: '@david:matrix.org'),
          },
          emails: {
            Email(address: 'david@gmail.com', matrixId: '@david.x:matrix.org'),
          },
        ),
        Contact(
          id: 'id_2',
          displayName: 'Bob',
          phoneNumbers: {
            PhoneNumber(number: '(212)444-6789', matrixId: '@bob:matrix.org'),
          },
          emails: {
            Email(address: 'bob@gmail.com', matrixId: '@bob2:matrix.org'),
          },
        ),
        Contact(
          id: 'id_3',
          displayName: 'Charlie',
          phoneNumbers: {
            PhoneNumber(
              number: '(212)333-6789',
              matrixId: '@charlie:matrix.org',
            ),
          },
          emails: {
            Email(
              address: 'Charlie@gmail.com',
              matrixId: '@charliex:matrix.org',
            ),
          },
        ),
      ];
      await repository.saveThirdPartyContactsForUser('12345678910', contacts);

      final hiveContacts = await repository.getThirdPartyContactByUserId(
        '12345678910',
      );

      expect(hiveContacts.length == 3, true);

      expect(hiveContacts.first.id, contacts.first.id);

      expect(hiveContacts.first.displayName, contacts.first.displayName);

      expect(
        hiveContacts.first.phoneNumbers?.first.number,
        contacts.first.phoneNumbers?.first.number,
      );

      expect(
        hiveContacts.first.phoneNumbers?.first.matrixId,
        contacts.first.phoneNumbers?.first.matrixId,
      );

      expect(
        hiveContacts.first.emails?.first.address,
        contacts.first.emails?.first.address,
      );

      expect(
        hiveContacts.first.emails?.first.matrixId,
        contacts.first.emails?.first.matrixId,
      );

      expect(hiveContacts[1].id, contacts[1].id);

      expect(hiveContacts[1].displayName, contacts[1].displayName);

      expect(
        hiveContacts[1].phoneNumbers?.first.number,
        contacts[1].phoneNumbers?.first.number,
      );

      expect(
        hiveContacts[1].phoneNumbers?.first.matrixId,
        contacts[1].phoneNumbers?.first.matrixId,
      );

      expect(
        hiveContacts[1].emails?.first.address,
        contacts[1].emails?.first.address,
      );

      expect(
        hiveContacts[1].emails?.first.matrixId,
        contacts[1].emails?.first.matrixId,
      );

      expect(hiveContacts.last.id, contacts.last.id);

      expect(hiveContacts.last.displayName, contacts.last.displayName);

      expect(
        hiveContacts.last.phoneNumbers?.first.number,
        contacts.last.phoneNumbers?.first.number,
      );

      expect(
        hiveContacts.last.phoneNumbers?.first.matrixId,
        contacts.last.phoneNumbers?.first.matrixId,
      );

      expect(
        hiveContacts.last.emails?.first.address,
        contacts.last.emails?.first.address,
      );

      expect(
        hiveContacts.last.emails?.first.matrixId,
        contacts.last.emails?.first.matrixId,
      );
    });

    test('Give list contact with multiple phone and email\n'
        'When store list contact is called\n'
        'Then all contact is stored in the database', () async {
      final repository = getIt.get<HiveContactRepository>();
      final contacts = [
        Contact(
          id: 'id_1',
          displayName: 'Alice',
          phoneNumbers: {
            PhoneNumber(number: '(212)555-6789', matrixId: '@david:matrix.org'),
            PhoneNumber(
              number: '(212)555-5555',
              matrixId: '@david2:matrix.org',
            ),
            PhoneNumber(
              number: '(212)555-5444',
              matrixId: '@david3:matrix.org',
            ),
          },
          emails: {
            Email(
              address: 'david_x@gmail.com',
              matrixId: '@david.x:matrix.org',
            ),
            Email(
              address: 'david_x1@gmail.com',
              matrixId: '@david.x1:matrix.org',
            ),
            Email(
              address: 'david_x2@gmail.com',
              matrixId: '@david.x2:matrix.org',
            ),
          },
        ),
        Contact(
          id: 'id_2',
          displayName: 'Bob',
          phoneNumbers: {
            PhoneNumber(number: '(212)444-6789', matrixId: '@bob:matrix.org'),
            PhoneNumber(number: '(212)444-1234', matrixId: '@bob1:matrix.org'),
            PhoneNumber(number: '(212)444-3214', matrixId: '@bob2:matrix.org'),
          },
          emails: {
            Email(address: 'bob_x@gmail.com', matrixId: '@bob.x:matrix.org'),
            Email(address: 'bob_x1@gmail.com', matrixId: '@bob.x1:matrix.org'),
            Email(address: 'bob_x2@gmail.com', matrixId: '@bob.x2:matrix.org'),
          },
        ),
      ];
      await repository.saveThirdPartyContactsForUser('12345678910', contacts);

      final hiveContacts = await repository.getThirdPartyContactByUserId(
        '12345678910',
      );

      expect(hiveContacts.length == 2, true);

      expect(hiveContacts.first.id, contacts.first.id);

      expect(hiveContacts.first.displayName, contacts.first.displayName);

      for (
        var index = 0;
        index < hiveContacts.first.phoneNumbers!.length;
        index++
      ) {
        expect(
          hiveContacts.first.phoneNumbers!.toList()[index].number,
          contacts.first.phoneNumbers!.toList()[index].number,
        );

        expect(
          hiveContacts.first.phoneNumbers!.toList()[index].matrixId,
          contacts.first.phoneNumbers!.toList()[index].matrixId,
        );

        expect(
          hiveContacts.first.emails!.toList()[index].address,
          contacts.first.emails!.toList()[index].address,
        );

        expect(
          hiveContacts.first.emails!.toList()[index].matrixId,
          contacts.first.emails!.toList()[index].matrixId,
        );
      }

      expect(hiveContacts.last.id, contacts.last.id);

      expect(hiveContacts.last.displayName, contacts.last.displayName);

      for (
        var index = 0;
        index < hiveContacts.last.phoneNumbers!.length;
        index++
      ) {
        expect(
          hiveContacts.last.phoneNumbers!.toList()[index].number,
          contacts.last.phoneNumbers!.toList()[index].number,
        );

        expect(
          hiveContacts.last.phoneNumbers!.toList()[index].matrixId,
          contacts.last.phoneNumbers!.toList()[index].matrixId,
        );

        expect(
          hiveContacts.last.emails!.toList()[index].address,
          contacts.last.emails!.toList()[index].address,
        );

        expect(
          hiveContacts.last.emails!.toList()[index].matrixId,
          contacts.last.emails!.toList()[index].matrixId,
        );
      }
    });

    test('Give list contact have 2 contact duplicated\n'
        'When store contact is called\n'
        'Then only one contact is stored in the database', () async {
      final repository = getIt.get<HiveContactRepository>();
      final contacts = [
        Contact(
          id: 'id_11',
          displayName: 'Alice',
          phoneNumbers: {
            PhoneNumber(number: '(212)555-6789', matrixId: '@david:matrix.org'),
          },
          emails: {
            Email(address: 'david@gmail.com', matrixId: '@david:matrix.org'),
          },
        ),
        Contact(
          id: 'id_11',
          displayName: 'Alice',
          phoneNumbers: {
            PhoneNumber(number: '(212)555-6789', matrixId: '@david:matrix.org'),
          },
          emails: {
            Email(address: 'david@gmail.com', matrixId: '@david:matrix.org'),
          },
        ),
      ];
      await repository.saveThirdPartyContactsForUser('12345678910', contacts);

      final hiveContacts = await repository.getThirdPartyContactByUserId(
        '12345678910',
      );

      expect(hiveContacts.isNotEmpty, true);

      expect(hiveContacts.length == 1, true);

      expect(hiveContacts.first.id, contacts.first.id);

      expect(hiveContacts.first.displayName, contacts.first.displayName);

      expect(
        hiveContacts.first.phoneNumbers?.first.number,
        contacts.first.phoneNumbers?.first.number,
      );

      expect(
        hiveContacts.first.phoneNumbers?.first.matrixId,
        contacts.first.phoneNumbers?.first.matrixId,
      );

      expect(
        hiveContacts.first.emails?.first.address,
        contacts.first.emails?.first.address,
      );

      expect(
        hiveContacts.first.emails?.first.matrixId,
        contacts.first.emails?.first.matrixId,
      );
    });

    test('Give a contact with id is id_1\n'
        'When the user existed in the database\n'
        'AND store users is called\n'
        'Then cannot store the user in the database', () async {
      final repository = getIt.get<HiveContactRepository>();

      final contacts = [
        Contact(
          id: 'id_1',
          displayName: 'Alice',
          phoneNumbers: {
            PhoneNumber(number: '(212)555-6789', matrixId: '@david:matrix.org'),
          },
          emails: {
            Email(address: 'david@gmail.com', matrixId: '@david:matrix.org'),
          },
        ),
      ];

      final getContactInitial = await repository.getThirdPartyContactByUserId(
        '12345678910',
      );

      expect(getContactInitial.length, 0);

      await repository.saveThirdPartyContactsForUser('12345678910', contacts);

      final hiveContacts = await repository.getThirdPartyContactByUserId(
        '12345678910',
      );

      expect(hiveContacts.isNotEmpty, true);

      expect(hiveContacts.length == 1, true);

      await repository.saveThirdPartyContactsForUser('12345678910', contacts);

      final finalContact = await repository.getThirdPartyContactByUserId(
        '12345678910',
      );

      expect(finalContact.isNotEmpty, true);

      expect(finalContact.length == 1, true);

      expect(finalContact.first.id, contacts.first.id);

      expect(finalContact.first.displayName, contacts.first.displayName);

      expect(
        finalContact.first.phoneNumbers?.first.number,
        contacts.first.phoneNumbers?.first.number,
      );

      expect(
        finalContact.first.phoneNumbers?.first.matrixId,
        contacts.first.phoneNumbers?.first.matrixId,
      );

      expect(
        finalContact.first.emails?.first.address,
        contacts.first.emails?.first.address,
      );

      expect(
        finalContact.first.emails?.first.matrixId,
        contacts.first.emails?.first.matrixId,
      );
    });
  });
}
