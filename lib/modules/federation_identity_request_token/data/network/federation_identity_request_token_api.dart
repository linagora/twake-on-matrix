import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/modules/federation_identity_request_token/data/network/federation_identity_request_token_endpoint.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';

class FederationIdentityRequestTokenApi {
  final DioClient client;

  FederationIdentityRequestTokenApi(this.client);

  Future<FederationTokenInformation> getToken({required String mxid}) async {
    final path = FederationIdentityRequestTokenEndpoint.requestTokenServicePath(
      mxid,
    ).generateFederationIdentityRequestTokenEndpoint();
    final response = await client.postToGetBody(path, data: {});

    return FederationTokenInformation.fromJson(response);
  }
}
