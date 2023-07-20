import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';

abstract class TomContactsDatasource {
  Future<List<Contact>> searchContacts(
      {required ContactQuery query, int? limit, int? offset});
}
