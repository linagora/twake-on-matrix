import 'dart:async';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/presentation/mixins/connect_page_mixin.dart';
import 'package:fluffychat/pages/connect/sso_login_state.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_state.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_homeserver_recommendations/matrix_homeserver_recommendations.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_bottom_sheet.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../utils/localized_exception_extension.dart';

import 'package:fluffychat/utils/tor_stub.dart'
    if (dart.library.html) 'package:tor_detector_web/tor_detector_web.dart';

class HomeserverPicker extends StatefulWidget {
  const HomeserverPicker({super.key});

  @override
  HomeserverPickerController createState() => HomeserverPickerController();
}

class HomeserverPickerController extends State<HomeserverPicker>
    with ConnectPageMixin {
  HomeserverState state = HomeserverState.ssoLoginServer;
  final TextEditingController homeserverController = TextEditingController(
    text: AppConfig.defaultHomeserver,
  );
  final FocusNode homeserverFocusNode = FocusNode();
  String? error;
  List<HomeserverBenchmarkResult>? benchmarkResults;
  bool displayServerList = false;

  bool get loadingHomeservers =>
      AppConfig.allowOtherHomeservers && benchmarkResults == null;
  String searchTerm = '';

  bool isTorBrowser = false;

  Future<void> _checkTorBrowser() async {
    if (!kIsWeb) return;

    Hive.openBox('test').then((value) => null).catchError(
      (e, s) async {
        await showOkAlertDialog(
          context: context,
          title: L10n.of(context)!.indexedDbErrorTitle,
          message: L10n.of(context)!.indexedDbErrorLong,
          onWillPop: () async => false,
        );
        _checkTorBrowser();
      },
    );

    final isTor = await TorBrowserDetector.isTorBrowser;
    isTorBrowser = isTor;
  }

  void _updateFocus() {
    if (benchmarkResults == null) loadHomeserverList();
    if (homeserverFocusNode.hasFocus) {
      setState(() {
        displayServerList = true;
      });
    }
  }

  void showServerInfo(HomeserverBenchmarkResult server) =>
      showAdaptiveBottomSheet(
        context: context,
        builder: (_) => HomeserverBottomSheet(
          homeserver: server,
        ),
      );

  void onChanged(String text) => setState(() {
        searchTerm = text;
      });

  List<HomeserverBenchmarkResult> filteredHomeservers(String searchTerm) {
    return benchmarkResults!
        .where(
          (element) =>
              element.homeserver.baseUrl.host.contains(searchTerm) ||
              (element.homeserver.description?.contains(searchTerm) ?? false),
        )
        .toList();
  }

  void loadHomeserverList() async {
    try {
      final homeserverList =
          await const JoinmatrixOrgParser().fetchHomeservers();
      final benchmark = await HomeserverListProvider.benchmarkHomeserver(
        homeserverList,
        timeout: const Duration(seconds: 10),
      );
      if (!mounted) return;
      setState(() {
        benchmarkResults = benchmark;
      });
    } catch (e, s) {
      Logs().e('Homeserver benchmark failed', e, s);
      benchmarkResults = [];
    }
  }

  void setServer(String server) => setState(() {
        homeserverController.text = server;
        searchTerm = '';
        homeserverFocusNode.unfocus();
        displayServerList = false;
      });

  /// Starts an analysis of the given homeserver. It uses the current domain and
  /// makes sure that it is prefixed with https. Then it searches for the
  /// well-known information and forwards to the login page depending on the
  /// login type.
  Future<void> checkHomeserverAction() async {
    setState(() {
      homeserverFocusNode.unfocus();
      error = null;
      state = HomeserverState.loading;
      displayServerList = false;
    });

    try {
      homeserverController.text =
          homeserverController.text.trim().toLowerCase().replaceAll(' ', '-');
      var homeserver = Uri.parse(homeserverController.text);
      if (homeserver.scheme.isEmpty) {
        homeserver = Uri.https(homeserverController.text, '');
      }
      final matrix = Matrix.of(context);
      final allHomeserverLoggedIn = (await ClientManager.getClients())
          .map((client) => client.homeserver.toString())
          .toList();
      Logs().i('All homeservers: $allHomeserverLoggedIn');
      final homeserverExists =
          allHomeserverLoggedIn.contains(homeserver.toString());

      if (homeserverExists &&
          !AppConfig.supportMultipleAccountsInTheSameHomeserver) {
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.isSingleAccountOnHomeserver,
        );
        state = HomeserverState.wrongServerName;
        return;
      }

      matrix.loginHomeserverSummary =
          await matrix.getLoginClient().checkHomeserver(homeserver);
      final ssoSupported = matrix.loginHomeserverSummary!.loginFlows
          .any((flow) => flow.type == 'm.login.sso');

      try {
        await Matrix.of(context).getLoginClient().register();
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
            .then((loginTypes) => rawLoginTypes = loginTypes);
        final identitiesProvider =
            identityProviders(rawLoginTypes: rawLoginTypes);

        if (supportsSso(context) && identitiesProvider?.length == 1) {
          final result = await ssoLoginAction(
            context: context,
            id: identitiesProvider!.single.id!,
          );
          if (result == SsoLoginState.error) {
            state = HomeserverState.ssoLoginServer;
          }
        }
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {});
      } else {
        state = HomeserverState.otherLoginMethod;
        context.push('/connect');
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {});
      }
    } catch (e) {
      state = HomeserverState.wrongServerName;
      setState(() => error = (e).toLocalizedString(context));
    }
  }

  void loginButtonPressed() async {
    _unfocusNodeHomeserver();
    switch (state) {
      case HomeserverState.ssoLoginServer:
        await checkHomeserverAction();
        break;
      case HomeserverState.wrongServerName:
        await checkHomeserverAction();
        break;
      default:
        await checkHomeserverAction();
        break;
    }
    setState(() {});
  }

  void _unfocusNodeHomeserver() {
    if (homeserverFocusNode.hasFocus) {
      homeserverFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    homeserverFocusNode.removeListener(_updateFocus);
    homeserverFocusNode.dispose();
    homeserverController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    homeserverFocusNode.addListener(_updateFocus);
    _checkTorBrowser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: state != HomeserverState.loading,
      child: HomeserverPickerView(this),
    );
  }

  Future<void> restoreBackup() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    final file = picked?.files.firstOrNull;
    if (file == null) return;
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        try {
          final client = Matrix.of(context).getLoginClient();
          await client.importDump(String.fromCharCodes(file.bytes!));
          Matrix.of(context).initMatrix();
        } catch (e, s) {
          Logs().e('Future error:', e, s);
        }
      },
    );
  }
}
