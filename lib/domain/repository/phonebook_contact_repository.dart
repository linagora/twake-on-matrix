import 'package:fluffychat/domain/model/contact/contact.dart';

abstract class PhonebookContactRepository {
  Future<List<Contact>> fetchContacts();
}
