import 'dart:async';

import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/data/account/login_sessions.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/widgets/layouts/agruments/logged_in_body_args.dart';
import 'package:twake_chat/widgets/layouts/agruments/logged_in_other_account_body_args.dart';
import 'package:twake_chat/widgets/twake_app.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:matrix/matrix.dart';

import 'package:twake_chat/utils/localized_exception_extension.dart';
import 'package:twake_chat/pages/login/login_client_owner.dart';
import 'package:twake_chat/widgets/matrix.dart';
import '../../utils/platform_infos.dart';
import 'login_view.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key, this.owner = LoginClientOwner.thisPage});

  /// Whether this screen or the one that pushed it drops the pending client.
  final LoginClientOwner owner;

  @override
  LoginController createState() => LoginController();
}

class LoginController extends ConsumerState<Login> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? usernameError;
  String? passwordError;
  String? loginError;
  bool loading = false;
  bool showPassword = false;
  late Future<Client> loginClientFuture;

  Client? _pendingLoginClient;

  /// The homeserver of the last login try, for the next try after a failure.
  Uri? _loginHomeserver;

  void toggleShowPassword() =>
      setState(() => showPassword = !loading && !showPassword);

  void login() async {
    setState(() => loginError = null);
    if (_pendingLoginClient != null || loading) return;
    if (usernameController.text.isEmpty) {
      setState(() => usernameError = L10n.of(context)!.pleaseEnterYourUsername);
    } else {
      setState(() => usernameError = null);
    }
    if (passwordController.text.isEmpty) {
      setState(() => passwordError = L10n.of(context)!.pleaseEnterYourPassword);
    } else {
      setState(() => passwordError = null);
    }

    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      return;
    }

    setState(() => loading = true);

    TwakeDialog.showLoadingDialog(context);

    _coolDown?.cancel();

    try {
      final username = usernameController.text;
      AuthenticationIdentifier identifier;
      if (username.isEmail) {
        identifier = AuthenticationThirdPartyIdentifier(
          medium: 'email',
          address: username,
        );
      } else if (username.isPhoneNumber) {
        identifier = AuthenticationThirdPartyIdentifier(
          medium: 'msisdn',
          address: username,
        );
      } else {
        identifier = AuthenticationUserIdentifier(user: username);
      }
      Matrix.of(context).loginType = LoginType.mLoginPassword;
      final client = await loginClientFuture;
      // After a failed try the client was signed out and lost its homeserver,
      // and the SDK can clear it again later: give it back right before the
      // login.
      client.homeserver ??= _loginHomeserver;
      _loginHomeserver = client.homeserver;
      _pendingLoginClient = client;
      await _sessions.trackLogin(
        client,
        () => client.login(
          LoginType.mLoginPassword,
          identifier: identifier,
          password: passwordController.text,
          initialDeviceDisplayName: PlatformInfos.clientName,
        ),
      );
    } on MatrixException catch (exception) {
      if (!mounted) return;
      _pendingLoginClient = null;
      TwakeDialog.hideLoadingDialog(context);
      setState(() {
        loginError = exception.errorMessage;
        loading = false;
      });
      return;
    } catch (exception) {
      if (!mounted) return;
      _pendingLoginClient = null;
      TwakeDialog.hideLoadingDialog(context);
      setState(() {
        loginError = exception.toLocalizedString(context);
        loading = false;
      });
      return;
    }

    if (mounted) setState(() => loading = false);
  }

  Timer? _coolDown;

  void checkWellKnownWithCoolDown(String userId) async {
    _coolDown?.cancel();
    _coolDown = Timer(
      const Duration(seconds: 1),
      () => _checkWellKnown(userId),
    );
  }

  final Completer<void> _loginCompleter = Completer<void>();

  void _listenClientLoginStateChanged(ClientLoginStateEvent event) {
    if (!mounted || _loginCompleter.isCompleted) return;
    if (event.client != _pendingLoginClient) return;
    Logs().i(
      'StreamDialogBuilder::_listenClientLoginStateChanged - ${event.multipleAccountLoginType}',
    );
    _pendingLoginClient = null;
    switch (event.multipleAccountLoginType) {
      case MultipleAccountLoginType.loginFailed ||
          MultipleAccountLoginType.cleanupFailed:
        // Not a completed login: the user can try again.
        _handleLoginFailed(event.error);
      case MultipleAccountLoginType.firstLoggedIn:
        _loginCompleter.complete();
        _handleFirstLoggedIn(event.client);
      case MultipleAccountLoginType.otherAccountLoggedIn:
        _loginCompleter.complete();
        _handleAddAnotherAccount(event.client);
    }
  }

  /// The login worked on the server but the account could not be stored and
  /// the login was undone: show why and let the user try again, on a client
  /// that is still usable.
  void _handleLoginFailed(Object? error) {
    if (!mounted) return;
    TwakeDialog.hideLoadingDialog(context);
    setState(() {
      loginClientFuture = _sessions.loginClient();
      loginError =
          error?.toLocalizedString(context) ??
          L10n.of(context)!.oopsSomethingWentWrong;
      loading = false;
    });
  }

  void _handleFirstLoggedIn(Client client) {
    if (!mounted) return;

    TwakeDialog.hideLoadingDialog(context);

    TwakeApp.router.go(
      '/rooms',
      extra: LoggedInBodyArgs(newActiveClient: client),
    );
  }

  void _handleAddAnotherAccount(Client client) {
    if (!mounted) return;

    TwakeDialog.hideLoadingDialog(context);

    TwakeApp.router.go(
      '/rooms',
      extra: LoggedInOtherAccountBodyArgs(newActiveClient: client),
    );
  }

  void _checkWellKnown(String userId) async {
    if (mounted) setState(() => usernameError = null);
    if (!userId.isValidMatrixId) return;
    final client = await loginClientFuture;
    final oldHomeserver = client.homeserver;
    try {
      var newDomain = Uri.https(userId.domain!, '');

      // Use cached discovery from loginHomeserverSummary instead of
      // re-fetching well-known (which fails on domains like twake.app
      // that don't serve .well-known/matrix/client).
      // Only apply when the MXID domain matches the current homeserver
      // (e.g. twake.app ↔ matrix.twake.app), so users entering an MXID
      // from a different server are not silently redirected.
      final mxidDomain = userId.domain!;
      final currentHost = oldHomeserver?.host ?? '';
      final cachedDiscovery = ref
          .read(loginHomeserverSummaryProvider)
          ?.discoveryInformation;
      final cachedBaseUrl =
          cachedDiscovery?.mHomeserver.baseUrl.toString() ?? '';
      if (currentHost.endsWith(mxidDomain) && cachedBaseUrl.isNotEmpty) {
        newDomain = cachedDiscovery!.mHomeserver.baseUrl;
      }

      if (newDomain != oldHomeserver) {
        client.homeserver = newDomain;
        await client.checkHomeserver(newDomain, checkWellKnown: false);

        if (client.homeserver == null) {
          client.homeserver = oldHomeserver;
          // okay, the server we checked does not appear to be a matrix server
          Logs().v(
            '$newDomain is not running a homeserver, asking to use $oldHomeserver',
          );
          final dialogResult = await showOkCancelAlertDialog(
            context: context,
            useRootNavigator: false,
            message: L10n.of(
              context,
            )!.noMatrixServer(newDomain, oldHomeserver!),
            okLabel: L10n.of(context)!.ok,
            cancelLabel: L10n.of(context)!.cancel,
          );
          if (dialogResult == OkCancelResult.ok) {
            if (mounted) setState(() => usernameError = null);
          } else {
            Navigator.of(context, rootNavigator: false).pop();
            return;
          }
        }
        usernameError = null;
        if (mounted) setState(() {});
      } else {
        client.homeserver = oldHomeserver;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      client.homeserver = oldHomeserver;
      usernameError = e.toLocalizedString(context);
      if (mounted) setState(() {});
    }
  }

  static int sendAttempt = 0;

  StreamSubscription? _clientLoginStateChangedSubscription;

  late final LoginSessions _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(loginSessionsProvider);
    loginClientFuture = _sessions.loginClient();
    _clientLoginStateChangedSubscription = Matrix.of(
      context,
    ).onClientLoginStateChanged.stream.listen(_listenClientLoginStateChanged);
  }

  @override
  void dispose() {
    if (widget.owner == LoginClientOwner.thisPage) {
      unawaited(_sessions.discardPending());
    }
    _coolDown?.cancel();
    usernameController.dispose();
    passwordController.dispose();
    _clientLoginStateChangedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LoginView(this);
}

extension on String {
  static final RegExp _phoneRegex = RegExp(
    r'^[+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]{0,20}$',
  );
  static final RegExp _emailRegex = RegExp(r'(.+)@(.+)\.(.+)');

  bool get isEmail => _emailRegex.hasMatch(this);

  bool get isPhoneNumber => _phoneRegex.hasMatch(this);
}
