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
}
