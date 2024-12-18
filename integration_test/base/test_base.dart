import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:patrol/patrol.dart';

class TestBase {
  void runPatrolTest({
    required String description,
    required Function(PatrolIntegrationTester $) test,
  }) {
    patrolTest(description,
        config: const PatrolTesterConfig(
          settlePolicy: SettlePolicy.trySettle,
          visibleTimeout: Duration(minutes: 1),
        ),
        nativeAutomatorConfig: const NativeAutomatorConfig(
          findTimeout: Duration(seconds: 10),
        ),
        framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
        ($) async {
      await initTwakeChat($);
      final originalOnError = FlutterError.onError!;
      FlutterError.onError = (FlutterErrorDetails details) {
        originalOnError(details);
      };
      await test($);
    });
  }

  Future<void> initTwakeChat(PatrolIntegrationTester $) async {
    MediaKit.ensureInitialized();
    GoRouter.optionURLReflectsImperativeAPIs = true;
    await Hive.initFlutter();
    GetItInitializer().setUp();
    final clients = await ClientManager.getClients();
    final firstClient = clients.firstOrNull;
    await firstClient?.roomsLoading;
    await firstClient?.accountDataLoading;
    await $.pumpWidgetAndSettle(
      TwakeApp(clients: clients),
    );
  }
}
