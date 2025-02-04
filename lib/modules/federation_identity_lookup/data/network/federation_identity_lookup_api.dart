import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/network/federation_identity_endpoint.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_indetity_request_token/domain/models/federation_token_information.dart';
import 'package:fluffychat/data/network/dio_client.dart';

class FederationIdentityLookupApi {
  final DioClient client;

  FederationIdentityLookupApi(this.client);

  Future<FederationRegisterResponse> register({
    required FederationTokenInformation tokenInformation,
  }) async {
    final path = FederationIdentityEndpoint.registerServicePath
        .generateFederationIdentityEndpoint();

    final response = await client.postToGetBody(
      path,
      data: tokenInformation.toJson(),
    );

    return FederationRegisterResponse.fromJson(response);
  }

  Future<FederationHashDetailsResponse> getHashDetails(String token) async {
    final path = FederationIdentityEndpoint.hashDetailsServicePath
        .generateFederationIdentityEndpoint();

    final dioHeaders = client.getHeaders();

    dioHeaders[HttpHeaders.authorizationHeader] = 'Bearer $token';

    final response = await client.get(
      path,
      options: Options(headers: dioHeaders),
    );

    return FederationHashDetailsResponse.fromJson(response);
  }

  Future<FederationLookupMxidResponse> lookupMxid({
    required FederationLookupMxidRequest request,
    required String token,
  }) async {
    final path = FederationIdentityEndpoint.lookupServicePath
        .generateFederationIdentityEndpoint();

    final dioHeaders = client.getHeaders();

    dioHeaders[HttpHeaders.authorizationHeader] = 'Bearer $token';

    final response = await client.postToGetBody(
      path,
      data: request.toJson(),
      options: Options(headers: dioHeaders),
    );

    return FederationLookupMxidResponse.fromJson(response);
  }
}
