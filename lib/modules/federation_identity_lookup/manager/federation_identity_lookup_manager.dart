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

class FederationIdentityLookupManager {
  final FederationArguments arguments;

  FederationIdentityLookupManager({
    required this.arguments,
  });

  DioClient _bindingDio() {
    final headers = {
      HttpHeaders.acceptHeader: FederationIdentityEndpoint.acceptHeaderDefault,
      HttpHeaders.contentTypeHeader:
          FederationIdentityEndpoint.contentTypeHeaderDefault,
    };

    return DioClient(
      Dio(
        BaseOptions(
          baseUrl: arguments.federationUrl,
          headers: headers,
        ),
      ),
    );
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
    return FederationIdentityLookupRepositoryImpl(
      datasource: datasource,
    );
  }

  FederationIdentityLookupInteractor _bindingInteractor() {
    final dio = _bindingDio();
    final api = _bindingAPI(dio);
    final datasource = _bindingDataSourceImpl(api);
    final repository = _bindingRepositoryImpl(datasource);

    return FederationIdentityLookupInteractor(
      federationIdentityLookupRepository: repository,
    );
  }

  Stream<Either<Failure, Success>> execute() {
    return _bindingInteractor().execute(arguments: arguments);
  }
}
