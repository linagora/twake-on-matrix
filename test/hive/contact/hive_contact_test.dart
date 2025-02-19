import 'package:fluffychat/data/datasource/contact/hive_third_party_contact_datasource.dart';
import 'package:fluffychat/data/datasource_impl/contact/hive_third_party_contact_datasource_impl.dart';
import 'package:fluffychat/data/hive/dto/contact/contact_hive_obj.dart';
import 'package:fluffychat/data/hive/dto/contact/third_party_contact_hive_obj.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/data/repository/contact/hive_third_party_contact_repository_impl.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
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
      final hiveCollectionToMDatabase =
          await getIt.getAsync<HiveCollectionToMDatabase>();
      await hiveCollectionToMDatabase.clear();
    });

    test(
      'Give a contact\n'
      'When store contact is called\n'
      'Then the contact is stored in the database',
      () async {
        final repository = getIt.get<HiveThirdPartyContactDatasource>();
        await repository.saveThirdPartyContactsForUser(
          '12345678910',
          [
            ContactHiveObj(
              id: 'id_1',
              displayName: 'Alice',
              phoneNumbers: {
                PhoneNumberHiveObject(
                  number: '(212)555-6789',
                  matrixId: '@david:matrix.org',
                ),
              },
              emails: {
                EmailHiveObject(
                  email: 'david@gmail.com',
                  matrixId: '@david:matrix.org',
                ),
              },
            ),
          ],
        );

        final contacts =
            await repository.getThirdPartyContactByUserId('12345678910');

        expect(contacts.isNotEmpty, true);

        expect(
          contacts.where((contact) => contact.id == 'id_1').isNotEmpty,
          true,
        );
      },
    );

    test(
      'Give list contact\n'
      'When store list contact is called\n'
      'Then all contact is stored in the database',
      () async {
        final repository = getIt.get<HiveThirdPartyContactDatasource>();
        await repository.saveThirdPartyContactsForUser(
          '12345678910',
          [
            ContactHiveObj(
              id: 'id_1',
              displayName: 'Alice',
              phoneNumbers: {
                PhoneNumberHiveObject(
                  number: '(212)555-6789',
                  matrixId: '@david:matrix.org',
                ),
              },
              emails: {
                EmailHiveObject(
                  email: 'david@gmail.com',
                  matrixId: '@david.x:matrix.org',
                ),
              },
            ),
            ContactHiveObj(
              id: 'id_2',
              displayName: 'Bob',
              phoneNumbers: {
                PhoneNumberHiveObject(
                  number: '(212)444-6789',
                  matrixId: '@bob:matrix.org',
                ),
              },
              emails: {
                EmailHiveObject(
                  email: 'bob@gmail.com',
                  matrixId: '@bob2:matrix.org',
                ),
              },
            ),
            ContactHiveObj(
              id: 'id_3',
              displayName: 'Charlie',
              phoneNumbers: {
                PhoneNumberHiveObject(
                  number: '(212)333-6789',
                  matrixId: '@charlie:matrix.org',
                ),
              },
              emails: {
                EmailHiveObject(
                  email: 'Charlie@gmail.com',
                  matrixId: '@charliex:matrix.org',
                ),
              },
            ),
          ],
        );

        final contacts =
            await repository.getThirdPartyContactByUserId('12345678910');

        expect(contacts.length == 3, true);

        expect(
          contacts.where((contact) => contact.id == 'id_1').isNotEmpty,
          true,
        );

        expect(
          contacts.where((contact) => contact.id == 'id_2').isNotEmpty,
          true,
        );

        expect(
          contacts.where((contact) => contact.id == 'id_3').isNotEmpty,
          true,
        );
      },
    );

    test(
      'Give list contact have 2 contact duplicated\n'
      'When store contact is called\n'
      'Then only one contact is stored in the database',
      () async {
        final repository = getIt.get<HiveThirdPartyContactDatasource>();
        await repository.saveThirdPartyContactsForUser(
          '12345678910',
          [
            ContactHiveObj(
              id: 'id_11',
              displayName: 'Alice',
              phoneNumbers: {
                PhoneNumberHiveObject(
                  number: '(212)555-6789',
                  matrixId: '@david:matrix.org',
                ),
              },
              emails: {
                EmailHiveObject(
                  email: 'david@gmail.com',
                  matrixId: '@david:matrix.org',
                ),
              },
            ),
            ContactHiveObj(
              id: 'id_11',
              displayName: 'Alice',
              phoneNumbers: {
                PhoneNumberHiveObject(
                  number: '(212)555-6789',
                  matrixId: '@david:matrix.org',
                ),
              },
              emails: {
                EmailHiveObject(
                  email: 'david@gmail.com',
                  matrixId: '@david:matrix.org',
                ),
              },
            ),
          ],
        );

        final contacts =
            await repository.getThirdPartyContactByUserId('12345678910');

        expect(contacts.isNotEmpty, true);

        expect(contacts.length == 1, true);

        expect(
          contacts.where((contact) => contact.id == 'id_11').length,
          1,
        );
      },
    );

    test(
      'Give a contact with id is id_1\n'
      'When the user existed in the database\n'
      'AND store users is called\n'
      'Then cannot store the user in the database',
      () async {
        final repository = getIt.get<HiveThirdPartyContactDatasource>();

        final getContactInitial =
            await repository.getThirdPartyContactByUserId('12345678910');

        expect(getContactInitial.length, 0);

        await repository.saveThirdPartyContactsForUser(
          '12345678910',
          [
            ContactHiveObj(
              id: 'id_1',
              displayName: 'Alice',
              phoneNumbers: {
                PhoneNumberHiveObject(
                  number: '(212)555-6789',
                  matrixId: '@david:matrix.org',
                ),
              },
              emails: {
                EmailHiveObject(
                  email: 'david@gmail.com',
                  matrixId: '@david:matrix.org',
                ),
              },
            ),
          ],
        );

        final contacts =
            await repository.getThirdPartyContactByUserId('12345678910');

        expect(contacts.isNotEmpty, true);

        expect(
          contacts.where((contact) => contact.id == 'id_1').isNotEmpty,
          true,
        );

        await repository.saveThirdPartyContactsForUser(
          '12345678910',
          [
            ContactHiveObj(
              id: 'id_1',
              displayName: 'Alice',
              phoneNumbers: {
                PhoneNumberHiveObject(
                  number: '(212)555-6789',
                  matrixId: '@david:matrix.org',
                ),
              },
              emails: {
                EmailHiveObject(
                  email: 'david@gmail.com',
                  matrixId: '@david:matrix.org',
                ),
              },
            ),
          ],
        );

        final finalContact =
            await repository.getThirdPartyContactByUserId('12345678910');

        expect(finalContact.isNotEmpty, true);

        expect(
          finalContact.where((contact) => contact.id == 'id_1').isNotEmpty,
          true,
        );
      },
    );
  });
}
