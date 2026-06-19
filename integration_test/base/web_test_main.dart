/// Lightweight app entry point for web integration tests.
///
/// Skips native-only init (vodozemac WASM, MediaKit, CozyConfigManager)
/// that can hang in headless Chrome / flutter drive --profile context.
///
/// Pre-populates [AppConfig] with a dead homeserver (`localhost:1`) so
/// [AutoHomeserverPicker]'s `_autoConnectHomeserver` fails fast (connection
/// refused) instead of hitting the real Synapse and leaking a
/// `MatrixException` from `register(inhibitLogin: true)` into the test zone.
/// The test itself calls `checkHomeserver` on the real `SERVER_URL`.
library;

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/logging/init_matrix_logger.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/widgets/twake_app.dart';

/// Dead homeserver — prevents auto-connect side effects during test init.
const _testConfig = <String, dynamic>{
  'app_grid_dashboard_available': false,
  'application_name': 'Twake Chat',
  'application_welcome_message': 'Welcome to Twake Chat!',
  'default_homeserver': 'localhost',
  'homeserver': 'https://localhost:1/',
  'twake_workplace_homeserver': 'https://localhost:1/',
  'platform': '',
  'render_html': true,
  'enable_logs': true,
};

bool _initialised = false;

/// Initialise just enough for a web login test, then [runApp].
///
/// Guard: each [patrolTest] callback calls this, but within a single test
/// file all callbacks share the same Dart isolate.  Calling [runApp] again
/// is fine (it replaces the root widget), but one-shot setup like
/// [GetItInitializer], [Hive.initFlutter], and the [AppConfig] completer
/// must only run once — a second call would throw (duplicate GetIt
/// registrations, double-completed Completer).
Future<void> main() async {
  if (!_initialised) {
    _initialised = true;
    WidgetsFlutterBinding.ensureInitialized();
    initMatrixLogger();

    AppConfig.loadFromJson(_testConfig);
    AppConfig.initConfigCompleter.complete(true);

    GoRouter.optionURLReflectsImperativeAPIs = true;
    await Hive.initFlutter();

    GetItInitializer().setUp();
  }

  Logs().nativeColors = !PlatformInfos.isIOS;
  final clients = await ClientManager.getClients(initialize: false);
  final firstClient = clients.firstOrNull;
  if (firstClient != null && !firstClient.isLogged()) {
    await firstClient
        .init(waitForFirstSync: false, waitUntilLoadCompletedLoaded: false)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => Logs().w('web_test_main: client.init() timed out'),
        );
  }

  Logs().i('web_test_main: starting GUI with ${clients.length} client(s)');
  runApp(TwakeApp(clients: clients));
}
