import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/call/call_controller.dart';
import 'package:twake_chat/pages/call/call_screen.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../domain/call/fake_call_repository.dart';
import 'call_controller_test.dart' show summaryWithFoci;

const _roomId = '!room:hs.test';

void main() {
  late FakeCallRepository repository;
  late ProviderContainer container;

  setUp(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
    repository = FakeCallRepository();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        callRepositoryProvider.overrideWithValue(repository),
        activeMatrixClientProvider.overrideWithValue(null),
      ],
    );
    container
        .read(loginHomeserverSummaryProvider.notifier)
        .set(
          summaryWithFoci([
            {'type': 'livekit', 'livekit_service_url': 'https://rtc.test'},
          ]),
        );
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  CallScreen.open(context, roomId: _roomId, title: 'Team'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> join(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('call-start')));
    await tester.pump();
    repository.participants.add([
      participant('@bob:hs.test:BOB', isLocal: true),
      participant(
        '@alice:hs.test:ALICE',
      ).copyWith(isMicrophoneOn: false, displayName: 'Alice'),
    ]);
    await tester.pump();
  }

  // The fake repository lives outside the fake zone of the test.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 2; i++) {
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
  }

  testWidgets('build_beforeTheCall_offersToStartIt', (tester) async {
    // Act
    await pumpScreen(tester);

    // Assert
    expect(find.text('Team'), findsOneWidget);
    expect(find.byKey(const Key('call-start')), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('startCall_always_joinsTheRoomWithoutVideo', (tester) async {
    // Arrange
    await pumpScreen(tester);

    // Act
    await join(tester);

    // Assert
    expect(repository.calls, contains('join $_roomId video=false'));
  });

  testWidgets('build_inTheCall_showsEachDeviceAndWhoIsMuted', (tester) async {
    // Arrange
    await pumpScreen(tester);

    // Act
    await join(tester);

    // Assert
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Microphone off'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('microphone_inTheCall_turnsTheOwnMicrophoneOff', (tester) async {
    // Arrange
    await pumpScreen(tester);
    await join(tester);

    // Act
    await tester.tap(find.byKey(const Key('call-microphone')));
    await tester.pump();

    // Assert
    expect(repository.calls, contains('microphone false'));
  });

  testWidgets('leave_inTheCall_leavesAndClosesTheScreen', (tester) async {
    // Arrange
    await pumpScreen(tester);
    await join(tester);

    // Act
    await tester.tap(find.byKey(const Key('call-leave')));
    await settle(tester);

    // Assert
    expect(repository.calls, contains('leave $_roomId'));
    expect(find.byType(CallScreen), findsNothing);
  });

  testWidgets('back_inTheCall_leavesTheCall', (tester) async {
    // Arrange
    await pumpScreen(tester);
    await join(tester);

    // Act
    await tester.binding.handlePopRoute();
    await settle(tester);

    // Assert
    expect(repository.calls, contains('leave $_roomId'));
    expect(find.byType(CallScreen), findsNothing);
  });

  testWidgets('build_whenTheTokenIsRefused_saysWhyAndOffersARetry', (
    tester,
  ) async {
    // Arrange
    repository.fetchError = const CallTokenFailedException();
    await pumpScreen(tester);

    // Act
    await tester.tap(find.byKey(const Key('call-start')));
    await tester.pump();

    // Assert
    expect(
      find.text('The call server refused the call. Try again in a moment.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('call-retry')), findsOneWidget);
  });

  testWidgets('dispose_whenTheRouteIsRemovedWithoutAPop_leavesTheCall', (
    tester,
  ) async {
    // Arrange
    await pumpScreen(tester);
    await join(tester);

    // Act
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const Text('shared')),
            (_) => false,
          ),
    );
    await settle(tester);

    // Assert
    expect(repository.calls, contains('leave $_roomId'));
  });

  testWidgets('build_whenTheCallOfAnotherRoomEnds_staysOpen', (tester) async {
    // Arrange
    await pumpScreen(tester);
    final calls = container.read(callControllerProvider.notifier);

    // Act
    await tester.runAsync(() => calls.join('!other:hs.test', isVideo: false));
    await tester.pump();
    await tester.runAsync(calls.leave);
    await settle(tester);

    // Assert
    expect(find.byType(CallScreen), findsOneWidget);
  });

  testWidgets('build_whenTheCallEndsUnderAnotherRoute_closesOnlyTheCall', (
    tester,
  ) async {
    // Arrange
    await pumpScreen(tester);
    await join(tester);
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(MaterialPageRoute<void>(builder: (_) => const Text('above'))),
    );
    await tester.pumpAndSettle();

    // Act
    await tester.runAsync(
      container.read(callControllerProvider.notifier).leave,
    );
    await settle(tester);

    // Assert
    expect(find.text('above'), findsOneWidget);
    expect(find.byType(CallScreen, skipOffstage: false), findsNothing);
    expect(find.text('open', skipOffstage: false), findsOneWidget);
  });
}
