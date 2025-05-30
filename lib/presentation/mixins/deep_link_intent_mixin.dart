import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/deep_link/deep_link.dart';
import 'package:fluffychat/presentation/model/deep_link/open_app_deep_link.dart';
import 'package:fluffychat/utils/deep_link/deep_link_utils.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/agruments/logout_body_args.dart';
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

      final clientExisted = await matrixState.getClientExisted(
        homeServer: openAppDeepLink.homeServer,
      );
      Logs().d(
        "DeepLinkIntentMixin::clientExisted: UserID =${clientExisted?.userID}",
      );
      if (clientExisted != null) {
        await _handleSignInWithSameHomeServer(
          openAppDeepLink: openAppDeepLink,
          clientExisted: clientExisted,
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
    required Client clientExisted,
  }) async {
    if (clientExisted.userID == null) {
      TwakeDialog.hideLoadingDialog(context);
      return;
    }

    final isSameClient =
        clientExisted.userID == openAppDeepLink.qualifiedUserId;
    final isActiveClient = matrixState.activatedUserId == clientExisted.userID;
    Logs().d(
      'DeepLinkIntentMixin::_handleSignInWithSameHomeServer(): isSameClient = $isSameClient, isActiveClient = $isActiveClient',
    );
    if (isSameClient && isActiveClient) {
      TwakeDialog.hideLoadingDialog(context);
    } else if (isSameClient && !isActiveClient) {
      await _handleSignInWithSameInactiveClient(
        openAppDeepLink: openAppDeepLink,
        clientExisted: clientExisted,
      );
    } else if (!isSameClient && isActiveClient) {
      await _handleSignInWithDifferentActiveClient(
        openAppDeepLink: openAppDeepLink,
        userIdExisted: clientExisted.userID!,
      );
    } else {
      await _handleSignInWithDifferentInactiveClient(
        openAppDeepLink: openAppDeepLink,
        clientExisted: clientExisted,
      );
    }
  }

  Future<void> _switchActiveClient({required Client clientExisted}) async {
    final activeClientState = await matrixState.setActiveClient(clientExisted);
    if (activeClientState.isSuccess) {
      TwakeApp.router.go(
        '/rooms',
        extra: LogoutBodyArgs(newActiveClient: clientExisted),
      );
    }
  }

  Future<void> _handleSignInWithSameInactiveClient({
    required OpenAppDeepLink openAppDeepLink,
    required Client clientExisted,
  }) async {
    Logs().d(
      'DeepLinkIntentMixin::_handleSignInWithSameInactiveClient():',
    );
    final confirmResult = await _showConfirmSwitchAccountDialog(
      userIdExisted: matrixState.activatedUserId,
      userId: openAppDeepLink.qualifiedUserId,
      onlySwitchAccount: true,
    );

    if (confirmResult == ConfirmResult.cancel) {
      TwakeDialog.hideLoadingDialog(context);
      return;
    }

    await _switchActiveClient(clientExisted: clientExisted);
    TwakeDialog.hideLoadingDialog(context);
  }

  Future<void> _handleSignInWithDifferentActiveClient({
    required OpenAppDeepLink openAppDeepLink,
    required String userIdExisted,
  }) async {
    Logs().d(
      'DeepLinkIntentMixin::_handleSignInWithDifferentActiveClient(): userIdExisted = $userIdExisted',
    );
    final confirmResult = await _showConfirmSwitchAccountDialog(
      userIdExisted: userIdExisted,
      userId: openAppDeepLink.qualifiedUserId,
    );

    if (confirmResult == ConfirmResult.cancel) {
      TwakeDialog.hideLoadingDialog(context);
      return;
    }

    processingDeepLink = openAppDeepLink;
    await _autoLogoutActiveClient();
  }

  Future<void> _handleSignInWithDifferentInactiveClient({
    required OpenAppDeepLink openAppDeepLink,
    required Client clientExisted,
  }) async {
    Logs().d(
      'DeepLinkIntentMixin::_handleSignInWithDifferentInactiveClient(): UserID = ${clientExisted.userID}',
    );
    final confirmResult = await _showConfirmSwitchAccountDialog(
      userIdExisted: clientExisted.userID!,
      userId: openAppDeepLink.qualifiedUserId,
    );

    if (confirmResult == ConfirmResult.cancel) {
      TwakeDialog.hideLoadingDialog(context);
      return;
    }

    processingDeepLink = openAppDeepLink;
    await _autoLogoutInactiveClient(client: clientExisted);
  }

  Future<ConfirmResult> _showConfirmSwitchAccountDialog({
    required String userIdExisted,
    required String userId,
    bool onlySwitchAccount = false,
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
          text: ' $userIdExisted',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
        const TextSpan(text: '. '),
        TextSpan(
          text: onlySwitchAccount
              ? l10n?.doYouWantToSwitchTo
              : l10n?.doYouWantToLogOutAndSwitchTo,
        ),
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

  Future<void> _autoLogoutActiveClient() async {
    Logs().d('DeepLinkIntentMixin::_autoLogoutActiveClient');
    await matrixState.logoutAction(matrix: matrixState);
  }

  Future<void> _autoLogoutInactiveClient({required Client client}) async {
    Logs().d('DeepLinkIntentMixin::_autoLogoutInactiveClient');
    final activeClientState = await matrixState.setActiveClient(client);

    if (activeClientState.isSuccess) {
      await matrixState.logoutAction(matrix: matrixState);
    } else {
      processingDeepLink = null;
      TwakeDialog.hideLoadingDialog(context);
    }
  }

  void disposeDeepLink() {
    Logs().d('DeepLinkIntentMixin::disposeDeepLink');
    intentUriStreamSubscription?.cancel();
    intentUriStreamSubscription = null;
    processingDeepLink = null;
  }
}
