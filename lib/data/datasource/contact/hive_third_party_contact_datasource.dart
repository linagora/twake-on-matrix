import 'package:fluffychat/data/hive/dto/contact/contact_hive_obj.dart';

abstract class HiveThirdPartyContactDatasource {
  Future<List<ContactHiveObj>> getThirdPartyContactByUserId(String userId);

  Future<void> saveThirdPartyContactsForUser(
    String userId,
    List<ContactHiveObj> contacts,
  );

  Future<void> deleteThirdPartyContactBox();
}
