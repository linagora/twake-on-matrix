import 'package:twake_chat/domain/model/contact/contact.dart';

abstract class PhonebookContactDatasource {
  Future<List<Contact>> fetchContacts();
}
