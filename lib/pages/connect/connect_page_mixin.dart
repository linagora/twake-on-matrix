import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:universal_html/html.dart' as html;

mixin ConnectPageMixin {
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

  void ssoLoginAction({
    required BuildContext context,
    required String id,
  }) async {
    final redirectUrl = kIsWeb
        ? '${html.window.origin!}/web/auth.html'
        : '${AppConfig.appOpenUrlScheme.toLowerCase()}://login';
    final url = _getAuthenticateUrl(
      context: context,
      id: id,
      redirectUrl: redirectUrl,
    );
    final urlScheme = _getRedirectUrlScheme(redirectUrl);
    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme: urlScheme,
    );
    final token = Uri.parse(result).queryParameters['loginToken'];
    if (token?.isEmpty ?? false) return;

    await showFutureLoadingDialog(
      context: context,
      future: () => Matrix.of(context).getLoginClient().login(
            LoginType.mLoginToken,
            token: token,
            initialDeviceDisplayName: PlatformInfos.clientName,
          ),
    );
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
}
