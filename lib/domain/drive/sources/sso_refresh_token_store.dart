/// Where the refresh token of the Twake SSO survives an app restart, in the
/// secure store, one per Matrix user id. With it the app gets a new id token
/// with no browser; without it the user signs in again.
///
/// A token belongs to the SSO that gave it: it is stored with that SSO's
/// issuer and read back only for the same issuer, so a token is never offered
/// to another SSO.
abstract interface class SsoRefreshTokenStore {
  /// The token of [userId] for [issuer], or null when there is none, it came
  /// from another issuer, or it cannot be read.
  Future<String?> read(String userId, {required String issuer});

  Future<void> write(
    String userId,
    String refreshToken, {
    required String issuer,
  });

  /// Safe to call twice, and for a user with no token.
  Future<void> delete(String userId);
}
