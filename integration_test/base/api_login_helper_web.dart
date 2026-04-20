/// Web stub for the OIDC-based API login helper.
///
/// The mobile flow drives the 7-step OIDC redirect dance via `dart:io`
/// `HttpClient`, which is not bound by the browser's same-origin policy.
/// In a browser those same requests go through XHR/`fetch`, and the SSO
/// provider does not expose the necessary CORS headers for a non-browser
/// origin — calling this helper from Flutter Web therefore hits an
/// `XMLHttpRequest error` on the very first request.
///
/// Web integration tests should instead run against a locally-provisioned
/// Matrix homeserver (e.g. the Docker Synapse shipped in
/// `integration_test/synapse/`) and authenticate via `m.login.password` on
/// the client-server API, which is CORS-allowed on a same-origin setup.
/// That migration is tracked as a follow-up to the Patrol 4.x upgrade.
Future<String> fetchOidcLoginToken({
  required String username,
  required String password,
}) => throw UnsupportedError(
  'API-based SSO login is not available on Flutter Web due to cross-origin '
  'restrictions. Run web integration tests against a local Synapse with '
  '`m.login.password` instead — see the web-integration follow-up PR.',
);

Future<void> sendMessageAsReceiver({required String message}) =>
    throw UnsupportedError(
      'Sending messages as the receiver account via the SSO bypass is not '
      'available on Flutter Web. Drive message emission against a local '
      'Synapse instead.',
    );
