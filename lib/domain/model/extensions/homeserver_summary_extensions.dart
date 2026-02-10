import 'package:fluffychat/config/app_constants.dart';
import 'package:fluffychat/data/model/federation_server/federation_server_information.dart';
import 'package:fluffychat/domain/model/app_twake_information.dart';
import 'package:fluffychat/domain/model/homeserver_summary.dart';
import 'package:fluffychat/domain/model/tom_server_information.dart';
import 'package:matrix/matrix.dart';

extension HomeserverSummaryExtensions on HomeserverSummary {
  ToMServerInformation? get tomServer {
    if (discoveryInformation?.additionalProperties == null) {
      return null;
    }
    final tomServerJson =
        discoveryInformation?.additionalProperties[ToMServerInformation
                .tomServerKey]
            as Map<String, dynamic>?;
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

  AppTwakeInformation? get appTwakeInformation {
    if (discoveryInformation?.additionalProperties == null) {
      return null;
    }
    final appTwakeJson =
        discoveryInformation?.additionalProperties[AppTwakeInformation
                .appTwakeInformationKey]
            as Map<String, dynamic>?;
    if (appTwakeJson == null) {
      return null;
    }
    try {
      return AppTwakeInformation.fromJson(appTwakeJson);
    } catch (e) {
      Logs().e('Failed to parse app.twake.chat from homeserver summary', e);
      return null;
    }
  }

  FederationServerInformation? get federationServer {
    if (discoveryInformation?.additionalProperties == null) {
      return null;
    }
    final fedServerJson =
        discoveryInformation?.additionalProperties[FederationServerInformation
                .fedServerKey]
            as Map<String, dynamic>?;
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

extension NullableHomeserverSummaryExtensions on HomeserverSummary? {
  bool get supportSSOLogin {
    return this?.loginFlows.any(
          (flow) => flow.type == AppConstants.ssoLoginType,
        ) ==
        true;
  }
}
