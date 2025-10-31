import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/sign_up/signup_view.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:go_router/go_router.dart';
import '../../utils/localized_exception_extension.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageController createState() => SignupPageController();
}

class SignupPageController extends State<SignupPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController password2Controller = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? error;
  bool loading = false;
  bool showPassword = false;
  bool noEmailWarningConfirmed = false;
  bool displaySecondPasswordField = false;

  static const int minPassLength = 8;

  void toggleShowPassword() => setState(() => showPassword = !showPassword);

  String? get domain => GoRouterState.of(context).pathParameters['domain'];

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void onPasswordType(String text) {
    if (text.length >= minPassLength && !displaySecondPasswordField) {
      setState(() {
        displaySecondPasswordField = true;
      });
    }
  }

  String? password1TextFieldValidator(String? value) {
    if (value!.isEmpty) {
      return L10n.of(context)!.chooseAStrongPassword;
    }
    if (value.length < minPassLength) {
      return L10n.of(context)!
          .pleaseChooseAtLeastChars(minPassLength.toString());
    }
    return null;
  }

  String? password2TextFieldValidator(String? value) {
    if (value!.isEmpty) {
      return L10n.of(context)!.repeatPassword;
    }
    if (value != passwordController.text) {
      return L10n.of(context)!.passwordsDoNotMatch;
    }
    return null;
  }

  String? emailTextFieldValidator(String? value) {
    if (value!.isEmpty && !noEmailWarningConfirmed) {
      noEmailWarningConfirmed = true;
      return L10n.of(context)!.noEmailWarning;
    }
    if (value.isNotEmpty && !value.contains('@')) {
      return L10n.of(context)!.pleaseEnterValidEmail;
    }
    return null;
  }

  void signup([_]) async {
    setState(() {
      error = null;
    });
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    try {
      final client = Matrix.of(context).getLoginClient();
      final email = emailController.text;
      if (email.isNotEmpty) {
        Matrix.of(context).currentClientSecret =
            DateTime.now().millisecondsSinceEpoch.toString();
        Matrix.of(context).currentThreepidCreds =
            await client.requestTokenToRegisterEmail(
          Matrix.of(context).currentClientSecret,
          email,
          0,
        );
      }

      final displayname = Matrix.of(context).loginUsername!;
      final localPart = displayname.toLowerCase().replaceAll(' ', '_');

      await client.uiaRequestBackground(
        (auth) => client.register(
          username: localPart,
          password: passwordController.text,
          initialDeviceDisplayName: PlatformInfos.clientName,
          auth: auth,
        ),
      );
      // Set displayname
      if (displayname != localPart) {
        await client.setProfileField(
          client.userID!,
          'displayname',
          {'displayname': displayname},
        );
      }
    } catch (e) {
      error = (e).toLocalizedString(context);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SignupPageView(this);
}
