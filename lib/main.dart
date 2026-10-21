import 'dart:async';

import 'package:collection/collection.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/providers/app_provider_container.dart';
import 'package:twake_chat/utils/client_manager.dart';
import 'package:twake_chat/utils/logging/init_matrix_logger.dart';
import 'package:twake_chat/utils/manager/legacy_settings_migration_manager.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/sentry_init.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:linagora_design_flutter/cozy_config_manager/cozy_config_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';

import 'utils/background_push.dart';
import 'widgets/lock_screen.dart';
import 'widgets/twake_app.dart';

void main() async {
  await runZonedGuarded(
    initializeApp,
    (error, stackTrace) => Logs().wtf('Error in main', error, stackTrace),
  );
}

Future<void> initializeApp() async {
  // Our background push shared isolate accesses flutter-internal things very early in the startup proccess
  // To make sure that the parts of flutter needed are started up already, we need to ensure that the
  // widget bindings are initialized already.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  initMatrixLogger();
  MediaKit.ensureInitialized();
  _enableAndroidPhotoPicker();
  await vod.init();
  if (PlatformInfos.isMobile) {
    databaseFactory = databaseFactoryFfi;
  }
  GoRouter.optionURLReflectsImperativeAPIs = true;
  if (PlatformInfos.isLinux) {
    Hive.init((await getApplicationSupportDirectory()).path);
  } else {
    await Hive.initFlutter();
  }

  GetItInitializer().setUp();

  await LegacySettingsMigrationManager.migrateLegacySettingKeys();

  final container = createAppProviderContainer();

  Logs().nativeColors = !PlatformInfos.isIOS;
  final clients = await ClientManager.getClients();
  // Preload the first account that can be used; a logged-out client kept for
  // its pending removal is not one.
  final firstClient = ClientManager.loggedIn(clients).firstOrNull;
  await firstClient?.roomsLoading;
  await firstClient?.accountDataLoading;

  // If the app starts in detached mode, we assume that it is in
  // background fetch mode for processing push notifications. This is
  // currently only supported on Android.
  if (PlatformInfos.isAndroid &&
      AppLifecycleState.detached == WidgetsBinding.instance.lifecycleState) {
    // In the background fetch mode we do not want to waste ressources with
    // starting the Flutter engine but process incoming push notifications.
    if (firstClient != null) {
      BackgroundPush.clientOnly(firstClient);
    } else {
      Logs().w('No logged-in client to serve push in background-fetch mode.');
    }
    // To start the flutter engine afterwards we add an custom observer.
    WidgetsBinding.instance.addObserver(AppStarter(clients, container));
    Logs().i(
      '${AppConfig.applicationName} started in background-fetch mode. No GUI will be created unless the app is no longer detached.',
    );
    return;
  }

  if (PlatformInfos.isWeb) {
    CozyConfigManager()
        .injectCozyScript(AppConfig.cozyExternalBridgeVersion)
        .then((value) => CozyConfigManager().initialize());
  }

  // Started in foreground mode.
  Logs().i(
    '${AppConfig.applicationName} started in foreground mode. Rendering GUI...',
  );
  await startGui(clients, container);
}

/// Opts the Android `image_picker` implementation into the modern, system
/// Android Photo Picker (`ACTION_PICK_IMAGES`) instead of the legacy
/// `ACTION_GET_CONTENT` document/SAF intent. Without this flag the chat media
/// button on Android opens the file-explorer-style picker rather than the
/// WhatsApp-like photo gallery. No-op on every other platform.
void _enableAndroidPhotoPicker() {
  if (!PlatformInfos.isAndroid) return;
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
}

/// Fetch the pincode for the applock and start the flutter engine.
Future<void> startGui(List<Client> clients, ProviderContainer container) async {
  // Fetch the pin for the applock if existing for mobile applications.
  String? pin;
  if (PlatformInfos.isMobile) {
    try {
      pin = await const FlutterSecureStorage().read(
        key: SettingKeys.appLockKey,
      );
    } catch (e, s) {
      Logs().d('Unable to read PIN from Secure storage', e, s);
    }
  }

  // The only container of the app (created in main): the boot reads go
  // through it and the widget tree is attached to it.
  final repository = container.read(accountRepositoryProvider);
  // The account that was active last time is read here, before the first
  // frame, so the account state starts on it.
  String? persistedActiveUserId;
  var pendingRemovalIds = <String>{};
  try {
    persistedActiveUserId = await repository.persistedActiveUserId();
  } catch (e, s) {
    Logs().w('Unable to read the persisted active account', e, s);
  }
  try {
    // Accounts whose removal did not finish before the last exit.
    pendingRemovalIds = await repository.pendingRemovalIds();
  } catch (e, s) {
    Logs().w('Unable to read the pending account removals', e, s);
  }
  container
      .read(bootAccountSnapshotProvider.notifier)
      .set(
        AccountBootSnapshot(
          persistedActiveUserId: persistedActiveUserId,
          pendingRemovalIds: pendingRemovalIds,
        ),
      );

  // Start rendering the Flutter app and wrap it in an Applock.
  // We do this only for mobile applications as we saw routing
  // problems on other platforms if we wrap it always.
  await sentryInit(
    runApp: runApp,
    app: UncontrolledProviderScope(
      container: container,
      child: PlatformInfos.isMobile
          ? AppLock(
              builder: (args) => TwakeApp(clients: clients),
              lockScreen: const LockScreen(),
              enabled: pin?.isNotEmpty ?? false,
            )
          : TwakeApp(clients: clients),
    ),
  );
}

/// Watches the lifecycle changes to start the application when it
/// is no longer detached.
class AppStarter with WidgetsBindingObserver {
  final List<Client> clients;
  final ProviderContainer container;
  bool guiStarted = false;

  AppStarter(this.clients, this.container);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (guiStarted) return;
    if (state == AppLifecycleState.detached) return;

    Logs().i(
      '${AppConfig.applicationName} switches from the detached background-fetch mode to ${state.name} mode. Rendering GUI...',
    );
    unawaited(startGui(clients, container));
    // We must make sure that the GUI is only started once.
    guiStarted = true;
  }
}
