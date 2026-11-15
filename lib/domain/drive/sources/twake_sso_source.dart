import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';

/// The Twake SSO, as one role: sign the user in and give back an id token.
abstract interface class TwakeSsoSource {
  /// Runs a full sign-in (browser included).
  ///
  /// Throws [DriveSignInCancelled] when the user backs out, and a
  /// [DriveSignInFailed] for any other failure.
  Future<DriveIdToken> signIn();

  /// A new id token for [refreshToken], with no browser. The result keeps the
  /// refresh token to use next.
  ///
  /// Throws [DriveSignInFailed] when the SSO refuses [refreshToken], and the
  /// network [DriveException]s ([DriveOffline], [DriveTimedOut],
  /// [DriveRateLimited]) when the SSO could not be asked.
  Future<DriveIdToken> refresh(String refreshToken);
}
