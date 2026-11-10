import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// Opens the system browser on [url] and waits for the redirect back to the
/// app. Behind an interface so the sign-in is tested without a browser.
abstract interface class WebAuthLauncher {
  /// Returns the callback URL. Throws a `PlatformException` with code
  /// `CANCELED` when the user closes the browser.
  Future<String> authenticate({
    required String url,
    required String callbackScheme,
  });
}

/// Use a fresh browser session so a Matrix account switch does not silently
/// reuse the previous account's SSO cookie.
class FlutterWebAuth2Launcher implements WebAuthLauncher {
  const FlutterWebAuth2Launcher();

  @override
  Future<String> authenticate({
    required String url,
    required String callbackScheme,
  }) => FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: callbackScheme,
    options: const FlutterWebAuth2Options(
      preferEphemeral: true,
      intentFlags: ephemeralIntentFlags,
    ),
  );
}
