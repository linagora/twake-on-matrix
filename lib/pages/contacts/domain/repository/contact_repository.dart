import 'package:fluffychat/entity/contact/contact.dart';

abstract class ContactRepository {
  Future<Set<Contact>> getContacts();
}