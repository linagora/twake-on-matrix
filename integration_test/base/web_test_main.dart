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

/// Shared client list — created once per isolate and reused across tests.
///
/// Patrol web runs all tests in the same Dart isolate (same headless-Chrome
/// session).  Creating a new client object per test would re-open the same
/// Hive boxes on every call, causing Hive to throw "box already open" or
/// deadlock on the second open attempt.  By creating clients once and
/// re-running [runApp] with the same objects, we keep the Hive state
/// consistent while still allowing [TwakeApp] to reset its widget tree.
List<Client> _testClients = [];

/// Initialise just enough for a web login test, then [runApp].
///
/// Guard: each [patrolTest] callback calls this, but within a single test
/// file all callbacks share the same Dart isolate.  Calling [runApp] again
/// is fine (it replaces the root widget), but one-shot setup like
/// [GetItInitializer], [Hive.initFlutter], [client.init()], and the
/// [AppConfig] completer must only run once.
Future<void> main() async {
  if (!_initialised) {
    _initialised = true;
    Logs().i('web_test_main: step 1 - binding');
    WidgetsFlutterBinding.ensureInitialized();
    initMatrixLogger();

    Logs().i('web_test_main: step 2 - AppConfig');
    AppConfig.loadFromJson(_testConfig);
    AppConfig.initConfigCompleter.complete(true);

    Logs().i('web_test_main: step 3 - GoRouter');
    GoRouter.optionURLReflectsImperativeAPIs = true;

    Logs().i('web_test_main: step 4 - Hive.initFlutter');
    await Hive.initFlutter().timeout(
      const Duration(seconds: 20),
      onTimeout: () => Logs().w('web_test_main: HANG Hive.initFlutter >20s'),
    );
    Logs().i('web_test_main: step 4 done');

    Logs().i('web_test_main: step 5 - GetIt setUp');
    GetItInitializer().setUp();

    Logs().i('web_test_main: step 6 - getClients');
    _testClients = await ClientManager.getClients(initialize: false).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        Logs().w('web_test_main: HANG getClients >30s');
        return <Client>[];
      },
    );
    Logs().i('web_test_main: step 6 done (${_testClients.length} client(s))');

    final firstClient = _testClients.firstOrNull;
    if (firstClient != null && !firstClient.isLogged()) {
      Logs().i('web_test_main: step 7 - client.init');
      await firstClient
          .init(waitForFirstSync: false, waitUntilLoadCompletedLoaded: false)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                Logs().w('web_test_main: client.init() timed out after 15s'),
          );
      Logs().i('web_test_main: step 7 done');
    }
  }

  Logs().i('web_test_main: step 8 - runApp');
  Logs().nativeColors = !PlatformInfos.isIOS;
  runApp(TwakeApp(clients: _testClients));
  Logs().i('web_test_main: step 8 runApp called');
}
