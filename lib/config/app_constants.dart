class AppConstants {
  AppConstants._();
  static const String appLinkUniversalLinkDomain = 'links.twake.app';
  static const String ssoLoginType = 'm.login.sso';

  /// Login with the id token of the Twake SSO. Not a login type of the Matrix
  /// client-server spec, which defines `m.login.password` and `m.login.token`
  /// for `POST /login`
  /// (https://spec.matrix.org/v1.19/client-server-api/#post_matrixclientv3login):
  /// the Twake homeserver takes it as an extension, and lists it in the flows
  /// of `GET /login` when it does
  /// (https://spec.matrix.org/v1.19/client-server-api/#get_matrixclientv3login;
  /// `mobile-single-login` in the Twake docs). `Client.login` of the pinned
  /// Matrix SDK takes any type string and sends it as it is.
  static const String jwtLoginType = 'org.matrix.login.jwt';

  /// Public OIDC client of this app at the Twake SSO (no secret).
  static const String twakeSsoClientId = 'twake-chat-mobile';
}
