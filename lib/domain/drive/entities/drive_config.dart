import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_config.freezed.dart';

/// Where the Twake SSO is and which client this app is at it. The SSO comes
/// from the homeserver well-known; empty means Drive is off.
@freezed
abstract class DriveConfig with _$DriveConfig {
  const DriveConfig._();

  const factory DriveConfig({
    /// Base URL of the Twake SSO (OIDC issuer).
    required String ssoUrl,

    /// Public OIDC client of this app at the Twake SSO.
    required String ssoClientId,
  }) = _DriveConfig;

  bool get isEnabled => ssoUrl.isNotEmpty && ssoClientId.isNotEmpty;
}
