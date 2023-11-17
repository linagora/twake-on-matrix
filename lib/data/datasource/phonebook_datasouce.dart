import 'package:fluffychat/domain/model/contact/contact.dart';

abstract class PhonebookContactDatasource {
  Future<List<Contact>> fetchContacts();
}
