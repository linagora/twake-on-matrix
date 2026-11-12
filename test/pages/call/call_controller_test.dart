import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' hide CallState;
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/pages/call/call_controller.dart';
import 'package:twake_chat/pages/call/call_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

import '../../domain/call/fake_call_repository.dart';

HomeserverSummary summaryWithFoci(List<Map<String, Object?>> foci) =>
    HomeserverSummary(
      discoveryInformation: DiscoveryInformation(
        mHomeserver: HomeserverInformation(
          baseUrl: Uri.parse('https://hs.test'),
        ),
        additionalProperties: {'org.matrix.msc4143.rtc_foci': foci},
      ),
      versions: GetVersionsResponse(versions: ['v1.11']),
      loginFlows: [],
    );

void main() {
  late FakeCallRepository repository;
  late ProviderContainer container;

  CallController controller() =>
      container.read(callControllerProvider.notifier);

  CallState state() => container.read(callControllerProvider);

  Future<void> leaveWhileJoining(Completer<void> gate) async {
    final joining = controller().join('!room', isVideo: false);
    await pumpEventQueue();
    await controller().leave();
    gate.complete();
    await joining;
  }

  void expectEndedAs<T extends CallException>() {
    expect((state() as CallFailed).error, isA<T>());
    expect(repository.calls, containsAllInOrder(['disconnect', 'leave !room']));
  }

  setUp(() {
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
            {
              'type': 'livekit',
              'livekit_service_url': 'https://rtc.test/',
              'livekit_base_url': 'https://meet.test',
            },
          ]),
        );
  });

  test('join_withATokenService_connectsThroughIt', () async {
    // Act
    await controller().join('!room', isVideo: false);

    // Assert
    expect(
      state(),
      const CallState.connected(roomId: '!room', isDirect: false),
    );
    expect(repository.calls, contains('fetchServer !room https://rtc.test'));
  });

  test('join_whileInProgress_isConnecting', () async {
    // Act
    final joining = controller().join('!room', isVideo: false);

    // Assert
    expect(state(), const CallState.connecting(roomId: '!room'));
    await joining;
  });

  test('join_whenItFails_keepsTheTypedError', () async {
    // Arrange
    repository.fetchError = const CallTokenFailedException();

    // Act
    await controller().join('!room', isVideo: false);

    // Assert
    expect(
      state(),
      isA<CallFailed>().having(
        (s) => s.error,
        'error',
        isA<CallTokenFailedException>(),
      ),
    );
  });

  test('join_whenAProgrammerErrorEscapes_failsAndSurfacesIt', () async {
    // Arrange
    repository.staleError = StateError('database closed');

    // Act & Assert
    await expectLater(
      controller().join('!room', isVideo: false),
      throwsA(isA<StateError>()),
    );
    expect((state() as CallFailed).error, isA<CallConnectionFailedException>());
  });

  test('join_afterAProgrammerError_canJoinAgain', () async {
    // Arrange
    repository.staleError = StateError('database closed');
    await controller().join('!room', isVideo: false).catchError((_) {});
    repository.staleError = null;

    // Act
    await controller().join('!room', isVideo: false);

    // Assert
    expect(state(), isA<CallConnected>());
  });

  test('join_withoutATokenService_failsAsUnavailable', () async {
    // Arrange
    container.read(loginHomeserverSummaryProvider.notifier).set(null);

    // Act
    await controller().join('!room', isVideo: false);

    // Assert
    expect(
      (state() as CallFailed).error,
      isA<CallServiceUnavailableException>(),
    );
  });

  test('onParticipants_whileConnected_showsThem', () async {
    // Arrange
    await controller().join('!room', isVideo: false);
    final everyone = [
      participant('@me:hs.test:DEV', isLocal: true),
      participant('@bob:hs.test:BOB'),
    ];

    // Act
    repository.participants.add(everyone);
    await pumpEventQueue();

    // Assert
    expect((state() as CallConnected).participants, everyone);
  });

  test('onParticipants_whenTheOtherLeavesADirectCall_leaves', () async {
    // Arrange
    repository.roomInfo = const CallRoomInfo(
      isEncrypted: false,
      isDirect: true,
      canJoin: true,
    );
    await controller().join('!dm', isVideo: false);
    repository.participants.add([
      participant('@me:hs.test:DEV', isLocal: true),
      participant('@bob:hs.test:BOB'),
    ]);
    await pumpEventQueue();

    // Act
    repository.participants.add([
      participant('@me:hs.test:DEV', isLocal: true),
    ]);
    await pumpEventQueue();

    // Assert
    expect(state(), const CallState.idle());
    expect(repository.calls, containsAllInOrder(['disconnect', 'leave !dm']));
  });

  test('onParticipants_whenLeftAloneInAGroupCall_staysConnected', () async {
    // Arrange
    await controller().join('!room', isVideo: false);
    repository.participants.add([
      participant('@me:hs.test:DEV', isLocal: true),
      participant('@bob:hs.test:BOB'),
    ]);
    await pumpEventQueue();

    // Act
    repository.participants.add([
      participant('@me:hs.test:DEV', isLocal: true),
    ]);
    await pumpEventQueue();

    // Assert
    expect(state(), isA<CallConnected>());
  });

  test('leave_whenTheMembershipCannotBeEnded_goesIdle', () async {
    // Arrange
    await controller().join('!room', isVideo: false);
    repository.leaveError = const CallMembershipFailedException();

    // Act
    await controller().leave();

    // Assert
    expect(state(), const CallState.idle());
    expect(repository.calls, containsAllInOrder(['disconnect', 'leave !room']));
  });

  test('setMicrophone_whenRefused_answersFalse', () async {
    // Arrange
    await controller().join('!room', isVideo: false);
    repository.mediaError = const CallMediaFailedException();

    // Act
    final isOn = await controller().setMicrophone(isOn: true);

    // Assert
    expect(isOn, isFalse);
  });

  test('leave_beforeTheMediaConnects_connectsNoMedia', () async {
    // Arrange
    final joining = controller().join('!room', isVideo: false);

    // Act
    await controller().leave();
    await joining;

    // Assert
    expect(state(), const CallState.idle());
    expect(repository.calls, isNot(contains('connect mic=true camera=false')));
  });

  test('leave_whileTheMembershipIsSent_leavesOnceJoined', () async {
    // Arrange
    final gate = repository.joinGate = Completer<void>();

    // Act
    await leaveWhileJoining(gate);

    // Assert
    expect(state(), const CallState.idle());
    expect(
      repository.calls,
      containsAllInOrder(['join !room video=false', 'leave !room']),
    );
  });

  test(
    'onParticipants_whenTheOtherLeavesADirectCallWithMyTwoDevices_leaves',
    () async {
      // Arrange
      repository.roomInfo = const CallRoomInfo(
        isEncrypted: false,
        isDirect: true,
        canJoin: true,
      );
      await controller().join('!dm', isVideo: false);
      repository.participants.add([
        participant('@me:hs.test:DEV', isLocal: true),
        participant('@me:hs.test:TABLET'),
        participant('@bob:hs.test:BOB'),
      ]);
      await pumpEventQueue();

      // Act
      repository.participants.add([
        participant('@me:hs.test:DEV', isLocal: true),
        participant('@me:hs.test:TABLET'),
      ]);
      await pumpEventQueue();

      // Assert
      expect(state(), const CallState.idle());
    },
  );

  test('leave_whileTheMediaConnects_sendsNoMembership', () async {
    // Arrange
    final gate = repository.connectGate = Completer<void>();

    // Act
    await leaveWhileJoining(gate);

    // Assert
    expect(state(), const CallState.idle());
    expect(repository.calls.last, 'disconnect');
    expect(repository.calls, isNot(contains('join !room video=false')));
  });

  test('join_whileThePreviousCallLeaves_waitsForItsCleanup', () async {
    // Arrange
    await controller().join('!room', isVideo: false);
    repository.leaveGate = Completer<void>();
    final leaving = controller().leave();

    // Act
    final joining = controller().join('!other', isVideo: false);
    await pumpEventQueue();
    final callsBeforeTheLeave = [...repository.calls];
    repository.leaveGate!.complete();
    await leaving;
    await joining;

    // Assert
    expect(callsBeforeTheLeave, isNot(contains('endStale !other')));
    expect(
      repository.calls,
      containsAllInOrder([
        'leave !room',
        'endStale !other',
        'join !other video=false',
      ]),
    );
  });

  test('onParticipants_whenTheMediaIsLost_failsAndEndsTheCall', () async {
    // Arrange
    await controller().join('!room', isVideo: false);

    // Act
    repository.participants.addError(const CallConnectionFailedException());
    await pumpEventQueue();

    // Assert
    expectEndedAs<CallConnectionFailedException>();
  });

  test('join_whenThePreviousLeaveNeverEnds_joinsAfterAWhile', () {
    fakeAsync((async) {
      // Arrange
      controller().join('!room', isVideo: false);
      async.flushMicrotasks();
      repository.leaveGate = Completer<void>();
      controller().leave();
      async.flushMicrotasks();

      // Act
      controller().join('!other', isVideo: false);
      async.elapse(const Duration(seconds: 5));
      final callsAfterFiveSeconds = [...repository.calls];
      async.elapse(const Duration(seconds: 6));

      // Assert
      expect(callsAfterFiveSeconds, isNot(contains('endStale !other')));
      expect(repository.calls, contains('join !other video=false'));
      expect(state(), isA<CallConnected>());
    });
  });

  test('onRoomEncrypted_duringTheCall_endsIt', () async {
    // Arrange
    await controller().join('!room', isVideo: false);

    // Act
    repository.encryptions.add(null);
    await pumpEventQueue();

    // Assert
    expectEndedAs<CallEncryptionUnsupportedException>();
  });

  group('accountSwitch', () {
    late FakeCallRepository first;
    late FakeCallRepository second;
    late ProviderContainer switching;
    final firstClient = _FakeClient();
    final secondClient = _FakeClient();

    setUp(() {
      first = FakeCallRepository();
      second = FakeCallRepository();
      switching = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          _clientProvider.overrideWith(() => _ClientNotifier(firstClient)),
          activeMatrixClientProvider.overrideWith(
            (ref) => ref.watch(_clientProvider),
          ),
          callRepositoryProvider.overrideWith(
            (ref) => ref.watch(activeMatrixClientProvider) == firstClient
                ? first
                : second,
          ),
        ],
      );
      switching
          .read(loginHomeserverSummaryProvider.notifier)
          .set(
            summaryWithFoci([
              {'type': 'livekit', 'livekit_service_url': 'https://rtc.test'},
            ]),
          );
      switching.listen(callControllerProvider, (_, _) {});
    });

    test('accountSwitch_whileConnected_leavesWithTheFirstClient', () async {
      // Arrange
      await switching
          .read(callControllerProvider.notifier)
          .join('!room', isVideo: false);

      // Act
      switching.read(_clientProvider.notifier).set(secondClient);
      await pumpEventQueue();

      // Assert
      expect(switching.read(callControllerProvider), const CallState.idle());
      expect(first.calls, containsAllInOrder(['disconnect', 'leave !room']));
      expect(second.calls, isEmpty);
    });

    test('accountSwitch_whileConnecting_sendsNoMembership', () async {
      // Arrange
      first.connectGate = Completer<void>();
      final joining = switching
          .read(callControllerProvider.notifier)
          .join('!room', isVideo: false);
      await pumpEventQueue();

      // Act
      switching.read(_clientProvider.notifier).set(secondClient);
      await pumpEventQueue();
      first.connectGate!.complete();
      await joining;

      // Assert
      expect(switching.read(callControllerProvider), const CallState.idle());
      expect(first.calls.last, 'disconnect');
      expect(first.calls, isNot(contains('join !room video=false')));
      expect(second.calls, isEmpty);
    });
  });

  test('onRoomEncrypted_whenTheRoomIsGone_endsTheCallAsRoomNotFound', () async {
    // Arrange
    await controller().join('!room', isVideo: false);

    // Act
    repository.encryptions.addError(const CallRoomNotFoundException());
    await pumpEventQueue();

    // Assert
    expectEndedAs<CallRoomNotFoundException>();
  });
}

class _FakeClient extends Fake implements Client {}

final _clientProvider = NotifierProvider<_ClientNotifier, Client?>(
  () => _ClientNotifier(null),
);

class _ClientNotifier extends Notifier<Client?> {
  _ClientNotifier(this._initial);

  final Client? _initial;

  @override
  Client? build() => _initial;

  void set(Client? client) => state = client;
}
