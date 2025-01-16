import 'package:fluffychat/domain/model/contact/contact_v2.dart';

abstract class PhonebookContactRepositoryV2 {
  Future<List<Contact>> fetchContacts();
}
