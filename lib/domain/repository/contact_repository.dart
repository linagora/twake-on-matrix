import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';

abstract class ContactRepository {
  Future<Set<Contact>> searchContact({required ContactQuery query});

  Future<Set<Contact>> fetchContacts();
}