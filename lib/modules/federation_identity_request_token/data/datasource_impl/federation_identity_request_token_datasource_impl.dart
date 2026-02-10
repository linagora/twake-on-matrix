import 'package:fluffychat/modules/federation_identity_request_token/data/datasource/federation_identity_request_token_datasource.dart';
import 'package:fluffychat/modules/federation_identity_request_token/data/network/federation_identity_request_token_api.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';

class FederationIdentityRequestTokenDatasourceImpl
    implements FederationIdentityRequestTokenDatasource {
  final FederationIdentityRequestTokenApi federationIdentityRequestTokenApi;

  FederationIdentityRequestTokenDatasourceImpl({
    required this.federationIdentityRequestTokenApi,
  });

  @override
  Future<FederationTokenInformation> requestToken({required String mxid}) {
    return federationIdentityRequestTokenApi.getToken(mxid: mxid);
  }
}
