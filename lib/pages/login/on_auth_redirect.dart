import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> tryLoggingUsingToken() async {
    try {
      final loginToken = getQueryParameter('loginToken');
      final homeserver = getQueryParameter('homeserver');
      if (loginToken == null ||
          loginToken.isEmpty ||
          homeserver == null ||
          homeserver.isEmpty) {
        throw Exception(
          'tryLoggingUsingToken(): Missing loginToken or homeserver',
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
      context.go('/home');
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
