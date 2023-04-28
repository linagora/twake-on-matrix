import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';

abstract class TomContactsDatasource {
  Future<Set<Contact>> searchContacts({required ContactQuery query});

  Future<Set<Contact>> fetchContacts();
}