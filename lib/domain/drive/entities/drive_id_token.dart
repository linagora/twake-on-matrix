import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_id_token.freezed.dart';

/// The id token of the Twake SSO that Drive takes in exchange for its own
/// token, with the claim the platform URL needs.
@freezed
abstract class DriveIdToken with _$DriveIdToken {
  const DriveIdToken._();

  const factory DriveIdToken({
    required String value,
    required DateTime expiresAt,

    /// Host of the user's workplace (claim `workplaceFqdn`); null when the SSO
    /// does not send it.
    String? workplaceFqdn,

    /// How the SSO names the user (claims `sub` and `email`), to tell whether
    /// it is the Matrix account that asked; null when the SSO sends none.
    String? subject,
    String? email,

    /// Lets the app get a new id token without a browser; null when the SSO
    /// sends none. A credential, like [value].
    String? refreshToken,
  }) = _DriveIdToken;

  /// What an app restart leaves: a refresh token and no id token. Never usable,
  /// so the first use refreshes it.
  factory DriveIdToken.refreshOnly(String refreshToken) => DriveIdToken(
    value: '',
    expiresAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    refreshToken: refreshToken,
  );

  /// The token is a credential: it never reaches a log line.
  @override
  String toString() => 'DriveIdToken(expiresAt: $expiresAt)';
}
