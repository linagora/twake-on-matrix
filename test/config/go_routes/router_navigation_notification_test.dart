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
              GoRoute(path: '/tabs', builder: (_, _) => const _TabsPage()),
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
    Future<void> openSecondTab(WidgetTester tester, GoRouter router) async {
      router.go('/tabs');
      await tester.pumpAndSettle();
      await tester.tap(find.text('tab 0'));
      await tester.pumpAndSettle();
      expect(find.text('tab 1'), findsOneWidget);
    }

    Future<void> expectBackReturnsToFirstTab(WidgetTester tester) async {
      expect(frameworkHandlesBack.last, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('tab 0'), findsOneWidget);
      expect(systemPops, 0);
      expect(frameworkHandlesBack.last, isFalse);
    }

    testWidgets('whenBackIsPressedOnASecondTab_returnsToTheFirstTab', (
      tester,
    ) async {
      final router = await openApp(tester);
      await openSecondTab(tester, router);

      await expectBackReturnsToFirstTab(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('whenADialogClosesOnASecondTab_backReturnsToTheFirstTab', (
      tester,
    ) async {
      final router = await openApp(tester);
      await openSecondTab(tester, router);

      await openAndCloseDialog(tester);

      await expectBackReturnsToFirstTab(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}

// A page that keeps Back while it shows another tab than the first one.
class _TabsPage extends StatefulWidget {
  const _TabsPage();

  @override
  State<_TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<_TabsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _tab == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) setState(() => _tab = 0);
    },
    child: GestureDetector(
      onTap: () => setState(() => _tab = 1),
      child: Text('tab $_tab'),
    ),
  );
}
