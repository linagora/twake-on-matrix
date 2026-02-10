import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/modules/federation_identity_request_token/data/datasource_impl/federation_identity_request_token_datasource_impl.dart';
import 'package:fluffychat/modules/federation_identity_request_token/data/network/federation_identity_request_token_api.dart';
import 'package:fluffychat/modules/federation_identity_request_token/data/network/federation_identity_request_token_endpoint.dart';
import 'package:fluffychat/modules/federation_identity_request_token/data/repository/federation_identity_request_token_repository_impl.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_request.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/usecase/federation_identity_request_token_interactor.dart';
import 'package:flutter/foundation.dart';

class FederationIdentityRequestTokenManager {
  DioClient _bindingDio({
    required FederationTokenRequest federationTokenRequest,
  }) {
    final headers = {
      HttpHeaders.acceptHeader:
          FederationIdentityRequestTokenEndpoint.acceptHeaderDefault,
      HttpHeaders.contentTypeHeader:
          FederationIdentityRequestTokenEndpoint.contentTypeHeaderDefault,
      HttpHeaders.authorizationHeader:
          'Bearer ${federationTokenRequest.accessToken}',
    };

    final dio = Dio(
      BaseOptions(
        baseUrl: federationTokenRequest.homeserverUrl,
        headers: headers,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return DioClient(dio);
  }

  FederationIdentityRequestTokenApi _bindingAPI(DioClient dio) {
    return FederationIdentityRequestTokenApi(dio);
  }

  FederationIdentityRequestTokenDatasourceImpl _bindingDataSourceImpl(
    FederationIdentityRequestTokenApi federationIdentityRequestTokenApi,
  ) {
    return FederationIdentityRequestTokenDatasourceImpl(
      federationIdentityRequestTokenApi: federationIdentityRequestTokenApi,
    );
  }

  FederationIdentityRequestTokenRepositoryImpl _bindingRepositoryImpl(
    FederationIdentityRequestTokenDatasourceImpl datasource,
  ) {
    return FederationIdentityRequestTokenRepositoryImpl(datasource: datasource);
  }

  FederationIdentityRequestTokenInteractor _bindingInteractor({
    required FederationTokenRequest federationTokenRequest,
  }) {
    final dio = _bindingDio(federationTokenRequest: federationTokenRequest);
    final api = _bindingAPI(dio);
    final datasource = _bindingDataSourceImpl(api);
    final repository = _bindingRepositoryImpl(datasource);

    return FederationIdentityRequestTokenInteractor(repository: repository);
  }

  Future<Either<Failure, Success>> execute({
    required FederationTokenRequest federationTokenRequest,
  }) {
    return _bindingInteractor(
      federationTokenRequest: federationTokenRequest,
    ).execute(mxid: federationTokenRequest.mxid);
  }
}
