import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';

class OnAuthRedirect extends StatefulWidget {
  const OnAuthRedirect({super.key});

  @override
  State<OnAuthRedirect> createState() => _OnAuthRedirectState();
}

class _OnAuthRedirectState extends State<OnAuthRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryLoggingUsingToken();
    });
  }

  String? getQueryParameter(String key) {
    final questionMarkIndex = html.window.location.href.indexOf('?');
    if (questionMarkIndex == -1) {
      return null;
    }
    final queryParams =
        Uri.parse(html.window.location.href, questionMarkIndex).queryParameters;
    return queryParams[key];
  }

  static bool get homeserverIsConfigured =>
      AppConfig.homeserver != 'https://example.com/' ||
      AppConfig.homeserver.isNotEmpty;

  Future<void> tryLoggingUsingToken() async {
    try {
      final isConfigured = await AppConfig.initConfigCompleter.future;
      if (!isConfigured) {
        if (!AppConfig.hasReachedMaxRetries) {
          tryLoggingUsingToken();
        } else {
          Logs().e(
            'OnAuthRedirect::tryGetHomeserver(): Config not found',
          );
          TwakeApp.router.go('/home', extra: true);
        }
      }
      final homeserver = AppConfig.homeserver;
      if (!homeserverIsConfigured) {
        throw Exception(
          'tryLoggingUsingToken(): Missing homeserver',
        );
      }

      final loginToken = getQueryParameter('loginToken');
      if (loginToken == null || loginToken.isEmpty) {
        throw Exception(
          'tryLoggingUsingToken(): Missing loginToken',
        );
      }
      Logs().i('tryLoggingUsingToken::loginToken: $loginToken');
      Logs().i('tryLoggingUsingToken::homeserver: $homeserver');
      Matrix.of(context).loginType = LoginType.mLoginToken;
      Matrix.of(context).loginHomeserverSummary = await Matrix.of(context)
          .getLoginClient()
          .checkHomeserver(Uri.parse(homeserver));

      await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () => Matrix.of(context).getLoginClient().login(
              LoginType.mLoginToken,
              token: loginToken,
              initialDeviceDisplayName: PlatformInfos.clientName,
            ),
      );
    } catch (e) {
      Logs().e('tryLoggingUsingToken::error: $e');
      TwakeApp.router.go('/home', extra: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CupertinoActivityIndicator(
          animating: true,
          color: Colors.white,
        ),
      ),
    );
  }
}
