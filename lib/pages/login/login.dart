import 'dart:async';

import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../utils/platform_infos.dart';
import 'login_view.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginController createState() => LoginController();
}

class LoginController extends State<Login> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? usernameError;
  String? passwordError;
  bool loading = false;
  bool showPassword = false;
  late final Future<Client> loginClientFuture;

  void toggleShowPassword() =>
      setState(() => showPassword = !loading && !showPassword);

  void login() async {
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
      await client.login(
        LoginType.mLoginPassword,
        identifier: identifier,
        // To stay compatible with older server versions
        // ignore: deprecated_member_use
        user: identifier.type == AuthenticationIdentifierTypes.userId
            ? username
            : null,
        password: passwordController.text,
        initialDeviceDisplayName: PlatformInfos.clientName,
      );
    } on MatrixException catch (exception) {
      setState(() => passwordError = exception.errorMessage);
      return setState(() => loading = false);
    } catch (exception) {
      setState(() => passwordError = exception.toString());
      return setState(() => loading = false);
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

  void _checkWellKnown(String userId) async {
    if (mounted) setState(() => usernameError = null);
    if (!userId.isValidMatrixId) return;
    final client = await loginClientFuture;
    final oldHomeserver = client.homeserver;
    try {
      var newDomain = Uri.https(userId.domain!, '');
      client.homeserver = newDomain;
      DiscoveryInformation? wellKnownInformation;
      try {
        wellKnownInformation = await client.getWellknown();
        if (wellKnownInformation.mHomeserver.baseUrl.toString().isNotEmpty) {
          newDomain = wellKnownInformation.mHomeserver.baseUrl;
        }
      } catch (_) {
        // do nothing, newDomain is already set to a reasonable fallback
      }
      if (newDomain != oldHomeserver) {
        await client.checkHomeserver(newDomain);

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

  void passwordForgotten() async {
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.passwordForgotten,
      message: L10n.of(context)!.enterAnEmailAddress,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      fullyCapitalizedForMaterial: false,
      textFields: [
        DialogTextField(
          initialText: usernameController.text.isEmail
              ? usernameController.text
              : '',
          hintText: L10n.of(context)!.enterAnEmailAddress,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
    if (input == null) return;
    final client = await loginClientFuture;
    final clientSecret = DateTime.now().millisecondsSinceEpoch.toString();
    final response = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => client.requestTokenToResetPasswordEmail(
        clientSecret,
        input.single,
        sendAttempt++,
      ),
    );
    if (response.error != null) return;
    final password = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.passwordForgotten,
      message: L10n.of(context)!.chooseAStrongPassword,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      fullyCapitalizedForMaterial: false,
      textFields: [
        const DialogTextField(
          hintText: '******',
          obscureText: true,
          minLines: 1,
          maxLines: 1,
        ),
      ],
    );
    if (password == null) return;
    final ok = await showOkAlertDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.weSentYouAnEmail,
      message: L10n.of(context)!.pleaseClickOnLink,
      okLabel: L10n.of(context)!.iHaveClickedOnLink,
      fullyCapitalizedForMaterial: false,
    );
    if (ok != OkCancelResult.ok) return;
    final data = <String, dynamic>{
      'new_password': password.single,
      'logout_devices': false,
      "auth": AuthenticationThreePidCreds(
        type: AuthenticationTypes.emailIdentity,
        threepidCreds: ThreepidCreds(
          sid: response.result!.sid,
          clientSecret: clientSecret,
        ),
      ).toJson(),
    };
    final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => client.request(
        RequestType.POST,
        '/client/r0/account/password',
        data: data,
      ),
    );
    if (success.error == null) {
      TwakeSnackBar.show(context, L10n.of(context)!.passwordHasBeenChanged);
      usernameController.text = input.single;
      passwordController.text = password.single;
      login();
    }
  }

  static int sendAttempt = 0;

  @override
  void initState() {
    super.initState();
    loginClientFuture = Matrix.of(context).getLoginClient();
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
