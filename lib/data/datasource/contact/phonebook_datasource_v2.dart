import 'package:fluffychat/domain/model/contact/contact_v2.dart';

abstract class PhonebookContactDatasourceV2 {
  Future<List<Contact>> fetchContacts();
}
