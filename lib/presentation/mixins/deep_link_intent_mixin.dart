import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/deep_link/deep_link.dart';
import 'package:fluffychat/presentation/model/deep_link/open_app_deep_link.dart';
import 'package:fluffychat/utils/deep_link/deep_link_utils.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin DeepLinkIntentMixin<T extends StatefulWidget> on State<T> {
  MatrixState get matrixState;

  StreamSubscription? intentUriStreamSubscription;

  final _responsiveUtils = getIt.get<ResponsiveUtils>();
  OpenAppDeepLink? processingDeepLink;

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
      Logs().d(
        "DeepLinkIntentMixin:_processIncomingUris: OPEN_APP_DEEP_LINK = $openAppDeepLink",
      );
      if (openAppDeepLink == null) return;

      _handleOpenAppFromDeepLink(openAppDeepLink);
    }
  }

  Future<void> initDeepLinkIntent() async {
    Logs().d('DeepLinkIntentMixin::initDeepLinkIntent');
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

      final homeServerExisted = await matrixState.validateHomeServerExisted(
        homeServer: openAppDeepLink.homeServer,
      );
      Logs().d("DeepLinkIntentMixin::homeServerExisted: $homeServerExisted");
      if (homeServerExisted) {
        await _handleSignInWithSameHomeServer(
          openAppDeepLink: openAppDeepLink,
        );
        return;
      }

      await autoSignInWithLoginToken(
        loginToken: openAppDeepLink.loginToken,
        homeServerUrl: openAppDeepLink.homeServerUrl,
      );
    } catch (e) {
      Logs().e("DeepLinkIntentMixin::_handleOpenAppFromDeepLink: $e");
      TwakeDialog.hideLoadingDialog(context);
    }
  }

  Future<void> autoSignInWithLoginToken({
    required String loginToken,
    required String homeServerUrl,
  }) async {
    try {
      Logs().d(
        'DeepLinkIntentMixin::autoSignInWithLoginToken(): LoginToken = $loginToken',
      );
      if (loginToken.isEmpty == true) return;

      matrixState.loginType = LoginType.mLoginToken;
      matrixState.loginHomeserverSummary = await matrixState
          .getLoginClient()
          .checkHomeserver(Uri.parse(homeServerUrl));

      await TwakeDialog.showStreamDialogFullScreen(
        future: () => matrixState.getLoginClient().login(
              LoginType.mLoginToken,
              token: loginToken,
              initialDeviceDisplayName: PlatformInfos.clientName,
            ),
      );
      Logs().d(
        'DeepLinkIntentMixin::autoSignInWithLoginToken(): Success',
      );
    } catch (e) {
      Logs().e('DeepLinkIntentMixin::handleTokenFromRegistrationSite(): $e');
    } finally {
      processingDeepLink = null;
      TwakeDialog.hideLoadingDialog(context);
    }
  }

  Future<void> _handleSignInWithSameHomeServer({
    required OpenAppDeepLink openAppDeepLink,
  }) async {
    final isSameAccount =
        matrixState.activatedUserId == openAppDeepLink.qualifiedUserId;
    Logs().d(
      'DeepLinkIntentMixin::_handleSignInWithSameHomeServer():activatedUserId = ${matrixState.activatedUserId}, userId = ${openAppDeepLink.qualifiedUserId}, loginToken = ${openAppDeepLink.loginToken}, isSameAccount = $isSameAccount',
    );
    if (!isSameAccount) {
      final confirmResult = await _showConfirmSwitchAccountDialog(
        activeUserId: matrixState.activatedUserId,
        userId: openAppDeepLink.qualifiedUserId,
      );

      if (confirmResult == ConfirmResult.cancel) {
        TwakeDialog.hideLoadingDialog(context);
        return;
      }

      processingDeepLink = openAppDeepLink;
      await _autoLogoutActiveAccount();
    } else {
      TwakeDialog.hideLoadingDialog(context);
    }
  }

  Future<ConfirmResult> _showConfirmSwitchAccountDialog({
    required String activeUserId,
    required String userId,
  }) async {
    final l10n = L10n.of(context);

    return await showConfirmAlertDialog(
      useRootNavigator: false,
      context: context,
      responsiveUtils: _responsiveUtils,
      title: l10n?.switchAccountConfirmation,
      textSpanMessages: [
        TextSpan(text: l10n?.youAreCurrentlyLoggedInWith),
        TextSpan(
          text: ' $activeUserId',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
        const TextSpan(text: '. '),
        TextSpan(text: l10n?.doYouWantToLogOutAndSwitchTo),
        TextSpan(
          text: ' $userId',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
        const TextSpan(text: '?'),
      ],
      maxLinesMessage: 4,
      okLabel: l10n?.yes,
      cancelLabel: l10n?.cancel,
    );
  }

  Future<void> _autoLogoutActiveAccount() async {
    await matrixState.logoutAction(matrix: matrixState);
  }

  void disposeDeepLink() {
    Logs().d('DeepLinkIntentMixin::disposeDeepLink');
    intentUriStreamSubscription?.cancel();
    intentUriStreamSubscription = null;
    processingDeepLink = null;
  }
}
