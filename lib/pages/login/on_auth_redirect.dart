import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/presentation/mixins/connect_page_mixin.dart';
import 'package:fluffychat/presentation/model/client_login_state_event.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_body_args.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluffychat/config/go_routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';

class OnAuthRedirect extends StatefulWidget {
  const OnAuthRedirect({super.key});

  @override
  State<OnAuthRedirect> createState() => _OnAuthRedirectState();
}

class _OnAuthRedirectState extends State<OnAuthRedirect> with ConnectPageMixin {
  Client? _clientFirstLoggedIn;

  StreamSubscription? _clientLoginStateChangedSubscription;

  @override
  void initState() {
    super.initState();
    _clientLoginStateChangedSubscription = Matrix.of(
      context,
    ).onClientLoginStateChanged.stream.listen(_listenClientLoginStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryLoggingUsingToken(context: context);
    });
  }

  @override
  void dispose() {
    _clientLoginStateChangedSubscription?.cancel();
    super.dispose();
  }

  void _listenClientLoginStateChanged(ClientLoginStateEvent event) {
    Logs().i(
      'StreamDialogBuilder::_listenClientLoginStateChanged - ${event.multipleAccountLoginType}',
    );
    if (!mounted) return;
    if (event.multipleAccountLoginType ==
        MultipleAccountLoginType.firstLoggedIn) {
      _clientFirstLoggedIn = event.client;
      _handleLoginSuccess();
      return;
    }
  }

  void _handleLoginSuccess() {
    Logs().i('OnAuthRedirect::_handleLoginSuccess');
    if (!context.mounted) return;
    if (_clientFirstLoggedIn != null) {
      context.go(
        '/rooms',
        extra: LoggedInBodyArgs(newActiveClient: _clientFirstLoggedIn),
      );
    } else {
      const HomeRoute().go(context);
    }
  }

  void _handleLoginError(Object? error, StackTrace stackTrace) {
    Logs().wtf(
      'OnAuthRedirect::_handleLoginError [Exception]',
      error,
      stackTrace,
    );
    if (!mounted) return;
    const HomeRoute().go(context);
  }

  Future<void> tryLoggingUsingToken({required BuildContext context}) async {
    // Read route params SYNCHRONOUSLY before any await — GoRouterState
    // must not be accessed after an async gap (inherited widget anti-pattern).
    // AppConfig.homeserver must NOT be captured here on web: on a fresh
    // /auth.html load after SSO, config.json may not have loaded yet, so
    // it would still be the default sample value. Resolve it after the
    // initConfigCompleter await below.
    final String? loginToken;
    final String? homeserverFromRoute;

    if (PlatformInfos.isWeb) {
      loginToken = getQueryParameter('loginToken');
      homeserverFromRoute = null;
    } else {
      final routeParams = GoRouterState.of(context).uri.queryParameters;
      loginToken = routeParams['loginToken'];
      homeserverFromRoute = routeParams['homeserver'];
    }

    if (loginToken == null || loginToken.isEmpty) {
      _handleLoginError(
        Exception('tryLoggingUsingToken(): Missing loginToken'),
        StackTrace.current,
      );
      return;
    }

    try {
      final isConfigured = await AppConfig.initConfigCompleter.future;
      if (!isConfigured) {
        if (!AppConfig.hasReachedMaxRetries) {
          tryLoggingUsingToken(context: context);
        } else {
          throw Exception('tryLoggingUsingToken(): Config not found');
        }
        return;
      }

      // Resolve homeserver AFTER initConfig: AppConfig.homeserver is now populated.
      // Route param takes precedence (tests, non-standard deployments);
      // fallback to AppConfig for standard mobile SSO where the deep link omits it.
      final homeserver =
          homeserverFromRoute ??
          (homeserverIsConfigured ? AppConfig.homeserver : '');

      if (homeserver.isEmpty) {
        _handleLoginError(
          Exception('tryLoggingUsingToken(): Missing homeserver'),
          StackTrace.current,
        );
        return;
      }

      if (!context.mounted) return;
      Logs().i('tryLoggingUsingToken::homeserver: $homeserver');
      Matrix.of(context).loginType = LoginType.mLoginToken;
      final client = await Matrix.of(context).getLoginClient();
      if (!context.mounted) return;
      Matrix.of(context).loginHomeserverSummary = await client
          .checkHomeserver(Uri.parse(homeserver))
          .toHomeserverSummary();

      await client.login(
        LoginType.mLoginToken,
        token: loginToken,
        initialDeviceDisplayName: PlatformInfos.clientName,
      );
    } catch (e, s) {
      _handleLoginError(e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CupertinoActivityIndicator(
          animating: true,
          color: LinagoraSysColors.material().onSurfaceVariant,
        ),
      ),
    );
  }
}
