import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';

import '../fake_call_repository.dart';

void main() {
  test('execute_always_disconnectsTheMediaBeforeTheMembershipLeaves', () async {
    // Arrange
    final repository = FakeCallRepository();

    // Act
    await LeaveCallUseCase(repository).execute('!room');

    // Assert
    expect(repository.calls, [
      'disconnect',
      'stopKeys',
      'leave !room',
      'line !room',
    ]);
  });

  test('execute_whenTheLeaveFails_hasDisconnectedTheMedia', () async {
    // Arrange
    final repository = FakeCallRepository(
      leaveError: const CallMembershipFailedException(),
    );

    // Act & Assert
    await expectLater(
      LeaveCallUseCase(repository).execute('!room'),
      throwsA(isA<CallMembershipFailedException>()),
    );
    expect(repository.calls, [
      'disconnect',
      'stopKeys',
      'leave !room',
      'line !room',
    ]);
  });

  test('execute_whenTheMediaFailsToDisconnect_stillLeaves', () async {
    // Arrange
    final repository = FakeCallRepository()
      ..disconnectError = const CallConnectionFailedException();

    // Act & Assert
    await expectLater(
      LeaveCallUseCase(repository).execute('!room'),
      throwsA(isA<CallConnectionFailedException>()),
    );
    expect(repository.calls, [
      'disconnect',
      'stopKeys',
      'leave !room',
      'line !room',
    ]);
  });

  test('execute_whenTheLineFails_stillLeavesTheCall', () async {
    // Arrange
    final repository = FakeCallRepository()
      ..lineError = const CallMembershipFailedException();

    // Act
    await LeaveCallUseCase(repository).execute('!room');

    // Assert
    expect(repository.calls, [
      'disconnect',
      'stopKeys',
      'leave !room',
      'line !room',
    ]);
  });

  test('execute_whenTheLeaveIsSlow_endsTheCallWhenTheUserHangsUp', () async {
    // Arrange
    final repository = FakeCallRepository()..leaveGate = Completer<void>();

    // Act
    final leaving = LeaveCallUseCase(repository).execute('!room');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final leftAt = DateTime.now();
    repository.leaveGate!.complete();
    await leaving;

    // Assert
    expect(repository.closedAt!.isBefore(leftAt), isTrue);
  });
}
