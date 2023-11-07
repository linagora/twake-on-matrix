import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:matrix/matrix.dart';

mixin HandleRegistrationMixin {
  void handleRegistrationDone(String uri) async {
    Logs().i('handleRegistrationDone: uri: $uri');
    TwakeApp.router.go('/home', extra: uri);
  }

  void register(String url) async {
    final redirectUrl = '${AppConfig.appOpenUrlScheme.toLowerCase()}://login';
    final uri = await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: Uri.parse(redirectUrl).scheme,
      options: const FlutterWebAuth2Options(
        intentFlags: ephemeralIntentFlags,
      ),
    );
    handleRegistrationDone(uri);
  }
}
