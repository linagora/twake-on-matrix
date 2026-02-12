import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';

abstract class FederationIdentityRequestTokenRepository {
  Future<FederationTokenInformation> requestToken({required String mxid});
}
