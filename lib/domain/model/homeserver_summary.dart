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

  /// Whether this summary describes [homeserver], the server it was discovered
  /// for. The summary the picker holds can belong to another account, so a
  /// caller that falls back on it checks this first.
  bool isOf(Uri? homeserver) {
    final base = discoveryInformation?.mHomeserver.baseUrl;
    if (base == null || homeserver == null) return false;
    return base.host == homeserver.host && base.port == homeserver.port;
  }
}
