import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/join_call_usecase.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_cancellation.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

import '../fake_call_repository.dart';

void main() {
  late FakeCallRepository repository;

  setUp(() => repository = FakeCallRepository());

  Future<CallRoomInfo?> join({
    String? serviceUrl = 'https://rtc.test',
    CallCancellation? cancellation,
  }) => JoinCallUseCase(repository).execute(
    roomId: '!room',
    serviceUrl: serviceUrl,
    isVideo: true,
    cancellation: cancellation,
  );

  Future<void> expectJoinTouchesNothing(Matcher error) async {
    await expectLater(join(), throwsA(error));
    expect(repository.calls, isEmpty);
  }

  test('execute_always_endsTheStaleOneThenConnectsAndJoins', () async {
    // Act
    final room = await join();

    // Assert
    expect(room, repository.roomInfo);
    expect(repository.calls, [
      'endStale !room',
      'fetchServer !room https://rtc.test',
      'connect mic=true camera=true',
      'join !room video=true',
      'ring !room video=true membership=$testMembershipEventId',
    ]);
  });

  test('an audio call rings as an audio call', () async {
    await JoinCallUseCase(
      repository,
    ).execute(roomId: '!room', serviceUrl: 'https://rtc.test', isVideo: false);

    expect(
      repository.calls.last,
      'ring !room video=false membership=$testMembershipEventId',
    );
  });

  test('joining a call someone is already in rings nobody', () async {
    repository.othersInCall = true;

    final room = await join();

    expect(room, repository.roomInfo);
    expect(repository.calls, contains('join !room video=true'));
    expect(repository.calls.where((call) => call.startsWith('ring')), isEmpty);
  });

  test('a ring that cannot be sent does not fail the call', () async {
    repository.ringError = Exception('offline');

    final room = await join();

    expect(room, repository.roomInfo);
    expect(repository.calls, contains('join !room video=true'));
    expect(repository.calls, isNot(contains('disconnect')));
    expect(repository.calls.any((call) => call.startsWith('leave')), isFalse);
  });

  test('execute_withoutATokenService_touchesNothing', () async {
    // Act & Assert
    await expectLater(
      join(serviceUrl: null),
      throwsA(isA<CallServiceUnavailableException>()),
    );
    expect(repository.calls, isEmpty);
  });

  test('execute_inAnEncryptedRoom_touchesNothing', () async {
    // Arrange
    repository.roomInfo = const CallRoomInfo(
      isEncrypted: true,
      isDirect: false,
      canJoin: true,
    );

    // Act & Assert
    await expectJoinTouchesNothing(isA<CallEncryptionUnsupportedException>());
  });

  test('execute_whenTheTokenFails_sendsNoMembership', () async {
    // Arrange
    repository.fetchError = const CallTokenFailedException();

    // Act & Assert
    await expectLater(join(), throwsA(isA<CallTokenFailedException>()));
    expect(repository.calls, isNot(contains('join !room video=true')));
    expect(repository.calls.last, startsWith('fetchServer'));
  });

  test('execute_whenTheMediaFails_sendsNoMembership', () async {
    // Arrange
    repository.connectError = const CallMediaFailedException();

    // Act & Assert
    await expectLater(join(), throwsA(isA<CallMediaFailedException>()));
    expect(repository.calls.last, 'connect mic=true camera=true');
  });

  test('execute_whenTheMembershipFails_disconnectsTheMedia', () async {
    // Arrange
    repository.joinError = const CallNoPermissionException();

    // Act & Assert
    await expectLater(join(), throwsA(isA<CallNoPermissionException>()));
    expect(repository.calls.last, 'disconnect');
    expect(repository.calls.where((call) => call.startsWith('ring')), isEmpty);
  });

  test('execute_whenCancelledBeforeTheMedia_connectsNothing', () async {
    // Arrange
    final cancellation = CallCancellation()..cancel();

    // Act
    final room = await join(cancellation: cancellation);

    // Assert
    expect(room, isNull);
    expect(repository.calls, [
      'endStale !room',
      'fetchServer !room https://rtc.test',
    ]);
  });

  test('execute_whenCancelledWhileTheMediaConnects_disconnectsIt', () async {
    // Arrange
    final cancellation = CallCancellation();
    repository.connectGate = Completer<void>();
    final joining = join(cancellation: cancellation);
    await pumpEventQueue();

    // Act
    cancellation.cancel();
    repository.connectGate!.complete();
    final room = await joining;

    // Assert
    expect(room, isNull);
    expect(repository.calls.last, 'disconnect');
    expect(repository.calls, isNot(contains('join !room video=true')));
  });

  test(
    'execute_whenCancelledWhileTheMembershipIsSent_stopsTheMediaAtOnce',
    () async {
      // Arrange
      final cancellation = CallCancellation();
      final gate = repository.joinGate = Completer<void>();
      final joining = join(cancellation: cancellation);
      await pumpEventQueue();

      // Act
      cancellation.cancel();
      await pumpEventQueue();
      final callsBeforeTheMembershipLands = [...repository.calls];
      gate.complete();
      final room = await joining;

      // Assert
      expect(callsBeforeTheMembershipLands.last, 'disconnect');
      expect(room, repository.roomInfo);
    },
  );

  test('execute_withoutTheRightToJoin_touchesNothing', () async {
    // Arrange
    repository.roomInfo = const CallRoomInfo(
      isEncrypted: false,
      isDirect: false,
      canJoin: false,
    );

    // Act & Assert
    await expectJoinTouchesNothing(isA<CallNoPermissionException>());
  });
}
