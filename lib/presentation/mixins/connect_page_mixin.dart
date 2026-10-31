import 'package:twake_chat/utils/login_failed_snackbar.dart';
import 'package:twake_chat/data/account/login_sessions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/pages/connect/connect_page.dart';
import 'package:twake_chat/pages/connect/sso_login_state.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/domain/account/entities/client_login_state_event.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:twake_chat/widgets/matrix.dart';
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

  LoginSessions _sessionsOf(BuildContext context) => ProviderScope.containerOf(
    context,
    listen: false,
  ).read(loginSessionsProvider);

  bool supportsFlow({
    required BuildContext context,
    required String flowType,
  }) =>
      ProviderScope.containerOf(context, listen: false)
          .read(loginHomeserverSummaryProvider)
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
    final queryParams = Uri.parse(
      html.window.location.href,
      questionMarkIndex,
    ).queryParameters;
    return queryParams[key];
  }

  bool get homeserverIsConfigured =>
      AppConfig.homeserver != AppConfig.sampleValue ||
      AppConfig.homeserver.isNotEmpty;

  static String _getRedirectUrlScheme(String redirectUrl) {
    return Uri.parse(redirectUrl).scheme;
  }

  static String _getAuthenticateUrl({
    required String homeserver,
    required String id,
    required String redirectUrl,
  }) {
    final normalizedHomeserver = homeserver.replaceFirst(RegExp(r'/*$'), '');
    final ssoRedirectUri =
        '$normalizedHomeserver/_matrix/client/r0/login/sso/redirect/${Uri.encodeComponent(id)}';
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

  String? _getLogoutUrl(BuildContext context) {
    final authUrl = Matrix.of(context).authUrl;
    if (authUrl == null) return null;

    return '$authUrl?logout=1';
  }

  Future<String> authenticateWithWebAuth({
    required BuildContext context,
    required String id,
  }) async {
    final client = await _sessionsOf(context).loginClient();
    final homeserver = client.homeserver?.toString() ?? '';
    if (homeserver.isEmpty) {
      throw StateError('Homeserver is not configured for SSO');
    }
    return webAuthenticate(homeserver: homeserver, id: id);
  }

  /// Runs the SSO flow of [homeserver] with the identity provider [id] and
  /// returns the callback URL, which carries the `loginToken`.
  static Future<String> webAuthenticate({
    required String homeserver,
    required String id,
  }) {
    final redirectUrl = _generateRedirectUrl(homeserver);
    final url = _getAuthenticateUrl(
      homeserver: homeserver,
      id: id,
      redirectUrl: redirectUrl,
    );
    return FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: _getRedirectUrlScheme(redirectUrl),
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
      if (token == null || token.isEmpty) return SsoLoginState.tokenEmpty;
      Matrix.of(context).loginType = LoginType.mLoginToken;
      final client = await _sessionsOf(context).loginClient();
      return await loginWithToken(
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(loginSessionsProvider),
        client,
        token,
      );
    } catch (e) {
      Logs().e('ConnectPageMixin:: ssoLoginActionMobil(): error: $e');
      return SsoLoginState.error;
    }
  }

  Future<void> tryLogoutSso(BuildContext context) async {
    if (Matrix.of(context).loginType != LoginType.mLoginToken) return;
    final redirectUrl = _generatePostLogoutRedirectUrl();
    final url = _getLogoutUrl(context);
    if (url == null) return Future.value();

    final urlScheme = _getRedirectUrlScheme(redirectUrl);
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: urlScheme,
        options: const FlutterWebAuth2Options(windowName: windowNameValue),
      );
      Logs().d('tryLogoutSso::result: $result');
    } catch (e) {
      Logs().d('tryLogoutSso::error: $e');
      rethrow;
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

  static String _generateRedirectUrl(String homeserver) {
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

    final flows = loginTypes.tryGetList('flows');
    if (flows == null) return null;

    try {
      final ssoFlow = flows.singleWhere(
        (flow) => flow['type'] == AuthenticationTypes.sso,
      );

      final rawProviders = ssoFlow['identity_providers'];

      // If no identity_providers field, return a generic SSO provider
      if (rawProviders == null) {
        return [];
      }

      final list = (rawProviders as List)
          .map((json) => IdentityProvider.fromJson(json))
          .toList();
      if (PlatformInfos.isCupertinoStyle) {
        list.sort((a, b) => a.brand == 'apple' ? -1 : 1);
      }
      return list;
    } catch (e) {
      // No SSO flow found or other error
      return null;
    }
  }

  /// Logs in with [token] in the full screen dialog. When the login worked on
  /// the server but the account could not be stored, the login was undone: the
  /// user is told and the result is an error, so they can try again.
  @visibleForTesting
  Future<SsoLoginState> loginWithToken(
    LoginSessions sessions,
    Client client,
    String token,
  ) async {
    final dialogResult = await TwakeDialog.showStreamDialogFullScreen(
      future: () async => sessions.trackLogin(
        client,
        () => client.login(
          LoginType.mLoginToken,
          token: token,
          initialDeviceDisplayName: PlatformInfos.clientName,
        ),
      ),
    );
    if (dialogResult is! ClientLoginStateEvent ||
        !dialogResult.multipleAccountLoginType.isFailure) {
      return SsoLoginState.success;
    }
    showLoginFailedSnackBar(dialogResult.error);
    return SsoLoginState.error;
  }

  Future<SsoLoginState> handleTokenFromRegistrationSite({
    required MatrixState matrix,
    required LoginSessions sessions,
    required String uri,
  }) async {
    try {
      final token = Uri.parse(uri).queryParameters['loginToken'];
      Logs().d("ConnectPageMixin: handleTokenFromRegistrationSite: got token");
      if (token == null || token.isEmpty == true) {
        return SsoLoginState.tokenEmpty;
      }
      matrix.loginType = LoginType.mLoginToken;
      final client = await sessions.loginClient();
      return await loginWithToken(sessions, client, token);
    } catch (e) {
      Logs().e(
        'ConnectPageMixin:: handleTokenFromRegistrationSite(): error: $e',
      );
      return SsoLoginState.error;
    }
  }

  void resetLocationPathWithLoginToken({String? route}) {
    final loginTokenExisted = getQueryParameter('loginToken') != null;
    if (!loginTokenExisted) return;
    html.window.history.replaceState(
      {},
      '',
      '${html.window.location.href.getBaseUrlBeforeHash()}#/${route ?? 'rooms'}',
    );
  }
}
