import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/presentation/model/registration_done_model.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

mixin HandleRegistrationMixin {
  void handleRegistrationDone(String uri) async {
    Logs().i('handleRegistrationDone: uri: $uri');
    final registrationDoneModel = RegistrationDoneModel.fromUrl(uri);
    if (registrationDoneModel.openApp?.startsWith(AppConfig.appOpenUrlScheme) ==
        true) {
      TwakeApp.router.go('/home', extra: uri);
    } else {
      try {
        if (await canLaunchUrlString(registrationDoneModel.openApp!)) {
          launchUrl(Uri.parse(registrationDoneModel.openApp!));
        } else {
          _openAppInStore(registrationDoneModel);
        }
      } catch (e) {
        _openAppInStore(registrationDoneModel);
      }
    }
  }

  void _openAppInStore(RegistrationDoneModel registrationDoneModel) async {
    await Future.delayed(const Duration(seconds: 1));
    if (PlatformInfos.isMacOS || PlatformInfos.isIOS) {
      if (registrationDoneModel.appStoreUrl != null) {
        await launchUrl(Uri.parse(registrationDoneModel.appStoreUrl!));
      }
    } else {
      if (registrationDoneModel.playStoreUrl != null) {
        await launchUrl(Uri.parse(registrationDoneModel.playStoreUrl!));
      }
    }
  }

  void registerIOS(String url) async {
    final uri = await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: AppConfig.appOpenUrlScheme,
      options: const FlutterWebAuth2Options(
        intentFlags: ephemeralIntentFlags,
      ),
    );
    handleRegistrationDone(uri);
  }
}
