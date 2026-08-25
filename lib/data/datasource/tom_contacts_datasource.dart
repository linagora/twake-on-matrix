import 'package:twake_chat/domain/model/contact/contact.dart';
import 'package:twake_chat/domain/model/contact/contact_query.dart';
import 'package:twake_chat/domain/model/contact/lookup_mxid_request.dart';

abstract class TomContactsDatasource {
  Future<List<Contact>> fetchContacts({
    required ContactQuery query,
    int? limit,
    int? offset,
    LookupMxidRequest? lookupMxidRequest,
  });
}
