import 'package:matrix/matrix.dart';

class HomeserverSummary {
  final DiscoveryInformation? discoveryInformation;
  final GetVersionsResponse versions;
  final List<LoginFlow> loginFlows;

  HomeserverSummary({
    required this.discoveryInformation,
    required this.versions,
    required this.loginFlows,
  });

  /// `m.authentication` is not in the client-server spec, which uses
  /// `GET /_matrix/client/v1/auth_metadata` instead
  /// (https://spec.matrix.org/v1.19/client-server-api/#server-metadata-discovery);
  /// the Twake homeserver publishes its OIDC issuer there (MSC2965).
  String? get ssoIssuer {
    final authentication =
        discoveryInformation?.additionalProperties['m.authentication'];
    final issuer = authentication is Map ? authentication['issuer'] : null;
    return issuer is String && issuer.isNotEmpty ? issuer : null;
  }

  bool describes(Uri? homeserver) {
    final own = discoveryInformation?.mHomeserver.baseUrl;
    return own != null &&
        homeserver != null &&
        own.hasAuthority &&
        own.origin == homeserver.origin;
  }
}
