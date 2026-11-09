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

  test('joins with the token service of the well-known', () async {
    await controller().join('!room', isVideo: false);

    expect(
      state(),
      const CallState.connected(roomId: '!room', isDirect: false),
    );
    expect(repository.calls, contains('fetchServer !room https://rtc.test'));
  });

  test('is connecting while it joins', () async {
    final joining = controller().join('!room', isVideo: false);

    expect(state(), const CallState.connecting(roomId: '!room'));
    await joining;
  });

  test('a failure is kept in the state with its type', () async {
    repository.fetchError = const CallTokenFailedException();

    await controller().join('!room', isVideo: false);

    expect(
      state(),
      isA<CallFailed>().having(
        (s) => s.error,
        'error',
        isA<CallTokenFailedException>(),
      ),
    );
  });

  test('join_whenAnUntypedErrorEscapes_failsAndCanJoinAgain', () async {
    repository.staleError = StateError('database closed');

    await controller().join('!room', isVideo: false);

    expect((state() as CallFailed).error, isA<CallConnectionFailedException>());
    repository.staleError = null;
    await controller().join('!room', isVideo: false);
    expect(state(), isA<CallConnected>());
  });

  test('without a token service the call fails as unavailable', () async {
    container.read(loginHomeserverSummaryProvider.notifier).set(null);

    await controller().join('!room', isVideo: false);

    expect(
      (state() as CallFailed).error,
      isA<CallServiceUnavailableException>(),
    );
  });

  test('shows the participants of the media', () async {
    await controller().join('!room', isVideo: false);
    final everyone = [
      participant('@me:hs.test:DEV', isLocal: true),
      participant('@bob:hs.test:BOB'),
    ];

    repository.participants.add(everyone);
    await pumpEventQueue();

    expect((state() as CallConnected).participants, everyone);
  });

  test(
    'a direct call ends when the other one leaves (DECISION.md D14)',
    () async {
      repository.roomInfo = const CallRoomInfo(
        isEncrypted: false,
        isDirect: true,
      );
      await controller().join('!dm', isVideo: false);
      repository.participants.add([
        participant('@me:hs.test:DEV', isLocal: true),
        participant('@bob:hs.test:BOB'),
      ]);
      await pumpEventQueue();

      repository.participants.add([
        participant('@me:hs.test:DEV', isLocal: true),
      ]);
      await pumpEventQueue();

      expect(state(), const CallState.idle());
      expect(repository.calls, containsAllInOrder(['disconnect', 'leave !dm']));
    },
  );

  test('a group call goes on alone', () async {
    await controller().join('!room', isVideo: false);
    repository.participants.add([
      participant('@me:hs.test:DEV', isLocal: true),
      participant('@bob:hs.test:BOB'),
    ]);
    await pumpEventQueue();

    repository.participants.add([
      participant('@me:hs.test:DEV', isLocal: true),
    ]);
    await pumpEventQueue();

    expect(state(), isA<CallConnected>());
  });

  test('leave goes idle even when the membership cannot be ended', () async {
    await controller().join('!room', isVideo: false);
    repository.leaveError = const CallMembershipFailedException();

    await controller().leave();

    expect(state(), const CallState.idle());
    expect(repository.calls, containsAllInOrder(['disconnect', 'leave !room']));
  });

  test('a refused microphone answers false', () async {
    await controller().join('!room', isVideo: false);
    repository.mediaError = const CallMediaFailedException();

    expect(await controller().setMicrophone(isOn: true), isFalse);
  });

  test('the camera follows the call', () async {
    await controller().join('!room', isVideo: false);

    expect(await controller().setCamera(isOn: true), isTrue);
    expect(repository.calls.last, 'camera true');
  });

  test('leave_beforeTheMediaConnects_connectsNoMedia', () async {
    final joining = controller().join('!room', isVideo: false);

    await controller().leave();
    await joining;

    expect(state(), const CallState.idle());
    expect(repository.calls, isNot(contains('connect mic=true camera=false')));
  });

  test('leave_whileTheMembershipIsSent_leavesOnceJoined', () async {
    repository.joinGate = Completer<void>();
    final joining = controller().join('!room', isVideo: false);
    await pumpEventQueue();

    await controller().leave();
    repository.joinGate!.complete();
    await joining;

    expect(state(), const CallState.idle());
    expect(
      repository.calls,
      containsAllInOrder(['join !room video=false', 'leave !room']),
    );
  });

  test(
    'onParticipants_whenTheOtherLeavesADirectCallWithMyTwoDevices_leaves',
    () async {
      repository.roomInfo = const CallRoomInfo(
        isEncrypted: false,
        isDirect: true,
      );
      await controller().join('!dm', isVideo: false);
      repository.participants.add([
        participant('@me:hs.test:DEV', isLocal: true),
        participant('@me:hs.test:TABLET'),
        participant('@bob:hs.test:BOB'),
      ]);
      await pumpEventQueue();

      repository.participants.add([
        participant('@me:hs.test:DEV', isLocal: true),
        participant('@me:hs.test:TABLET'),
      ]);
      await pumpEventQueue();

      expect(state(), const CallState.idle());
    },
  );

  test('leave_whileTheMediaConnects_sendsNoMembership', () async {
    repository.connectGate = Completer<void>();
    final joining = controller().join('!room', isVideo: false);
    await pumpEventQueue();

    await controller().leave();
    repository.connectGate!.complete();
    await joining;

    expect(state(), const CallState.idle());
    expect(repository.calls.last, 'disconnect');
    expect(repository.calls, isNot(contains('join !room video=false')));
  });

  test('join_whileThePreviousCallLeaves_waitsForItsCleanup', () async {
    await controller().join('!room', isVideo: false);
    repository.leaveGate = Completer<void>();
    final leaving = controller().leave();

    final joining = controller().join('!other', isVideo: false);
    await pumpEventQueue();
    expect(repository.calls, isNot(contains('endStale !other')));

    repository.leaveGate!.complete();
    await leaving;
    await joining;
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
    await controller().join('!room', isVideo: false);

    repository.participants.addError(const CallConnectionFailedException());
    await pumpEventQueue();

    expect((state() as CallFailed).error, isA<CallConnectionFailedException>());
    expect(repository.calls, containsAllInOrder(['disconnect', 'leave !room']));
  });

  test('join_whenThePreviousLeaveNeverEnds_joinsAfterAWhile', () {
    fakeAsync((async) {
      controller().join('!room', isVideo: false);
      async.flushMicrotasks();
      repository.leaveGate = Completer<void>();
      controller().leave();
      async.flushMicrotasks();

      controller().join('!other', isVideo: false);
      async.elapse(const Duration(seconds: 5));
      expect(repository.calls, isNot(contains('endStale !other')));
      async.elapse(const Duration(seconds: 6));

      expect(repository.calls, contains('join !other video=false'));
      expect(state(), isA<CallConnected>());
    });
  });
}
