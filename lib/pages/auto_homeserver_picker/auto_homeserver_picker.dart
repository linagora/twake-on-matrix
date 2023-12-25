import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker_view.dart';
import 'package:fluffychat/pages/connect/connect_page_mixin.dart';
import 'package:fluffychat/utils/exception/check_homeserver_exception.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class AutoHomeserverPicker extends StatefulWidget {
  final bool? loggedOut;

  const AutoHomeserverPicker({
    super.key,
    this.loggedOut,
  });

  @override
  State<AutoHomeserverPicker> createState() => AutoHomeserverPickerController();
}

class AutoHomeserverPickerController extends State<AutoHomeserverPicker>
    with ConnectPageMixin {
  static const Duration autoHomeserverPickerTimeout = Duration(seconds: 30);

  final showButtonRetryNotifier = ValueNotifier<bool>(false);

  MatrixState get matrix => Matrix.of(context);

  void _autoCheckHomeserver() async {
    try {
      matrix.loginHomeserverSummary = await matrix
          .getLoginClient()
          .checkHomeserver(
            Uri.parse(AppConfig.homeserver),
          )
          .timeout(
        autoHomeserverPickerTimeout,
        onTimeout: () {
          throw CheckHomeserverTimeoutException();
        },
      );

      final ssoSupported = matrix.loginHomeserverSummary!.loginFlows
          .any((flow) => flow.type == 'm.login.sso');

      try {
        await Matrix.of(context).getLoginClient().register().timeout(
          autoHomeserverPickerTimeout,
          onTimeout: () {
            throw CheckHomeserverTimeoutException();
          },
        );
        matrix.loginRegistrationSupported = true;
      } on MatrixException catch (e) {
        matrix.loginRegistrationSupported = e.requireAdditionalAuthentication;
      }

      if (!ssoSupported && matrix.loginRegistrationSupported == false) {
        // Server does not support SSO or registration. We can skip to login page:
        context.push('/login');
      } else if (ssoSupported && matrix.loginRegistrationSupported == false) {
        Map<String, dynamic>? rawLoginTypes;
        await Matrix.of(context)
            .getLoginClient()
            .request(
              RequestType.GET,
              '/client/r0/login',
            )
            .then((loginTypes) => rawLoginTypes = loginTypes)
            .timeout(
          autoHomeserverPickerTimeout,
          onTimeout: () {
            throw CheckHomeserverTimeoutException();
          },
        );
        final identitiesProvider =
            identityProviders(rawLoginTypes: rawLoginTypes);
        if (supportsSso(context) && identitiesProvider?.length == 1) {
          ssoLoginAction(context: context, id: identitiesProvider!.single.id!);
        }
      } else {
        context.push('/connect');
      }
    } catch (e) {
      showButtonRetryNotifier.toggle();
      Logs().d(
        "AutoHomeserverPickerController: _autoCheckHomeserver: Error: $e",
      );
    }
  }

  void retryCheckHomeserver() {
    showButtonRetryNotifier.toggle();
    _autoCheckHomeserver();
  }

  @override
  void initState() {
    if (widget.loggedOut == null) {
      _autoCheckHomeserver();
    } else {
      if (widget.loggedOut == true) {
        showButtonRetryNotifier.toggle();
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AutoHomeserverPickerView(
      controller: this,
    );
  }
}
