import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/contact/lookup_mxid_request.dart';

abstract class ContactRepository {
  Future<List<Contact>> fetchContacts({
    required ContactQuery query,
    int? limit,
    int? offset,
  });

  Future<List<Contact>> lookupMatchContact({
    required ContactQuery query,
    LookupMxidRequest lookupMxidRequest,
  });
}
