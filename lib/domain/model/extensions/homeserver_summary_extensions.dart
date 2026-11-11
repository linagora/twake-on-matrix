import 'package:twake_chat/config/app_constants.dart';
import 'package:twake_chat/data/model/federation_server/federation_server_information.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/domain/model/app_twake_information.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/model/rtc_focus.dart';
import 'package:twake_chat/domain/model/tom_server_information.dart';
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

  String? get videoCallBaseUrl =>
      _firstLiveKitUrl((focus) => focus.livekitBaseUrl);

  /// The token service of in-app calls. A base url alone is a Meet server
  /// (DECISION.md D15).
  String? get callTokenServiceUrl =>
      _firstLiveKitUrl((focus) => focus.livekitServiceUrl.whereSecure);

  String? _firstLiveKitUrl(Uri? Function(RtcFocus focus) urlOf) {
    for (final focus in _liveKitFoci) {
      final url = urlOf(focus)?.toString() ?? '';
      if (url.isEmpty) continue;
      return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }
    return null;
  }

  Iterable<RtcFocus> get _liveKitFoci sync* {
    final rtcFociJson =
        discoveryInformation?.additionalProperties[RtcFocus.rtcFociKey];
    if (rtcFociJson is! List) return;
    for (final focusJson in rtcFociJson.whereType<Map>()) {
      try {
        final focus = RtcFocus.fromJson(Map<String, dynamic>.from(focusJson));
        if (focus.isLiveKit) yield focus;
      } catch (e, s) {
        Logs().wtf(
          'Failed to parse ${RtcFocus.rtcFociKey} from homeserver summary',
          e,
          s,
        );
      }
    }
  }
}

extension NullableHomeserverSummaryExtensions on HomeserverSummary? {
  bool get isInvitationEnabled =>
      this?.appTwakeInformation?.isInvitationEnabled ?? false;

  /// Off unless the homeserver turns it on: an OIDC issuer alone does not
  /// mean its users have a Twake Drive.
  bool get isTwakeDriveEnabled =>
      this?.appTwakeInformation?.isTwakeDriveEnabled ?? false;

  /// The Drive of this homeserver: its SSO when it turns Drive on, else off.
  DriveConfig get twakeDriveConfig => DriveConfig(
    ssoUrl: (isTwakeDriveEnabled ? this?.ssoIssuer : null) ?? '',
    ssoClientId: AppConstants.twakeSsoClientId,
  );

  /// The `https` origin of the Twake Chat web app (`app.twake.chat`
  /// `web_url`), or null when it is missing or not an `https` URL.
  String? get webAppOrigin {
    final webUrl = this?.appTwakeInformation?.webUrl;
    if (webUrl == null) return null;
    final uri = Uri.tryParse(webUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri.origin;
  }

  bool get isPublicGroupsEnabled =>
      this?.appTwakeInformation?.publicGroupsInformation?.isEnabled ?? false;

  bool get isPublicGroupsServerAclEnabled =>
      this?.appTwakeInformation?.publicGroupsInformation?.isServerAclEnabled ??
      false;

  bool get supportSSOLogin {
    return this?.loginFlows.any(
          (flow) => flow.type == AppConstants.ssoLoginType,
        ) ==
        true;
  }
}

const _loopbackHosts = {'localhost', '127.0.0.1', '::1'};

extension on Uri? {
  // The OpenID token goes to this service: http only on this machine.
  Uri? get whereSecure => switch (this) {
    final Uri url when url.isScheme('https') => url,
    final Uri url
        when url.isScheme('http') && _loopbackHosts.contains(url.host) =>
      url,
    _ => null,
  };
}
