import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fluffychat/pages/connect/sso_login_state.dart';
import 'package:fluffychat/presentation/model/deep_link/deep_link.dart';
import 'package:fluffychat/presentation/model/deep_link/open_app_deep_link.dart';
import 'package:fluffychat/utils/app_utils.dart';
import 'package:fluffychat/utils/deep_link/deep_link_utils.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin DeepLinkIntentMixin<T extends StatefulWidget> on State<T> {
  MatrixState get matrixState;

  StreamSubscription? intentUriStreamSubscription;

  void _processIncomingUris(Uri? uri) async {
    Logs().d("DeepLinkIntentMixin:_processIncomingUris: URI = $uri");
    if (uri == null) return;

    final deepLink = DeepLinkUtils.parseDeepLink(uri.toString());
    if (deepLink == null) return;
    Logs().d("DeepLinkIntentMixin:_processIncomingUris: DEEP_LINK = $deepLink");
    if (deepLink.isOpenAppAction) {
      final openAppDeepLink = DeepLinkUtils.parseOpenAppDeepLink(
        deepLink.queryParameters,
      );
      Logs().d("DeepLinkIntentMixin:_processIncomingUris: OPEN_APP_DEEP_LINK = $openAppDeepLink");
      if (openAppDeepLink == null) return;

      _handleOpenAppFromDeepLink(openAppDeepLink);
    }
  }

  Future<void> initDeepLinkIntent() async {
    final appLinks = AppLinks();
    intentUriStreamSubscription =
        appLinks.uriLinkStream.listen(_processIncomingUris);

    if (TwakeApp.gotInitialDeepLink == false) {
      TwakeApp.gotInitialDeepLink = true;
      appLinks.getInitialLink().then(_processIncomingUris);
    }
  }

  void _handleOpenAppFromDeepLink(OpenAppDeepLink openAppDeepLink) async {
    try {
      TwakeDialog.showLoadingTwakeWelcomeDialog(context);

      final homeServerExisted = await AppUtils.validateHomeServerExisted(
        homeServer: openAppDeepLink.homeServer,
      );

      if (homeServerExisted) {
        TwakeDialog.hideLoadingDialog(context);
        return;
      }

      matrixState.loginHomeserverSummary = await matrixState
          .getLoginClient()
          .checkHomeserver(Uri.parse(openAppDeepLink.homeServerUrl));

      await _handleTokenFromRegistrationSite(
        matrix: matrixState,
        loginToken: openAppDeepLink.loginToken,
      );

      TwakeDialog.hideLoadingDialog(context);
    } catch (e) {
      Logs().e("DeepLinkIntentMixin::_handleOpenAppFromDeepLink: $e");
      TwakeDialog.hideLoadingDialog(context);
    }
  }

  Future<SsoLoginState> _handleTokenFromRegistrationSite({
    required MatrixState matrix,
    required String loginToken,
  }) async {
    try {
      if (loginToken.isEmpty == true) {
        return SsoLoginState.tokenEmpty;
      }
      matrix.loginType = LoginType.mLoginToken;

      await TwakeDialog.showStreamDialogFullScreen(
        future: () => matrix.getLoginClient().login(
              LoginType.mLoginToken,
              token: loginToken,
              initialDeviceDisplayName: PlatformInfos.clientName,
            ),
      );

      return SsoLoginState.success;
    } catch (e) {
      Logs().e('DeepLinkIntentMixin::handleTokenFromRegistrationSite(): $e');
      return SsoLoginState.error;
    }
  }

  void disposeDeepLink() {
    intentUriStreamSubscription?.cancel();
    intentUriStreamSubscription = null;
  }
}
