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
///
/// ## Why we do NOT pre-create Matrix clients here
///
/// [ClientManager.getClients] calls [MatrixSdkDatabase.init] which opens
/// IndexedDB via [BoxCollection.open].  [BoxCollection.open] uses
/// `package:web` `.toJS` callbacks that never fire before [runApp] is called
/// — the Playwright headless-Chrome context does not deliver those macrotask
/// callbacks until Flutter's rendering pipeline starts (first frame).
///
/// The test therefore boots with `clients: []` (logged-out state) and
/// logs in through the UI.  The IndexedDB callback fires inside
/// [Matrix.getLoginClient], which is invoked only after [runApp] and after the
/// first frame is rendered — at that point everything works correctly.
library;

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
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

/// Initialise just enough for a web test, then [runApp].
///
/// Guard: each [patrolTest] callback calls this, but within a single test
/// file all callbacks share the same Dart isolate.  Calling [runApp] again
/// is fine (it replaces the root widget), but one-shot setup like
/// [GetItInitializer], [Hive.initFlutter], and the [AppConfig] completer
/// must only run once.
Future<void> main() async {
  if (!_initialised) {
    _initialised = true;
    WidgetsFlutterBinding.ensureInitialized();
    initMatrixLogger();

    AppConfig.loadFromJson(_testConfig);
    AppConfig.initConfigCompleter.complete(true);

    GoRouter.optionURLReflectsImperativeAPIs = true;

    // On web kIsWeb is true so this returns immediately; kept for safety
    // in case this file is ever reused on another target.
    await Hive.initFlutter();

    GetItInitializer().setUp();
  }

  Logs().nativeColors = !PlatformInfos.isIOS;
  // Boot with no pre-existing session.  The test logs in via the UI and the
  // IndexedDB database is opened lazily inside Matrix.getLoginClient(),
  // which runs only after runApp() and after the first frame renders.
  //
  // A growable (non-const) list is required: Matrix._handleAddAnotherAccount
  // calls `widget.clients.add(...)` on a successful login, which would throw
  // on a const list. Held in a `final` so the analyzer doesn't suggest const.
  final clients = <Client>[];
  runApp(TwakeApp(clients: clients));
}
