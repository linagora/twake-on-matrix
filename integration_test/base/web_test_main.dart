/// Lightweight app entry point for web integration tests.
///
/// Skips native-only init (vodozemac WASM, MediaKit, CozyConfigManager)
/// that can hang in headless Chrome / flutter drive --profile context.
///
/// Pre-populates [AppConfig] with a dead homeserver (`localhost:1`) so
/// [AutoHomeserverPicker] fails fast instead of triggering SSO redirect.
/// The real server URL comes from `--dart-define=SERVER_URL` at the test
/// level.  No physical `web/config.json` is required.
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

/// Test-safe config: dead homeserver prevents SSO / auto-connect side effects.
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

/// Initialise just enough for a web login test, then [runApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initMatrixLogger();

  // Skip: MediaKit.ensureInitialized()  — media player, not needed
  // Skip: vod.init()                    — vodozemac WASM hangs in test
  // Skip: CozyConfigManager             — Cozy integration, not needed

  // Pre-populate AppConfig so AutoHomeserverPicker can proceed immediately
  // without fetching config.json over HTTP.  The isCompleted guard in
  // initConfigWeb() prevents a double-complete crash.
  AppConfig.loadFromJson(_testConfig);
  AppConfig.initConfigCompleter.complete(true);

  GoRouter.optionURLReflectsImperativeAPIs = true;
  await Hive.initFlutter();

  GetItInitializer().setUp();

  Logs().nativeColors = !PlatformInfos.isIOS;
  final clients = await ClientManager.getClients();
  final firstClient = clients.firstOrNull;
  await firstClient?.roomsLoading;
  await firstClient?.accountDataLoading;

  Logs().i('web_test_main: starting GUI with ${clients.length} client(s)');
  runApp(TwakeApp(clients: clients));
}
