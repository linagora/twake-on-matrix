import 'package:fluffychat/data/network/service_path.dart';

class FederationIdentityEndpoint {
  static const String federationIdentityRootPath = '/_matrix/identity';
  static const String federationIdentityAPIVersion = 'v2';

  static const acceptHeaderDefault = 'application/json';

  static const contentTypeHeaderDefault = 'application/json';

  static final ServicePath lookupServicePath = ServicePath('/lookup');

  static final ServicePath hashDetailsServicePath = ServicePath(
    '/hash_details',
  );

  static final ServicePath registerServicePath = ServicePath(
    '/account/register',
  );
}

extension FederationServicePathExtensions on ServicePath {
  String generateFederationIdentityEndpoint({
    String rootPath = FederationIdentityEndpoint.federationIdentityRootPath,
    String apiVersion = FederationIdentityEndpoint.federationIdentityAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }
}
