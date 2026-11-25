import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/call/call_controller.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_host.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

import '../../../domain/call/fake_call_repository.dart';
import '../call_controller_test.dart' show summaryWithFoci;

final _ring = CallRing(
  eventId: r'$ring',
  room: const CallRoom('!dm:hs.test'),
  senderId: '@alice:hs.test',
  isVideo: false,
  expiresAt: DateTime(2100),
  roomName: 'Alice',
  isDirect: true,
);

class _FakePlayer extends Fake implements AudioPlayer {
  final calls = <String>[];

  @override
  Future<void> setAndroidAudioAttributes(
    AndroidAudioAttributes audioAttributes,
  ) async => calls.add('attributes ${audioAttributes.usage}');

  @override
  Future<void> setLoopMode(LoopMode mode) async => calls.add('loop $mode');

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    calls.add('asset $assetPath');
    return null;
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  late List<_FakePlayer> players;
  late FakeCallRepository repository;

  Future<void> pumpHost(WidgetTester tester) async {
    repository = FakeCallRepository();
    players = [];
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          callRepositoryProvider.overrideWithValue(repository),
          activeMatrixClientProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          builder: (context, child) => IncomingCallHost(
            navigatorKey: navigatorKey,
            createPlayer: () => (players..add(_FakePlayer())).last,
            child: child!,
          ),
          home: const Scaffold(body: Text('chats')),
        ),
      ),
    );
  }

  testWidgets('mount_setsTheRingPushRulesOnce', (tester) async {
    // Act
    await pumpHost(tester);
    await tester.pump();

    // Assert
    expect(
      repository.calls.where((call) => call == 'ensureCallRingPushRules'),
      hasLength(1),
    );
  });

  testWidgets('aRing_showsOverTheAppUntilDeclined', (tester) async {
    // Arrange
    await pumpHost(tester);
    expect(find.byKey(const Key('incoming-call')), findsNothing);

    // Act
    repository.rings.add([_ring]);
    await tester.pump();

    // Assert
    expect(find.text('chats'), findsOneWidget);
    expect(find.byKey(const Key('incoming-call')), findsOneWidget);

    // Act
    await tester.tap(find.byKey(const Key('decline-call')));
    await tester.pump();

    // Assert
    expect(find.byKey(const Key('incoming-call')), findsNothing);
    expect(repository.calls, contains(r'decline $ring'));
  });

  testWidgets('aRingThatStopsElsewhere_goes', (tester) async {
    // Arrange
    await pumpHost(tester);
    repository.rings.add([_ring]);
    await tester.pump();

    // Act
    repository.rings.add([]);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(const Key('incoming-call')), findsNothing);
  });

  testWidgets('aRing_ringsALoopedRingtone_untilItStops', (tester) async {
    // Arrange
    await pumpHost(tester);

    // Act
    repository.rings.add([_ring]);
    await tester.pump();

    // Assert
    expect(players.single.calls, [
      'attributes ${AndroidAudioUsage.notificationRingtone}',
      'loop ${LoopMode.one}',
      'asset ${IncomingCallHost.ringAsset}',
      'play',
    ]);

    // Act
    repository.rings.add([]);
    await tester.pumpAndSettle();

    // Assert
    expect(players.single.calls.last, 'dispose');
  });

  testWidgets('aRingDuringAnotherCall_showsWithoutSound', (tester) async {
    // Arrange
    await pumpHost(tester);
    repository.othersInCall = true;
    final container = ProviderScope.containerOf(
      tester.element(find.text('chats')),
    );
    container
        .read(loginHomeserverSummaryProvider.notifier)
        .set(
          summaryWithFoci([
            {'type': 'livekit', 'livekit_service_url': 'https://rtc.test/'},
          ]),
        );
    unawaited(
      container
          .read(callControllerProvider.notifier)
          .join('!other:hs.test', isVideo: false),
    );
    await tester.pump();

    // Act
    repository.rings.add([_ring]);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(const Key('incoming-call')), findsOneWidget);
    expect(players, isEmpty);
  });
}
