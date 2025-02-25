import 'package:fluffychat/data/datasource/contact/hive_third_party_contact_datasource.dart';
import 'package:fluffychat/data/hive/dto/contact/contact_hive_obj.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/contact/hive_contact_repository.dart';

class HiveThirdPartyContactRepositoryImpl implements HiveContactRepository {
  final HiveThirdPartyContactDatasource datasource =
      getIt.get<HiveThirdPartyContactDatasource>();

  @override
  Future<List<ContactHiveObj>> getThirdPartyContactByUserId(String userId) {
    return datasource.getThirdPartyContactByUserId(userId);
  }

  @override
  Future<void> saveThirdPartyContactsForUser(
    String userId,
    List<ContactHiveObj> contacts,
  ) {
    return datasource.saveThirdPartyContactsForUser(userId, contacts);
  }

  @override
  Future<void> deleteThirdPartyContactBox() {
    return datasource.deleteThirdPartyContactBox();
  }
}
