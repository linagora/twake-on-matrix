import 'package:fluffychat/domain/model/contact/contact.dart';

abstract class HiveContactRepository {
  Future<List<Contact>> getThirdPartyContactByUserId(String userId);

  Future<void> saveThirdPartyContactsForUser(
    String userId,
    List<Contact> contacts,
  );

  Future<void> deleteThirdPartyContactBox();
}
