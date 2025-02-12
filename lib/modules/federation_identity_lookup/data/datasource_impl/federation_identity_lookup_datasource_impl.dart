import 'package:fluffychat/modules/federation_identity_lookup/data/datasource/federation_identity_lookup_datasource.dart';
import 'package:fluffychat/modules/federation_identity_lookup/data/network/federation_identity_lookup_api.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';

class FederationIdentityLookupDatasourceImpl
    implements FederationIdentityLookupDatasource {
  final FederationIdentityLookupApi federationIdentityLookupApi;

  FederationIdentityLookupDatasourceImpl({
    required this.federationIdentityLookupApi,
  });

  @override
  Future<FederationHashDetailsResponse> getHashDetails({
    required String token,
  }) {
    return federationIdentityLookupApi.getHashDetails(
      token,
    );
  }

  @override
  Future<FederationLookupMxidResponse> lookupMxid({
    required FederationLookupMxidRequest request,
    required String token,
  }) {
    return federationIdentityLookupApi.lookupMxid(
      request: request,
      token: token,
    );
  }

  @override
  Future<FederationRegisterResponse> register({
    required FederationTokenInformation tokenInformation,
  }) {
    return federationIdentityLookupApi.register(
      tokenInformation: tokenInformation,
    );
  }
}
