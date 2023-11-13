import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/identity_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_mxid_response.dart';

class TomContactAPI {
  final DioClient _client =
      getIt.get<DioClient>(instanceName: NetworkDI.tomDioClientName);

  TomContactAPI();

  Future<LookupMxidResponse> fetchContacts(
    ContactQuery query, {
    int? limit,
    int? offset,
  }) async {
    final requestBody = LookupMxidRequest(
      scope: ['mail', 'uid', 'mobile', 'cn', 'displayName'],
      fields: ['uid', 'mobile', 'mail', 'cn', 'displayName'],
      val: query.keyword,
      limit: limit,
      offset: offset,
    );

    final response = await _client
        .postToGetBody(
          IdentityEndpoint.matchUserIdServicePath
              .generateTwakeIdentityEndpoint(),
          data: requestBody.toJson(),
        )
        .onError((error, stackTrace) => throw Exception(error));

    return LookupMxidResponse.fromJson(response);
  }

  Future<HashDetailsResponse> getHashDetails() async {
    final response = await _client.postToGetBody(
      IdentityEndpoint.hashDetailsServicePath.generateMatrixIdentityEndpoint(),
    );
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
