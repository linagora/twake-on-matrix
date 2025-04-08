import 'package:collection/collection.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:linagora_design_flutter/cozy_config_manager/cozy_config_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'utils/background_push.dart';
import 'widgets/twake_app.dart';
import 'widgets/lock_screen.dart';

void main() async {
  // Our background push shared isolate accesses flutter-internal things very early in the startup proccess
  // To make sure that the parts of flutter needed are started up already, we need to ensure that the
  // widget bindings are initialized already.
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  if (PlatformInfos.isLinux) {
    Hive.init((await getApplicationSupportDirectory()).path);
  } else {
    await Hive.initFlutter();
  }

  GetItInitializer().setUp();

  Logs().nativeColors = !PlatformInfos.isIOS;
  final clients = await ClientManager.getClients();
  // Preload first client
  final firstClient = clients.firstOrNull;
  firstClient?.isSupportDeleteCollections = !PlatformInfos.isWeb;
  await firstClient?.roomsLoading;
  await firstClient?.accountDataLoading;

  // If the app starts in detached mode, we assume that it is in
  // background fetch mode for processing push notifications. This is
  // currently only supported on Android.
  if (PlatformInfos.isAndroid &&
      AppLifecycleState.detached == WidgetsBinding.instance.lifecycleState) {
    // In the background fetch mode we do not want to waste ressources with
    // starting the Flutter engine but process incoming push notifications.
    BackgroundPush.clientOnly(clients.first);
    // To start the flutter engine afterwards we add an custom observer.
    WidgetsBinding.instance.addObserver(AppStarter(clients));
    Logs().i(
      '${AppConfig.applicationName} started in background-fetch mode. No GUI will be created unless the app is no longer detached.',
    );
    return;
  }

  if (PlatformInfos.isWeb) {
    CozyConfigManager().injectCozyScript();
  }

  // Started in foreground mode.
  Logs().i(
    '${AppConfig.applicationName} started in foreground mode. Rendering GUI...',
  );
  await startGui(clients);
}

/// Fetch the pincode for the applock and start the flutter engine.
Future<void> startGui(List<Client> clients) async {
  // Fetch the pin for the applock if existing for mobile applications.
  String? pin;
  if (PlatformInfos.isMobile) {
    try {
      pin =
          await const FlutterSecureStorage().read(key: SettingKeys.appLockKey);
    } catch (e, s) {
      Logs().d('Unable to read PIN from Secure storage', e, s);
    }
  }

  // Start rendering the Flutter app and wrap it in an Applock.
  // We do this only for mobile applications as we saw routing
  // problems on other platforms if we wrap it always.
  runApp(
    PlatformInfos.isMobile
        ? AppLock(
            builder: (args) => TwakeApp(clients: clients),
            lockScreen: const LockScreen(),
            enabled: pin?.isNotEmpty ?? false,
          )
        : TwakeApp(clients: clients),
  );
}

/// Watches the lifecycle changes to start the application when it
/// is no longer detached.
class AppStarter with WidgetsBindingObserver {
  final List<Client> clients;
  bool guiStarted = false;

  AppStarter(this.clients);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (guiStarted) return;
    if (state == AppLifecycleState.detached) return;

    Logs().i(
      '${AppConfig.applicationName} switches from the detached background-fetch mode to ${state.name} mode. Rendering GUI...',
    );
    startGui(clients);
    // We must make sure that the GUI is only started once.
    guiStarted = true;
  }
}
