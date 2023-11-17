import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/identity_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';

class LookupAPI {
  final DioClient _client =
      getIt.get<DioClient>(instanceName: NetworkDI.identityDioClientName);

  Future<HashDetailsResponse> getHashDetails() async {
    final path = IdentityEndpoint.hashDetailsServicePath
        .generateMatrixIdentityEndpoint();
    final response = await _client.get(path);
    return HashDetailsResponse.fromJson(response);
  }

  Future<LookupListMxidResponse> lookupListMxid(
    LookupListMxidRequest request,
  ) async {
    final response = await _client.postToGetBody(
      IdentityEndpoint.matchListUserIdsServicePath
          .generateMatrixIdentityEndpoint(),
      data: request.toJson(),
    );
    return LookupListMxidResponse.fromJson(response);
  }
}
