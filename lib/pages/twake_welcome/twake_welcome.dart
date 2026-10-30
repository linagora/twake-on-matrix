import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/account/login_sessions.dart';
import 'package:equatable/equatable.dart';
import 'package:twake_chat/presentation/mixins/connect_page_mixin.dart';
import 'package:twake_chat/pages/twake_welcome/twake_welcome_view.dart';
import 'package:twake_chat/utils/client_manager.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:matrix/matrix.dart';

enum TwakeWelcomeType { firstAccount, otherAccounts }

class TwakeWelcomeArg extends Equatable {
  final TwakeWelcomeType twakeIdType;

  const TwakeWelcomeArg({this.twakeIdType = TwakeWelcomeType.firstAccount});

  bool get isAddAnotherAccount => twakeIdType == TwakeWelcomeType.otherAccounts;

  @override
  List<Object?> get props => [twakeIdType];
}

class TwakeWelcome extends ConsumerStatefulWidget {
  final TwakeWelcomeArg? arg;

  const TwakeWelcome({super.key, this.arg});

  @override
  ConsumerState<TwakeWelcome> createState() => TwakeWelcomeController();
}

class TwakeWelcomeController extends ConsumerState<TwakeWelcome>
    with ConnectPageMixin {
  void goToHomeserverPicker() {
    if (widget.arg != null && widget.arg?.isAddAnotherAccount == true) {
      const AddAccountHomeserverPickerRoute().push(context);
    } else {
      const HomeHomeserverPickerRoute().push(context);
    }
  }

  static const String postLoginRedirectUrlPathParams =
      'post_login_redirect_url';

  static const String postRegisteredRedirectUrlPathParams =
      'post_registered_redirect_url';

  String get loginUrl =>
      "${AppConfig.registrationUrl}?$postLoginRedirectUrlPathParams=${AppConfig.appOpenUrlScheme}://redirect&app=${AppConfig.appParameter}";

  String get signupUrl =>
      "${AppConfig.registrationUrl}?$postRegisteredRedirectUrlPathParams=${AppConfig.appOpenUrlScheme}://redirect&app=${AppConfig.appParameter}";

  MatrixState get matrix => Matrix.of(context);

  late final LoginSessions _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(loginSessionsProvider);
  }

  @override
  void dispose() {
    // Leaving the welcome screen drops a login client that did not log in.
    unawaited(_sessions.discardPending());
    super.dispose();
  }

  void onClickSignIn() {
    Logs().d("TwakeIdController::onClickSignIn: Login Url - $loginUrl");
    unawaited(_redirectRegistrationUrl(loginUrl));
  }

  Future<void> _redirectRegistrationUrl(String url) async {
    try {
      TwakeDialog.showLoadingTwakeWelcomeDialog(context);
      final homeserverExisted = await _homeserverExisted();
      if (!mounted) return;
      if (homeserverExisted) {
        TwakeDialog.hideLoadingDialog(context);
        return;
      }
      final sessions = _sessions;
      final client = await sessions.loginClient();
      final summary = await client
          .checkHomeserver(Uri.parse(AppConfig.twakeWorkplaceHomeserver))
          .toHomeserverSummary();
      if (!mounted) return;
      ref.read(loginHomeserverSummaryProvider.notifier).set(summary);
      final uri = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: AppConfig.appOpenUrlScheme,
        options: const FlutterWebAuth2Options(
          intentFlags: ephemeralIntentFlags,
        ),
      );
      Logs().d("TwakeIdController:_redirectRegistrationUrl: URI - $uri");
      if (!mounted) return;
      await handleTokenFromRegistrationSite(
        matrix: matrix,
        sessions: sessions,
        uri: uri,
      );
      Logs().d("TwakeIdController:_redirectRegistrationUrl: DONE");
      if (!mounted) return;
      TwakeDialog.hideLoadingDialog(context);
    } catch (e) {
      Logs().e("TwakeIdController::_redirectRegistrationUrl: $e");
      // Cancelled or failed: the login client of this attempt is dropped.
      unawaited(_sessions.discardPending());
      if (!mounted) return;
      TwakeDialog.hideLoadingDialog(context);
    }
  }

  void onClickCreateTwakeId() {
    Logs().d(
      "TwakeIdController::onClickCreateTwakeId: Signup Url - $signupUrl",
    );
    unawaited(_redirectRegistrationUrl(signupUrl));
  }

  Future<bool> _homeserverExisted() async {
    if (widget.arg != null && widget.arg?.isAddAnotherAccount == false) {
      return false;
    }
    try {
      final allHomeserverLoggedIn =
          ClientManager.loggedIn(await ClientManager.getClients())
              .where((client) => client.homeserver != null)
              .map((client) => client.homeserver.toString())
              .toList();
      Logs().i('All homeservers: $allHomeserverLoggedIn');
      final homeserverExists = allHomeserverLoggedIn.any(
        (homeserver) => "$homeserver/".contains(AppConfig.homeserver),
      );

      if (homeserverExists &&
          !AppConfig.supportMultipleAccountsInTheSameHomeserver) {
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.isSingleAccountOnHomeserver,
        );
        return true;
      }
    } catch (e) {
      Logs().e('TwakeIdController::_homeserverExisted: $e');
      return false;
    }
    return false;
  }

  void onClickPrivacyPolicy() {
    UrlLauncher(context, url: AppConfig.privacyUrl).openUrlInAppBrowser();
  }

  @override
  Widget build(BuildContext context) {
    return TwakeWelcomeView(controller: this);
  }
}
