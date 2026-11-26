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
  _FakePlayer({required this.appliesSessionAttributes});

  /// Whether the player follows the shared audio session attributes.
  final bool appliesSessionAttributes;

  final calls = <String>[];

  @override
  Future<void> setAndroidAudioAttributes(
    AndroidAudioAttributes audioAttributes,
  ) async => calls.add('attributes ${audioAttributes.usage}');

  @override
  Future<void> setLoopMode(LoopMode mode) async => calls.add('loop $mode');

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    calls.add('source ${(audioSource as UriAudioSource).uri}');
    return null;
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

class _Host {
  final repository = FakeCallRepository();
  final players = <_FakePlayer>[];
}

Future<_Host> _pumpHost(WidgetTester tester) async {
  final host = _Host();
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        callRepositoryProvider.overrideWithValue(host.repository),
        activeMatrixClientProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: (context, child) => IncomingCallHost(
          navigatorKey: navigatorKey,
          createPlayer: ({androidApplyAudioAttributes = true}) =>
              (host.players..add(
                    _FakePlayer(
                      appliesSessionAttributes: androidApplyAudioAttributes,
                    ),
                  ))
                  .last,
          child: child!,
        ),
        home: const Scaffold(body: Text('chats')),
      ),
    ),
  );
  return host;
}

void main() {
  group('push rules', _pushRuleTests);
  group('banner', _bannerTests);
  group('ringtone', _ringtoneTests);
}

void _pushRuleTests() {
  testWidgets('mount_setsTheRingPushRulesOnce', (tester) async {
    // Act
    final host = await _pumpHost(tester);
    await tester.pump();

    // Assert
    expect(
      host.repository.calls.where((call) => call == 'ensureCallRingPushRules'),
      hasLength(1),
    );
  });
}

void _bannerTests() {
  testWidgets('aRing_showsOverTheAppUntilDeclined', (tester) async {
    // Arrange
    final host = await _pumpHost(tester);
    expect(find.byKey(const Key('incoming-call')), findsNothing);

    // Act
    host.repository.rings.add([_ring]);
    await tester.pump();

    // Assert
    expect(find.text('chats'), findsOneWidget);
    expect(find.byKey(const Key('incoming-call')), findsOneWidget);

    // Act
    await tester.tap(find.byKey(const Key('decline-call')));
    await tester.pump();

    // Assert
    expect(find.byKey(const Key('incoming-call')), findsNothing);
    expect(host.repository.calls, contains(r'decline $ring'));
  });

  testWidgets('aRingThatStopsElsewhere_goes', (tester) async {
    // Arrange
    final host = await _pumpHost(tester);
    host.repository.rings.add([_ring]);
    await tester.pump();

    // Act
    host.repository.rings.add([]);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(const Key('incoming-call')), findsNothing);
  });
}

void _ringtoneTests() {
  testWidgets('aRing_ringsALoopedRingtone_untilItStops', (tester) async {
    // Arrange
    final host = await _pumpHost(tester);

    // Act
    host.repository.rings.add([_ring]);
    await tester.pump();

    // Assert
    expect(host.players.single.appliesSessionAttributes, isFalse);
    expect(host.players.single.calls, [
      'attributes ${AndroidAudioUsage.notificationRingtone}',
      'loop ${LoopMode.one}',
      'source asset:///${IncomingCallHost.ringAsset}',
      'play',
    ]);

    // Act
    host.repository.rings.add([]);
    await tester.pumpAndSettle();

    // Assert
    expect(host.players.single.calls.last, 'dispose');
  });

  testWidgets('aRingDuringAnotherCall_showsWithoutSound', (tester) async {
    // Arrange
    final host = await _pumpHost(tester);
    host.repository.othersInCall = true;
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
    host.repository.rings.add([_ring]);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(const Key('incoming-call')), findsOneWidget);
    expect(host.players, isEmpty);
  });
}
