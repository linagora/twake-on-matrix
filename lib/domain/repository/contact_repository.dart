import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';

abstract class ContactRepository {
  Stream<List<Contact>> fetchContacts({
    required ContactQuery query,
    int? limit,
    int? offset,
  });

  Future<HashDetailsResponse> getHashDetails();

  Future<LookupListMxidResponse> lookupListMxid(
    LookupListMxidRequest request,
  );
}
