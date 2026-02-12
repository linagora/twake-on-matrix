import 'package:fluffychat/modules/federation_identity_request_token/data/datasource/federation_identity_request_token_datasource.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/repository/federation_identity_request_token_repository.dart';

class FederationIdentityRequestTokenRepositoryImpl
    implements FederationIdentityRequestTokenRepository {
  final FederationIdentityRequestTokenDatasource datasource;

  FederationIdentityRequestTokenRepositoryImpl({required this.datasource});

  @override
  Future<FederationTokenInformation> requestToken({required String mxid}) {
    return datasource.requestToken(mxid: mxid);
  }
}
