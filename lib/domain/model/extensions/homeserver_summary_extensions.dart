import 'package:fluffychat/config/app_constants.dart';
import 'package:fluffychat/data/model/federation_server/federation_server_information.dart';
import 'package:fluffychat/domain/model/app_twake_information.dart';
import 'package:fluffychat/domain/model/homeserver_summary.dart';
import 'package:fluffychat/domain/model/rtc_focus.dart';
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
    } catch (e, s) {
      Logs().wtf('Failed to parse t.server from homeserver summary', e, s);
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
    } catch (e, s) {
      Logs().wtf(
        'Failed to parse app.twake.chat from homeserver summary',
        e,
        s,
      );
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
    } catch (e, s) {
      Logs().wtf(
        'Failed to parse m.federated_identity_services from homeserver summary',
        e,
        s,
      );
      return null;
    }
  }

  String? get videoCallBaseUrl {
    if (discoveryInformation?.additionalProperties == null) {
      return null;
    }
    final rtcFociJson =
        discoveryInformation?.additionalProperties[RtcFocus.rtcFociKey];
    if (rtcFociJson is! List) {
      return null;
    }
    for (final focusJson in rtcFociJson) {
      if (focusJson is! Map) continue;
      try {
        final focus = RtcFocus.fromJson(Map<String, dynamic>.from(focusJson));
        final baseUrl = focus.livekitBaseUrl?.toString();
        if (!focus.isLiveKit || baseUrl == null || baseUrl.isEmpty) continue;
        return baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
      } catch (e, s) {
        Logs().wtf(
          'Failed to parse ${RtcFocus.rtcFociKey} from homeserver summary',
          e,
          s,
        );
      }
    }
    return null;
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
