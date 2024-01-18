import 'package:fluffychat/config/app_config.dart';
import 'package:equatable/equatable.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome_view.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

enum TwakeWelcomeType {
  firstAccount,
  otherAccounts,
}

class TwakeWelcomeArg extends Equatable {
  final TwakeWelcomeType twakeIdType;

  const TwakeWelcomeArg({
    this.twakeIdType = TwakeWelcomeType.firstAccount,
  });

  bool get isAddAnotherAccount => twakeIdType == TwakeWelcomeType.otherAccounts;

  @override
  List<Object?> get props => [twakeIdType];
}

class TwakeWelcome extends StatefulWidget {
  final TwakeWelcomeArg? arg;
  const TwakeWelcome({super.key, this.arg});

  @override
  State<TwakeWelcome> createState() => TwakeWelcomeController();
}

class TwakeWelcomeController extends State<TwakeWelcome> {
  void goToHomeserverPicker() {
    if (widget.arg?.isAddAnotherAccount == true) {
      context.push('/rooms/addhomeserver');
    } else {
      context.push('/home/homeserverpicker');
    }
  }

  static const String postLoginRedirectUrlPathParams =
      'post_login_redirect_url';

  static const String postRegisteredRedirectUrlPathParams =
      'post_registered_redirect_url';

  String loginUrl =
      "${AppConfig.registrationUrl}?$postLoginRedirectUrlPathParams=${AppConfig.appOpenUrlScheme}://redirect";

  String signupUrl =
      "${AppConfig.registrationUrl}?$postRegisteredRedirectUrlPathParams=${AppConfig.appOpenUrlScheme}://redirect";

  MatrixState get matrix => Matrix.of(context);

  void onClickSignIn() {
    Logs().d("TwakeIdController::onClickSignIn: Login Url - $loginUrl");
    _redirectRegistrationUrl(loginUrl);
  }

  void _handleTokenFromRegistrationSite(String uri) async {
    final token = Uri.parse(uri).queryParameters['loginToken'];
    Logs().d("TwakeIdController: _handleLoginToken: token: $token");
    if (token?.isEmpty ?? false) return;
    Matrix.of(context).loginType = LoginType.mLoginToken;
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => Matrix.of(context).getLoginClient().login(
            LoginType.mLoginToken,
            token: token,
            initialDeviceDisplayName: PlatformInfos.clientName,
          ),
    );
  }

  void _redirectRegistrationUrl(String url) async {
    matrix.loginHomeserverSummary =
        await matrix.getLoginClient().checkHomeserver(
              Uri.parse(AppConfig.twakeWorkplaceHomeserver),
            );
    final uri = await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: AppConfig.appOpenUrlScheme,
      options: const FlutterWebAuth2Options(
        intentFlags: ephemeralIntentFlags,
      ),
    );
    Logs().d("TwakeIdController:_redirectRegistrationUrl: URI - $uri");
    _handleTokenFromRegistrationSite(uri);
  }

  void onClickCreateTwakeId() {
    Logs()
        .d("TwakeIdController::onClickCreateTwakeId: Signup Url - $signupUrl");
    _redirectRegistrationUrl(signupUrl);
  }

  @override
  Widget build(BuildContext context) {
    return TwakeWelcomeView(controller: this);
  }
}
