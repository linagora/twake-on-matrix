import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';

abstract class LookupRepository {
  Future<HashDetailsResponse> getHashDetails();

  Future<LookupListMxidResponse> lookupListMxid(
    LookupListMxidRequest request,
  );
}
