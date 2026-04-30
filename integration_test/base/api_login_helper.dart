/// OIDC-based API login and messaging helper used by integration tests.
///
/// Mobile platforms run through the 7-step OIDC redirect flow using
/// `dart:io`'s `HttpClient`. On Flutter Web the same flow is not feasible
/// — cross-origin XHR/fetch cannot walk the SSO 302 chain and the SSO
/// origin does not expose CORS headers — so
/// `api_login_helper_web.dart` throws `UnsupportedError` and web
/// integration tests are expected to authenticate against a local
/// Synapse via `m.login.password` instead. See the web-integration
/// follow-up PR for the setup.
library;

export 'api_login_helper_io.dart'
    if (dart.library.js_interop) 'api_login_helper_web.dart';
