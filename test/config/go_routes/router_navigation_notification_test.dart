import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/router_navigation_notification.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/lock_screen.dart';
import 'package:twake_chat/widgets/twake_app_lock.dart';

void main() {
  group('RouterNavigationNotification', () {
    late List<bool> frameworkHandlesBack;
    late int systemPops;
    late GlobalKey<NavigatorState> rootKey;
    late GlobalKey<NavigatorState> shellKey;

    setUp(() {
      getIt.registerSingleton<ResponsiveUtils>(ResponsiveUtils());
      frameworkHandlesBack = [];
      systemPops = 0;
      rootKey = GlobalKey<NavigatorState>();
      shellKey = GlobalKey<NavigatorState>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
              frameworkHandlesBack.add(call.arguments as bool);
            }
            if (call.method == 'SystemNavigator.pop') systemPops++;
            return null;
          });
    });

    tearDown(() async {
      await getIt.reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Future<GoRouter> openApp(WidgetTester tester, {bool locked = false}) async {
      final router = GoRouter(
        navigatorKey: rootKey,
        initialLocation: '/rooms',
        routes: [
          ShellRoute(
            navigatorKey: shellKey,
            builder: (_, _, child) => child,
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (_, _) => const Text('rooms'),
                routes: [
                  GoRoute(path: 'info', builder: (_, _) => const Text('info')),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          onNavigationNotification: router.onNavigationNotification,
          builder: (_, child) => TwakeAppLock(
            dispatcher: router.backButtonDispatcher,
            initiallyEnabled: locked,
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    Future<void> openAndCloseDialog(WidgetTester tester) async {
      showDialog<void>(
        context: rootKey.currentContext!,
        builder: (_) => const Text('dialog'),
      );
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);
      Navigator.of(tester.element(find.text('dialog'))).pop();
      await tester.pumpAndSettle();
    }

    Future<void> expectBackReturnsToRooms(WidgetTester tester) async {
      expect(find.text('info'), findsOneWidget);
      expect(frameworkHandlesBack.last, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('rooms'), findsOneWidget);
      expect(frameworkHandlesBack.last, isFalse);
    }

    testWidgets('whenBackIsPressedWithADialogOpen_closesItAndKeepsThePage', (
      tester,
    ) async {
      final router = await openApp(tester);
      router.push('/rooms/info');
      await tester.pumpAndSettle();
      showDialog<void>(
        context: rootKey.currentContext!,
        builder: (_) => const Text('dialog'),
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('dialog'), findsNothing);
      expect(find.text('info'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('whenBackIsPressedOnTheLockScreen_keepsThePageBehindIt', (
      tester,
    ) async {
      final router = await openApp(tester);
      router.push('/rooms/info');
      await tester.pumpAndSettle();
      final appLock = tester.state<AppLockState>(find.byType(AppLock));
      appLock.enable();
      appLock.showLockScreen();
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(LockScreen), findsOneWidget);
      appLock.didUnlock();
      await tester.pumpAndSettle();
      expect(find.text('info'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('whenBackIsPressedOnTheLockScreenAtLaunch_staysOnIt', (
      tester,
    ) async {
      await openApp(tester, locked: true);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(LockScreen), findsOneWidget);
      expect(systemPops, 0);
      expect(frameworkHandlesBack.last, isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('whenADialogClosesOnARoute_backPopsTheRoute', (tester) async {
      final router = await openApp(tester);
      router.push('/rooms/info');
      await tester.pumpAndSettle();

      await openAndCloseDialog(tester);

      await expectBackReturnsToRooms(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('whenADialogClosesOnAPagelessRoute_backPopsThatRoute', (
      tester,
    ) async {
      await openApp(tester);
      shellKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('info')),
      );
      await tester.pumpAndSettle();

      await openAndCloseDialog(tester);

      await expectBackReturnsToRooms(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}
