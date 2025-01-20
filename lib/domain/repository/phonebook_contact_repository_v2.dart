import 'package:fluffychat/domain/model/contact/contact_new.dart';

abstract class PhonebookContactRepositoryV2 {
  Future<List<Contact>> fetchContacts();
}
