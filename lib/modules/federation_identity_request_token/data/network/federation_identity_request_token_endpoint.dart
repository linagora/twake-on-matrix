import 'package:fluffychat/data/network/service_path.dart';

class FederationIdentityRequestTokenEndpoint {
  static const String federationIdentityRootPath = '_matrix/client';
  static const String federationIdentityAPIVersion = 'v3';

  static const acceptHeaderDefault = 'application/json';

  static const contentTypeHeaderDefault = 'application/json';

  static ServicePath requestTokenServicePath(String mxid) =>
      ServicePath('/user/$mxid/openid/request_token');
}

extension FederationRequestTokenServicePathExtensions on ServicePath {
  String generateFederationIdentityRequestTokenEndpoint({
    String rootPath =
        FederationIdentityRequestTokenEndpoint.federationIdentityRootPath,
    String apiVersion =
        FederationIdentityRequestTokenEndpoint.federationIdentityAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }
}
