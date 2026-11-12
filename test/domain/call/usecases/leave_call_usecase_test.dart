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
    expect(repository.calls, ['disconnect', 'leave !room']);
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
    expect(repository.calls, ['disconnect', 'leave !room']);
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
    expect(repository.calls, ['disconnect', 'leave !room']);
  });
}
