import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/datasource_impl/federation_identity_lookup_datasource_impl.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/network/federation_identity_endpoint.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/network/federation_identity_lookup_api.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/repository_impl/federation_identity_lookup_repository_impl.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';
import 'package:flutter/foundation.dart';

class IdentityLookupManager {
  DioClient _bindingDio({required String federationUrl}) {
    final headers = {
      HttpHeaders.acceptHeader: FederationIdentityEndpoint.acceptHeaderDefault,
      HttpHeaders.contentTypeHeader:
          FederationIdentityEndpoint.contentTypeHeaderDefault,
    };

    final dio = Dio(BaseOptions(baseUrl: federationUrl, headers: headers));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return DioClient(dio);
  }

  FederationIdentityLookupApi _bindingAPI(DioClient dio) {
    return FederationIdentityLookupApi(dio);
  }

  FederationIdentityLookupDatasourceImpl _bindingDataSourceImpl(
    FederationIdentityLookupApi federationIdentityLookupApi,
  ) {
    return FederationIdentityLookupDatasourceImpl(
      federationIdentityLookupApi: federationIdentityLookupApi,
    );
  }

  FederationIdentityLookupRepositoryImpl _bindingRepositoryImpl(
    FederationIdentityLookupDatasourceImpl datasource,
  ) {
    return FederationIdentityLookupRepositoryImpl(datasource: datasource);
  }

  Future<FederationRegisterResponse> register({
    required String federationUrl,
    required FederationTokenInformation tokenInformation,
  }) {
    final dio = _bindingDio(federationUrl: federationUrl);
    final api = _bindingAPI(dio);
    final datasource = _bindingDataSourceImpl(api);
    final repository = _bindingRepositoryImpl(datasource);
    return repository.register(tokenInformation: tokenInformation);
  }

  Future<FederationHashDetailsResponse> getHashDetails({
    required String federationUrl,
    required String registeredToken,
  }) {
    final dio = _bindingDio(federationUrl: federationUrl);
    final api = _bindingAPI(dio);
    final datasource = _bindingDataSourceImpl(api);
    final repository = _bindingRepositoryImpl(datasource);
    return repository.getHashDetails(registeredToken: registeredToken);
  }

  Future<FederationLookupMxidResponse> lookupMxid({
    required String federationUrl,
    required FederationLookupMxidRequest request,
    required String registeredToken,
  }) {
    final dio = _bindingDio(federationUrl: federationUrl);
    final api = _bindingAPI(dio);
    final datasource = _bindingDataSourceImpl(api);
    final repository = _bindingRepositoryImpl(datasource);
    return repository.lookupMxid(
      request: request,
      registeredToken: registeredToken,
    );
  }
}
