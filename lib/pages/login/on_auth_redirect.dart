import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/presentation/mixins/connect_page_mixin.dart';
import 'package:fluffychat/presentation/model/client_login_state_event.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_body_args.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
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
    _clientLoginStateChangedSubscription =
        Matrix.of(context).onClientLoginStateChanged.stream.listen(
              _listenClientLoginStateChanged,
            );
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
    if (event.multipleAccountLoginType ==
        MultipleAccountLoginType.firstLoggedIn) {
      _clientFirstLoggedIn = event.client;
      _handleLoginSuccess();
      return;
    }
  }

  void _handleLoginSuccess() {
    Logs().i('OnAuthRedirect::_handleLoginSuccess');
    if (_clientFirstLoggedIn != null) {
      context.go(
        '/rooms',
        extra: LoggedInBodyArgs(
          newActiveClient: _clientFirstLoggedIn,
        ),
      );
    } else {
      context.go('/home');
    }
  }

  void _handleLoginError(Object? error) {
    Logs().e('OnAuthRedirect::_handleLoginError - $error');
    context.go('/home');
  }

  Future<void> tryLoggingUsingToken({
    required BuildContext context,
  }) async {
    try {
      final isConfigured = await AppConfig.initConfigCompleter.future;
      if (!isConfigured) {
        if (!AppConfig.hasReachedMaxRetries) {
          tryLoggingUsingToken(context: context);
        } else {
          throw Exception(
            'tryLoggingUsingToken(): Config not found',
          );
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

      await Matrix.of(context).getLoginClient().login(
            LoginType.mLoginToken,
            token: loginToken,
            initialDeviceDisplayName: PlatformInfos.clientName,
          );
    } catch (e) {
      _handleLoginError(e);
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
