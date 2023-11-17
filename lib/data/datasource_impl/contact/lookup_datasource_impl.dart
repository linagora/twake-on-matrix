import 'package:fluffychat/data/datasource/lookup_datasource.dart';
import 'package:fluffychat/data/network/contact/lookup_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';

class LookupDatasourceImpl implements LookupDatasource {
  final LookupAPI _lookupAPI = getIt.get<LookupAPI>();

  @override
  Future<HashDetailsResponse> getHashDetails() {
    return _lookupAPI.getHashDetails();
  }

  @override
  Future<LookupListMxidResponse> lookupListMxid(
    LookupListMxidRequest request,
  ) async {
    return _lookupAPI.lookupListMxid(request);
  }
}
