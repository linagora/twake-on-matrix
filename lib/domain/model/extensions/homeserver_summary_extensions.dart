import 'package:fluffychat/data/model/federation_server/federation_server_information.dart';
import 'package:fluffychat/domain/model/tom_server_information.dart';
import 'package:matrix/matrix.dart';

extension HomeserverSummaryExtensions on HomeserverSummary {
  ToMServerInformation? get tomServer {
    if (discoveryInformation?.additionalProperties == null) {
      return null;
    }
    final tomServerJson = discoveryInformation
        ?.additionalProperties[ToMServerInformation.tomServerKey];
    if (tomServerJson == null) {
      return null;
    }
    try {
      return ToMServerInformation.fromJson(tomServerJson);
    } catch (e) {
      Logs().e('Failed to parse t.server from homeserver summary', e);
      return null;
    }
  }

  FederationServerInformation? get federationServer {
    if (discoveryInformation?.additionalProperties == null) {
      return null;
    }
    final fedServerJson = discoveryInformation
        ?.additionalProperties[FederationServerInformation.fedServerKey];
    if (fedServerJson == null) {
      return null;
    }
    try {
      return FederationServerInformation.fromJson(fedServerJson);
    } catch (e) {
      Logs().e(
        'Failed to parse m.federated_identity_services from homeserver summary',
        e,
      );
      return null;
    }
  }
}
