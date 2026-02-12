import 'package:fluffychat/data/datasource/contact/hive_third_party_contact_datasource.dart';
import 'package:fluffychat/data/hive/dto/contact/contact_hive_obj.dart';
import 'package:fluffychat/data/hive/extension/contact_hive_obj_extension.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/utils/copy_map.dart';
import 'package:matrix/matrix.dart' hide Contact;

class HiveThirdPartyContactDatasourceImpl
    extends HiveThirdPartyContactDatasource {
  @override
  Future<List<Contact>> getThirdPartyContactByUserId(String userId) async {
    final updateContacts = <Contact>[];
    final hiveCollectionFederationDatabase = await getIt
        .getAsync<HiveCollectionToMDatabase>();
    final keys =
        (await hiveCollectionFederationDatabase.thirdPartyContactsBox
                .getAllKeys())
            .where((key) => TupleKey.fromString(key).parts.first == userId)
            .toList();
    final contacts = await hiveCollectionFederationDatabase
        .thirdPartyContactsBox
        .getAll(keys);
    contacts.removeWhere((state) => state == null);
    for (final contact in contacts) {
      updateContacts.add(
        ContactHiveObj.fromJson(copyMap(contact!)).toContact(),
      );
    }

    return updateContacts;
  }

  @override
  Future<void> saveThirdPartyContactsForUser(
    String userId,
    List<Contact> contacts,
  ) async {
    final hiveCollectionFederationDatabase = await getIt
        .getAsync<HiveCollectionToMDatabase>();

    for (final contact in contacts) {
      final key = TupleKey(userId, contact.id).toString();

      await hiveCollectionFederationDatabase.thirdPartyContactsBox.put(
        key,
        contact.toHiveObj().toJson(),
      );
    }
    return;
  }

  @override
  Future<void> deleteThirdPartyContactBox() {
    final hiveCollectionFederationDatabase = getIt
        .get<HiveCollectionToMDatabase>();
    return hiveCollectionFederationDatabase.thirdPartyContactsBox.clear();
  }
}
