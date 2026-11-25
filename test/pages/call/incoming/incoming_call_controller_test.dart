import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' show Client;
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/pages/call/call_controller.dart';
import 'package:twake_chat/pages/call/call_state.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_controller.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

import '../../../domain/call/fake_call_repository.dart';
import '../call_controller_test.dart' show summaryWithFoci;

CallRing _ring(String eventId, {String roomId = '!dm'}) => CallRing(
  eventId: eventId,
  room: CallRoom(roomId),
  senderId: '@alice:hs.test',
  isVideo: false,
  expiresAt: DateTime(2100),
  roomName: 'Alice',
  isDirect: true,
);

class _FakeClient extends Fake implements Client {}

class _ActiveClient extends Notifier<Client?> {
  @override
  Client? build() => null;

  void set(Client? client) => state = client;
}

final _activeClientProvider = NotifierProvider<_ActiveClient, Client?>(
  _ActiveClient.new,
);

void main() {
  late FakeCallRepository repository;
  late ProviderContainer container;

  IncomingCallController controller() =>
      container.read(incomingCallControllerProvider.notifier);

  IncomingCallState state() => container.read(incomingCallControllerProvider);

  Future<void> ring(List<CallRing> rings) async {
    repository.rings.add(rings);
    await pumpEventQueue();
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
            {'type': 'livekit', 'livekit_service_url': 'https://rtc.test/'},
          ]),
        );
    container.listen(incomingCallControllerProvider, (_, _) {});
  });

  group('accountChange', () {
    final first = _FakeClient();
    late FakeCallRepository firstRepository;
    late ProviderContainer accounts;

    IncomingCallState ringState() =>
        accounts.read(incomingCallControllerProvider);

    setUp(() async {
      firstRepository = FakeCallRepository();
      accounts = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          activeMatrixClientProvider.overrideWith(
            (ref) => ref.watch(_activeClientProvider),
          ),
          callRepositoryProvider.overrideWith(
            (ref) => identical(ref.watch(activeMatrixClientProvider), first)
                ? firstRepository
                : FakeCallRepository(),
          ),
        ],
      );
      accounts.listen(incomingCallControllerProvider, (_, _) {});
      accounts.read(_activeClientProvider.notifier).set(first);
      await pumpEventQueue();
      firstRepository.rings.add([_ring(r'$ring')]);
      await pumpEventQueue();
      expect(ringState(), isA<IncomingCallRinging>());
    });

    test('switchToAnotherAccount_whileItRings_goesQuiet', () async {
      // Act
      accounts.read(_activeClientProvider.notifier).set(_FakeClient());
      await pumpEventQueue();

      // Assert
      expect(ringState(), const IncomingCallState.quiet());
    });

    test('logout_whileItRings_goesQuiet', () async {
      // Act
      accounts.read(_activeClientProvider.notifier).set(null);
      await pumpEventQueue();

      // Assert
      expect(ringState(), const IncomingCallState.quiet());
    });
  });

  test('build_withNoRing_isQuiet', () {
    // Assert
    expect(state(), const IncomingCallState.quiet());
  });

  test('aRing_rings', () async {
    // Act
    await ring([_ring(r'$ring')]);

    // Assert
    expect(
      state(),
      IncomingCallState.ringing(ring: _ring(r'$ring'), isInCall: false),
    );
  });

  test('aRingThatStops_goesQuiet', () async {
    // Arrange
    await ring([_ring(r'$ring')]);

    // Act: lapsed, declined or answered on another device.
    await ring([]);

    // Assert
    expect(state(), const IncomingCallState.quiet());
  });

  test('decline_goesQuietAtOnceAndSendsTheDecline', () async {
    // Arrange
    await ring([_ring(r'$ring')]);

    // Act
    final declining = controller().decline();

    // Assert
    expect(state(), const IncomingCallState.quiet());
    await declining;
    expect(repository.calls, contains(r'decline $ring'));
    await ring([_ring(r'$ring')]);
    expect(state(), const IncomingCallState.quiet());
  });

  test('decline_whenItCannotBeSent_staysQuiet', () async {
    // Arrange
    repository.declineError = const CallMembershipFailedException();
    await ring([_ring(r'$ring')]);

    // Act
    await controller().decline();

    // Assert
    expect(state(), const IncomingCallState.quiet());
  });

  test('decline_showsTheNextRing', () async {
    // Arrange
    await ring([_ring(r'$one'), _ring(r'$two', roomId: '!other')]);

    // Act
    await controller().decline();

    // Assert
    expect(
      state(),
      IncomingCallState.ringing(
        ring: _ring(r'$two', roomId: '!other'),
        isInCall: false,
      ),
    );
  });

  test('answer_joinsTheCallAudioOnly', () async {
    // Arrange
    await ring([_ring(r'$ring')]);

    // Act
    final answered = controller().answer();
    await pumpEventQueue();

    // Assert
    expect(answered, _ring(r'$ring'));
    expect(state(), const IncomingCallState.quiet());
    expect(repository.calls, contains('join !dm video=false'));
    expect(repository.calls, isNot(contains(r'decline $ring')));
    expect(container.read(callControllerProvider), isA<CallConnected>());
  });

  test('answer_withNothingRinging_doesNothing', () {
    // Act
    final answered = controller().answer();

    // Assert
    expect(answered, isNull);
    expect(container.read(callControllerProvider), const CallState.idle());
  });

  test('aRingDuringAnotherCall_ringsAsInCall', () async {
    // Arrange
    await container
        .read(callControllerProvider.notifier)
        .join('!room', isVideo: false);

    // Act
    await ring([_ring(r'$ring')]);

    // Assert
    expect(
      state(),
      IncomingCallState.ringing(ring: _ring(r'$ring'), isInCall: true),
    );
  });

  test('answer_duringAnotherCall_leavesItFirst', () async {
    // Arrange
    await container
        .read(callControllerProvider.notifier)
        .join('!room', isVideo: false);
    await ring([_ring(r'$ring')]);

    // Act
    controller().answer();
    await pumpEventQueue();

    // Assert
    expect(
      repository.calls,
      containsAllInOrder(['leave !room', 'join !dm video=false']),
    );
    expect(
      container.read(callControllerProvider),
      isA<CallConnected>().having((call) => call.roomId, 'roomId', '!dm'),
    );
  });

  test('answer_whileAnotherCallConnects_joinsOnceItIsCancelled', () async {
    // Arrange
    final connecting = Completer<void>();
    repository.connectGate = connecting;
    final first = container
        .read(callControllerProvider.notifier)
        .join('!room', isVideo: false);
    await pumpEventQueue();
    await ring([_ring(r'$ring')]);

    // Act
    controller().answer();
    await pumpEventQueue();
    repository.connectGate = null;
    connecting.complete();
    await first;
    await pumpEventQueue();

    // Assert
    expect(repository.calls, contains('join !dm video=false'));
    expect(repository.calls, isNot(contains('join !room video=false')));
    expect(
      container.read(callControllerProvider),
      isA<CallConnected>().having((call) => call.roomId, 'roomId', '!dm'),
    );
  });

  test('aRingOfTheCallThisDeviceIsIn_isQuiet', () async {
    // Arrange
    await container
        .read(callControllerProvider.notifier)
        .join('!dm', isVideo: false);

    // Act
    await ring([_ring(r'$ring')]);

    // Assert
    expect(state(), const IncomingCallState.quiet());
  });
}
