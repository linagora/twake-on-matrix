import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker_state.dart';
import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker_view.dart';
import 'package:fluffychat/presentation/mixins/connect_page_mixin.dart';
import 'package:fluffychat/presentation/mixins/init_config_mixin.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/exception/homeserver_exception.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    with ConnectPageMixin, InitConfigMixin {
  static const Duration autoHomeserverPickerTimeout = Duration(seconds: 30);

  static const _saasPlatform = 'saas';

  final autoHomeserverPickerUIState = ValueNotifier<AutoHomeServerPickerState>(
    AutoHomeServerPickerInitialState(),
  );

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
      autoHomeserverPickerUIState.value = AutoHomeServerPickerFailureState();
      Logs().d(
        "AutoHomeserverPickerController: _autoCheckHomeserver: Error: $e",
      );
    }
  }

  void retryCheckHomeserver() {
    autoHomeserverPickerUIState.value = AutoHomeServerPickerLoadingState();
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
      try {
        await registerPublicPlatformAction(
          context: context,
          id: identitiesProvider!.single.id!,
        );
      } on HomeserverTokenNotFoundException catch (e) {
        autoHomeserverPickerUIState.value = AutoHomeServerPickerFailureState(
          error: e.toString(),
        );
      } catch (e) {
        autoHomeserverPickerUIState.value = AutoHomeServerPickerFailureState();
      }
    }
  }

  Future<void> _setupAutoHomeserverPicker() async {
    autoHomeserverPickerUIState.value = AutoHomeServerPickerLoadingState();
    if (widget.loggedOut == null) {
      final isConfigured = await AppConfig.initConfigCompleter.future;
      if (!isConfigured) {
        if (!AppConfig.hasReachedMaxRetries) {
          return _setupAutoHomeserverPicker();
        } else {
          autoHomeserverPickerUIState.value =
              AutoHomeServerPickerFailureState();
        }
      }
      Logs().d(
        "AutoHomeserverPickerController::_setupAutoHomeserverPicker: PlatForm ${AppConfig.platform}",
      );
      final loginToken = getQueryParameter('loginToken');
      if (loginToken != null || loginToken?.isNotEmpty == true) {
        Matrix.of(context).loginType = LoginType.mLoginToken;
        Matrix.of(context).loginHomeserverSummary =
            await Matrix.of(context).getLoginClient().checkHomeserver(
                  Uri.parse(
                    AppConfig.homeserver,
                  ),
                );
        final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () => Matrix.of(context).getLoginClient().login(
                LoginType.mLoginToken,
                token: loginToken,
                initialDeviceDisplayName: PlatformInfos.clientName,
              ),
        );
        if (result.error != null) {
          autoHomeserverPickerUIState.value = AutoHomeServerPickerFailureState(
            error: L10n.of(context)!.invalidLoginToken,
          );
          resetLocationPathWithLoginToken(
            route: 'home',
          );
        } else {
          resetLocationPathWithLoginToken();
        }
        return;
      }
      if (_isSaasPlatform) {
        _autoConnectSaas();
      } else {
        _autoConnectHomeserver();
      }
    } else {
      if (widget.loggedOut == true) {
        autoHomeserverPickerUIState.value = AutoHomeServerPickerInitialState();
      }
    }
  }

  @override
  void initState() {
    _setupAutoHomeserverPicker();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    autoHomeserverPickerUIState.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoHomeserverPickerView(
      controller: this,
    );
  }
}
