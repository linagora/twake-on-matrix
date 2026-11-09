import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
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
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }

  testWidgets('build_beforeTheCall_offersToStartIt', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Team'), findsOneWidget);
    expect(find.byKey(const Key('call-start')), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('startCall_always_joinsTheRoomWithoutVideo', (tester) async {
    await pumpScreen(tester);

    await join(tester);

    expect(repository.calls, contains('join $_roomId video=false'));
  });

  testWidgets('build_inTheCall_showsEachDeviceAndWhoIsMuted', (tester) async {
    await pumpScreen(tester);

    await join(tester);

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Microphone off'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('microphone_inTheCall_turnsTheOwnMicrophoneOff', (tester) async {
    await pumpScreen(tester);
    await join(tester);

    await tester.tap(find.byKey(const Key('call-microphone')));
    await tester.pump();

    expect(repository.calls, contains('microphone false'));
  });

  testWidgets('leave_inTheCall_leavesAndClosesTheScreen', (tester) async {
    await pumpScreen(tester);
    await join(tester);

    await tester.tap(find.byKey(const Key('call-leave')));
    await settle(tester);

    expect(repository.calls, contains('leave $_roomId'));
    expect(find.byType(CallScreen), findsNothing);
  });

  testWidgets('back_inTheCall_leavesTheCall', (tester) async {
    await pumpScreen(tester);
    await join(tester);

    await tester.binding.handlePopRoute();
    await settle(tester);

    expect(repository.calls, contains('leave $_roomId'));
    expect(find.byType(CallScreen), findsNothing);
  });

  testWidgets('build_whenTheTokenIsRefused_saysWhyAndOffersARetry', (
    tester,
  ) async {
    repository.fetchError = const CallTokenFailedException();
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('call-start')));
    await tester.pump();

    expect(
      find.text('The call server refused the call. Try again in a moment.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('call-retry')), findsOneWidget);
  });
}
