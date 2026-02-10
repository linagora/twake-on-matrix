import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/datasource_impl/federation_identity_lookup_datasource_impl.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/network/federation_identity_endpoint.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/network/federation_identity_lookup_api.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/repository_impl/federation_identity_lookup_repository_impl.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_arguments.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/usecase/federation_identity_lookup_interactor.dart';
import 'package:flutter/foundation.dart';

class FederationIdentityLookupManager {
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

  FederationIdentityLookupInteractor _bindingInteractor({
    required FederationArguments arguments,
  }) {
    final dio = _bindingDio(federationUrl: arguments.federationUrl);
    final api = _bindingAPI(dio);
    final datasource = _bindingDataSourceImpl(api);
    final repository = _bindingRepositoryImpl(datasource);

    return FederationIdentityLookupInteractor(
      federationIdentityLookupRepository: repository,
    );
  }

  Future<Either<Failure, Success>> execute({
    required FederationArguments arguments,
  }) {
    return _bindingInteractor(
      arguments: arguments,
    ).execute(arguments: arguments);
  }
}
