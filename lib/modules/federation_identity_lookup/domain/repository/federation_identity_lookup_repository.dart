import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';

abstract class FederationIdentityLookupRepository {
  Future<FederationRegisterResponse> register({
    required FederationTokenInformation tokenInformation,
  });

  Future<FederationHashDetailsResponse> getHashDetails({
    required String registeredToken,
  });

  Future<FederationLookupMxidResponse> lookupMxid({
    required FederationLookupMxidRequest request,
    required String registeredToken,
  });
}
