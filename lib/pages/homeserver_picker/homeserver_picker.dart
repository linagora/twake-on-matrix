import 'dart:async';

import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/pages/login/login_client_owner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:twake_chat/data/account/login_sessions.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/presentation/mixins/connect_page_mixin.dart';
import 'package:twake_chat/pages/connect/sso_login_state.dart';
import 'package:twake_chat/pages/homeserver_picker/homeserver_state.dart';
import 'package:twake_chat/utils/client_manager.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_homeserver_recommendations/matrix_homeserver_recommendations.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/pages/homeserver_picker/homeserver_bottom_sheet.dart';
import 'package:twake_chat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:twake_chat/utils/adaptive_bottom_sheet.dart';
import 'package:twake_chat/widgets/matrix.dart';
import '../../utils/localized_exception_extension.dart';

import 'package:twake_chat/utils/tor_stub.dart'
    if (dart.library.html) 'package:tor_detector_web/tor_detector_web.dart';

enum HomeserverPickerType { singleAccount, multiAccount }

class HomeserverPickerArg {
  final HomeserverPickerType type;

  const HomeserverPickerArg({required this.type});
}

class HomeserverPicker extends ConsumerStatefulWidget {
  final HomeserverPickerArg arg;

  const HomeserverPicker({super.key, required this.arg});

  @override
  HomeserverPickerController createState() => HomeserverPickerController();
}

class HomeserverPickerController extends ConsumerState<HomeserverPicker>
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

    Hive.openBox('test').then((value) => null).catchError((e, s) async {
      await showOkAlertDialog(
        context: context,
        title: L10n.of(context)!.indexedDbErrorTitle,
        message: L10n.of(context)!.indexedDbErrorLong,
        onWillPop: () async => false,
      );
      _checkTorBrowser();
    });

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
        builder: (_) => HomeserverBottomSheet(homeserver: server),
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
      final homeserverList = await const JoinmatrixOrgParser()
          .fetchHomeservers();
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
      homeserverController.text = homeserverController.text
          .trim()
          .toLowerCase()
          .replaceAll(' ', '-');
      var homeserver = Uri.parse(homeserverController.text);
      if (homeserver.scheme.isEmpty) {
        homeserver = Uri.https(homeserverController.text, '');
      }
      final matrix = Matrix.of(context);
      final allHomeserverLoggedIn = ClientManager.loggedIn(
        await ClientManager.getClients(),
      ).map((client) => client.homeserver.toString()).toList();
      Logs().i('All homeservers: $allHomeserverLoggedIn');
      final client = await _sessions.loginClient();

      final homeserverSummary = await client.checkHomeserver(homeserver);

      final homeserverFromSummary =
          homeserverSummary.$1?.mHomeserver.baseUrl.toString() ?? '';

      final cleanHomeserver = homeserverFromSummary.endsWith('/')
          ? homeserverFromSummary.substring(0, homeserverFromSummary.length - 1)
          : homeserverFromSummary;

      final homeserverExists = allHomeserverLoggedIn.contains(
        cleanHomeserver.toString(),
      );

      if (homeserverExists &&
          !AppConfig.supportMultipleAccountsInTheSameHomeserver) {
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.isSingleAccountOnHomeserver,
        );
        state = HomeserverState.wrongServerName;
        return;
      }

      final summary = HomeserverSummary(
        discoveryInformation: homeserverSummary.$1,
        versions: homeserverSummary.$2,
        loginFlows: homeserverSummary.$3,
      );
      ref.read(loginHomeserverSummaryProvider.notifier).set(summary);
      final ssoSupported = summary.supportSSOLogin;

      try {
        await client
            .register(inhibitLogin: true)
            .timeout(const Duration(seconds: 30));
        matrix.loginRegistrationSupported = true;
      } on MatrixException catch (e) {
        matrix.loginRegistrationSupported = e.requireAdditionalAuthentication;
      } catch (e) {
        Logs().w('Registration check failed', e);
        matrix.loginRegistrationSupported = false;
      }

      if (!ssoSupported) {
        // No SSO: go straight to password login page
        handlePasswordLogin();
      } else if (ssoSupported && matrix.loginRegistrationSupported == false) {
        Map<String, dynamic>? rawLoginTypes;
        await client
            .request(RequestType.GET, '/client/r0/login')
            .then((loginTypes) => rawLoginTypes = loginTypes);
        final identitiesProvider = identityProviders(
          rawLoginTypes: rawLoginTypes,
        );

        if (supportsSso(context) && identitiesProvider?.length == 1) {
          final result = await ssoLoginAction(
            context: context,
            id: identitiesProvider!.single.id!,
          );
          if (result == SsoLoginState.error) {
            state = HomeserverState.ssoLoginServer;
          }
        } else if (supportsLogin(context)) {
          handlePasswordLogin();
        } else {
          state = HomeserverState.otherLoginMethod;
          const ConnectRoute($extra: LoginClientOwner.caller).push(context);
        }
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {});
      } else {
        state = HomeserverState.otherLoginMethod;
        const ConnectRoute($extra: LoginClientOwner.caller).push(context);
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {});
      }
    } catch (e) {
      state = HomeserverState.wrongServerName;
      setState(() => error = (e).toLocalizedString(context));
    }
  }

  void handlePasswordLogin() {
    state = HomeserverState.passwordLoginMethod;
    if (widget.arg.type == HomeserverPickerType.singleAccount) {
      const HomeLoginRoute($extra: LoginClientOwner.caller).push(context);
    } else {
      const AddAccountLoginRoute($extra: LoginClientOwner.caller).push(context);
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

  late final LoginSessions _sessions;

  @override
  void dispose() {
    // Leaving the add-account flow without logging in drops its client.
    if (widget.arg.type == HomeserverPickerType.multiAccount) {
      unawaited(_sessions.discardPending());
    }
    homeserverFocusNode.removeListener(_updateFocus);
    homeserverFocusNode.dispose();
    homeserverController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _sessions = ref.read(loginSessionsProvider);
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
          final client = await _sessions.loginClient();
          await client.importDump(String.fromCharCodes(file.bytes!));
          Matrix.of(context).initMatrix();
        } catch (e, s) {
          Logs().wtf('HomeserverPicker::restoreBackup() [Exception]', e, s);
        }
      },
    );
  }
}
