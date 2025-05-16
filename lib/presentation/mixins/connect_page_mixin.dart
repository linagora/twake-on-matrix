import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/federation_configurations_repository.dart';
import 'package:fluffychat/domain/repository/tom_configurations_repository.dart';
import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/pages/connect/sso_login_state.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:matrix/matrix.dart';
import 'package:universal_html/html.dart' as html;

typedef OnSAASRegistrationTimeoutCallback = void Function();
typedef OnSAASRegistrationErrorCallback = void Function(Object?);

mixin ConnectPageMixin {
  static const saasRegistrationTimeout = Duration(seconds: 120);

  static const windowNameValue = '_self';

  static const redirectPublicPlatformOnWeb = 'post_login_redirect_url';

  bool supportsFlow({
    required BuildContext context,
    required String flowType,
  }) =>
      Matrix.of(context)
          .loginHomeserverSummary
          ?.loginFlows
          .any((flow) => flow.type == flowType) ??
      false;

  bool supportsSso(BuildContext context) =>
      (PlatformInfos.isMobile ||
          PlatformInfos.isWeb ||
          PlatformInfos.isMacOS) &&
      supportsFlow(context: context, flowType: 'm.login.sso');

  bool supportsLogin(BuildContext context) =>
      supportsFlow(context: context, flowType: 'm.login.password');

  String? getQueryParameter(String key) {
    final questionMarkIndex = html.window.location.href.indexOf('?');
    if (questionMarkIndex == -1) {
      return null;
    }
    final queryParams =
        Uri.parse(html.window.location.href, questionMarkIndex).queryParameters;
    return queryParams[key];
  }

  bool get homeserverIsConfigured =>
      AppConfig.homeserver != AppConfig.sampleValue ||
      AppConfig.homeserver.isNotEmpty;

  String _getRedirectUrlScheme(String redirectUrl) {
    return Uri.parse(redirectUrl).scheme;
  }

  String _getAuthenticateUrl({
    required BuildContext context,
    required String id,
    required String redirectUrl,
  }) {
    final homeserver =
        Matrix.of(context).getLoginClient().homeserver?.toString();
    final ssoRedirectUri =
        '$homeserver/_matrix/client/r0/login/sso/redirect/${Uri.encodeComponent(id)}';
    final redirectUrlEncode = Uri.encodeQueryComponent(redirectUrl);
    return '$ssoRedirectUri?redirectUrl=$redirectUrlEncode';
  }

  String generatePublicPlatformAuthenticationUrl({
    required BuildContext context,
    required String id,
    required String redirectUrl,
  }) {
    final redirectUrlEncode = Uri.encodeQueryComponent(redirectUrl);
    return '${AppConfig.registrationUrl}?$redirectPublicPlatformOnWeb=$redirectUrlEncode&app=${AppConfig.appParameter}';
  }

  String _getLogoutUrl({
    required String authUrl,
    String? redirectUrl,
  }) {
    if (redirectUrl != null) {
      final redirectUrlEncode = base64Url.encode(utf8.encode(redirectUrl));
      return '$authUrl?logout=1&url=$redirectUrlEncode';
    } else {
      return '$authUrl?logout=1';
    }
  }

  Future<String> authenticateWithWebAuth({
    required BuildContext context,
    required String id,
  }) async {
    final redirectUrl = _generateRedirectUrl(
      Matrix.of(context).client.homeserver.toString(),
    );
    final url = _getAuthenticateUrl(
      context: context,
      id: id,
      redirectUrl: redirectUrl,
    );
    final urlScheme = _getRedirectUrlScheme(redirectUrl);
    return await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: urlScheme,
      options: const FlutterWebAuth2Options(
        intentFlags: ephemeralIntentFlags,
        windowName: windowNameValue,
      ),
    );
  }

  Future<SsoLoginState> ssoLoginAction({
    required BuildContext context,
    required String id,
  }) async {
    if (PlatformInfos.isWeb) {
      return ssoLoginActionWeb(context: context, id: id);
    } else {
      return ssoLoginActionMobile(context: context, id: id);
    }
  }

  Future<SsoLoginState> ssoLoginActionWeb({
    required BuildContext context,
    required String id,
  }) async {
    await authenticateWithWebAuth(context: context, id: id);
    return SsoLoginState.success;
  }

  Future<SsoLoginState> ssoLoginActionMobile({
    required BuildContext context,
    required String id,
  }) async {
    try {
      final result = await authenticateWithWebAuth(context: context, id: id);
      final token = Uri.parse(result).queryParameters['loginToken'];
      if (token?.isEmpty ?? false) return SsoLoginState.tokenEmpty;
      Matrix.of(context).loginType = LoginType.mLoginToken;
      await TwakeDialog.showStreamDialogFullScreen(
        future: () => Matrix.of(context).getLoginClient().login(
              LoginType.mLoginToken,
              token: token,
              initialDeviceDisplayName: PlatformInfos.clientName,
            ),
      );
      return SsoLoginState.success;
    } catch (e) {
      Logs().e('ConnectPageMixin:: ssoLoginActionMobil(): error: $e');
      return SsoLoginState.error;
    }
  }

  Future<void> tryLogoutSso({required MatrixState matrix}) async {
    try {
      final authUrl = matrix.authUrl;
      final loginType = matrix.loginType;

      if (authUrl == null || loginType != LoginType.mLoginToken) return;

      final redirectUrl = _generatePostLogoutRedirectUrl();
      final url = _getLogoutUrl(
        authUrl: authUrl,
        redirectUrl: PlatformInfos.isMobile ? redirectUrl : null,
      );
      final urlScheme = _getRedirectUrlScheme(redirectUrl);

      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: urlScheme,
        options: const FlutterWebAuth2Options(windowName: windowNameValue),
      );
      Logs().d('ConnectPageMixin::tryLogoutSso::Result: $result');
    } catch (e) {
      Logs().e('ConnectPageMixin::tryLogoutSso::Error: $e');
    }
  }

  Future<void> registerPublicPlatformAction({
    required BuildContext context,
    required String id,
  }) async {
    final redirectUrl = _generateRedirectUrl(
      Matrix.of(context).client.homeserver.toString(),
    );
    final url = generatePublicPlatformAuthenticationUrl(
      context: context,
      id: id,
      redirectUrl: redirectUrl,
    );
    final urlScheme = _getRedirectUrlScheme(redirectUrl);
    final uri = await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: urlScheme,
      options: const FlutterWebAuth2Options(
        intentFlags: ephemeralIntentFlags,
        windowName: windowNameValue,
      ),
    );
    Logs().d("ConnectPageMixin:_redirectRegistrationUrl: URI - $uri");
  }

  String _generatePostLogoutRedirectUrl() {
    if (kIsWeb) {
      if (AppConfig.issueId != null && AppConfig.issueId!.isNotEmpty) {
        return '${html.window.location.href.getBaseUrlBeforeHash()}auth.html';
      }
      return html.window.location.href
          .getBaseUrlBeforeHash()
          .generateLogoutAuthPath(isDevMode: AppConfig.devMode);
    }
    return '${AppConfig.appOpenUrlScheme.toLowerCase()}://redirect';
  }

  String _generateRedirectUrl(String homeserver) {
    if (kIsWeb) {
      String? homeserverParam = '';
      if (homeserver.isNotEmpty) {
        homeserverParam = '?homeserver=$homeserver';
      }
      if (AppConfig.issueId != null && AppConfig.issueId!.isNotEmpty) {
        return '${html.window.location.href.getBaseUrlBeforeHash()}auth.html$homeserverParam';
      }
      return html.window.location.href
          .getBaseUrlBeforeHash()
          .generateLoginAuthPath(
            homeserverParams: homeserverParam,
            isDevMode: AppConfig.devMode,
          );
    }
    return '${AppConfig.appOpenUrlScheme.toLowerCase()}://login';
  }

  List<IdentityProvider>? identityProviders({
    Map<String, dynamic>? rawLoginTypes,
  }) {
    final loginTypes = rawLoginTypes;
    if (loginTypes == null) return null;
    final rawProviders = loginTypes.tryGetList('flows')!.singleWhere(
          (flow) => flow['type'] == AuthenticationTypes.sso,
        )['identity_providers'];
    final list = (rawProviders as List)
        .map((json) => IdentityProvider.fromJson(json))
        .toList();
    if (PlatformInfos.isCupertinoStyle) {
      list.sort((a, b) => a.brand == 'apple' ? -1 : 1);
    }
    return list;
  }

  Future<SsoLoginState> handleTokenFromRegistrationSite({
    required MatrixState matrix,
    required String uri,
  }) async {
    try {
      final token = Uri.parse(uri).queryParameters['loginToken'];
      Logs().d(
        "ConnectPageMixin: handleTokenFromRegistrationSite: token: $token",
      );
      if (token == null || token.isEmpty == true) {
        return SsoLoginState.tokenEmpty;
      }
      matrix.loginType = LoginType.mLoginToken;
      await TwakeDialog.showStreamDialogFullScreen(
        future: () => matrix.getLoginClient().login(
              LoginType.mLoginToken,
              token: token,
              initialDeviceDisplayName: PlatformInfos.clientName,
            ),
      );
      return SsoLoginState.success;
    } catch (e) {
      Logs()
          .e('ConnectPageMixin:: handleTokenFromRegistrationSite(): error: $e');
      return SsoLoginState.error;
    }
  }

  void resetLocationPathWithLoginToken({
    String? route,
  }) {
    final loginTokenExisted = getQueryParameter('loginToken') != null;
    if (!loginTokenExisted) return;
    html.window.history.replaceState(
      {},
      '',
      '${html.window.location.href.getBaseUrlBeforeHash()}#/${route ?? 'rooms'}',
    );
  }

  Future<Client?> getClientExisted({required String homeServer}) async {
    try {
      final clients = await ClientManager.getClients();
      Logs().d(
        'ConnectPageMixin::getClientExisted:Clients = ${clients.map((client) => client.homeserver).toString()}',
      );
      final clientExisted = clients.firstWhereOrNull(
        (client) => client.homeserver?.toString().contains(homeServer) == true,
      );
      Logs().d(
        'ConnectPageMixin::getClientExisted: $clientExisted',
      );
      if (clientExisted != null &&
          !AppConfig.supportMultipleAccountsInTheSameHomeserver) {
        return clientExisted;
      } else {
        return null;
      }
    } catch (e) {
      Logs().e(
        'ConnectPageMixin::getClientExisted: Exception: $e',
      );
      return null;
    }
  }

  Future<void> logoutAction({required MatrixState matrix}) async {
    Logs().d('ConnectPageMixin::logoutAction');
    await _tryToUploadKeyBackup(matrix: matrix);

    if (PlatformInfos.isMobile) {
      await _logoutActionsOnMobile(matrix: matrix);
    } else {
      await _logoutActionOnOtherPlatform(matrix: matrix);
    }
  }

  Future<void> _tryToUploadKeyBackup({required MatrixState matrix}) async {
    Logs().d('ConnectPageMixin::_tryToUploadKeyBackup');
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        await matrix.client.encryption?.keyManager.uploadInboundGroupSessions();
      },
    );
  }

  Future<void> _logoutActionsOnMobile({required MatrixState matrix}) async {
    await tryLogoutSso(matrix: matrix);

    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        try {
          await _clearAndSignOut(matrix: matrix);
        } catch (e) {
          Logs().e('ConnectPageMixin()::_logoutActionsOnMobile - error: $e');
        }
      },
    );
  }

  Future<void> _deleteTomConfigurations({required MatrixState matrix}) async {
    try {
      final userId = matrix.activatedUserId;
      Logs().d(
        'ConnectPageMixin::_deleteTomConfigurations - Client ID: $userId',
      );
      if (matrix.twakeSupported) {
        await getIt
            .get<ToMConfigurationsRepository>()
            .deleteTomConfigurations(userId);
      }
      Logs().d(
        'ConnectPageMixin::_deleteTomConfigurations - Success',
      );
    } catch (e) {
      Logs().e(
        'ConnectPageMixin::_deleteTomConfigurations - error: $e',
      );
    }
  }

  Future<void> _deleteFederationConfigurations({
    required MatrixState matrix,
  }) async {
    try {
      final userId = matrix.activatedUserId;
      Logs().d(
        'ConnectPageMixin::_deleteFederationConfigurations - Client ID: $userId',
      );
      await getIt
          .get<FederationConfigurationsRepository>()
          .deleteFederationConfigurations(userId);
      Logs().d(
        'ConnectPageMixin::_deleteFederationConfigurations - Success',
      );
    } catch (e) {
      Logs().e(
        'ConnectPageMixin::_deleteFederationConfigurations - error: $e',
      );
    }
  }

  Future<void> _logoutActionOnOtherPlatform({
    required MatrixState matrix,
  }) async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        try {
          await _clearAndSignOut(matrix: matrix);
        } catch (e) {
          Logs().e(
            'ConnectPageMixin()::_logoutActionOnOtherPlatform - error: $e',
          );
        } finally {
          await tryLogoutSso(matrix: matrix);
        }
      },
    );
  }

  Future<void> _clearAndSignOut({required MatrixState matrix}) async {
    Logs().d('ConnectPageMixin::_clearAndSignOut');
    if (matrix.backgroundPush != null) {
      await matrix.backgroundPush!.removeCurrentPusher();
    }

    await Future.wait([
      matrix.client.logout(),
      _deleteTomConfigurations(matrix: matrix),
      _deleteFederationConfigurations(matrix: matrix),
    ]);
  }
}
