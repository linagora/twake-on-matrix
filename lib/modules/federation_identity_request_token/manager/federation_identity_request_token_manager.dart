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

class FederationIdentityRequestTokenManager {
  final FederationTokenRequest federationTokenRequest;

  FederationIdentityRequestTokenManager({
    required this.federationTokenRequest,
  });

  DioClient _bindingDio() {
    final headers = {
      HttpHeaders.acceptHeader:
          FederationIdentityRequestTokenEndpoint.acceptHeaderDefault,
      HttpHeaders.contentTypeHeader:
          FederationIdentityRequestTokenEndpoint.contentTypeHeaderDefault,
      HttpHeaders.authorizationHeader: 'Bearer ${federationTokenRequest.token}',
    };

    return DioClient(
      Dio(
        BaseOptions(
          baseUrl: federationTokenRequest.federationUrl,
          headers: headers,
        ),
      ),
    );
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
    return FederationIdentityRequestTokenRepositoryImpl(
      datasource: datasource,
    );
  }

  FederationIdentityRequestTokenInteractor _bindingInteractor() {
    final dio = _bindingDio();
    final api = _bindingAPI(dio);
    final datasource = _bindingDataSourceImpl(api);
    final repository = _bindingRepositoryImpl(datasource);

    return FederationIdentityRequestTokenInteractor(
      repository: repository,
    );
  }

  Stream<Either<Failure, Success>> execute() {
    return _bindingInteractor().execute(
      mxid: federationTokenRequest.mxid,
    );
  }
}
