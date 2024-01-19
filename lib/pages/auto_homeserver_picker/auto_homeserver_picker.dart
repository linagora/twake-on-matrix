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

  static const _saasPlatform = 'saas';

  final showButtonRetryNotifier = ValueNotifier<bool>(false);

  MatrixState get matrix => Matrix.of(context);

  bool get _isSaasPlatform =>
      AppConfig.platform != null &&
      AppConfig.platform!.isNotEmpty &&
      AppConfig.platform == _saasPlatform;

  void _autoConnectHomeserver() async {
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
    if (_isSaasPlatform) {
      _autoConnectSaas();
    } else {
      _autoConnectHomeserver();
    }
  }

  void _autoConnectSaas() async {
    matrix.loginHomeserverSummary =
        await matrix.getLoginClient().checkHomeserver(
              Uri.parse(AppConfig.twakeWorkplaceHomeserver),
            );
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
    final identitiesProvider = identityProviders(rawLoginTypes: rawLoginTypes);
    if (identitiesProvider?.length == 1) {
      registerPublicPlatformAction(
        context: context,
        id: identitiesProvider!.single.id!,
        saasRegistrationErrorCallback: (object) {
          Logs().e(
            "AutoHomeserverPickerController: _saasAutoRegistration: Error - $object",
          );
        },
        saasRegistrationTimeoutCallback: () {
          Logs().e(
            "AutoHomeserverPickerController: _saasAutoRegistration: Timeout",
          );
        },
      );
    }
  }

  void _setupAutoHomeserverPicker() {
    if (widget.loggedOut == null) {
      Logs().d(
        "AutoHomeserverPickerController: _initializeAutoHomeserverPicker: PlatForm ${AppConfig.platform}",
      );
      if (_isSaasPlatform) {
        _autoConnectSaas();
      } else {
        _autoConnectHomeserver();
      }
    } else {
      if (widget.loggedOut == true) {
        showButtonRetryNotifier.toggle();
      }
    }
  }

  @override
  void initState() {
    _setupAutoHomeserverPicker();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AutoHomeserverPickerView(
      controller: this,
    );
  }
}
