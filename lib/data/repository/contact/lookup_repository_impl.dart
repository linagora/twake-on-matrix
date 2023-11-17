import 'package:fluffychat/data/datasource/lookup_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';
import 'package:fluffychat/domain/repository/lookup_repository.dart';

class LookupRepositoryImpl implements LookupRepository {
  final LookupDatasource datasource = getIt.get<LookupDatasource>();

  @override
  Future<HashDetailsResponse> getHashDetails() {
    return datasource.getHashDetails();
  }

  @override
  Future<LookupListMxidResponse> lookupListMxid(LookupListMxidRequest request) {
    return datasource.lookupListMxid(request);
  }
}
