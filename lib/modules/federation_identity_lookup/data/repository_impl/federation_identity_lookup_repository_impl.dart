import 'package:fluffychat/modules/federation_identity_lookup/data/datasource/federation_identity_lookup_datasource.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/repository/federation_identity_lookup_repository.dart';
import 'package:fluffychat/modules/federation_indetity_request_token/domain/models/federation_token_information.dart';

class FederationIdentityLookupRepositoryImpl
    implements FederationIdentityLookupRepository {
  final FederationIdentityLookupDatasource datasource;

  FederationIdentityLookupRepositoryImpl({required this.datasource});

  @override
  Future<FederationHashDetailsResponse> getHashDetails({
    required String token,
  }) {
    return datasource.getHashDetails(
      token: token,
    );
  }

  @override
  Future<FederationLookupMxidResponse> lookupMxid({
    required FederationLookupMxidRequest request,
    required String token,
  }) {
    return datasource.lookupMxid(
      request: request,
      token: token,
    );
  }

  @override
  Future<FederationRegisterResponse> register({
    required FederationTokenInformation tokenInformation,
  }) {
    return datasource.register(
      tokenInformation: tokenInformation,
    );
  }
}
