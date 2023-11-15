import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';

abstract class ContactRepository {
  Stream<List<Contact>> fetchContacts({
    required ContactQuery query,
    int? limit,
    int? offset,
  });
}
